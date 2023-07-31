import XCTest
import Nimble
@testable import BellMetal

final class BlockTests: XCTestCase {
  
  func testBlockConstruction() {
    let block: Block4 = "x14.12"
    
    let expectedChanges: [Change4] = [
      "x",
      "14",
      "12"
    ]
    
    expect(block.changes).to(equal(expectedChanges))
    expect(block.row).to(equal(Row4("2431")))
  }
  
  func testBlockConstructionWithSymmetry() {
    let block: Block4 = "x14x14,12"
    expect(block.row).to(equal(Row4("1342")))
  }
  
  func testApplication() {
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
    expect(rows).to(equal(expectedRows))
  }
}
