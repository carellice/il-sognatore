#!/bin/bash
# Uso: tools/shot.sh nome [argomenti...]   -> build/nome.png (finestra 3x, max 40 s)
cd "$(dirname "$0")/.."
mkdir -p build
name=$1; shift
rm -f "build/$name.png"
godot --path . --disable-vsync --fixed-fps 60 $GODOT_ARGS -- --shot="$PWD/build/$name.png" "$@" > "build/$name.log" 2>&1 &
pid=$!
for i in $(seq 1 80); do
  if ! kill -0 $pid 2>/dev/null; then break; fi
  sleep 0.5
done
if kill -0 $pid 2>/dev/null; then kill $pid; echo "TIMEOUT $name"; fi
grep -E "ERROR|SCRIPT" -A3 "build/$name.log" | grep -v -e "icon.png" -e "image_loader" | head -30
