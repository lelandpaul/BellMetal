import Foundation
import Testing
@testable import BellMetal

@Suite("Block unit tests")
struct BlockTests {
  
  // MARK: Instantiation
  @Test func instantiateFromRowArray() {
    let block = Block([
      "1234",
      "2143",
      "2413"
    ])
    #expect(block.count == 3)
    #expect(block.uniqueCount == 3)
    #expect(block.first == "1234")
    #expect(block.last == "2413")
  }
  
  @Test func instantiateFromArrayLiteral() {
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
  
  @Test func instantiateFromRows() {
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
  @Test func singleBlockTruth() {
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
  
  @Test func multiBlockTruth() throws {
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
  
  @Test func testTranspose() throws {
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
  
  @Test func testTransposePb4() throws {
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
    
    let pb4_second_lead: Block = try pb4_first_lead.transpose(by: pb4_first_lead.last!)
    
    #expect(pb4_second_lead == pb4_expected_second_lead)
  }
  
  @Test func testExtend() throws {
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
  
  @Test func testConcatenate() throws {
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
  
  @Test func testAppend() throws {
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
