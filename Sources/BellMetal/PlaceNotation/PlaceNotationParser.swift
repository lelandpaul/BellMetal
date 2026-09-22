import Foundation

// MARK: - Splitting

/// The individual parsing steps behind ``PlaceNotation``'s string
/// initializer, exposed for building custom tooling (editors, validators,
/// etc.) around place notation text. Most callers should just use
/// ``PlaceNotation`` directly.
public enum PlaceNotationParser {
  
  // `\d` only matches 0-9; place characters above bell 10 use E,T,A,B,C,D
  // (see interpretPlace/representPlace), so they must be included explicitly
  // or a compound change like "1T" gets split into "1" with the "T" silently lost.
  nonisolated(unsafe)
  private static let changeRegex: Regex = /([0-9ETABCD]+|x|-)/
  
  /// Given a non-symmetric PN string, extract individual changes.
  /// Throws `.invalidPlaceNotation` if any character in `pn` isn't part of a
  /// recognized token (a place run, "x", or "-") or the "." separator
  /// between tokens -- e.g. an unrecognized character like "Z" would
  /// otherwise be silently skipped by the tokenizer instead of being
  /// reported.
  public static func splitToChanges(_ pn: String) throws -> [String] {
    var tokens: [String] = []
    var consumedUpTo = pn.startIndex
    for match in pn.matches(of: changeRegex) {
      let gap = pn[consumedUpTo..<match.range.lowerBound]
      guard gap.allSatisfy({ $0 == "." }) else {
        throw BellMetalError.invalidPlaceNotation
      }
      tokens.append(String(match.0))
      consumedUpTo = match.range.upperBound
    }
    guard pn[consumedUpTo...].allSatisfy({ $0 == "." }) else {
      throw BellMetalError.invalidPlaceNotation
    }
    return tokens
  }

  /// Split palindromic sections
  private static func splitPalindrome(_ pn: String) -> [String] {
    pn.split(separator: ",").map(String.init)
  }

  /// Splits a place notation string into individual changes, expanding any
  /// comma-separated palindromic sections along the way (see
  /// ``PlaceNotation`` for the palindrome syntax). Throws
  /// `.invalidPlaceNotation` if any section contains an unrecognized
  /// character (see `splitToChanges`).
  public static func splitAndExpandPalindrome(_ pn:String) throws -> [String] {
    guard pn.contains(",") else {
      return try splitToChanges(pn)
    }
    return try splitPalindrome(pn).flatMap { segment in
      try splitToChanges(segment).makePalindrome()
    }
  }
}

extension Array {
  func makePalindrome() -> Self {
    self + self.dropLast(1).reversed()
  }
}

// MARK: - Interpretting individual changes

extension PlaceNotationParser {
  
  /// Converts a single place character to its place number, e.g. "T" to 12,
  /// using the same convention as `Bell`: "1"..."9", then "0", "E", "T", "A",
  /// "B", "C", "D" for places 10 through 16. Returns nil for any other character.
  public static func interpretPlace(_ value: Character) -> Int? {
    return switch value {
    case "1": 1
    case "2": 2
    case "3": 3
    case "4": 4
    case "5": 5
    case "6": 6
    case "7": 7
    case "8": 8
    case "9": 9
    case "0": 10
    case "E": 11
    case "T": 12
    case "A": 13
    case "B": 14
    case "C": 15
    case "D": 16
    default: nil
    }
  }
  
  /// Converts a place number to its single-character representation, e.g. 12
  /// to "T", using the same convention as `Bell`.
  /// - Precondition: `value` must be between 1 and 16, inclusive.
  public static func representPlace(_ value: UInt8) -> String {
    return switch value {
    case let x where x < 10: "\(x)"
    case 10: "0"
    case 11: "E"
    case 12: "T"
    case 13: "A"
    case 14: "B"
    case 15: "C"
    case 16: "D"
    default: fatalError("Invalid place: \(value)")
    }
  }

  /// Converts a place number to its single-character representation, e.g. 12
  /// to "T", using the same convention as `Bell`. Convenience overload of
  /// `representPlace(_:UInt8)` for callers working with `Int`, e.g. the
  /// place lists produced by `parsePlaces`/`inferExternalPlaces`.
  /// - Precondition: `value` must be between 1 and 16, inclusive.
  public static func representPlace(_ value: Int) -> String {
    representPlace(UInt8(value))
  }
  
  /// Converts a sequence of places to its string representation.
  /// Performs no validation that this represents a valid change.
  /// - Parameter values: The values to convert.
  /// - Returns: The place notation representation string.
  public static func representPlaces(_ values: [UInt8]) -> String {
    values.sorted().map(representPlace(_:)).joined()
  }
  
  /// Converts a sequence of places to its string representation.
  /// Performs no validation that this represents a valid change.
  /// Convenience overload for callers with Int.
  /// - Parameter values: The values to convert.
  /// - Returns: The place notation representation string.
  public static func representPlaces(_ values: [Int]) -> String {
    representPlaces(values.map { UInt8($0) })
  }

  /// Given a single change, return a list of places explicitly made.
  /// (Does not add implicit external places -- see `inferExternalPlaces`.)
  /// Throws `.invalidPlaceNotation` if the change contains an invalid character.
  public static func parsePlaces(_ change: String) throws -> [Int] {
    switch change {
    case "x", "-":
      return []
    default:
      return try change.map {
        guard let place = interpretPlace($0) else { throw BellMetalError.invalidPlaceNotation}
        return place
      }
    }
  }
  
