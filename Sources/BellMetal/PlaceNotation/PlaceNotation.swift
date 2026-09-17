import Foundation


/// A segment of place notation at some stage.
public struct PlaceNotation: Sendable {
  let stage: Stage
  private let changes: [RawRow]
  
  internal init(stage: Stage, changes: [RawRow]) {
    self.stage = stage
    self.changes = changes
  }
  
  public init(string: String, at stage: Stage? = nil) throws {
    let (explicitStage, string) = try PlaceNotationParser.getExplicitStage(string)
    if explicitStage != nil,
       stage != nil,
       explicitStage != stage {
      throw BellMetalError.invalidPlaceNotation
    }
    let (knownStage, changes) = try PlaceNotationParser.parseAllChanges(string, at: stage ?? explicitStage)
    self.stage = knownStage
    self.changes = changes
  }
}

extension PlaceNotation: Equatable {
  public static func == (lhs: PlaceNotation, rhs: PlaceNotation) -> Bool {
    return lhs.stage == rhs.stage
    && lhs.changes == rhs.changes
  }
}

extension PlaceNotation: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(stage)
    hasher.combine(changes)
  }
}

extension PlaceNotation: ExpressibleByStringLiteral {
  public init(stringLiteral value: StringLiteralType) {
    try! self.init(string: value)
  }
}

// MARK: - Codable

extension PlaceNotation: Codable {
  private enum CodingKeys: String, CodingKey {
    case stage
    case notation
  }

  /// Encodes/decodes as `{"stage": <bell count>, "notation": "<place notation
  /// string>"}`, rather than the internal representation. A keyed structure
  /// (rather than just the notation string) is needed because the stage can't
  /// always be recovered from the notation alone -- e.g. an all-cross
  /// notation like "x" carries no place numbers to infer a stage from.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let stage = try container.decode(Stage.self, forKey: .stage)
    let notation = try container.decode(String.self, forKey: .notation)
    do {
      try self.init(string: notation, at: stage)
    } catch {
      throw DecodingError.dataCorruptedError(
        forKey: .notation,
        in: container,
        debugDescription: "Invalid PlaceNotation \"\(notation)\" at stage \(stage)"
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(stage, forKey: .stage)
    try container.encode(description, forKey: .notation)
  }
}

extension PlaceNotation: CustomStringConvertible {
  
  /// Tries every way of splitting the sequence of changes in two,
  /// looking for a split in which both segments are palindromes about a change.
  /// - Returns: The reduced forms (i.e. from begining up through apex)
  /// of of two palindromes that together make up the full sequence of changes.
  private func findPalindromicSplit() -> ([RawRow], [RawRow])? {
    for i in self.changes.indices {
      let (a,b) = (Array(self.changes[...i]), Array(self.changes[(i+1)...]))
      if let ap = a.reduceOddPalindrome(),
         let bp = b.reduceOddPalindrome()
      {
        return (ap, bp)
      }
    }
    return nil
  }
  
  /// Takes a sequence of changes and maps them to an appropriate string.
  /// - Parameter changes: A sequence of changes.
  /// - Returns: A string of valid place notation representing those changes,
  /// including "." separators where appropriate.
  private static func changesToString(_ changes: [RawRow]) -> String {
    var strings = Array(changes.map { change in
      let places = change.fixedBells.map { $0 + 1 }
      if places.isEmpty { return "x" }
      return places
        .map(PlaceNotationParser.representPlace)
        .joined(separator: "")
    }.reversed())
    var complete: [String] = []
    while let nextChange = strings.popLast() {
      if let lastChange = complete.last,
         lastChange != "x",
         nextChange != "x"
      {
        complete.append(".")
      }
      complete.append(nextChange)
    }
    return complete.joined()
  }
  
