# Design: supporting stages above 16

Status: **design agreed (2026-09-28); implementation not started.** Work happens on
`feature/extended-stages`, branched from `develop`.

This replaces the earlier notes-only version of this document. That version kept the public API
unchanged by adding a separate public `BigRow`. That approach is dropped: callers would have to know
which storage a row uses, which is exactly what this design rules out.

## Goals

1. **Raise the stage cap from 16 to 24.** Ringing Room supports 18 bells today, and the largest stage
   with named methods is 22. 24 covers both with some margin.
2. **Callers can't tell which storage is in use.** Outside BellMetal, a 20-bell `Row`, `Block` or
   `PlaceNotation` is the same type, with the same API and behaviour, as an 8-bell one. No second
   public type, no generic parameter, no protocol existential.
3. **Keep the fast `UInt64` path for stages up to 16.** Rows of 16 bells or fewer keep today's
   4-bit-per-bell packing in a single `UInt64`, and collections of them keep today's raw
   `[UInt64]`/`Set<UInt64>` storage. Nearly all real use falls here.
4. **Changing the public API is allowed** when needed to meet goal 2. Changes are listed below
   and should break as little as possible.

## Why the cap exists today

`RawRow` (`Sources/BellMetal/RawRow.swift`) is a `UInt64` holding one bell per 4-bit field. A 4-bit field
only holds values 0–15, and a 64-bit word only fits 16 of them. Both limits have to go: 24 bells need
5-bit fields (values 0–31) and 120 bits of storage.

## Design overview

The storage choice depends on the stage, and it happens at runtime:

- **Narrow** (stage 1–16): a `UInt64` with 4-bit fields. This is the current `RawRow` and its
  existing code, unchanged.
- **Wide** (stage 17–24): two `UInt64` words with 5-bit fields, 12 fields per word, so no field
  crosses a word boundary and no `UInt128` arithmetic is needed.

`Stage` decides the storage. Two stages share storage exactly when they're both narrow or both wide,
and every operation that combines two values already requires the same stage. So mixed-storage
arithmetic can't happen. The only place the two layouts meet is extending across the 16/17 boundary
(see "Crossing the 16/17 boundary").

Dispatch happens once per value for `Row`, and once per collection for `Block` and `PlaceNotation`.
It never happens per element inside a loop.

## Internal engine

### `RawPermutation` protocol (internal)

A small internal protocol holding the bit-packing operations `RawRow` has today. It has two
conforming types:

```swift
internal protocol RawPermutation: Hashable, Sendable {
  func rawBell(at position: UInt8) -> UInt8
  func rawPosition(of bell: UInt8) -> UInt8?
  static func build(rawStage: UInt8, value: (UInt8) -> UInt8) -> Self
  func composePermutation(_ other: Self, rawStage: UInt8) -> Self
  func extend(from: Stage, to: Stage) -> Self
  func swapUp(from rawPos: UInt8) -> Self
  var fixedBells: [UInt8] { get }
  static func rounds(rawStage: UInt8) -> Self
}
```

- **`UInt64`**: the existing `RawRow` extension, renamed and otherwise untouched. The narrow hot path
  keeps exactly today's code.
- **`WideRawRow`**: a new internal `struct WideRawRow: Hashable, Sendable { var lo: UInt64; var hi: UInt64 }`.
  - Positions 0–11 live in `lo`, positions 12–23 in `hi`, each at bit `5 * (p % 12)`.
  - The top 4 bits of each word are always zero.
  - Field width, field mask and fields per word are `static let` constants, so they fold to
    constants in optimised builds.

The field-count limits live on the conforming types. The hardcoded `0..<16` loops in `rawPosition(of:)`
and `fixedBells` become per-type constants.

Code shared between the two layouts (pricking, leadheads, change-to-string, truth checks, transposition)
is written once as a generic function over `R: RawPermutation`. It's internal to the module, so the
optimiser specialises it for each concrete type. No generic ever crosses the module boundary: every
public entry point is a concrete method that switches, then calls a concrete version.

### `Row`: 16 bytes, stage packed into unused bits

```swift
public struct Row: Equatable, Hashable, Sendable {
  internal let lo: UInt64
  internal let hi: UInt64
}
```

