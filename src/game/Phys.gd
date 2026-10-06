extends RefCounted
## Corpo fisico su griglia di tile. Non dipende da nodi né dal motore fisico di Godot:
## lo usano il protagonista, i nemici e il validatore dei livelli (stessa identica fisica).

var x := 0.0  # centro dell'hitbox
var y := 0.0
var hw := 5.0
var hh := 9.0
var full_h := 18.0
var vx := 0.0
var vy := 0.0
var g := 1  # verso della gravità: 1 giù, -1 su
var facing := 1
var on_ground := false

var coyote := 0.0
var jbuf := 0.0
var jumping := false
var djump_used := false
var has_double := false
var has_glide := false
var auto_high := false

var dash_t := 0.0
var dash_dir := 1
var crouch := false
var bubble_t := 0.0
var flip_ready := true
var slamming := false
var gliding := false
var cd := {}
var lock_t := 0.0
var slow_t := 0.0
var push_x := 0.0
var ride = null
var events: Array = []

var _undo_age := 9.0
var _undo_vy := 0.0
var _undo_double := false


func feet() -> float:
	return y + hh * g


func set_feet(fx: float, fy: float) -> void:
	x = fx
	y = fy - hh * g


func rect() -> Rect2:
	return Rect2(x - hw, y - hh, hw * 2.0, hh * 2.0)


## Annulla un salto appena iniziato (il tocco era l'inizio di uno swipe).
func undo_jump() -> void:
	if _undo_age > 0.16:
		return
	_undo_age = 9.0
	jumping = false
	if _undo_double:
		djump_used = false
		vy = _undo_vy
	else:
		vy = 0.0


