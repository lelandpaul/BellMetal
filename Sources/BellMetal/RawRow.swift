import Foundation

internal typealias RawRow = UInt64

/// Various functions handling bit-packing on UInt64-representations
/// of rows. Extracted here so that they can be shared between Row,
/// Block, etc, which saves on instantiation costs in some operations.
/// These are in general unsafe — checking for stage matching / etc.
/// happens at the call site.
extension RawRow {
  /// Retrieve the raw bell number at a given zero-indexed position.
  internal func rawBell(at position: UInt8) -> UInt8 {
    return UInt8((self >> (4 * position)) & 0xF)
  }

  /// Retrieves the raw (0-indexed) position of a given raw (0-indexed)
  /// bell. Performs no safety checks.
  internal func rawPosition(of bell: UInt8) -> UInt8? {
    var bells = self
    for i in 0..<16 {
      if bells & 0xF == bell {
        return UInt8(i)
      }
      bells >>= 4
    }
    return nil
  }

  /// Handles multiplying two permutations. Performs no
  /// safety checks.
  internal func composePermutation(_ other: RawRow, rawStage: UInt8) -> RawRow {
    var newRow = RawRow.zero
    var indices = other
    for _ in (0...rawStage) {
      let nextBell: UInt8 = UInt8(indices & 0xF)
      newRow |= UInt64(self.rawBell(at: nextBell)) << 60 // Put new bell on the left
      newRow >>= 4 // Shift over
      indices >>= 4 // Shift over
    }
    newRow >>= 4*(14 - rawStage) // Right-justify. 14 bc 0-indexed and we've already shifted 1 nibble in the loop
    return newRow
  }
  
  /// Handles extending a row up to a higher stage by appending
  /// covers. Performs no safety checks.
  internal func extend(from: Stage, to: Stage) -> RawRow {
    let mask = UInt64.max << (4 * (from.rawValue + 1))
    return self | (to.rounds.row & mask)
  }
  
  /// Performs a pairwise swap of the bell at rawPos and
  /// the bell one place higher than it. Performs no safety checks.
  internal func swapUp(from rawPos: UInt8) -> RawRow {
    let mask: RawRow = 0xF << (4 * rawPos)
    let lowerBell: RawRow = (self & mask)
    let upperBell: RawRow = (self & (mask << 4))
    var newRow = self
    newRow &= ~mask
    newRow &= ~(mask << 4)
    newRow |= lowerBell << 4
    newRow |= upperBell >> 4
    return newRow
  }
  
  /// Returns a list of (raw) bells that are in their home position.
  var fixedBells: [UInt8] {
    (0..<16)
      .map { UInt8($0) }
      .filter { self.rawBell(at: $0) == $0 }
  }
}