| | `lo` | `hi` |
|---|---|---|
| Narrow (stage 1–16) | today's `RawRow`, 16 × 4-bit | bit 63 = 0; bits 0–3 = `stage.rawValue` (0–15); all other bits 0 |
| Wide (stage 17–24) | `WideRawRow.lo`, positions 0–11 | bit 63 = 1; bits 60–62 = `stage.rawValue - 16` (0–7); bits 0–59 = `WideRawRow.hi` |

- `stage` is read from `hi`: if bit 63 is clear, `hi` is the raw stage; otherwise it's
  `16 + (hi >> 60) & 0b111`. `isWide` is `hi >> 63 != 0`, a single test.
- **Unused bits must always be zero.** This makes the synthesized `Equatable`/`Hashable` correct.
  Only internal initialisers build a `Row` (`init(stage:narrow:)`, `init(stage:wide:)`), and they
  enforce this.
- Size and copy behaviour are unchanged: `MemoryLayout<Row>.stride == 16` (as today:
  `Stage` + padding + `UInt64`), and `Row` is still plain bitwise-copyable (no reference counting). A
  test asserts both.
- The internal accessors `narrow: UInt64` and `wide: WideRawRow` hand a row's raw contents to
  `Block` and `PlaceNotation`, and assert the layout in debug builds.

**Why the stage is encoded unevenly:** the wide layout's 12-fields-per-word split leaves 4 spare bits in
each word, not a spare byte. A wide stage therefore needs a tag bit plus a 3-bit offset. The
awkwardness is confined to the `stage` getter and the two initialisers. The alternative, a single
`UInt128` with 5-bit fields and the stage in the top byte, has a cleaner stage byte but a field that
crosses the 64-bit halves and 16-byte alignment. It's recorded here as the fallback if the two-word
layout proves awkward.

Each public `Row` operation checks `isWide` once and calls the matching version (`UInt64` or
`WideRawRow`). For stages up to 16 the only added cost is that single, predictable branch.

### Collections: dispatch once per collection

```swift
internal struct RawBlock<R: RawPermutation>: Sendable {
  var rows: [R]
  var rowSet: Set<R>
}

public struct Block: Sendable {
  public let stage: Stage
  internal let storage: Storage
  internal enum Storage: Sendable {
    case narrow(RawBlock<UInt64>)
    case wide(RawBlock<WideRawRow>)
  }
}
```

`PlaceNotation` follows the same pattern: `enum Changes { case narrow([UInt64]), wide([WideRawRow]) }`.

A narrow `Block` or `PlaceNotation` holds byte-for-byte what it holds today. Bulk operations switch
once, then run the generic version specialised for that layout:
- `prick`, `leadhead`, `description`
- `isTrue`, `isTrue(against:)`, `transpose(by:)`, `groupByStroke`
- `concatenate`, `extend`, `covered(at:)`, `replacing`, `slice`

`Row` values are only created at the boundary: subscripts, `first`/`last`, iteration.

### Crossing the 16/17 boundary

`Row.extend(to:)`, `Block.extend(to:)` and `PlaceNotation.covered(at:)` from a narrow stage to a wide
one convert the 4-bit layout to the 5-bit layout. `WideRawRow(widening: UInt64, from: Stage, to: Stage)`
reads each field and writes it into the wide layout, filling the new positions with the extra bells in
their home positions. This is the only code where the two layouts meet. It's rare and one-way (there's
no narrowing), and it gets dedicated tests.

## Public types: `Stage` and `Bell`

Both change from enums to structs over a `UInt8`, capped at 24. They still conform to
`RawRepresentable`, so `rawValue` (zero-based) and `init?(rawValue:)` keep their current meaning and
spelling. RRTower relies on `bell.rawValue`, and existing code in the other packages uses
`Bell(rawValue:)` and the `.bX` constants.

### `Stage`

```swift
public struct Stage: RawRepresentable, Hashable, Comparable, Sendable, Codable {
  public let rawValue: UInt8          // count - 1, 0...23
  public init?(rawValue: UInt8)       // nil if > 23
  public init(_ count: Int)           // precondition 1...24
  public static let maxCount = 24

  public static let one, two, singles, minimus, doubles, minor, triples, major,
                    caters, royal, cinques, maximus, thirteen, fourteen, fifteen, sixteen,
                    seventeen, eighteen, nineteen, twenty,
                    twentyOne, twentyTwo, twentyThree, twentyFour
}
```

