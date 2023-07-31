import Foundation

extension Row {
  public var isLeadHead: Bool {
    self.position(of: .b1) == 1
  }
  
  public var isTenorsTogether: Bool? {
    guard Stage.n >= 8 else { return nil }
    guard self.isLeadHead else { return nil }
    let notTenor = Bell(rawValue: Stage.tenor.rawValue - 1)!
    let positionOfTenor = self.position(of: Stage.tenor)
    let positionOfNotTenor = self.position(of: notTenor)
    return switch (positionOfNotTenor, positionOfTenor) {
    case (2,3): true
    case (Stage.n-1, Stage.n): true
    case (let x, let y) where !x.isMultiple(of: 2) && x + 2 == y: true
    case (let x, let y) where x.isMultiple(of: 2) && x - 2 == y: true
    default: false
    }
  }
}

extension Array {
  public func replacing(indices: [Int], with elements: [Element]) -> Self {
    var newArray = self
    for (i, e) in zip(indices, elements) {
      newArray[i] = e
    }
    return newArray
  }
}

@available(macOS 10.15.0, *)
extension StageProtocol {
  static public var leadheads: RowGenerator<Self> {
    let positions = ["1"] + Array(repeating: "x", count: Self.n)
    let mask = Mask<Self>(positions.joined())
    return RowGenerator(matching: mask)
  }
  
  static internal var tenorsTogetherLeadheadMasks: [Mask<Self>] {
    guard Self.n >= 8 && Self.n.isMultiple(of: 2) else {
      fatalError("tenorsTogetherLeadheads not currently supported on stage \(Self.description)")
    }
    let base = ["1"] + Array(repeating: "x", count: Self.n-1)
    var masks = [Mask<Self>]()
    for tenorPos in 2...Self.n {
      let positions: [Int] = switch tenorPos {
      case Self.n: [Self.n-2, Self.n-1]
      case 3: [1, 2]
      case let x where x.isMultiple(of: 2): [x+1,x-1]
      default: [tenorPos-3,tenorPos-1]
      }
      let substitutedPostions = base
        .replacing(indices: positions,
                   with: [Self.nearTenor.description,
                          Self.tenor.description])
        .joined()
      masks.append(Mask<Self>(substitutedPostions))
    }
    return masks
  }
  
  static internal var tenorsTogetherLeadheads: some Sequence {
    let generators = tenorsTogetherLeadheadMasks.map { RowGenerator(matching: $0)}
    return ChainedGenerators(generators: generators)
  }
}
