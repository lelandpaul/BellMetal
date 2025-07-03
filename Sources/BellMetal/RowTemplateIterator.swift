import Foundation
import Algorithms


extension Mask {
  
  /// Return an Iterator over all possible rows at the same stage as the Mask
  /// that match.
  /// - Returns: An Iterator over rows
  public func allMatchingRows() -> RowTemplateIterator {
    RowTemplateIterator(mask: self)
  }
  
  struct RowTemplateIterator {
    let stage: Stage
    let mask: Mask
    let unfixedPos: [Int]
    let unfixedBells: [Bell]
    
    var permutations: PermutationsSequence<[Bell]>.Iterator
    
    internal init(mask: Mask) {
      self.stage = mask.stage
      self.mask = mask
      self.unfixedPos = (1...stage.count).filter { !mask.fixedPos.keys.contains($0) }
      self.unfixedBells = stage.allBells.filter { !mask.fixedPos.values.contains($0) }
      self.permutations = unfixedBells.permutations().makeIterator()
    }
  }
}

extension Mask.RowTemplateIterator: IteratorProtocol {
  typealias Element = Row
  
  mutating func next() -> Row? {
    guard var nextPerm = permutations.next() else { return nil }
    let bellArray = (1...stage.count).map { pos in
      if let fixedBell = mask.fixedPos[pos] {
        return fixedBell
      }
      return nextPerm.removeFirst()
    }
    return Row(bellArray)
  }
}