- `.major`-style constants keep compiling at every existing use.
- `switch stage { case .major: … }` still compiles, matching each value with `==`. Exhaustive switches
  no longer do. BellMetal's own switches (`NamedRows`, `Stage.description`) get a `default`, or are
  replaced by lookup tables.
- `description` extends the existing number words: "Seventeen" … "Twenty-Four".
- `rounds` is currently a switch over string literals that parses a string on every call. It's
  replaced by arithmetic: the constant `0xFEDC_BA98_7654_3210` masked to the stage's length for narrow
  stages, and the equivalent build for wide ones (see "Benchmarking").
- `Codable` still encodes the bell count; the valid decode range becomes 1…24.

### `Bell`

```swift
public struct Bell: RawRepresentable, Hashable, Comparable, Sendable, Codable {
  public let rawValue: UInt8          // 0...23
  public static let b1, b2, …, b9, b0, bE, bT, bA, bB, bC, bD,
                    bF, bG, bH, bJ, bK, bL, bM, bN
}
```

- **Bell symbols** for 1–24 are `1234567890ETABCDFGHJKLMN`, one string used by
  `description`, `init?(character:)`, the place-notation parser (`interpretPlace`/`representPlace`,
  the tokenising pattern's character class, stage prefixes such as `N:`) and the DocC
  `PlaceNotationSyntax` article.
- `Bell(number:)` accepts 1…24. `Codable` still encodes the symbol character.

## Public API changes (summary)

Source-breaking only where noted. Recommend releasing as **2.0.0**.

| Change | Breaks existing code? |
|---|---|
| `Stage` enum → struct with the same constants | Only exhaustive `switch`es. None found in RRMethods, RRTower, ComplibKit or RRNext. |
| `Bell` enum → struct with the same constants | Same. |
| New constants: `Stage.seventeen` … `.twentyFour`, `Stage.maxCount`, `Bell.bF` … `.bN` | No |
| Stage- and place-related ranges widen from 1…16 to 1…24 (`Stage.init`, `Row.init(validating:)`, `Bell(number:)`, `representPlace`, decoders) | No: inputs that were previously rejected are now accepted. |
| `Block.makeIterator()` returns a new `Block.Iterator` instead of `Array<Row>.Iterator` | Only for code that names the iterator type. |

## Fixes in passing

Existing bugs in code this work rewrites anyway. Each gets a test:

- **`PlaceNotationParser.inferStage` rejects notation whose highest place is 16.** The check is
  `maxPlace < 16`, so `x1D` can't infer Sixteen. The bound becomes "the resulting stage is
  ≤ `Stage.maxCount`".
- **`Mask(string:)` crashes instead of throwing on an over-long string.** `Stage(string.count)` is a
  precondition. It should throw `.invalidMask`.
- **`Block.makeIterator()` builds an eager `[Row]`.** The return type forces the non-lazy `map`, so
  every iteration first allocates a full array. The new iterator is lazy.

## Downstream follow-up (outside BellMetal)

- **RRTower `BellSet`** (`RRTower/Sources/RRSimulator/BellSet.swift`) stores bells as bits in a `UInt16`
  on the assumption that bells max out at 16. Swift's `<<` gives 0 when the shift is too large rather
  than trapping, so for bells 17–24 `insert` silently does nothing and `contains` returns false. It
  needs to become a `UInt32` (and its comment updated) before RRTower runs above 16 bells.
- Before merging, build and test RRMethods, RRTower, ComplibKit and RRNext against the branch, and
  search them for other 16-bell assumptions.

## Plan

Build out the full change first, then benchmark it against current `develop`. Tests pass at every step.

1. **`Stage`/`Bell` → structs, cap still 16.** A pure refactor with no change in behaviour. Includes
   arithmetic `rounds` and table-based `description`.
2. **Internal engine.** Add the `RawPermutation` protocol, make `UInt64` conform (existing code), and
   add `WideRawRow`. Unit-test both against a simple `[Int]`-based permutation reference
   implementation.
3. **`Row` two-word layout** with dispatch on `isWide`. Tests for layout (stride 16, bitwise-copyable)
   and for the "unused bits are zero" rule.
4. **`Block`/`PlaceNotation` per-collection storage** via generic `RawBlock<R>`/changes. Check
   `Mask`, `RowTemplateIterator` and `Music` for remaining 16-bell assumptions.
5. **Raise the cap to 24.** New constants and bell symbols; parser, `Codable` ranges and DocC updated.
   Include the "Fixes in passing".
6. **Tests at stages above 16.** Cross-check every stage 1–24 against the reference implementation:
   multiply, invert, pow, `placeBellOrders`, subscripts. Extend across the 16/17 boundary. Prick
   known methods at 18, 22 and 24 and check leadheads and plain-course lengths. Round-trip parsing,
   `description` and `Codable`.
7. **Downstream check.** Build and test RRMethods, RRTower, ComplibKit and RRNext against the
   branch; raise the RRTower `BellSet` fix.
8. **Benchmarks** (below): run against `develop` and the branch, report, and fix any regressions for
   stages up to 16.
9. **PR** `feature/extended-stages` → `develop`.

## Benchmarking

The comparison runs after the full change is built, against current `develop`.

**Harness.** A separate SwiftPM package at `Benchmarks/` using `package-benchmark` (ordo-one).
- It reports wall-clock and CPU time, malloc counts, and supports saving and comparing baselines.
- The dependency lives only in the benchmark package, never in the library.
- It depends on BellMetal by local path, so the **same benchmark source** runs against a worktree of
  `develop` and against the branch. The exact switching mechanism is decided when the harness is
  built; watch out for SwiftPM caching manifest evaluation if an environment variable is used.
- Benchmarks up to 16 bells use only API that exists identically on both sides (`.major`,
  `Row("…")`, `PlaceNotation("…")`, `Block`, …). Benchmarks above 16 bells are gated and built only
  against the branch.
- Always release builds. Per the global CLAUDE.md, `swift package` runs with `--disable-sandbox`.
  Without jemalloc (`BENCHMARK_DISABLE_JEMALLOC=true`), malloc counts are lost.

**Stages.** 6, 8, 12 and 16 on both sides (16 being the largest narrow stage). 17, 18, 22 and 24 on
the branch only, as absolute numbers and relative to 16.

**Operations.**
- `Row`: construction from string and array, `*`, `invert`, `pow`, both subscripts, `description`,
  `extend`, `placeBellOrders`, hashing and `Set` insertion.
- `PlaceNotation`: parsing (with and without palindromes), `leadhead`, `description`, and pricking.
  Pricking covers one lead, a plain course (Plain Bob, Cambridge Surprise at 8, 12 and 16), and
  `.untilRound`/`.untilFalse`.
- `Block`: `isTrue` and `isTrue(against:)` on large blocks (the Minor extent, a 5,000-row Major
  block), `transpose`, `concatenate`, `extend`, iteration, `groupByStroke`,
  `count(matchingAny:)`.
- `Mask`: `matches`, `allMatchingRows`.
- `MusicScheme`: scoring a long block.

**Known confounders.** Three changes speed things up for reasons unrelated to storage:
- `Stage.rounds`: string parse → arithmetic.
- `Block` iteration: eager array → lazy.
- `inferStage`: a correctness fix only.

Benchmarks that touch them (anything that pricks from rounds by default, iterates a `Block`, or
builds from rounds) will show gains that the storage change didn't cause. The report calls these out,
and where practical includes a variant that avoids the confounded path.

**Acceptance (proposed).**
- No benchmark at 16 bells or fewer regresses beyond run-to-run noise. Anything with a median
  regression above ~5% is investigated and fixed before the PR.
- Benchmarks above 16 bells have no pass/fail threshold, but are reported.

## Performance notes carried forward

- `Package.swift` doesn't enable library evolution, so optimised builds can specialise across
  modules. Under this design that barely matters: public entry points are concrete, and generics
  stay internal to BellMetal.
- Debug builds don't specialise generics. The shared generic code will be slower in debug builds than
  today; only release numbers count.
- Bit-width values must be `static let`s on each layout type, not computed at runtime, so they fold
  to constants.
