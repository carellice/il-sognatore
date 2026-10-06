extends Node
## Audio sintetizzato dal codice, in stile chiptune: effetti sonori (onde quadre,
## triangolari e rumore) e un tema musicale per mondo composto da un piccolo
## sequencer procedurale. Nessun file audio esterno: vedi ASSETS.md.

const RATE := 16000
const PAD := 32

# effetto -> lista di segmenti [onda, freq iniziale, freq finale, durata, volume]
const SFX := {
	"jump": [["sq", 330, 580, 0.11, 0.30]],
	"djump": [["sq", 460, 820, 0.11, 0.30]],
	"land": [["noise", 300, 120, 0.05, 0.16]],
	"frag": [["sq", 990, 990, 0.045, 0.22], ["sq", 1480, 1480, 0.08, 0.22]],
	"hurt": [["saw", 320, 90, 0.26, 0.38]],
	"die": [["sq", 440, 55, 0.6, 0.38]],
	"stomp": [["sq", 240, 90, 0.09, 0.34], ["noise", 500, 200, 0.05, 0.2]],
	"checkpoint": [["tri", 523, 523, 0.08, 0.4], ["tri", 659, 659, 0.08, 0.4], ["tri", 784, 784, 0.16, 0.4]],
	"dash": [["noise", 2400, 600, 0.13, 0.22]],
	"bubble": [["tri", 280, 620, 0.2, 0.4]],
	"pop": [["noise", 1800, 600, 0.05, 0.28], ["sq", 900, 420, 0.05, 0.2]],
	"flip": [["tri", 520, 250, 0.09, 0.4], ["tri", 250, 520, 0.09, 0.4]],
	"slam": [["noise", 700, 80, 0.22, 0.45]],
	"bounce": [["tri", 200, 520, 0.14, 0.42]],
	"break": [["noise", 1400, 200, 0.16, 0.36]],
	"slow": [["tri", 640, 190, 0.4, 0.4]],
	"clone": [["sq", 660, 660, 0.06, 0.24], ["sq", 990, 990, 0.1, 0.24]],
	"select": [["sq", 700, 700, 0.035, 0.2]],
	"switch": [["sq", 500, 500, 0.05, 0.25], ["sq", 720, 720, 0.06, 0.25]],
	"secret": [["tri", 659, 659, 0.08, 0.42], ["tri", 784, 784, 0.08, 0.42], ["tri", 988, 988, 0.08, 0.42], ["tri", 1319, 1319, 0.22, 0.42]],
	"life": [["sq", 523, 523, 0.07, 0.26], ["sq", 784, 784, 0.07, 0.26], ["sq", 1047, 1047, 0.16, 0.26]],
	"portal": [["tri", 400, 1250, 0.5, 0.42]],
	"shoot": [["sq", 520, 240, 0.1, 0.22]],
	"warn": [["sq", 880, 880, 0.06, 0.26], ["sq", 0, 0, 0.04, 0.0], ["sq", 880, 880, 0.06, 0.26]],
	"sticky": [["tri", 190, 130, 0.16, 0.4]],
	"wake": [["tri", 520, 140, 0.9, 0.42]],
	"boss_hit": [["noise", 900, 200, 0.12, 0.35], ["sq", 330, 110, 0.2, 0.35]],
	"boss_die": [["noise", 1600, 80, 0.9, 0.45]],
}

# brano -> parametri del sequencer
const TRACKS := {
	"menu": {"root": 60, "minor": false, "bpm": 92, "drums": 0, "seed": 11},
	"story": {"root": 57, "minor": true, "bpm": 76, "drums": 0, "seed": 23},
	"boss": {"root": 52, "minor": true, "bpm": 152, "drums": 2, "seed": 37},
	"ending": {"root": 60, "minor": false, "bpm": 84, "drums": 0, "seed": 41},
}

var _sfx := {}
var _pool: Array = []
var _pool_i := 0
var _music: AudioStreamPlayer
var _tracks := {}
var _want := ""
var _mutex := Mutex.new()
var _pending := {}
var muted := false
var _tasks: Array = []
var _recorded := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	muted = DisplayServer.get_name() == "headless"
	for i in range(8):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	apply_volume()


func _exit_tree() -> void:
	# non uscire mentre un thread sta ancora componendo un brano
	for id in _tasks:
		WorkerThreadPool.wait_for_task_completion(id)
	_tasks.clear()
	_music.stop()
	_music.stream = null
	_tracks.clear()


