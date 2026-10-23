# Place Notation Syntax

The string syntax that ``PlaceNotation`` parses, and the rules that resolve its shorthands.

## Overview

Place notation describes a method as a sequence of changes. Each change either
crosses every pair of adjacent bells (`x` or `-`), or holds one or more bells
in place while everything else around them crosses:

```swift
try PlaceNotation(string: "x18x18,12")
```

Notation must have at least one change: `""` and `"."` throw
`BellMetalError.invalidPlaceNotation`. Only a lowercase `x` is a cross, and
place letters are uppercase, so `"X18X18"` and `"x1t"` also throw.

### Places

A place is written as the position it holds, using the same characters as
``Bell``: `1`-`9` for the first nine places, then `0`, `E`, `T`, `A`, `B`, `C`,
`D`, `F`, `G`, `H`, `J`, `K`, `L`, `M`, `N` for places 10 through 24. (`I`
is skipped, as it's easily misread as `1`.) Several places in the same change are written
together, e.g. `"14"` holds places 1 and 4 while everything between them
crosses in pairs.

### The dot separator

Adjacent changes are usually written with nothing between them -- `"x14x14"`
is unambiguous, since `x` can't be confused with a place. But two changes that
are *both* written as bare numbers need a `.` between them, or they'd parse as
one compound change instead of two:

```swift
"5.3.1.3.1"   // five separate one-place changes: 5, then 3, then 1, then 3, then 1
"531"         // NOT the same thing -- read as one change, and rejected: see below
"1.4"         // two changes: 1, then 4
"14"          // one change holding places 1 and 4
```

The places in a single change must be written in ascending order, and none
may be above the stage: `"41"` and `"18"` on Minor both throw
`BellMetalError.invalidPlaceNotation`.

`PlaceNotation`'s own `description` always inserts the dot wherever it's
needed, so the string parses back to the same changes even if the one you
originally typed wasn't fully explicit. It doesn't include the stage, though,
so pass it back in with `at:` (or use `Codable`, which stores it):
`"x"` on Minor won't parse alone, and `"x14x14"` on Minor would be read as
Minimus.

### Implicit places

You don't have to spell out every place a change holds. `PlaceNotation`
infers two kinds of implicit place from context, matching standard ringing
convention:

- If the lowest place you write is even, place 1 is added in front of it.
- If the parity of the highest place you write doesn't match the stage
  (odd on an even stage, or vice versa), the last place is added after it.

So on Minimus (4 bells), `"4"` alone means the same thing as `"14"` --
place 1 is inferred since 4 is even -- and both parse identically:

```swift
try PlaceNotation(string: "x4x4,2")   // ringers' shorthand
try PlaceNotation(string: "x14x14,12") // fully explicit -- same notation
```

On an odd stage a cross can't pair every bell, so `x` makes the last place:
on Doubles, `"x"` is the same change as `"5"`. The same rule applies when the
stage is inferred: an odd highest place together with a cross means one more
bell, so `"x3"` is Minimus and `"x1x1,5"` is Minor.

### Palindromes

A comma splits the notation into sections, and each section is mirrored about
its own last change -- the standard shorthand for a symmetric method:

```swift
try PlaceNotation(string: "x4x4,2")
// expands to "x4x4x4x2", i.e. eight changes: x,4,x,4,x,4,x,2
```

A notation can have any number of comma-separated sections, each mirrored
independently, which is how asymmetric multi-part notations like Grandsire
(`"3,1.5.1.5.1"`) are written. Every section needs at least one change, so a
stray comma (`",12"`, `"x16x16,"`) throws rather than silently changing the
method.

### Explicit stage

Since a notation like `"x"` carries no place numbers at all, its stage often
can't be inferred and must be given explicitly, either as the `at:` parameter:

```swift
try PlaceNotation(string: "x", at: .minimus)
```

or as a single-character prefix on the string itself, using the same
character-per-bell convention as ``Bell`` -- `"1"`-`"9"`, then `"0"`, `"E"`,
`"T"`, `"A"`...`"D"`, `"F"`...`"H"`, `"J"`...`"N"` for stages 10 through 24:

```swift
let minor: PlaceNotation = "6:x4x4,2"   // Minor (6 bells)
let maximus: PlaceNotation = "T:x1T"  // Maximus (12 bells)
```

The prefix is exactly one character followed by one colon; `"6::x16"` and
`"6:x16:"` throw.
