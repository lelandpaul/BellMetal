import Testing
@testable import BellMetal

@Suite("Changes")
struct ChangeTests {
  let cross: Change4 = "x"
  let hunt: Change4 = "14"
  
  @Test
  func construction() async throws {
    #expect(cross.places == [])
    #expect(hunt.places == [1,4])
    
    #expect(cross.row == "2143")
    #expect(hunt.row == "1324")
  }
  
  @Test
  func composition() async throws {
    let backrounds: Row4 = "4321"
    
    #expect(backrounds * cross == "3412")
    #expect(cross * hunt == "2413")
    #expect(hunt * cross == "3142")
  }
}
