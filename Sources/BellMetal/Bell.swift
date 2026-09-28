import Foundation

/// An individual bell, e.g. `.bT` for bell 12.
///
/// Every bell has a named constant (`.b1`...`.b9`, `.b0`, `.bE`, `.bT`,
/// `.bA`, `.bB`, `.bC`, `.bD`) spelled after its single-character symbol.
public struct Bell: RawRepresentable, Hashable, Sendable {
  /// One fewer than the bell's number, e.g. 11 for `.bT`.
  public let rawValue: UInt8

  /// Creates the bell with the given (0-indexed) raw value, e.g. 11 for
  /// `.bT`. Returns nil if it's not below `Stage.maxCount`.
  public init?(rawValue: UInt8) {
    guard Int(rawValue) < Stage.maxCount else { return nil }
    self.rawValue = rawValue
  }

  /// Creates the bell with the given raw value, which the caller has
  /// already checked is below `Stage.maxCount`.
  internal init(uncheckedRawValue rawValue: UInt8) {
    self.rawValue = rawValue
  }
}

extension Bell {
  public static let b1 = Bell(uncheckedRawValue: 0x0)
  public static let b2 = Bell(uncheckedRawValue: 0x1)
  public static let b3 = Bell(uncheckedRawValue: 0x2)
  public static let b4 = Bell(uncheckedRawValue: 0x3)
  public static let b5 = Bell(uncheckedRawValue: 0x4)
  public static let b6 = Bell(uncheckedRawValue: 0x5)
  public static let b7 = Bell(uncheckedRawValue: 0x6)
  public static let b8 = Bell(uncheckedRawValue: 0x7)
  public static let b9 = Bell(uncheckedRawValue: 0x8)
  public static let b0 = Bell(uncheckedRawValue: 0x9)
  public static let bE = Bell(uncheckedRawValue: 0xA)
  public static let bT = Bell(uncheckedRawValue: 0xB)
  public static let bA = Bell(uncheckedRawValue: 0xC)
  public static let bB = Bell(uncheckedRawValue: 0xD)
  public static let bC = Bell(uncheckedRawValue: 0xE)
  public static let bD = Bell(uncheckedRawValue: 0xF)
}

extension Bell {
  /// Each bell's single-character symbol, indexed by raw value.
  internal static let symbols: [Character] = Array("1234567890ETABCD")

  /// Raw values indexed by ASCII code, or `noBell` for characters that
  /// aren't a bell symbol.
  private static let rawValuesByASCII: [UInt8] = {
    var table = [UInt8](repeating: noBell, count: 128)
    for (rawValue, symbol) in symbols.enumerated() {
      table[Int(symbol.asciiValue!)] = UInt8(rawValue) // Safe: every symbol is ASCII
    }
    return table
  }()
  private static let noBell = UInt8.max
}

extension Bell: CustomStringConvertible {
  /// The single-character representation of this bell, e.g. "T" for bell 12.
  public var description: String {
    String(Bell.symbols[Int(rawValue)])
  }
}

extension Bell: ExpressibleByStringLiteral {
  /// Creates a bell from a single-character string, e.g. `"T"` for bell 12.
  /// - Precondition: `value` must be exactly one character, and a valid bell
  /// (one of "1"..."9", "0", "E", "T", "A", "B", "C", "D"). Use `init?(character:)`
  /// instead when the source might not satisfy that (e.g. untrusted input).
  public init(stringLiteral value: String) {
    precondition(value.count == 1, "Invalid Bell literal: \(value)")
    guard let bell = Bell(character: value[value.startIndex]) else {
      fatalError("Invalid Bell literal: \(value)")
    }
    self = bell
  }

  /// Creates a bell from a single valid bell character. See `init(stringLiteral:)`.
  public init(_ character: Character) {
    self.init(stringLiteral: String(character))
  }

  /// Creates a bell from a single valid bell character. See `init(stringLiteral:)`.
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
    guard let ascii = character.asciiValue else { return nil }
    let rawValue = Bell.rawValuesByASCII[Int(ascii)]
    guard rawValue != Bell.noBell else { return nil }
    self.init(uncheckedRawValue: rawValue)
  }
}

extension Bell {
  /// Creates the bell numbered `number`, counting from 1 (e.g. 12 for `.bT`),
  /// if `stage` has it. Returns nil otherwise, including for 0 and negative numbers.
  public init?(number: Int, on stage: Stage) {
    guard (1...stage.count).contains(number) else { return nil }
    self.init(uncheckedRawValue: UInt8(number - 1))
  }

  /// Creates the bell numbered `number`, counting from 1 (e.g. 12 for `.bT`),
  /// if any stage has it (1...`Stage.maxCount`). Returns nil otherwise.
  public init?(number: Int) {
    guard (1...Stage.maxCount).contains(number) else { return nil }
    self.init(uncheckedRawValue: UInt8(number - 1))
  }

  /// This bell's number, counting from 1 (e.g. 12 for `.bT`).
  public var number: Int {
    Int(rawValue) + 1
  }
}

extension Bell: Comparable {
  /// Bells are ordered from lightest (treble) to heaviest (tenor).
  public static func < (lhs: Bell, rhs: Bell) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// MARK: - Codable

extension Bell: Codable {
  /// Encodes/decodes as its single-character representation (e.g. "T" for bell
  /// 12), matching its string-literal form, not the raw value.
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
