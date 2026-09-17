import Foundation

/// A representation of an individual row, i.e. an arbitrary permutation
/// on some number of bells.
public struct Row: Equatable, Hashable, Sendable {
  /// The stage (number of bells) this row belongs to.
  public let stage: Stage
  internal let row: RawRow
  
  internal init(stage: Stage, row: RawRow) {
    self.stage = stage
    self.row = row
  }
}

// MARK: - Literals
extension Row: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = Bell

  public init(arrayLiteral elements: Bell...) {
    self.init(elements)
  }

  /// Creates a row from an array of bells, e.g. `[.b2, .b1, .b3]` is "213".
  /// - Precondition: the array must be a valid permutation -- see
  /// `init(validating:)` for the throwing equivalent, which is safe to use
  /// on untrusted input.
  public init(_ array: [Bell]) {
    do {
      try self.init(validating: array)
    } catch {
      fatalError("Invalid Row literal: \(array)")
    }
  }
}

extension Row: ExpressibleByStringLiteral {
  /// Creates a row from its string representation, e.g. "14235".
  /// - Precondition: the string must be a valid permutation -- see
  /// `init(validating:)` for the throwing equivalent, which is safe to use
  /// on untrusted input.
  public init(stringLiteral value: String) {
    do {
      try self.init(validating: value)
    } catch {
      fatalError("Invalid Row literal: \(value)")
    }
  }
}

// MARK: - Safe construction

extension Row {
  /// Safe, throwing construction from an array of Bells. Throws `.invalidBell`
  /// if the array isn't a valid permutation: wrong length (must be 1...16),
  /// a duplicate bell, or a bell outside the range implied by the array's length.
  public init(validating array: [Bell]) throws {
    guard array.count >= 1 && array.count <= 16 else {
      throw BellMetalError.invalidBell
    }
    let stage = Stage(array.count)
    guard array.min() == .b1,
          array.max() == stage.tenor,
          Set(array).count == stage.count
    else {
      throw BellMetalError.invalidBell
    }
    var row = RawRow.zero
    for (i, b) in array.enumerated() {
      row |= RawRow(b.rawValue) << (4 * i)
    }
    self.init(stage: stage, row: row)
  }

  /// Safe, throwing construction from a string representation, e.g. "1234".
  /// Throws `.invalidBell` if any character isn't a valid bell, or if the
  /// resulting bells don't form a valid permutation (see `init(validating:)`
  /// above). Use this instead of the crashing string-literal initializer when
  /// the string comes from untrusted input.
  public init(validating string: String) throws {
    let bells = try string.map { character -> Bell in
      guard let bell = Bell(character: character) else {
        throw BellMetalError.invalidBell
      }
      return bell
    }
    try self.init(validating: bells)
  }
}

extension Row: CustomStringConvertible {
  /// The string representation of this row, e.g. "14235".
  public var description: String {
    var result: [String] = []
    var row = self.row
    for _ in 0..<Int(self.stage.count) {
      let bell = Bell(rawValue: UInt8(row & 0xF))! // Safe: Checked when row was created
      result.append(bell.description)
      row >>= 4
    }
    return result.joined()
  }
}

// MARK: - Codable

