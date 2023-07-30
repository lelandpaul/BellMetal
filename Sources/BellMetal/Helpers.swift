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
