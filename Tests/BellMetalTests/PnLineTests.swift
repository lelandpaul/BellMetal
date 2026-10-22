import Foundation
import Testing
@testable import BellMetal

@Suite("PlaceNotation lines and leadhead transposition")
struct PlaceNotationLineTests {
  let pb4 = PlaceNotation("x4x4,2")

  @Test("line(for:) gives a bell's position in every row of the lead, first and last rows included")
  func lineOneLead() {
    #expect(pb4.line(for: .b1) == [1, 2, 3, 4, 4, 3, 2, 1, 1])
    #expect(pb4.line(for: .b2) == [2, 1, 1, 2, 3, 4, 4, 3, 4])
  }

  @Test("line(for:leads:) continues the line through later leads")
  func lineSeveralLeads() {
    let line = pb4.line(for: .b1, leads: 3)
    #expect(line.count == 3 * pb4.count + 1)
    #expect(Array(line.prefix(9)) == [1, 2, 3, 4, 4, 3, 2, 1, 1])
    #expect(Array(line.suffix(9)) == [1, 2, 3, 4, 4, 3, 2, 1, 1])
    #expect(pb4.line(for: .b2, leads: 3).last == 2)
  }

  @Test("line(for:) is empty for a bell that isn't on the notation's stage")
  func lineBellAboveStage() {
    #expect(pb4.line(for: .b5) == [])
    #expect(pb4.line(for: .bN) == [])
  }

  @Test("Row * PlaceNotation transposes the row by the notation's leadhead")
  func rowTimesNotation() {
    #expect(Stage.minimus.rounds * pb4 == "1342")
    let row: Row = "2143"
    #expect(row * pb4 == row * pb4.leadhead)
    let wide = PlaceNotation("N:x1Nx1N,12")
    let backrounds = Row(Array(Stage.twentyFour.allBells.reversed()))
    #expect(backrounds * wide == backrounds * wide.leadhead)
  }
}
