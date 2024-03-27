import Foundation

/// A block of place notation, i.e. sequence of changes
public struct Block<Stage: StageProtocol>: CustomStringConvertible {
  static var stage: Int { Stage.n }
  public let pn: String // the place notation for this block
  public let changes: [Change<Stage>] // the changes
  public let row: Row<Stage>
  
  public var description: String {
    "<\(pn) -> \(row)>"
  }
  
  /// Initialize from place notation
  /// - Parameter pn: place notation
  public init(pn: String) {
    self.pn = pn
    self.changes = Self.splitPn(pn).map { Change(pn: $0) }
    self.row = changes.reduce(into: Row<Stage>.rounds()) { $0 = $0 * $1 }
  }
  
  public init(changes: [Change<Stage>]) {
    self.changes = changes
    self.pn = changes.map({ $0.pn }).joined(separator: ".")
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
  public static func == (lhs: Block, rhs: Block) -> Bool {
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
  public static func *(lhs: Row<Stage>, rhs: Block<Stage>) -> Row<Stage> {
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
  public enum EvalMode {
    case keepInitial
    case keepFinal
    case keepBoth
  }
  
  public func evaluate(at row: Row<Stage>, evalMode: EvalMode = .keepFinal) -> RowBlock<Stage> {
    var result = [row]
    for change in self.changes {
      result.append(result.last! * change)
    }
    switch evalMode {
    case .keepInitial:
      return RowBlock<Stage>(rows: result.dropLast())
    case .keepFinal:
      return RowBlock<Stage>(rows: result.dropFirst())
    case.keepBoth:
      return RowBlock<Stage>(rows: result)
    }
  }
  
  public func roundBlock(at row: Row<Stage> = Row<Stage>.rounds()) -> RowBlock<Stage> {
    var rows = self.evaluate(at: row)
    while rows.last != row {
      rows.extend(by: self)
    }
    return rows
  }
  
  public func rowsWithTreble(at pos: Int) -> [Row<Stage>] {
    guard pos <= Stage.n else { return [] }
    return self.evaluate(at: Stage.rounds)
      .filter { $0.position(of: .b1) == pos }
  }
  
  /// Generates the line traced by a bell starting
  /// in a given position under this block.
  /// - Parameter bell: The starting position
  /// - Returns: A sequence representing the line (inclusive
  ///   of starting and ending positions)
  public func lineFrom(_ bell: Int, leads: Int = 1)
    -> [Int]
  {
    var result = [bell]
    for _ in 0 ..< leads {
      for change in changes {
        result.append(change.apply(result.last!))
      }
    }
    return result
  }
}

// MARK: - Aliases

public typealias Block3 = Block<Singles>
public typealias Block4 = Block<Minimus>
public typealias Block5 = Block<Doubles>
public typealias Block6 = Block<Minor>
public typealias Block7 = Block<Triples>
public typealias Block8 = Block<Major>
public typealias Block9 = Block<Caters>
public typealias Block0 = Block<Royal>
public typealias BlockE = Block<Cinques>
public typealias BlockT = Block<Maximus>
public typealias BlockA = Block<Thirteen>
public typealias BlockB = Block<Fourteen>
public typealias BlockC = Block<Fifteen>
public typealias BlockD = Block<Sixteen>
