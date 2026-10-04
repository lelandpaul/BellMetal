# Plan: what is left

Every open item as of 2026-10-04, each checked against the code and the issue tracker (one open issue, no
open PRs). Done work isn't listed (git history has it). The design behind the code is in `row-storage.md`.
Items marked *(decision)* need an owner's call, not just work.

1. **`MusicScheme.score(_:backstrokeStart:)` ignores `backstrokeStart`.** It calls `pair.type.score(block)`
   (`Sources/BellMetal/Music/MusicScheme.swift:38`) instead of passing the flag through, so
   `.tenorsReversed` is always scored as if the block starts at handstroke. `scoreDetails` and
   `MusicType.score` do pass it, so `score` and the sum of `scoreDetails` disagree when it is `true`. Fix and
   add a test (no test covers the flag at scheme level).
2. **`Block.description` is missing a closing parenthesis** (`Sources/BellMetal/Block.swift:99`:
   `"Block(\(Array(self))"`). Fix and add a test.
3. **Jump-change place notation** ([#2](https://github.com/lelandpaul/BellMetal/issues/2)).
   `PlaceNotation(string:at:)` throws on the CCCBR Jump class (`(24)`, `[3142]`), 28 methods at stages up to
   16. *(decision)* Whether to extend the one-transposition-per-change model or keep jump changes separate,
   and which of the two notations must round-trip through `description`.
4. *(decision)* **Named rows and combination masks stop at Sixteen.** `NamedRow.hagdyke` and `.jacks`, and
   `MusicType.namedComboMasks`, are defined for stages up to 16 only, so `.namedRowCombo` scores 0 and those
   named rows are absent above 16. Define them for 17-24, or leave music scoring at 16 and below.
5. *(decision)* **`BellMetalError.inconsistentStageForMusic` is never thrown.** It is public and documented as
   reserved. Removing it breaks exhaustive `switch`es over `BellMetalError`; keeping it leaves a dead case.
