# BellMetal

A Swift library for modeling and performing calculations related to English change
ringing: bells, rows, place notation, and the musicality of a touch.

BellMetal represents rows as compact bit-packed values internally, but its public
API works entirely in terms of ordinary Swift value types and familiar ringing
notation (`"14235"`, `"x18x18,12"`, `"xxxxxx78"`), so most day-to-day code doesn't
need to think about the representation at all. It supports any stage from one to
sixteen bells.

## Installation

Add BellMetal as a dependency in your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/lelandpaul/BellMetal.git", from: "1.0.4")
]
```

and add it to your target:

```swift
.target(
  name: "YourTarget",
  dependencies: ["BellMetal"]
)
```

## Quick start

```swift
import BellMetal

// Rows are permutations, expressed as strings.
let x: Row = "214365"
let h: Row = "132546"
x * h // "241635" -- row multiplication composes rows the way ringing does

Stage.major.rounds // "12345678"

// Place notation can be pricked out into a Block of rows.
let plainBob4 = try PlaceNotation(string: "x14x14,12")
let plainCourse = try plainBob4.prick(repeat: .untilRound)
plainCourse.isTrue  // true
plainCourse.count   // 24

// Masks describe a family of rows by pattern.
let endsIn78: Mask = "xxxxxx78"
endsIn78.matches("12345678") // true

// MusicType/MusicScheme score the musicality of a block, using a scheme
// that mimics CompLib's default by default.
plainCourse.musicScore()
plainCourse.musicScoreDetails() // a breakdown by MusicType
```

See the "Place Notation Syntax" article in the full documentation (below) for the
place notation string syntax this library parses, including its shorthands.

## Documentation

The full API reference and guides are written as a DocC catalog
(`Sources/BellMetal/BellMetal.docc`). Build and open it locally with:

```bash
swift package generate-documentation --target BellMetal
```

or, in Xcode, **Product > Build Documentation**.

## Development

Run the test suite with:

```bash
swift test
```
