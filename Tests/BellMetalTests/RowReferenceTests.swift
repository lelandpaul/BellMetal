import Foundation
import Testing
@testable import BellMetal

/// Every public Row operation, at every stage 1-24, against a plain
/// `[Int]` reference (1-based bell numbers by position), on seeded random
/// rows. Covers both layouts and the stages either side of the boundary.
@Suite("Row reference cross-check")
struct RowReferenceTests {
  static let samplesPerStage = 20

  /// Random rows as 1-based bell numbers, always including rounds.
  static func samples(count: Int) -> [[Int]] {
    RawPermutationTests.permutations(rawStage: UInt8(count - 1), seed: 0xC0FFEE &+ UInt64(count))
      .prefix(samplesPerStage)
      .map { $0.map { Int($0) + 1 } }
  }

  static func row(_ numbers: [Int]) throws -> Row {
    try Row(validating: numbers.map { Bell(number: $0)! })
  }

  // Reference operations.
  static func multiply(_ a: [Int], _ b: [Int]) -> [Int] { b.map { a[$0 - 1] } }
  static func invert(_ a: [Int]) -> [Int] {
    var result = a
    for (position, bell) in a.enumerated() { result[bell - 1] = position + 1 }
    return result
  }
  static func pow(_ a: [Int], _ n: Int) -> [Int] {
    var result = Array(1...a.count)
    for _ in 0..<abs(n) { result = multiply(result, a) }
    return n < 0 ? invert(result) : result
  }

  @Test("Construction, description, iteration, subscripts and Codable", arguments: 1...Stage.maxCount)
  func basics(count: Int) throws {
    let symbols = Array("1234567890ETABCDFGHJKLMN")
    for numbers in Self.samples(count: count) {
      let row = try Self.row(numbers)
      let string = String(numbers.map { symbols[$0 - 1] })
      #expect(row.stage == Stage(count))
      #expect(row.description == string)
      #expect(try Row(validating: string) == row)
      #expect(row.map(\.number) == numbers)
      for position in 1...count {
        #expect(row[position].number == numbers[position - 1])
        #expect(row[Bell(number: numbers[position - 1])!] == position)
      }
      #expect(row.bell(at: 0) == nil)
      #expect(row.bell(at: count + 1) == nil)
      let decoded = try JSONDecoder().decode(Row.self, from: JSONEncoder().encode(row))
      #expect(decoded == row)
    }
  }

  @Test("multiply, invert and pow", arguments: 1...Stage.maxCount)
  func arithmetic(count: Int) throws {
    let samples = Self.samples(count: count)
    for (a, b) in zip(samples, samples.dropFirst()) {
      let (rowA, rowB) = (try Self.row(a), try Self.row(b))
      #expect(rowA * rowB == (try Self.row(Self.multiply(a, b))))
      #expect(rowA.invert() == (try Self.row(Self.invert(a))))
      for n in -3...3 {
        #expect(rowA.pow(n) == (try Self.row(Self.pow(a, n))), "power \(n)")
      }
    }
  }

  @Test("placeBellOrders meets its documented definition", arguments: 1...Stage.maxCount)
  func placeBellOrders(count: Int) throws {
    for numbers in Self.samples(count: count) {
      let orders = try Self.row(numbers).placeBellOrders
      // Every place exactly once.
      #expect(orders.flatMap { $0 }.sorted() == Array(1...count))
      // Each order starts at its lowest place, and orders are sorted by it.
      #expect(orders.allSatisfy { $0.first == $0.min() })
      #expect(orders.map { $0.first! } == orders.map { $0.first! }.sorted())
      // The bell that rings place p this lead rings place q next: q is where
      // bell p sits in the leadhead. Wraps round at the end of each order.
      for order in orders {
        for (p, q) in zip(order, order.dropFirst() + [order.first!]) {
          #expect(numbers[q - 1] == p)
        }
      }
    }
  }

  @Test("extend(to:) to every higher stage appends covers", arguments: 1..<Stage.maxCount)
  func extend(count: Int) throws {
    for numbers in Self.samples(count: count).prefix(3) {
      let row = try Self.row(numbers)
      for higher in (count + 1)...Stage.maxCount {
        #expect(try row.extend(to: Stage(higher)) == (try Self.row(numbers + Array((count + 1)...higher))))
      }
      #expect(throws: BellMetalError.invalidStage) { try row.extend(to: Stage(count)) }
    }
  }
}
