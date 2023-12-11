import Foundation

public struct MusicScheme<Stage: StageProtocol> {
  typealias MType = MusicType<Stage>
  typealias MMask = MusicMask<Stage>
  let mtypes: [MType: [any MMask]]

  init(_ types: MType...) {
    var mtypes = [MType: [any MMask]]()
    for type in types {
      mtypes[type] = type.masks
    }
    self.mtypes = mtypes
  }
  
  func scoreDetails(_ row: Row<Stage>) -> [MType: Int] {
    mtypes.mapValues { masks in
      masks.map { $0.matches(row) }
        .sum()
    }
  }
  
  func score(_ row: Row<Stage>) -> Int {
    scoreDetails(row)
      .reduce(into: 0) { partialResult, element in
        partialResult += element.key.weight * element.value
      }
  }
  
  func scoreDetails(
    _ rows: RowBlock<Stage>,
    backstrokeStart: Bool = false
  ) -> [MType: Int] {
    mtypes.mapValues { masks in
      rows.wholePulls(backstrokeStart: backstrokeStart)
        .flatMap { wholePull in
          masks
            .map { mask in
              mask.matches(wholePull)
            }
        }
        .sum()
    }
  }
  
  func score(_ rows: RowBlock<Stage>, backstrokeStart: Bool = false) -> Int {
    scoreDetails(rows, backstrokeStart: backstrokeStart)
      .reduce(into: 0) { partialResult, element in
        partialResult += element.key.weight * element.value
      }
  }
}

extension MusicScheme {
  static var standard: Self {
    Self(
      .fiveSix(),
      .cru(),
      .runs(),
      .wrap(),
      .namedRow(),
      .namedRowCombo(),
      .tenorsReversed()
    )
  }
}
