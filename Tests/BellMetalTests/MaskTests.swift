import Testing
@testable import BellMetal

@Suite("Masks")
struct MaskTests {
  
  @Test func equality() async {
    #expect(Mask6("xxx456") == Mask("xxx456"))
  }
  
  @Test func matching() async throws {
    let mask: Mask6 = "1x6xxx"
    #expect(mask.matches("126345"))
    #expect(!mask.matches("123456"))
    #expect(!mask.matches("216345"))
    #expect(!mask.matches("621345"))
  }
  
  @Test func fill() async throws {
    let mask: Mask6 = "1x6xxx"
    #expect(try mask.fill(with: [.b2, .b3, .b4, .b5]) == "126345")
  }
  
  @Test func tenorsTogetherMasks() async throws {
    let expected: Set<Mask8> = [
      "178xxxxx",
      "18x7xxxx",
      "1x7x8xxx",
      "1xx8x7xx",
      "1xxx7x8x",
      "1xxxx8x7",
      "1xxxxx78"
    ]
    #expect(Set(Major.tenorsTogetherLeadheadMasks) == expected)
  }
  
  @Test func tenorsTogetherRows() async throws {
    var rows = [Row8]()
    for row in Major.tenorsTogetherLeadheads {
      rows.append(row as! Row8)
    }
    #expect(rows.count == 840)
    #expect(Set(rows).count == 840)
    #expect(rows.allSatisfy { $0.isTenorsTogether ?? false} )
  }
}
