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
    #expect(Stage.seventeen.description == "Seventeen")
    #expect(Stage.twenty.description == "Twenty")
    #expect(Stage.twentyOne.description == "Twenty-One")
    #expect(Stage.twentyFour.description == "Twenty-Four")
    #expect(Stage.maxCount == 24)
    #expect(Stage(24) == .twentyFour)
  }

  @Test("init?(count:) accepts exactly 1...maxCount, matching init(_:)")
  func initCount() {
    for count in 1...Stage.maxCount {
      #expect(Stage(count: count) == Stage(count))
    }
    for count in [Int.min, -1, 0, Stage.maxCount + 1, Int.max] {
      #expect(Stage(count: count) == nil)
    }
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

  @Test("tenorPair is the two heaviest bells, in ringing order")
  func tenorPair() {
    #expect(Stage.two.tenorPair == (.b1, .b2))
    #expect(Stage.major.tenorPair == (.b7, .b8))
    #expect(Stage.sixteen.tenorPair == (.bC, .bD))
    #expect(Stage.seventeen.tenorPair == (.bD, .bF))
    #expect(Stage.twentyFour.tenorPair == (.bM, .bN))
  }

  @Test("includes(_:) is true up to the tenor and false above it")
  func includes() {
    for count in 1...Stage.maxCount {
      let stage = Stage(count)
      #expect(stage.includes(.b1))
      #expect(stage.includes(stage.tenor))
      if let above = Bell(number: count + 1) {
        #expect(!stage.includes(above))
      }
    }
    #expect(!Stage.major.includes(.b9))
    #expect(Stage.twentyFour.includes(.bN))
  }

  @Test("even follows the number of bells")
  func even() {
    #expect(!Stage.one.even)
    #expect(Stage.two.even)
    #expect(!Stage.doubles.even)
    #expect(Stage.major.even)
    #expect(!Stage.twentyThree.even)
    #expect(Stage.twentyFour.even)
  }

  @Test("Stages and bells order from fewest bells and from the treble")
  func ordering() {
    #expect(Stage.one < .twentyFour)
    #expect(Stage.minor < .triples)
    #expect(!(Stage.major < .major))
    #expect([Stage.royal, .one, .twentyFour, .minor].sorted() == [.one, .minor, .royal, .twentyFour])
    #expect(Bell.b1 < .bN)
    #expect(Bell.b0 < .bE)
    #expect(Bell.bT < .bA)
    let bells = Stage.twentyFour.allBells
    #expect(bells.reversed().sorted() == bells)
  }

  @Test("Stage stays a single byte")
  func layout() {
    #expect(MemoryLayout<Stage>.size == 1)
  }
}

@Suite("Stages above 16 through the public API")
struct ExtendedStageTests {
  @Test("Rows above 16 bells parse, describe, multiply and invert", arguments: 17...Stage.maxCount)
  func rows(count: Int) throws {
    let stage = Stage(count)
    let backrounds = try Row(validating: String(stage.rounds.description.reversed()))
    #expect(backrounds.stage == stage)
    #expect(backrounds.description == String(stage.rounds.description.reversed()))
    #expect(backrounds * backrounds == stage.rounds)
    #expect(backrounds.invert() == backrounds)
    #expect(backrounds[1] == stage.tenor)
    #expect(backrounds[stage.tenor] == 1)
  }

  @Test("Plain Bob pricks a plain course of the expected length on even stages above 16", arguments: [18, 20, 22, 24])
  func plainBob(count: Int) throws {
    let stage = Stage(count)
    let tenor = PlaceNotationParser.representPlace(count)
    // Plain Bob: "x1n" n/2 times, then lead end "12". A lead is 2n changes
    // and the plain course is n-1 leads.
    let leadPN = try PlaceNotation(string: String(repeating: "x1\(tenor)", count: count / 2) + ",12", at: stage)
    #expect(leadPN.count == 2 * count)
    let course = try leadPN.prick(repeat: .untilRound)
    #expect(course.count == 2 * count * (count - 1))
    #expect(course.last == stage.rounds)
    #expect(course.isTrue)
    #expect(leadPN.description.contains(tenor))
  }

  @Test("Place notation above 16 bells round-trips through its description")
  func notationRoundTrip() throws {
    for notation in ["x1Nx1Nx1N,12", "F:3.1.F.1.3", "x1Jx1J,1J"] {
      let pn = try PlaceNotation(string: notation)
      #expect(try PlaceNotation(string: pn.description, at: pn.stage) == pn, "\(notation)")
    }
  }

  @Test("Masks above 16 bells match, and over-long mask strings throw instead of crashing")
  func masks() throws {
    let mask = try Mask(string: String(repeating: "x", count: 20) + "KLMN")
    #expect(mask.stage == .twentyFour)
    #expect(mask.matches(Stage.twentyFour.rounds))
    #expect(!mask.matches(Stage.twentyThree.rounds))
    #expect(throws: BellMetalError.invalidMask) {
      try Mask(string: String(repeating: "x", count: 25))
    }
    #expect(throws: BellMetalError.invalidMask) {
      try Mask(string: "")
    }
  }
}
