import Foundation

struct MusicScheme: Sendable {
  let scheme: [(type: MusicType, weight: Int)]
  
  public init(_ scheme: [(MusicType, weight: Int)]) {
    self.scheme = scheme
  }
  
  static let shared: MusicScheme = .init([
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
  
  typealias ScoreDetail = (type: MusicType, weight: Int, score: Int)
  
  public func scoreDetails(_ block: Block) -> [ScoreDetail] {
    scheme.map { pair in
      (type: pair.type, weight: pair.weight, score: pair.type.score(block) * pair.weight)
    }
  }
  
  public func scoreDetails(_ rows: [Row]) -> [ScoreDetail] {
    scoreDetails(Block(rows))
  }
}

