import Foundation
import Testing
@testable import BellMetal

/// Row's two-word layout: its size, the stage packed into it, and wide
/// rows' arithmetic, checked on raw bells against the reference.
@Suite("Row layout unit tests")
struct RowLayoutTests {
  typealias Reference = RawPermutationTests

  static let allRawStages: [UInt8] = Array(0...23)
  static let wideRawStages: [UInt8] = Array(16...23)

  /// A row at any raw stage 0-23, in whichever layout it uses.
  static func row(_ bells: [UInt8]) -> Row {
    let stage = Stage(uncheckedRawValue: UInt8(bells.count - 1))
    if stage.usesWideLayout {
      return Row(stage: stage, wide: .build(rawStage: stage.rawValue) { bells[Int($0)] })
    }
    return Row(stage: stage, narrow: .build(rawStage: stage.rawValue) { bells[Int($0)] })
  }

  static func bells(_ row: Row) -> [UInt8] {
    (0...row.stage.rawValue).map { row.rawBell(at: $0) }
  }

  @Test("Row is 16 bytes and a plain bitwise copy, like the Stage-plus-UInt64 it replaced")
  func layout() {
    #expect(MemoryLayout<Row>.size == 16)
    #expect(MemoryLayout<Row>.stride == 16)
    #expect(_isPOD(Row.self))
  }

  @Test("A row reports the stage it was built with, and the layout that stage uses", arguments: allRawStages)
  func stageRoundTrip(rawStage: UInt8) {
    let row = Self.row(Array(0...rawStage))
    #expect(row.stage.rawValue == rawStage)
    #expect(row.isWide == (rawStage >= 16))
    #expect(row.stage.rounds == row)
  }

  @Test("Rows of different stages are never equal, even when their bells agree as far as they go")
  func equalityIncludesStage() {
    for rawStage in UInt8(0)..<23 {
      let shorter = Self.row(Array(0...rawStage))
      let longer = Self.row(Array(0...(rawStage + 1)))
      #expect(shorter != longer)
      #expect(Set([shorter, longer]).count == 2)
    }
  }

  @Test("Wide rows multiply, invert and index like the reference", arguments: wideRawStages)
  func wideArithmetic(rawStage: UInt8) {
    let samples = Reference.permutations(rawStage: rawStage, seed: 0x5EED &+ UInt64(rawStage))
    for (lhs, rhs) in zip(samples, samples.dropFirst()) {
      let product = Self.row(lhs) * Self.row(rhs)
      #expect(Self.bells(product) == rhs.map { lhs[Int($0)] })
      #expect(product.stage.rawValue == rawStage)

      let inverse = Self.row(lhs).invert()
      #expect(Self.row(lhs) * inverse == Self.row(Array(0...rawStage)))

      for position in 1...Int(rawStage) + 1 {
        #expect(Self.row(lhs)[position].rawValue == lhs[position - 1])
      }
      for bell in 0...rawStage {
        #expect(Self.row(lhs)[Bell(uncheckedRawValue: bell)] == lhs.firstIndex(of: bell)! + 1)
      }
    }
  }

  @Test("extend(to:) works within each layout and across the 16/17 boundary")
  func extendAcrossBoundary() throws {
    for from in UInt8(0)..<23 {
      let bells = Reference.permutations(rawStage: from, seed: UInt64(from))[1]
      for to in (from + 1)...23 {
        let extended = try Self.row(bells).extend(to: Stage(uncheckedRawValue: to))
        #expect(extended == Self.row(bells + Array((from + 1)...to)))
      }
    }
  }
}
