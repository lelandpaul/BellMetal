import Benchmark
import BellMetal

// Written against only the API that BellMetal 1.x and 2.0 share, so the
// same source measures both (see ../../README.md). Stages above 16 exist
// only from 2.0; their benchmarks register only when the BellMetal being
// measured supports them.

/// Stages every BellMetal version supports. 16 is the largest stage in the
/// narrow (UInt64) layout.
let narrowStages = [6, 8, 12, 16]
/// Stages only BellMetal 2.0 supports, in the wide layout.
let wideStages = [17, 18, 22, 24]
let supportsWideStages = Stage(rawValue: 16) != nil

/// SplitMix64, so every run measures the same rows.
struct SeededGenerator: RandomNumberGenerator {
  var state: UInt64
  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}

/// Fixed inputs for one stage, built once at registration.
struct Inputs: Sendable {
  let stage: Stage
  let rows: [Row]
  let rowStrings: [String]
  let notationString: String
  let notation: PlaceNotation
  let course: Block
  let transposedCourse: Block
  let masks: [Mask]
  let allMatchingMask: Mask

  init(count: Int) throws {
    stage = Stage(count)
    var generator = SeededGenerator(state: UInt64(count))
    let bells = (0..<UInt8(count)).map { Bell(rawValue: $0)! }
    rows = try (0..<64).map { _ in try Row(validating: bells.shuffled(using: &generator)) }
    rowStrings = rows.map(\.description)

    // Plain Bob: "x1n" n/2 times then "12" on even stages; alternating
    // "n.1" then "12n" on odd ones.
    let tenor = stage.tenor.description
    if count.isMultiple(of: 2) {
      notationString = String(repeating: "x1\(tenor)", count: count / 2) + ",12"
    } else {
      notationString = (0..<count).map { $0.isMultiple(of: 2) ? tenor : "1" }.joined(separator: ".") + ",12\(tenor)"
    }
    notation = try PlaceNotation(string: notationString, at: stage)
    course = try notation.prick(repeat: .untilRound)
    transposedCourse = try course.transpose(by: rows[1])

    let (nearTenor, tenorBell) = stage.tenorPair
    let front = String(repeating: "x", count: count - 2)
    masks = [
      Mask(stringLiteral: front + nearTenor.description + tenorBell.description),
      Mask(stringLiteral: front + tenorBell.description + nearTenor.description),
    ]
    // Rounds at the front, the back five free: 120 matching rows.
    let fixed = bells.prefix(count - 5).map(\.description).joined()
    allMatchingMask = Mask(stringLiteral: fixed + "xxxxx")
  }
}

