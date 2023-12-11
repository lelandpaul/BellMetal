import Foundation

public enum MusicType<Stage: StageProtocol>: Hashable, CustomStringConvertible {
  case fiveSix(weight: Int = 1)
  case cru(weight: Int = 1)
  case runs(weight: Int = 1)
  case run(weight: Int = 1, length: Int)
  case wrap(weight: Int = 1)
  case namedRow(weight: Int = 1)
  case namedRowCombo(weight: Int = 1)
  case tenorsReversed(weight: Int = -1)
  case customWhole(weight: Int = 1, name: String, masks: [WholePullMusicMask<Stage>])
  case customHalf(weight: Int = 1, name: String, masks: [HalfPullMusicMask<Stage>])
  
  public var description: String {
    switch self {
    case .fiveSix(weight: let weight):
      "fiveSix(\(weight))"
    case .cru(weight: let weight):
      "cru(\(weight))"
    case .runs(weight: let weight):
      "runs(\(weight))"
    case .run(weight: let weight, length: let length):
      "runsOf\(length)(\(weight))"
    case .wrap(weight: let weight):
      "wrap(\(weight))"
    case .namedRow(weight: let weight):
      "namedRow(\(weight))"
    case .namedRowCombo(weight: let weight):
      "namedRowCombo(\(weight))"
    case .tenorsReversed(weight: let weight):
      "tenorsReversed(\(weight))"
    case .customWhole(weight: let weight, name: let name, _):
      "\(name)(\(weight))"
    case .customHalf(weight: let weight, name: let name, _):
      "\(name)(\(weight))"
    }
  }
}

extension MusicType {
  
  var weight: Int {
    switch self {
    case .fiveSix(let weight), .cru(let weight), .runs(let weight), .run(let weight, _), .wrap(let weight), .namedRow(let weight), .namedRowCombo(let weight), .tenorsReversed(let weight), .customWhole(let weight, _, _), .customHalf(let weight, _, _):
      weight
    }
  }
  
  var isWholePull: Bool {
    switch self {
    case .wrap: true
    case .tenorsReversed: true
    default: false
    }
  }
  
  var masks: [any MusicMask<Stage>] {
    return switch self {
    case .fiveSix: 
      MaskGenerator.fiveSix()
    case .cru: 
      MaskGenerator.cru()
    case .runs:
      (4...Stage.n-1).flatMap(MaskGenerator.run(length:))
    case .run(_, let length):
      MaskGenerator.run(length: length)
    case .namedRow:
      MaskGenerator.namedRows()
    case .namedRowCombo:
      MaskGenerator.namedRowCombos()
    case .customWhole(_, _, let masks):
      masks
    case .customHalf(_, _, let masks):
      masks
    case .wrap:
      MaskGenerator.wraps()
    case .tenorsReversed:
      MaskGenerator.tenorsReversed()
    }
  }
  
