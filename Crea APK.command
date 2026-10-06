#!/bin/bash
# Doppio clic: incrementa la versione e genera l'APK Android di debug in build/.
# La versione sta in export_presets.cfg (version/code e version/name) e in project.godot.
cd "$(dirname "$0")" || exit 1

GODOT="$(command -v godot || echo /opt/homebrew/bin/godot)"
if [ ! -x "$GODOT" ]; then
	echo "Godot non trovato. Installalo con: brew install --cask godot"
	read -r -p "Premi Invio per chiudere."
	exit 1
fi

cp export_presets.cfg export_presets.cfg.bak
cp project.godot project.godot.bak

# incrementa: codice +1, ultima cifra del nome +1 (es. 0.1.0 -> 0.1.1)
VERSION=$(python3 - <<'EOF'
import re
p = "export_presets.cfg"
s = open(p).read()
code = int(re.search(r"version/code=(\d+)", s).group(1)) + 1
parts = re.search(r'version/name="([^"]+)"', s).group(1).split(".")
parts[-1] = str(int(parts[-1]) + 1)
name = ".".join(parts)
s = re.sub(r"version/code=\d+", "version/code=%d" % code, s)
s = re.sub(r'version/name="[^"]+"', 'version/name="%s"' % name, s)
open(p, "w").write(s)
p = "project.godot"
s = open(p).read()
s = re.sub(r'config/version="[^"]+"', 'config/version="%s"' % name, s)
open(p, "w").write(s)
print("%s %d" % (name, code))
EOF
)
NAME="${VERSION% *}"
CODE="${VERSION#* }"
APK="build/il-sognatore-$NAME.apk"
mkdir -p build

echo "Il Sognatore: genero la versione $NAME (codice $CODE)..."
"$GODOT" --headless --path . --export-debug "Android" "$APK" > build/export.log 2>&1

if [ -s "$APK" ] && ! grep -q "ERROR" build/export.log; then
	rm -f export_presets.cfg.bak project.godot.bak
	cp "$APK" build/il-sognatore.apk
	echo "Fatto: $APK ($(du -h "$APK" | cut -f1 | tr -d ' '))"
	open -R "$APK"
else
	# export fallito: la versione torna quella di prima
	mv export_presets.cfg.bak export_presets.cfg
	mv project.godot.bak project.godot
	rm -f "$APK"
	echo "Export fallito, versione non modificata. Ultime righe di build/export.log:"
	tail -15 build/export.log
fi
read -r -p "Premi Invio per chiudere."
