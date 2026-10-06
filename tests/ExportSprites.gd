extends RefCounted
## Esporta in sprite-images/ i PNG di tutti gli sprite del gioco (generati dal codice).
## Uso (serve la finestra, non --headless):  godot --path . -- --export-sprites
## Ogni immagine c'è in due versioni: nome.png (dimensione originale) e nome@4x.png.

const ArtBG = preload("res://src/core/ArtBG.gd")
const EnemyDefs = preload("res://src/game/EnemyDefs.gd")

const AGES := ["6-anni", "9-anni", "14-anni", "20-anni", "30-anni"]
const POSES := {
	"idle": "fermo", "run0": "corsa-1", "run1": "corsa-2", "run2": "corsa-3", "run3": "corsa-4",
	"jump": "salto", "fall": "caduta", "hurt": "colpito", "glide": "planata", "slide": "scivolata",
}
const OBJECTS := {
	"frag": "frammento", "frag2": "frammento-2", "secret": "oggetto-segreto", "life": "vita-extra",
	"cp_off": "checkpoint-spento", "cp_on": "checkpoint-acceso", "switch_up": "interruttore-su",
	"switch_down": "interruttore-giu", "blade": "lama", "guard": "scudo-nemico",
	"cherry": "ciliegia-portafortuna",
}
const UI_ICONS := {
	"heart": "cuore", "heart_off": "cuore-vuoto", "pause": "pausa", "hand": "mano-tutorial",
	"ic_scatto": "abilita-scatto", "ic_bolla": "abilita-bolla", "ic_gravita": "abilita-gravita",
	"ic_tempo": "abilita-tempo", "ic_schianto": "abilita-schianto", "ic_riflesso": "abilita-riflesso",
}

var main: Node
var root := ""
var count := 0


func wait(sec: float) -> void:
	await main.get_tree().create_timer(sec).timeout


func save(img: Image, rel: String) -> void:
	var path := root + "/" + rel + ".png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	var big: Image = img.duplicate()
	big.resize(img.get_width() * 4, img.get_height() * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(root + "/" + rel + "@4x.png")
	count += 1


func tex(t: Texture2D, rel: String) -> void:
	save(t.get_image(), rel)


func world_dir(w: int) -> String:
	return "%02d-%s" % [w, G.WORLDS[w - 1]["id"]]


func run(m: Node) -> void:
	main = m
	root = ProjectSettings.globalize_path("res://sprite-images")
	DirAccess.make_dir_recursive_absolute(root)
	var f := FileAccess.open(root + "/.gdignore", FileAccess.WRITE)
	f.close()
	# Flavio (5 età) e la sua versione oscura
	for st in range(5):
		var fr: Dictionary = Art.player_frames(st)
		var dk: Dictionary = Art.dark_player_frames(st)
		for p in POSES:
			tex(fr[p], "flavio/%s/%s" % [AGES[st], POSES[p]])
			tex(dk[p], "flavio-oscuro/%s/%s" % [AGES[st], POSES[p]])
	# Chiara
	tex(Art.tex("chiara"), "chiara/chiara-bambina")
	tex(Art.tex("chiara_adult"), "chiara/chiara-adulta")
	tex(Art.tex("echo"), "chiara/eco-di-chiara")
	# nemici, per mondo, e la loro versione "ombra" dell'Incubo
	for w in range(1, 11):
		for k in G.WORLDS[w - 1]["enemies"]:
			if Art.Sprites.SPR.has(k):
				tex(Art.tex(k), "nemici/%s/%s" % [world_dir(w), k])
				tex(Art.shadow_tex(k), "nemici/ombre/%s" % k)
	tex(Art.tex("tombino_o"), "nemici/%s/tombino-aperto" % world_dir(5))
	# oggetti, proiettili, interfaccia
	for k in OBJECTS:
		tex(Art.tex(k), "oggetti/" + OBJECTS[k])
	for k in Art.Sprites.SPR:
		if str(k).begins_with("shot_"):
			tex(Art.tex(k), "proiettili/" + str(k).substr(5))
	for k in UI_ICONS:
		tex(Art.tex(k), "interfaccia/" + UI_ICONS[k])
	tex(Art.logo_tex(T.t("title")), "interfaccia/logo")
	# decorazioni, tileset e sfondi di ogni mondo
	for w in range(1, 11):
		var i := 1
		for d in Art.decor(w):
			tex(d[0], "decorazioni/%s/decorazione-%d" % [world_dir(w), i])
			i += 1
		var ts: TileSet = Art.tileset(w)
		tex((ts.get_source(0) as TileSetAtlasSource).texture, "tileset/" + world_dir(w))
		var layers: Array = Art.bg(w)
		var sky: Image = layers[0].get_image()
		sky.resize(320, sky.get_height(), Image.INTERPOLATE_NEAREST)
		save(sky, "sfondi/%s/cielo" % world_dir(w))
		tex(layers[1], "sfondi/%s/strato-lontano" % world_dir(w))
		tex(layers[2], "sfondi/%s/strato-vicino" % world_dir(w))
	# boss: sono disegnati dal codice, quindi si fotografano dentro il loro livello
	Save.settings["hd2d"] = false
	Save.new_run(-1, 12345, "lucido", true)
	Save.run["max_world"] = 10
	Save.run["max_level"] = G.LEVELS
	for w in range(1, 11):
		main.goto("game", {"world": w, "level": G.LEVELS})
		await wait(1.6)
		var game = main.current
		if game == null or game.get("boss") == null or game.boss == null:
			continue
		game.state = "pause"
		await wait(0.3)
		var b: Node2D = game.boss
		for c in game.get_children():
			if c != b and (c is CanvasItem or c is CanvasLayer):
				c.visible = false
		game.cam.position = b.global_position + Vector2(0, -20)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img: Image = main.vp1.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		# solo la zona attorno al boss (tranne l'Incubo, che è enorme): niente gocce o scie lontane
		var vs := img.get_size()
		var center := Vector2i(vs.x / 2, vs.y / 2 + 20)
		var area := Rect2i(Vector2i.ZERO, vs) if w == 10 else Rect2i(center - Vector2i(110, 100), Vector2i(220, 180)).intersection(Rect2i(Vector2i.ZERO, vs))
		var part: Image = img.get_region(area)
		var used := part.get_used_rect()
		if used.size.x > 0:
			save(part.get_region(used), "boss/%s" % world_dir(w).replace(G.WORLDS[w - 1]["id"], G.WORLDS[w - 1]["boss"]))
	Save.load_global()
	print("sprite esportati: %d immagini in %s" % [count, root])
	main.get_tree().quit()