func step(inp: Dictionary, dt: float, lv) -> void:
	events.clear()
	coyote = maxf(0.0, coyote - dt)
	jbuf = maxf(0.0, jbuf - dt)
	lock_t = maxf(0.0, lock_t - dt)
	slow_t = maxf(0.0, slow_t - dt)
	_undo_age += dt
	for k in cd:
		cd[k] = maxf(0.0, cd[k] - dt)

	if ride != null:
		if ride.get("dead", false) or g != 1:
			ride = null
		else:
			if ride["dx"] != 0.0:
				move_x(lv, ride["dx"])
			y = ride["y"] - hh

	var mx: float = inp.get("mx", 0.0)
	var jp: bool = inp.get("jp", false)
	var jh: bool = inp.get("jh", false)
	var ab: String = inp.get("ab", "")
	if lock_t > 0.0:
		mx = 0.0
		jp = false
		ab = ""
	if jp:
		jbuf = G.JUMP_BUFFER
	if mx != 0.0 and dash_t <= 0.0 and not slamming:
		facing = 1 if mx > 0.0 else -1

	if ab != "" and cd.get(ab, 0.0) <= 0.0:
		_use_ability(ab, inp, lv)

	# --- orizzontale ---
	if dash_t > 0.0:
		dash_t -= dt
		vx = dash_dir * G.DASH_SPEED
		vy = 0.0
		if dash_t <= 0.0:
			vx = dash_dir * G.RUN_SPEED
	elif slamming:
		vx = 0.0
	else:
		if crouch:
			if not _set_crouch(false, lv) and mx == 0.0:
				mx = float(dash_dir)  # sotto una soglia bassa si continua a scivolare
		var maxs := G.RUN_SPEED
		if bubble_t > 0.0:
			maxs = G.BUBBLE_SPEED
		if slow_t > 0.0:
			maxs *= 0.5
		var target := mx * maxs
		var a := G.DEC_GROUND
		if mx != 0.0 and signf(mx) == signf(vx):
			a = G.ACC_GROUND
		elif mx != 0.0 and vx == 0.0:
			a = G.ACC_GROUND
		if not on_ground:
			a *= G.AIR_CONTROL
		vx = move_toward(vx, target, a * dt)

	# --- verticale ---
	var jumped := false
	gliding = false
	if dash_t > 0.0:
		pass
	elif bubble_t > 0.0:
		bubble_t -= dt
		vy = move_toward(vy, -G.BUBBLE_RISE * g, 900.0 * dt)
		if bubble_t <= 0.0 or (jp and bubble_t < G.BUBBLE_TIME - 0.25):
			pop_bubble()
			jbuf = 0.0
	else:
		if jbuf > 0.0 and (on_ground or coyote > 0.0) and not crouch:
			_undo_age = 0.0
			_undo_double = false
			vy = -G.JUMP_V * g
			jumping = true
			jumped = true
			on_ground = false
			coyote = 0.0
			jbuf = 0.0
			ride = null
			slamming = false
			events.append("jump")
		elif jp and not on_ground and has_double and not djump_used and not crouch and not slamming:
			_undo_age = 0.0
			_undo_double = true
			_undo_vy = vy
			vy = -G.DJUMP_V * g
			djump_used = true
			jumping = true
			jumped = true
			jbuf = 0.0
			events.append("djump")
		if jumping and not jh and not auto_high and vy * g < 0.0:
			vy *= 0.5
			jumping = false
		if vy * g >= 0.0:
			jumping = false
		vy += G.GRAVITY * g * dt
		var maxf := G.MAX_FALL
		if slamming:
			maxf = G.SLAM_SPEED
		elif has_glide and jh and vy * g > 0.0:
			gliding = true
			maxf = G.GLIDE_FALL
			if lv.tile(int(floor(x / G.TILE)), int(floor(y / G.TILE))) == G.T_UPDRAFT:
				vy = move_toward(vy, -G.UPDRAFT_V * g, 1600.0 * dt)
		if vy * g > maxf:
			vy = maxf * g

	# --- movimento e collisioni ---
	var hit := move_x(lv, (vx + push_x) * dt)
	push_x = 0.0
	if hit:
		vx = 0.0
		if dash_t > 0.0:
			dash_t = 0.0
	var was_ground := on_ground
	var land := move_y(lv, vy * dt)
	on_ground = land == 1
	if land == 1:
		var under := _tiles_under(lv)
		if slamming:
			if under.has(G.T_CRATE):
				_break_under(lv)
				events.append("break")
				if not under.has(G.T_SOLID) and not under.has(G.T_BOUNCY):
					on_ground = false
			if on_ground:
				slamming = false
				if under.has(G.T_BOUNCY):
					vy = -G.SLAM_BOUNCE * g
					on_ground = false
					djump_used = false
					events.append("superbounce")
				else:
					vy = 0.0
					events.append("slam_land")
		elif under.has(G.T_BOUNCY) and ride == null:
			vy = -(G.BOUNCE_HELD_V if jh else G.BOUNCE_V) * g
			on_ground = false
			djump_used = false
			flip_ready = true
			jumping = false
			events.append("bounce")
		else:
			if not was_ground:
				events.append("land")
			vy = 0.0
			djump_used = false
			flip_ready = true
	elif land == -1:
		vy = 0.0
		jumping = false
	if was_ground and not on_ground and not jumped and vy * g >= 0.0:
		coyote = G.COYOTE


func _use_ability(ab: String, inp: Dictionary, lv) -> void:
	match ab:
		"scatto":
			if dash_t <= 0.0:
				var ax: float = inp.get("abx", 0.0)
				dash_dir = facing if ax == 0.0 else (1 if ax > 0.0 else -1)
				facing = dash_dir
				dash_t = G.DASH_TIME
				_set_crouch(true, lv)
				vy = 0.0
				bubble_t = 0.0
				slamming = false
				jumping = false
				cd[ab] = G.DASH_CD
				events.append("dash")
		"bolla":
			if bubble_t <= 0.0 and dash_t <= 0.0:
				bubble_t = G.BUBBLE_TIME
				slamming = false
				jumping = false
				ride = null
				on_ground = false
				events.append("bubble")
		"gravita":
			if flip_ready and dash_t <= 0.0:
				g = -g
				flip_ready = false
				on_ground = false
				ride = null
				coyote = 0.0
				jumping = false
				bubble_t = 0.0
				cd[ab] = G.FLIP_CD
				events.append("flip")
		"schianto":
			if not on_ground and dash_t <= 0.0:
				if bubble_t > 0.0:
					pop_bubble()
				slamming = true
				vx = 0.0
				vy = G.SLAM_SPEED * g
				jumping = false
				cd[ab] = G.SLAM_CD
				events.append("slam")
		"tempo":
			cd[ab] = G.SLOW_TIME + G.SLOW_CD
			events.append("tempo")
		"riflesso":
			cd[ab] = G.CLONE_TIME + G.CLONE_CD
			events.append("riflesso")


