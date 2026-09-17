import Foundation
import Testing
@testable import BellMetal

@Suite("Error-path unit tests")
struct ErrorsTests {

  // MARK: - Block

  @Test func blockIsTrueAgainstStageMismatch() {
    let a: Block = ["1234", "2143"] // minimus
    let b: Block = ["12345", "21345"] // doubles
    #expect(throws: BellMetalError.stageMismatch) {
      try a.isTrue(against: b)
    }
  }

  @Test func blockTransposeStageMismatch() {
    let block: Block = ["1234", "2143"] // minimus
    let row: Row = "12345" // doubles
    #expect(throws: BellMetalError.stageMismatch) {
      try block.transpose(by: row)
    }
  }

  @Test func blockExtendInvalidStage() {
    let block: Block = ["12345678", "21436587"] // major
    #expect(throws: BellMetalError.invalidStage) {
      try block.extend(to: .major) // same stage, not strictly higher
    }
    #expect(throws: BellMetalError.invalidStage) {
      try block.extend(to: .minor) // lower stage
    }
  }

  @Test func blockConcatenateStageMismatch() {
    let a: Block = ["1234", "2143"]
    let b: Block = ["12345", "21345"]
    #expect(throws: BellMetalError.stageMismatch) {
      try a.concatenate(b)
    }
  }

  @Test func blockAppendStageMismatch() {
    let block: Block = ["1234", "2143"]
    let wrongStageRow: Row = "12345"
    #expect(throws: BellMetalError.stageMismatch) {
      try block.append(wrongStageRow)
    }
  }

  // MARK: - Mask

  @Test func maskInitInvalidMask() {
    // 'D' (bell 16) isn't valid on a 3-bell stage (inferred from the string's length).
    #expect(throws: BellMetalError.invalidMask) {
      try Mask("x1D")
    }
  }

  @Test func maskMatchingAnyStageMismatch() {
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

  @Test func maskCountMatchingAnyStageMismatch() {
    let block: Block = ["1234", "2143"] // minimus
    let wrongStageMask: Mask = "12345" // doubles
    #expect(throws: BellMetalError.stageMismatch) {
      try block.count(matchingAny: [wrongStageMask])
    }
  }

  // MARK: - Row

  @Test func rowMultiplyStageMismatch() {
    let a: Row = "1234"
    let b: Row = "12345"
    #expect(throws: BellMetalError.stageMismatch) {
      try a.multiply(by: b)
    }
  }

  @Test func rowExtendInvalidStage() {
    let row: Row = "4321" // minimus
    #expect(throws: BellMetalError.invalidStage) {
      try row.extend(to: .minimus) // same stage, not strictly higher
    }
    #expect(throws: BellMetalError.invalidStage) {
      try row.extend(to: .singles) // lower stage
    }
  }

  // MARK: - PlaceNotation

  @Test func placeNotationExplicitStageConflict() {
    // "6:" declares Minor (6 bells); the `at:` parameter says Major -- they disagree.
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PlaceNotation("6:14", at: .major)
    }
  }

  @Test func placeNotationSilentlyDropsUnrecognizedCharacters() {
    // NOTE: this documents a real gap, not desired behavior. The top-level tokenizer
    // (PlaceNotationParser.changeRegex) only ever extracts digit runs, "x", or "-";
    // any other character (e.g. "Z") is silently skipped rather than causing a throw,
    // even though PlaceNotationParser.parsePlaces itself validates individual
    // characters correctly when called directly (see parsePlacesInvalidCharacter).
    // So "1Z3" parses as two separate one-place changes ("1", "3") instead of
    // throwing .invalidPlaceNotation for the unrecognized "Z".
    let pn = try? PlaceNotation("1Z3")
    #expect(pn != nil)
  }

  @Test func prickStageMismatch() throws {
    let pn = try PlaceNotation("x4x4,2") // inferred Minimus
    let wrongStageRow: Row = "123456" // Minor
    #expect(throws: BellMetalError.stageMismatch) {
      try pn.prick(at: wrongStageRow)
    }
  }

  @Test func placeNotationConcatenateStageMismatch() throws {
    let minimus = try PlaceNotation("x4x4,2")
    let doubles = try PlaceNotation("12", at: .doubles)
    #expect(throws: BellMetalError.stageMismatch) {
      try minimus.concatenate(with: doubles)
    }
  }

  // MARK: - PlaceNotationParser

  @Test func parsePlacesInvalidCharacter() {
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PlaceNotationParser.parsePlaces("1Z3")
    }
  }

  @Test func explicitStagePrefixErrors() {
    typealias PNP = PlaceNotationParser
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PNP.getExplicitStage("12:34") // stage prefix must be a single character
    }
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PNP.getExplicitStage("0:34") // stage number must be >= 1
    }
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PNP.getExplicitStage("A:34") // stage prefix must be numeric
    }
    #expect(throws: BellMetalError.invalidPlaceNotation) {
      try PNP.getExplicitStage("1:2:34") // only one colon is allowed
    }
  }
}
