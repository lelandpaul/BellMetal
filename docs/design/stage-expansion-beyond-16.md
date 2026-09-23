# Design note: supporting stages above 16

Status: **not started — notes only, captured for future reference.**

## Motivation

- Ringing Room currently supports up to 18 bells.
- Future projects want headroom up to the limit of currently named methods (22), plus a little margin.
- BellMetal's row representation is currently hard-capped at 16 bells.

## Why the cap exists

`RawRow` (`Sources/BellMetal/RawRow.swift:3`) is a `UInt64` packing one bell number per **4-bit nibble**
(`rawBell(at:)`, `RawRow.swift:12-14`). A nibble holds values 0–15, and 64 bits / 4 bits = 16 fields — so
the cap comes from **both** the per-bell field width (4 bits) **and** the word width (64 bits) together, not
either alone.

Important consequence: naively swapping the storage type from `UInt64` to `UInt128` while keeping 4-bit
nibbles does **nothing** for the stage limit — a nibble still only holds 0–15. To actually raise the limit,
the per-bell field must widen (e.g. to 5 bits, for bell values 0–31), and the *word* must also widen to
avoid losing capacity: 5-bit fields in a 64-bit word only fit 12 bells (worse than today); 5-bit fields in a
128-bit word fit 25 bells, comfortably covering the 22-bell target with headroom.

## Where the bit-width assumptions live (blast radius)

`RawRow` is `internal`-only — it never appears in a public signature (confirmed via search: `Row.swift:8`,
`Block.swift:9-10`, `PlaceNotation.swift:7` all hold it privately) — so this is a contained internal
refactor, not a public API break by itself. Files touched:

1. **`RawRow.swift`** — the core. All bit-width-derived constants live here:
   - `rawBell(at:)` (`:12-14`) — nibble extraction via `(self >> (4 * position)) & 0xF`.
   - `rawPosition(of:)` (`:18-27`) and `fixedBells` (`:66-70`) — loop hardcoded to `0..<16`.
   - `composePermutation(_:rawStage:)` (`:31-42`) — the row-multiplication hot path; shifts a new nibble
     in at bit **60** and right-justifies by `4*(14 - rawStage)`. Both `60` and `14` are artifacts of
     "64 bits, 16 nibbles, 0-indexed" and need re-deriving for any other field/word width.
   - `extend(from:to:)` (`:47-49`) — mask via `UInt64.max << (4 * (from.rawValue + 1))`.
   - `swapUp(from:)` (`:53-63`) — nibble-swap mask `0xF << (4 * rawPos)`.
2. **`Row.swift:177-186`** (`invert()`) — duplicates the same shift-and-right-justify logic inline instead
   of reusing `composePermutation`; needs the identical fix in a second place.
3. **`Stage.swift`** — currently a `UInt8`-backed enum with exactly 16 named cases (`.one`...`.sixteen`,
   `:4-21`) and a hardcoded `1...16` precondition (`:26-29`). Bell-ringing has no traditional names for
   stages above 16, so exhaustively naming more cases doesn't make sense here — worth reconsidering as a
   validated integer wrapper instead of an exhaustive enum, if/when this is implemented. Also check whether
   `Stage` is public API before deciding.
4. **`Row.init(validating:)`** (`Row.swift:57-60`) — same `1...16` precondition, needs updating in step
   with `Stage`.
5. No bit-scanning tricks (`leadingZeroBitCount`/`trailingZeroBitCount`/popcount) exist anywhere in
   `Sources/` — confirmed by search — so there's nothing beyond fixed shift/mask arithmetic to worry about
   at a wider word size.

## Chosen direction: generic storage, kept behind concrete public types

