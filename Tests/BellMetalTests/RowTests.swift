import Testing
@testable import BellMetal

@Suite("Row unit tests")
struct RowTests {
  
  // MARK: Instantiation
  @Test("A Row instantiated from a string literal has the right description, raw value, and stage")
  func instantiateWithStringLiteral() async throws {
    let a: Row = "14235"
    #expect(a.description == "14235")
    #expect(a.row == 0x42130)
    #expect(a.stage == .doubles)
    
    let b: Row = "2143658709TEBADC"
    #expect(b.description == "2143658709TEBADC")
    #expect(b.row == 0xEFCDAB8967452301)
    #expect(b.stage == .sixteen)
  }
  
  @Test("A Row instantiated from an array literal has the right description, raw value, and stage")
  func instantiateWithArrayLiteral() async throws {
    let a: Row = [.b1, .b4, .b2, .b3, .b5]
    #expect(a.description == "14235")
    #expect(a.row == 0x42130)
    #expect(a.stage == .doubles)
    
    let b: Row = [.b2, .b1, .b4, .b3, .b6, .b5, .b8, .b7, .b0, .b9, .bT, .bE, .bB, .bA, .bD, .bC]
    #expect(b.description == "2143658709TEBADC")
    #expect(b.row == 0xEFCDAB8967452301)
    #expect(b.stage == .sixteen)
  }

  // MARK: Safe construction

