import Foundation
import Testing
@testable import BellMetal

@Suite("Place notation parsing unit tests")
struct PnParsingTests {
  typealias PNP = PlaceNotationParser
  
  @Test("splitToChanges tokenizes a notation string on \"x\" and place runs")
  func splitRightPlace() throws {
    let pn = "x12x14"
    let expected = ["x", "12", "x", "14"]
    #expect(try PNP.splitToChanges(pn) == expected)
  }

  @Test("splitToChanges tokenizes \".\" and \"-\" separators the same way as \"x\"")
  func splitWrongPlace() throws {
    let pn = "-12.34-"
    let expected = ["-", "12", "34", "-"]
    #expect(try PNP.splitToChanges(pn) == expected)
  }

  @Test("splitToChanges keeps digit/letter compound changes as a single token")
  func splitCompoundChangesWithLetterPlaces() throws {
    // Places above bell 10 use E,T,A,B,C,D (see interpretPlace/representPlace).
    // A compound change mixing digits and letters must stay one token.
    #expect(try PNP.splitToChanges("1E") == ["1E"])
    #expect(try PNP.splitToChanges("90ET") == ["90ET"])
    // A change consisting solely of a letter must not be dropped entirely.
    #expect(try PNP.splitToChanges("E") == ["E"])
    #expect(try PNP.splitToChanges("x1E.T4x") == ["x", "1E", "T4", "x"])
  }

