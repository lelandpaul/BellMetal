import Foundation
import Combinatorics

extension StageProtocol {
  public static var rounds: Row<Self> { Row<Self>.rounds() }
  
  public static var rows: RowGenerator<Self> { RowGenerator() }
}

public struct RowGenerator<Stage: StageProtocol>: Sequence, IteratorProtocol {
  public typealias Element = Row<Stage>
  
  let permutations: Permutation<Bell>
  var mask: Mask<Stage>? = nil
  var current_pos = 0
  
  init() {
    self.permutations = Permutation(of: Stage.bells)
  }
  
  init(matching mask: Mask<Stage>) {
    self.mask = mask
    self.permutations = Permutation(of: mask.unfixedBells)
  }
  
  public mutating func next() -> Row<Stage>? {
    defer { current_pos += 1 }
    if current_pos >= permutations.count {
      return nil
    }
    if let mask {
      return try! mask.fill(with: permutations[current_pos])
    } else {
      return try! Row<Stage>(permutations[current_pos])
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
