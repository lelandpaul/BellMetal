import Foundation

enum BellMetalError: Error {
  case stageMismatch
  case invalidStage
  case invalidPlaceNotation
  case invalidMask
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
    }
  }
}
