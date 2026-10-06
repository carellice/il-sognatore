extends Node3D
## Versione HD-2D di un livello: il terreno diventa una fila di blocchi 3D veri, con
## luce, ombre, nebbia di profondità e sfondi su piani lontani. La logica del gioco
## resta in 2D: la faccia anteriore dei blocchi sta esattamente sul piano di gioco,
## e la telecamera 3D (dritta, in prospettiva) segue la telecamera 2D, così sprite
## e blocchi combaciano al pixel.
##
## Unità: 1 = una casella (16 px). Asse y verso l'alto: la casella (tx, ty) occupa
## x in [tx, tx+1], y in [-ty-1, -ty], z in [-DEPTH, 0].

const DEPTH := 1.6
const SEC := 16          # colonne per pezzo di mesh (si ricostruisce solo il pezzo cambiato)
const DIST := 20.0       # distanza della telecamera dal piano di gioco
const FAR_Z := -34.0
const MID_Z := -12.0

var game
var lv
var world := 1
var cam: Camera3D
var mat: StandardMaterial3D
var tex_size := Vector2.ONE
var sections := {}
var lamps: Array = []


func setup(g) -> void:
	game = g
	lv = g.lv
	world = g.world
	var src: TileSetAtlasSource = Art.tileset(world).get_source(0)
	tex_size = Vector2(src.texture.get_size())
	mat = StandardMaterial3D.new()
	mat.albedo_texture = src.texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.roughness = 0.9
	mat.metallic_specular = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	cam = Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 1.0
	cam.far = 200.0
	add_child(cam)
	cam.make_current()
	_environment()
	_light()
	_backdrop()
	for s in range(int(ceil(lv.w / float(SEC)))):
		_build_section(s)


## Allinea la telecamera 3D a quella 2D (centro della vista in pixel di gioco).
func sync(center: Vector2, view: Vector2) -> void:
	cam.fov = rad_to_deg(2.0 * atan(view.y / G.TILE * 0.5 / DIST))
	cam.position = Vector3(center.x / G.TILE, -center.y / G.TILE, DIST)


# ------------------------------------------------------------------ ambiente

func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = G.pal(world, "sky2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = G.pal(world, "sky1").lerp(Color.WHITE, 0.9)
	env.ambient_light_energy = 0.3
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = G.pal(world, "sky2").lerp(G.pal(world, "sky1"), 0.4)
	env.fog_depth_begin = DIST + 1.0
	env.fog_depth_end = DIST + 40.0
	env.fog_density = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _light() -> void:
	var sun := DirectionalLight3D.new()
	# luce da sinistra, dall'alto e da davanti: le ombre cadono a destra e indietro.
	# Tarata perché la faccia anteriore resti del colore originale (ambiente 0.45 +
	# sole 1.0 x 0.55), la terrazza un po' più chiara e i fianchi in ombra.
	var toward := Vector3(-0.45, 0.7, 0.55).normalized()
	add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, -toward, Vector3.UP)
	var warm := Color(1.0, 0.97, 0.93)
	if world in [4, 8, 10]:
		warm = Color(0.8, 0.85, 1.0)
	sun.light_color = warm
	sun.light_energy = 0.68
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 60.0


## Lucina 3D (lampade, checkpoint, portale): illumina i blocchi vicini.
func add_lamp(px_pos: Vector2, col: Color, range_tiles := 5.0, energy := 1.2) -> OmniLight3D:
	if lamps.size() >= 14:
		return null
	var l := OmniLight3D.new()
	l.position = Vector3(px_pos.x / G.TILE, -px_pos.y / G.TILE, 1.4)
	l.light_color = col
	l.omni_range = range_tiles
	l.light_energy = energy
	l.omni_attenuation = 1.4
	add_child(l)
	lamps.append(l)
	return l


## Sfondi del mondo su due piani lontani: la prospettiva fa da parallasse.
func _backdrop() -> void:
	var layers: Array = Art.bg(world)
	var view_h: float = game.view_h / G.TILE
	var cy0: float = -(lv.h * G.TILE - game.view_h * 0.5) / G.TILE
	# cielo: un quadro attaccato alla telecamera, sempre a tutto schermo
	var sky := MeshInstance3D.new()
	var q := QuadMesh.new()
	var sd := 150.0
	var sh := 2.0 * sd * tan(deg_to_rad(40.0)) * 1.3
	q.size = Vector2(sh * 3.0, sh)
	sky.mesh = q
	sky.material_override = _flat_mat(layers[0], false)
	sky.position = Vector3(0, 0, -sd)
	sky.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cam.add_child(sky)
	for i in range(2):
		var tex: Texture2D = layers[i + 1]
		var z: float = FAR_Z if i == 0 else MID_Z
		var k := (DIST - z) / DIST
		var tw := tex.get_width() / float(G.TILE) * k
		var th := tex.get_height() / float(G.TILE) * k
		var width: float = (lv.w + 60.0) * k
		var m := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(width, th)
		m.mesh = qm
		var fm := _flat_mat(tex, true)
		fm.uv1_scale = Vector3(width / tw, 1, 1)
		m.material_override = fm
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# il bordo inferiore coincide con il fondo dello schermo, come nella versione 2D
		var bottom: float = cy0 - view_h * 0.5 * k
		m.position = Vector3(lv.w * 0.5, bottom + th * 0.5, z)
		add_child(m)