  /// Infers a stage from a set of changes' explicit places, e.g. a change
  /// containing place 8 implies at least Major. Throws `.invalidPlaceNotation`
  /// if no stage can be inferred at all, e.g. from an all-cross notation like
  /// "x" -- that has no place numbers to infer anything from, and needs an
  /// explicit stage instead (see `getExplicitStage` or `PlaceNotation.init(string:at:)`).
  public static func inferStage(_ changes: [[Int]]) throws -> Stage {
    let maxPlace = changes
      .compactMap { $0.max() }
      .max() ?? 0
    guard maxPlace > 0 && maxPlace < 16 else {
      throw BellMetalError.invalidPlaceNotation
    }
    let containsCrossChange = changes.contains([])
    let evenMaxPlace = maxPlace.isMultiple(of: 2)
    if containsCrossChange && !evenMaxPlace {
      return Stage(maxPlace + 1)
    }
    return Stage(maxPlace)
  }
  
  /// Adds the implicit places a change gets by convention: place 1 if the
  /// lowest explicit place is even, and the last place if the highest
  /// explicit place doesn't already share the stage's parity.
  public static func inferExternalPlaces(_ change: [Int], at stage: Stage) -> [Int] {
    guard change.count > 0 else {
      return switch stage.even {
      case true: []
      case false: [stage.count]
      }
    }
    var adjustedChange = change
    if change.first!.isMultiple(of: 2) {
      // Lowest place made is always odd, add 1st
      adjustedChange.insert(1, at: 0)
    }
    if change.last!.isMultiple(of: 2) != stage.even {
      // Highest place must be same parity as stage, add nth
      adjustedChange.append(stage.count)
    }
    return adjustedChange
  }

  /// Validates that a fully-resolved change (after `inferExternalPlaces`) is
  /// structurally well-formed: its places start on an odd-numbered position
  /// and strictly alternate odd/even thereafter. This is what guarantees
  /// every unlisted position -- before the first place, between two listed
  /// places, and after the last -- has an even number of bells left to pair
  /// up and cross. A change like `"128"` on Major (places 1, 2, 8) breaks
  /// this (2 and 8 are both even, back to back) and must be rejected rather
  /// than silently accepted with place 3..7 crossing incorrectly.
  /// Throws `.invalidPlaceNotation` if the sequence doesn't alternate.
  public static func validateAlternatingParity(_ places: [Int]) throws {
    for (index, place) in places.enumerated() {
      let expectOdd = index.isMultiple(of: 2)
      let isOdd = !place.isMultiple(of: 2)
      guard isOdd == expectOdd else { throw BellMetalError.invalidPlaceNotation }
    }
  }
  

  /// Fully parses a place notation string (expanding palindromes and implicit
  /// places) into its stage and the explicit places held by each change, in
  /// order. Pass `stage` if it's known; otherwise it's inferred (see
  /// `inferStage`) and may throw if it can't be. Throws `.invalidPlaceNotation`
  /// if any resulting change isn't structurally valid (see
  /// `validateAlternatingParity`) -- e.g. `"128"` on Major, which has two
  /// even places (2 and 8) back to back.
  public static func parseAllPlaces(
    _ pn: String,
    at stage: Stage? = nil
  ) throws -> (Stage, [[Int]]) {
    let changes = try splitAndExpandPalindrome(pn)
      .map(parsePlaces)
    let knownStage = try stage ?? inferStage(changes)
    let adjustedChanges = changes.map { inferExternalPlaces($0, at: knownStage) }
    try adjustedChanges.forEach(validateAlternatingParity)
    return (knownStage, adjustedChanges)
  }
  
  internal static func changeToRawRow(_ places: [Int], at stage: Stage) -> RawRow {
    var change = stage.rounds.row
    var i = 0
    while i < stage.count - 1 {
      if places.contains(i+1) {
        i += 1
      } else {
        change = change.swapUp(from: UInt8(i))
        i += 2
      }
    }
    return change
  }
  
  /// Parses an explicit stage prefix off the front of a place notation string,
  /// e.g. "6:12" (Minor) or "T:x1T" (Maximus, using the same single-character
  /// convention as `Bell`: "1"..."9", then "0", "E", "T", "A", "B", "C", "D"
  /// for stages 10 through 16). Returns `(nil, pn)` unchanged if there's no
  /// "stage:" prefix at all.
  public static func getExplicitStage(_ pn: String) throws -> (Stage?, String) {
    guard pn.contains(":") else { return (nil, pn) }
    let splits = pn.split(separator: ":")
    guard splits.count == 2,
          let stageStr = splits.first,
          let pnStr = splits.last,
          stageStr.count == 1,
          let stageCount = interpretPlace(stageStr[stageStr.startIndex])
    else { throw BellMetalError.invalidPlaceNotation }
    return (Stage(stageCount), String(pnStr))
  }
  
  internal static func parseAllChanges(
    _ pn: String,
    at stage: Stage? = nil
  ) throws -> (Stage, [RawRow]) {
    let (knownStage, places) = try parseAllPlaces(pn, at: stage)
    return (knownStage, places.map { changeToRawRow($0, at: knownStage) })
  }
}
