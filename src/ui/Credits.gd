extends Control
## Titoli di coda a scorrimento.

const UI = preload("res://src/ui/UI.gd")

var lab: Label
var y := 0.0


func _ready() -> void:
	G.full(self)
	var bg = preload("res://src/game/Background.gd").new()
	bg.setup(4)
	add_child(bg)
	Snd.music("ending")
	lab = UI.label(T.t("credits_text"))
	G.top_wide(lab, 0, 200)
	add_child(lab)
	y = 280.0
	var b := UI.button(T.t("skip"), _done, 50)
	G.pin(b, 1.0, 1.0, -78, -34, 68, 26)
	add_child(b)
	b.grab_focus.call_deferred()


func _process(dt: float) -> void:
	y -= dt * 22.0
	lab.offset_top = round(y)
	lab.offset_bottom = round(y) + 200.0
	if y < -lab.get_minimum_size().y - 10.0:
		_done()


func _done() -> void:
	set_process(false)
	G.goto(str(G.params.get("then", "title")))
