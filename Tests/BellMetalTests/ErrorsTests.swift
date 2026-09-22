import Foundation
import Testing
@testable import BellMetal

@Suite("Error-path unit tests")
struct ErrorsTests {

  // MARK: - Block

  @Test("isTrue(against:) throws on a stage mismatch between blocks")
  func blockIsTrueAgainstStageMismatch() {
    let a: Block = ["1234", "2143"] // minimus
    let b: Block = ["12345", "21345"] // doubles
    #expect(throws: BellMetalError.stageMismatch) {
      try a.isTrue(against: b)
    }
  }

  @Test("transpose(by:) throws when the transposing row is a different stage")
  func blockTransposeStageMismatch() {
    let block: Block = ["1234", "2143"] // minimus
    let row: Row = "12345" // doubles
    #expect(throws: BellMetalError.stageMismatch) {
      try block.transpose(by: row)
    }
  }

  @Test("extend(to:) throws when the target stage isn't strictly higher")
  func blockExtendInvalidStage() {
    let block: Block = ["12345678", "21436587"] // major
    #expect(throws: BellMetalError.invalidStage) {
      try block.extend(to: .major) // same stage, not strictly higher
    }
    #expect(throws: BellMetalError.invalidStage) {
      try block.extend(to: .minor) // lower stage
    }
  }

  @Test("concatenate(_:) throws on a stage mismatch between blocks")
  func blockConcatenateStageMismatch() {
    let a: Block = ["1234", "2143"]
    let b: Block = ["12345", "21345"]
    #expect(throws: BellMetalError.stageMismatch) {
      try a.concatenate(b)
    }
  }

  @Test("append(_:) throws when the appended row is a different stage")
  func blockAppendStageMismatch() {
    let block: Block = ["1234", "2143"]
    let wrongStageRow: Row = "12345"
    #expect(throws: BellMetalError.stageMismatch) {
      try block.append(wrongStageRow)
    }
  }

  // MARK: - Mask

  @Test("Mask(string:) throws when a letter is out of range for the inferred stage")
  func maskInitInvalidMask() {
    // 'D' (bell 16) isn't valid on a 3-bell stage (inferred from the string's length).
    #expect(throws: BellMetalError.invalidMask) {
      try Mask(string: "x1D")
    }
  }

  @Test("matching(any:) throws when a mask's stage disagrees with the block or another mask")
  func maskMatchingAnyStageMismatch() {
    let block: Block = ["1234", "2143"] // minimus
    let wrongStageMask: Mask = "12345" // doubles
    #expect(throws: BellMetalError.stageMismatch) {
      try block.matching(any: [wrongStageMask])
    }
    // Masks that are inconsistent with each other are also rejected.
    let mixedStageMasks: [Mask] = ["1234", "12345"]
    #expect(throws: BellMetalError.stageMismatch) {
      try block.matching(any: mixedStageMasks)
    }
  }

  @Test("count(matchingAny:) throws when a mask's stage disagrees with the block")
  func maskCountMatchingAnyStageMismatch() {
    let block: Block = ["1234", "2143"] // minimus
    let wrongStageMask: Mask = "12345" // doubles
    #expect(throws: BellMetalError.stageMismatch) {
      try block.count(matchingAny: [wrongStageMask])
    }
  }

  // MARK: - Row

  @Test("multiply(by:) throws on a stage mismatch between rows")
  func rowMultiplyStageMismatch() {
    let a: Row = "1234"
    let b: Row = "12345"
    #expect(throws: BellMetalError.stageMismatch) {
      try a.multiply(by: b)
    }
  }

  @Test("Row.extend(to:) throws when the target stage isn't strictly higher")
  func rowExtendInvalidStage() {
    let row: Row = "4321" // minimus
    #expect(throws: BellMetalError.invalidStage) {
      try row.extend(to: .minimus) // same stage, not strictly higher
    }
    #expect(throws: BellMetalError.invalidStage) {
      try row.extend(to: .singles) // lower stage
    }
  }

  // MARK: - PlaceNotation

  @Test("PlaceNotation init throws when the string's stage prefix conflicts with the `at:` parameter")
  func placeNotationExplicitStageConflict() {
    // "6:" declares Minor (6 bells); the `at:` parameter says Major -- they disagree.
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PlaceNotation(string: "6:14", at: .major)
    }
  }

  @Test("PlaceNotation init throws when a bare \"x\" carries no stage to infer")
  func placeNotationCannotInferStageFromBareCross() {
    // "x" alone carries no place numbers to infer a stage from, and none is given.
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PlaceNotation(string: "x")
    }
  }

  @Test("Regression: PlaceNotation throws on an unrecognized character instead of silently dropping it")
  func placeNotationThrowsOnUnrecognizedCharacters() {
    // The top-level tokenizer (PlaceNotationParser.splitToChanges) used to only
    // ever extract digit runs, "x", or "-", silently skipping any other
    // character (e.g. "Z") rather than throwing -- so "1Z3" parsed as two
    // separate one-place changes ("1", "3") instead of surfacing the
    // unrecognized "Z".
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PlaceNotation(string: "1Z3")
    }
  }

  @Test("Regression: a change whose places don't strictly alternate odd/even is rejected instead of silently mis-parsed")
  func placeNotationThrowsOnNonAlternatingPlaces() {
    // "128" on Major (places 1, 2, 8) has two even places (2, 8) back to
    // back with nothing alternating between them -- structurally invalid
    // place notation, since it leaves places 3-7 with no consistent way to
    // pair up and cross. This used to parse without error (both 1 and 8 are
    // already the stage's external places, so inferExternalPlaces had
    // nothing to add) and silently produce the wrong row.
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PlaceNotation(string: "128", at: .major)
    }
  }

  @Test("prick(at:) throws when the starting row is a different stage")
  func prickStageMismatch() throws {
    let pn = try PlaceNotation(string: "x4x4,2") // inferred Minimus
    let wrongStageRow: Row = "123456" // Minor
    #expect(throws: BellMetalError.stageMismatch) {
      try pn.prick(at: wrongStageRow)
    }
  }

  @Test("PlaceNotation.concatenate(with:) throws on a stage mismatch")
  func placeNotationConcatenateStageMismatch() throws {
    let minimus = try PlaceNotation(string: "x4x4,2")
    let doubles = try PlaceNotation(string: "12", at: .doubles)
    #expect(throws: BellMetalError.stageMismatch) {
      try minimus.concatenate(with: doubles)
    }
  }

  // MARK: - PlaceNotationParser

  @Test("parsePlaces(_:) throws on an unrecognized place character")
  func parsePlacesInvalidCharacter() {
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PlaceNotationParser.parsePlaces("1Z3")
    }
  }

  @Test("getExplicitStage(_:) throws on a malformed or invalid stage prefix")
  func explicitStagePrefixErrors() {
    typealias PNP = PlaceNotationParser
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PNP.getExplicitStage("12:34") // stage prefix must be a single character
    }
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PNP.getExplicitStage("x:34") // "x" isn't a place character, even though it's used in PN content
    }
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PNP.getExplicitStage("Z:34") // not a recognized place character at all
    }
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PNP.getExplicitStage("1:2:34") // only one colon is allowed
    }
  }
}
