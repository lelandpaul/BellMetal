import XCTest
import Nimble
@testable import BellMetal

final class MaskTests: XCTestCase {
  
  func testEquality() {
    expect(Mask6("xxx456"))
      .to(equal(Mask("xxx456")))
  }
  
  func testMatching() {
    let mask: Mask6 = "1x6xxx"
    expect(mask.matches(Row6("126345"))).to(beTrue())
    expect(mask.matches(Row6("621345"))).to(beFalse())
  }
  
  func testFill() throws {
    let mask: Mask6 = "1x6xxx"
    expect(try mask.fill(with: [.b2, .b3, .b4, .b5]))
      .to(equal(Row6("126345")))
  }
  
  func testTenorsTogetherMasks() {
    let expected: [Mask8] = [
      "178xxxxx",
      "18x7xxxx",
      "1x7x8xxx",
      "1xx8x7xx",
      "1xxx7x8x",
      "1xxxx8x7",
      "1xxxxx78"
    ]
    expect(Set(Major.tenorsTogetherLeadheadMasks))
      .to(equal(Set(expected)))
  }
  
  func testTenorsTogetherRows() {
    var rows = [Row8]()
    for row in Major.tenorsTogetherLeadheads {
      rows.append(row as! Row8)
    }
    expect(rows.count).to(equal(840))
    expect(Set(rows).count).to(equal(840))
    expect(rows.allSatisfy { $0.isTenorsTogether ?? false })
      .to(beTrue())
  }
}