func _flat_mat(tex: Texture2D, alpha: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.texture_repeat = true
	m.disable_fog = true
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


# ------------------------------------------------------------------ blocchi

func _wall(tx: int, ty: int) -> bool:
	return game._is_wall(tx, ty) and tx >= 0 and tx < lv.w and ty < lv.h


## Dopo un cambio nel terreno (muro finto distrutto) si rifanno i pezzi toccati.
func rebuild_cells(cells: Array) -> void:
	var todo := {}
	for c in cells:
		for dx in [-1, 0, 1]:
			todo[clampi((c.x + dx) / SEC, 0, int(ceil(lv.w / float(SEC))) - 1)] = true
	for s in todo:
		_build_section(s)


func _uv_rect(at: Vector2i) -> Rect2:
	var tp := tex_size.x / 16.0
	var inset := 0.04
	return Rect2((Vector2(at) * tp + Vector2(inset, inset)) / tex_size, Vector2(tp - inset * 2, tp - inset * 2) / tex_size)


func _build_section(s: int) -> void:
	if sections.has(s):
		sections[s].queue_free()
		sections.erase(s)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 0
	for tx in range(s * SEC, mini(lv.w, (s + 1) * SEC)):
		for ty in range(lv.h):
			if not _wall(tx, ty):
				continue
			n += 1
			var x0 := float(tx)
			var x1 := x0 + 1.0
			var y1 := -float(ty)
			var y0 := y1 - 1.0
			var open_up := ty > 0 and not _wall(tx, ty - 1)
			var mask := 0
			if not game._is_wall(tx, ty - 1):
				mask |= 1
			if not game._is_wall(tx + 1, ty):
				mask |= 2
			if not game._is_wall(tx, ty + 1):
				mask |= 4
			if not game._is_wall(tx - 1, ty):
				mask |= 8
			var t: int = lv.tile(tx, ty)
			var front_at: Vector2i = Art.at_fake(mask & 1 != 0, tx, ty) if t == G.T_FAKE else Art.at_solid(mask, tx, ty)
			var plain := _uv_rect(Art.at_solid(0, tx, ty))
			# faccia anteriore (sul piano di gioco)
			var shade := [_dark(tx, ty), _dark(tx + 1, ty), _dark(tx + 1, ty + 1), _dark(tx, ty + 1)]
			_quad(st, Vector3(x0, y1, 0), Vector3(x1, y1, 0), Vector3(x1, y0, 0), Vector3(x0, y0, 0), Vector3(0, 0, 1), _uv_rect(front_at), shade)
			# sopra: la terrazza vista dalla telecamera quando il blocco è sotto l'orizzonte
			if open_up or ty == 0:
				var top := _uv_rect(Vector2i(Art.variant(tx, ty), Art.ArtTiles.ROW_TOP))
				_quad(st, Vector3(x0, y1, -DEPTH), Vector3(x1, y1, -DEPTH), Vector3(x1, y1, 0), Vector3(x0, y1, 0), Vector3(0, 1, 0), top)
			if ty < lv.h - 1 and not _wall(tx, ty + 1):
				_quad(st, Vector3(x0, y0, 0), Vector3(x1, y0, 0), Vector3(x1, y0, -DEPTH), Vector3(x0, y0, -DEPTH), Vector3(0, -1, 0), plain)
			if not _wall(tx - 1, ty):
				_quad(st, Vector3(x0, y1, -DEPTH), Vector3(x0, y1, 0), Vector3(x0, y0, 0), Vector3(x0, y0, -DEPTH), Vector3(-1, 0, 0), plain)
			if not _wall(tx + 1, ty):
				_quad(st, Vector3(x1, y1, 0), Vector3(x1, y1, -DEPTH), Vector3(x1, y0, -DEPTH), Vector3(x1, y0, 0), Vector3(1, 0, 0), plain)
	if n == 0:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)
	sections[s] = mi


## Luminosità di un angolo della faccia anteriore: più scura lontano dalla superficie
## (la stessa ombra interna della versione 2D), media delle quattro caselle attorno.
func _dark(cx: int, cy: int) -> float:
	var sum := 0.0
	for yy in [cy - 1, cy]:
		for xx in [cx - 1, cx]:
			var dd := 0
			if xx >= 0 and xx < lv.w and yy >= 0 and yy < lv.h and game.shade_dist.size() > 0:
				dd = game.shade_dist[yy * lv.w + xx]
			sum += clampf((dd - 1.0) / 3.0, 0.0, 1.0)
	# nelle nuvole l'interno resta chiaro (una nuvola non ha un cuore di roccia)
	return 1.0 - (0.22 if world == 2 else 0.62) * sum / 4.0


## Quadrilatero a-b-c-d (in senso orario visto dal davanti), con la regione dell'atlante.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, nrm: Vector3, uv: Rect2, shade := [1.0, 1.0, 1.0, 1.0]) -> void:
	var u0 := uv.position
	var u1 := uv.end
	var pts := [a, b, c, a, c, d]
	var uvs := [u0, Vector2(u1.x, u0.y), u1, u0, u1, Vector2(u0.x, u1.y)]
	var ks := [shade[0], shade[1], shade[2], shade[0], shade[2], shade[3]]
	for i in range(6):
		var k: float = ks[i]
		st.set_color(Color(k, k, k))
		st.set_normal(nrm)
		st.set_uv(uvs[i])
		st.add_vertex(pts[i])
