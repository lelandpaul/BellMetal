import Foundation

/// A representation of an individual row, i.e. an arbitrary permutation
/// on some number of bells.
public struct Row: Equatable, Hashable, Sendable {
  // Two words, whose layout depends on the stage:
  // - Up to 16 bells: `lo` is the row as a `RawRow`. `hi` is the stage's
  //   raw value (0-15), with bit 63 clear.
  // - 17 to 24 bells: `lo` and `hi` are the row as a `WideRawRow`, with
  //   the stage packed into `hi`'s top 4 bits (which `WideRawRow` leaves
  //   0): bit 63 set, bits 60-62 the stage's raw value minus 16.
  // Every unused bit is 0, so the synthesized Equatable and the
  // hash below, both over the raw words, treat rows correctly.
  private let lo: UInt64
  private let hi: UInt64

  private static let wideFlag: UInt64 = 1 << 63
  private static let wideStageShift: UInt64 = 60
  private static let wideRowMask: UInt64 = (1 << 60) - 1

  /// A row of 16 bells or fewer.
  internal init(stage: Stage, narrow: RawRow) {
    assert(!stage.usesWideLayout, "Narrow row with wide stage \(stage)")
    self.lo = narrow
    self.hi = UInt64(stage.rawValue)
  }

  /// A row of 17 to 24 bells.
  internal init(stage: Stage, wide: WideRawRow) {
    assert(stage.usesWideLayout, "Wide row with narrow stage \(stage)")
    self.lo = wide.lo
    self.hi = wide.hi
      | Row.wideFlag
      | UInt64(stage.rawValue - Stage.narrowMaxCount) << Row.wideStageShift
  }

  /// Hashes the two words mixed into one, rather than the synthesized
  /// two separate combines: half the bytes through the hasher, which is
  /// most of the cost of putting rows in a `Set`. Equal rows have equal
  /// words, so they still hash equally.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(lo ^ (hi &* 0x9E37_79B9_7F4A_7C15))
  }

  /// Whether this row uses the wide layout, i.e. has more than 16 bells.
  internal var isWide: Bool {
    hi & Row.wideFlag != 0
  }

  /// The stage (number of bells) this row belongs to.
  public var stage: Stage {
    if isWide {
      let offset = UInt8(truncatingIfNeeded: (hi & ~Row.wideFlag) >> Row.wideStageShift)
      return Stage(uncheckedRawValue: UInt8(Stage.narrowMaxCount) + offset)
    }
    return Stage(uncheckedRawValue: UInt8(truncatingIfNeeded: hi))
  }

  /// The row's bells, for a row of 16 bells or fewer.
  internal var narrow: RawRow {
    assert(!isWide, "Narrow access to a wide row")
    return lo
  }

  /// The row's bells, for a row of 17 to 24 bells.
  internal var wide: WideRawRow {
    assert(isWide, "Wide access to a narrow row")
    return WideRawRow(lo: lo, hi: hi & Row.wideRowMask)
  }

  /// The raw bell at a zero-indexed position, in either layout.
  internal func rawBell(at position: UInt8) -> UInt8 {
    isWide ? wide.rawBell(at: position) : narrow.rawBell(at: position)
  }

  /// The zero-indexed position of a raw bell, in either layout.
  internal func rawPosition(of bell: UInt8) -> UInt8? {
    isWide ? wide.rawPosition(of: bell) : narrow.rawPosition(of: bell)
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
  /// if the array isn't a valid permutation: wrong length (must be
  /// 1...`Stage.maxCount`), a duplicate bell, or a bell outside the range
  /// implied by the array's length.
  public init(validating array: [Bell]) throws {
    guard array.count >= 1 && array.count <= Stage.maxCount else {
      throw BellMetalError.invalidBell
    }
    let stage = Stage(array.count)
    guard array.min() == .b1,
          array.max() == stage.tenor,
          Set(array).count == stage.count
    else {
      throw BellMetalError.invalidBell
    }
    if stage.usesWideLayout {
      self.init(stage: stage, wide: .build(rawStage: stage.rawValue) { array[Int($0)].rawValue })
    } else {
      self.init(stage: stage, narrow: .build(rawStage: stage.rawValue) { array[Int($0)].rawValue })
    }
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
    String((0...stage.rawValue).map { Bell.symbols[Int(rawBell(at: $0))] })
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
    return Bell(uncheckedRawValue: rawBell(at: UInt8(position - 1))) // Safe: Checked when row is built
  }
  
  
  /// Retrieve the 1-indexed position of a bell in the row.
  public subscript(bell: Bell) -> Int {
    precondition(self.stage.includes(bell), "Invalid bell for stage \(self.stage): \(bell)")
    guard let rawPosition = self.rawPosition(of: bell.rawValue) else {
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
    let stage = self.stage
    if isWide {
      return Row(stage: stage, wide: wide.composePermutation(other.wide, rawStage: stage.rawValue))
    }
    return Row(stage: stage, narrow: narrow.composePermutation(other.narrow, rawStage: stage.rawValue))
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
    let stage = self.stage
    if isWide {
      let wide = self.wide
      return Row(stage: stage, wide: .build(rawStage: stage.rawValue) { wide.rawPosition(of: $0)! })
    }
    let narrow = self.narrow
    return Row(stage: stage, narrow: .build(rawStage: stage.rawValue) { narrow.rawPosition(of: $0)! })
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
    switch (isWide, newStage.usesWideLayout) {
    case (false, false):
      return Row(stage: newStage, narrow: narrow.extend(from: stage, to: newStage))
    case (false, true):
      return Row(stage: newStage, wide: WideRawRow(widening: narrow, from: stage, to: newStage))
    case (true, _):
      return Row(stage: newStage, wide: wide.extend(from: stage, to: newStage))
    }
  }
}

extension Row {
  /// Builds a Row from 1-indexed bell numbers (e.g. `Row([1,2,3])` is rounds on singles),
  /// matching the convention used by Bell's string/character initializers.
  init(_ row: [Int]) {
    self.init(row.map { value -> Bell in
      guard let bell = Bell(number: value) else {
        fatalError("Invalid bell number: \(value)")
      }
      return bell
    })
  }
}

// MARK: - Place bell orders

extension Row {
  /// Taking this row as a leadhead, the order in which the place bells
  /// follow one another: the bell that rings place bell `p` in one lead
  /// rings place bell `q` in the next, where `q` is the place bell `p`
  /// occupies in this row. E.g. Plain Bob Minor's leadhead `135264` gives
  /// `[[1], [2, 4, 6, 5, 3]]`.
  ///
  /// Every place appears in exactly one order. Each order starts from its
  /// lowest place, and the orders are sorted by that lowest place. Hunt
  /// bells (places the leadhead leaves fixed) come out as one-element
  /// orders; filter on `count > 1` for just the working bells.
  ///
  /// This is the cycle decomposition of the permutation taking each place
  /// to the position of the bell of that number -- i.e. of `invert()`, not
  /// of the row read as place → bell.
  public var placeBellOrders: [[Int]] {
    let count = stage.count
    var seen = [Bool](repeating: false, count: count)
    var orders = [[Int]]()
    for start in 0..<count where !seen[start] {
      var order = [Int]()
      var place = start
      repeat {
        seen[place] = true
        order.append(place + 1)
        place = Int(rawPosition(of: UInt8(place))!) // Safe: every bell of the stage is present
      } while place != start
      orders.append(order)
    }
    return orders
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
