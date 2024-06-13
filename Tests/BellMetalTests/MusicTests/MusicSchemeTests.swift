import Testing
@testable import BellMetal

@Suite("Music schemes")
struct MusicSchemeTests {
  
  @Test
  func halfPullMusic() async throws {
    let testRow: Row8 = "23458617"
    let mask: HalfPullMusicMask<Major> = "2345xxxx"
    #expect(mask.matches(testRow) == 1)
    
    let customScheme = MusicScheme<Major>(.customHalf(weight: 1, name: "test", masks: [mask]))
    #expect(customScheme.score(testRow) == 1)
    
    let customScheme2 = MusicScheme<Major>(.customHalf(weight: 2, name: "test", masks: [mask]))
    #expect(customScheme2.score(testRow) == 2)
    
    let noRunRow: Row8 = "15263748"
    let otherRunRow: Row8 = "23457681"
    #expect(customScheme.score(RowBlock8(rows: [testRow, noRunRow])) == 1)
    #expect(customScheme.score(RowBlock8(rows: [noRunRow, testRow])) == 1)
    #expect(customScheme.score(RowBlock8(rows: [testRow, otherRunRow])) == 2)
    #expect(customScheme.score(RowBlock8(rows: [otherRunRow, testRow])) == 2)
  }
  
  @Test
  func runs() throws {
    let testRow1: Row8 = "23456817"
    let testRow2: Row8 = "34568172"
    
    #expect(testRow1.musicScore == 2) // 4- and 5-bell runs
    #expect(RowBlock8(rows: [testRow1, testRow2]).musicScore() == 3) // additional 4-bell run
  }
  
  @Test
  func wraps() throws {
    let block = RowBlock8(rows: ["86751234", "56783142"])
    let customScheme = MusicScheme<Major>(.wrap())
    #expect(customScheme.score(block) == 1)
    #expect(customScheme.score(block, backstrokeStart: true) == 0)
  }
  
  @Test
  func tenorsReversed() throws {
    let rowWithTenorsOver: Row8 = "32165487"
    let rowWithRun: Row8 = "23458617"
    #expect(RowBlock8(
      rows: [rowWithRun, rowWithTenorsOver]
    ).musicScore() == 0)
    #expect(RowBlock8(
      rows: [rowWithTenorsOver, rowWithRun]
    ).musicScore() == 1)
    #expect(RowBlock8(
      rows: [rowWithRun, rowWithTenorsOver]
    ).musicScore(backstrokeStart: true) == 1)
  }
}
