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
  
  @Test func parseAllPlaces() throws {
    let pb4 = "x4x4,2"
    let pb4_places = [[],[1,4],[],[1,4],[],[1,4],[],[1,2]]
    #expect(try PNP.parseAllPlaces(pb4).1 == pb4_places)
    
    let g5 = "3,1.5.1.5.1"
    let g5_places = [[3],[1],[5],[1],[5],[1],[5],[1],[5],[1]]
    #expect(try PNP.parseAllPlaces(g5).1 == g5_places)
  }
  
  @Test func changeToRawRow() {
    let expectedX: Row = "21436587"
    let expected14: Row = "1324"
    let expected3: Row = "21354"
    #expect(PNP.changeToRawRow([], at: .major) == expectedX.row)
    #expect(PNP.changeToRawRow([1,4], at: .minimus) == expected14.row)
    #expect(PNP.changeToRawRow([3], at: .doubles) == expected3.row)
  }
  
  @Test func parseAllChanges() throws {
    let pb4 = "x4x4,2"
    let pb4_changes: [Row] = ["2143", "1324", "2143", "1324", "2143", "1324", "2143", "1243"]
    #expect(try PNP.parseAllChanges(pb4).1 == pb4_changes.map(\.row))
    
    let g5 = "3,1.5.1.5.1"
    let g5_changes: [Row] = ["21354", "13254", "21435", "13254", "21435", "13254", "21435", "13254", "21435", "13254"]
    #expect(try PNP.parseAllChanges(g5).1 == g5_changes.map(\.row))
  }
  
  @Test func parsePN() throws {
    let pb4 = "x4x4,2"
    let pb4_changes: [Row] = ["2143", "1324", "2143", "1324", "2143", "1324", "2143", "1243"]
    let expectedPb4 = PlaceNotation(stage: .minimus, changes: pb4_changes.map(\.row))
    #expect(try PlaceNotation(pb4) == expectedPb4)

    let g5 = "3,1.5.1.5.1"
    let g5_changes: [Row] = ["21354", "13254", "21435", "13254", "21435", "13254", "21435", "13254", "21435", "13254"]
    let expectedG5 = PlaceNotation(stage: .doubles, changes: g5_changes.map(\.row))
    #expect(try PlaceNotation(g5) == expectedG5)
  }
  
  @Test func parsePNWithExplicitStage() throws {
    let lb6: PlaceNotation = "6:x4x4,2"
    print(lb6)
    #expect(try lb6 == PlaceNotation("x4x4,2", at: .minor))
    
    let invalid: PlaceNotation? = try? PlaceNotation("4:x4x4,2", at: .minor)
    #expect(invalid == nil)
  }
}

