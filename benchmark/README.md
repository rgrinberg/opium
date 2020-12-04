# Opium Benchmark

Benchmarking of Opium with `wrk2`.

## Install wrk

We use wrk2 to generate the benchmark.

If you're on macOS, you can install wrk2 with:

```
brew tap jabley/homebrew-wrk2
brew install --HEAD wrk2
```

## Run the benchmarks

To run a benchmark, start the HTTP server that you want to benchmark:

```
opam exec -- dune exec benchmark/main.exe
```

And in another tab, run the benchmark script:

```
sh benchmark/run.sh
```

## Results

The results of the benchmarks can be found in `benchmark/opium.log`.

Here's a plot of the historgram with all of them.

![](./benchmark/histogram.png)

It has been generated with [hdrhistogram](http://hdrhistogram.github.io/HdrHistogram/plotFiles.html).