func apply_volume() -> void:
	if _music == null:
		return
	var mv: float = Save.settings["music"]
	# i brani registrati sono già a volume pieno, quelli sintetizzati sono più forti
	var gain := 0.8 if _recorded.has(_want) else 0.55
	_music.volume_db = linear_to_db(maxf(0.0001, mv * gain))
	_music.stream_paused = mv <= 0.0


func play(name: String) -> void:
	if muted or not SFX.has(name):
		return
	var v: float = Save.settings["sfx"]
	if v <= 0.0:
		return
	if not _sfx.has(name):
		_sfx[name] = _render_sfx(SFX[name])
	var p: AudioStreamPlayer = _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = _sfx[name]
	p.volume_db = linear_to_db(v)
	p.play()


func music(name: String) -> void:
	if name == _want:
		return
	_want = name
	if muted:
		return
	if name == "":
		_music.stop()
		return
	if not _tracks.has(name):
		# brano registrato in audio/<nome>.mp3, se c'è; altrimenti lo si compone
		var path := "res://audio/%s.mp3" % name
		if ResourceLoader.exists(path):
			var st: AudioStreamMP3 = load(path)
			st.loop = true
			_tracks[name] = st
			_recorded[name] = true
			if "--verbose-audio" in OS.get_cmdline_user_args():
				print("brano %s caricato da file (%.0f s)" % [name, st.get_length()])
	if _tracks.has(name):
		_start(name)
		return
	_music.stop()
	# la composizione richiede qualche istante: si fa in un thread
	_tasks.append(WorkerThreadPool.add_task(_compose_task.bind(name)))


func _compose_task(name: String) -> void:
	var t0 := Time.get_ticks_msec()
	var stream := _compose(name)
	if OS.is_debug_build() and "--verbose-audio" in OS.get_cmdline_user_args():
		print("brano %s composto in %d ms" % [name, Time.get_ticks_msec() - t0])
	_mutex.lock()
	_pending[name] = stream
	_mutex.unlock()


func _process(_dt: float) -> void:
	if _pending.is_empty():
		return
	_mutex.lock()
	for k in _pending:
		_tracks[k] = _pending[k]
	_pending.clear()
	_mutex.unlock()
	if _tracks.has(_want) and (not _music.playing or _music.stream != _tracks[_want]):
		_start(_want)


func _start(name: String) -> void:
	_music.stream = _tracks[name]
	apply_volume()
	_music.play()


func _wav(data: PackedByteArray, loop: bool) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	var frames := data.size() / 2
	# coda di sicurezza: il mixer interpola leggendo qualche campione oltre la fine
	# (su Android, senza, il gioco andava in crash al giro del loop)
	if loop:
		data.append_array(data.slice(0, PAD * 2))
	else:
		data.resize(data.size() + PAD * 2)
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = frames
	return w