  public var description: String {
    if let (a,b) = self.findPalindromicSplit() {
      return PlaceNotation.changesToString(a) + "," + PlaceNotation.changesToString(b)
    }
    return PlaceNotation.changesToString(changes)
  }
}

extension PlaceNotation {
  /// Applies a place notation's overall transposition (its `leadhead`) to a row.
  /// - Precondition: `lhs` and `rhs` must share a stage.
  public static func *(lhs: Row, rhs: PlaceNotation) -> Row {
    precondition(lhs.stage == rhs.stage)
    return lhs * rhs.leadhead
  }
}

extension PlaceNotation {
  /// When pricking a block, used to determine which of the starting and ending
  /// rows to keep in the result.
  public enum LeadheadMode {
    case keepFinal, keepInitial, keepBoth, keepNeither
  }
  
  /// When pricking a block, used to set the conditions under which repetition should
  /// stop.
  /// .times(let n): Stop after n times
  /// .untilRound: Stop when the start and end rows are the same
  /// .untilFalse: Stop when the resulting block contains repeating rows
  /// .untilPosition(bell:position): Until the final leadhead
  /// has the specified bell in the specified position. (Note: If not paired
  /// with another condition, may result in an infinite loop. Also, if paired
  /// with a LeadheadMode that drops the final row, the bell in question may
  /// not be in the specified position at the end of the returned Block, but
  /// would reach that position if one more change were made.)
  public enum RepeatCondition {
    case times(UInt)
    case untilRound
    case untilFalse
    case untilPosition(bell: Bell, position: Int)
  }
  
  private func shouldKeepRepeating(
    rows: [RawRow],
    rowSet: Set<RawRow>,
    repetitions: UInt,
    conditions: [RepeatCondition]
  ) -> Bool {
    // If empty, do not repeat.
    guard !conditions.isEmpty else { return false }
    for condition in conditions {
      switch condition {
      case .times(let count):
        guard repetitions < count else { return false }
      case .untilRound:
        guard rows.last != rows.first else { return false }
      case .untilFalse:
        guard rows.count == rowSet.count else { return false }
      case .untilPosition(let bell, let position):
        guard let bellPos = rows.last?.rawPosition(of: bell.rawValue),
              bellPos != position - 1
        else { return false }
      }
    }
    return true
  }
  
  private func prickOneRepetition(_ row: RawRow) -> [RawRow] {
    Array(self.changes.reduce(into: [row]) { into, new in
      into.append(into.last!.composePermutation(new, rawStage: stage.rawValue))
    }.dropFirst())
  }
  
  /// Prick this place notation starting from a given row. The place notation
  /// will be repeated until any one of the repeatModes conditions are filled.
  /// - Parameters:
  ///   - row: The row from which to start pricking; defaults to rounds.
  ///   - leadheadMode: Which of the first or last rows to keep.
  ///   (E.g. when pricking a round block, should rounds appear at
  ///   the beginning or the end of the block?) Defaults to .keepFinal.
  ///   - repeatConditions: Variadic; the conditions under which to stop repetition.
  ///   Repetition will continue until any one of these are met.
  ///   If no arguments are given, the place notation will be pricked once
  ///   and not repeated. This is equivalent to .times(1)
  /// - Returns: The result of pricking this place notation from the starting
  /// row some number of times.
  public func prick(
    at row: Row? = nil,
    keeping leadheadMode: LeadheadMode = .keepFinal,
    repeat repeatConditions: RepeatCondition...
  ) throws -> Block {
    let row = row ?? stage.rounds
    guard row.stage == self.stage else { throw BellMetalError.stageMismatch }
    
    var rawRows = [row.row]
    var rawRowsSet = Set(rawRows)
    var repetitions: UInt = 0
    repeat {
      let newRows = prickOneRepetition(rawRows.last!)
      rawRows += newRows
      rawRowsSet.insert(contentsOf: newRows)
      repetitions += 1
    } while shouldKeepRepeating(
      rows: rawRows,
      rowSet: rawRowsSet,
      repetitions: repetitions,
      conditions: repeatConditions
    )
    
    switch leadheadMode {
    case .keepFinal: rawRows.removeFirst()
    case .keepInitial: rawRows.removeLast()
    case.keepNeither:
      rawRows.removeFirst()
      rawRows.removeLast()
    case .keepBoth: break
    }
    return Block(stage: stage, rows: rawRows, rowSet: Set(rawRows))
  }
}

// MARK: - Useful facts
extension PlaceNotation {
  /// The number of individual changes in this place notation.
  public var count: Int {
    changes.count
  }
  
