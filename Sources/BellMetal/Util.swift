import Foundation

extension Array {
  func interleave(with other: Self) -> Self {
    let overlappedLength = Swift.min(self.count, other.count)
    let excess = self.count > overlappedLength ? self.dropFirst(overlappedLength) : other.dropFirst(overlappedLength)
    return zip(self.prefix(overlappedLength), other.prefix(overlappedLength))
      .flatMap { [$0, $1] } + excess
  }
  
  func partition(on predicate: (Element) -> Bool) -> ([Element], [Element]) {
    return (self.filter(predicate), self.filter { !predicate($0) })
  }
  
  func partitionMap(
    on predicate: (Element) -> Bool,
    applying function: (Self, Self) -> Self
  ) -> Self {
    let (left, right) = self.partition(on: predicate)
    return function(left, right)
  }
}

extension Array where Element: Hashable {
  func toSet() -> Set<Element> {
    Set(self)
  }
}

extension Array where Element == Int {
  func sum() -> Int {
    self.reduce(into: 0) { $0 += $1 }
  }
}
