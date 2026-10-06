extends Node
## Radice del gioco: cambia schermata con una dissolvenza, applica tema,
## scalatura e filtro per il daltonismo.

const SCREENS := {
	"title": "res://src/ui/Title.gd",
	"newgame": "res://src/ui/NewGame.gd",
	"map": "res://src/ui/WorldMap.gd",
	"game": "res://src/game/Game.gd",
	"cutscene": "res://src/ui/Cutscene.gd",
	"settings": "res://src/ui/Settings.gd",
	"gallery": "res://src/ui/Gallery.gd",
	"credits": "res://src/ui/Credits.gd",
	"gameover": "res://src/ui/GameOver.gd",
}

const CB_SHADER := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform int mode = 0;
void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	mat3 sim = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0));
	if (mode == 1) { sim = mat3(vec3(0.567, 0.558, 0.0), vec3(0.433, 0.442, 0.242), vec3(0.0, 0.0, 0.758)); }
	if (mode == 2) { sim = mat3(vec3(0.625, 0.7, 0.0), vec3(0.375, 0.3, 0.3), vec3(0.0, 0.0, 0.7)); }
	if (mode == 3) { sim = mat3(vec3(0.95, 0.0, 0.0), vec3(0.05, 0.433, 0.475), vec3(0.0, 0.567, 0.525)); }
	vec3 err = c - sim * c;
	vec3 fix = c;
	if (mode == 3) { fix += vec3(err.b * 0.7, err.b * 0.7, 0.0); }
	else { fix += vec3(0.0, err.r * 0.7, err.r * 0.7); }
	COLOR = vec4(clamp(fix, 0.0, 1.0), 1.0);
}
"""

const EPX_SHADER := """
shader_type canvas_item;
// EPX / Scale2x: ogni pixel diventa 2x2, e gli angoli delle scalette si arrotondano.
bool eq(vec4 a, vec4 b) {
	vec4 d = abs(a - b);
	return max(max(d.r, d.g), max(d.b, d.a)) < 0.012;
}
void fragment() {
	ivec2 ts = textureSize(TEXTURE, 0);
	vec2 p = UV * vec2(ts);
	ivec2 ip = clamp(ivec2(floor(p)), ivec2(0), ts - 1);
	vec2 f = fract(p);
	vec4 P = texelFetch(TEXTURE, ip, 0);
	vec4 A = texelFetch(TEXTURE, clamp(ip + ivec2(0, -1), ivec2(0), ts - 1), 0);
	vec4 B = texelFetch(TEXTURE, clamp(ip + ivec2(1, 0), ivec2(0), ts - 1), 0);
	vec4 C = texelFetch(TEXTURE, clamp(ip + ivec2(-1, 0), ivec2(0), ts - 1), 0);
	vec4 D = texelFetch(TEXTURE, clamp(ip + ivec2(0, 1), ivec2(0), ts - 1), 0);
	vec4 o = P;
	if (f.x < 0.5 && f.y < 0.5) { if (eq(C, A) && !eq(C, D) && !eq(A, B)) o = A; }
	else if (f.x >= 0.5 && f.y < 0.5) { if (eq(A, B) && !eq(A, C) && !eq(B, D)) o = B; }
	else if (f.x < 0.5 && f.y >= 0.5) { if (eq(D, C) && !eq(D, B) && !eq(C, A)) o = C; }
	else { if (eq(B, D) && !eq(B, A) && !eq(D, C)) o = D; }
	COLOR = o;
}
"""

const FINAL_SHADER := """
shader_type canvas_item;
// Passata finale: alone morbido attorno alle zone luminose (bloom) e colori un po' più vivi.
uniform sampler2D low : filter_linear, repeat_disable;
uniform sampler2D scene : filter_linear, repeat_disable;
uniform bool use3d = false;
uniform float bloom = 0.4;
// livello 3D sotto la grafica 2D; sfocato in alto e in basso (effetto "plastico", tilt-shift)
vec3 scene_at(vec2 uv) {
	float blur = smoothstep(0.27, 0.52, abs(uv.y - 0.56)) * 2.0;
	vec3 c = texture(scene, uv).rgb;
	if (blur > 0.05) {
		vec2 px = blur / vec2(textureSize(scene, 0));
		c = c * 0.2;
		for (int i = 0; i < 8; i++) {
			float a = float(i) * 0.7854;
			c += texture(scene, uv + vec2(cos(a), sin(a)) * px * 1.6).rgb * 0.1;
		}
	}
	return c;
}
vec3 bright(vec2 uv) {
	vec3 c = texture(low, uv).rgb;
	float l = max(c.r, max(c.g, c.b));
	return c * smoothstep(0.78, 1.0, l);
}
void fragment() {
	vec4 s = texture(TEXTURE, UV);
	vec3 c = s.rgb;
	if (use3d) {
		// la grafica 2D è premoltiplicata: dove è trasparente si vede il 3D
		c = s.rgb + scene_at(UV) * (1.0 - s.a);
	}
	if (bloom > 0.0) {
		vec2 px = 1.0 / vec2(textureSize(low, 0));
		vec3 b = bright(UV) * 0.5;
		for (int i = 0; i < 6; i++) {
			float a = float(i) * 1.0472;
			b += bright(UV + vec2(cos(a), sin(a)) * px * 2.2);
			b += bright(UV + vec2(cos(a + 0.52), sin(a + 0.52)) * px * 5.5) * 0.6;
		}
		// fusione "schermo": schiarisce senza bruciare le zone già chiare
		c = 1.0 - (1.0 - c) * (1.0 - clamp(b / 10.1 * bloom, 0.0, 1.0));
	}
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, 1.1);
	c = (c - 0.5) * 1.05 + 0.5;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""

