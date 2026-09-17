import Foundation

/// Errors thrown by BellMetal's throwing initializers and methods.
public enum BellMetalError: Error, Equatable {
  /// Two `Row`/`Block`/`PlaceNotation`/`Mask` values that were expected to
  /// share a stage don't.
  case stageMismatch
  /// A stage-changing operation (e.g. `Row.extend(to:)`) was given a stage
  /// that isn't valid for it, such as one that isn't actually higher.
  case invalidStage
  /// A place notation string couldn't be parsed, or its explicit stage
  /// conflicts with one given separately.
  case invalidPlaceNotation
  /// A mask string named a bell that isn't valid for its (inferred) stage.
  case invalidMask
  /// A bell number or character was out of range, or the bells given don't
  /// form a valid permutation.
  case invalidBell
  /// Reserved for scoring rows of inconsistent stages; not currently thrown
  /// anywhere, since `MusicType`/`MusicScheme` operate on a single `Block`.
  case inconsistentStageForMusic
  /// An index or range used to address into a `PlaceNotation`'s changes was
  /// out of bounds.
  case invalidIndex
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
    case .invalidIndex:
      "Invalid index."
    }
  }
}
