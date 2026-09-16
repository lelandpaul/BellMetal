import Foundation
import Testing
@testable import BellMetal

@Suite
struct MusicTypeTests {
  @Test func comboNearMiss() {
    let single: Row = "1324"
    let double: Row = "2143"
    let not: Row = "3124"
    #expect(MusicType.scoreComboNearMiss(Block(single)) == 1)
    #expect(MusicType.scoreComboNearMiss(Block(double)) == 1)
    #expect(MusicType.scoreComboNearMiss(Block(not)) == 0)
  }

  @Test func fiveSix() {
    #expect(MusicType.scoreFiveSix(Block("12345678")) == 1) // xxxx5678
    #expect(MusicType.scoreFiveSix(Block("12346578")) == 1) // xxxx6578
    #expect(MusicType.scoreFiveSix(Block("56781234")) == 1) // 5678xxxx
    #expect(MusicType.scoreFiveSix(Block("65781234")) == 1) // 6578xxxx
    #expect(MusicType.scoreFiveSix(Block("12345687")) == 0) // no 56 combo
    // Below Minor's threshold (stage must be > minor), always scores 0.
    #expect(MusicType.scoreFiveSix(Block("123456")) == 0)
  }

  @Test func cru() {
    #expect(MusicType.scoreCru(Block("12345678")) == 1) // xxxx5678
    #expect(MusicType.scoreCru(Block("12356478")) == 1) // xxxx6478
    #expect(MusicType.scoreCru(Block("12345768")) == 0) // not a recognized combo
    // Only defined for Major.
    #expect(MusicType.scoreCru(Block("1234567")) == 0)
  }

  @Test func runs() {
    // Front run reversed ("4321") and back run reversed ("8765") both match,
    // but scoring is per-row (matches-any), so a single row still scores 1.
    #expect(MusicType.scoreRuns(Block("43218765"), length: 4) == 1)
    #expect(MusicType.scoreRuns(Block("23456781"), length: 4) == 1) // front run "2345"
    #expect(MusicType.scoreRuns(Block("12345678"), length: 4) == 1) // matches at least one mask
    #expect(MusicType.scoreRuns(Block("21436587"), length: 4) == 0) // no 4-run anywhere
    // Score accumulates across rows, one point per matching row.
    let twoRuns: Block = ["23456781", "21436587"]
    #expect(MusicType.scoreRuns(twoRuns, length: 4) == 1)

    // .runs defaults to length 4.
    #expect(MusicType.runs.score(Block("12345678")) == 1)

    // Custom lengths via .run(length:).
    #expect(MusicType.scoreRuns(Block("12345678"), length: 5) == 1) // front run "12345"

    // Invalid lengths always score 0.
    #expect(MusicType.scoreRuns(Block("1234"), length: 4) == 0) // length must be < stage.count
    #expect(MusicType.scoreRuns(Block("12345678"), length: 3) == 0) // length must be >= 4
  }

  @Test func wrap() {
    // Row A ends "...1234" and Row B starts "5678..." -> a rounds-wrap at the seam.
    let wrapping: Block = ["56781234", "56784321"]
    #expect(MusicType.scoreWraps(wrapping) == 1)

    // A single-row block has no adjacent pairs to check.
    #expect(MusicType.scoreWraps(Block("12345678")) == 0)
  }

  @Test func namedRow() {
    let block: Block = ["12345678", "13572468", "21435687"]
    #expect(MusicType.scoreNamedRows(block) == 2) // rounds + queens match; the third row matches nothing
  }

  @Test func namedRowCombo() {
    #expect(MusicType.scoreNamedRowCombos(Block("1234765")) == 1) // xxxx765 on Triples
    #expect(MusicType.scoreNamedRowCombos(Block("1234567")) == 0) // rounds: no match
    // No combo masks are defined for Doubles or Minor.
    #expect(MusicType.scoreNamedRowCombos(Block("12345")) == 0)
    #expect(MusicType.scoreNamedRowCombos(Block("123456")) == 0)
  }

  @Test func tenorsReversed() {
    // Positions 7,8 = 8,7 ("tenors reversed") on both rows; only the backstroke (odd index) counts by default.
    let block: Block = ["12345687", "21345687"]
    #expect(MusicType.scoreTenorsReversed(block) == 1)

    // With only the handstroke (even index) row matching, default excludes it...
    let handOnly: Block = ["12345687", "12345678"]
    #expect(MusicType.scoreTenorsReversed(handOnly) == 0)
    // ...but flipping backstrokeStart brings it into the counted group.
    #expect(MusicType.scoreTenorsReversed(handOnly, backstrokeStart: true) == 1)
  }

  @Test func backBellCombo() {
    let block: Block = ["12345678", "56781234", "12345687"]
    #expect(MusicType.scoreBackBellCombo(block) == 2) // first two rows match; the third doesn't
    // Only defined for Major.
    #expect(MusicType.scoreBackBellCombo(Block("1234567")) == 0)
  }
}