  /// The total transposition reached by this place notation.
  public var leadhead: Row {
    Row(
      stage: stage,
      row: changes.reduce(into: stage.rounds.row) { $0 = $0.composePermutation($1, rawStage: stage.rawValue) }
    )
  }
}

// MARK: - PN to PN operations
extension PlaceNotation {
  /// Safe, throwing concatenation of two PlaceNotations
  public func concatenate(with other: PlaceNotation) throws -> PlaceNotation {
    guard stage == other.stage else { throw BellMetalError.stageMismatch }
    return .init(stage: stage, changes: changes + other.changes)
    
  }
  
  /// Unsafe, non-throwing concatenation of PlaceNotation.
  /// The user is responsible for not mismatching stages.
  public static func + (lhs: PlaceNotation, rhs: PlaceNotation) -> PlaceNotation {
    precondition(lhs.stage == rhs.stage, "Stages don't match: \(lhs) + \(rhs)")
    return try! lhs.concatenate(with: rhs)
  }
}

// MARK: - Segment replacement
extension PlaceNotation {
  /// Replaces the changes in `range` with the changes from `replacement`.
  /// - Throws: `BellMetalError.stageMismatch` if `replacement`'s stage differs
  ///   from this place notation's stage. `BellMetalError.invalidIndex` if
  ///   `range` isn't within `0..<count` (inclusive of `count` as an upper bound).
  public func replacing(_ range: Range<Int>, with replacement: PlaceNotation) throws -> PlaceNotation {
    guard stage == replacement.stage else { throw BellMetalError.stageMismatch }
    guard range.lowerBound >= 0, range.upperBound <= count else {
      throw BellMetalError.invalidIndex
    }
    var newChanges = changes
    newChanges.replaceSubrange(range, with: replacement.changes)
    return PlaceNotation(stage: stage, changes: newChanges)
  }

  /// Replaces the changes in `range` with the changes parsed from
  /// `replacement`, interpreted at this place notation's stage.
  public func replacing(_ range: Range<Int>, with replacement: String) throws -> PlaceNotation {
    try replacing(range, with: PlaceNotation(string: replacement, at: stage))
  }

  /// Replaces the single change at `index` with `replacement`.
  public func replacing(at index: Int, with replacement: PlaceNotation) throws -> PlaceNotation {
    try replacing(index..<(index + 1), with: replacement)
  }

  /// Replaces the single change at `index` with the change(s) parsed from
  /// `replacement`, interpreted at this place notation's stage.
  public func replacing(at index: Int, with replacement: String) throws -> PlaceNotation {
    try replacing(index..<(index + 1), with: replacement)
  }

  /// Replaces the last change with `replacement`. The common case: e.g.
  /// `"x16x16,12"` -> `replacingLast(with: "14")` -> `"x16x16,14"`.
  public func replacingLast(with replacement: PlaceNotation) throws -> PlaceNotation {
    try replacing(at: count - 1, with: replacement)
  }

  /// Replaces the last change with the change(s) parsed from `replacement`,
  /// interpreted at this place notation's stage.
  public func replacingLast(with replacement: String) throws -> PlaceNotation {
    try replacing(at: count - 1, with: replacement)
  }
}

// MARK: - Lines
extension PlaceNotation {
  
  /// Generate the blueline for a given place bell, extending for some number of leads.
  /// - Parameters:
  ///   - bell: The bell to generate the line for.
  ///   - leads: How many repetitions of the place notation block to continue the line through.
  /// - Returns: A sequence of integers between 1 and stage.n (inclusive) representing the
  /// position of the bell in each row. Includes both the first and last rows.
  public func line(for bell: Bell, leads: UInt = 1) -> [Int] {
    guard self.stage.includes(bell) else { return [] }
    return (try? prick(keeping: .keepBoth, repeat: .times(leads)))?
      .map { $0[bell] } ?? []
  }
}
