import Foundation

/// An ordered sequence of rows. Differs from [Row] in
/// enforcing a consistent stage and in keeping a Set
/// for quick truth-checking.
struct Block {
  let stage: Stage
  internal let rows: [RawRow]
  internal let rowSet: Set<RawRow>
  
  internal init(stage: Stage, rows: [RawRow], rowSet: Set<RawRow>) {
    self.stage = stage
    self.rows = rows
    self.rowSet = rowSet
  }
  
  init(_ rows: Row...) {
    self.init(Array(rows))
  }

  init(_ rows: [Row]) {
    precondition(!rows.isEmpty, "Cannot create empty Block.")
    precondition(Set(rows.map(\.stage)).count == 1, "Inconsistent Stages: \(rows)")
    self.stage = rows[0].stage
    self.rows = rows.map(\.row)
    self.rowSet = Set(self.rows)
  }
}

extension Block: ExpressibleByArrayLiteral {
  typealias ArrayLiteralElement = Row
  init(arrayLiteral elements: ArrayLiteralElement...) {
    self.init(elements)
  }
}

extension Block: CustomStringConvertible {
  var description: String {
    let rows = self.rows.map { Row(stage: self.stage, row: $0) }
    return "Block(\(rows)"
  }
}

extension Block: Sequence {
  func makeIterator() -> Array<Row>.Iterator {
    return self.rows.lazy.map({ Row(stage: self.stage, row: $0) }).makeIterator()
  }
}

extension Block: Equatable {
  public static func == (lhs: Block, rhs: Block) -> Bool {
    return lhs.rows == rhs.rows
  }
}

extension Block: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(stage)
    hasher.combine(rows)
  }
}

extension Block {
  public subscript(_ index: Int) -> Row {
    Row(stage: self.stage, row: self.rows[index])
  }
}

// MARK: - Helpers
extension Block {
  public var count: Int { rows.count }
  public var uniqueCount: Int { rowSet.count }
  public var first: Row {
    Row.init(stage: stage, row: rows.first!) // Safe: Not possible to construct empty Block
  }
  public var last: Row? {
    Row.init(stage: stage, row: rows.last!) // Safe: Not possible to construct tempty Block
  }
  
  /// Separates the rows into two blocks by stroke parity.
  /// - Parameter backstrokeStart: Whether to consider the current
  /// block to start at a backstroke or not. (Default false, i.e. handstroke
  /// start.)
  /// - Returns: Two blocks labeled hand and back.
  public func groupByStroke(
    backstrokeStart: Bool = false
  ) -> (hand: Block, back: Block) {
    var first: [RawRow] = []
    var second: [RawRow] = []
    self.rows.enumerated().forEach { (idx, row) in
      if idx.isMultiple(of: 2) {
        first.append(row)
      } else {
        second.append(row)
      }
    }
    let firstBlock = Block(stage: self.stage, rows: first, rowSet: Set(first))
    let secondBlock = Block(stage: self.stage, rows: second, rowSet: Set(second))
    return backstrokeStart ? (hand: secondBlock, back: firstBlock) : (hand: firstBlock, back: secondBlock)
  }
}

// MARK: - Truth

// 1-extent truth
extension Block {
  /// Whether the block is 1-extent true, i.e. every row is unique.
  public var isTrue: Bool {
    rows.count == rowSet.count
  }
  
  /// Whether the block is 1-extent true against another block.
  /// An internally-false Block is considered to be false against
  /// all other blocks.
  /// Throws: .stageMismatch
  public func isTrue(against other: Block) throws -> Bool {
    guard self.stage == other.stage else {
      throw BellMetalError.stageMismatch
    }
    return self.isTrue && other.isTrue && self.rowSet.intersection(other.rowSet).isEmpty
  }
}


// MARK: - Operations

extension Block {
  /// Transposes the entire block by a Row by multiplying each
  /// row in the block *on the left*.
  public func transpose(by new: Row) throws -> Block {
    guard new.stage == self.stage else {
      throw BellMetalError.stageMismatch
    }
    let newRows = self.rows.map { new.row.composePermutation($0, rawStage: new.stage.rawValue) }
    return Block(stage: self.stage, rows: newRows, rowSet: Set(newRows))
  }
  
  /// Extend the block to a higher stage by appending tenors-behind.
  public func extend(to higher: Stage) throws -> Block {
    guard self.stage < higher else {
      throw BellMetalError.invalidStage
    }
    let newRows = self.rows.map { $0.extend(from: self.stage, to: higher) }
    return Block(stage: higher, rows: newRows, rowSet: Set(newRows))
  }
}

extension Block {
  /// Concatenate two blocks.
  public func concatenate(_ other: Block) throws -> Block {
    guard self.stage == other.stage else {
      throw BellMetalError.stageMismatch
    }
    return Block(stage: self.stage, rows: self.rows + other.rows, rowSet: self.rowSet.union(other.rowSet))
  }
  
  /// Concatenate two blocks. Caller is responsible for ensuring stage matching.
  public static func + (lhs: Block, rhs: Block) -> Block {
    precondition(lhs.stage == rhs.stage, "Mismatched stages: \(lhs.stage) & \(rhs.stage)")
    return try! lhs.concatenate(rhs) // Safe: Checked by precondition.
  }
  
  /// Append one or more rows to this block.
  public func append(_ other: Row...) throws -> Block {
    return try self.concatenate(Block(other))
  }
}
