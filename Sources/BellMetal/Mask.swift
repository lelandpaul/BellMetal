import Foundation

struct Mask<Stage: StageProtocol> {
  let positions: [Bell : Int]
  
  init(_ mask: String) {
    guard mask.count == Stage.n else {
      fatalError("Invalid mask \(mask) for stage \(Stage.description)")
    }
    var results = [Bell : Int]()
    for (i, char) in mask.enumerated() {
      guard char != "x" else { continue }
      let bell: Bell
      do {
        bell = try Bell.from(char)
      } catch {
        fatalError("Invalid bell \(char) in mask")
      }
      results[bell] = i + 1
    }
    self.positions = results
  }
  
  public func matches(_ row: Row<Stage>) -> Bool {
    for (bell, pos) in positions {
      guard row.position(of: bell) == pos else { return false }
    }
    return true
  }
}
