import Foundation

enum MusicType: Sendable {
  case fiveSix
  case cru
  case runs
  case run(length: Int)
  case wrap
  case namedRow
  case namedRowCombo
  case tenorsReversed
  case backBellCombo
  case comboNearMiss
  case custom(name: String, score: @Sendable (Block) -> Int)
}

extension MusicType {
  public func score(_ rows: Block) -> Int {
    switch self {
    case .fiveSix:
      MusicType.scoreFiveSix(rows)
    case .cru:
      MusicType.scoreCru(rows)
    case .runs:
      MusicType.scoreRuns(rows, length: 4)
    case .run(length: let length):
      MusicType.scoreRuns(rows, length: length)
    case .wrap:
      MusicType.scoreWraps(rows)
    case .namedRow:
      MusicType.scoreNamedRows(rows)
    case .namedRowCombo:
      MusicType.scoreNamedRowCombos(rows)
    case .tenorsReversed:
      MusicType.scoreTenorsReversed(rows)
    case .backBellCombo:
      MusicType.scoreBackBellCombo(rows)
    case .comboNearMiss:
      MusicType.scoreComboNearMiss(rows)
    case .custom(_, let scoreFunction):
      scoreFunction(rows)
    }
  }
}

extension MusicType {
  internal static func scoreFiveSix(_ rows: Block) -> Int {
    guard rows.stage > .minor else { return 0 }
    let front = "xxxx"
    let back = (7...rows.stage.count)
      .compactMap { Bell(rawValue: UInt8($0))?.description }
      .joined()
    let masks = [
      front + "56" + back,
      front + "65" + back,
      "56" + back + front,
      "65" + back + front
    ].compactMap { try? Mask($0) }
    return (try? rows.count(matchingAny: masks)) ?? 0
  }
  
  internal static func scoreRuns(_ rows: Block, length: Int) -> Int {
    guard length < rows.stage.count,
          length >= 4
    else { return 0 }
    let empty = (1...(rows.stage.count - length))
      .map { _ in "x" }
      .joined()
    let runSegments = (1...rows.stage.count - length+1)
      .map {
        ($0...($0+length-1))
          .compactMap { Bell(rawValue: UInt8($0))?.description }
          .joined()
      }
    var masks: [Mask] = []
    runSegments.forEach { seg in
      if let m = try? Mask(seg + empty) { masks.append(m) }
      if let m = try? Mask(seg.reversed() + empty) { masks.append(m) }
      if let m = try? Mask(empty + seg) { masks.append(m) }
      if let m = try? Mask(empty + seg.reversed()) { masks.append(m) }
    }
    return (try? rows.count(matchingAny: masks)) ?? 0
  }
  
  internal static func scoreCru(_ rows: Block) -> Int {
    guard rows.stage == .major else { return 0 }
    let masks: [Mask] = [
      "xxxx5678",
      "xxxx6578",
      "xxxx4578",
      "xxxx5478",
      "xxxx4678",
      "xxxx6478",
      "5678xxxx",
      "6578xxxx",
      "4578xxxx",
      "5478xxxx",
      "4678xxxx",
      "6478xxxx"
      ]
    return (try? rows.count(matchingAny: masks)) ?? 0
  }
  
  internal static func scoreNamedRows(_ rows: Block) -> Int {
    let masks = NamedRow.allCases
      .compactMap { $0.row(at: rows.stage) }
      .map(Mask.init)
    return (try? rows.count(matchingAny: masks)) ?? 0
  }
  
  internal static func wrapMasks(of row: Row?) -> [(Mask, Mask)] {
    guard let row else { return [] }
    return (1...row.stage.count).compactMap { i in
      let prefix = Array(repeating: "x", count: i).joined()
      let suffix = Array(repeating: "x", count: row.stage.count - i).joined()
      let rowA = row.prefix(row.stage.count - i).map({ $0.description }).joined()
      let rowB = row.suffix(i).map({ $0.description }).joined()
      guard let maskA = try? Mask(prefix+rowA),
            let maskB = try? Mask(rowB+suffix) else {
        return nil
      }
      return (maskA, maskB)
    }
  }
  
