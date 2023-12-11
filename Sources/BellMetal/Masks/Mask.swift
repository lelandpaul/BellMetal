import Foundation

public struct Mask<Stage: StageProtocol> {
  let string: String
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
    self.string = mask
    self.bellToPosition = b2P
    self.positionToBell = p2B
  }
  
  init?(_ row: Row<Stage>?) {
    guard let row else { return nil }
    var b2P = [Bell : Int]()
    var p2B = [Int : Bell]()
    for (i, bell) in row.enumerated() {
      b2P[bell] = i + 1
      p2B[i+1] = bell
    }
    self.string = row.description
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

extension Mask: CustomDebugStringConvertible {
  public var debugDescription: String {
    "Mask\(Stage.n)(\(self.string))"
  }
}

extension Mask: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(value)
  }
}

extension Mask: Hashable, Equatable { }

public typealias Mask3 = Mask<Singles>
public typealias Mask4 = Mask<Minimus>
public typealias Mask5 = Mask<Doubles>
public typealias Mask6 = Mask<Minor>
public typealias Mask7 = Mask<Triples>
public typealias Mask8 = Mask<Major>
public typealias Mask9 = Mask<Caters>
public typealias Mask0 = Mask<Royal>
public typealias MaskE = Mask<Cinques>
public typealias MaskT = Mask<Maximus>
public typealias MaskA = Mask<Thirteen>
public typealias MaskB = Mask<Fourteen>
public typealias MaskC = Mask<Fifteen>
public typealias MaskD = Mask<Sixteen>

extension Mask {
  static func empty() -> Self {
    .init(Array(repeating: "x", count: Stage.n).joined())
  }
  
  var isEmpty: Bool {
    self.bellToPosition.isEmpty
  }
}
