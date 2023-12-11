import Foundation


protocol MusicMask<Stage>: Equatable, Hashable {
  associatedtype Stage: StageProtocol
  
  /// Returns a match score for a single row.
  /// - Parameter row: The row to match
  /// - Returns: 0 or 1
  func matches(_ row: Row<Stage>) -> Int
  
  /// Returns a match score for a whole pull as separate rows.
  /// 0: Neither row matched
  /// 1: Either 1 row matched, or both rows matched a 2-row mask
  /// 2: Both rows matched a 1-row mask
  /// - Parameters:
  ///   - hand: The handstroke row
  ///   - back: The backstroke row
  /// - Returns: 0, 1, or 2
  func matches(hand: Row<Stage>, back: Row<Stage>) -> Int
  
  /// Returns a match score for a whole pull as a single object.
  /// 0: Neither row matched
  /// 1: Either 1 row matched, or both rows matched a 2-row mask
  /// 2: Both rows matched a 1-row mask
  /// - Parameter wholePull: The whole pull to score.
  /// - Returns: 0, 1, or 2
  func matches(_ wholePull: WholePull<Stage>) -> Int
}

public struct HalfPullMusicMask<Stage: StageProtocol>: MusicMask {
  typealias Stage = Stage
  
  let mask: Mask<Stage>
  
  init(_ mask: Mask<Stage>) {
    self.mask = mask
  }
  
  init(_ string: String) {
    self.mask = Mask<Stage>(string)
  }
  
  func matches(_ row: Row<Stage>) -> Int {
    mask.matches(row) ? 1 : 0
  }
  
  func matches(hand: Row<Stage>, back: Row<Stage>) -> Int {
    matches(hand) + matches(back)
  }
  
  func matches(_ wholePull: WholePull<Stage>) -> Int {
    let handMatch = if let hRow = wholePull.hand {
      matches(hRow)
    } else { 0 }
    let backMatch = if let bRow = wholePull.back {
      matches(bRow)
    } else { 0 }
    return handMatch + backMatch
  }
}

extension HalfPullMusicMask: ExpressibleByStringLiteral {
  public init(stringLiteral value: StringLiteralType) {
    self.mask = Mask(stringLiteral: value)
  }
}

public struct WholePullMusicMask<Stage: StageProtocol>: MusicMask {
  typealias Stage = Stage
  
  let handMask: Mask<Stage>
  let backMask: Mask<Stage>
  
  init(hand: Mask<Stage>? = nil, back: Mask<Stage>? = nil) {
    handMask = hand ?? Mask<Stage>.empty()
    backMask = back ?? Mask<Stage>.empty()
  }
  
  // Always 0: we can only match if we know parity
  func matches(_ row: Row<Stage>) -> Int { 0 }
  
  func matches(hand: Row<Stage>, back: Row<Stage>) -> Int {
    (handMask.matches(hand) && backMask.matches(back)) ? 1 : 0
  }
  
  func matchesAt(hand: Row<Stage>?) -> Bool {
    guard let hand else { return handMask.isEmpty }
    return handMask.matches(hand)
  }
  
  func matchesAt(back: Row<Stage>?) -> Bool {
    guard let back else { return backMask.isEmpty }
    return backMask.matches(back)
  }
  
  func matches(_ wholePull: WholePull<Stage>) -> Int {
    if matchesAt(hand: wholePull.hand),
       matchesAt(back: wholePull.back) {
      return 1
    } else {
      return 0
    }
  }
}
