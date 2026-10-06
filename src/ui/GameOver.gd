extends Control
## Fine della partita in modalità Incubo: restano solo le statistiche.

const UI = preload("res://src/ui/UI.gd")


func _ready() -> void:
	G.full(self)
	var bg = preload("res://src/game/Background.gd").new()
	bg.setup(10)
	add_child(bg)
	Snd.music("")
	var run: Dictionary = Save.run
	UI.panel(self, [
		UI.label(T.t("over_title"), true, Color("ff3b6b")),
		UI.label(T.t("over_text")),
		UI.label("%s %d-%d" % [T.t("level"), run.get("world", 1), run.get("level", 1)]),
		UI.label("%s: %d   %s: %s" % [T.t("fragments"), run.get("fragments", 0), T.t("time"), G.fmt_time(run.get("time", 0.0))]),
		UI.button(T.t("continue"), func(): G.goto("title")),
	])
