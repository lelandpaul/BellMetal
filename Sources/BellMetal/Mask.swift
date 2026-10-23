import Foundation

/// Masks represent generalizations over rows at some stage.
/// E.g. a mask might represent all rows ending 78 on Major.
/// Masks are created through a string representation of the row
/// in which the "open" positions are replaced by "x"; e.g.
/// "xxxxxx78" represents all rows ending 78 on Major.
/// Masks can be `match`ed against some target row, or all matching
/// rows may be iterated over via `allMatchingRows()`.
public struct Mask: Sendable {
  /// The stage of the rows this mask can match.
  public let stage: Stage
  let fixedPos: [Int: Bell]

  internal init(stage: Stage, fixedPos: [Int: Bell]) {
    self.stage = stage
    self.fixedPos = fixedPos
  }

  /// Creates a mask from its string representation, e.g. "xxxxxx78": one
  /// character per position, either "x" (open) or a bell. The string's
  /// length sets the stage.
  /// - Throws: `BellMetalError.invalidMask` if the length isn't
  ///   1...`Stage.maxCount`, a character is neither "x" nor a bell of that
  ///   stage, or the same bell is fixed in two positions.
  public init(string: String) throws {
    guard (1...Stage.maxCount).contains(string.count) else { throw BellMetalError.invalidMask }
    self.stage = Stage(string.count)
    var fixedPos: [Int: Bell] = [:]
    for (i, c) in string.enumerated() where c != "x" {
      guard let bell = Bell(character: c),
            self.stage.includes(bell),
            !fixedPos.values.contains(bell)
      else { throw BellMetalError.invalidMask }
      fixedPos[i+1] = bell
    }
    self.fixedPos = fixedPos
  }

  /// Creates a mask with every position fixed to the given row's, so it
  /// matches that row only.
  public init(_ row: Row) {
    self.stage = row.stage
    self.fixedPos = (1...stage.count).reduce(into: [:]) { dict, new in
      dict[new] = row[new]
    }
  }
  
  /// Checks whether a given row matches this mask.
  /// - Parameter row: The row to check.
  /// - Returns: True if the row matches. Always false
  /// if the row is a different stage from the mask.
  public func matches(_ row: Row) -> Bool {
    guard row.stage == stage else { return false }
    return fixedPos.allSatisfy { i, bell in
      row[i] == bell
    }
  }
}

extension Mask: ExpressibleByStringLiteral {
  /// Creates a mask from its string representation, e.g. "xxxxxx78".
  /// - Precondition: the string must be a valid mask -- see `init(string:)`
  /// for the throwing equivalent, which is safe to use on untrusted input.
  public init(stringLiteral value: StringLiteralType) {
    do {
      try self.init(string: value)
    } catch {
      preconditionFailure("Invalid mask literal \"\(value)\": \(error)")
    }
  }
}

extension Mask: CustomStringConvertible {
  /// The string representation of this mask, e.g. "xxxxxx78".
  public var description: String {
    (1...stage.count).map { i in
      fixedPos[i]?.description ?? "x"
    }.joined()
  }
}

extension Mask: Equatable, Hashable { }

// MARK: - Codable

extension Mask: Codable {
  /// Encodes/decodes as its string representation (e.g. "1xx2xx38"), not the
  /// internal fixedPos dictionary.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    do {
      try self.init(string: string)
    } catch {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid Mask: \(string)")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}

extension Block {
  /// Return rows matching at least one of the supplied masks.
  /// - Parameter masks: The masks to match against. If empty, no row matches.
  /// - Returns: Rows that match at least one mask.
  /// - Throws: `BellMetalError.stageMismatch` if any mask's stage isn't the block's.
  public func matching(any masks: [Mask]) throws -> [Row] {
    guard masks.allSatisfy({ $0.stage == self.stage }) else {
      throw BellMetalError.stageMismatch
    }
    return self.filter { row in
      masks.contains { $0.matches(row) }
    }
  }

  /// A count of rows matching at least one of the supplied Masks.
  /// - Parameter masks: Masks to match against. If empty, no row matches.
  /// - Returns: An integer count of rows.
  /// - Throws: `BellMetalError.stageMismatch` if any mask's stage isn't the block's.
  public func count(matchingAny masks: [Mask]) throws -> Int {
    guard masks.allSatisfy({ $0.stage == self.stage }) else {
      throw BellMetalError.stageMismatch
    }
    return self.count { row in
      masks.contains { $0.matches(row) }
    }
  }
}
