import Foundation

enum NamedRow<Stage: StageProtocol>: Equatable, Hashable, CaseIterable {
  case backrounds
  case explodedtittums
  case hagdyke
  case intermediate
  case jacks
  case jokers
  case kings
  case princes
  case princesses
  case queens
  case rounds
  case tittums
  case whittingtons
}

extension NamedRow {
  var row: Row<Stage>? {
    switch self {
    case .backrounds:
      return (1...Stage.n).reversed().toRow()
    case .explodedtittums:
      let half = (Stage.n + 1) / 2
      let upwards = Array((1...half).reversed())
      let downwards = Array(half+1...Stage.n)
      return upwards.interleave(with: downwards).toRow()
    case .hagdyke:
      return hagdyke
    case .intermediate:
      return Stage.rounds * (Stage.n.isMultiple(of: 2) ? Change(places: [1, Stage.n]) : Change(places: [1]))
    case .jacks:
      return jacks
    case .jokers:
      guard let jacks else { return nil }
      return jacks * intermediateChange
    case .kings:
      return kings
    case .princes:
      return Stage.rounds * Change(places: Array(3...Stage.n)) * kings
    case .princesses:
      let half = (Stage.n + 1) / 2
      return queens * Change(places: Array(1..<half) + Array(half+2...Stage.n))
    case .queens:
      return queens
    case .rounds:
      return Stage.rounds
    case .tittums:
      let half = (Stage.n + 1) / 2
      let upper = Array((1...half))
      let lower = Array((half+1...Stage.n))
      return upper.interleave(with: lower).toRow()
    case .whittingtons:
      guard Stage.n > 5, Stage.n < 11 else { return nil }
      return ([1,2] + Array(3...Stage.n)
        .partitionMap(on: { $0.isMultiple(of: 2) }) { evens, odds in
          odds.reversed() + evens
        }
      ).toRow()
    }
  }
  
  private var hagdyke: Row<Stage>? {
    switch Stage.n {
    case 5: "34125"
    case 6: "341256"
    case 7: "1256347"
    case 8: "12563478"
    case 9: "341278569"
    case 10: "3412785690"
    case 11: "1256349078E"
    case 12: "1256349078ET"
    case 13: "34127856ET90A"
    case 14: "34127856ET90AB"
    case 15: "1256349078ABETC"
    case 16: "1256349078ABETCD"
    default: nil
    }
  }
  
  private var jacks: Row<Stage>? {
    switch Stage.n {
    case 5: "14523"
    case 6: "145236"
    case 7: "1674523"
    case 8: "16745238"
    case 9: "189674523"
    case 10: "1896745230"
    case 11: "10E89674523"
    case 12: "10E89674523T"
    case 13: "1TA0E89674523"
    case 14: "1TA0E89674523B"
    case 15: "1BCTA0E89674523"
    case 16: "1BCTA0E89674523D"
    default: nil
    }
  }
  
  private var intermediateChange: Change<Stage> {
    (Stage.n.isMultiple(of: 2) ? Change(places: [1, Stage.n]) : Change(places: [1]))
  }
  
  private var queens: Row<Stage> {
    Array(1...Stage.n)
      .partitionMap(on: { $0.isMultiple(of: 2) }) { evens, odds in
        odds + evens
      }
      .toRow()!
  }
  
  private var kings: Row<Stage> {
    Array(1...Stage.n)
      .partitionMap(on: { $0.isMultiple(of: 2) }) { evens, odds in
        odds.reversed() + evens
      }
      .toRow()!
  }
}

