import Foundation

internal typealias RawRow = UInt64

/// Bit-packing on `UInt64` rows (4 bits per bell, stages up to 16),
/// shared by Row, Block and PlaceNotation. Unsafe: stage checks happen at
/// the call site.
extension RawRow: RawPermutation {
  /// Retrieve the raw bell number at a given zero-indexed position.
  internal func rawBell(at position: UInt8) -> UInt8 {
    return UInt8((self >> (4 * position)) & 0xF)
  }

  /// Retrieves the raw (0-indexed) position of a given raw (0-indexed)
  /// bell, or nil if it isn't present.
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

  /// Builds a `RawRow` by placing `value(position)` at nibble `position`,
  /// for every position from 0 through `rawStage`.
  ///
  /// Each nibble goes straight to its final position, with no
  /// stage-dependent shift to correct afterwards: such a shift underflows
  /// (and traps) at the maximum stage, `rawStage == 15`.
  internal static func build(rawStage: UInt8, value: (UInt8) -> UInt8) -> RawRow {
    var newRow: RawRow = .zero
    for position in 0...rawStage {
      newRow |= RawRow(value(position)) << (4 * RawRow(position))
    }
    return newRow
  }

  /// Rounds at the given raw stage: every bell in its home position.
  /// The full-stage constant, with the positions above `rawStage` masked
  /// off.
  internal static func rounds(rawStage: UInt8) -> RawRow {
    0xFEDC_BA98_7654_3210 & (RawRow.max >> (4 * (15 - rawStage)))
  }

  /// Multiplies two permutations.
  internal func composePermutation(_ other: RawRow, rawStage: UInt8) -> RawRow {
    var indices = other
    return RawRow.build(rawStage: rawStage) { _ in
      defer { indices >>= 4 }
      return self.rawBell(at: UInt8(indices & 0xF))
    }
  }
  
  /// Extends a row up to a higher stage by appending covers.
  internal func extend(from: Stage, to: Stage) -> RawRow {
    let mask = UInt64.max << (4 * (from.rawValue + 1))
    return self | (RawRow.rounds(rawStage: to.rawValue) & mask)
  }
  
  /// Swaps the bell at `rawPos` with the bell one place higher.
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
  
  /// The (raw) bells that are in their home position.
  internal var fixedBells: [UInt8] {
    (0..<16)
      .map { UInt8($0) }
      .filter { self.rawBell(at: $0) == $0 }
  }
}