let benchmarks: @Sendable () -> Void = {
  Benchmark.defaultConfiguration = .init(
    metrics: [.wallClock, .cpuTotal, .mallocCountTotal, .throughput],
    maxDuration: .seconds(1),
    maxIterations: 1_000_000
  )
  let kilo = Benchmark.Configuration(scalingFactor: .kilo)

  let stages = narrowStages + (supportsWideStages ? wideStages : [])
  for count in stages {
    let inputs = try! Inputs(count: count) // Safe: fixed, valid inputs
    let label = count < 10 ? "0\(count) bells" : "\(count) bells"
    let rows = inputs.rows

    // MARK: Row

    Benchmark("Row.init(validating:) | \(label)", configuration: kilo) { benchmark in
      for i in benchmark.scaledIterations {
        blackHole(try Row(validating: inputs.rowStrings[i & 63]))
      }
    }
    Benchmark("Row * Row | \(label)", configuration: kilo) { benchmark in
      for i in benchmark.scaledIterations {
        blackHole(rows[i & 63] * rows[(i + 1) & 63])
      }
    }
    Benchmark("Row.invert | \(label)", configuration: kilo) { benchmark in
      for i in benchmark.scaledIterations {
        blackHole(rows[i & 63].invert())
      }
    }
    Benchmark("Row.pow(7) | \(label)", configuration: kilo) { benchmark in
      for i in benchmark.scaledIterations {
        blackHole(rows[i & 63].pow(7))
      }
    }
    Benchmark("Row[position], every position | \(label)", configuration: kilo) { benchmark in
      for i in benchmark.scaledIterations {
        let row = rows[i & 63]
        for position in 1...count { blackHole(row[position]) }
      }
    }
    Benchmark("Row[bell], every bell | \(label)", configuration: kilo) { benchmark in
      for i in benchmark.scaledIterations {
        let row = rows[i & 63]
        for bell in row { blackHole(row[bell]) }
      }
    }
    Benchmark("Row.description | \(label)", configuration: kilo) { benchmark in
      for i in benchmark.scaledIterations {
        blackHole(rows[i & 63].description)
      }
    }
    Benchmark("Row.placeBellOrders | \(label)", configuration: kilo) { benchmark in
      for i in benchmark.scaledIterations {
        blackHole(rows[i & 63].placeBellOrders)
      }
    }
    Benchmark("Set<Row> insert 64 rows | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        var set = Set<Row>()
        for row in rows { set.insert(row) }
        blackHole(set)
      }
    }
    Benchmark("Stage.rounds | \(label)", configuration: kilo) { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(inputs.stage.rounds)
      }
    }
    if let higher = Stage(rawValue: UInt8(count)) {
      Benchmark("Row.extend(to: +1) | \(label)", configuration: kilo) { benchmark in
        for i in benchmark.scaledIterations {
          blackHole(try rows[i & 63].extend(to: higher))
        }
      }
    }

    // MARK: PlaceNotation

    Benchmark("PlaceNotation.init(string:) Plain Bob | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(try PlaceNotation(string: inputs.notationString, at: inputs.stage))
      }
    }
    Benchmark("PlaceNotation.leadhead | \(label)", configuration: kilo) { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(inputs.notation.leadhead)
      }
    }
    Benchmark("PlaceNotation.description | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(inputs.notation.description)
      }
    }
    Benchmark("prick one lead | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(try inputs.notation.prick())
      }
    }
    Benchmark("prick plain course (.untilRound) | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(try inputs.notation.prick(repeat: .untilRound))
      }
    }
    Benchmark("prick 160 leads (.times) | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(try inputs.notation.prick(repeat: .times(160)))
      }
    }

    // MARK: Block

    let course = inputs.course
    Benchmark("Block iterate plain course | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        var total = 0
        for row in course { total &+= row[1].number }
        blackHole(total)
      }
    }
    Benchmark("Block subscript every row | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        for index in 0..<course.count { blackHole(course[index]) }
      }
    }
    Benchmark("Block.transpose | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(try course.transpose(by: rows[1]))
      }
    }
    Benchmark("Block.isTrue(against:) | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(try course.isTrue(against: inputs.transposedCourse))
      }
    }
    Benchmark("Block + Block | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(course + inputs.transposedCourse)
      }
    }
    Benchmark("Block.groupByStroke | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(course.groupByStroke())
      }
    }
    if let higher = Stage(rawValue: UInt8(count + 1)) {
      Benchmark("Block.extend(to: +2) | \(label)") { benchmark in
        for _ in benchmark.scaledIterations {
          blackHole(try course.extend(to: higher))
        }
      }
    }
    Benchmark("Block.count(matchingAny:) | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(try course.count(matchingAny: inputs.masks))
      }
    }
    Benchmark("MusicScheme.shared.score | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        blackHole(MusicScheme.shared.score(course))
      }
    }

    // MARK: Mask

    Benchmark("Mask.matches | \(label)", configuration: kilo) { benchmark in
      for i in benchmark.scaledIterations {
        blackHole(inputs.masks[0].matches(rows[i & 63]))
      }
    }
    Benchmark("Mask.allMatchingRows (120) | \(label)") { benchmark in
      for _ in benchmark.scaledIterations {
        var iterator = inputs.allMatchingMask.allMatchingRows()
        while let row = iterator.next() { blackHole(row) }
      }
    }
  }
}
