#!/bin/bash
# Prova di flusso end-to-end senza finestra (max 3 minuti).
cd "$(dirname "$0")/.."
mkdir -p build
godot --headless --path . --fixed-fps 60 -- --flow > build/flow.log 2>&1 &
pid=$!
for i in $(seq 1 360); do
  if ! kill -0 $pid 2>/dev/null; then break; fi
  sleep 0.5
done
if kill -0 $pid 2>/dev/null; then kill $pid; echo "TIMEOUT"; fi
grep -v -e "^$" -e "icon.png" -e "image_loader" build/flow.log | cut -c1-200 | tail -${1:-25}
