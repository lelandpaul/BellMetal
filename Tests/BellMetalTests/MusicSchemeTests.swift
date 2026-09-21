import Foundation
import Testing
@testable import BellMetal

@Suite("MusicScheme unit tests")
struct MusicSchemeTests {
  // Rounds on Major: comboNearMiss scores 1 (every bell is in its home position),
  // and the default-length run scores 1 (the whole row is a single run).
  let rounds: Block = Block(Row("12345678"))

  @Test("A scheme's total score sums each music type's score times its weight")
  func weightedScore() {
    let scheme = MusicScheme([(.comboNearMiss, weight: 3), (.runs, weight: -1)])
    #expect(scheme.score(rounds) == 3 * 1 + (-1) * 1)
  }

  @Test("scoreDetails(_:) reports each music type's individual weight and score")
  func scoreDetails() {
    let scheme = MusicScheme([(.comboNearMiss, weight: 3), (.runs, weight: -1)])
    let details = scheme.scoreDetails(rounds)
    #expect(details.count == 2)
    #expect(details[0].type.description == MusicType.comboNearMiss.description)
    #expect(details[0].weight == 3)
    #expect(details[0].score == 3)
    #expect(details[1].weight == -1)
    #expect(details[1].score == -1)
  }

  @Test("Scoring an array of rows matches scoring the equivalent Block")
  func scoreRowArrayMatchesScoreBlock() {
    let scheme = MusicScheme([(.comboNearMiss, weight: 1)])
    let rows: [Row] = ["12345678"]
    #expect(scheme.score(rows) == scheme.score(Block(rows)))
  }

  @Test("Block's musicScore/musicScoreDetails convenience methods match the equivalent MusicScheme calls")
  func blockConvenienceMethodsMatchSchemeMethods() {
    let scheme = MusicScheme([(.comboNearMiss, weight: 2), (.namedRow, weight: 1)])
    #expect(rounds.musicScore(scheme) == scheme.score(rounds))
    #expect(rounds.musicScoreDetails(scheme).count == scheme.scoreDetails(rounds).count)
  }

  @Test("Regression: MusicScheme.shared scores without trapping, including its NamedRow-based types")
  func sharedSchemeDoesNotCrash() {
    // Regression test: MusicScheme.shared includes .wrap, which touches every
    // NamedRow used by scoreWraps (rounds, backrounds, queens, tittums) -- all
    // of which must be constructible without trapping.
    _ = rounds.musicScore()
    _ = rounds.musicScoreDetails()
  }
}
