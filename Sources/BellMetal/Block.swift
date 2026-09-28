import Foundation

/// An ordered sequence of rows. Differs from [Row] in
/// enforcing a consistent stage and in keeping a Set
/// for quick truth-checking.
public struct Block: Sendable {
  /// The stage (number of bells) every row in this block belongs to.
  public let stage: Stage
  internal let storage: Storage

  /// The rows, in the raw layout the block's stage uses. Operations
  /// switch on this once, then run on the raw rows directly.
  internal enum Storage: Sendable {
    case narrow(RawBlock<RawRow>)
    case wide(RawBlock<WideRawRow>)
  }

  internal init<R: RawLayout>(stage: Stage, raw: RawBlock<R>) {
    self.stage = stage
    self.storage = R.blockStorage(raw)
  }

  init(_ rows: Row...) {
    self.init(Array(rows))
  }

  init(_ rows: [Row]) {
    precondition(!rows.isEmpty, "Cannot create empty Block.")
    precondition(Set(rows.map(\.stage)).count == 1, "Inconsistent Stages: \(rows)")
    let stage = rows[0].stage
    if stage.usesWideLayout {
      self.init(stage: stage, raw: RawBlock(rows: rows.map(\.wide)))
    } else {
      self.init(stage: stage, raw: RawBlock(rows: rows.map(\.narrow)))
    }
  }
}

/// A block's rows in one raw layout, with the set kept alongside for
/// truth checks. Everything `Block` does is written here once and
/// specialized per layout.
internal struct RawBlock<R: RawLayout>: Sendable {
  let rows: [R]
  let rowSet: Set<R>

  init(rows: [R], rowSet: Set<R>) {
    self.rows = rows
    self.rowSet = rowSet
  }

  init(rows: [R]) {
    self.init(rows: rows, rowSet: Set(rows))
  }

  var isTrue: Bool {
    rows.count == rowSet.count
  }

  func isTrue(against other: RawBlock) -> Bool {
    isTrue && other.isTrue && rowSet.isDisjoint(with: other.rowSet)
  }

  func groupByStroke() -> (RawBlock, RawBlock) {
    var first: [R] = []
    var second: [R] = []
    for (idx, row) in rows.enumerated() {
      if idx.isMultiple(of: 2) {
        first.append(row)
      } else {
        second.append(row)
      }
    }
    return (RawBlock(rows: first), RawBlock(rows: second))
  }

  func transposed(by row: R, rawStage: UInt8) -> RawBlock {
    RawBlock(rows: rows.map { row.composePermutation($0, rawStage: rawStage) })
  }

  func extended(from: Stage, to: Stage) -> RawBlock {
    RawBlock(rows: rows.map { $0.extend(from: from, to: to) })
  }

  func concatenated(_ other: RawBlock) -> RawBlock {
    RawBlock(rows: rows + other.rows, rowSet: rowSet.union(other.rowSet))
  }
}

extension Block: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = Row
  public init(arrayLiteral elements: ArrayLiteralElement...) {
    self.init(elements)
  }
}

extension Block: CustomStringConvertible {
  /// A description listing every row in the block, in order.
  public var description: String {
    return "Block(\(Array(self))"
  }
}

extension Block: Sequence {
  public func makeIterator() -> Iterator {
    Iterator(block: self)
  }

  /// Iterates over a block's rows in order, building each `Row` as it goes.
  public struct Iterator: IteratorProtocol {
    let block: Block
    var index = 0

    public mutating func next() -> Row? {
      guard index < block.count else { return nil }
      defer { index += 1 }
      return block[index]
    }
  }

  public var underestimatedCount: Int { count }
}

extension Block: Equatable {
  public static func == (lhs: Block, rhs: Block) -> Bool {
    switch (lhs.storage, rhs.storage) {
    case let (.narrow(lhs), .narrow(rhs)): lhs.rows == rhs.rows
    case let (.wide(lhs), .wide(rhs)): lhs.rows == rhs.rows
    default: false
    }
  }
}

extension Block: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(stage)
    switch storage {
    case .narrow(let raw): hasher.combine(raw.rows)
    case .wide(let raw): hasher.combine(raw.rows)
    }
  }
}

// MARK: - Codable

extension Block: Codable {
  /// Encodes/decodes as a plain array of Rows, not the internal
  /// bit-packed storage (or the redundant rowSet cache).
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rows = try container.decode([Row].self)
    guard !rows.isEmpty else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Block cannot be empty")
    }
    guard Set(rows.map(\.stage)).count == 1 else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Block rows have inconsistent stages")
    }
    self.init(rows)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(Array(self))
  }
}

