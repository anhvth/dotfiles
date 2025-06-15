#!/bin/bash
# Simple zsh startup benchmark script

echo "🚀 ZSH Startup Performance Test"
echo "================================"

# Test 5 times for average
total_time=0
runs=5

for i in $(seq 1 $runs); do
    echo -n "Run $i: "
    start_time=$(date +%s.%N)
    /usr/bin/time -f "%e seconds" zsh -i -c exit 2>&1 | grep "seconds"
    end_time=$(date +%s.%N)
    runtime=$(echo "$end_time - $start_time" | bc -l)
    total_time=$(echo "$total_time + $runtime" | bc -l)
done

avg_time=$(echo "scale=3; $total_time / $runs" | bc -l)
echo "================================"
echo "Average startup time: ${avg_time} seconds"

# Performance targets
if (( $(echo "$avg_time < 0.2" | bc -l) )); then
    echo "✅ Excellent performance (< 0.2s)"
elif (( $(echo "$avg_time < 0.3" | bc -l) )); then
    echo "✅ Good performance (< 0.3s)"
elif (( $(echo "$avg_time < 0.5" | bc -l) )); then
    echo "⚠️  Acceptable performance (< 0.5s)"
else
    echo "❌ Slow performance (> 0.5s)"
fi
