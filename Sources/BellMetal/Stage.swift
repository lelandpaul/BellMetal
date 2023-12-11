import Foundation

public protocol StageProtocol {
  static var n: Int { get }
  static var description: String { get }
  static var musicScheme: MusicScheme<Self> { get set }
}

extension StageProtocol {
  public static var bells: [Bell] {
    Array(1...n).map { Bell(rawValue: $0)! }
  }
  public static var tenor: Bell {
    Bell(rawValue: n)! // Safe: stage ns are known in advance
  }
  public static var nearTenor: Bell {
    Bell(rawValue: n-1)! // Safe: stage ns are known in advance
  }
}

public enum Singles: StageProtocol {
  public static let n: Int = 3
  public static let description: String = "Singles"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Minimus: StageProtocol {
  public static let n: Int = 4
  public static let description: String = "Minimus"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Doubles: StageProtocol {
  public static let n: Int = 5
  public static let description: String = "Doubles"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Minor: StageProtocol {
  public static let n: Int = 6
  public static let description: String = "Minor"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Triples: StageProtocol {
  public static let n: Int = 7
  public static let description: String = "Triples"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Major: StageProtocol {
  public static let n: Int = 8
  public static let description: String = "Major"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Caters: StageProtocol {
  public static let n: Int = 9
  public static let description: String = "Caters"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Royal: StageProtocol {
  public static let n: Int = 10
  public static let description: String = "Royal"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Cinques: StageProtocol {
  public static let n: Int = 11
  public static let description: String = "Cinques"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Maximus: StageProtocol {
  public static let n: Int = 12
  public static let description: String = "Maximus"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Thirteen: StageProtocol {
  public static let n: Int = 13
  public static let description: String = "Thirteen"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Fourteen: StageProtocol {
  public static let n: Int = 14
  public static let description: String = "Fourteen"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Fifteen: StageProtocol {
  public static let n: Int = 15
  public static let description: String = "Fifteen"
  public static var musicScheme = MusicScheme<Self>.standard
}

public enum Sixteen: StageProtocol {
  public static let n: Int = 16
  public static let description: String = "Sixteen"
  public static var musicScheme = MusicScheme<Self>.standard
}
