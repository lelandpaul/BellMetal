import Foundation

/// An enum representing available stages.
public enum Stage: UInt8 {
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
  public init(_ count: Int) {
    precondition(count >= 1 && count <= 16, "Invalid Stage number: \(count).")
    self.init(rawValue: UInt8(count - 1))! // Safe: precondition
  }
  
  public var count: Int {
    Int(rawValue) + 1
  }
  
  public var even: Bool {
    count.isMultiple(of: 2)
  }
}

extension Stage {
  public var tenor: Bell {
    Bell(rawValue: rawValue)! // Safe: raw values are known to be the same
  }
  
  public var tenorPair: (Bell, Bell) {
    (Bell(rawValue: rawValue - 1)!, Bell(rawValue: rawValue)!)
  }
  
  public func includes(_ bell: Bell) -> Bool {
    bell.rawValue <= self.rawValue
  }
  
  public var allBells: [Bell] {
    (0...rawValue).map { Bell(rawValue: $0)! }
  }
  
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
  public static func < (lhs: Stage, rhs: Stage) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
