import Foundation
import Testing
@testable import BellMetal

@Suite("Block unit tests")
struct BlockTests {

  // MARK: Instantiation
  @Test("Instantiates from an array of rows")
  func instantiateFromRowArray() {
    let block = Block([
      "1234",
      "2143",
      "2413"
    ])
    #expect(block.count == 3)
    #expect(block.uniqueCount == 3)
    #expect(block.first == "1234")
    #expect(block.last == "2413")
    // `last`, like `first`, is never nil -- a Block can't be empty.
    // The `: Row` annotation makes that a compile-time check, not just a runtime one.
    let last: Row = block.last
    #expect(last == "2413")
  }

  @Test("Instantiates from an array literal")
  func instantiateFromArrayLiteral() {
    let block: Block = [
      "1234",
      "2143",
      "2413"
    ]
    #expect(block.count == 3)
    #expect(block.uniqueCount == 3)
    #expect(block.first == "1234")
    #expect(block.last == "2413")
  }

  @Test("Instantiates from variadic rows")
  func instantiateFromRows() {
    let block = Block(
      "1234",
      "2143",
      "2413"
    )
    #expect(block.count == 3)
    #expect(block.uniqueCount == 3)
    #expect(block.first == "1234")
    #expect(block.last == "2413")
  }

  // MARK: Truth
  @Test("A block is true iff it contains no repeated rows")
  func singleBlockTruth() {
    let trueBlock: Block = [
      "1234",
      "2143"
    ]
    let falseBlock: Block = [
      "1234",
      "1234"
    ]

    #expect(trueBlock.isTrue)
    #expect(!falseBlock.isTrue)
  }

  @Test("Two blocks are true against each other iff they share no rows")
  func multiBlockTruth() throws {
    let blockA: Block = [
      "1234",
      "2143"
    ]
    let blockB: Block = [
      "4321",
      "3412"
    ]
    let blockC: Block = [
      "1234",
      "1243"
    ]
    #expect(try blockA.isTrue(against: blockB))
    #expect(try !blockA.isTrue(against: blockC))
    #expect(try blockB.isTrue(against: blockC))

    #expect(try blockB.isTrue(against: blockA))
    #expect(try !blockC.isTrue(against: blockA))
    #expect(try blockC.isTrue(against: blockB))
  }

  // MARK: - Transposition & extention

  @Test("Transposing a block multiplies every row by the transposing row")
  func testTranspose() throws {
    let transposeBy: Row = "4321"
    let block: Block = [
      "1234",
      "2143",
    ]

    let expectedTransposed: Block = [
      "4321",
      "3412"
    ]

    #expect(try block.transpose(by: transposeBy) == expectedTransposed)
  }

  @Test("Transposing a plain bob minimus lead by its own leadhead gives the next lead")
  func testTransposePb4() throws {
    let pb4_first_lead: Block = [
      "2143",
      "2413",
      "4231",
      "4321",
      "3412",
      "3142",
      "1324",
      "1342"
    ]

    let pb4_expected_second_lead: Block = [
      "3124",
      "3214",
      "2341",
      "2431",
      "4213",
      "4123",
      "1432",
      "1423"
    ]

    let pb4_second_lead: Block = try pb4_first_lead.transpose(by: pb4_first_lead.last)

    #expect(pb4_second_lead == pb4_expected_second_lead)
  }

  @Test("Extending a block to a higher stage extends every row")
  func testExtend() throws {
    let block: Block = [
      "1234",
      "2143",
    ]
    let extended = try block.extend(to: .minor)
    let expected: Block = [
      "123456",
      "214356"
    ]
    #expect(extended == expected)
  }

  @Test("Concatenating two blocks with + appends their rows")
  func testConcatenate() throws {
    let blockA: Block = [
      "1234",
      "2143",
    ]
    let blockB: Block = [
      "2413",
      "4231",
    ]
    let expected: Block = [
      "1234",
      "2143",
      "2413",
      "4231",
    ]
    #expect(blockA + blockB == expected)
  }

  @Test("Appending rows to a block adds them to the end")
  func testAppend() throws {
    let block: Block = [
      "1234",
      "2143",
    ]
    let rows: [Row] = [
      "2413",
      "4231",
    ]
    let expected: Block = [
      "1234",
      "2143",
      "2413",
      "4231",
    ]
    #expect(try block.append(rows.first!, rows.last!) == expected)
  }
}
