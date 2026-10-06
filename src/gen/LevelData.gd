extends RefCounted
## Un livello in memoria: griglia di tile + entità. Lo producono il generatore
## (livelli 1-9) e i livelli fatti a mano (tutorial, boss).

var w := 0
var h := G.ROWS
var cells := PackedByteArray()
var ents: Array = []  # {"t": tipo, "x": col, "y": riga, ...}
var world := 1
var level := 1
var boss := false
var tutorial := false
var hints: Array = []  # chiavi dei suggerimenti dell'eco, indicizzate dai marcatori 1..9
var spans: Array = []  # [col_inizio, col_fine, id_blocco]
var start := Vector2i(2, 0)
var exit_x := 0
var platforms: Array = []  # piattaforme mobili (solo a runtime)
var broken: Array = []  # casse rotte (solo a runtime), per ridisegnare la mappa


func init(width: int, height: int) -> void:
	w = width
	h = height
	cells = PackedByteArray()
	cells.resize(w * h)


func tile(tx: int, ty: int) -> int:
	if tx < 0 or tx >= w:
		return G.T_SOLID
	if ty < 0 or ty >= h:
		return G.T_EMPTY
	return cells[ty * w + tx]


func solid(tx: int, ty: int) -> bool:
	if tx < 0 or tx >= w:
		return true
	if ty < 0 or ty >= h:
		return false
	var t := cells[ty * w + tx]
	return t == G.T_SOLID or t == G.T_CRATE or t == G.T_BOUNCY or t == G.T_DOOR


func set_tile(tx: int, ty: int, v: int) -> void:
	if tx >= 0 and tx < w and ty >= 0 and ty < h:
		cells[ty * w + tx] = v


func break_crate(tx: int, ty: int) -> void:
	set_tile(tx, ty, G.T_EMPTY)
	broken.append(Vector2i(tx, ty))


## Riga del primo tile solido della colonna partendo dall'alto (h se non c'è).
func ground_row(tx: int) -> int:
	for ty in range(h):
		if solid(tx, ty):
			return ty
	return h