var vp1: SubViewport
var vp2: SubViewport
var vp3d: SubViewport
var pass2: TextureRect
var screen_rect: TextureRect
var bloom_k := 1.0
var current: Node
var screen := ""
var fade: ColorRect
var cb_rect: ColorRect
var busy := false
var _shot_path := ""
var _shot_frames := 0
var _run_frames := 0
var _flow: RefCounted


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--test" in args:
		var Tests = load("res://tests/Tests.gd")
		var fails: int = Tests.run("--write" in args, "--diag" in args, "--levels" in args)
		get_tree().quit(1 if fails > 0 else 0)
		return
	if "--make-icon" in args:
		_make_icons()
		get_tree().quit()
		return
	if "--stats" in args:
		_stats()
		get_tree().quit()
		return
	if "--sheet" in args:
		_sheet()
		get_tree().quit()
		return
	if "--check" in args:
		_check_dir("res://src")
		get_tree().quit()
		return
	G.main = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.theme = Art.theme
	_build_pipeline()
	var cb_layer := CanvasLayer.new()
	cb_layer.layer = 90
	add_child(cb_layer)
	cb_rect = ColorRect.new()
	G.full(cb_rect)
	cb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = CB_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	cb_rect.material = mat
	cb_layer.add_child(cb_rect)
	var vl := CanvasLayer.new()
	vl.layer = 5
	add_child(vl)
	var vig := TextureRect.new()
	vig.texture = Art.vignette()
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	G.full(vig)
	vl.add_child(vig)
	var fl := CanvasLayer.new()
	fl.layer = 100
	add_child(fl)
	fade = ColorRect.new()
	G.full(fade)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.color = Color(0.03, 0.02, 0.06, 1.0)
	fl.add_child(fade)
	apply_settings()
	var start := "title"
	var params := {}
	for a in args:
		if a.begins_with("--shot="):
			_shot_path = a.substr(7)
			_shot_frames = 90
		elif a.begins_with("--run="):
			_run_frames = int(a.substr(6))
		elif a.begins_with("--frames="):
			_shot_frames = int(a.substr(9))
		elif a.begins_with("--go="):
			start = a.substr(5)
		elif a.begins_with("--keys="):
			for k in a.substr(7).split(","):
				G.debug_keys[k] = true
		elif a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=")
			params[kv[0]] = int(kv[1]) if kv[1].is_valid_int() else kv[1]
	if start != "title" and Save.run.is_empty():
		Save.new_run(-1, int(params.get("seed", 12345)), str(params.get("mode", "lucido")), bool(params.get("skip", 0)))
		Save.run["max_world"] = 10
		Save.run["max_level"] = G.LEVELS
	if "--flow" in args or "--export-sprites" in args:
		start = "title"
	_swap(start, params)
	create_tween().tween_property(fade, "color:a", 0.0, 0.3)
	if "--flow" in args:
		_flow = load("res://tests/Flow.gd").new()
		_flow.run(self)
	if "--export-sprites" in args:
		_flow = load("res://tests/ExportSprites.gd").new()
		_flow.run(self)


## Il gioco si disegna in vp1 con coordinate di 480x270 (pixel di gioco), ma a
## risoluzione doppia: così gli sprite in alta definizione mostrano i loro dettagli.
## Una passata di levigatura (EPX) porta l'immagine a 4 volte i pixel di gioco,
## arrotondando le scalette; poi si adatta allo schermo con filtro morbido.
## Con "Grafica levigata: no" si mostra vp1 così com'è.
const HI := 2


