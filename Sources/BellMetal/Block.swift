import Foundation

/// A block of place notation, i.e. sequence of changes
struct Block<Stage: StageProtocol>: CustomStringConvertible {
  static var stage: Int { Stage.n }
  let pn: String // the place notation for this block
  let changes: [Change<Stage>] // the changes
  let row: Row<Stage>
  
  var description: String {
    "<\(pn) -> \(row)>"
  }
  
  /// Initialize from place notation
  /// - Parameter pn: place notation
  init(pn: String) {
    self.pn = pn
    self.changes = Self.splitPn(pn).map { Change(pn: $0) }
    self.row = changes.reduce(into: Row<Stage>.rounds()) { $0 = $0 * $1 }
  }
}

// MARK: PN Parsing
extension Block {
  /// Splits the place notation into strings representing
  /// individual changes.
  /// (Does not handle jump changes.)
  /// - Parameter pn: Some place notation
  /// - Returns: A sequence of strings representing
  ///   the individual changes.
  static func splitPn(_ pn: String) -> [String] {
    var result = [String]()
    var cur = [String]()
    for char in pn {
      if ["x", "-", ".", ","].contains(char) {
        if cur.count > 0 {
          result.append(cur.joined())
        }
        cur = []
      }
      if ["x", "-"].contains(char) {
        result.append(String(char))
        continue
      }
      if char == "," {
        result.append(contentsOf: result.dropLast().reversed())
        continue
      }
      if char != "." {
        cur.append(String(char))
      }
    }
    if cur.count > 0 {
      result.append(cur.joined())
    }
    return result
  }
}

// MARK: - Various conformances

extension Block: Equatable {
  static func == (lhs: Block, rhs: Block) -> Bool {
    lhs.pn == rhs.pn &&
    lhs.changes == rhs.changes
  }
}

extension Block: ExpressibleByStringLiteral {
  public init(stringLiteral value: StringLiteralType) {
    self.init(pn: value)
  }
}

// MARK: - Operators

extension Block {
  static public func *(lhs: Row<Stage>, rhs: Block<Stage>) -> Row<Stage> {
    lhs * rhs.row
  }
  
  static public func *(lhs: Block<Stage>, rhs: Block<Stage>) -> Row<Stage> {
    lhs.row * rhs.row
  }
  
  static public func +(lhs: Block<Stage>, rhs: Block<Stage>) -> Block<Stage> {
    Block<Stage>(pn: lhs.pn + rhs.pn)
  }
  
  static public func +(lhs: Block<Stage>, rhs: Change<Stage>) -> Block<Stage> {
    Block<Stage>(pn: lhs.pn + rhs.pn)
  }
  
  static public func +(lhs: Change<Stage>, rhs: Block<Stage>) -> Block<Stage> {
    Block<Stage>(pn: lhs.pn + rhs.pn)
  }
}

// MARK: - Evaluation

extension Block {
  public func evaluate(at row: Row<Stage>) -> RowBlock<Stage> {
    var result = [row]
    for change in self.changes {
      result.append(result.last! * change)
    }
    return RowBlock<Stage>(rows: result.dropFirst())
  }
  
  public func roundBlock(at row: Row<Stage> = Row<Stage>.rounds()) -> RowBlock<Stage> {
    var rows = self.evaluate(at: row)
    while rows.last != row {
      rows.extend(by: self)
    }
    return rows
  }
}

// MARK: - Aliases

typealias Block3 = Block<Singles>
typealias Block4 = Block<Minimus>
typealias Block5 = Block<Doubles>
typealias Block6 = Block<Minor>
typealias Block7 = Block<Triples>
typealias Block8 = Block<Major>
typealias Block9 = Block<Caters>
typealias Block0 = Block<Royal>
typealias BlockE = Block<Cinques>
typealias BlockT = Block<Maximus>
typealias BlockA = Block<Thirteen>
typealias BlockB = Block<Fourteen>
typealias BlockC = Block<Fifteen>
typealias BlockD = Block<Sixteen>
