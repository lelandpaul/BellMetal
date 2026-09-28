import Foundation
import Testing
@testable import BellMetal

/// Block and PlaceNotation in the wide layout, and across the 16/17
/// boundary.
@Suite("Block and PlaceNotation layout unit tests")
struct CollectionLayoutTests {
  typealias Reference = RawPermutationTests

  static func stage(_ count: Int) -> Stage {
    Stage(uncheckedRawValue: UInt8(count - 1))
  }

  static func rows(count: Int, rowCount: Int, seed: UInt64) -> [Row] {
    Reference.permutations(rawStage: UInt8(count - 1), seed: seed)
      .prefix(rowCount)
      .map(RowLayoutTests.row)
  }

  @Test("A wide block stores its rows, counts and indexes them, and iterates them in order", arguments: [17, 20, 24])
  func wideBasics(count: Int) {
    let rows = Self.rows(count: count, rowCount: 10, seed: 1)
    let block = Block(rows)
    #expect(block.stage == Self.stage(count))
    #expect(block.count == 10)
    #expect(block.uniqueCount == 10)
    #expect(block.first == rows.first)
    #expect(block.last == rows.last)
    #expect(Array(block) == rows)
    #expect((0..<10).map { block[$0] } == rows)
  }

  @Test("Wide block truth checks", arguments: [17, 24])
  func wideTruth(count: Int) throws {
    let rows = Self.rows(count: count, rowCount: 10, seed: 2)
    let block = Block(rows)
    #expect(block.isTrue)
    let repeated = try block.append(rows[3])
    #expect(!repeated.isTrue)
    #expect(repeated.uniqueCount == 10)
    let otherRows = Self.rows(count: count, rowCount: 20, seed: 3).suffix(5)
    #expect(try block.isTrue(against: Block(Array(otherRows))))
    #expect(try !block.isTrue(against: Block([rows[5]])))
  }

  @Test("Wide transpose, groupByStroke and concatenate match doing the same row by row", arguments: [17, 24])
  func wideOperations(count: Int) throws {
    let rows = Self.rows(count: count, rowCount: 9, seed: 4)
    let block = Block(rows)
    let by = Self.rows(count: count, rowCount: 2, seed: 5)[1]
    #expect(try block.transpose(by: by) == Block(rows.map { by * $0 }))

    let (hand, back) = block.groupByStroke()
    #expect(Array(hand) == stride(from: 0, to: 9, by: 2).map { rows[$0] })
    #expect(Array(back) == stride(from: 1, to: 9, by: 2).map { rows[$0] })

    #expect(Array(block + block) == rows + rows)
  }

  @Test("Block.extend(to:) matches extending each row, within and across layouts")
  func blockExtend() throws {
    for (from, to) in [(8, 12), (8, 16), (8, 17), (16, 17), (12, 24), (17, 24)] {
      let rows = Self.rows(count: from, rowCount: 6, seed: UInt64(from))
      let extended = try Block(rows).extend(to: Self.stage(to))
      #expect(extended == Block(try rows.map { try $0.extend(to: Self.stage(to)) }), "\(from) to \(to)")
    }
  }

  @Test("Narrow and wide blocks are never equal")
  func crossLayoutEquality() throws {
    let narrow = Block(Self.rows(count: 16, rowCount: 3, seed: 6))
    let wide = try narrow.extend(to: Self.stage(17))
    #expect(narrow != wide)
    #expect(Set([narrow, wide]).count == 2)
  }

  @Test("Pricking a covered notation matches pricking then extending the block, within and across layouts")
  func coveredPricking() throws {
    // Plain Bob Major, and an all-cross notation on an odd stage (covered
    // stage parity doesn't have to match).
    let notations: [PlaceNotation] = ["x18x18x18x18,12", try PlaceNotation(string: "3.1", at: .triples)]
    for pn in notations {
      let narrowCourse = try pn.prick(repeat: .untilRound)
      for to in [pn.stage.count + 1, 16, 17, 18, 22, 24] where to > pn.stage.count {
        let covered = try pn.covered(at: Self.stage(to))
        let coveredCourse = try covered.prick(repeat: .untilRound)
        #expect(coveredCourse == (try narrowCourse.extend(to: Self.stage(to))), "\(pn) to \(to)")
        #expect(covered.leadhead == (try pn.leadhead.extend(to: Self.stage(to))))
        #expect(covered.count == pn.count)
      }
    }
  }

  @Test("Wide place notation concatenates, slices and replaces like its narrow original")
  func wideNotationEditing() throws {
    let pn: PlaceNotation = "x18x18x18x18,12"
    let wide = try pn.covered(at: Self.stage(20))
    #expect(try wide.slice(0..<4) == (try pn.slice(0..<4).covered(at: Self.stage(20))))
    #expect(try wide.concatenate(with: wide).count == 2 * pn.count)
    let replaced = try wide.replacing(0..<1, with: wide.slice(1..<2))
    #expect(replaced == (try pn.replacing(0..<1, with: pn.slice(1..<2)).covered(at: Self.stage(20))))
  }
}
