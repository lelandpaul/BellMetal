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
    // .wrap uses rounds, backrounds, queens and tittums, all of which must
    // be constructible without trapping.
    _ = rounds.musicScore()
    _ = rounds.musicScoreDetails()
  }

  @Test("Regression: MusicScheme.shared scores a block at every stage without trapping",
        arguments: (1...Stage.maxCount).map { Stage($0) })
  func sharedSchemeEveryStage(stage: Stage) {
    let block = Block(stage.rounds)
    let total = MusicScheme.shared.score(block)
    #expect(total == MusicScheme.shared.scoreDetails(block).reduce(0) { $0 + $1.score })
  }

  @Test("backstrokeStart reaches every music type, so score agrees with the sum of scoreDetails")
  func backstrokeStartPassedThrough() {
    // Tenors reversed in the second row: a backstroke from a handstroke start,
    // a handstroke from a backstroke start.
    let block: Block = ["12345678", "12345687"]
    let scheme = MusicScheme([(.tenorsReversed, weight: 1)])
    #expect(scheme.score(block) == 1)
    #expect(scheme.score(block, backstrokeStart: true) == 0)
    #expect(block.musicScore(scheme, backstrokeStart: true) == 0)
    #expect(block.musicScoreDetails(scheme, backstrokeStart: true).map(\.score) == [0])
    for start in [false, true] {
      let total = MusicScheme.shared.score(block, backstrokeStart: start)
      let details = MusicScheme.shared.scoreDetails(block, backstrokeStart: start)
      #expect(total == details.reduce(0) { $0 + $1.score })
    }
  }

  @Test("Scoring no rows gives 0, and a 0 for every type in the details")
  func scoreNoRows() {
    #expect(MusicScheme.shared.score([Row]()) == 0)
    let details = MusicScheme.shared.scoreDetails([Row]())
    #expect(details.count == MusicScheme.shared.scoreDetails(rounds).count)
    #expect(details.allSatisfy { $0.score == 0 })
  }
}
