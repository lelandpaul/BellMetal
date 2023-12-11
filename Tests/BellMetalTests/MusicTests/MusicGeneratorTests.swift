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
        HalfPullMusicMask(stringLiteral: "xxxx5678"),
        HalfPullMusicMask(stringLiteral: "xxxx6578"),
      ]))
    expect(GenCaters.fiveSix())
      .to(equal([
        "xxxx56789",
        "xxxx65789",
      ]))
  }
  
  func testRuns() throws {
    expect(GenDoubles.run(length: 5))
      .to(beEmpty())
    expect(GenDoubles.run(length: 4).toSet())
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
    expect(GenCaters.run(length: 7).toSet())
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
      ].toSet()))
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
    
    expect(NRMajor.princesses.row)
      .to(equal("13527468"))
    expect(NRCaters.princesses.row)
      .to(equal("135729468"))
    
    expect(NRMajor.tittums.row)
      .to(equal("15263748"))
    expect(NRCaters.tittums.row)
      .to(equal("162738495"))
    
    expect(NRMajor.whittingtons.row)
      .to(equal("12753468"))
    expect(NRCaters.whittingtons.row)
      .to(equal("129753468"))
    expect(NRMaximus.whittingtons.row)
      .to(beNil())
  }
  
  func testWraps() throws {
    let roundsWraps = GenMajor.wraps(of: Major.rounds)
    let expectedWraps: [WholePullMusicMask<Major>] = [
      "x1234567/8xxxxxxx",
      "xx123456/78xxxxxx",
      "xxx12345/678xxxxx",
      "xxxx1234/5678xxxx",
      "xxxxx123/45678xxx",
      "xxxxxx12/345678xx",
      "xxxxxxx1/2345678x",
    ]
    expect(roundsWraps).to(equal(expectedWraps))
  }
  
  func testTenorsReversed() throws {
    expect(GenMajor.tenorsReversed())
      .to(equal([
        "xxxxxxxx/xxxxxx87"
      ]))
  }
}
