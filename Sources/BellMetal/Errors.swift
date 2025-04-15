import Foundation

enum BellMetalError: Error {
  case stageMismatch
  case invalidStage
}

extension BellMetalError: CustomStringConvertible {
  var description: String {
    switch self {
    case .stageMismatch:
      "Stages don't match."
    case .invalidStage:
      "Invalid stage."
    }
  }
}
