import Foundation

/// An enum representing available stages.
public enum Stage: UInt8, Sendable {
  case one = 0x0
  case two = 0x1
  case singles = 0x2
  case minimus = 0x3
  case doubles = 0x4
  case minor = 0x5
  case triples = 0x6
  case major = 0x7
  case caters = 0x8
  case royal = 0x9
  case cinques = 0xA
  case maximus = 0xB
  case thirteen = 0xC
  case fourteen = 0xD
  case fifteen = 0xE
  case sixteen = 0xF
}

extension Stage {
  /// Creates the stage with the given number of bells (1...16).
  /// - Precondition: `count` must be between 1 and 16, inclusive.
  public init(_ count: Int) {
    precondition(count >= 1 && count <= 16, "Invalid Stage number: \(count).")
    self.init(rawValue: UInt8(count - 1))! // Safe: precondition
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
    Bell(rawValue: rawValue)! // Safe: raw values are known to be the same
  }

  /// The two heaviest bells on this stage, in ringing order (e.g. 7,8 on Major).
  /// - Precondition: the stage must have at least two bells.
  public var tenorPair: (Bell, Bell) {
    precondition(self > .one, "tenorPair requires at least two bells: \(self)")
    return (Bell(rawValue: rawValue - 1)!, Bell(rawValue: rawValue)!)
  }

  /// Whether the given bell exists on this stage.
  public func includes(_ bell: Bell) -> Bool {
    bell.rawValue <= self.rawValue
  }

  /// Every bell on this stage, from the treble to the tenor.
  public var allBells: [Bell] {
    (0...rawValue).map { Bell(rawValue: $0)! }
  }

  /// Rounds on this stage, e.g. "12345678" on Major.
  public var rounds: Row {
    switch self {
    case .one:
      "1"
    case .two:
      "12"
    case .singles:
      "123"
    case .minimus:
      "1234"
    case .doubles:
      "12345"
    case .minor:
      "123456"
    case .triples:
      "1234567"
    case .major:
      "12345678"
    case .caters:
      "123456789"
    case .royal:
      "1234567890"
    case .cinques:
      "1234567890E"
    case .maximus:
      "1234567890ET"
    case .thirteen:
      "1234567890ETA"
    case .fourteen:
      "1234567890ETAB"
    case .fifteen:
      "1234567890ETABC"
    case .sixteen:
      "1234567890ETABCD"
    }
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
  /// (0-indexed) enum value, since the count is the meaningful, stable
  /// external representation.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let count = try container.decode(Int.self)
    guard count >= 1 && count <= 16 else {
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
  public var description: String {
    switch self {
    case .one: "One"
    case .two: "Two"
    case .singles: "Singles"
    case .minimus: "Minimus"
    case .doubles: "Doubles"
    case .minor: "Minor"
    case .triples: "Triples"
    case .major: "Major"
    case .caters: "Caters"
    case .royal: "Royal"
    case .cinques: "Cinques"
    case .maximus: "Maximus"
    case .thirteen: "Thirteen"
    case .fourteen: "Fourteen"
    case .fifteen: "Fifteen"
    case .sixteen: "Sixteen"
    }
  }
}
