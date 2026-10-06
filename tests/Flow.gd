extends RefCounted
## Prova di flusso (headless):  godot --headless --path . --fixed-fps 60 -- --flow
## Percorre menu, nuova partita, scene, livello, pausa, mappa, galleria, impostazioni,
## "ti svegli", boss finale, titoli di coda e game over chiamando le stesse funzioni
## dei pulsanti. Usa lo slot 3 e rimette a posto impostazioni e galleria alla fine.

var main: Node
var step := ""


func wait(sec: float) -> void:
	await main.get_tree().create_timer(sec).timeout


func until(screen: String) -> void:
	for i in range(200):
		if main.current != null and main.screen == screen and not main.busy:
			await wait(0.2)
			return
		await wait(0.1)
	push_error("FLOW: schermata '%s' mai raggiunta (passo: %s)" % [screen, step])


func press(root: Node, text: String) -> bool:
	for c in root.get_children():
		if c is Button and c.text == text and not c.disabled:
			c.pressed.emit()
			return true
		if press(c, text):
			return true
	return false


func run(m: Node) -> void:
	main = m
	var settings_bak: Dictionary = Save.settings.duplicate(true)
	var gallery_bak: Dictionary = Save.gallery.duplicate(true)
	var slot := 2
	Save.delete_slot(slot)

	step = "titolo"
	print("passo: ", step)
	await until("title")
	main.current._slots(true)
	await wait(0.2)
	main.current._pick(slot, true, {})
	step = "nuova partita"
	print("passo: ", step)
	await until("newgame")
	var ng = main.current
	ng._keypad()
	ng._key("4")
	ng._key("2")
	ng._key(T.t("ok"))
	assert(ng.seed_val == 42)
	ng.mode = "agitato"
	ng._menu()
	ng._start()
	step = "prologo"
	print("passo: ", step)
	await until("cutscene")
	for i in range(12):
		if main.screen == "cutscene" and not main.busy:
			main.current._advance()
		await wait(0.1)
	step = "tutorial"
	print("passo: ", step)
	await until("game")
	var game = main.current
	assert(game.lv.tutorial)
	await wait(0.5)
	game.open_pause()
	await wait(0.3)
	press(game.overlay, T.t("settings"))
	await wait(0.3)
	game.close_pause()
	game.player_fell()
	game.spawn_clone()
	game.start_slow()
	await wait(0.5)
	game.secret_found = true
	game._win()
	await wait(1.5)
	press(game.overlay, T.t("continue"))
	step = "mappa"
	print("passo: ", step)
	await until("map")
	var map = main.current
	map._select(2)
	map._switch(1)
	map._play(2)
	step = "livello 1-2"
	print("passo: ", step)
	await until("game")
	game = main.current
	assert(Save.run["level"] == 2 and Save.run["mode"] == "agitato")
	game._checkpoint({"idx": 1, "feet": game.cp_feet, "node": Sprite2D.new(), "on": false})
	Save.run["lives"] = 1
	game.player.die()
	step = "ti svegli"
	print("passo: ", step)
	await wait(4.5)
	await until("game")
	assert(Save.run["level"] == 1 and Save.run["lives"] == 5)

	step = "galleria"
	print("passo: ", step)
	main.goto("gallery")
	await until("gallery")
	for tab in ["story", "memories", "bestiary", "stats"]:
		main.current._tab(tab)
		await wait(0.2)
	step = "impostazioni"
	print("passo: ", step)
	main.goto("settings")
	await until("settings")
	for i in range(13):
		var st = main.current
		st._cycle(st.ITEMS[i])
		await wait(0.1)
	Save.settings = settings_bak.duplicate(true)
	main.apply_settings()

	step = "continua da slot"
	print("passo: ", step)
	main.goto("title")
	await until("title")
	main.current._slots(false)
	await wait(0.2)
	main.current._pick(slot, false, Save.peek_slot(slot))
	await until("map")

	step = "ogni mondo: livello 1 e boss"
	print("passo: ", step)
	Save.run["max_world"] = 10
	Save.run["max_level"] = G.LEVELS
	for w in range(2, 11):
		main.goto("game", {"world": w, "level": 1})
		await until("game")
		assert(main.current.hint_ents.size() >= 1)
		await wait(0.3)
	for w in range(1, 10):
		main.goto("game", {"world": w, "level": G.LEVELS})
		await until("game")
		game = main.current
		assert(game.boss != null)
		await wait(0.6)
		for i in range(9):
			game.boss.invuln = 0.0
			game.boss.hit()
		assert(game.boss.dead and game.portal_active)
		game.on_player_respawn_test()

	step = "boss finale e finale"
	print("passo: ", step)
	main.goto("game", {"world": 10, "level": G.LEVELS})
	await until("game")
	game = main.current
	await wait(0.6)
	for i in range(9):
		game.boss.invuln = 0.0
		game.boss.on_switches()
		game.boss.hit()
	assert(game.boss.dead)
	Save.run["max_world"] = 10
	Save.run["max_level"] = G.LEVELS
	game._win()
	await wait(1.5)
	press(game.overlay, T.t("continue"))
	await until("cutscene")
	# i tocchi sullo schermo non fanno avanzare il finale: serve il pulsante "Avanti"
	for i in range(16):
		if main.screen == "cutscene" and not main.busy:
			main.current._advance()
		await wait(0.1)
	assert(main.screen == "cutscene" and main.current.panels[main.current.pi].get("lock", false))
	assert(main.current.next_btn.visible and not main.current.skip_btn.visible)
	# i quattro quadri del finale sono tutti bloccati: un "Avanti" per ciascuno
	for i in range(4):
		assert(main.screen == "cutscene" and main.current.panels[main.current.pi].get("lock", false))
		main.current._advance()
		main.current._advance()
		assert(main.current.pi == i)
		press(main.current, T.t("next"))
		await wait(0.1)
	await until("credits")
	assert(Save.run["finished"] and Save.gallery["incubo"])
	main.current._done()
	await until("title")

	step = "incubo: game over"
	print("passo: ", step)
	Save.new_run(slot, 7, "incubo", true)
	main.goto("game", {"world": 1, "level": 1})
	await until("game")
	main.current.player.die()
	await until("gameover")
	assert(Save.run["over"])

	Save.delete_slot(slot)
	Save.settings = settings_bak
	Save.gallery = gallery_bak
	Save.save_global()
	print("FLOW OK")
	main.get_tree().quit()
