import Foundation

// MARK: - Splitting

enum PlaceNotationParser {
  
  nonisolated(unsafe)
  private static let changeRegex: Regex = /(\d+|x|-)/
  
  /// Given a non-symmetric PN string, extract individual changes.
  internal static func splitToChanges(_ pn: String) -> [String] {
    pn.matches(of: changeRegex).map(\.0).map(String.init)
  }
  
  /// Split palindromic sections
  private static func splitPalindrome(_ pn: String) -> [String] {
    pn.split(separator: ",").map(String.init)
  }
  
  /// Split to changes and expand palindromic subsections.
  internal static func splitAndExpandPalindrome(_ pn:String) -> [String] {
    guard pn.contains(",") else {
      return splitToChanges(pn)
    }
    return splitPalindrome(pn).flatMap { segment in
      splitToChanges(segment).makePalindrome()
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
  
  private static func interpretPlace(_ value: Character) -> Int {
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
    default: fatalError("Invalid place: \(value)")
    }
  }
  
  /// Given a single change, return a list of places explicitly made. (Does not add implicit external places.)
  internal static func parsePlaces(_ change: String) -> [Int] {
    switch change {
    case "x", "-": []
    default: change.map(interpretPlace)
    }
  }
  
  internal static func inferStage(_ changes: [[Int]]) -> Stage {
    let maxPlace = changes
      .compactMap { $0.max() }
      .max() ?? 0
    precondition(maxPlace > 0 && maxPlace < 16, "Couldn't infer stage for place notation.")
    let containsCrossChange = changes.contains([])
    let evenMaxPlace = maxPlace.isMultiple(of: 2)
    if containsCrossChange && !evenMaxPlace {
      
      return Stage(maxPlace + 1)
    }
    return Stage(maxPlace)
  }
  
  internal static func inferExternalPlaces(_ change: [Int], at stage: Stage) -> [Int] {
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
  

  internal static func parseAllChanges(_ pn: String) -> [[Int]] {
    let changes = splitAndExpandPalindrome(pn)
      .map(parsePlaces)
    let stage = inferStage(changes)
    return changes.map { inferExternalPlaces($0, at: stage)}
  }
}
