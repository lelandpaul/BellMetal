import Foundation
import Testing
@testable import BellMetal

@Suite("Stage unit tests")
struct StageTests {
  @Test("Every Stage case has its traditional English name as its description")
  func description() {
    #expect(Stage.one.description == "One")
    #expect(Stage.two.description == "Two")
    #expect(Stage.singles.description == "Singles")
    #expect(Stage.minimus.description == "Minimus")
    #expect(Stage.doubles.description == "Doubles")
    #expect(Stage.minor.description == "Minor")
    #expect(Stage.triples.description == "Triples")
    #expect(Stage.major.description == "Major")
    #expect(Stage.caters.description == "Caters")
    #expect(Stage.royal.description == "Royal")
    #expect(Stage.cinques.description == "Cinques")
    #expect(Stage.maximus.description == "Maximus")
    #expect(Stage.thirteen.description == "Thirteen")
    #expect(Stage.fourteen.description == "Fourteen")
    #expect(Stage.fifteen.description == "Fifteen")
    #expect(Stage.sixteen.description == "Sixteen")
  }

  @Test("init?(rawValue:) accepts exactly 0..<maxCount, matching init(_:)")
  func rawValueRange() {
    for count in 1...Stage.maxCount {
      #expect(Stage(rawValue: UInt8(count - 1)) == Stage(count))
    }
    #expect(Stage(rawValue: UInt8(Stage.maxCount)) == nil)
    #expect(Stage(rawValue: .max) == nil)
  }

  @Test("rounds on every stage matches the rounds string")
  func roundsEveryStage() {
    for count in 1...Stage.maxCount {
      let stage = Stage(count)
      let expected = String(stage.allBells.map(\.description).joined())
      #expect(stage.rounds.description == expected)
      #expect(stage.rounds.stage == stage)
    }
  }

  @Test("Stage stays a single byte")
  func layout() {
    #expect(MemoryLayout<Stage>.size == 1)
  }
}