func _render_sfx(segs: Array) -> AudioStreamWAV:
	var total := 0
	for s in segs:
		total += int(s[3] * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var pos := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for s in segs:
		var n := int(s[3] * RATE)
		_voice(buf, pos, n, s[0], float(s[1]), float(s[2]), float(s[4]), rng, 1.0)
		pos += n
	return _wav(_to_bytes(buf), false)


## Scrive una nota nel buffer (somma), con inviluppo a decadimento.
func _voice(buf: PackedFloat32Array, start: int, n: int, wave: String, f0: float, f1: float, vol: float, rng: RandomNumberGenerator, decay: float) -> void:
	if vol <= 0.0 or n <= 0:
		return
	var phase := 0.0
	var noise_v := 0.0
	var noise_c := 0.0
	var end := mini(buf.size(), start + n)
	var inv := 1.0 / float(n)
	for i in range(start, end):
		var k := (i - start) * inv
		var f := f0 + (f1 - f0) * k
		phase += f / RATE
		if phase >= 1.0:
			phase -= 1.0
		var s := 0.0
		match wave:
			"sq":
				s = 1.0 if phase < 0.5 else -1.0
			"sq25":
				s = 1.0 if phase < 0.25 else -1.0
			"tri":
				s = 4.0 * absf(phase - 0.5) - 1.0
			"saw":
				s = 2.0 * phase - 1.0
			"noise":
				noise_c += f / RATE * 4.0
				if noise_c >= 1.0:
					noise_c -= 1.0
					noise_v = rng.randf_range(-1.0, 1.0)
				s = noise_v
		var env := 1.0 - k * decay
		if k < 0.02:
			env *= k * 50.0
		buf[i] += s * vol * env


func _to_bytes(buf: PackedFloat32Array) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(buf.size() * 2)
	for i in range(buf.size()):
		out.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	return out


func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## Compone un brano di 8 battute in loop: basso, arpeggio, melodia e batteria.
func _compose(name: String) -> AudioStreamWAV:
	var p: Dictionary
	if TRACKS.has(name):
		p = TRACKS[name]
	else:
		var w := clampi(int(name.substr(1)), 1, 10)
		p = G.WORLDS[w - 1]["music"].duplicate()
		p["seed"] = 100 + w * 17
		p["drums"] = 0 if w == 4 else (2 if w in [5, 6, 9, 10] else 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = p["seed"]
	var minor: bool = p["minor"]
	var scale: Array = [0, 2, 3, 5, 7, 8, 10] if minor else [0, 2, 4, 5, 7, 9, 11]
	var progs: Array = [[0, 5, 2, 6], [0, 3, 4, 0], [0, 6, 5, 4], [0, 2, 5, 4]] if minor else [[0, 4, 5, 3], [0, 3, 4, 0], [0, 5, 3, 4], [0, 3, 0, 4]]
	var prog: Array = progs[rng.randi_range(0, progs.size() - 1)]
	var root: int = p["root"]
	var step := 60.0 / float(p["bpm"]) / 2.0  # durata di una croma
	var sn := int(step * RATE)
	var bars := 8
	var buf := PackedFloat32Array()
	buf.resize(sn * 8 * bars)
	var rhythms: Array = [[1, 0, 1, 0, 1, 0, 1, 1], [1, 0, 0, 1, 1, 0, 1, 0], [1, 1, 0, 1, 0, 0, 1, 0], [1, 0, 1, 1, 0, 1, 0, 0], [1, 0, 0, 0, 1, 0, 1, 0]]
	var bar_rhythm: Array = []
	for i in range(4):
		bar_rhythm.append(rhythms[rng.randi_range(0, rhythms.size() - 1)])
	var deg := 4
	var drums: int = p["drums"]
	for bar in range(bars):
		var chord: int = prog[bar % 4]
		var tones: Array = [chord, chord + 2, chord + 4]
		var rh: Array = bar_rhythm[bar % 4] if bar < 6 else bar_rhythm[(bar + 1) % 4]
		for st in range(8):
			var pos := (bar * 8 + st) * sn
			# basso
			if st % 2 == 0:
				var bdeg: int = chord if st != 4 else chord + 4
				_voice(buf, pos, sn * 2 - 40, "tri", _freq(root - 24 + _deg(scale, bdeg)), _freq(root - 24 + _deg(scale, bdeg)), 0.30, rng, 0.5)
			# arpeggio
			var adeg: int = tones[st % 3]
			_voice(buf, pos, sn - 20, "sq25", _freq(root + _deg(scale, adeg)), _freq(root + _deg(scale, adeg)), 0.07, rng, 0.9)
			# melodia
			if rh[st] == 1:
				if st == 0 or rng.randf() < 0.35:
					deg = tones[rng.randi_range(0, 2)] + (7 if rng.randf() < 0.4 else 0)
				else:
					deg += [-2, -1, -1, 1, 1, 2][rng.randi_range(0, 5)]
				deg = clampi(deg, 0, 11)
				var length := 1
				while st + length < 8 and rh[st + length] == 0 and length < 3:
					length += 1
				var fq := _freq(root + 12 + _deg(scale, deg))
				_voice(buf, pos, sn * length - 30, "sq", fq, fq, 0.13, rng, 0.75)
			# batteria
			if drums > 0:
				if st % 4 == 0:
					_voice(buf, pos, int(sn * 0.6), "tri", 150.0, 45.0, 0.42, rng, 1.0)
				if st % 4 == 2:
					_voice(buf, pos, int(sn * 0.5), "noise", 1800.0, 900.0, 0.16, rng, 1.0)
				if drums > 1 or st % 2 == 1:
					_voice(buf, pos, int(sn * 0.2), "noise", 6000.0, 6000.0, 0.05, rng, 1.0)
	return _wav(_to_bytes(buf), true)


func _deg(scale: Array, d: int) -> int:
	return scale[posmod(d, 7)] + 12 * int(floor(d / 7.0))
