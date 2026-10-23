import Foundation
import Testing
@testable import BellMetal

@Suite("Mask unit tests")
struct MaskTests {
  @Test("A mask matches a row iff fixed positions agree and open positions are ignored")
  func matching() throws {
    let noOpenPos: Mask = "1243"
    #expect(noOpenPos.matches("1243"))
    #expect(!noOpenPos.matches("1234"))
    #expect(!noOpenPos.matches("2143"))

    let onlyTreble: Mask = "1xxx"
    #expect(onlyTreble.matches("1234"))
    #expect(onlyTreble.matches("1423"))
    #expect(!onlyTreble.matches("2134"))
    #expect(!onlyTreble.matches("2314"))
    #expect(!onlyTreble.matches("2341"))

    let onlyTenor: Mask = "x4xx"
    #expect(!onlyTenor.matches("1234"))
    #expect(!onlyTenor.matches("1243"))
    #expect(onlyTenor.matches("1423"))
    #expect(onlyTenor.matches("2431"))
    #expect(!onlyTenor.matches("4123"))

    let wrongStage: Mask = "xxxx"
    #expect(!wrongStage.matches("12345"))
  }

  @Test("A mask's description is its original string")
  func description() {
    let test: Mask = "1xx2xx38"
    #expect(test.description == "1xx2xx38")
  }

  @Test("A mask's stage is its string's length")
  func stage() throws {
    #expect(try Mask(string: "xxxxxx78").stage == .major)
    #expect(try Mask(string: "x").stage == .one)
  }

  @Test("A mask made from a row matches that row and no other")
  func fromRow() {
    let mask = Mask(Row("2143"))
    #expect(mask.description == "2143")
    #expect(mask.matches("2143"))
    #expect(!mask.matches("1234"))
  }

  @Test("matching(any:) and count(matchingAny:) with no masks match nothing")
  func noMasks() throws {
    let block: Block = ["1234", "2143"]
    #expect(try block.matching(any: []).isEmpty)
    #expect(try block.count(matchingAny: []) == 0)
  }
}

@Suite("Mask row-generation unit tests")
struct RowGenTests {
  @Test("A fully-fixed mask generates exactly the one row it names")
  func allFixed() {
    let mask: Mask = "1234"
    let rows = mask.allMatchingRows().collect()
    #expect(rows == ["1234"])
  }

  @Test("A fully-open mask generates every permutation of its stage")
  func noneFixed() {
    let mask: Mask = "xxxx"
    let rows = mask.allMatchingRows().collect()
    #expect(rows.count == 24)
    #expect(Set(rows).count == 24)
  }

  @Test("A partially-fixed mask generates every permutation of its open positions")
  func someFixed() {
    let mask: Mask = "12xx"
    let rows = mask.allMatchingRows().collect()
    #expect(rows == [
      "1234",
      "1243",
    ])
  }

  @Test("allMatchingRows() can be used directly in a for loop")
  func forLoop() {
    var rows: [Row] = []
    for row in Mask("x2x4").allMatchingRows() {
      rows.append(row)
    }
    #expect(rows == ["1234", "3214"])
  }
}
