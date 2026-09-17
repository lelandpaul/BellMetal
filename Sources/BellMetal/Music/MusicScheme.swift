import Foundation

/// A scheme for scoring the musicality of a block.
/// The default, `.shared`, mimics [CompLib](complib.org)'s
/// default music scheme as far as possible. `\Block.musicScore`
/// uses `.shared` by default.
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
  /// Compute the overall music score for a given `Block`.
  /// - Parameter block: The `Block` to score.
  /// - Parameter backstrokeStart: Whether to score the `Block` as though
  /// the first row is a backstroke.
  /// - Returns: A score.
  public func score(_ block: Block, backstrokeStart: Bool = false) -> Int {
    scheme.reduce(into: 0) { result, pair in
      result += pair.type.score(block) * pair.weight
    }
  }
  
  /// Compute the overall music score for a sequence of `Row`s.
  /// - Parameter rows: The `Row`s to score
  /// - Parameter backstrokeStart: Whether to score the `Row`s as
  /// though the first row is a backstroke.
  /// - Returns: A score.
  public func score(_ rows: [Row], backstrokeStart: Bool = false) -> Int {
    score(Block(rows), backstrokeStart: backstrokeStart)
  }
  
  public typealias ScoreDetail = (type: MusicType, weight: Int, score: Int)
  
  /// Get a breakdown by `MusicType` of the score for a given `Block`.
  /// - Parameter block: The `Block` to score.
  /// - Parameter backstrokeStart: Whether to score the `Block` as
  /// though the first row is a backstroke.
  /// - Returns: A summary of the score by `MusicType.`
  public func scoreDetails(_ block: Block, backstrokeStart: Bool = false) -> [ScoreDetail] {
    scheme.map { pair in
      (type: pair.type, weight: pair.weight, score: pair.type.score(block, backstrokeStart: backstrokeStart) * pair.weight)
    }
  }
  
  /// Get a breakdown by `MusicType` of the score for a given sequence of Rows.
  /// - Parameter block: The `Row`s to score.
  /// - Parameter backstrokeStart: Whether to score the `Row`s as
  /// though the first row is a backstroke.
  /// - Returns: A summary of the score by `MusicType.`
  public func scoreDetails(_ rows: [Row], backstrokeStart: Bool = false) -> [ScoreDetail] {
    scoreDetails(Block(rows), backstrokeStart: backstrokeStart)
  }
}

extension Block {
  /// Get the music score on a given scheme, defaulting to `.shared`.
  /// - Parameter scheme: The scheme to score on.
  /// - Parameter backstrokeStart: Whether to score the `Row`s as
  /// though the first row is a backstroke.
  /// - Returns: The score.
  public func musicScore(_ scheme: MusicScheme = .shared, backstrokeStart: Bool = false) -> Int {
    scheme.score(self, backstrokeStart: backstrokeStart)
  }
<<<<<<< HEAD
  
  /// Get a breakdown of the music score by `MusicType` on some scheme, defaulting to `.shared`.
  /// - Parameter scheme: The scheme to score on.
  /// - Parameter backstrokeStart: Whether to score the `Row`s as
  /// though the first row is a backstroke.
  /// - Returns: The score breakdown.
  public func musicScoreDetails(_ scheme: MusicScheme = .shared, backstrokeStart: Bool = false) -> [MusicScheme.ScoreDetail] {
    scheme.scoreDetails(self, backstrokeStart: backstrokeStart)
||||||| dee21d1
  
  public func musicScoreDetails(_ scheme: MusicScheme = .shared) -> [MusicScheme.ScoreDetail] {
    scheme.scoreDetails(self)
=======

  public func musicScoreDetails(_ scheme: MusicScheme = .shared) -> [MusicScheme.ScoreDetail] {
    scheme.scoreDetails(self)
>>>>>>> develop
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
