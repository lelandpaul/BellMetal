import Foundation

extension Array where Element: Equatable {
  /// If the sequence is a palindrome about its
  /// middle element, return only the first half
  /// (including the apex).
  internal func reduceOddPalindrome() -> Self? {
    // Always nil if even length — no apex element
    guard !self.count.isMultiple(of: 2) else { return nil }
    let midpoint = self.count / 2
    if Array(self) == self.reversed() {
      return Array(self[...midpoint])
    }
    return nil
  }
}

extension Array {
  /// Interleave two arrays, alternating one element of self and one element of other
  /// - Parameter other: The other array to interleave in
  /// - Returns: An interleaved array
  internal func interleave(with other: Self) -> Self {
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

extension Set {
  internal mutating func insert(
    contentsOf sequence: any Sequence<Element>
  ) {
    sequence.forEach { insert($0) }
  }
}

extension IteratorProtocol {
  internal func collect() -> [Element] {
    var iteratorCopy = self
    var result: [Element] = []
    while let element = iteratorCopy.next() {
      result.append(element)
    }
    return result
  }
}
