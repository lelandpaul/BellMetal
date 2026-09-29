import Foundation
import Testing
@testable import BellMetal

/// Checks both raw layouts against a plain `[UInt8]` reference, on
/// seeded random permutations of every stage each layout supports.
@Suite("RawPermutation unit tests")
struct RawPermutationTests {
  /// SplitMix64: a small, deterministic generator, so failures reproduce.
  struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
      state &+= 0x9E37_79B9_7F4A_7C15
      var z = state
      z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
      z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
      return z ^ (z >> 31)
    }
  }

  static let narrowRawStages: [UInt8] = Array(0...15)
  static let wideRawStages: [UInt8] = Array(0...23)
  static let samplesPerStage = 50

  /// Random permutations of `0...rawStage`, always including rounds.
  static func permutations(rawStage: UInt8, seed: UInt64) -> [[UInt8]] {
    var generator = SeededGenerator(state: seed)
    let rounds = Array(0...rawStage)
    return [rounds] + (1..<samplesPerStage).map { _ in rounds.shuffled(using: &generator) }
  }

  static func make<R: RawPermutation>(_: R.Type, _ bells: [UInt8]) -> R {
    R.build(rawStage: UInt8(bells.count - 1)) { bells[Int($0)] }
  }

  static func unpack<R: RawPermutation>(_ row: R, rawStage: UInt8) -> [UInt8] {
    (0...rawStage).map { row.rawBell(at: $0) }
  }

  /// Every property, for one layout at one stage.
  static func checkLayout<R: RawPermutation>(_ type: R.Type, rawStage: UInt8) {
    let samples = permutations(rawStage: rawStage, seed: 0xBE11 &+ UInt64(rawStage))
    let rows = samples.map { make(type, $0) }

    #expect(R.rounds(rawStage: rawStage) == make(type, Array(0...rawStage)))

    for (bells, row) in zip(samples, rows) {
      #expect(unpack(row, rawStage: rawStage) == bells)
      for bell in 0...rawStage {
        #expect(row.rawPosition(of: bell) == bells.firstIndex(of: bell).map(UInt8.init))
      }
      let expectedFixed = (0...rawStage).filter { bells[Int($0)] == $0 }
      #expect(row.fixedBells == expectedFixed)
      for position in 0..<rawStage {
        var swapped = bells
        swapped.swapAt(Int(position), Int(position) + 1)
        #expect(row.swapUp(from: position) == make(type, swapped))
      }
    }

    // Every pair would be slow; adjacent pairs of samples cover plenty.
    for (lhs, rhs) in zip(zip(samples, rows), zip(samples, rows).dropFirst()) {
      let expected = rhs.0.map { lhs.0[Int($0)] }
      #expect(lhs.1.composePermutation(rhs.1, rawStage: rawStage) == make(type, expected))
    }
  }

  @Test("RawRow matches the reference on every stage up to 16", arguments: narrowRawStages)
  func narrow(rawStage: UInt8) {
    Self.checkLayout(RawRow.self, rawStage: rawStage)
  }

  @Test("WideRawRow matches the reference on every stage up to 24", arguments: wideRawStages)
  func wide(rawStage: UInt8) {
    Self.checkLayout(WideRawRow.self, rawStage: rawStage)
  }

  @Test("extend(from:to:) adds covers, in both layouts")
  func extend() {
    for from in UInt8(0)..<23 {
      for bells in Self.permutations(rawStage: from, seed: UInt64(from)).prefix(5) {
        for to in (from + 1)...23 {
          let expected = bells + Array((from + 1)...to)
          let (fromStage, toStage) = (Stage(uncheckedRawValue: from), Stage(uncheckedRawValue: to))
          #expect(Self.make(WideRawRow.self, bells).extend(from: fromStage, to: toStage) == Self.make(WideRawRow.self, expected))
          if to < 16 {
            #expect(Self.make(RawRow.self, bells).extend(from: fromStage, to: toStage) == Self.make(RawRow.self, expected))
          }
        }
      }
    }
  }

  @Test("Widening a narrow row to any wide stage keeps its bells and adds covers")
  func widening() {
    for from in UInt8(0)...15 {
      for bells in Self.permutations(rawStage: from, seed: UInt64(from)).prefix(5) {
        for to in UInt8(16)...23 {
          let widened = WideRawRow(
            widening: Self.make(RawRow.self, bells),
            from: Stage(uncheckedRawValue: from),
            to: Stage(uncheckedRawValue: to)
          )
          #expect(widened == Self.make(WideRawRow.self, bells + Array((from + 1)...to)))
        }
      }
    }
  }

  @Test("WideRawRow keeps unused bits zero: the top 4 bits of each word, and positions above the stage")
  func wideUnusedBitsZero() {
    let full = WideRawRow.rounds(rawStage: 23)
    #expect(full.lo >> 60 == 0)
    #expect(full.hi >> 60 == 0)
    let seventeen = WideRawRow.rounds(rawStage: 16)
    #expect(seventeen.hi >> 25 == 0)
    // A wide row equal to rounds only up to its stage isn't equal to a longer rounds.
    #expect(seventeen != WideRawRow.rounds(rawStage: 17))
  }
}
