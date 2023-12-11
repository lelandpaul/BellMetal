import XCTest
import Nimble
@testable import BellMetal

final class UtilTests: XCTestCase {
  func testInterleave() {
    expect([1,2,3].interleave(with: [4,5,6]))
      .to(equal([1,4,2,5,3,6]))
    expect([1,2,3].interleave(with: [4,5,6,7,8]))
      .to(equal([1,4,2,5,3,6,7,8]))
    expect([1,2,3,7,8].interleave(with: [4,5,6]))
      .to(equal([1,4,2,5,3,6,7,8]))
  }
}
