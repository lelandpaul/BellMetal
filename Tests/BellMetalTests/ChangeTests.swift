import XCTest
import Nimble
@testable import BellMetal

final class ChangeTests: XCTestCase {
  
  func testChangeConstruction() {
    let cross: Change4 = "x"
    let hunt: Change4 = "14"
    
    expect(cross.places).to(equal([]))
    expect(hunt.places).to(equal([1,4]))
    
    expect(cross.row).to(equal(Row4("2143")))
    expect(hunt.row).to(equal(Row4("1324")))
  }
  
  func testChangeComposition() {
    let backrounds: Row4 = "4321"
    let cross: Change4 = "x"
    let hunt: Change4 = "14"
    
    expect(backrounds * cross).to(equal(Row4("3412")))
    expect(cross * hunt).to(equal(Row4("2413")))
  }
}
