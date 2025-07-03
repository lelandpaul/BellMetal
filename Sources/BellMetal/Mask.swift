import Foundation

/// Masks represent generalizations over rows at some stage.
/// E.g. a mask might represent all rows ending 78 on Major.
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
  
  func matches(_ row: Row) -> Bool {
    fixedPos.allSatisfy { i, bell in
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