Rather than moving everything to a wider word (which would tax the ≤16-bell case — 99%+ of real usage —
with `UInt128`'s emulated, non-native arithmetic on every row multiply), make the underlying storage
generic and expose two concrete public types:

- `Row` — stays `UInt64`-backed, for stage ≤ 16 (the fast, native-word path, unchanged from today).
- `BigRow` — `UInt128`-backed, for stage > 16 up to whatever the wider field width supports (~25 bells at
  5 bits/field).

Explicitly out of scope: a homogeneous collection over rows of *different* stages. Not needed for any known
use case, so no type-erasure story is required — this sidesteps the sharpest risk in the design space
(protocol existentials reintroducing witness-table dispatch and potential heap allocation).

### API shape: two options considered

**Option A — typealiases of a generic type:**
```swift
public struct GenericRow<Storage: FixedWidthInteger & UnsignedInteger> { ... }
public typealias Row = GenericRow<UInt64>
public typealias BigRow = GenericRow<UInt128>
```
Least code (single implementation, `Storage`-specific members via constrained extensions). Drawback: Swift
requires a public typealias's underlying type to be at least as visible as the typealias, so `GenericRow`
must itself be `public` — leaking it as an alternate (unintended) public spelling of `Row`/`BigRow`, and
technically permitting `GenericRow<AnyOtherUnsignedFixedWidthInteger>` instantiations the bit-math was never
designed for.

**Option B — concrete wrapper structs over an internal generic engine (preferred):**
```swift
internal struct RawStorage<Storage: FixedWidthInteger & UnsignedInteger> { ... } // stays internal
public struct Row {
    private let raw: RawStorage<UInt64>
    // public methods forward to `raw`
}
public struct BigRow {
    private let raw: RawStorage<UInt128>
    // same forwarding methods
}
```
Keeps `Row`/`BigRow` as plain, non-generic structs — matches "the current API" exactly, with the generic
engine never exposed. Cost: mechanical one-line forwarding per public method. `Equatable`/`Hashable` are
synthesized for free since each wrapper has exactly one stored, already-conforming property.

**Decision: Option B**, specifically because it preserves the current public API shape (no generic type
name ever visible to consumers) at a boilerplate cost the optimizer erases (see below).

## Performance of the genericity itself

Net assessment: **no expected runtime cost for `Row` (`UInt64`) in release builds**, conditional on a few
things holding:

- `Package.swift` does **not** set `-enable-library-evolution` (confirmed — it doesn't). Without library
  evolution, Swift's cross-module optimization (default for `-O` builds) specializes generic calls across
  module boundaries, not just within BellMetal itself.
- `FixedWidthInteger & UnsignedInteger`-constrained generics over stdlib integer types is the most
  well-optimized pattern in the language — it's how the standard library's own generic numeric code
  achieves performance, and `UInt64`/`UInt128`'s protocol-conformance implementations are `@inlinable` for
  this reason.
- Bit-width-derived "constants" (nibble width, field count, etc.) must be expressed as genuine
  `static`/associated constants per `Storage`-conforming type, not values recomputed at runtime — otherwise
  they don't constant-fold away under specialization and reintroduce a small avoidable per-call cost.
- Option B's forwarding layer (`Row.method()` → `raw.method()`) is, if anything, an *easier* case for the
  inliner than Option A's generic-typealias approach: by the time you're at `Row`, there's no generic
  parameter left in play at all — it's a concrete struct forwarding to a method on a concrete stored field.

Caveats worth remembering, none of which block the approach:
- **Debug builds do not specialize** (`-Onone` always uses witness-table dispatch for generics) — expect
  debug-mode benchmarks to look worse than today; this doesn't affect shipped release performance.
- Specialization is a compiler heuristic, not a guarantee — **benchmark `Row` against today's baseline
  once implemented**, rather than assuming.
- Binary size grows with each concrete `Storage` instantiation actually used (negligible for a library this
  size, but it's the honest "cost" side of specialization — code size for speed).

## Open questions for when this is picked up

- Exact field width for `BigRow` (5 bits comfortably covers 22 bells with headroom to 25; confirm against
  the actual target ceiling before committing).
- Whether `Stage` should become a validated integer wrapper rather than an exhaustive named-case enum, and
  whether that's a breaking change for existing public API consumers.
- Whether `Bell` needs the same treatment as `Stage` (currently presumably capped in step with the 16-bell
  assumption).