func _build_pipeline() -> void:
	vp2 = SubViewport.new()
	vp1 = SubViewport.new()
	for v in [vp1, vp2]:
		v.disable_3d = true
		v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		v.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		v.transparent_bg = true
	vp1.snap_2d_transforms_to_pixel = true
	vp1.size_2d_override_stretch = true
	vp3d = SubViewport.new()
	vp3d.own_world_3d = true
	vp3d.msaa_3d = Viewport.MSAA_2X
	vp3d.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(vp3d)
	# annidati, così vp1 si disegna prima della passata che lo usa (niente ritardo)
	add_child(vp2)
	vp2.add_child(vp1)
	var sh := Shader.new()
	sh.code = EPX_SHADER
	pass2 = _pass_rect(vp1, sh)
	vp2.add_child(pass2)
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	screen_rect = TextureRect.new()
	screen_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen_rect.stretch_mode = TextureRect.STRETCH_SCALE
	screen_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fsh := Shader.new()
	fsh.code = FINAL_SHADER
	var fm := ShaderMaterial.new()
	fm.shader = fsh
	fm.set_shader_parameter("low", vp1.get_texture())
	fm.set_shader_parameter("scene", vp3d.get_texture())
	screen_rect.material = fm
	G.full(screen_rect)
	layer.add_child(screen_rect)
	_resize()
	get_tree().root.size_changed.connect(_resize)


func _pass_rect(src: SubViewport, sh: Shader) -> TextureRect:
	var r := TextureRect.new()
	r.texture = src.get_texture()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var m := ShaderMaterial.new()
	m.shader = sh
	r.material = m
	return r


func _resize() -> void:
	var vs: Vector2 = get_tree().root.get_visible_rect().size
	var sz := Vector2i(int(ceil(vs.x)), int(ceil(vs.y)))
	vp1.size = sz * HI
	vp1.size_2d_override = sz
	vp2.size = sz * HI * 2
	vp3d.size = sz * 2
	pass2.size = Vector2(sz * HI * 2)


func _apply_smooth() -> void:
	var smooth: bool = Save.settings["smooth"]
	vp2.render_target_update_mode = SubViewport.UPDATE_ALWAYS if smooth else SubViewport.UPDATE_DISABLED
	screen_rect.texture = vp2.get_texture() if smooth else vp1.get_texture()
	screen_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if smooth else CanvasItem.TEXTURE_FILTER_NEAREST
	set_bloom(bloom_k)


## Il livello 3D (HD-2D) viene mostrato solo mentre si gioca e se l'opzione è attiva.
func set_3d(on: bool) -> void:
	vp3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	(screen_rect.material as ShaderMaterial).set_shader_parameter("use3d", on)


func use_3d() -> bool:
	return Save.settings["hd2d"] and vp3d != null


## Intensità del bagliore: piena nei mondi scuri, quasi nulla dove il cielo è già chiaro.
func set_bloom(k: float) -> void:
	bloom_k = k
	if screen_rect != null:
		(screen_rect.material as ShaderMaterial).set_shader_parameter("bloom", 0.0 if Save.settings["reduce_fx"] else 0.55 * k)


## Tocchi, tasti e controller arrivano alla finestra: si passano al gioco in vp1.
func _input(ev: InputEvent) -> void:
	if vp1 != null:
		vp1.push_input(ev, true)


func apply_settings() -> void:
	var mode: int = int(Save.settings["cb"])
	cb_rect.visible = mode != 0
	(cb_rect.material as ShaderMaterial).set_shader_parameter("mode", mode)
	Engine.time_scale = float(Save.settings["speed"]) if Save.run.get("mode", "") != "incubo" else 1.0
	Snd.apply_volume()
	_apply_smooth()


func goto(name: String, params := {}) -> void:
	if busy:
		return
	busy = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.18)
	tw.tween_callback(func():
		_swap(name, params)
		busy = false)
	tw.tween_property(fade, "color:a", 0.0, 0.22)


func _swap(name: String, params: Dictionary) -> void:
	if current != null:
		current.queue_free()
		current = null
	G.params = params
	if name == "game":
		G.req = {"world": int(params.get("world", 1)), "level": int(params.get("level", 1)), "from_cp": params.get("from_cp", false)}
	apply_settings()
	current = load(SCREENS[name]).new()
	screen = name
	vp1.add_child(current)


func _notification(what: int) -> void:
	# tasto "indietro" di Android: nel gioco mette in pausa (Controls), nei menu torna al titolo
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and current != null and not busy:
		if screen == "title":
			get_tree().quit()
		elif screen != "game":
			goto("title")


