import Foundation

/// A single change (i.e. a permutation composed
/// of disjoint adjacent transpositions).
public struct Change<Stage: StageProtocol> {
  static var stage: Int { Stage.n }
  let pn: String // the place notation for this place
  let places: [Int] // all of the places made; [0] if no places are made
  var row: Row<Stage> {
    let rounds = (1...Stage.n).map { Bell(rawValue: $0)! }
    var newrow = rounds
    for i in 0 ..< Stage.n {
      newrow[apply(i + 1) - 1] = rounds[i]
    }
    return try! Row<Stage>(newrow)
  }
  
  /// Initialize from place notation
  /// - Parameter pn: place notation
  init(pn: String) {
    self.pn = pn
    if ["-","x"].contains(pn) {
      self.places = []
      return
    }
    let roundsBellsInPlaces = pn.map { try! Bell.from($0) }
    if let maxBell = roundsBellsInPlaces.max(),
       maxBell > Stage.tenor {
      fatalError("Place notation \(maxBell) invalid for stage \(Stage.description)")
    }
    self.places = roundsBellsInPlaces.sorted().map { $0.rawValue }
  }
  
  /// Initialize just from set of places
  /// - Parameter places: the places made
  init(places: [Int]) {
    if let maxPlace = places.max(),
       maxPlace > Stage.n {
      fatalError("Invalid change \(places) for stage \(Stage.description)")
    }
    self.places = places.sorted()
    self.pn = self.places.map {
      Bell(rawValue: $0)!.description
    }.joined()
  }
  
  /// Where does this change move the bell in a given place?
  /// - Parameter position: The starting place
  /// - Returns: The ending place
  public func apply(_ position: Int) -> Int {
    if places.contains(position) {
      return position
    }
    let relPlace = places.filter { $0 < Int(position) }.max() ?? 0
    let dir = (position - relPlace) % 2 == 0 ? -1 : 1
    return position + dir
  }
}

// MARK: - Conformance

extension Change: Equatable {
  public static func == (lhs: Change, rhs: Change) -> Bool {
    lhs.pn == rhs.pn &&
    lhs.places == rhs.places
  }
}

extension Change: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(pn: value)
  }
}

extension Change: Hashable { }

// MARK: - Aliases

public typealias Change3 = Change<Singles>
public typealias Change4 = Change<Minimus>
public typealias Change5 = Change<Doubles>
public typealias Change6 = Change<Minor>
public typealias Change7 = Change<Triples>
public typealias Change8 = Change<Major>
public typealias Change9 = Change<Caters>
public typealias Change0 = Change<Royal>
public typealias ChangeE = Change<Cinques>
public typealias ChangeT = Change<Maximus>
public typealias ChangeA = Change<Thirteen>
public typealias ChangeB = Change<Fourteen>
public typealias ChangeC = Change<Fifteen>
public typealias ChangeD = Change<Sixteen>

// MARK: - Operators

extension Change {
  public static func *(lhs: Row<Stage>, rhs: Change<Stage>) -> Row<Stage> {
    lhs * rhs.row
  }
  
  public static func *(lhs: Change<Stage>, rhs: Change<Stage>) -> Row<Stage> {
    lhs.row * rhs.row
  }
  
  public static func +(lhs: Change<Stage>, rhs: Change<Stage>) -> Block<Stage> {
    Block<Stage>(pn: lhs.pn + rhs.pn)
  }
}

extension Change {
  public func isDisjoint(with other: Change<Stage>) -> Bool {
    for p in places {
      if other.places.contains(p) {
        return false
      }
    }
    return true
  }
}
