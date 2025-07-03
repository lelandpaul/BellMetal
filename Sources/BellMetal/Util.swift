import Foundation

extension Array where Element: Equatable {
  /// If the sequence is a palindrome about its
  /// middle element, return only the first half
  /// (including the apex).
  func reduceOddPalindrome() -> Self? {
    // Always nil if even length — no apex element
    guard !self.count.isMultiple(of: 2) else { return nil }
    let midpoint = self.count / 2
    if Array(self) == self.reversed() {
      return Array(self[...midpoint])
    }
    return nil
  }
}

extension Set {
  mutating func insert(
    contentsOf sequence: any Sequence<Element>
  ) {
    sequence.forEach { insert($0) }
  }
}

extension IteratorProtocol {
  func collect() -> [Element] {
    var iteratorCopy = self
    var result: [Element] = []
    while let element = iteratorCopy.next() {
      result.append(element)
    }
    return result
  }
}
