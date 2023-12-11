import XCTest
import Nimble
@testable import BellMetal

final class MusicGeneratorTests: XCTestCase {
  
  typealias GenDoubles = MusicType<Doubles>.MaskGenerator
  typealias GenMajor = MusicType<Major>.MaskGenerator
  typealias GenCaters = MusicType<Caters>.MaskGenerator
  typealias GenMaximus = MusicType<Maximus>.MaskGenerator
  typealias NRDoubles = NamedRow<Doubles>
  typealias NRMajor = NamedRow<Major>
  typealias NRCaters = NamedRow<Caters>
  typealias NRMaximus = NamedRow<Maximus>
  
  func testFiveSix() throws {
    expect(GenDoubles.fiveSix())
      .to(beEmpty())
    expect(GenMajor.fiveSix())
      .to(equal([
        "xxxx5678",
        "xxxx6578",
      ].toSet()))
    expect(GenCaters.fiveSix())
      .to(equal([
        "xxxx56789",
        "xxxx65789",
      ].toSet()))
  }
  
  func testRuns() throws {
    expect(GenDoubles.run(length: 5))
      .to(beEmpty())
    expect(GenDoubles.run(length: 4))
      .to(equal([
        "x1234",
        "x4321",
        "1234x",
        "4321x",
        "2345x",
        "x2345",
        "5432x",
        "x5432"
      ].toSet()))
    expect(GenCaters.run(length: 7))
      .to(equal([
        "1234567xx",
        "xx1234567",
        "7654321xx",
        "xx7654321",
        "2345678xx",
        "xx2345678",
        "8765432xx",
        "xx8765432",
        "3456789xx",
        "xx3456789",
        "9876543xx",
        "xx9876543",
      ]))
  }
  
  func testNamedRows() throws {
    expect(NRDoubles.explodedtittums.row)
      .to(equal("34251"))
    expect(NRMajor.explodedtittums.row)
      .to(equal("45362718"))
    expect(NRDoubles.intermediate.row)
      .to(equal("13254"))
    expect(NRMajor.intermediate.row)
      .to(equal("13254768"))
    expect(NRDoubles.princes.row)
      .to(equal("53214"))
    expect(NRMajor.princes.row)
      .to(equal("75321468"))
    // TODO: Finish testing
  }
}
