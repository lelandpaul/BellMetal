import Testing
@testable import BellMetal

@Suite("Blocks")
struct BlockTests {
  
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
    let rows = block.evaluate(at: Row4.rounds())
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
}
