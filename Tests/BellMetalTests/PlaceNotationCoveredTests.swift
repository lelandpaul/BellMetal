import Foundation
import Testing
@testable import BellMetal

@Suite("PlaceNotation.covered(at:): extending a place notation itself, not just its rows")
struct PlaceNotationCoveredTests {
    /// Plain Bob Minor, with a bob at the lead end -- exercises both a
    /// plain lead and a call, covered up to Major.
    private let plainBobMinor = try! PlaceNotation(string: "x16x16x16,12", at: .minor)
    private let bob = try! PlaceNotation(string: "14", at: .minor)

    @Test("Pricking a covered notation gives exactly the same result, row for row, as pricking the original and then extending each row")
    func coveredPrickingMatchesExtendedPricking() throws {
        let course = try plainBobMinor.prick(at: Stage.minor.rounds, keeping: .keepBoth, repeat: .times(1))
        let coveredCourse = try plainBobMinor.covered(at: Stage.major).prick(at: Stage.major.rounds, keeping: .keepBoth, repeat: .times(1))

        #expect(coveredCourse.count == course.count)
        for (row, coveredRow) in zip(course, coveredCourse) {
            #expect(coveredRow == (try row.extend(to: Stage.major)))
        }
    }

    @Test("The cover bells never move, across an entire plain course")
    func coverBellsNeverMove() throws {
        let coveredCourse = try plainBobMinor.covered(at: Stage.major).prick(at: Stage.major.rounds, keeping: .keepBoth, repeat: .untilRound)
        for row in coveredCourse {
            #expect(row[.b7] == 7)
            #expect(row[.b8] == 8)
        }
    }

    @Test("Covering preserves a call's own effect on the working bells, cover bells still untouched")
    func coveredCallBehavesLikeTheOriginalOnTheWorkingBells() throws {
        let coveredPlain = try plainBobMinor.covered(at: Stage.major)
        let coveredBob = try bob.covered(at: Stage.major)

        let plainRow = try plainBobMinor.prick(at: Stage.minor.rounds, keeping: .keepFinal, repeat: .times(1)).last
        let bobRow = try bob.prick(at: plainRow, keeping: .keepFinal, repeat: .times(1)).last

        let coveredPlainRow = try coveredPlain.prick(at: Stage.major.rounds, keeping: .keepFinal, repeat: .times(1)).last
        let coveredBobRow = try coveredBob.prick(at: coveredPlainRow, keeping: .keepFinal, repeat: .times(1)).last

        #expect(coveredBobRow == (try bobRow.extend(to: Stage.major)))
        #expect(coveredBobRow[.b7] == 7)
        #expect(coveredBobRow[.b8] == 8)
    }

    @Test("Throws BellMetalError.invalidStage when the target stage isn't strictly higher", arguments: [
        Stage.minor, Stage.minimus,
    ])
    func rejectsNonHigherStage(target: Stage) {
        #expect(throws: BellMetalError.invalidStage) {
            try plainBobMinor.covered(at: target)
        }
    }

    @Test(
        "Covering round-trips correctly from every stage up to Stage.sixteen, including the maximum",
        arguments: 1...15
    )
    func coveringWorksFromEveryStageUpToSixteen(bellCount: Int) throws {
        // Regression coverage for the same bit-packing territory that
        // trapped at Stage.sixteen before (RawRow.composePermutation,
        // fixed in Row/Block.extend's own RawRow.extend) -- covered(at:)
        // leans on that same RawRow.extend, so it's worth the same
        // exhaustive check, not just a single spot-checked stage pair.
        let fromStage = Stage(bellCount)
        let notation = fromStage.even
            ? try PlaceNotation(string: "x", at: fromStage)
            : try PlaceNotation(string: "1", at: fromStage)
        let covered = try notation.covered(at: .sixteen)

        let course = try notation.prick(repeat: .untilRound)
        let coveredCourse = try covered.prick(repeat: .untilRound)
        #expect(coveredCourse.count == course.count)
        for (row, coveredRow) in zip(course, coveredCourse) {
            #expect(coveredRow == (try row.extend(to: .sixteen)))
        }
    }
}
