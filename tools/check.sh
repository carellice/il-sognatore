#!/bin/bash
# Controlla che tutti gli script GDScript del progetto compilino.
cd "$(dirname "$0")/.."
godot --headless --path . -- --check 2>&1 | grep -E "Parse Error|Compile Error" -A1 | grep -v -e "^--" | paste - - | grep -v "depended" | sed 's/SCRIPT ERROR: //; s/GDScript::reload//' | sort -u
