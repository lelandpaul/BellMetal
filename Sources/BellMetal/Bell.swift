import Foundation

/// An enum representing an individual bell.
public enum Bell: UInt8 {
  case b1, b2, b3, b4, b5, b6, b7, b8, b9, b0, bE, bT, bA, bB, bC, bD
}

extension Bell: CustomStringConvertible {
  public var description: String {
    switch self {
    case .b1: "1"
    case .b2: "2"
    case .b3: "3"
    case .b4: "4"
    case .b5: "5"
    case .b6: "6"
    case .b7: "7"
    case .b8: "8"
    case .b9: "9"
    case .b0: "0"
    case .bE: "E"
    case .bT: "T"
    case .bA: "A"
    case .bB: "B"
    case .bC: "C"
    case .bD: "D"
    }
  }
}

extension Bell: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    precondition(value.count == 1, "Invalid Bell literal: \(value)")
    guard let bell = Bell(character: value[value.startIndex]) else {
      fatalError("Invalid Bell literal: \(value)")
    }
    self = bell
  }

  public init(_ character: Character) {
    self.init(stringLiteral: String(character))
  }

  public init(_ character: Substring) {
    self.init(stringLiteral: String(character))
  }
}

extension Bell {
  /// Safe, failable construction from a single-character representation of a bell
  /// (one of "1"..."9", "0", "E", "T", "A", "B", "C", "D"). Returns nil for any
  /// other character, rather than trapping like the ExpressibleByStringLiteral
  /// initializer -- use this when the character comes from untrusted input.
  public init?(character: Character) {
    switch character {
    case "1": self = .b1
    case "2": self = .b2
    case "3": self = .b3
    case "4": self = .b4
    case "5": self = .b5
    case "6": self = .b6
    case "7": self = .b7
    case "8": self = .b8
    case "9": self = .b9
    case "0": self = .b0
    case "E": self = .bE
    case "T": self = .bT
    case "A": self = .bA
    case "B": self = .bB
    case "C": self = .bC
    case "D": self = .bD
    default: return nil
    }
  }
}

extension Bell: Comparable {
  public static func < (lhs: Bell, rhs: Bell) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// MARK: - Codable

extension Bell: Codable {
  /// Encodes/decodes as its single-character representation (e.g. "T" for bell
  /// 12), matching its string-literal form, not the raw enum value.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    guard string.count == 1, let bell = Bell(character: string[string.startIndex]) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid Bell character: \(string)")
    }
    self = bell
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}