func _process(_dt: float) -> void:
	if Engine.get_process_frames() % 300 == 0 and "--fps" in OS.get_cmdline_user_args():
		print("fps: %d" % Engine.get_frames_per_second())
	if _run_frames > 0:
		_run_frames -= 1
		if _run_frames == 0:
			if current != null and current.get("player") != null:
				print("fine corsa: stato=%s x=%d/%d morti=%d frammenti=%d" % [current.state, int(current.player.b.x), current.lv.w * 16, Save.run["deaths"], current.frags])
			get_tree().quit()
	if _shot_path != "":
		_shot_frames -= 1
		if _shot_frames == 0:
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.save_png(_shot_path)
			get_tree().quit()


## Quanti nemici e pericoli per schermata ha ogni mondo (media sui livelli generati di un seed).
func _stats() -> void:
	var LevelGen = load("res://src/gen/LevelGen.gd")
	for w in range(1, 11):
		var en := 0
		var haz := 0
		var screens := 0.0
		var kinds := {}
		var lo := 99.0
		for l in range(1, G.LEVELS):
			var lv = LevelGen.build(4242, w, l, {"skip_tut": true})
			var n := 0
			for e in lv.ents:
				if e["t"] == "enemy":
					n += 1
					kinds[e["kind"]] = kinds.get(e["kind"], 0) + 1
				elif e["t"] == "blade":
					haz += 1
			var sc: float = lv.w / 30.0
			en += n
			screens += sc
			lo = minf(lo, n / sc)
		print("mondo %2d: nemici/schermata %.2f (minimo %.2f)  lame/schermata %.2f  %s" % [w, en / screens, lo, haz / screens, str(kinds)])


## Tavola di tutti gli sprite (ingranditi) in build/sprites.png, per controllarli a occhio.
func _sheet() -> void:
	var names: Array = Art.Sprites.SPR.keys()
	var img := Image.create(40 * 12, 40 * 9, false, Image.FORMAT_RGBA8)
	img.fill(Color("5a6a8a"))
	var n := 0
	for k in names:
		var im: Image = Art.tex(k).get_image()
		img.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((n % 12) * 40 + 4, (n / 12) * 40 + 4))
		n += 1
	n = 12 * 6
	for st in [0, 2, 4]:
		var fr: Dictionary = Art.player_frames(st)
		for a in ["idle", "run0", "run1", "run2", "jump", "fall", "hurt", "glide", "slide"]:
			var im: Image = fr[a].get_image()
			img.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((n % 12) * 40 + 8, (n / 12) * 40 + 2))
			n += 1
		n = (n / 12 + 1) * 12
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png("res://build/sprites.png")


func _check_dir(path: String) -> void:
	for f in DirAccess.get_files_at(path):
		if f.ends_with(".gd"):
			load(path + "/" + f)
	for d in DirAccess.get_directories_at(path):
		_check_dir(path + "/" + d)


## Genera le icone dell'app (Chiara che brilla nel cielo notturno) a partire dagli sprite.
func _make_icons() -> void:
	var size := 432
	var bg := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for y in range(size):
		var c := Color("070b30").lerp(Color("3a2a7a"), float(y) / size)
		for x in range(size):
			bg.set_pixel(x, y, c)
	for i in range(70):
		var p := Vector2i(rng.randi_range(8, size - 16) / 8 * 8, rng.randi_range(8, size - 16) / 8 * 8)
		bg.fill_rect(Rect2i(p, Vector2i(8, 8)), Color(1, 1, 0.85, rng.randf_range(0.35, 1.0)))
	var fg := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var chiara: Image = Art.image_from(Art.Sprites.SPR["chiara"])
	var k := 14
	chiara.resize(chiara.get_width() * k, chiara.get_height() * k, Image.INTERPOLATE_NEAREST)
	fg.blend_rect(chiara, Rect2i(Vector2i.ZERO, chiara.get_size()), Vector2i((size - chiara.get_width()) / 2, (size - chiara.get_height()) / 2))
	bg.save_png("res://icon_bg.png")
	fg.save_png("res://icon_fg.png")
	var full := bg.duplicate()
	full.blend_rect(fg, Rect2i(0, 0, size, size), Vector2i.ZERO)
	full.resize(512, 512, Image.INTERPOLATE_NEAREST)
	full.save_png("res://icon.png")
	full.resize(192, 192, Image.INTERPOLATE_BILINEAR)
	full.save_png("res://icon_192.png")
	print("icone generate")
