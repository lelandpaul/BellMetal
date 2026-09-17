import Foundation
import Testing
@testable import BellMetal

@Suite("NamedRow unit tests")
struct NamedRowsTests {

  // MARK: - Trivial identities

  @Test func rounds() {
    #expect(NamedRow.rounds.row(at: .minor) == "123456")
    #expect(NamedRow.rounds.row(at: .major) == "12345678")
  }

  @Test func backrounds() {
    #expect(NamedRow.backrounds.row(at: .minor) == "654321")
    #expect(NamedRow.backrounds.row(at: .major) == "87654321")
  }

  // MARK: - Canonical named rows

  @Test func queens() {
    #expect(NamedRow.queens.row(at: .minor) == "135246")
    #expect(NamedRow.queens.row(at: .major) == "13572468")
  }

  @Test func kings() {
    #expect(NamedRow.kings.row(at: .minor) == "531246")
    #expect(NamedRow.kings.row(at: .major) == "75312468")
  }

  @Test func tittums() {
    #expect(NamedRow.tittums.row(at: .minor) == "142536")
    #expect(NamedRow.tittums.row(at: .major) == "15263748")
  }

  @Test func explodedTittums() {
    // half = (n+1)/2; upwards = reversed(1...half); downwards = (half+1...n); interleaved
    #expect(NamedRow.explodedtittums.row(at: .major) == "45362718")
  }

  @Test func intermediate() {
    // rounds with places 1 & n made, all other adjacent pairs swapped
    #expect(NamedRow.intermediate.row(at: .major) == "13254768")
  }

  // MARK: - Rows derived by relationship to queens/kings

  @Test func princesIsKingsWithFrontPairSwapped() {
    // Princes: Kings with the values 1 and 2 interchanged.
    let kings = NamedRow.kings.row(at: .major)!
    let princes = NamedRow.princes.row(at: .major)!
    #expect(princes == "75321468")
    // Every position not holding a 1 or 2 in Kings is unchanged in Princes.
    for pos in 1...8 {
      if kings[pos] != .b1 && kings[pos] != .b2 {
        #expect(princes[pos] == kings[pos])
      }
    }
  }

  @Test func princessesIsQueensWithMiddlePairSwapped() {
    // Princesses: Queens with positions half & half+1 (4 & 5 on Major) swapped.
    let queens = NamedRow.queens.row(at: .major)!
    let princesses = NamedRow.princesses.row(at: .major)!
    #expect(princesses == "13527468")
    #expect(princesses[4] == queens[5])
    #expect(princesses[5] == queens[4])
    for pos in [1, 2, 3, 6, 7, 8] {
      #expect(princesses[pos] == queens[pos])
    }
  }

  @Test func jokersIsJacksTimesIntermediate() {
    let jacks = NamedRow.jacks.row(at: .major)!
    let intermediate = NamedRow.intermediate.row(at: .major)!
    let jokers = NamedRow.jokers.row(at: .major)!
    #expect(jokers == jacks * intermediate)
  }

  // MARK: - Stage boundaries

  @Test func whittingtonsOnlyDefinedForMinorThroughRoyal() {
    #expect(NamedRow.whittingtons.row(at: .singles) == nil)
    #expect(NamedRow.whittingtons.row(at: .minimus) == nil)
    #expect(NamedRow.whittingtons.row(at: .doubles) == nil)
    #expect(NamedRow.whittingtons.row(at: .minor) != nil)
    #expect(NamedRow.whittingtons.row(at: .triples) != nil)
    #expect(NamedRow.whittingtons.row(at: .major) == "12753468")
    #expect(NamedRow.whittingtons.row(at: .caters) != nil)
    #expect(NamedRow.whittingtons.row(at: .royal) != nil)
    #expect(NamedRow.whittingtons.row(at: .cinques) == nil)
  }

  @Test func rollercoasterSeesawSawseeOnlyDefinedForMajor() {
    for row in [NamedRow.rollercoaster, .seesaw, .sawsee] {
      #expect(row.row(at: .minor) == nil)
      #expect(row.row(at: .triples) == nil)
      #expect(row.row(at: .major) != nil)
      #expect(row.row(at: .caters) == nil)
    }
    #expect(NamedRow.rollercoaster.row(at: .major) == "14327658")
    #expect(NamedRow.seesaw.row(at: .major) == "43215678")
    #expect(NamedRow.sawsee.row(at: .major) == "56781234")
  }

  @Test func hagdykeAndJacksDefinedFromDoublesUpward() {
    for stage: Stage in [.singles, .minimus] {
      #expect(NamedRow.hagdyke.row(at: stage) == nil)
      #expect(NamedRow.jacks.row(at: stage) == nil)
    }
    for stage: Stage in [.doubles, .minor, .triples, .major, .caters, .royal, .cinques, .maximus, .thirteen, .fourteen, .fifteen, .sixteen] {
      let hagdyke = NamedRow.hagdyke.row(at: stage)
      let jacks = NamedRow.jacks.row(at: stage)
      #expect(hagdyke?.stage == stage)
      #expect(jacks?.stage == stage)
    }
  }

  @Test func allCasesCount() {
    #expect(NamedRow.allCases.count == 16)
  }
}