  @Test("splitToChanges throws on an unrecognized character instead of silently dropping it")
  func splitToChangesThrowsOnUnrecognizedCharacter() {
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PNP.splitToChanges("1Z3")
    }
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      // Regression: on an even stage, silently dropping "n" from "12n" left
      // "12" -- a token that happens to parse without error (see
      // inferExternalPlaces), silently producing the wrong place list
      // instead of surfacing the unrecognized character.
      try PNP.splitToChanges("12n")
    }
  }

  @Test("parsePlaces resolves letter places (E, T, ...) to their bell numbers")
  func parsePlacesWithLetters() throws {
    #expect(try PNP.parsePlaces("1E") == [1, 11])
    #expect(try PNP.parsePlaces("90ET") == [9, 10, 11, 12])
  }

  @Test("Regression: letter places parse without losing made places to place inference")
  func placeNotationRoundTripWithLetterPlaces() throws {
    // Places 2, 11 (E), and 12 (T) made explicit on Maximus; inference adds
    // place 1 (since place 2 is even) leaving {1,2,11,12} made overall.
    // Before the tokenizer recognized letter places, "2E" parsed as "2" alone,
    // silently losing the made place at 11 and 12 and producing the wrong row.
    let pn = try PlaceNotation(string: "2E", at: .maximus)
    #expect(pn.leadhead == "1243658709ET")
  }

  @Test("makePalindrome mirrors an array about its last element")
  func palindromeHelper() {
    #expect([1,2,3].makePalindrome() == [1,2,3,2,1])
    #expect([1].makePalindrome() == [1])
  }
  
  @Test("splitAndExpandPalindrome expands a comma-separated palindromic notation into its full change list")
  func palindromeExpansion() throws {
    let pb = "x14x14,12"
    let expected_pb = ["x", "14", "x", "14", "x", "14", "x", "12"]
    #expect(try PNP.splitAndExpandPalindrome(pb) == expected_pb)

    let grandsire5 = "3,1.5.1.5.1"
    let expected_g5 = ["3", "1", "5", "1", "5", "1", "5", "1", "5", "1"]
    #expect(try PNP.splitAndExpandPalindrome(grandsire5) == expected_g5)

    let test = "x12,56.18"
    let expected_test = ["x","12","x","56","18","56"]
    #expect(try PNP.splitAndExpandPalindrome(test) == expected_test)
  }
  
  @Test("inferStage picks the smallest stage consistent with the given places")
  func inferStage() throws {
    let doubles = [[5],[1],[5],[1],[5]]
    #expect(try PNP.inferStage(doubles) == .doubles)
    let minor = [[1,2],[3,4],[5,6],[1,2]]
    #expect(try PNP.inferStage(minor) == .minor)
    let withCrossChange = [[],[5]]
    #expect(try PNP.inferStage(withCrossChange) == .minor)
  }

  @Test("inferStage throws when an all-cross change list carries no places to infer from")
  func inferStageThrowsWhenNoPlacesGiven() {
    // An all-cross set of changes carries no place numbers to infer from.
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PNP.inferStage([[], []])
    }
  }
  
  @Test("inferExternalPlaces adds the implied places at the stage's edges")
  func inferExternalPlaces() {
    #expect(PNP.inferExternalPlaces([4], at: .minor) == [1,4])
    #expect(PNP.inferExternalPlaces([3], at: .minor) == [3,6])
    #expect(PNP.inferExternalPlaces([2], at: .doubles) == [1,2,5])
    #expect(PNP.inferExternalPlaces([], at: .minor) == [])
    #expect(PNP.inferExternalPlaces([], at: .doubles) == [5])
  }
  
  @Test("parseAllPlaces parses a full notation string into its per-change place lists")
  func parseAllPlaces() throws {
    let pb4 = "x4x4,2"
    let pb4_places = [[],[1,4],[],[1,4],[],[1,4],[],[1,2]]
    #expect(try PNP.parseAllPlaces(pb4).1 == pb4_places)
    
    let g5 = "3,1.5.1.5.1"
    let g5_places = [[3],[1],[5],[1],[5],[1],[5],[1],[5],[1]]
    #expect(try PNP.parseAllPlaces(g5).1 == g5_places)
  }
  
  @Test("changeToRawRow converts a set of made places into the resulting row")
  func changeToRawRow() {
    let expectedX: Row = "21436587"
    let expected14: Row = "1324"
    let expected3: Row = "21354"
    #expect(PNP.changeToRawRow([], at: .major) == expectedX.row)
    #expect(PNP.changeToRawRow([1,4], at: .minimus) == expected14.row)
    #expect(PNP.changeToRawRow([3], at: .doubles) == expected3.row)
  }
  
  @Test("parseAllChanges parses a full notation string into its sequence of rows")
  func parseAllChanges() throws {
    let pb4 = "x4x4,2"
    let pb4_changes: [Row] = ["2143", "1324", "2143", "1324", "2143", "1324", "2143", "1243"]
    #expect(try PNP.parseAllChanges(pb4).1 == pb4_changes.map(\.row))
    
    let g5 = "3,1.5.1.5.1"
    let g5_changes: [Row] = ["21354", "13254", "21435", "13254", "21435", "13254", "21435", "13254", "21435", "13254"]
    #expect(try PNP.parseAllChanges(g5).1 == g5_changes.map(\.row))
  }
  
  @Test("PlaceNotation(string:) parses plain bob minimus and grandsire doubles correctly")
  func parsePN() throws {
    let pb4 = "x4x4,2"
    let pb4_changes: [Row] = ["2143", "1324", "2143", "1324", "2143", "1324", "2143", "1243"]
    let expectedPb4 = PlaceNotation(stage: .minimus, changes: pb4_changes.map(\.row))
    #expect(try PlaceNotation(string: pb4) == expectedPb4)

    let g5 = "3,1.5.1.5.1"
    let g5_changes: [Row] = ["21354", "13254", "21435", "13254", "21435", "13254", "21435", "13254", "21435", "13254"]
    let expectedG5 = PlaceNotation(stage: .doubles, changes: g5_changes.map(\.row))
    #expect(try PlaceNotation(string: g5) == expectedG5)
  }

  @Test("An explicit stage prefix sets the stage, and conflicting with `at:` fails parsing")
  func parsePNWithExplicitStage() throws {
    let lb6: PlaceNotation = "6:x4x4,2"
    #expect(try lb6 == PlaceNotation(string: "x4x4,2", at: .minor))

    let invalid: PlaceNotation? = try? PlaceNotation(string: "4:x4x4,2", at: .minor)
    #expect(invalid == nil)
  }

  @Test("The stage prefix accepts any bell-letter, not just digits 1 through 9")
  func explicitStageSupportsFullBellRange() throws {
    // The stage prefix uses the same one-character-per-bell convention as
    // Bell, so it can express any stage, not just 1 through 9.
    let royal: PlaceNotation = "0:34" // "0" = 10 (Royal)
    #expect(try royal == PlaceNotation(string: "34", at: .royal))

    let maximus: PlaceNotation = "T:x1T" // "T" = 12 (Maximus)
    #expect(try maximus == PlaceNotation(string: "x1T", at: .maximus))

    let sixteen: PlaceNotation = "D:x1D" // "D" = 16 (Sixteen)
    #expect(try sixteen == PlaceNotation(string: "x1D", at: .sixteen))
  }

  @Test("getExplicitStage parses every bell-letter prefix, or nil when there's no prefix")
  func getExplicitStageSupportsFullBellRange() throws {
    #expect(try PNP.getExplicitStage("6:12").0 == .minor)
    #expect(try PNP.getExplicitStage("0:34").0 == .royal)
    #expect(try PNP.getExplicitStage("E:34").0 == .cinques)
    #expect(try PNP.getExplicitStage("T:x1T").0 == .maximus)
    #expect(try PNP.getExplicitStage("D:x1D").0 == .sixteen)
    #expect(try PNP.getExplicitStage("no-prefix-here").0 == nil)
  }
}