  package enum MaskGenerator {
    static func fiveSix() -> [HalfPullMusicMask<Stage>] {
      guard Stage.n > 6 else { return [] }
      let front = "xxxx"
      let back = (7...Stage.n)
        .compactMap { Bell(rawValue: $0)?.description }
        .joined()
      return [
        front + "56" + back,
        front + "65" + back
      ].map { HalfPullMusicMask($0) }
    }
    
    static func run(length: Int) -> [HalfPullMusicMask<Stage>] {
      guard length < Stage.n,
            length >= 4
      else { return [] }
      let empty = (1...(Stage.n - length))
        .map { _ in "x" }
        .joined()
      let runSegments = (1...Stage.n - length+1)
        .map {
          ($0...($0+length-1))
            .compactMap { Bell(rawValue: $0)?.description }
            .joined()
        }
      var masks: [HalfPullMusicMask<Stage>] = []
      runSegments.forEach { seg in
        masks.append(HalfPullMusicMask(seg + empty))
        masks.append(HalfPullMusicMask(seg.reversed() + empty))
        masks.append(HalfPullMusicMask(empty + seg))
        masks.append(HalfPullMusicMask(empty + seg.reversed()))
      }
      return masks
    }
    
    static func cru() -> [HalfPullMusicMask<Stage>] {
      guard Stage.self == Major.self else { return [] }
      return [
        HalfPullMusicMask("xxxx5678"),
        HalfPullMusicMask("xxxx6578"),
        HalfPullMusicMask("xxxx4578"),
        HalfPullMusicMask("xxxx5478"),
        HalfPullMusicMask("xxxx4678"),
        HalfPullMusicMask("xxxx6478"),
        HalfPullMusicMask("5678xxxx"),
        HalfPullMusicMask("6578xxxx"),
        HalfPullMusicMask("4578xxxx"),
        HalfPullMusicMask("5478xxxx"),
        HalfPullMusicMask("4678xxxx"),
        HalfPullMusicMask("6478xxxx")
      ]
    }
    
    static func namedRows() -> [HalfPullMusicMask<Stage>] {
      NamedRow<Stage>.allCases
        .compactMap { Mask<Stage>($0.row) }
        .map { HalfPullMusicMask($0) }
    }
    
    static func wraps(of row: Row<Stage>?) -> [WholePullMusicMask<Stage>] {
      guard let row else { return [] }
      return (1...Stage.n-1).map { i in
        let prefix = Array(repeating: "x", count: i).joined()
        let suffix = Array(repeating: "x", count: Stage.n - i).joined()
        let rowA = row.prefix(Stage.n - i).map({ $0.description }).joined()
        let rowB = row.suffix(i).map({ $0.description }).joined()
        return WholePullMusicMask<Stage>(hand: Mask(prefix+rowA), back: Mask(rowB+suffix))
      }
    }
    
    static func wraps() -> [WholePullMusicMask<Stage>] {
      [NamedRow<Stage>.rounds,
       NamedRow<Stage>.backrounds,
       NamedRow<Stage>.queens,
       NamedRow<Stage>.tittums]
        .reduce(into: [WholePullMusicMask<Stage>]()) { into, new in
          wraps(of: new.row).forEach { into.append($0) }
        }
    }
    
    static func tenorsReversed() -> [WholePullMusicMask<Stage>] {
      [
        WholePullMusicMask(
          back: Mask(
            (Array(repeating: "x", count: Stage.n-2)).joined() +
            Stage.tenor.description + Stage.nearTenor.description
          )
        )
      ]
    }
    
    // Hack: Lets us use the string-literal representations of the masks
    // in the inner function.
    static func namedRowCombos() -> [HalfPullMusicMask<Stage>] {
      return namedRowCombosInner()
    }
    
    private static func namedRowCombosInner() -> [HalfPullMusicMask<Stage>] {
      return switch Stage.n {
      case 7:
        ["xxxx246", "xxxx346", "xxxx347", "xxxx374", "xxxx765", "x5x6x7x"]
      case 8:
        ["xxxx1357", "xxxx2468", "xxxx3468", "xxxx3478", "xxxx7658", "x5x6x7x8"]
      case 9:
        ["xxxxx468", "xxxxx987", "xxxxx8495", "xxx97568", "xxx7x8x9x"]
      case 10:
        ["xxxxx24680", "xxxxx13579", "xxxx975680", "x6x7x8x9x0"]
      case 11:
        ["xxxxxxx4680", "xxxxxx24680", "xxxxxxE9780", "xxxxxx9078E", "xxxxx9x0xEx"]
      case 12:
        ["xxxxxx24680T", "xxxxxx9078ET", "xxxxxxE9780T", "xxxxx9x0xExT"]
      case 14:
        ["xxxxxxxx4680TB", "xxxxxxxxAE90TB", "xxxxxxxExTxAxB"]
      case 16:
        ["xxxxxxxxxx4680TB", "xxxxxxxxxxAE90TB", "xxxxxxxxAxBxCxD"]
      default:
        []
      }
    }
  }
}

