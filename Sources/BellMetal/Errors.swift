import Foundation

enum BellMetalError: Error {
  case stageMismatch
  case invalidStage
  case invalidPlaceNotation
  case invalidMask
  case inconsistentStageForMusic
}

extension BellMetalError: CustomStringConvertible {
  var description: String {
    switch self {
    case .stageMismatch:
      "Stages don't match."
    case .invalidStage:
      "Invalid stage."
    case .invalidPlaceNotation:
      "Invalid place notation."
    case .invalidMask:
      "Invalid mask."
    case .inconsistentStageForMusic:
      "Music can only be assessed if the rows are of the same stage."
    }
  }
}
