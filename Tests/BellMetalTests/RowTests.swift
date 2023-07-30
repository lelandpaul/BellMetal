import XCTest
import Nimble
@testable import BellMetal


final class RowTests: XCTestCase {
  
  func testRowConstruction() {
    let row: RowD = "1234567890ETABCD"
    expect(row.description).to(equal("1234567890ETABCD"))
  }
  
  func testRowComposition() {
    let a: Row4 = "1324"
    let b: Row4 = "4321"
    expect(a*b).to(equal(Row4("4231")))
  }
  
  func testRowExponentiation() {
    let row: Row4 = "2341"
    expect(row ^ 2).to(equal(Row4("3412")))
    expect(row ^ 0).to(equal(Row4("1234")))
    expect(row ^ -1).to(equal(Row4("4123")))
    expect(row ^ -2).to(equal(Row4("3412")))
  }
  
  func testRounds() {
    expect(Row4.rounds()).to(equal(Row4("1234")))
    expect(RowT.rounds()).to(equal(RowT("1234567890ET")))
  }
}
