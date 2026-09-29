# BellMetal benchmarks

Benchmarks for BellMetal's `Row`, `PlaceNotation`, `Block`, `Mask` and
music scoring, using [package-benchmark](https://github.com/ordo-one/package-benchmark).
They live in their own package, so the benchmark dependency never reaches
the library.

The benchmark source uses only API that BellMetal 1.x and 2.0 share, so the
same code can measure two versions against each other. Benchmarks for stages
above 16 register only when the BellMetal being measured supports them.

## Requirements

- `jemalloc` for malloc counts (`brew install jemalloc`). Without it, set
  `BENCHMARK_DISABLE_JEMALLOC=true` to get timings only.
- Pass `--disable-sandbox` to `swift package`.

## Running

From this directory, against this checkout's BellMetal:

```bash
swift package --disable-sandbox --allow-writing-to-package-directory benchmark
```

## Comparing two versions

`BELLMETAL_PATH` points the package at another BellMetal checkout. Give each
version its own `--scratch-path`, so the two builds don't overwrite each other,
and pass `--manifest-cache none` so the manifest is re-read each time rather
than reusing a cached copy that points at the other checkout.

```bash
git -C .. worktree add /tmp/BellMetal-develop develop

BELLMETAL_PATH=/tmp/BellMetal-develop swift package --disable-sandbox \
  --manifest-cache none --scratch-path .build-develop \
  --allow-writing-to-package-directory benchmark baseline update develop

swift package --disable-sandbox --manifest-cache none \
  --allow-writing-to-package-directory benchmark baseline update branch

swift package --disable-sandbox --manifest-cache none \
  --allow-writing-to-package-directory benchmark baseline compare develop branch
```

Baselines are stored in `.benchmarkBaselines/`, which is git-ignored: the
numbers are specific to the machine that recorded them.
