# ``BellMetal``

A Swift library for modeling and performing calculations related to English change ringing.

## Overview

BellMetal models the core concepts of change ringing -- bells, rows, stages, place
notation, and blocks of rows -- as small, efficient value types, and builds a few
useful operations on top of them: pricking compositions from place notation,
matching rows against patterns, and scoring the musicality of a touch.

A ``Row`` is a permutation of bells, represented as a compact string like `"14235"`.
Rows exist at a ``Stage`` (a number of bells, from one to sixteen), and multiplying
two rows together (`*`) composes them the way rows compose during ringing. A
``Block`` is an ordered sequence of rows -- typically the rows rung during a touch,
or part of one.

```swift
let x: Row = "214365"
let h: Row = "132546"
x * h // "241635"

Stage.major.rounds // "12345678"
```

``PlaceNotation`` parses the compact notation ringers use to describe a method
(`"x18x18,12"`, `"36-3.4-2-3.4-4.3,2"`, and so on) and can prick it out into a
``Block`` of rows from any starting point:

```swift
let plainBob4 = try PlaceNotation(string: "x14x14,12")
let plainCourse = try plainBob4.prick(repeat: .untilRound)
plainCourse.isTrue // true
plainCourse.count // 24
```

A ``Mask`` describes a family of rows by pattern, using `x` for any bell, e.g.
`"xxxxxx78"` for every row on Major ending in 78:

```swift
let endsIn78: Mask = "xxxxxx78"
endsIn78.matches("12345678") // true
```

``MusicType`` and ``MusicScheme`` build on masks to score how "musical" a block
of rows is, using a scheme that mimics [CompLib](https://complib.org)'s default
by default:

```swift
plainCourse.musicScore() // an Int
```

## Topics

### Bells, Rows, and Stages

- ``Bell``
- ``Row``
- ``Stage``
- ``Block``

### Place Notation

- ``PlaceNotation``
- ``PlaceNotationParser``
- <doc:PlaceNotationSyntax>

### Pattern Matching

- ``Mask``

### Scoring Music

- ``MusicType``
- ``MusicScheme``
- ``NamedRow``

### Errors

- ``BellMetalError``
