import Foundation

struct Mask<Stage: StageProtocol> {
  let bellToPosition: [Bell : Int]
  let positionToBell: [Int : Bell]
  
  public var fixedBells: [Bell] { Array(bellToPosition.keys) }
  public var unfixedBells: [Bell] {
    Stage.bells.filter { !fixedBells.contains($0) }
  }
  
  init(_ mask: String) {
    guard mask.count == Stage.n else {
      fatalError("Invalid mask \(mask) for stage \(Stage.description)")
    }
    var b2P = [Bell : Int]()
    var p2B = [Int : Bell]()
    for (i, char) in mask.enumerated() {
      guard char != "x" else { continue }
      let bell: Bell
      do {
        bell = try Bell.from(char)
      } catch {
        fatalError("Invalid bell \(char) in mask")
      }
      b2P[bell] = i + 1
      p2B[i+1] = bell
    }
    self.bellToPosition = b2P
    self.positionToBell = p2B
  }
  
  public func matches(_ row: Row<Stage>) -> Bool {
    for (bell, pos) in bellToPosition {
      guard row.position(of: bell) == pos else { return false }
    }
    return true
  }
  
  public func fill(with bells: [Bell]) throws -> Row<Stage> {
    guard Stage.n - bells.count == fixedBells.count else {
      throw BellMetalError.invalidFillOnMask
    }
    var result = [Bell]()
    var nextIndex = 0
    for i in 1...Stage.n {
      if let fixed = positionToBell[i] {
        result.append(fixed)
      } else {
        result.append(bells[nextIndex])
        nextIndex += 1
      }
    }
    return try Row<Stage>(result)
  }
}

extension Mask: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(value)
  }
}

extension Mask: Hashable, Equatable { }

typealias Mask3 = Mask<Singles>
typealias Mask4 = Mask<Minimus>
typealias Mask5 = Mask<Doubles>
typealias Mask6 = Mask<Minor>
typealias Mask7 = Mask<Triples>
typealias Mask8 = Mask<Major>
typealias Mask9 = Mask<Caters>
typealias Mask0 = Mask<Royal>
typealias MaskE = Mask<Cinques>
typealias MaskT = Mask<Maximus>
typealias MaskA = Mask<Thirteen>
typealias MaskB = Mask<Fourteen>
typealias MaskC = Mask<Fifteen>
typealias MaskD = Mask<Sixteen>
