import Testing
@testable import BellMetal

@Suite("Changes")
struct ChangeTests {
  let cross: Change4 = "x"
  let hunt: Change4 = "14"
  
  @Test("Stage shortcut")
  func stageShortcut() async throws {
    #expect(Change4.stage == 4)
  }
  
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
  
  @Test
  func addition() {
    #expect(cross + hunt == "x14")
  }
  
  @Test
  func isDisjoint() async throws {
    let seconds: Change4 = "12"
    #expect(cross.isDisjoint(with: hunt))
    #expect(!seconds.isDisjoint(with: hunt))
    #expect(seconds.isDisjoint(with: "34"))
  }
}