  internal static func scoreWraps(_ rows: Block) -> Int {
    let wrapTypes = [NamedRow.rounds, .backrounds, .queens, .tittums]
      .compactMap { $0.row(at: rows.stage) }
      .map { wrapMasks(of: $0) }
    var result = 0
    for (rowA, rowB) in zip(rows, rows.dropFirst()) {
      wrapTypeLoop: for wrapType in wrapTypes {
        for (maskA, maskB) in wrapType {
          if maskA.matches(rowA) && maskB.matches(rowB) {
            result += 1
            break wrapTypeLoop
          }
        }
      }
    }
    return result
  }
  
  internal static func scoreBackBellCombo(_ rows: Block) -> Int {
    guard rows.stage == .major else { return 0 }
    let masks: [Mask] = [
      "xxxx5678",
      "5678xxxx",
      "xxxx6578",
      "6578xxxx",
      "xxxx7658",
      "7658xxxx",
      "xxxx8765",
      "8765xxxx",
      "xxxx7568",
      "7568xxxx"
    ]
    return (try? rows.count(matchingAny: masks)) ?? 0
  }
  
  internal static func scoreTenorsReversed(
    _ rows: Block,
    backstrokeStart: Bool = false
  ) -> Int {
    let (nearTenor, tenor) = rows.stage.tenorPair
    let mask = try? Mask(
      Array(repeating: "x", count: rows.stage.count - 2).joined() +
      tenor.description + nearTenor.description
    )
    guard let mask else { return 0 }
    let backstrokes = rows.groupByStroke(backstrokeStart: backstrokeStart).back
    return (try? backstrokes.count(matchingAny: [mask])) ?? 0
  }
  
  internal static func namedComboMasks(at stage: Stage) -> [Mask] {
    switch stage {
    case .triples:
      ["xxxx246", "xxxx346", "xxxx347", "xxxx374", "xxxx765", "x5x6x7x"]
    case .major:
      ["xxxx1357", "xxxx2468", "xxxx3468", "xxxx3478", "xxxx3578", "xxxx7658", "x5x6x7x8", "xxxx5768", "xxxx7468", "xxxx7568", "xxxx8765"]
    case .caters:
      ["xxxxx468", "xxxxx987", "xxxxx8495", "xxx97568", "xxx7x8x9x"]
    case .royal:
      ["xxxxx24680", "xxxxx13579", "xxxx975680", "x6x7x8x9x0"]
    case .cinques:
      ["xxxxxxx4680", "xxxxxx24680", "xxxxxxE9780", "xxxxxx9078E", "xxxxx9x0xEx"]
    case .maximus:
      ["xxxxxx24680T", "xxxxxx9078ET", "xxxxxxE9780T", "xxxxx9x0xExT"]
    case .fourteen:
      ["xxxxxxxx4680TB", "xxxxxxxxAE90TB", "xxxxxxxExTxAxB"]
    case .sixteen:
      ["xxxxxxxxxx4680TB", "xxxxxxxxxxAE90TB", "xxxxxxxxAxBxCxD"]
    default:
      []
    }
  }
  
  internal static func scoreNamedRowCombos(_ rows: Block) -> Int {
    let masks = namedComboMasks(at: rows.stage)
    return (try? rows.count(matchingAny: masks)) ?? 0
  }
  
  internal static func scoreComboNearMiss(_ rows: Block) -> Int {
    rows.count { row in
      row.stage.allBells.allSatisfy { bell in
        Swift.abs(row[bell] - (Int(bell.rawValue) + 1)) <= 1
      }
    }
  }
}


extension MusicType: CustomStringConvertible {
  var description: String {
    switch self {
    case .fiveSix:
      "56s"
    case .cru:
      "CRUs"
    case .runs:
      "4-runs"
    case .run(length: let length):
      "\(length)-runs"
    case .wrap:
      "Wraps"
    case .namedRow:
      "Named Rows"
    case .namedRowCombo:
      "Named Row Combinations"
    case .tenorsReversed:
      "Tenors-reversed"
    case .backBellCombo:
      "Back Bell Combinations"
    case .comboNearMiss:
      "Combination Near Misses"
    case .custom(name: let name, score: let score):
      name
    }
    
  }
}
