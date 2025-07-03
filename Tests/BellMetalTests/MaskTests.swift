import Foundation
import Testing
@testable import BellMetal

@Suite("MaskTests")
struct MaskTests {
  @Test func matching() throws {
    let noOpenPos: Mask = "1243"
    #expect(noOpenPos.matches("1243"))
    #expect(!noOpenPos.matches("1234"))
    #expect(!noOpenPos.matches("2143"))
    
    let onlyTreble: Mask = "1xxx"
    #expect(onlyTreble.matches("1234"))
    #expect(onlyTreble.matches("1423"))
    #expect(!onlyTreble.matches("2134"))
    #expect(!onlyTreble.matches("2314"))
    #expect(!onlyTreble.matches("2341"))
    
    let onlyTenor: Mask = "x4xx"
    #expect(!onlyTenor.matches("1234"))
    #expect(!onlyTenor.matches("1243"))
    #expect(onlyTenor.matches("1423"))
    #expect(onlyTenor.matches("2431"))
    #expect(!onlyTenor.matches("4123"))
  }
  
  @Test func description() {
    let test: Mask = "1xx2xx38"
    #expect(test.description == "1xx2xx38")
  }
}

@Suite
struct RowGenTests {
  @Test func allFixed() {
    let mask: Mask = "1234"
    let rows = mask.allMatchingRows().collect()
    #expect(rows == ["1234"])
  }
  
  @Test func noneFixed() {
    let mask: Mask = "xxxx"
    let rows = mask.allMatchingRows().collect()
    #expect(rows.count == 24)
    #expect(Set(rows).count == 24)
  }
  
  @Test func someFixed() {
    let mask: Mask = "12xx"
    let rows = mask.allMatchingRows().collect()
    #expect(rows == [
      "1234",
      "1243"
    ])
  }
}
