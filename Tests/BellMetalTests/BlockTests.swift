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
      "2413",
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
      "2413",
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
      "2143",
    ]
    let falseBlock: Block = [
      "1234",
      "1234",
    ]

    #expect(trueBlock.isTrue)
    #expect(!falseBlock.isTrue)
  }

  @Test("Two blocks are true against each other iff they share no rows")
  func multiBlockTruth() throws {
    let blockA: Block = [
      "1234",
      "2143",
    ]
    let blockB: Block = [
      "4321",
      "3412",
    ]
    let blockC: Block = [
      "1234",
      "1243",
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
      "3412",
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
      "1342",
    ]

    let pb4_expected_second_lead: Block = [
      "3124",
      "3214",
      "2341",
      "2431",
      "4213",
      "4123",
      "1432",
      "1423",
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
      "214356",
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

  @Test("Concatenating with += appends the other block's rows in place, as + does")
  func concatenateInPlace() {
    var block: Block = [
      "1234",
      "2143",
    ]
    let other: Block = [
      "2413",
      "4231",
    ]
    let expected = block + other
    block += other
    #expect(block == expected)
    #expect(block.count == 4)
    #expect(block.last == "4231")
  }

  @Test("isEmpty is false for a block with rows, and true for one without, in either row layout")
  func isEmpty() throws {
    let narrow: Block = ["1234"]
    #expect(!narrow.isEmpty)
    #expect(try Block([], at: .minimus).isEmpty)
    let wide = Block(Stage(24).rounds)
    #expect(Stage(24).usesWideLayout)
    #expect(!wide.isEmpty)
    #expect(try Block([], at: Stage(24)).isEmpty)
  }

  @Test("Block(_:at:) builds a block from a runtime array, and throws on a row of another stage")
  func initRowsAtStage() throws {
    let rows: [Row] = ["1234", "2143"]
    #expect(try Block(rows, at: .minimus) == ["1234", "2143"])
    #expect(throws: BellMetalError.stageMismatch) {
      try Block(rows, at: .doubles)
    }
    #expect(throws: BellMetalError.stageMismatch) {
      try Block(["1234", "12345"], at: .minimus)
    }
  }

  @Test("groupByStroke on a one-row block gives an empty half at the other stroke",
        arguments: [Stage.minimus, .twentyFour])
  func groupByStrokeOneRow(stage: Stage) {
    let block = Block(stage.rounds)
    let hand = block.groupByStroke()
    #expect(Array(hand.hand) == [stage.rounds])
    #expect(hand.back.isEmpty)
    #expect(hand.back.stage == stage)
    let back = block.groupByStroke(backstrokeStart: true)
    #expect(back.hand.isEmpty)
    #expect(Array(back.back) == [stage.rounds])
  }

  @Test("Empty blocks of different stages aren't equal, so equality agrees with hashing")
  func emptyBlocksEqualityAndHash() throws {
    let minimus = try Block([], at: .minimus)
    let minor = try Block([], at: .minor)
    #expect(minimus != minor)
    #expect(minimus == (try Block([], at: .minimus)))
    #expect(minimus.hashValue == (try Block([], at: .minimus)).hashValue)
  }

  @Test("append() with no rows returns the block unchanged")
  func appendNothing() throws {
    let block: Block = ["1234", "2143"]
    #expect(try block.append() == block)
  }
}
