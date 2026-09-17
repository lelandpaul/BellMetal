import Foundation
import Testing
@testable import BellMetal

@Suite("Stage unit tests")
struct StageTests {
  @Test func description() {
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
}
