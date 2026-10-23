import Foundation
import Algorithms

extension Mask {
  
  /// Every row at the mask's stage that it matches, generated lazily. Usable
  /// directly in a `for` loop.
  /// - Returns: A sequence of rows
  public func allMatchingRows() -> RowTemplateIterator {
    RowTemplateIterator(mask: self)
  }

  public struct RowTemplateIterator {
    let stage: Stage
    let mask: Mask
    let unfixedBells: [Bell]

    var permutations: PermutationsSequence<[Bell]>.Iterator

    internal init(mask: Mask) {
      self.stage = mask.stage
      self.mask = mask
      self.unfixedBells = stage.allBells.filter { !mask.fixedPos.values.contains($0) }
      self.permutations = unfixedBells.permutations().makeIterator()
    }
  }
}

extension Mask.RowTemplateIterator: IteratorProtocol, Sequence {
  public typealias Element = Row

  mutating public func next() -> Row? {
    guard let nextPerm = permutations.next() else { return nil }
    // There are exactly as many unfixed bells as open positions.
    var unfixed = nextPerm.makeIterator()
    return Row((1...stage.count).compactMap { pos in
      mask.fixedPos[pos] ?? unfixed.next()
    })
  }
}
