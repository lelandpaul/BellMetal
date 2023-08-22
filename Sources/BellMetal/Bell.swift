import Foundation

public enum Bell: Int, Comparable, CustomStringConvertible {
  public static func < (lhs: Bell, rhs: Bell) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
  
  case b1 = 1 // skip 0 to avoid off-by-one errors elsewhere
  case b2, b3, b4, b5, b6, b7, b8, b9, b0, bE, bT, bA, bB, bC, bD
  
  static func from(_ name: Character) throws -> Bell {
    return switch name {
    case "1": .b1
    case "2": .b2
    case "3": .b3
    case "4": .b4
    case "5": .b5
    case "6": .b6
    case "7": .b7
    case "8": .b8
    case "9": .b9
    case "0": .b0
    case "E": .bE
    case "T": .bT
    case "A": .bA
    case "B": .bB
    case "C": .bC
    case "D": .bD
    default: throw BellMetalError.invalidBell
    }
  }
  
  public var description: String {
    switch self {
    case .b1:
      "1"
    case .b2:
      "2"
    case .b3:
      "3"
    case .b4:
      "4"
    case .b5:
      "5"
    case .b6:
      "6"
    case .b7:
      "7"
    case .b8:
      "8"
    case .b9:
      "9"
    case .b0:
      "0"
    case .bE:
      "E"
    case .bT:
      "T"
    case .bA:
      "A"
    case .bB:
      "B"
    case .bC:
      "C"
    case .bD:
      "D"
    }
  }
}

// MARK: - reordering

extension [Bell] {
  subscript(_ row: [Bell]) -> [Bell] {
    return row.map { self[$0.rawValue-1] }
  }
}
