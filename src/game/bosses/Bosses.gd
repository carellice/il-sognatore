extends RefCounted
## Fabbrica dei 10 boss (uno script per boss in questa cartella).

const FILES := [
	"ReGiocattoli", "Cumulonembo", "GrandeTomo", "Leviatano", "Sindaco",
	"GrandeOrologio", "ReginaGlassata", "FlavioOscuro", "OcchioCiclone", "Incubo",
]


static func create(world: int):
	var path := "res://src/game/bosses/%s.gd" % FILES[world - 1]
	if not ResourceLoader.exists(path):
		return null
	return load(path).new()
