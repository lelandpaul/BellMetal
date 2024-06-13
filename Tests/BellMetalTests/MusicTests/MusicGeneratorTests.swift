import Testing
@testable import BellMetal

@Suite("Music Generator Tests")
struct MusicGeneratorTests {
  typealias GenDoubles = MusicType<Doubles>.MaskGenerator
  typealias GenMajor = MusicType<Major>.MaskGenerator
  typealias GenCaters = MusicType<Caters>.MaskGenerator
  typealias GenMaximus = MusicType<Maximus>.MaskGenerator
  typealias NRDoubles = NamedRow<Doubles>
  typealias NRMajor = NamedRow<Major>
  typealias NRCaters = NamedRow<Caters>
  typealias NRMaximus = NamedRow<Maximus>
  
  @Test
  func fiveSix() async throws {
    #expect(GenDoubles.fiveSix().isEmpty)
    #expect(GenMajor.fiveSix() == [
      "xxxx5678",
      "xxxx6578"
    ])
    #expect(GenCaters.fiveSix() == [
      "xxxx56789",
      "xxxx65789"
    ])
  }
  
  @Test
  func runs() async throws {
    #expect(GenDoubles.run(length: 5).isEmpty)
    #expect(GenDoubles.run(length: 4).toSet() == [
      "x1234",
      "x4321",
      "1234x",
      "4321x",
      "2345x",
      "x2345",
      "5432x",
      "x5432"
    ])
    #expect(GenCaters.run(length: 7).toSet() == [
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
    ])
  }
  
  @Test
  func namedRows() throws {
    #expect(NRDoubles.explodedtittums.row == "34251")
    #expect(NRMajor.explodedtittums.row == "45362718")
    
    #expect(NRDoubles.intermediate.row == "13254")
    #expect(NRMajor.intermediate.row == "13254768")
    
    #expect(NRDoubles.princes.row == "53214")
    #expect(NRMajor.princes.row == "75321468")
    
    #expect(NRMajor.princesses.row == "13527468")
    #expect(NRCaters.princesses.row == "135729468")
    
    #expect(NRMajor.tittums.row == "15263748")
    #expect(NRCaters.tittums.row == "162738495")
    
    #expect(NRMajor.whittingtons.row == "12753468")
    #expect(NRCaters.whittingtons.row == "129753468")
    #expect(NRMaximus.whittingtons.row == nil)
  }
  
  @Test
  func wraps() async throws {
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
    #expect(roundsWraps == expectedWraps)
  }
  
  @Test
  func tenorsReversed() async throws {
    #expect(GenMajor.tenorsReversed() == [
      "xxxxxxxx/xxxxxx87"
    ])
  }
}
