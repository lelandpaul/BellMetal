import Testing
@testable import BellMetal

@Suite("Array interleaving")
struct ArrayInterleavingTests {
  
  @Test("Arrays of equal length") func equalLength() async throws {
    #expect([1,2,3].interleave(with: [4,5,6]) == [1,4,2,5,3,6])
  }
  
  @Test("First array shorter") func firstShort() async throws {
    #expect([1,2,3].interleave(with: [4,5,6,7,8]) == [1,4,2,5,3,6,7,8])
  }
  
  @Test("First array longer") func firstLong() async throws {
    #expect([1,2,3,7,8].interleave(with: [4,5,6]) == [1,4,2,5,3,6,7,8])
  }
}
