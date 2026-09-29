import Foundation

/// The raw layout for rows above 16 bells: 5 bits per bell (values
/// 0-31), 12 bells per `UInt64`, 24 bells in all. Positions 0-11 are in
/// `lo` and 12-23 in `hi`, each at bit `5 * (position % 12)`, so no bell
/// straddles the two words. The top 4 bits of each word, and every
/// position above the row's stage, are always 0.
internal struct WideRawRow: Hashable, Sendable {
  internal var lo: UInt64
  internal var hi: UInt64

  internal init(lo: UInt64, hi: UInt64) {
    self.lo = lo
    self.hi = hi
  }

  internal static let zero = WideRawRow(lo: 0, hi: 0)

  private static let bitsPerBell: UInt64 = 5
  private static let bellMask: UInt64 = 0x1F
  private static let bellsPerWord: UInt8 = 12
  /// The number of positions this layout holds.
  internal static let positionCount: UInt8 = 24

  /// Writes `bell` at `position`, which must currently hold 0.
  private mutating func place(_ bell: UInt8, at position: UInt8) {
    if position < Self.bellsPerWord {
      lo |= UInt64(bell) << (Self.bitsPerBell * UInt64(position))
    } else {
      hi |= UInt64(bell) << (Self.bitsPerBell * UInt64(position - Self.bellsPerWord))
    }
  }
}

extension WideRawRow {
  /// Converts a narrow row to this layout, then extends it from `from` up
  /// to `to` with covers. The only place the two layouts meet.
  /// - Precondition: `from` fits the narrow layout; `to` is above it.
  internal init(widening narrow: RawRow, from: Stage, to: Stage) {
    precondition(!from.usesWideLayout && to.usesWideLayout, "Invalid widening: \(from) to \(to)")
    self = .build(rawStage: to.rawValue) { position in
      position <= from.rawValue ? narrow.rawBell(at: position) : position
    }
  }
}

extension WideRawRow: RawPermutation {
  internal func rawBell(at position: UInt8) -> UInt8 {
    if position < Self.bellsPerWord {
      return UInt8((lo >> (Self.bitsPerBell * UInt64(position))) & Self.bellMask)
    }
    return UInt8((hi >> (Self.bitsPerBell * UInt64(position - Self.bellsPerWord))) & Self.bellMask)
  }

  internal func rawPosition(of bell: UInt8) -> UInt8? {
    for position in 0..<Self.positionCount where rawBell(at: position) == bell {
      return position
    }
    return nil
  }

  internal static func build(rawStage: UInt8, value: (UInt8) -> UInt8) -> WideRawRow {
    var newRow = WideRawRow.zero
    for position in 0...rawStage {
      newRow.place(value(position), at: position)
    }
    return newRow
  }

  internal static func rounds(rawStage: UInt8) -> WideRawRow {
    build(rawStage: rawStage) { $0 }
  }

  internal func composePermutation(_ other: WideRawRow, rawStage: UInt8) -> WideRawRow {
    WideRawRow.build(rawStage: rawStage) { position in
      self.rawBell(at: other.rawBell(at: position))
    }
  }

  internal func extend(from: Stage, to: Stage) -> WideRawRow {
    WideRawRow.build(rawStage: to.rawValue) { position in
      position <= from.rawValue ? self.rawBell(at: position) : position
    }
  }

  internal func swapUp(from rawPos: UInt8) -> WideRawRow {
    let lower = rawBell(at: rawPos)
    let upper = rawBell(at: rawPos + 1)
    // Clear both positions, then write them back swapped.
    var newRow = self
    for position in [rawPos, rawPos + 1] {
      if position < Self.bellsPerWord {
        newRow.lo &= ~(Self.bellMask << (Self.bitsPerBell * UInt64(position)))
      } else {
        newRow.hi &= ~(Self.bellMask << (Self.bitsPerBell * UInt64(position - Self.bellsPerWord)))
      }
    }
    newRow.place(upper, at: rawPos)
    newRow.place(lower, at: rawPos + 1)
    return newRow
  }

  internal var fixedBells: [UInt8] {
    (0..<Self.positionCount).filter { rawBell(at: $0) == $0 }
  }
}
