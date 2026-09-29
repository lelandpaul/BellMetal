# Design: supporting stages above 16

Status: **implemented and benchmarked (2026-09-29)** on `feature/extended-stages`, branched from
`develop`. This document describes what was built. Where the implementation differs from the
original plan, the relevant section says so.

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
- **Unused bits must always be zero.** This makes the synthesized `Equatable` correct, and the hash
  too. Only internal initialisers build a `Row` (`init(stage:narrow:)`, `init(stage:wide:)`), and they
  enforce this.
- **`hash(into:)` is written by hand:** it mixes the two words into one value
  (`lo ^ (hi &* 0x9E37_79B9_7F4A_7C15)`) before hashing. The synthesized version fed both words to the
  hasher (16 bytes, against 9 on `develop`), which made `Set<Row>` insertion 18–28% slower in the
  first benchmark run. Mixed, it's 3–11% faster than `develop`.
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
internal struct RawBlock<R: RawLayout>: Sendable {
  let rows: [R]
  let rowSet: Set<R>
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

**`RawLayout`**, an internal protocol that refines `RawPermutation`, lets the shared generic code move
between raw rows and the public types: `row(stage:)`, `raw(of:)`, `blockStorage(_:)` and `changes(_:)`,
each a plain wrap or unwrap.

**Two-array alternative (considered, not taken).** Benchmarks showed `Block`'s subscript about
0.4 ns (19–25%) slower per row than on `develop`. The compiled getter has no reference counting: it's
the layout check (3 instructions plus a taken branch) on top of `develop`'s 11-instruction getter. Two
array fields chosen by stage, one always empty, would need the same check, so the enum stays.

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

Found while working, each in its own commit:

- **`NamedRow.intermediate` (and `.jokers`) crashes on odd stages from Triples up, and on even
  stages from Royal up.** `"1"` parsed without a stage infers Singles, and the tenor's place was written
  as its decimal count (`"112"` on Maximus). This also made `MusicScheme` scoring crash from 10 bells
  up on `develop`.
- **Named combo masks for Sixteen and Caters had the wrong length.** Sixteen's
  `"xxxxxxxxAxBxCxD"` became `"xxxxxxxxxAxBxCxD"`, and Caters' `"xxxxx468"`, `"xxxxx987"` and
  `"xxx97568"` gained a leading `x` each. Two of them contained a bell the mask's own stage doesn't
  have, so scoring crashed.

## Downstream (outside BellMetal)

All four packages build and pass their tests against the branch with no source changes, linked
locally with `swift package edit`: RRMethods (137 tests), RRTower (154), ComplibKit (58), RRNext (205).
No package switches exhaustively over `Stage` or `Bell`.

- **RRTower `BellSet`**, fixed in lelandpaul/RRTower#16 (merged). It stored bells as bits in a
  `UInt16`. Swift's `<<` gives 0 for a shift past the word's width rather than trapping, so bells
  17–24 would have been silently dropped. It's now a `UInt32`, and `insert` asserts the bell fits.
- **RRNext `RowGen.body()`** rejects stages above 16 with a hard-coded `(1...16)` check. That's
  correct against BellMetal 1.x. Once RRNext moves to 2.0, it should become `1...Stage.maxCount`.

## Plan (done)

Built out in full first, then benchmarked against `develop`. Tests passed at every step: 146 on
`develop`, 180 at the end.

1. **`Stage`/`Bell` → structs, cap still 16** (`9804f0f`). Arithmetic `rounds`, table-based
   `description`.
2. **Internal engine** (`d1245a5`). `RawPermutation`, the `UInt64` conformance, and `WideRawRow`,
   each checked against a plain-array reference.
3. **`Row` two-word layout** (`0a2cae1`).
4. **`Block`/`PlaceNotation` per-collection storage** (`5bc0345`).
5. **Cap raised to 24** (`c845116`), including the planned fixes in passing.
6. **Tests at stages above 16** (`1271a6a`). Every public `Row` operation at every stage 1–24
   against the reference.
7. **Downstream check.** See "Downstream".
8. **Benchmarks** (`a5bdc9b`, `57419c2`), and the `Row` hash fix (`0183fb7`).
9. **PR** `feature/extended-stages` → `develop`.

## Benchmarking

**Harness.** A separate SwiftPM package at `Benchmarks/`, using ordo-one's
[Benchmark](https://github.com/ordo-one/benchmark). See `Benchmarks/README.md` for how to run it.
- The dependency lives only in the benchmark package, never in the library.
- It takes BellMetal from a local path, `BELLMETAL_PATH` (defaulting to this checkout), so the same
  benchmark source measures a worktree of `develop` and the branch.
- Each version gets its own `--scratch-path`, and `--manifest-cache none` stops SwiftPM reusing a
  manifest evaluated for the other path.
- The code uses only API that 1.x and 2.0 share. Benchmarks above 16 bells register only when
  `Stage(rawValue: 16)` exists.
- Release builds only, with malloc counts via jemalloc.

**Stages.** 6, 8, 12 and 16 on both versions; 17, 18, 22 and 24 on the branch only.

**Operations.** 29 per stage, across `Row`, `PlaceNotation` (parsing, `leadhead`, `description`,
pricking one lead, a plain course and 160 leads), `Block`, `Mask` and `MusicScheme`. Inputs are Plain
Bob at each stage and 64 seeded random rows. The plan's Cambridge, Minor-extent and 5,000-row blocks
were replaced by Plain Bob courses and a 160-lead prick, which work at every stage.

Music scoring is measured on `develop` only at 6 and 8 bells, because `develop` crashes scoring from
10 bells up (the `NamedRow.intermediate` bug).

**Noise.** `develop` was measured twice. The same code differs by 0.7% in the median case, 3.6% at
the 90th percentile and 8% at worst, and the biggest gaps are all 6-bell benchmarks.

### Results

Change in median time from `develop` to the branch (negative is faster), and the branch's median
time per operation at 16 and 24 bells. `—`: not measured on one side.

| Benchmark | 6 | 8 | 12 | 16 | 16 bells (branch) | 24 bells (branch) |
|---|---:|---:|---:|---:|---:|---:|
| Block + Block | +0% | +0% | +4% | +2% | 10.4 µs | 62.5 µs |
| Block iterate plain course | -33% | -33% | -28% | -26% | 958 ns | 2994 ns |
| Block subscript every row | +0% | +25% | +22% | +19% | 791 ns | 1792 ns |
| Block.count(matchingAny:) | -7% | -7% | -8% | -4% | 35.7 µs | 76.9 µs |
| Block.extend(to: +2) | -97% | -98% | -99% | — | 20.4 µs | — |
| Block.groupByStroke | -3% | -2% | +8% | +7% | 6536 ns | 31.2 µs |
| Block.isTrue(against:) | -93% | -5% | +0% | +2% | 3040 ns | 25.6 µs |
| Block.transpose | +5% | -2% | -1% | +2% | 8929 ns | 76.9 µs |
| Mask.allMatchingRows (120) | +0% | +0% | +0% | +0% | 71.4 µs | 90.9 µs |
| Mask.matches | -26% | -29% | -29% | -29% | 8 ns | 8 ns |
| MusicScheme.shared.score | -19% | -21% | — | — | 749.1 µs | 1886.8 µs |
| PlaceNotation.description | -1% | -1% | -3% | +0% | 11.4 µs | 16.1 µs |
| PlaceNotation.init(string:) Plain Bob | -27% | -32% | -41% | -51% | 25.6 µs | 37.0 µs |
| PlaceNotation.leadhead | -89% | -84% | -79% | -74% | 300 ns | 1736 ns |
| Row * Row | -19% | -15% | -8% | -6% | 11 ns | 50 ns |
| Row.description | -65% | -63% | -62% | -58% | 232 ns | 331 ns |
| Row.extend(to: +1) | -99% | -99% | -100% | — | 16 ns | — |
| Row.init(validating:) | -8% | -10% | -16% | -24% | 716 ns | 1029 ns |
| Row.invert | +5% | +2% | +0% | +0% | 53 ns | 143 ns |
| Row.placeBellOrders | -0% | +1% | +1% | +2% | 757 ns | 986 ns |
| Row.pow(7) | -31% | -25% | -18% | -12% | 59 ns | 287 ns |
| Row[bell], every bell | +0% | +5% | +0% | -1% | 109 ns | 221 ns |
| Row[position], every position | -32% | -32% | -32% | -37% | 26 ns | 56 ns |
| Set<Row> insert 64 rows | -11% | -7% | -3% | -5% | 2874 ns | 2833 ns |
| Stage.rounds | -100% | -100% | -100% | -100% | 1 ns | 1 ns |
| prick 160 leads (.times) | -8% | -6% | -7% | -6% | 182.9 µs | 740.2 µs |
| prick one lead | -27% | -28% | -27% | -29% | 2247 ns | 6944 ns |
| prick plain course (.untilRound) | -10% | -11% | -9% | -8% | 25.6 µs | 143.5 µs |

Up to 16 bells: 68 benchmarks are faster by more than 5%, 34 are within ±5%, and 6 are slower by more
than 5%. The median change is 8.6% faster.

**Slower:**
- **`Block` subscript**, +19–25% (about 0.4 ns per row). This is the per-access layout check; see
  "Two-array alternative".
- **`Block.groupByStroke` at 12 and 16 bells**, +7–8% in the full run. It doesn't reproduce: three
  alternating head-to-head runs averaged about +2%, flipping in both directions. The compiled code
  makes the same calls as `develop`'s.
- **`Row.invert` at 6 bells**, +5%, against 3.8% noise for that benchmark.

**Faster for reasons unrelated to the storage change:**
- `Stage.rounds`, `Row.extend` and `Block.extend` no longer parse a string: 97–100% faster.
- `PlaceNotation.leadhead`, `Row.description` and parsing are 27–89% faster.
- `Block` iteration is lazy: 26–33% faster.
- `Block.isTrue(against:)` checks the two row sets with `isDisjoint(with:)`, which stops at the
  first shared row, instead of building their intersection. It's up to 93% faster (at 6 bells) and no
  longer allocates.

**Above 16 bells:** simple operations (parsing, `description`, `Mask.matches`, `Set` insertion) cost
about the same as at 16 bells. Operations that rebuild whole rows cost 1.5–4× as much: multiply,
`pow`, `transpose`, `isTrue(against:)`, pricking. A 24-bell plain course pricks in about 140 µs.

## Performance notes carried forward

- `Package.swift` doesn't enable library evolution, so optimised builds can specialise across
  modules. Under this design that barely matters: public entry points are concrete, and generics
  stay internal to BellMetal.
- Debug builds don't specialise generics. The shared generic code will be slower in debug builds than
  today; only release numbers count.
- Bit-width values must be `static let`s on each layout type, not computed at runtime, so they fold
  to constants.
