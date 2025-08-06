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
}
