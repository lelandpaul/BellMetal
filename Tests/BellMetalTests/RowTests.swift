import Testing
@testable import BellMetal

@Suite("Row unit tests")
struct RowTests {
  
  // MARK: Instantiation
  @Test func instantiateWithStringLiteral() async throws {
    let a: Row = "14235"
    #expect(a.description == "14235")
    #expect(a.row == 0x42130)
    #expect(a.stage == .doubles)
    
    let b: Row = "2143658709TEBADC"
    #expect(b.description == "2143658709TEBADC")
    #expect(b.row == 0xEFCDAB8967452301)
    #expect(b.stage == .sixteen)
  }
  
  @Test func instantiateWithArrayLiteral() async throws {
    let a: Row = [.b1, .b4, .b2, .b3, .b5]
    #expect(a.description == "14235")
    #expect(a.row == 0x42130)
    #expect(a.stage == .doubles)
    
    let b: Row = [.b2, .b1, .b4, .b3, .b6, .b5, .b8, .b7, .b0, .b9, .bT, .bE, .bB, .bA, .bD, .bC]
    #expect(b.description == "2143658709TEBADC")
    #expect(b.row == 0xEFCDAB8967452301)
    #expect(b.stage == .sixteen)
  }
  
  //MARK: Subscripts
  @Test func retrieveBellAtPostition() async throws {
    let a: Row = "14235"
    #expect(a.row.rawBell(at: 0) == 0x0)
    #expect(a.row.rawBell(at: 1) == 0x3)
    #expect(a.row.rawBell(at: 2) == 0x1)
    #expect(a.row.rawBell(at: 3) == 0x2)
    #expect(a.row.rawBell(at: 4) == 0x4)

    #expect(a[1] == .b1)
    #expect(a[2] == .b4)
    #expect(a[3] == .b2)
    #expect(a[4] == .b3)
    #expect(a[5] == .b5)
  }
  
  @Test func retrievePositionofBell() async throws {
    let a: Row = "14235"
    #expect(a.row.rawPosition(of: 0x0) == 0)
    #expect(a.row.rawPosition(of: 0x1) == 2)
    #expect(a.row.rawPosition(of: 0x2) == 3)
    #expect(a.row.rawPosition(of: 0x3) == 1)
    #expect(a.row.rawPosition(of: 0x4) == 4)
    
    #expect(a[.b1] == 1)
    #expect(a[.b2] == 3)
    #expect(a[.b3] == 4)
    #expect(a[.b4] == 2)
    #expect(a[.b5] == 5)
  }
  
  // MARK: Operators
  @Test func equality() async throws {
    let a: Row = "14235"
    let b: Row = [.b1, .b4, .b2, .b3, .b5]
    let x: Row = "32145"
    #expect(a == b)
    #expect(a != x)
    #expect(b != x)
  }
  
  @Test func multiplication() async throws {
    let x: Row = "214365"
    let h: Row = "132546"
    let xh: Row = "241635"
    let hx: Row = "315264"
    
    #expect(x * h == xh)
    #expect(h * x == hx)
    
    let t1: Row = "1342"
    let t2: Row = "4231"
    let t1t2: Row = "2341"
    let t2t1: Row = "4312"
    #expect(t1 * t2 == t1t2)
    #expect(t2 * t1 == t2t1)
    
  }
  
  @Test func inverse() async throws {
    let t: Row = "312645"
    let expected: Row = "231564"
    #expect(t.invert() == expected)
    #expect(t * t.invert() == "123456")
    #expect(t.invert() * t == "123456")
  }
  
  @Test func powers() async throws {
    let t: Row = "4123"
    #expect(t ** 0 == "1234")
    #expect(t ** 1 == "4123")
    #expect(t ** 2 == "3412")
    #expect(t ** 3 == "2341")
    #expect(t ** 4 == "1234")
    #expect(t ** 5 == "4123")
    #expect(t ** -1 == "2341")
    #expect(t ** -2 == "3412")
  }
  
  @Test func powerAndMultPrecedence() async throws {
    let t: Row = "4123"
    let x: Row = "2143"
    #expect(t ** 2 * x == "4321")
    #expect(t * x ** 2 == "4123")
  }
  
  @Test func extention() async throws {
    let t: Row = "4321"
    #expect(try t.extend(to: .doubles) == "43215")
    #expect(try t.extend(to: .major) == "43215678")
    #expect(try t.extend(to: .royal) == "4321567890")
  }
  
  @Test func swap() async throws {
    let t_row: Row = "1234"
    let t_raw = t_row.row
    #expect(Row(stage: .minimus, row: t_raw.swapUp(from: 0)) == "2134")
    #expect(Row(stage: .minimus, row: t_raw.swapUp(from: 1)) == "1324")
    #expect(Row(stage: .minimus, row: t_raw.swapUp(from: 2)) == "1243")
  }
}
