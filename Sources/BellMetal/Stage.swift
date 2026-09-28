import Foundation

/// The number of bells something is rung on, e.g. `.major` for 8 bells.
///
/// Every supported stage has a named constant (`.one`, `.minor`,
/// `.maximus`, `.sixteen`, `.twentyFour`, ...); `init(_:)` builds one
/// from a bell count.
public struct Stage: RawRepresentable, Hashable, Sendable {
  /// One fewer than the number of bells, e.g. 7 for `.major`.
  public let rawValue: UInt8

  /// Creates the stage with the given (0-indexed) raw value, e.g. 7 for
  /// `.major`. Returns nil if it's not below `Stage.maxCount`.
  public init?(rawValue: UInt8) {
    guard Int(rawValue) < Stage.maxCount else { return nil }
    self.rawValue = rawValue
  }

  /// Creates the stage with the given raw value, which the caller has
  /// already checked is below `Stage.maxCount`.
  internal init(uncheckedRawValue rawValue: UInt8) {
    self.rawValue = rawValue
  }

  /// The largest supported number of bells.
  public static let maxCount = 24

  /// The largest number of bells stored in the narrow (`RawRow`) layout.
  internal static let narrowMaxCount: UInt8 = 16

  /// Whether rows at this stage use the wide (`WideRawRow`) layout.
  internal var usesWideLayout: Bool {
    rawValue >= Stage.narrowMaxCount
  }
}

extension Stage {
  public static let one = Stage(uncheckedRawValue: 0x0)
  public static let two = Stage(uncheckedRawValue: 0x1)
  public static let singles = Stage(uncheckedRawValue: 0x2)
  public static let minimus = Stage(uncheckedRawValue: 0x3)
  public static let doubles = Stage(uncheckedRawValue: 0x4)
  public static let minor = Stage(uncheckedRawValue: 0x5)
  public static let triples = Stage(uncheckedRawValue: 0x6)
  public static let major = Stage(uncheckedRawValue: 0x7)
  public static let caters = Stage(uncheckedRawValue: 0x8)
  public static let royal = Stage(uncheckedRawValue: 0x9)
  public static let cinques = Stage(uncheckedRawValue: 0xA)
  public static let maximus = Stage(uncheckedRawValue: 0xB)
  public static let thirteen = Stage(uncheckedRawValue: 0xC)
  public static let fourteen = Stage(uncheckedRawValue: 0xD)
  public static let fifteen = Stage(uncheckedRawValue: 0xE)
  public static let sixteen = Stage(uncheckedRawValue: 0xF)
  public static let seventeen = Stage(uncheckedRawValue: 0x10)
  public static let eighteen = Stage(uncheckedRawValue: 0x11)
  public static let nineteen = Stage(uncheckedRawValue: 0x12)
  public static let twenty = Stage(uncheckedRawValue: 0x13)
  public static let twentyOne = Stage(uncheckedRawValue: 0x14)
  public static let twentyTwo = Stage(uncheckedRawValue: 0x15)
  public static let twentyThree = Stage(uncheckedRawValue: 0x16)
  public static let twentyFour = Stage(uncheckedRawValue: 0x17)
}

extension Stage {
  /// Creates the stage with the given number of bells (1...`Stage.maxCount`).
  /// - Precondition: `count` must be between 1 and `Stage.maxCount`, inclusive.
  public init(_ count: Int) {
    precondition(count >= 1 && count <= Stage.maxCount, "Invalid Stage number: \(count).")
    self.init(uncheckedRawValue: UInt8(count - 1))
  }

  /// The number of bells on this stage, e.g. 8 for `.major`.
  public var count: Int {
    Int(rawValue) + 1
  }

  /// Whether this stage has an even number of bells.
  public var even: Bool {
    count.isMultiple(of: 2)
  }
}

extension Stage {
  /// The heaviest (highest-numbered) bell on this stage.
  public var tenor: Bell {
    Bell(uncheckedRawValue: rawValue) // Safe: every stage's tenor is a valid bell
  }

  /// The two heaviest bells on this stage, in ringing order (e.g. 7,8 on Major).
  /// - Precondition: the stage must have at least two bells.
  public var tenorPair: (Bell, Bell) {
    precondition(self > .one, "tenorPair requires at least two bells: \(self)")
    return (Bell(uncheckedRawValue: rawValue - 1), Bell(uncheckedRawValue: rawValue))
  }

  /// Whether the given bell exists on this stage.
  public func includes(_ bell: Bell) -> Bool {
    bell.rawValue <= self.rawValue
  }

  /// Every bell on this stage, from the treble to the tenor.
  public var allBells: [Bell] {
    (0...rawValue).map { Bell(uncheckedRawValue: $0) }
  }

  /// Rounds on this stage, e.g. "12345678" on Major.
  public var rounds: Row {
    usesWideLayout
      ? Row(stage: self, wide: .rounds(rawStage: rawValue))
      : Row(stage: self, narrow: .rounds(rawStage: rawValue))
  }
}

// MARK: - Comparable

extension Stage: Comparable {
  /// Stages are ordered by number of bells.
  public static func < (lhs: Stage, rhs: Stage) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// MARK: - Codable

extension Stage: Codable {
  /// Encodes/decodes as the bell count (e.g. 8 for Major), not the raw
  /// (0-indexed) value, since the count is the meaningful, stable
  /// external representation.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let count = try container.decode(Int.self)
    guard count >= 1 && count <= Stage.maxCount else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid Stage bell count: \(count)")
    }
    self.init(count)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(count)
  }
}

// MARK: - CustomStringConvertible

extension Stage: CustomStringConvertible {
  /// Each stage's name, indexed by raw value.
  private static let names = [
    "One", "Two", "Singles", "Minimus", "Doubles", "Minor", "Triples", "Major",
    "Caters", "Royal", "Cinques", "Maximus", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
    "Seventeen", "Eighteen", "Nineteen", "Twenty",
    "Twenty-One", "Twenty-Two", "Twenty-Three", "Twenty-Four",
  ]

  public var description: String {
    Stage.names[Int(rawValue)]
  }
}
