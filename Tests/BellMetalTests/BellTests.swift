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
  }

  @Test("init(number:) round-trips every bell")
  func roundTrip() {
    for bell in Stage.sixteen.allBells {
      #expect(Bell(number: bell.number) == bell)
      #expect(Bell(number: bell.number, on: .sixteen) == bell)
    }
  }

  @Test("init(number:) rejects numbers outside 1...16")
  func outOfRange() {
    #expect(Bell(number: 0) == nil)
    #expect(Bell(number: -1) == nil)
    #expect(Bell(number: Int.min) == nil)
    #expect(Bell(number: 17) == nil)
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
}
