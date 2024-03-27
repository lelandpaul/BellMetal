import Foundation

public struct Row<Stage: StageProtocol>: CustomStringConvertible {
  static var stage: Int { Stage.n }
  
  package let _row: [Bell]
  
  public var description: String {
    self._row.map({ $0.description }).joined()
  }
  
  init(_ row: [Bell]) throws {
    guard
      row.min() == .b1,
      let tenor = row.max(),
      tenor == Stage.tenor,
      Set(row).count == Self.stage
    else { throw BellMetalError.invalidRow }
    self._row = row
  }
  
  init!(_ row: String) throws {
    let parsedRow: [Bell]
    do {
      parsedRow = try row.map { try Bell.from($0) }
    } catch {
      throw BellMetalError.invalidRow
    }
    try self.init(parsedRow)
  }
  
  public func position(of bell: Bell) -> Int {
    guard let pos = _row.firstIndex(of: bell) else {
      fatalError("Tried to find position of bell \(bell) in a row of stage \(Stage.description)")
    }
    return pos + 1
  }
}

extension Row: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    try! self.init(value)
  }
}

extension Row: Equatable { }
extension Row: Hashable { }

extension Row: Sequence {
  public func makeIterator() -> IndexingIterator<Array<Bell>> {
    return _row.makeIterator()
  }
}

// MARK: - Aliases

public typealias Row3 = Row<Singles>
public typealias Row4 = Row<Minimus>
public typealias Row5 = Row<Doubles>
public typealias Row6 = Row<Minor>
public typealias Row7 = Row<Triples>
public typealias Row8 = Row<Major>
public typealias Row9 = Row<Caters>
public typealias Row0 = Row<Royal>
public typealias RowE = Row<Cinques>
public typealias RowT = Row<Maximus>
public typealias RowA = Row<Thirteen>
public typealias RowB = Row<Fourteen>
public typealias RowC = Row<Fifteen>
public typealias RowD = Row<Sixteen>

// MARK: - Operators

extension Row {
  public static func rounds() -> Row<Stage> {
    let seq = Array(1...stage).map { Bell(rawValue: $0)! }
    return try! Row<Stage>(seq)
  }
  
  public static func *(lhs: Row<Stage>, rhs: Row<Stage>) -> Row<Stage> {
    let internalRow = lhs._row[rhs._row]
    return try! Row<Stage>(internalRow)
  }
  
  public static func ^(lhs: Row<Stage>, rhs: Int) -> Row<Stage> {
    guard lhs != rounds() else { return lhs }
    switch rhs {
    case 0:
      return rounds()
    case -1: // inverse
      var result = lhs
      while result * lhs != rounds() {
        result = result * lhs
      }
      return result
    case let x where x > 0: // positive
      var result = lhs
      for _ in 1..<rhs {
        result = result * lhs
      }
      return result
    default: // negative
      return (lhs ^ abs(rhs)) ^ -1
    }
  }
}

extension [Bell] {
  public func toRow<Stage: StageProtocol>() -> Row<Stage> {
    do {
      return try Row(self)
    } catch {
      fatalError("Invalid row.")
    }
  }
}

extension [Int] {
  public func toRow<Stage: StageProtocol>() -> Row<Stage> {
    return self.compactMap { Bell(rawValue: $0) }.toRow()
  }
}

// MARK: - RowBlock
// This is basically a wrapper around Array<Row>, but gets
// around some genericity issues.

public struct RowBlock<Stage: StageProtocol>: CustomStringConvertible {
  public var rows: [Row<Stage>]
  
  public var first: Row<Stage>? { rows.first }
  public var last: Row<Stage>? { rows.last }
  
  public var description: String {
    rows.map({$0.description}).joined(separator: "\n")
  }
  
  public var count: Int { rows.count }
  
  public init<T: Sequence>(rows: T) where T.Element == Row<Stage> {
    self.rows = []
    for row in rows {
      self.rows.append(row)
    }
  }
}

extension RowBlock: Sequence {
  public func makeIterator() -> IndexingIterator<Array<Row<Stage>>> {
    return rows.makeIterator()
  }
}

typealias RowBlock3 = RowBlock<Singles>
typealias RowBlock4 = RowBlock<Minimus>
typealias RowBlock5 = RowBlock<Doubles>
typealias RowBlock6 = RowBlock<Minor>
typealias RowBlock7 = RowBlock<Triples>
typealias RowBlock8 = RowBlock<Major>
typealias RowBlock9 = RowBlock<Caters>
typealias RowBlock0 = RowBlock<Royal>
typealias RowBlockE = RowBlock<Cinques>
typealias RowBlockT = RowBlock<Maximus>
typealias RowBlockA = RowBlock<Thirteen>
typealias RowBlockB = RowBlock<Fourteen>
typealias RowBlockC = RowBlock<Fifteen>
typealias RowBlockD = RowBlock<Sixteen>

extension RowBlock {
  mutating public func extend(by block: Block<Stage>) {
    let lastRow = rows.last ?? Row<Stage>.rounds()
    let newRows = block.evaluate(at: lastRow)
    self.rows.append(contentsOf: newRows)
  }
}

extension RowBlock: Equatable { }

extension RowBlock {
  public var isTrue: Bool {
    var set = Set<Element>()
    for row in self.rows {
      if set.contains(row) { return false }
      set.insert(row)
    }
    return true
  }
  
  public func isTrue(against block: Self) -> Bool {
    var set = Set<Element>()
    for row in self.rows {
      if set.contains(row) { return false }
      set.insert(row)
    }
    for row in block.rows {
      if set.contains(row) { return false }
      set.insert(row)
    }
    return true
  }
  
  public static func + (lhs: Self, rhs: Self) -> Self {
    return Self(rows: lhs.rows + rhs.rows)
  }
}

// MARK: - Whole Pulls

public struct WholePull<Stage: StageProtocol> {
  let hand: Row<Stage>?
  let back: Row<Stage>?
  
  init(hand: Row<Stage>?, back: Row<Stage>?) {
    guard hand != nil || back != nil else {
      fatalError("WholePull must have at least one row.")
    }
    self.hand = hand
    self.back = back
  }
}

extension RowBlock {
  func wholePulls(backstrokeStart: Bool = false) -> [WholePull<Stage>] {
    var result = [WholePull<Stage>]()
    var remaining = self.rows
    if backstrokeStart {
      let start = remaining.removeFirst()
      result.append(WholePull(hand: nil, back: start))
    }
    while remaining.count > 1 {
      let hand = remaining.removeFirst()
      let back = remaining.removeFirst()
      result.append(WholePull(hand: hand, back: back))
    }
    if remaining.count > 0 {
      result.append(WholePull(hand: remaining.first, back: nil))
    }
    return result
  }
}

// MARK: - Music

extension Row {
  public var musicScore: Int {
    Stage.musicScheme.score(self)
  }
  
  public var musicDetails: [MusicType<Stage>: Int] {
    Stage.musicScheme.scoreDetails(self)
  }
}

extension RowBlock {
  public func musicScore(backstrokeStart: Bool = false) -> Int {
    Stage.musicScheme.score(self, backstrokeStart: backstrokeStart)
  }
  
  public func musicDetails(backstrokeStart: Bool = false) -> [MusicType<Stage>: Int] {
    Stage.musicScheme.scoreDetails(self, backstrokeStart: backstrokeStart)
  }
}

