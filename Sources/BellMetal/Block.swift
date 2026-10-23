import Foundation

/// An ordered sequence of rows. Differs from [Row] in
/// enforcing a consistent stage and in keeping a Set
/// for quick truth-checking.
///
/// A block can be empty, e.g. one half of `groupByStroke()` on a one-row
/// block, or a one-change notation pricked with `.keepNeither`. Check
/// `isEmpty` before using `first` or `last`.
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
    self.init(unchecked: rows, at: rows[0].stage)
  }

  /// Creates a block from rows that all have the given stage. Unlike an
  /// array literal, this takes a runtime array, and allows an empty one.
  /// - Throws: `BellMetalError.stageMismatch` if any row isn't at `stage`.
  public init(_ rows: [Row], at stage: Stage) throws {
    guard rows.allSatisfy({ $0.stage == stage }) else {
      throw BellMetalError.stageMismatch
    }
    self.init(unchecked: rows, at: stage)
  }

  private init(unchecked rows: [Row], at stage: Stage) {
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
    return "Block(\(Array(self)))"
  }
}

extension Block: Sequence {
  public func makeIterator() -> Iterator {
    Iterator(block: self)
  }

  /// Iterates over a block's rows in order, building each `Row` as it goes.
  public struct Iterator: IteratorProtocol, Sendable {
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
  /// Blocks are equal if they have the same stage and the same rows in the
  /// same order. (The stage matters for empty blocks.)
  public static func == (lhs: Block, rhs: Block) -> Bool {
    guard lhs.stage == rhs.stage else { return false }
    return switch (lhs.storage, rhs.storage) {
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
  private enum CodingKeys: String, CodingKey {
    case stage
    case rows
  }

  /// Encodes/decodes as a plain array of Rows, not the internal
  /// bit-packed storage (or the redundant rowSet cache). An empty array
  /// has no stage to take, so an empty block encodes as
  /// `{"stage": <bell count>, "rows": []}` instead. Decoding accepts that
  /// form for any block.
  public init(from decoder: Decoder) throws {
    if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
      let stage = try keyed.decode(Stage.self, forKey: .stage)
      let rows = try keyed.decode([Row].self, forKey: .rows)
      do {
        try self.init(rows, at: stage)
      } catch {
        throw DecodingError.dataCorruptedError(
          forKey: .rows, in: keyed, debugDescription: "Block rows aren't all at stage \(stage)"
        )
      }
      return
    }
    let container = try decoder.singleValueContainer()
    let rows = try container.decode([Row].self)
    guard let stage = rows.first?.stage else {
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "An empty Block must be encoded with its stage"
      )
    }
    guard let block = try? Block(rows, at: stage) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Block rows have inconsistent stages")
    }
    self = block
  }

  public func encode(to encoder: Encoder) throws {
    if isEmpty {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(stage, forKey: .stage)
      try container.encode([Row](), forKey: .rows)
    } else {
      var container = encoder.singleValueContainer()
      try container.encode(Array(self))
    }
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

  /// Whether the block has no rows.
  public var isEmpty: Bool {
    switch storage {
    case .narrow(let raw): raw.rows.isEmpty
    case .wide(let raw): raw.rows.isEmpty
    }
  }
  /// The number of distinct rows in the block, i.e. `count` minus any repeats.
  public var uniqueCount: Int {
    switch storage {
    case .narrow(let raw): raw.rowSet.count
    case .wide(let raw): raw.rowSet.count
    }
  }
  /// The first row in the block.
  /// - Precondition: The block isn't empty (see `isEmpty`).
  public var first: Row {
    precondition(!isEmpty, "first on an empty Block")
    return self[0]
  }
  /// The last row in the block.
  /// - Precondition: The block isn't empty (see `isEmpty`).
  public var last: Row {
    precondition(!isEmpty, "last on an empty Block")
    return self[count - 1]
  }

  /// Separates the rows into two blocks by stroke parity.
  /// - Parameter backstrokeStart: Whether to consider the current
  /// block to start at a backstroke or not. (Default false, i.e. handstroke
  /// start.)
  /// - Returns: Two blocks labeled hand and back. Either can be empty: a
  /// one-row block has no rows at the other stroke.
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
  /// - Throws: `BellMetalError.stageMismatch` if `new` is a different stage.
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
  /// - Throws: `BellMetalError.invalidStage` unless `higher` is strictly
  ///   higher than the block's stage (the same stage throws too).
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
  /// - Throws: `BellMetalError.stageMismatch` if `other` is a different stage.
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
    // swiftlint:disable:next force_try
    return try! lhs.concatenate(rhs) // Safe: Checked by precondition.
  }

  /// Concatenate a block onto this one. Caller is responsible for ensuring stage matching.
  public static func += (lhs: inout Block, rhs: Block) {
    lhs = lhs + rhs
  }

  /// Returns this block with the given rows added to the end. (It doesn't
  /// change this block.) With no rows, returns the block unchanged.
  /// - Throws: `BellMetalError.stageMismatch` if any row is a different stage.
  public func append(_ other: Row...) throws -> Block {
    try self.concatenate(Block(other, at: stage))
  }
}