  @Test("Row(validating:) throws on an empty, duplicate, or out-of-stage array of bells")
  func validatingArrayLiteral() throws {
    let row = try Row(validating: [.b1, .b4, .b2, .b3, .b5])
    #expect(row == "14235")

    #expect(throws: BellMetalError.invalidBell) {
      try Row(validating: [Bell]()) // empty
    }
    #expect(throws: BellMetalError.invalidBell) {
      try Row(validating: [.b1, .b1, .b3]) // duplicate bell, and .b2 missing
    }
    #expect(throws: BellMetalError.invalidBell) {
      try Row(validating: [.b1, .b2, .b4]) // .b4 outside a 3-bell stage
    }
  }

  @Test("Row(validating:) throws on a string with invalid characters or a non-permutation")
  func validatingString() throws {
    let row = try Row(validating: "14235")
    #expect(row == "14235")

    #expect(throws: BellMetalError.invalidBell) {
      try Row(validating: "142Z5") // "Z" isn't a valid bell character
    }
    #expect(throws: BellMetalError.invalidBell) {
      try Row(validating: "11235") // valid characters, but not a permutation
    }
  }

  @Test("Bell(character:) resolves a valid bell character, or nil for an unrecognized one")
  func bellFromCharacter() {
    #expect(Bell(character: "1") == .b1)
    #expect(Bell(character: "E") == .bE)
    #expect(Bell(character: "D") == .bD)
    #expect(Bell(character: "Z") == nil)
  }

  //MARK: Subscripts

  @Test("bell(at:) returns the bell at a 1-indexed position, or nil out of range")
  func bellAtPosition() {
    let a: Row = "14235"
    #expect(a.bell(at: 1) == .b1)
    #expect(a.bell(at: 5) == .b5)
    #expect(a.bell(at: 0) == nil)
    #expect(a.bell(at: 6) == nil)
  }

  @Test("Raw and subscript position lookups agree on which bell sits at each position")
  func retrieveBellAtPostition() async throws {
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
  
  @Test("Raw and subscript bell lookups agree on which position each bell sits in")
  func retrievePositionofBell() async throws {
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
  @Test("Rows are equal iff their bell sequences match")
  func equality() async throws {
    let a: Row = "14235"
    let b: Row = [.b1, .b4, .b2, .b3, .b5]
    let x: Row = "32145"
    #expect(a == b)
    #expect(a != x)
    #expect(b != x)
  }
  
  @Test("Row multiplication with * composes permutations, and isn't commutative")
  func multiplication() async throws {
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
  
  @Test("invert() produces the inverse permutation, which multiplies with the original to rounds")
  func inverse() async throws {
    let t: Row = "312645"
    let expected: Row = "231564"
    #expect(t.invert() == expected)
    #expect(t * t.invert() == "123456")
    #expect(t.invert() * t == "123456")
  }

  // MARK: Every stage, including the maximum

  @Test(
    "Multiplication and invert() round-trip correctly at every stage from One through Sixteen",
    arguments: 1...16
  )
  func multiplicationAndInverseRoundTripAtEveryStage(bellCount: Int) throws {
    let stage = Stage(bellCount)
    // A nontrivial permutation any stage can build without hand-authoring
    // a literal: reversing rounds is its own inverse whenever it isn't
    // already the identity (stage <= 2).
    let reversed = try Row(validating: Array(stage.allBells.reversed()))
    #expect(try reversed.multiply(by: reversed.invert()) == stage.rounds)
    #expect(try reversed.invert().multiply(by: reversed) == stage.rounds)
    #expect(reversed.invert().invert() == reversed)
  }

  @Test("Multiplication and invert() are correct at Sixteen specifically, not just non-crashing")
  func multiplicationAndInverseAtSixteen() async throws {
    // Regression test for a bug where RawRow.composePermutation and
    // Row.invert() both trapped at Stage.sixteen (rawStage == 15): each
    // built its result by loading bells at the top of the register and
    // correcting with a right-shift of `4*(14 - rawStage)`, computed in
    // unsigned arithmetic -- which underflowed exactly at rawStage == 15.
    // Every adjacent pair swapped (the first change of a full "x" cross)
    // is its own inverse: applying it twice is the identity.
    let x: Row = "2143658709TEBADC"
    #expect(x.stage == .sixteen)
    #expect(x * x == Stage.sixteen.rounds)
    #expect(x.invert() == x)
  }
  
  @Test("The ** operator raises a row to positive, zero, and negative integer powers")
  func powers() async throws {
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
  
  @Test("** binds tighter than * when the two operators are mixed")
  func powerAndMultPrecedence() async throws {
    let t: Row = "4123"
    let x: Row = "2143"
    #expect(t ** 2 * x == "4321")
    #expect(t * x ** 2 == "4123")
  }
  
  @Test("extend(to:) appends bells in ascending place order up to the target stage")
  func extention() async throws {
    let t: Row = "4321"
    #expect(try t.extend(to: .doubles) == "43215")
    #expect(try t.extend(to: .major) == "43215678")
    #expect(try t.extend(to: .royal) == "4321567890")
  }
  
  @Test("swapUp(from:) swaps the pair of bells starting at the given raw position")
  func swap() async throws {
    let t_row: Row = "1234"
    let t_raw = t_row.row
    #expect(Row(stage: .minimus, row: t_raw.swapUp(from: 0)) == "2134")
    #expect(Row(stage: .minimus, row: t_raw.swapUp(from: 1)) == "1324")
    #expect(Row(stage: .minimus, row: t_raw.swapUp(from: 2)) == "1243")
  }

  // MARK: Place bell orders

  @Test("placeBellOrders gives the standard place bell order for Plain Bob leadheads")
  func placeBellOrdersPlainBob() {
    let minor: Row = "135264"
    #expect(minor.placeBellOrders == [[1], [2, 4, 6, 5, 3]])
    let major: Row = "13527486"
    #expect(major.placeBellOrders == [[1], [2, 4, 6, 8, 7, 5, 3]])
  }

  @Test("placeBellOrders splits a multi-cycle leadhead, ordered by lowest place")
  func placeBellOrdersMultiCycle() {
    let row: Row = "13254"
    #expect(row.placeBellOrders == [[1], [2, 3], [4, 5]])
    let rotated: Row = "14523"
    #expect(rotated.placeBellOrders == [[1], [2, 4], [3, 5]])
  }

  @Test("placeBellOrders leaves every bell of rounds on its own")
  func placeBellOrdersRounds() {
    #expect(Stage.major.rounds.placeBellOrders == (1 ... 8).map { [$0] })
  }

  @Test("placeBellOrders handles the maximum stage")
  func placeBellOrdersSixteen() {
    let row: Row = "2143658709TEBADC"
    #expect(row.placeBellOrders == stride(from: 1, to: 16, by: 2).map { [$0, $0 + 1] })
  }

  @Test("Each step of every place bell order is the place the leadhead moves that bell to")
  func placeBellOrdersFollowTheBell() throws {
    for notation in ["-36-14-12-36-14-56,12", "-38-14-1258-36-14-58-16-78,12", "3,1.5.1.5.1", "3.1.7.3.1.3,1"] {
      let leadhead = try PlaceNotation(string: notation).leadhead
      let orders = leadhead.placeBellOrders
      #expect(orders.flatMap { $0 }.sorted() == Array(1 ... leadhead.stage.count))
      for order in orders {
        #expect(order.first == order.min())
        for (place, next) in zip(order, order.dropFirst() + [order[0]]) {
          #expect(leadhead[Bell(rawValue: UInt8(place - 1))!] == next)
        }
      }
    }
  }
}
