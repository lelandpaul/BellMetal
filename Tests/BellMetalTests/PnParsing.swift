import Foundation
import Testing
@testable import BellMetal

@Suite("Place notation parsing unit tests")
struct PnParsingTests {
  typealias PNP = PlaceNotationParser
  
  @Test func splitRightPlace() {
    let pn = "x12x14"
    let expected = ["x", "12", "x", "14"]
    #expect(PNP.splitToChanges(pn) == expected)
  }
  
  @Test func splitWrongPlace() {
    let pn = "-12.34-"
    let expected = ["-", "12", "34", "-"]
    #expect(PNP.splitToChanges(pn) == expected)
  }
  
  @Test func palindromeHelper() {
    #expect([1,2,3].makePalindrome() == [1,2,3,2,1])
    #expect([1].makePalindrome() == [1])
  }
  
  @Test func palindromeExpansion() {
    let pb = "x14x14,12"
    let expected_pb = ["x", "14", "x", "14", "x", "14", "x", "12"]
    #expect(PNP.splitAndExpandPalindrome(pb) == expected_pb)
    
    let grandsire5 = "3,1.5.1.5.1"
    let expected_g5 = ["3", "1", "5", "1", "5", "1", "5", "1", "5", "1"]
    #expect(PNP.splitAndExpandPalindrome(grandsire5) == expected_g5)
    
    let test = "x12,56.18"
    let expected_test = ["x","12","x","56","18","56"]
    #expect(PNP.splitAndExpandPalindrome(test) == expected_test)
  }
  
  @Test func inferStage() {
    let doubles = [[5],[1],[5],[1],[5]]
    #expect(PNP.inferStage(doubles) == .doubles)
    let minor = [[1,2],[3,4],[5,6],[1,2]]
    #expect(PNP.inferStage(minor) == .minor)
    let withCrossChange = [[],[5]]
    #expect(PNP.inferStage(withCrossChange) == .minor)
  }
  
  @Test func inferExternalPlaces() {
    #expect(PNP.inferExternalPlaces([4], at: .minor) == [1,4])
    #expect(PNP.inferExternalPlaces([3], at: .minor) == [3,6])
    #expect(PNP.inferExternalPlaces([2], at: .doubles) == [1,2,5])
    #expect(PNP.inferExternalPlaces([], at: .minor) == [])
    #expect(PNP.inferExternalPlaces([], at: .doubles) == [5])
  }
  
  @Test func parseAllChanges() {
    let pb4 = "x4x4,2"
    let pb4_changes = [[],[1,4],[],[1,4],[],[1,4],[],[1,2]]
    #expect(PNP.parseAllChanges(pb4) == pb4_changes)
    
    let g5 = "3,1.5.1.5.1"
    let g5_changes = [[3],[1],[5],[1],[5],[1],[5],[1],[5],[1]]
    #expect(PNP.parseAllChanges(g5) == g5_changes)
  }
}

