# Row storage: stages 1 to 24

How `Row`, `Block` and `PlaceNotation` hold their bells. Open work is in `plan.md`.

## Goals

1. **Stages up to 24.** Ringing Room runs up to 18 bells and the largest stage with named methods
   is 22; 24 covers both with some margin.
2. **Callers can't tell which storage is in use.** A 20-bell `Row`, `Block` or `PlaceNotation` is the same
   type, with the same API and behaviour, as an 8-bell one: no second public type, no generic parameter, no
   protocol existential.
3. **Stages up to 16 stay on a single `UInt64`.** Nearly all real use falls here, so rows of 16 bells or
   fewer keep the 4-bit-per-bell packing, and collections of them keep raw `[UInt64]`/`Set<UInt64>` storage.

## Layouts

The layout depends on the stage and is chosen at runtime. Two stages share a layout exactly when both are
narrow or both wide, and every operation that combines two values already requires the same stage, so
mixed-layout arithmetic can't happen. The layouts meet only when extending across the 16/17 boundary.

- **Narrow** (stages 1-16): `RawRow`, a `UInt64` with 4-bit fields (`typealias RawRow = UInt64`). A 4-bit
  field holds 0-15 and a word holds 16 of them, so both limits had to change to pass 16.
- **Wide** (stages 17-24): `WideRawRow`, two `UInt64`s with 5-bit fields (values 0-31), 12 per word:
  positions 0-11 in `lo`, 12-23 in `hi`, each at bit `5 * (position % 12)`. No field crosses a word
  boundary, so no `UInt128` arithmetic is needed. The top 4 bits of each word are always 0.

Every position above a row's stage holds 0, so two rows of one stage are equal exactly when their bits are.

Dispatch happens once per value for `Row` and once per collection for `Block` and `PlaceNotation`, never per
element inside a loop.

## Internal engine

`RawPermutation` (internal) is the bit-packing interface both layouts implement: bell at position, position
of bell, `build`, `rounds`, `composePermutation`, `extend`, `swapUp`, `fixedBells`. `RawLayout` refines it
with the plain wrap and unwrap that move between raw values and the public types (`row(stage:)`,
`raw(of:)`, `blockStorage(_:)`, `changes(_:)`).

Code shared by both layouts (pricking, leadheads, change-to-string, truth checks, transposition) is written
once, generic over `RawLayout`. It is internal, so the optimiser specialises it per layout. **No generic
crosses the module boundary:** every public entry point is a concrete method that switches on the layout and
calls a concrete version.

Field widths, masks and fields-per-word are `static let` constants on each layout type so they fold to
constants. Debug builds don't specialise generics, so the shared code is slower there; only release numbers
matter. `Package.swift` doesn't enable library evolution, which would block cross-module specialisation, but
since public entry points are concrete it barely matters.

## `Row`: 16 bytes, stage packed into unused bits

```swift
public struct Row { private let lo: UInt64; private let hi: UInt64 }
```

| | `lo` | `hi` |
|---|---|---|
| Narrow (1-16) | the `RawRow` | bit 63 = 0; low bits = `stage.rawValue` (0-15) |
| Wide (17-24) | `WideRawRow.lo` | bit 63 = 1; bits 60-62 = `stage.rawValue - 16`; bits 0-59 = `WideRawRow.hi` |

- `isWide` is `hi >> 63 != 0`, a single test. Each public operation checks it once, then calls the narrow or
  wide version; for stages up to 16 that predictable branch is the only added cost.
- **Unused bits are always zero**, so the synthesized `Equatable` is correct. Only internal initialisers
  build a `Row`, and they enforce this.
- **`hash(into:)` mixes the two words into one value** (`lo ^ (hi &* 0x9E37_79B9_7F4A_7C15)`) before
  hashing. The synthesized version fed 16 bytes to the hasher instead of 9 and made `Set<Row>` insertion
  18-28% slower than the single-word row; mixed, it is 3-11% faster.
- `MemoryLayout<Row>.stride == 16` and a `Row` is plain bitwise-copyable (no reference counting). A test
  asserts both.

**Why the stage is encoded unevenly:** 12 five-bit fields per word leave 4 spare bits in each word, not a
spare byte, so a wide stage needs a tag bit plus a 3-bit offset. The awkwardness is confined to the `stage`
getter and the two initialisers. The alternative is a single `UInt128` with 5-bit fields and the stage in the
top byte: a cleaner stage byte, but a field that crosses the 64-bit halves and 16-byte alignment.

## `Block` and `PlaceNotation`: dispatch once per collection

```swift
public struct Block { public let stage: Stage; internal let storage: Storage
  enum Storage { case narrow(RawBlock<RawRow>), wide(RawBlock<WideRawRow>) } }
```

`RawBlock<R>` holds `rows: [R]` and `rowSet: Set<R>` (for truth checks). `PlaceNotation` has the same shape
(`enum Changes { case narrow([RawRow]), wide([WideRawRow]) }`). Bulk operations switch once, then run the generic version: `prick`, `leadhead`,
`description`, `isTrue`, `isTrue(against:)`, `transpose(by:)`, `groupByStroke`, `concatenate`, `extend`,
`covered(at:)`, `replacing`, `slice`. `Row` values are made only at the boundary: subscripts, `first`/`last`,
iteration.

