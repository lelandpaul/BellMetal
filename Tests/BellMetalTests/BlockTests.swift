import Testing
@testable import BellMetal

@Suite("Blocks")
struct BlockTests {
  
  @Test("Basic properties")
  func basicProperties() async throws {
    #expect(Block4.stage == 4)
    #expect(Block4(pn: "x.12").description == "<x.12 -> 2134>")
  }
  
  @Test("Construct from raw changes")
  func constructFromChanges() async throws {
    let block: Block4 = Block4(changes: ["x", "12"])
    #expect(block == "x.12")
  }
  
  @Test("Asymmetric construction")
  func asymmetricConstruction() async throws {
    let block: Block4 = "x14.12"
    let expectedChanges: [Change4] = [
      "x",
      "14",
      "12"
    ]
    
    #expect(block.changes == expectedChanges)
    #expect(block.row == "2431")
  }
  
  @Test("Symmetric construction")
  func symmetricConstruction() async throws {
    let block: Block4 = "x14x14,12"
    let expectedChanges: [Change4] = [
      "x",
      "14",
      "x",
      "14",
      "x",
      "14",
      "x",
      "12"
    ]
    
    #expect(block.changes == expectedChanges)
    #expect(block.row == "1342")
  }
  
  @Test("Evaluation")
  func evaluation() async throws {
    let block: Block4 = "x14x14,12"
    let expectedRows = RowBlock4(rows: [
      "2143",
      "2413",
      "4231",
      "4321",
      "3412",
      "3142",
      "1324",
      "1342",
    ])
    
    #expect(block.evaluate(at: Row4.rounds()) == expectedRows)
    #expect(block.evaluate(at: Row4.rounds(), evalMode: .keepBoth) == RowBlock4(rows: [Row4.rounds()] + expectedRows))
    #expect(block.evaluate(at: Row4.rounds(), evalMode: .keepInitial) == RowBlock4(rows: [Row4.rounds()] + expectedRows[0..<7]))
  }
  
  @Suite("Block, row, & change arithmetic")
  struct ArithmeticTests {
    let testRow: Row4 = "4321"
    let testBlock1: Block4 = "x"
    let testBlock2: Block4 = "14"
    let testChange: Change4 = "12"
    
    @Test("Row * block")
    func rowTimesBlock() {
      #expect(testRow * testBlock1 == "3412")
      #expect(testRow * testBlock2 == "4231")
    }
    
    @Test("Block * block")
    func blockTimesBlock() {
      #expect(testBlock1 * testBlock2 == "2413")
      #expect(testBlock2 * testBlock1 == "3142")
    }
    
    @Test("Block + block")
    func blockPlusBlock() {
      #expect(testBlock1 + testBlock2 == "x.14")
      #expect(testBlock2 + testBlock1 == "14.x")
    }
    
    @Test("Block & change")
    func blockAndChange() {
      #expect(testBlock1 + testChange == "x.12")
      #expect(testChange + testBlock1 == "12.x")
    }
  }
  
  @Test("Round blocks")
  func roundBlocks() {
    let block: Block4 = "x14"
    #expect(block.roundBlock() == [
      "2143",
      "2413",
      "4231",
      "4321",
      "3412",
      "3142",
      "1324",
      "1234"
    ])
    
    #expect(block.roundBlock(at: "1243") == [
      "2134",
      "2314",
      "3241",
      "3421",
      "4312",
      "4132",
      "1423",
      "1243"
    ])
  }
  
  @Test("Rows with treble at position")
  func rowsWithTreble() {
    let block: Block4 = "x14x14x14x14"
    #expect(block.rowsWithTreble(at: 3) == ["2413", "3412"])
    #expect(block.rowsWithTreble(at: 5) == [])
  }
  
  @Test("Line from position")
  func lineFrom() {
    let block: Block4 = "x14x14x14x14"
    #expect(block.lineFrom(1) == [1, 2, 3, 4, 4, 3, 2, 1, 1])
    #expect(block.lineFrom(1, leads: 2) == [
      1, 2, 3, 4, 4, 3, 2, 1, 1,
         2, 3, 4, 4, 3, 2, 1, 1
    ])
    #expect(block.lineFrom(0) == [])
    #expect(block.lineFrom(5) == [])
  }
}
