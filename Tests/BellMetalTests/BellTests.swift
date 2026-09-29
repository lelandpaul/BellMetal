import Foundation
import Testing
@testable import BellMetal

@Suite("Bell unit tests")
struct BellTests {
  @Test("number counts from 1")
  func number() {
    #expect(Bell.b1.number == 1)
    #expect(Bell.b0.number == 10)
    #expect(Bell.bT.number == 12)
    #expect(Bell.bD.number == 16)
    #expect(Bell.bF.number == 17)
    #expect(Bell.bN.number == 24)
  }

  @Test("init(number:) round-trips every bell")
  func roundTrip() {
    for bell in Stage.twentyFour.allBells {
      #expect(Bell(number: bell.number) == bell)
      #expect(Bell(number: bell.number, on: .twentyFour) == bell)
    }
  }

  @Test("init(number:) rejects numbers outside 1...24")
  func outOfRange() {
    #expect(Bell(number: 0) == nil)
    #expect(Bell(number: -1) == nil)
    #expect(Bell(number: Int.min) == nil)
    #expect(Bell(number: 17) == .bF)
    #expect(Bell(number: 25) == nil)
    #expect(Bell(number: Int.max) == nil)
  }

  @Test("init(number:on:) accepts exactly the bells on the stage")
  func onStage() {
    #expect(Bell(number: 1, on: .one) == .b1)
    #expect(Bell(number: 2, on: .one) == nil)
    #expect(Bell(number: 8, on: .major) == .b8)
    #expect(Bell(number: 9, on: .major) == nil)
    #expect(Bell(number: 0, on: .major) == nil)
    #expect(Bell(number: -3, on: .major) == nil)
    #expect(Bell(number: 17, on: .sixteen) == nil)
  }

  @Test("init?(rawValue:) accepts exactly 0..<Stage.maxCount")
  func rawValueRange() {
    for number in 1...Stage.maxCount {
      #expect(Bell(rawValue: UInt8(number - 1)) == Bell(number: number))
    }
    #expect(Bell(rawValue: UInt8(Stage.maxCount)) == nil)
    #expect(Bell(rawValue: .max) == nil)
  }

  @Test("Every bell's symbol round-trips through init?(character:)")
  func symbolRoundTrip() {
    for bell in Stage(Stage.maxCount).allBells {
      #expect(bell.description.count == 1)
      #expect(Bell(character: Character(bell.description)) == bell)
    }
    #expect(Stage(Stage.maxCount).allBells.map(\.description).joined() == "1234567890ETABCDFGHJKLMN")
  }

  @Test("init?(character:) rejects non-symbols, including lowercase and non-ASCII")
  func rejectsNonSymbols() {
    for character: Character in ["x", "e", "t", "I", "O", "P", "Z", " ", "\u{7F}", "é", "🔔"] {
      #expect(Bell(character: character) == nil)
    }
  }

  @Test("Bell stays a single byte")
  func layout() {
    #expect(MemoryLayout<Bell>.size == 1)
  }
}
