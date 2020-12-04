#!/bin/sh

set -e

opam exec -- dune exec "benchmark/src/opium.exe" &
pid=$!

# Wait for the server to start
sleep 1

echo "Running benchmarks with opium.exe"

wrk2 \
  -t8 -c10000 -d60S \
  --timeout 2000 \
  -R 30000 --latency \
  -H 'Connection: keep-alive' \
  http://localhost:3000/ \
  > "benchmark/result/opium.log" 2>&1

kill $pid

opam exec -- dune exec "benchmark/src/httpaf.exe" &
pid=$!

# Wait for the server to start
sleep 1

echo "Running benchmarks with httpaf.exe"

wrk2 \
  -t8 -c10000 -d60S \
  --timeout 2000 \
  -R 30000 --latency \
  -H 'Connection: keep-alive' \
  http://localhost:3000/ \
  > "benchmark/result/httpaf.log" 2>&1

kill $pid
