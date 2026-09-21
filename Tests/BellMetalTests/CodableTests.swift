import Foundation
import Testing
@testable import BellMetal

@Suite("Codable unit tests")
struct CodableTests {
  let encoder = JSONEncoder()
  let decoder = JSONDecoder()

  private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
    let data = try encoder.encode(value)
    let decoded = try decoder.decode(T.self, from: data)
    #expect(decoded == value)
    return decoded
  }

  @Test("Bell encodes and decodes as its letter, and rejects unknown letters")
  func bellRoundTrip() throws {
    for bell in Stage.sixteen.allBells {
      _ = try roundTrip(bell)
    }
    let data = try encoder.encode(Bell.bT)
    #expect(String(data: data, encoding: .utf8) == "\"T\"")

    #expect(throws: (any Error).self) {
      try decoder.decode(Bell.self, from: Data("\"Z\"".utf8))
    }
  }

  @Test("Stage encodes and decodes as its bell count, and rejects out-of-range counts")
  func stageRoundTrip() throws {
    for stage: Stage in [.one, .doubles, .major, .cinques, .sixteen] {
      _ = try roundTrip(stage)
    }
    let data = try encoder.encode(Stage.major)
    #expect(String(data: data, encoding: .utf8) == "8")

    #expect(throws: (any Error).self) {
      try decoder.decode(Stage.self, from: Data("17".utf8))
    }
    #expect(throws: (any Error).self) {
      try decoder.decode(Stage.self, from: Data("0".utf8))
    }
  }

  @Test("Row encodes and decodes as its string, and rejects non-permutation strings")
  func rowRoundTrip() throws {
    let row: Row = "2143658709TEBADC"
    _ = try roundTrip(row)

    let data = try encoder.encode(row)
    #expect(String(data: data, encoding: .utf8) == "\"2143658709TEBADC\"")

    #expect(throws: (any Error).self) {
      try decoder.decode(Row.self, from: Data("\"1123\"".utf8)) // not a permutation
    }
  }

  @Test("Block round-trips through JSON, and rejects empty or mixed-stage arrays")
  func blockRoundTrip() throws {
    let block: Block = ["1234", "2143", "2413"]
    _ = try roundTrip(block)

    #expect(throws: (any Error).self) {
      try decoder.decode(Block.self, from: Data("[]".utf8))
    }
    #expect(throws: (any Error).self) {
      try decoder.decode(Block.self, from: Data("[\"1234\", \"12345\"]".utf8)) // mixed stages
    }
  }

  @Test("Mask encodes and decodes as its string, and rejects letters outside its stage")
  func maskRoundTrip() throws {
    let mask: Mask = "1xx2xx38"
    _ = try roundTrip(mask)

    let data = try encoder.encode(mask)
    #expect(String(data: data, encoding: .utf8) == "\"1xx2xx38\"")

    #expect(throws: (any Error).self) {
      try decoder.decode(Mask.self, from: Data("\"x1D\"".utf8)) // 'D' invalid on a 3-bell stage
    }
  }

  @Test("PlaceNotation encodes as a stage/notation pair, including the all-cross edge case")
  func placeNotationRoundTrip() throws {
    let pn = try PlaceNotation(string: "x4x4,2")
    _ = try roundTrip(pn)

    // The all-cross edge case: the notation alone carries no place numbers to
    // infer a stage from, which is exactly why encoding includes the stage.
    let cross = try PlaceNotation(string: "x", at: .minimus)
    _ = try roundTrip(cross)

    let data = try encoder.encode(pn)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(json?["stage"] as? Int == 4)
    #expect(json?["notation"] as? String == pn.description)
  }

  @Test("NamedRow encodes and decodes as its case name")
  func namedRowRoundTrip() throws {
    for namedRow in NamedRow.allCases {
      _ = try roundTrip(namedRow)
    }
    let data = try encoder.encode(NamedRow.backrounds)
    #expect(String(data: data, encoding: .utf8) == "\"backrounds\"")
  }

  @Test("Built-in MusicType cases round-trip, preserving associated values like .run's length")
  func musicTypeRoundTrip() throws {
    // MusicType isn't Equatable, so compare via description instead -- this
    // also confirms .run's associated length round-trips (a wrong length
    // would produce a different description).
    let types: [MusicType] = [
      .fiveSix, .cru, .runs, .run(length: 7), .wrap, .namedRow,
      .namedRowCombo, .tenorsReversed, .backBellCombo, .comboNearMiss,
    ]
    for type in types {
      let data = try encoder.encode(type)
      let decoded = try decoder.decode(MusicType.self, from: data)
      #expect(decoded.description == type.description)
    }
  }

  @Test("A .custom MusicType cannot be encoded or decoded, since its closure isn't Codable")
  func musicTypeCustomCannotRoundTrip() throws {
    let custom = MusicType.custom(name: "test", score: { _ in 0 })
    #expect(throws: (any Error).self) {
      try encoder.encode(custom)
    }
    #expect(throws: (any Error).self) {
      try decoder.decode(MusicType.self, from: Data(#"{"kind":"custom"}"#.utf8))
    }
  }

  @Test("MusicScheme.shared round-trips through JSON and scores the same after decoding")
  func musicSchemeRoundTrip() throws {
    let data = try encoder.encode(MusicScheme.shared)
    let decoded = try decoder.decode(MusicScheme.self, from: data)
    let rounds = Block(Row("12345678"))
    #expect(decoded.score(rounds) == MusicScheme.shared.score(rounds))
  }

  @Test("A MusicScheme containing a .custom MusicType cannot be encoded")
  func musicSchemeWithCustomTypeCannotBeEncoded() throws {
    let scheme = MusicScheme([(.custom(name: "x", score: { _ in 1 }), weight: 1)])
    #expect(throws: (any Error).self) {
      try encoder.encode(scheme)
    }
  }
}