**Why an enum, not two arrays.** `Block`'s subscript costs about 0.4 ns (19-25%) more per row than a bare
array. The compiled getter has no reference counting; the extra is the layout check (3 instructions and a
taken branch). Two array fields chosen by stage, one always empty, would need the same check.

`Block.Iterator` is lazy: it builds each `Row` on demand rather than mapping the whole block to an array
first.

### Crossing 16/17

`Row.extend(to:)`, `Block.extend(to:)` and `PlaceNotation.covered(at:)` from a narrow to a wide stage go
through `WideRawRow(widening:from:to:)`, which reads each 4-bit field and writes it as a 5-bit field, filling
new positions with the added bells in their home positions. It is the only code where the layouts meet,
one-way (there is no narrowing), and has dedicated tests.

## `Stage` and `Bell`

Both are structs over a `UInt8`, capped at 24, conforming to `RawRepresentable` (zero-based `rawValue`,
failable `init(rawValue:)`), with a named constant for every value (`.major`, `.b1` ... `.bN`).
Consequences of not being enums:

- `switch stage { case .major: ... }` compiles (patterns match with `==`) but is never exhaustive, so
  BellMetal's own switches carry a `default` or use lookup tables.
- `Stage.rounds` is arithmetic (the `0xFEDC_BA98_7654_3210` constant masked to the stage's length for narrow
  stages, a `build` for wide ones), not string parsing.
- `Stage` encodes as its bell count, `Bell` as its symbol character; decoding accepts 1...24.
- **Bell symbols** are `1234567890ETABCDFGHJKLMN`, one string used by `Bell.description`,
  `Bell(character:)`, the place-notation parser (`interpretPlace`/`representPlace`, the tokenizer's
  character class, stage prefixes such as `N:`) and the `PlaceNotationSyntax` article. `I` is skipped as
  easily misread as `1`.

For callers moving from 1.x: only exhaustive `switch`es over `Stage`/`Bell` and code that names
`Array<Row>.Iterator` as `Block`'s iterator type break; the ranges that were 1...16 now accept 1...24.

## Pitfalls

- A bare `"1"` parsed without a stage infers Singles, and the tenor's place must be written as its symbol
  (`T` on Maximus), not its decimal count; `NamedRow.intermediate` and `.jokers` build their change
  accordingly (`intermediateChange(at:)`).
- Named combination masks (`MusicType.namedComboMasks`) must be exactly the stage's length. A mask of the
  wrong length gets a different stage, so counting it throws `.stageMismatch`, which scoring swallows with
  `try?` and scores 0; one naming a bell its own length lacks traps when the literal is built.
- `inferStage` bounds the result at `Stage.maxCount`, not at 16.

## Performance

Benchmarks are in `Benchmarks/` (see its README). Measured in release builds on one machine while 2.0 was
built, against the single-`UInt64` implementation of 1.x: median change over all benchmarks at 6-16 bells
was 8.6% faster; 68 of 108 were faster by more than 5%, 34 within +/-5%, 6 slower by more than 5%. Run-to-run
noise on the same code was 0.7% at the median, 3.6% at the 90th percentile and 8% at worst, mostly at 6 bells.

**Slower:** `Block` subscript (+19-25%, the layout check above); `Block.groupByStroke` at 12 and 16 bells
(+7-8% in the full run, about +2% and sign-flipping in head-to-head runs, so noise); `Row.invert` at 6 bells
(+5% against 3.8% noise).

**Faster, unrelated to storage:** `Stage.rounds`, `Row.extend` and `Block.extend` no longer parse a string
(97-100%); `PlaceNotation.leadhead`, `Row.description` and parsing 27-89%; `Block` iteration (lazy) 26-33%;
`Block.isTrue(against:)` uses `isDisjoint(with:)`, which stops at the first shared row and allocates nothing
(up to 93%).

**Above 16 bells:** parsing, `description`, `Mask.matches` and `Set` insertion cost about what they do at
16. Operations that rebuild whole rows cost 1.5-4x as much (multiply, `pow`, `transpose`,
`isTrue(against:)`, pricking).

Median time per operation, release build:

| Benchmark | 16 bells | 24 bells |
|---|---:|---:|
| `Row * Row` | 11 ns | 50 ns |
| `Row.invert` | 53 ns | 143 ns |
| `Row.description` | 232 ns | 331 ns |
| `Mask.matches` | 8 ns | 8 ns |
| `Block` subscript, every row of a plain course | 791 ns | 1792 ns |
| `Block.transpose` of a plain course | 8.9 µs | 76.9 µs |
| `Block.isTrue(against:)` | 3.0 µs | 25.6 µs |
| `PlaceNotation.leadhead` | 300 ns | 1.7 µs |
| prick a plain course (`.untilRound`) | 25.6 µs | 143.5 µs |
| `MusicScheme.shared.score` of a plain course | 749 µs | 1.9 ms |
