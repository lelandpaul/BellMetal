import Foundation
import Algorithms

extension StageProtocol {
  public static var rounds: Row<Self> { Row<Self>.rounds() }
  
  public static var rows: RowGenerator<Self> { RowGenerator() }
}

public struct RowGenerator<Stage: StageProtocol>: Sequence, IteratorProtocol {
  public typealias Element = Row<Stage>
  
  var permutations: PermutationsSequence<[Bell]>.Iterator
  var mask: Mask<Stage>? = nil
  var current_pos = 0
  
  public init() {
    self.permutations = Stage.bells.permutations().makeIterator()
  }
  
  public init(matching mask: Mask<Stage>) {
    self.mask = mask
    self.permutations = mask.unfixedBells.permutations().makeIterator()
  }
  
  public mutating func next() -> Row<Stage>? {
//    defer { current_pos += 1 }
//    if current_pos >= permutations.count {
//      return nil
//    }
    guard let perm = permutations.next() else { return nil }
    if let mask {
      return try! mask.fill(with: perm)
    } else {
      return try! Row<Stage>(perm)
    }
  }
  
  func collect() -> RowBlock<Stage> {
    var results = [Row<Stage>]()
    for row in self {
      results.append(row)
    }
    return RowBlock<Stage>(rows: results)
  }
}

public struct ChainedGenerators<Generator: IteratorProtocol>: Sequence, IteratorProtocol {
  public typealias Element = Generator.Element
  var generators: [Generator]
  var onDeckGenerator: Generator?
  
  public mutating func next() -> Element? {
    guard onDeckGenerator != nil || !generators.isEmpty else { return nil }
    let nextItem = onDeckGenerator?.next()
    if nextItem == nil && !generators.isEmpty {
      onDeckGenerator = generators.removeFirst()
      return onDeckGenerator?.next()
    }
    return nextItem
  }
}
