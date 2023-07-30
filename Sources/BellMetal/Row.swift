import Foundation

struct Row<Stage: StageProtocol>: CustomStringConvertible {
  static var stage: Int { Stage.n }
  
  private let _row: [Bell]
  
  var description: String {
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

extension Row: Sequence {
  func makeIterator() -> IndexingIterator<Array<Bell>> {
    return _row.makeIterator()
  }
}

// MARK: - Aliases

typealias Row3 = Row<Singles>
typealias Row4 = Row<Minimus>
typealias Row5 = Row<Doubles>
typealias Row6 = Row<Minor>
typealias Row7 = Row<Triples>
typealias Row8 = Row<Major>
typealias Row9 = Row<Caters>
typealias Row0 = Row<Royal>
typealias RowE = Row<Cinques>
typealias RowT = Row<Maximus>
typealias RowA = Row<Thirteen>
typealias RowB = Row<Fourteen>
typealias RowC = Row<Fifteen>
typealias RowD = Row<Sixteen>

// MARK: - Operators

extension Row {
  static func rounds() -> Row<Stage> {
    let seq = Array(1...stage).map { Bell(rawValue: $0)! }
    return try! Row<Stage>(seq)
  }
  
  static func *(lhs: Row<Stage>, rhs: Row<Stage>) -> Row<Stage> {
    let internalRow = lhs._row[rhs._row]
    return try! Row<Stage>(internalRow)
  }
  
  static func ^(lhs: Row<Stage>, rhs: Int) -> Row<Stage> {
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

// MARK: - RowBlock
// This is basically a wrapper around Array<Row>, but gets
// around some genericity issues.

struct RowBlock<Stage: StageProtocol> {
  public var rows: [Row<Stage>]
  
  public var first: Row<Stage>? { rows.first }
  public var last: Row<Stage>? { rows.last }
  
  init(rows: ArraySlice<Row<Stage>>) {
    self.rows = []
    for row in rows {
      self.rows.append(row)
    }
  }
}

extension RowBlock: Sequence {
  func makeIterator() -> IndexingIterator<Array<Row<Stage>>> {
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
