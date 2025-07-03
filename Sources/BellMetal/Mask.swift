import Foundation

/// Masks represent generalizations over rows at some stage.
/// E.g. a mask might represent all rows ending 78 on Major.
/// Masks are created through a string representation of the row
/// in which the "open" positions are replaced by "x"; e.g.
/// "xxxxxx78" represents all rows ending 78 on Major.
/// Masks can be `match`ed against some target row, or all matching
/// rows may be iterated over via `allMatchingRows()`.
struct Mask {
  let stage: Stage
  let fixedPos: [Int: Bell]
  
  internal init(stage: Stage, fixedPos: [Int : Bell]) {
    self.stage = stage
    self.fixedPos = fixedPos
  }
  
  init(_ string: String) throws {
    self.stage = Stage(string.count)
    var fixedPos: [Int: Bell] = [:]
    for (i, c) in string.enumerated() where c != "x" {
      let bell = Bell(c)
      guard self.stage.includes(bell) else { throw BellMetalError.invalidMask }
      fixedPos[i+1] = bell
    }
    self.fixedPos = fixedPos
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
  public init(stringLiteral value: StringLiteralType) {
    try! self.init(value)
  }
}

extension Mask: CustomStringConvertible {
  var description: String {
    (1...stage.count).map { i in
      fixedPos[i]?.description ?? "x"
    }.joined()
  }
}

extension Mask: Equatable, Hashable { }
