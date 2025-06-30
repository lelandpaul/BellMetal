import Foundation


/// A segment of place notation at some stage.
struct PlaceNotation {
  let stage: Stage
  private let changes: [RawRow]
  
  internal init(stage: Stage, changes: [RawRow]) {
    self.stage = stage
    self.changes = changes
  }
  
  public init(_ pn: String, at stage: Stage? = nil) throws {
    let (explicitStage, pn) = try PlaceNotationParser.getExplicitStage(pn)
    if explicitStage != nil,
       stage != nil,
       explicitStage != stage {
      throw BellMetalError.invalidPlaceNotation
    }
    let (knownStage, changes) = try PlaceNotationParser.parseAllChanges(pn, at: stage ?? explicitStage)
    self.stage = knownStage
    self.changes = changes
  }
}

extension PlaceNotation: Equatable {
  static func == (lhs: PlaceNotation, rhs: PlaceNotation) -> Bool {
    return lhs.stage == rhs.stage
    && lhs.changes == rhs.changes
  }
}

extension PlaceNotation: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(stage)
    hasher.combine(changes)
  }
}

extension PlaceNotation: ExpressibleByStringLiteral {
  init(stringLiteral value: StringLiteralType) {
    try! self.init(value)
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
  
  var description: String {
    if let (a,b) = self.findPalindromicSplit() {
      return PlaceNotation.changesToString(a) + "," + PlaceNotation.changesToString(b)
    }
    return PlaceNotation.changesToString(changes)
  }
}

extension PlaceNotation {
  /// When pricking a block, used to determine which of the starting and ending
  /// rows to keep in the result.
  enum LeadheadMode {
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
  enum RepeatCondition {
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
  ///   - repeat: Variadic; the conditions under which to stop repetition.
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
  var count: Int {
    changes.count
  }
  
  /// The total transposition reached by this place notation.
  var leadhead: Row {
    Row(
      stage: stage,
      row: changes.reduce(into: stage.rounds.row) { $0 = $0 * $1 }
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