func pop_bubble() -> void:
	bubble_t = 0.0
	cd["bolla"] = G.BUBBLE_CD
	events.append("pop")


## Passa da in piedi ad accovacciato (e viceversa) tenendo fermi i piedi.
func _set_crouch(on: bool, lv) -> bool:
	if on == crouch:
		return true
	var f := feet()
	var new_hh := (G.CROUCH_H if on else full_h) * 0.5
	if not on:
		var ny := f - new_hh * g
		var top := int(floor((ny - new_hh) / G.TILE))
		var bot := int(floor((ny + new_hh - 0.01) / G.TILE))
		var l := int(floor((x - hw) / G.TILE))
		var r := int(floor((x + hw - 0.01) / G.TILE))
		for ty in range(top, bot + 1):
			for tx in range(l, r + 1):
				if lv.solid(tx, ty):
					return false
	hh = new_hh
	y = f - hh * g
	crouch = on
	return true


func move_x(lv, dx: float) -> bool:
	if dx == 0.0:
		return false
	x += dx
	var top := int(floor((y - hh) / G.TILE))
	var bot := int(floor((y + hh - 0.01) / G.TILE))
	if dx > 0.0:
		var tx := int(floor((x + hw - 0.01) / G.TILE))
		for ty in range(top, bot + 1):
			if lv.solid(tx, ty):
				x = tx * G.TILE - hw
				return true
	else:
		var tx := int(floor((x - hw) / G.TILE))
		for ty in range(top, bot + 1):
			if lv.solid(tx, ty):
				x = (tx + 1) * G.TILE + hw
				return true
	return false


## Ritorna 1 se atterra (nel verso della gravità), -1 se sbatte la testa, 0 altrimenti.
func move_y(lv, dy: float) -> int:
	ride = null
	if dy == 0.0:
		return 0
	var prev_bot := y + hh
	var prev_top := y - hh
	y += dy
	var l := int(floor((x - hw) / G.TILE))
	var r := int(floor((x + hw - 0.01) / G.TILE))
	if dy > 0.0:
		var ty := int(floor((y + hh - 0.01) / G.TILE))
		for tx in range(l, r + 1):
			var t: int = lv.tile(tx, ty)
			if _is_solid(t) or (t == G.T_ONEWAY and g == 1 and prev_bot <= ty * G.TILE + 0.01):
				y = ty * G.TILE - hh
				return 1 if g == 1 else -1
		if g == 1:
			for p in lv.platforms:
				if x + hw > p["x"] and x - hw < p["x"] + p["w"] and prev_bot <= p["y"] - p["dy"] + 0.6 and y + hh >= p["y"]:
					y = p["y"] - hh
					ride = p
					return 1
	else:
		var ty := int(floor((y - hh) / G.TILE))
		for tx in range(l, r + 1):
			var t: int = lv.tile(tx, ty)
			if _is_solid(t) or (t == G.T_ONEWAY and g == -1 and prev_top >= (ty + 1) * G.TILE - 0.01):
				y = (ty + 1) * G.TILE + hh
				return 1 if g == -1 else -1
	return 0


static func _is_solid(t: int) -> bool:
	return t == G.T_SOLID or t == G.T_CRATE or t == G.T_BOUNCY or t == G.T_DOOR


func _under_row() -> int:
	if g == 1:
		return int(floor((y + hh + 1.0) / G.TILE))
	return int(floor((y - hh - 1.0) / G.TILE))


func _tiles_under(lv) -> Dictionary:
	var out := {}
	var ty := _under_row()
	for tx in range(int(floor((x - hw) / G.TILE)), int(floor((x + hw - 0.01) / G.TILE)) + 1):
		var t: int = lv.tile(tx, ty)
		if t == G.T_ONEWAY or t == G.T_DOOR:
			t = G.T_SOLID
		if t == G.T_SOLID or t == G.T_CRATE or t == G.T_BOUNCY:
			out[t] = true
	return out


func _break_under(lv) -> void:
	var ty := _under_row()
	for tx in range(int(floor((x - hw) / G.TILE)), int(floor((x + hw - 0.01) / G.TILE)) + 1):
		if lv.tile(tx, ty) == G.T_CRATE:
			lv.break_crate(tx, ty)
