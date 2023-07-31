import Foundation

protocol StageProtocol {
  static var n: Int { get }
  static var description: String { get }
}

extension StageProtocol {
  static var bells: [Bell] {
    Array(1...n).map { Bell(rawValue: $0)! }
  }
  static var tenor: Bell {
    Bell(rawValue: n)! // Safe: stage ns are known in advance
  }
  static var nearTenor: Bell {
    Bell(rawValue: n-1)!
  }
}

enum Singles: StageProtocol {
  static let n: Int = 3
  static let description: String = "Singles"
}

enum Minimus: StageProtocol {
  static let n: Int = 4
  static let description: String = "Minimus"
}

enum Doubles: StageProtocol {
  static let n: Int = 5
  static let description: String = "Doubles"
}

enum Minor: StageProtocol {
  static let n: Int = 6
  static let description: String = "Minor"
}

enum Triples: StageProtocol {
  static let n: Int = 7
  static let description: String = "Triples"
}

enum Major: StageProtocol {
  static let n: Int = 8
  static let description: String = "Major"
}

enum Caters: StageProtocol {
  static let n: Int = 9
  static let description: String = "Caters"
}

enum Royal: StageProtocol {
  static let n: Int = 10
  static let description: String = "Royal"
}

enum Cinques: StageProtocol {
  static let n: Int = 11
  static let description: String = "Cinques"
}

enum Maximus: StageProtocol {
  static let n: Int = 12
  static let description: String = "Maximus"
}

enum Thirteen: StageProtocol {
  static let n: Int = 13
  static let description: String = "Thirteen"
}

enum Fourteen: StageProtocol {
  static let n: Int = 14
  static let description: String = "Fourteen"
}

enum Fifteen: StageProtocol {
  static let n: Int = 15
  static let description: String = "Fifteen"
}

enum Sixteen: StageProtocol {
  static let n: Int = 16
  static let description: String = "Sixteen"
}