extension Block {
  /// The row at the given (0-indexed) position in the block.
  public subscript(_ index: Int) -> Row {
    switch storage {
    case .narrow(let raw): raw.rows[index].row(stage: stage)
    case .wide(let raw): raw.rows[index].row(stage: stage)
    }
  }
}

// MARK: - Helpers
extension Block {
  /// The number of rows in the block, including any repeats.
  public var count: Int {
    switch storage {
    case .narrow(let raw): raw.rows.count
    case .wide(let raw): raw.rows.count
    }
  }
  /// The number of distinct rows in the block, i.e. `count` minus any repeats.
  public var uniqueCount: Int {
    switch storage {
    case .narrow(let raw): raw.rowSet.count
    case .wide(let raw): raw.rowSet.count
    }
  }
  /// The first row in the block. A block can never be empty.
  public var first: Row {
    self[0] // Safe: Not possible to construct empty Block
  }
  /// The last row in the block. A block can never be empty.
  public var last: Row {
    self[count - 1] // Safe: Not possible to construct empty Block
  }

  /// Separates the rows into two blocks by stroke parity.
  /// - Parameter backstrokeStart: Whether to consider the current
  /// block to start at a backstroke or not. (Default false, i.e. handstroke
  /// start.)
  /// - Returns: Two blocks labeled hand and back.
  public func groupByStroke(
    backstrokeStart: Bool = false
  ) -> (hand: Block, back: Block) {
    let (firstBlock, secondBlock) = switch storage {
    case .narrow(let raw): grouped(raw)
    case .wide(let raw): grouped(raw)
    }
    return backstrokeStart ? (hand: secondBlock, back: firstBlock) : (hand: firstBlock, back: secondBlock)
  }

  private func grouped<R>(_ raw: RawBlock<R>) -> (Block, Block) {
    let (first, second) = raw.groupByStroke()
    return (Block(stage: stage, raw: first), Block(stage: stage, raw: second))
  }
}

// MARK: - Truth

// 1-extent truth
extension Block {
  /// Whether the block is 1-extent true, i.e. every row is unique.
  public var isTrue: Bool {
    switch storage {
    case .narrow(let raw): raw.isTrue
    case .wide(let raw): raw.isTrue
    }
  }

  /// Whether the block is 1-extent true against another block.
  /// An internally-false Block is considered to be false against
  /// all other blocks.
  /// Throws: .stageMismatch
  public func isTrue(against other: Block) throws -> Bool {
    guard self.stage == other.stage else {
      throw BellMetalError.stageMismatch
    }
    switch (storage, other.storage) {
    case let (.narrow(lhs), .narrow(rhs)): return lhs.isTrue(against: rhs)
    case let (.wide(lhs), .wide(rhs)): return lhs.isTrue(against: rhs)
    default: preconditionFailure("Same stage, different layouts: \(stage)")
    }
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
    return switch storage {
    case .narrow(let raw): transposed(raw, by: new)
    case .wide(let raw): transposed(raw, by: new)
    }
  }

  private func transposed<R>(_ raw: RawBlock<R>, by new: Row) -> Block {
    Block(stage: stage, raw: raw.transposed(by: R.raw(of: new), rawStage: stage.rawValue))
  }

  /// Extend the block to a higher stage by appending tenors-behind.
  public func extend(to higher: Stage) throws -> Block {
    guard self.stage < higher else {
      throw BellMetalError.invalidStage
    }
    switch (storage, higher.usesWideLayout) {
    case (.narrow(let raw), false):
      return Block(stage: higher, raw: raw.extended(from: stage, to: higher))
    case (.narrow(let raw), true):
      let widened = raw.rows.map { WideRawRow(widening: $0, from: stage, to: higher) }
      return Block(stage: higher, raw: RawBlock(rows: widened))
    case (.wide(let raw), _):
      return Block(stage: higher, raw: raw.extended(from: stage, to: higher))
    }
  }
}

extension Block {
  /// Concatenate two blocks.
  public func concatenate(_ other: Block) throws -> Block {
    guard self.stage == other.stage else {
      throw BellMetalError.stageMismatch
    }
    switch (storage, other.storage) {
    case let (.narrow(lhs), .narrow(rhs)): return Block(stage: stage, raw: lhs.concatenated(rhs))
    case let (.wide(lhs), .wide(rhs)): return Block(stage: stage, raw: lhs.concatenated(rhs))
    default: preconditionFailure("Same stage, different layouts: \(stage)")
    }
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
