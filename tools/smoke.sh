#!/bin/bash
# Prova di fumo: avvia ogni mondo (livelli 1, 3 e boss) senza finestra con un "bot"
# che corre, salta e usa l'abilità, e riporta gli errori di script.
cd "$(dirname "$0")/.."
fail=0
for w in 1 2 3 4 5 6 7 8 9 10; do
  for l in ${LEVELS:-1 3 5}; do
    out=$(godot --headless --path . --fixed-fps 60 -- --go=game --world=$w --level=$l --run=${FRAMES:-1500} --keys=right,jump,ab --mode=${MODE:-lucido} 2>&1 | grep -E "SCRIPT ERROR|ERROR:" -A4 | grep -v -e "icon.png" -e "image_loader" | head -12)
    if [ -n "$out" ]; then echo "== mondo $w livello $l"; echo "$out"; fail=1; fi
  done
done
[ $fail = 0 ] && echo "smoke OK"
