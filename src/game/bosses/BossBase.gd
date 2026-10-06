extends Node2D
## Base comune dei boss: 3 fasi, 3 colpi per fase, ogni fase più veloce.

const PHASES := 3
const HITS := 3

var game
var home := Vector2.ZERO  # punto del marcatore Q (a terra)
var pos := Vector2.ZERO  # centro del boss
var phase := 0
var hits := 0
var dead := false
var active := false
var invuln := 0.0
var t := 0.0
var state := ""
var st := 0.0
var arena := Vector2.ZERO


func setup(g, feet: Vector2) -> void:
	game = g
	home = feet
	arena = Vector2(g.lv.w * G.TILE, g.lv.h * G.TILE)
	z_index = 4
	_reset()
	position = pos.round()


func hits_left() -> int:
	return (PHASES - phase) * HITS - hits


## Moltiplicatore di velocità della fase corrente.
func rate() -> float:
	return 1.0 + phase * 0.3


func tick(dt: float) -> void:
	if dead:
		return
	if not active:
		active = true
		game.echo.say(T.t("say_boss"), 3.0)
	t += dt
	invuln = maxf(0.0, invuln - dt)
	st -= dt
	_tick(dt)
	position = pos.round()
	modulate = Color(3, 3, 3) if invuln > 0.0 and int(invuln * 16.0) % 2 == 0 else Color.WHITE
	queue_redraw()


func hit() -> bool:
	if invuln > 0.0 or dead:
		return false
	hits += 1
	invuln = 1.2
	Snd.play("boss_hit")
	game.shake(4.0)
	game.buzz(30)
	game.fx.burst(pos, Color.WHITE, 14, 90.0)
	if hits >= HITS:
		hits = 0
		phase += 1
		if phase >= PHASES:
			_die()
			return true
		game.flash(Color(1, 1, 1, 0.4))
		_on_phase()
	_on_hit()
	return true


func _die() -> void:
	dead = true
	visible = false
	game.clear_shots()
	Snd.play("boss_die")
	game.shake(6.0)
	for i in range(6):
		game.fx.burst(pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)), G.pal(game.world, "accent"), 12, 110.0)
	game.portal_active = true
	game.portal.visible = true
	game.fx.ring(game.portal.position - Vector2(0, 14), Color("fff3b0"))
	var id := "boss_%d" % game.world
	if not (id in Save.gallery["bosses"]):
		Save.gallery["bosses"].append(id)


## Sogno lucido: si riparte dall'inizio della fase. Sonno agitato: dall'inizio del combattimento.
func on_player_respawn(lucido: bool) -> void:
	hits = 0
	if not lucido:
		phase = 0
	invuln = 0.0
	_reset()


## Colpo dall'alto sul punto debole: il giocatore deve arrivarci cadendo.
func stomp(weak: Rect2, min_speed := 30.0) -> bool:
	var p = game.player
	if p.dead or invuln > 0.0 or not p.b.rect().intersects(weak):
		return false
	var falling: bool = p.b.vy * p.b.g > min_speed
	var above: bool = (p.prev_feet - weak.get_center().y) * p.b.g <= 0.0
	if falling and above:
		hit()
		p.bounce_off(true)
		return true
	return false


func touch(r: Rect2) -> void:
	var p = game.player
	if invuln > 0.9 or p.dead:
		return
	if p.b.rect().grow(-1.0).intersects(r):
		p.hurt(1, r.get_center().x)


func _tick(_dt: float) -> void:
	pass


func _reset() -> void:
	pos = home


func _on_phase() -> void:
	pass


func _on_hit() -> void:
	pass
