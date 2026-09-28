import Foundation

/// The bit-packing operations a raw row layout provides. Two layouts
/// conform: `RawRow` (a `UInt64`, 4 bits per bell, stages up to 16) and
/// `WideRawRow` (two `UInt64`s, 5 bits per bell, stages 17 to 24).
///
/// Code shared by both layouts is written once, generic over this
/// protocol. It's internal, so it's specialized per layout within the
/// module and never appears in the public API. Like the layouts' own
/// operations, everything here is unsafe: stage checks happen at the
/// call site.
///
/// Every position above a row's stage holds 0, so two rows of the same
/// stage are equal exactly when their bits are.
internal protocol RawPermutation: Hashable, Sendable {
  /// Retrieve the raw bell number at a given zero-indexed position.
  func rawBell(at position: UInt8) -> UInt8

  /// Retrieves the raw (0-indexed) position of a given raw (0-indexed)
  /// bell, or nil if it isn't present.
  func rawPosition(of bell: UInt8) -> UInt8?

  /// Builds a row by placing `value(position)` at every position from 0
  /// through `rawStage`.
  static func build(rawStage: UInt8, value: (UInt8) -> UInt8) -> Self

  /// Rounds at the given raw stage: every bell in its home position.
  static func rounds(rawStage: UInt8) -> Self

  /// Multiplies two permutations: the result has `self`'s bell at
  /// position `other.rawBell(at: p)` in each position `p`.
  func composePermutation(_ other: Self, rawStage: UInt8) -> Self

  /// Extends a row up to a higher stage by appending covers.
  func extend(from: Stage, to: Stage) -> Self

  /// Swaps the bell at `rawPos` with the bell one place higher.
  func swapUp(from rawPos: UInt8) -> Self

  /// The (raw) bells that are in their home position.
  var fixedBells: [UInt8] { get }
}
