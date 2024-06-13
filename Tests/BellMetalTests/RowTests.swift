import Testing
@testable import BellMetal

@Suite("Rows")
struct RowTests {
  
  @Test("Construction") 
  func rowConstruction() async throws {
    let row: RowD = "1234567890ETABCD"
    #expect(row.description == "1234567890ETABCD")
    #expect(throws: BellMetalError.invalidRow) {
      try Row4(row: "12345")
    }
  }
  
  @Test("Subscripting")
  func subscripting() async throws {
    let row: Row5 = "54321"
    #expect(row[1] == .b5)
    #expect(row[0] == nil)
    #expect(row[6] == nil)
  }
  
  @Test("Position of bell")
  func positionOfBell() async throws {
    let row: Row5 = "54321"
    #expect(row.position(of: .b3) == 3)
    #expect(row.position(of: .b6) == nil)
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

@Suite("RowBlocks")
struct RowBlockTests {
  let block: RowBlock4 = [
    "1234",
    "2143",
    "4321"
  ]

  @Test("Properties")
  func properties() async throws {
    #expect(block.first == "1234")
    #expect(block.last == "4321")
    #expect(block.description == "1234\n2143\n4321")
    #expect(block.count == 3)
    #expect(block[1] == "2143")
    #expect(block[1..<3] == ["2143","4321"])
  }
  
  @Test("Extending")
  func extending() async throws {
    var localBlock = block
    
    localBlock.extend(by: "x.12")
    #expect(localBlock == [
      "1234",
      "2143",
      "4321",
      "3412",
      "3421"
    ])
  }
  
  @Test("Truth")
  func truth() async throws {
    #expect(block.isTrue)
    #expect(!block.extended(by: "x.x").isTrue)
    #expect(block.isTrue(against: ["3412"]))
    #expect(!block.isTrue(against: ["1234"]))
  }
  
  @Test("Addition")
  func addition() async throws {
    #expect(block + RowBlock4(arrayLiteral: "1234") == [
      "1234",
      "2143",
      "4321",
      "1234",
    ])
  }
}
