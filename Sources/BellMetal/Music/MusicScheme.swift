import Foundation

public struct MusicScheme: Sendable {
  let scheme: [(type: MusicType, weight: Int)]
  
  public init(_ scheme: [(MusicType, weight: Int)]) {
    self.scheme = scheme
  }
  
  public static let shared: MusicScheme = .init([
    (type: .fiveSix, weight: 1),
    (type: .cru, weight: 1),
    (type: .runs, weight: 1),
    (type: .wrap, weight: 1),
    (type: .namedRow, weight: 1),
    (type: .namedRowCombo, weight: 1),
    (type: .tenorsReversed, weight: -1),
    (type: .backBellCombo, weight: 1),
    (type: .comboNearMiss, weight: 1),
  ])
}

extension MusicScheme {
  public func score(_ block: Block) -> Int {
    scheme.reduce(into: 0) { result, pair in
      result += pair.type.score(block) * pair.weight
    }
  }
  
  public func score(_ rows: [Row]) -> Int {
    score(Block(rows))
  }
  
  public typealias ScoreDetail = (type: MusicType, weight: Int, score: Int)
  
  public func scoreDetails(_ block: Block) -> [ScoreDetail] {
    scheme.map { pair in
      (type: pair.type, weight: pair.weight, score: pair.type.score(block) * pair.weight)
    }
  }
  
  public func scoreDetails(_ rows: [Row]) -> [ScoreDetail] {
    scoreDetails(Block(rows))
  }
}

extension Block {
  public func musicScore(_ scheme: MusicScheme = .shared) -> Int {
    scheme.score(self)
  }

  public func musicScoreDetails(_ scheme: MusicScheme = .shared) -> [MusicScheme.ScoreDetail] {
    scheme.scoreDetails(self)
  }
}

// MARK: - Codable

extension MusicScheme: Codable {
  /// Tuples aren't Codable, so `scheme` is encoded/decoded as an array of this
  /// equivalent struct instead. Encoding (or decoding) fails if any entry's
  /// MusicType is `.custom`, since that carries a closure -- see MusicType's
  /// own Codable conformance.
  private struct Entry: Codable {
    let type: MusicType
    let weight: Int
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let entries = try container.decode([Entry].self)
    self.scheme = entries.map { (type: $0.type, weight: $0.weight) }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(scheme.map { Entry(type: $0.type, weight: $0.weight) })
  }
}
