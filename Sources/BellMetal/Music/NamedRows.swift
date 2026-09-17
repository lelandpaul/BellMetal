import Foundation

/// A well-known "special" row, often used as a target when composing or
/// scoring music. Not every named row is defined at every stage -- see
/// `row(at:)`.
public enum NamedRow: Equatable, Hashable, CaseIterable, Sendable {
  /// Rounds reversed, e.g. "87654321" on Major.
  case backrounds
  /// A "spread" variant of `tittums`, with the front half reversed.
  case explodedtittums
  /// A well-known named row (defined per-stage, from Doubles upward).
  case hagdyke
  /// Rounds with the first and last bells fixed and every other adjacent pair swapped.
  case intermediate
  /// A well-known named row (defined per-stage, from Doubles upward).
  case jacks
  /// `jacks` combined with the `intermediate` transposition.
  case jokers
  /// The odd bells descending, followed by the even bells ascending, e.g. "531246" on Minor.
  case kings
  /// `kings` with the first two bells swapped.
  case princes
  /// `queens` with the middle two bells swapped.
  case princesses
  /// The odd bells ascending, followed by the even bells ascending, e.g. "135246" on Minor.
  case queens
  /// The bells in their home positions, e.g. "12345678" on Major.
  case rounds
  /// The front and back halves of rounds interleaved, e.g. "15263748" on Major.
  case tittums
  /// A well-known named row, defined only for Minor through Royal.
  case whittingtons
  /// A well-known named row, defined only on Major.
  case rollercoaster
  /// A well-known named row, defined only on Major.
  case seesaw
  /// A well-known named row, defined only on Major.
  case sawsee
}

// MARK: - Codable

extension NamedRow: Codable {
  /// Encodes/decodes as the case name (e.g. "backrounds"), spelled out
  /// explicitly here rather than relying on synthesis, since a plain
  /// no-associated-values enum's default synthesized representation isn't
  /// guaranteed to be this simple string form.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let name = try container.decode(String.self)
    guard let namedRow = NamedRow.allCases.first(where: { "\($0)" == name }) else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid NamedRow: \(name)")
    }
    self = namedRow
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode("\(self)")
  }
}

extension NamedRow {
  /// This named row at the given stage, or nil if it isn't defined there.
  public func row(at stage: Stage) -> Row? {
    switch self {
    case .backrounds:
      return Row((1...stage.count).reversed())
    case .explodedtittums:
      let half = (stage.count + 1) / 2
      let upwards = Array((1...half).reversed())
      let downwards = Array(half+1...stage.count)
      return Row(upwards.interleave(with: downwards))
    case .hagdyke:
      return hagdyke(at: stage)
    case .intermediate:
      return stage.rounds * intermediateChange(at: stage)
    case .jacks:
      return jacks(at: stage)
    case .jokers:
      guard let j = jacks(at: stage) else { return nil }
      return j * intermediateChange(at: stage)
    case .kings:
      return kings(at: stage)
    case .princes:
      return Row([2,1] + (3...stage.count)) * kings(at: stage)
    case .princesses:
      let half = (stage.count + 1) / 2
      return queens(at: stage) * Row((1..<half) + [half+1, half] + (half+2...stage.count))
    case .queens:
      return queens(at: stage)
    case .rounds:
      return stage.rounds
    case .tittums:
      let half = (stage.count + 1) / 2
      let upper = Array(1...half)
      let lower = Array(half+1...stage.count)
      return Row(upper.interleave(with: lower))
    case .whittingtons:
      guard stage > .doubles, stage < .cinques else { return nil }
      let array = ([1,2] + Array(3...stage.count)
        .partitionMap(on: { $0.isMultiple(of: 2) }) { evens, odds in
          odds.reversed() + evens
        }
      )
      return Row(array)
    case .rollercoaster:
      return stage == .major ? "14327658" : nil
    case .seesaw:
      return stage == .major ? "43215678" : nil
    case .sawsee:
      return stage == .major ? "56781234" : nil
    }
  }
  
  private func hagdyke(at stage: Stage) -> Row? {
    switch stage {
    case .doubles: "34125"
    case .minor: "341256"
    case .triples: "1256347"
    case .major: "12563478"
    case .caters: "341278569"
    case .royal: "3412785690"
    case .cinques: "1256349078E"
    case .maximus: "1256349078ET"
    case .thirteen: "34127856ET90A"
    case .fourteen: "34127856ET90AB"
    case .fifteen: "1256349078ABETC"
    case .sixteen: "1256349078ABETCD"
    default: nil
    }
  }
  
  private func jacks(at stage: Stage) -> Row? {
    switch stage {
    case .doubles: "14523"
    case .minor: "145236"
    case .triples: "1674523"
    case .major: "16745238"
    case .caters: "189674523"
    case .royal: "1896745230"
    case .cinques: "10E89674523"
    case .maximus: "10E89674523T"
    case .thirteen: "1TA0E89674523"
    case .fourteen: "1TA0E89674523B"
    case .fifteen: "1BCTA0E89674523"
    case .sixteen: "1BCTA0E89674523D"
    default: nil
    }
  }
  
  private func intermediateChange(at stage: Stage) -> PlaceNotation {
    (stage.even ? try! PlaceNotation(string: "1\(stage.count)") : "1")
  }
  
  private func queens(at stage: Stage) -> Row {
    Row(Array(1...stage.count)
      .partitionMap(on: { $0.isMultiple(of: 2) }) { evens, odds in
        odds + evens
      })
  }
  
  private func kings(at stage: Stage) -> Row {
    Row(Array(1...stage.count)
      .partitionMap(on: { $0.isMultiple(of: 2) }) { evens, odds in
        odds.reversed() + evens
      })
  }
}

