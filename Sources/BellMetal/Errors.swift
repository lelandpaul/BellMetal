import Foundation

public enum BellMetalError: Error {
  case stageMismatch
  case invalidStage
  case invalidPlaceNotation
  case invalidMask
  case invalidBell
  case inconsistentStageForMusic
}

extension BellMetalError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .stageMismatch:
      "Stages don't match."
    case .invalidStage:
      "Invalid stage."
    case .invalidPlaceNotation:
      "Invalid place notation."
    case .invalidMask:
      "Invalid mask."
    case .invalidBell:
      "Invalid bell."
    case .inconsistentStageForMusic:
      "Music can only be assessed if the rows are of the same stage."
    }
  }
}
