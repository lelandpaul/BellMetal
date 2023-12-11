import XCTest
import Nimble
@testable import BellMetal

final class MusicSchemeTests: XCTestCase {
  
  func testHalfPullMusic() throws {
    let testRow: Row8 = "23458617"
    let mask: HalfPullMusicMask<Major> = "2345xxxx"
    expect(mask.matches(testRow))
      .to(equal(1))
    
    let customScheme = MusicScheme<Major>(.customHalf(weight: 1, name: "test", masks: [mask]))
    expect(customScheme.score(testRow))
      .to(equal(1))
    
    let customScheme2 = MusicScheme<Major>(.customHalf(weight: 2, name: "test", masks: [mask]))
    expect(customScheme2.score(testRow))
      .to(equal(2))
    
    let noRunRow: Row8 = "15263748"
    let otherRunRow: Row8 = "23457681"
    expect(customScheme.score(RowBlock8(rows: [testRow, noRunRow])))
      .to(equal(1))
    expect(customScheme.score(RowBlock8(rows: [noRunRow, testRow])))
      .to(equal(1))
    expect(customScheme.score(RowBlock8(rows: [testRow, otherRunRow])))
      .to(equal(2))
    expect(customScheme.score(RowBlock8(rows: [otherRunRow, testRow])))
      .to(equal(2))
  }
  
  func testRuns() throws {
    let testRow1: Row8 = "23456817"
    let testRow2: Row8 = "34568172"
    
    expect(testRow1.musicScore)
      .to(equal(2)) // 4- and 5-bell runs
    expect(RowBlock8(rows: [testRow1, testRow2]).musicScore())
      .to(equal(3)) // additional 4-bell run
  }
  
  func testWraps() throws {
    let block = RowBlock8(rows: ["86751234", "56783142"])
    let customScheme = MusicScheme<Major>(.wrap())
    expect(customScheme.score(block))
      .to(equal(1))
    expect(customScheme.score(block, backstrokeStart: true))
      .to(equal(0))
  }
  
  func testTenorsReversed() throws {
    let rowWithTenorsOver: Row8 = "32165487"
    let rowWithRun: Row8 = "23458617"
    expect(RowBlock8(
      rows: [rowWithRun, rowWithTenorsOver]
    ).musicScore())
      .to(equal(0))
    expect(RowBlock8(
      rows: [rowWithTenorsOver, rowWithRun]
    ).musicScore())
      .to(equal(1))
    expect(RowBlock8(
      rows: [rowWithRun, rowWithTenorsOver]
    ).musicScore(backstrokeStart: true))
      .to(equal(1))
  }
}
