extends RefCounted
## Piccole decorazioni appoggiate sul terreno, diverse per ogni mondo (solo estetiche).
## Come per gli sprite, ogni carattere è un colore; alcune lettere prendono i colori
## del mondo: a = accento, t = bordo, g = terreno, d = scuro.

const PAL := {
	"k": "1a1423", "w": "ffffff", "y": "ffd65a", "o": "f08a3c", "n": "5fae5a", "N": "2f7a45",
	"r": "d9534f", "p": "f08fc0", "c": "7fd4ff", "b": "3f6fd6", "s": "9aa0b4", "S": "555a6e",
	"m": "8a5a36", "M": "4a2f1f", "e": "fff3b0", "v": "c9a8ff", "P": "4a2a7a",
}

# stile -> lista di [righe, colore della luce ("" = nessuna)]
const DECOR := {
	"wood": [
		[["kkkkkkkkkk", "kttttttttk", "ktrrrrrrtk", "ktrwwwwrtk", "ktrwrrwrtk", "ktrwwwwrtk", "ktrwrrwrtk", "ktrrrrrrtk", "kttttttttk", "kkkkkkkkkk"], ""],
		[["..kkkk..", ".krrrrk.", "krrwrrbk", "krrrrbbk", "kyyyybbk", "kyyyybbk", ".kyybbk.", "..kkkk.."], ""],
		[[".y.r.c.", ".y.r.c.", ".y.r.c.", "kkkkkkk", "kbbbbbk", "kbwbbbk", "kbbbbbk", "kkkkkkk"], ""],
	],
	"cloud": [
		[["..y..", ".ywy.", "..y..", "..n..", ".nn..", "..n.."], ""],
		[["..p..", ".pwp.", "..p..", "..n..", "..nn.", "..n.."], ""],
		[["n...n.n", ".n.n.n.", ".nnnnn."], ""],
	],
	"books": [
		[["..y..", ".yoy.", ".yey.", "..k..", ".eee.", ".eee.", ".eee.", ".eee.", ".eee.", "kmmmk", ".mmm."], "ffb060"],
		[[".kkkkkkkkk..", ".krrrrrrrk..", ".kkkkkkkkkk.", "kbbbbbbbbbbk", "kbbeebbbbbbk", "kkkkkkkkkkkk", ".knnnnnnnnk.", ".kkkkkkkkkk."], ""],
		[["......w.", ".....ww.", "....ww..", "...ww...", "...w....", "..kwk...", ".kkkkk..", "kbbbbbk.", "kbbwbbk.", "kbbbbbk.", ".kkkkk.."], ""],
	],
	"stars": [
		[[".c...c.", ".c.c.c.", ".ccc.c.", "..c.cc.", "..ccc..", "...c...", "...c..."], "7fd4ff"],
		[["...y...", "..yyy..", "yyyyyyy", ".yyeyy.", ".yy.yy.", "y.....y"], ""],
		[["..c..", ".c...", "..c..", "...b.", "..c..", ".c...", "..b..", "..c..", "..b.."], ""],
	],
	"brick": [
		[[".kkkkkkk.", "kyyyyyyyk", "keeeeeeek", "kyyyyyyyk", ".kkkkkkk.", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "...kSk...", "..kSSSk..", ".kkkkkkk."], "ffd166"],
		[[".kkkkkk.", "kssssssk", ".kkkkkk.", ".kSsSsk.", ".kSsSsk.", ".kSsSsk.", ".kSsSsk.", ".kSsSsk.", ".kkkkkk."], ""],
		[["..krk..", ".krrrk.", ".kkkkk.", "kkrrrkk", "krrwrrk", "kkrrrkk", ".krrrk.", ".krrrk.", "kkkkkkk"], ""],
	],
	"brass": [
		[["..k.k.k..", ".kyyyyyk.", "kyykkkyyk", ".yk...ky.", "kyk...kyk"], ""],
		[[".krrrrk.", "krkkkkrk", ".krrrrk.", "...kk...", "..kssk..", "..kssk..", ".kssssk.", "kssssssk", "kssssssk", "kkkkkkkk"], ""],
		[["r.......", "kr......", ".kk.....", "..kk....", "..kssk..", ".kssssk.", "kkkkkkkk"], ""],
	],
	"wafer": [
		[["..krrk.", ".krwwrk", "krwkkwk", "krk.krk", "kwk.kkk", "kwk....", "krk....", "krk....", "kwk....", "kwk....", "krk....", "krk....", "kkk...."], ""],
		[["....nn..", "...n....", "..n.n...", ".n...n..", "krk.krk.", "kwrkkwrk", "krrkkrrk", ".kk..kk."], ""],
		[["..kkkk..", ".kaaaak.", "kaawaaak", "kaaaaaak", "kaaaaaak", "kaaaaaak", "kkkkkkkk"], ""],
	],
	"glass": [
		[["....k.....", "...kck....", "...kwck...", "..kkwck.k.", ".kckwckkck", ".kwkcckwck", "kcwkcckwck", "kcwkcckcck", "kcckcckcck", "kkkkkkkkkk"], "a8c8ff"],
		[["..k..", ".kwk.", ".kck.", "kcvck", "kcvck", "kkkkk"], "c08cff"],
	],
	"rock": [
		[["N..n..N", ".N.n.n.", ".NnNnN."], ""],
		[["..kkkk..", ".ksssSk.", "kswssSSk", "ksssSSSk", "kkkkkkkk"], ""],
		[["m...m...m", ".m..m..m.", "..m.mm...", "m..mm..m.", ".m.m..m..", "..mmmm...", "...mm....", "...mm...."], ""],
	],
	"void": [
		[["....k....", "...kvk...", "...kPk...", "k..kPk..k", "vk.kPk.kv", "kPkkPkkPk", ".kPPPPPk.", "..kkkkk.."], ""],
		[[".kkkkk.", "kwwwwwk", "kwarawk", "kwwwwwk", ".kkkkk.", "...P...", "..PP...", "...P..."], "ff3b6b"],
	],
}


static func build(world: int) -> Array:
	var pal := {}
	for k in PAL:
		pal[k] = Color(PAL[k])
	pal["a"] = G.pal(world, "accent")
	pal["t"] = G.pal(world, "top")
	pal["g"] = G.pal(world, "ground")
	pal["d"] = G.pal(world, "dark")
	var out: Array = []
	for d in DECOR[G.WORLDS[world - 1]["style"]]:
		var rows: Array = d[0]
		var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
		for y in range(rows.size()):
			var row: String = rows[y]
			for x in range(mini(row.length(), img.get_width())):
				if pal.has(row[x]):
					img.set_pixel(x, y, pal[row[x]])
		out.append([Art.ArtShade.tex3d(img, false, 0.4), d[1]])
	return out