extension Row: Codable {
  /// Encodes/decodes as its string representation (e.g. "14235"), not the
  /// internal bit-packed storage.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    do {
      try self.init(validating: string)
    } catch {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid Row: \(string)")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}

// MARK: - Subscripts

extension Row {
  
  /// Safely retrieve the bell at a given 1-indexed position;
  /// nil if the position is invalid for the stage.
  public func bell(at pos: Int) -> Bell? {
    guard pos > 0 && pos <= self.stage.count else { return nil }
    return self[pos]
  }
  
  /// Retrieve the Bell at a given 1-indexed position.
  public subscript(_ position: Int) -> Bell {
    precondition(position > 0 && position <= self.stage.count, "Invalid position for row of stage \(stage): \(position)")
    let raw = self.row.rawBell(at: UInt8(position - 1))
    return Bell(rawValue: raw)! // Safe: Checked when row is built
  }
  
  
  /// Retrieve the 1-indexed position of a bell in the row.
  public subscript(bell: Bell) -> Int {
    precondition(self.stage.includes(bell), "Invalid bell for stage \(self.stage): \(bell)")
    guard let rawPosition = self.row.rawPosition(of: bell.rawValue) else {
      fatalError("Tried to find a bell in an invalid row: \(self), \(bell)")
    }
    return Int(rawPosition) + 1
  }
}

// MARK: - Multiplication

extension Row {
  /// Safe, throwing multiplication of rows.
  public func multiply(by other: Row) throws -> Row {
    guard self.stage == other.stage else {
      throw BellMetalError.stageMismatch
    }
    return Self.init(stage: self.stage, row: self.row.composePermutation(other.row, rawStage: stage.rawValue))
  }
  
  /// Unsafe, non-throwing multiplication.
  /// The user is responsible for not mismatching stages.
  public static func * (lhs: Row, rhs: Row) -> Row {
    precondition(lhs.stage == rhs.stage, "Stages don't match: \(lhs) * \(rhs)")
    return try! lhs.multiply(by: rhs) // Safe: Checked by precondition.
  }
}

extension Row {
  /// Get the inverse row, i.e. the row such that
  /// x.multiply(by: x.invert) == stage.rounds
  public func invert() -> Row {
    var newRow = UInt64.zero
    for i in 0...self.stage.rawValue {
      let pos: UInt8 = self.row.rawPosition(of: i)!
      newRow |= UInt64(pos) << 60 // Put new bell on the left
      newRow >>= 4
    }
    newRow >>= 4*(14 - self.stage.rawValue) // Right-justify. 14 bc 0-indexed and we've already shifted 1 nibble in the loop
    return Self.init(stage: stage, row: newRow)
  }
  
  /// Multiply repeatedly.
  private func raiseToPositivePower(_ power: Int) -> Row {
    precondition(power > 0, "Tried to raise to a non-positive power with internal function.")
    var newRow = self
    for _ in 1..<power {
      newRow = newRow * self
    }
    return newRow
  }
  
  /// Raise the row to the specified power.
  public func pow(_ power: Int) -> Row {
    switch power {
    case 0:
      stage.rounds
    case 1:
      self
    case -1:
      invert()
    case let x where x < 0:
      raiseToPositivePower(-power).invert()
    default:
      raiseToPositivePower(power)
    }
  }
}

precedencegroup ExponentialPrecedence {
  higherThan : MultiplicationPrecedence
  lowerThan : BitwiseShiftPrecedence
  associativity : left
}
infix operator **: ExponentialPrecedence

extension Row {
  static func ** (lhs: Self, rhs: Int) -> Self {
    lhs.pow(rhs)
  }
}


// MARK: - Other

// Stage change
extension Row {
  /// Extends the row up to a higher stage by adding tenors-behind.
  /// e.g. 4321.extend(to .major) == 43215678
  public func extend(to newStage: Stage) throws -> Row {
    guard self.stage < newStage else {
      throw BellMetalError.invalidStage
    }
    return Row(stage: newStage, row: self.row.extend(from: self.stage, to: newStage))
  }
}

extension Row {
  /// Builds a Row from 1-indexed bell numbers (e.g. `Row([1,2,3])` is rounds on singles),
  /// matching the convention used by Bell's string/character initializers.
  init(_ row: [Int]) {
    self.init(row.map { value -> Bell in
      guard let bell = Bell(rawValue: UInt8(value - 1)) else {
        fatalError("Invalid bell number: \(value)")
      }
      return bell
    })
  }
}

// MARK: - Sequence conformance

extension Row: Sequence {
  public func makeIterator() -> RowIterator {
    RowIterator(row: self)
  }
  
  public struct RowIterator: IteratorProtocol {
    public typealias Element = Bell
    let row: Row
    var currentIndex: Int = 1
    
    public mutating func next() -> Bell? {
      defer { currentIndex += 1}
      guard let nextBell = row.bell(at: currentIndex) else { return nil }
      return nextBell
    }
  }
}
