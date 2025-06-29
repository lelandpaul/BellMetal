import Foundation
import Testing
@testable import BellMetal

@Suite("Unit tests for the PlaceNotation class")
struct PlaceNotationTests {
  let pb4 = PlaceNotation("x4x4,2")
  let london6 = PlaceNotation("36-3.4-2-3.4-4.3,2")
  let pb4_first_lead: Block = [
    "1234",
    "2143",
    "2413",
    "4231",
    "4321",
    "3412",
    "3142",
    "1324",
    "1342"
  ]
  

  @Test func representation() async throws {
    #expect(pb4.description == "x14x14,12")
    
    #expect(london6.description == "36x36.14x12x36.14x14.36,12")
    
    let asym = PlaceNotation("5.3.1.3.1")
    #expect(asym.description == "5.3.1.3.1")
  }
  
  @Test func prickRowsCorrectly() async throws {
    let pb4_no_first: Block = Block(Array(pb4_first_lead.dropFirst()))
    let pb4_no_last: Block = Block(Array(pb4_first_lead.dropLast()))
    let pb4_neither: Block = Block(Array(pb4_no_first.dropLast()))

    #expect(try pb4.prick() == pb4_no_first)
    #expect(try pb4.prick(keeping: .keepInitial) == pb4_no_last)
    #expect(try pb4.prick(keeping: .keepNeither) == pb4_neither)
    #expect(try pb4.prick(keeping: .keepBoth) == pb4_first_lead)
  }
  
  @Test func startingRow() async throws {
    let pricked = try pb4.prick(at: "4321")
    let expected: Block = [
      "3412",
      "3142",
      "1324",
      "1234",
      "2143",
      "2413",
      "4231",
      "4213"
    ]
    
    #expect(pricked == expected)
  }
  
  @Test func repeatTimes() async throws {
    let pb4_second_lead = Block(Array(try pb4_first_lead.transpose(by: pb4_first_lead.last!).dropFirst()))
    let first_two_leads = Block(Array((pb4_first_lead + pb4_second_lead).dropFirst()))
    
    let pricked = try pb4.prick(repeat: .times(2))
    
    #expect(pricked == first_two_leads)
  }
  
  @Test func repeatRound() async throws {
    let all_pb4 = try pb4.prick(repeat: .untilRound)
    #expect(all_pb4.isTrue)
    #expect(all_pb4.count == 24)
  }
  
  @Test func repeatFalse() async throws {
    let x = PlaceNotation("x", at: .minimus)
    let pricked = try x.prick(repeat: .untilFalse)
    #expect(pricked == ["2143", "1234"])
    
    let longer: PlaceNotation = "x14xx"
    let longerPricked = try longer.prick(repeat: .untilFalse)
    #expect(longerPricked == ["2143", "2413", "4231", "2413"])
  }
  
  @Test func repeatPosition() async throws {
    let wrong = try pb4.prick(repeat: .untilPosition(bell: .b4, position: 3))
    let before = try pb4.prick(repeat: .untilPosition(bell: .b4, position: 2))
    let home = try pb4.prick(repeat: .untilPosition(bell: .b4, position: 4))
    #expect(wrong.count == 8)
    #expect(before.count == 16)
    #expect(home.count == 24)
  }
}
