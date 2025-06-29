import Foundation
import Testing
@testable import BellMetal

@Suite("Unit tests for various utility functions")
struct UtilTests {
  @Test func reducePalindrome() {
    #expect([1].reduceOddPalindrome() == [1])
    #expect([1,2,3,4].reduceOddPalindrome() == nil)
    #expect([1,2,3].reduceOddPalindrome() == nil)
    #expect([1,2,1].reduceOddPalindrome() == [1,2])
    #expect([1,2,3,2,1].reduceOddPalindrome() == [1,2,3])
  }
}

