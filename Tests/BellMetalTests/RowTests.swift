import Testing
@testable import BellMetal

@Suite("Rows")
struct RowTests {
  
  @Test("Construction") 
  func rowConstruction() async throws {
    let row: RowD = "1234567890ETABCD"
    #expect(row.description == "1234567890ETABCD")
  }
  
  @Test("Composition") 
  func rowComposition() async throws {
    let a: Row4 = "1324"
    let b: Row4 = "4321"
    #expect(a*b == "4231")
  }
  
  @Test("Exponentiation") 
  func rowExponentiation() async throws {
    let row: Row4 = "2341"
    #expect(row ^ 2 == "3412")
    #expect(row ^ 0 == "1234")
    #expect(row ^ -1 == "4123")
    #expect(row ^ -2 == "3412")
  }
  
  @Test("Rounds") 
  func rounds() async throws {
    #expect(Row4.rounds() == "1234")
    #expect(RowT.rounds() == "1234567890ET")
  }
  
  @Test("Generation")
  func rowGeneration() {
    #expect(Singles.rows.collect().count == 6)
    let minimusLeadheads = RowGenerator(matching: Mask4("1xxx")).collect()
    #expect(minimusLeadheads.rows.count == 6)
  }
  
}
