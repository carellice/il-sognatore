extends Control
## HUD: salute, vite (solo Sonno agitato), frammenti, livello, barra del boss.
## Ogni gruppo sta in un riquadro scuro arrotondato; i valori "saltano" quando cambiano.

var game
var cues: Array = []  # indicatori visivi per i suoni importanti
var t := 0.0
var last_hp := -1
var last_frags := -1
var hp_bump := 0.0
var frag_bump := 0.0


func _ready() -> void:
	G.full(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func cue(screen_y: float) -> void:
	cues.append({"y": screen_y, "t": 0.9})


func _process(dt: float) -> void:
	t += dt
	hp_bump = maxf(0.0, hp_bump - dt * 3.0)
	frag_bump = maxf(0.0, frag_bump - dt * 5.0)
	for c in cues:
		c["t"] -= dt
	cues = cues.filter(func(c): return c["t"] > 0.0)
	queue_redraw()


func _text(pos: Vector2, s: String, col: Color) -> void:
	draw_string(Art.font, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 0, 0, 0.6))
	draw_string(Art.font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)


func _tw(s: String) -> float:
	return Art.font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x


## Disegna una texture ingrandita attorno al suo centro (per i "salti").
func _pop(tex: Texture2D, pos: Vector2, k: float, mod := Color.WHITE) -> void:
	var sz := tex.get_size()
	draw_set_transform(pos + sz * 0.5, 0.0, Vector2(k, k))
	draw_texture(tex, -sz * 0.5, mod)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _bar(r: Rect2, k: float, col: Color) -> void:
	draw_style_box(Art.hud_box(), r.grow(2))
	var w := r.size.x * clampf(k, 0.0, 1.0)
	draw_rect(Rect2(r.position, Vector2(w, r.size.y)), col)
	draw_rect(Rect2(r.position, Vector2(w, 1)), col.lightened(0.5))


func _draw() -> void:
	if game == null or game.player == null:
		return
	var hp: int = game.player.hp
	if hp != last_hp:
		if last_hp != -1:
			hp_bump = 1.0
		last_hp = hp
	if game.frags != last_frags:
		if last_frags != -1:
			frag_bump = 1.0
		last_frags = game.frags
	var agitato: bool = Save.run.get("mode", "") == "agitato"
	var lives_txt := "×%d" % Save.run.get("lives", 0)
	var frag_txt := str(game.frags)
	# larghezza del riquadro
	var w := 6.0 + G.MAX_HP * 10 + 5 + 10 + _tw(frag_txt) + 6
	if agitato:
		w += 12 + _tw(lives_txt) + 5
	if game.secret_found:
		w += 14
	var x: float = game.safe_margin + 4.0 + (34.0 if Save.settings["lefty"] else 0.0)
	draw_style_box(Art.hud_box(), Rect2(x, 3, w, 16))
	x += 6
	var heart := Art.tex("heart")
	var heart_off := Art.tex("heart_off")
	for i in range(G.MAX_HP):
		var full := i < hp
		var k := 1.0
		if full and hp == 1:
			k = 1.0 + 0.14 * maxf(0.0, sin(t * 8.0))
		if hp_bump > 0.0 and (i == hp or i == hp - 1):
			k += hp_bump * 0.5
		_pop(heart if full else heart_off, Vector2(x + i * 10, 7), k, Color.WHITE if full else Color(1, 1, 1, 0.7))
	x += G.MAX_HP * 10 + 2
	draw_rect(Rect2(x, 6, 1, 10), Color(1, 1, 1, 0.16))
	x += 4
	if agitato:
		draw_texture(Art.tex("life"), Vector2(x, 6))
		_text(Vector2(x + 12, 15), lives_txt, Color.WHITE)
		x += 12 + _tw(lives_txt) + 5
	_pop(Art.tex("frag"), Vector2(x, 7), 1.0 + frag_bump * 0.45)
	_text(Vector2(x + 11, 15 - round(frag_bump * 2.0)), frag_txt, Color("fff3b0"))
	x += 11 + _tw(frag_txt) + 3
	if game.secret_found:
		draw_texture(Art.tex("secret"), Vector2(x, 5))
	var boss_on: bool = game.boss != null and not game.boss.dead and game.boss.active
	if boss_on:
		# barra del boss, a tacche
		var bw := 132.0
		var bx: float = round((size.x - bw) * 0.5)
		draw_style_box(Art.hud_box(Color(1, 1, 1, 0.3)), Rect2(bx - 4, 3, bw + 8, 12))
		var total: int = game.boss.PHASES * game.boss.HITS
		var seg := bw / total
		var acc: Color = G.pal(game.world, "accent")
		for i in range(total):
			var r := Rect2(bx + i * seg + 0.5, 6, seg - 1, 6)
			if i < game.boss.hits_left():
				draw_rect(r, acc)
				draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), acc.lightened(0.45))
				draw_rect(Rect2(r.position + Vector2(0, 5), Vector2(r.size.x, 1)), acc.darkened(0.3))
			else:
				draw_rect(r, Color(0.2, 0.19, 0.3, 0.9))
		var name: String = T.t("boss_" + str(game.world))
		_text(Vector2(round((size.x - _tw(name)) * 0.5), 26), name, Color.WHITE)
	else:
		# livello corrente
		var tag := "%d-%d" % [game.world, game.level]
		var tw := _tw(tag) + 10
		var tx: float = round((size.x - tw) * 0.5)
		draw_style_box(Art.hud_box(Color(1, 1, 1, 0.12)), Rect2(tx, 3, tw, 13))
		_text(Vector2(tx + 5, 13), tag, Color(1, 1, 1, 0.85))
	if Save.settings["mod_god"]:
		_text(Vector2(game.safe_margin + 6.0 + (34.0 if Save.settings["lefty"] else 0.0), 30), "MOD", Color("ff8fb0"))
	# tempo rallentato e riflesso
	if game.slow_t > 0.0:
		_bar(Rect2(round((size.x - 60) * 0.5), size.y - 14, 60, 3), game.slow_t / G.SLOW_TIME, G.ABILITY_COLOR["tempo"])
	if game.clone != null:
		_bar(Rect2(round((size.x - 60) * 0.5), size.y - 7, 60, 3), game.clone_t / G.CLONE_TIME, G.ABILITY_COLOR["riflesso"])
	for c in cues:
		if int(c["t"] * 10.0) % 2 == 0:
			draw_string(Art.font_big, Vector2(size.x - 16 - game.safe_margin, c["y"] + 8), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ffe27a"))
