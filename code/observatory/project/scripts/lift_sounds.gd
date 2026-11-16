extends RefCounted
## The lift's sounds (scripts/lift.gd), synthesized when the lift is built: nothing is recorded or
## downloaded. The motor's hum, which loops; a small bell for an arrival; and the rattle of a folding
## gate. Mono, 16-bit, 22,050 Hz.

const RATE := 22050


## The motor: a 50 Hz hum, its harmonics and a faint whine, each a whole number of cycles in 0.2 s so
## that the loop has no seam.
static func hum() -> AudioStreamWAV:
	var n := int(RATE * 0.2)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = (0.5 * sin(TAU * 50.0 * t) + 0.28 * sin(TAU * 100.0 * t + 0.6) + 0.14 * sin(TAU * 150.0 * t + 1.1)
			+ 0.06 * sin(TAU * 250.0 * t + 2.0) + 0.03 * sin(TAU * 400.0 * t))
	var w := _wav(s, 0.5)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w


## An arrival: a small bell struck once, on C6. Its partials stand in a bell's ratios (a hum note an
## octave down, the fundamental, then 2, 2.76 and 5.4 times it), the higher ones dying first.
static func bell() -> AudioStreamWAV:
	var n := int(RATE * 1.8)
	var s := PackedFloat32Array()
	s.resize(n)
	var f := TAU * 1046.5 / RATE
	# Each partial's amplitude falls by a constant factor per sample: exp(-1 / (RATE * decay)).
	var d0 := exp(-1.0 / (RATE * 1.4))
	var d1 := exp(-1.0 / (RATE * 1.1))
	var d2 := exp(-1.0 / (RATE * 0.7))
	var d3 := exp(-1.0 / (RATE * 0.45))
	var d4 := exp(-1.0 / (RATE * 0.22))
	var e0 := 0.18
	var e1 := 1.0
	var e2 := 0.4
	var e3 := 0.3
	var e4 := 0.12
	for i in n:
		var x := f * i
		var v := e0 * sin(x * 0.5) + e1 * sin(x) + e2 * sin(x * 2.0) + e3 * sin(x * 2.76) + e4 * sin(x * 5.4)
		e0 *= d0
		e1 *= d1
		e2 *= d2
		e3 *= d3
		e4 *= d4
		# A 2 ms strike, and the last 50 ms faded out.
		s[i] = v * minf(1.0, i / (RATE * 0.002)) * minf(1.0, (n - i) / (RATE * 0.05))
	return _wav(s, 0.55)


## A folding gate: a click as each bar meets the next, closer together towards the end, then the
## leading bar's clack against the jamb. Metal: a burst of noise ringing at two high partials.
static func rattle(bars: int) -> AudioStreamWAV:
	var n := int(RATE * 0.55)
	var s := PackedFloat32Array()
	s.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var hits := []
	for k in bars - 1:
		hits.append([0.4 * pow(float(k + 1) / (bars - 1), 0.8), 0.3 + 0.15 * rng.randf(), 2300.0 + 400.0 * rng.randf()])
	hits.append([0.44, 1.0, 1700.0])
	for hit in hits:
		var i0 := int(float(hit[0]) * RATE)
		var amp: float = hit[1]
		var w := TAU * float(hit[2]) / RATE
		for j in int(RATE * 0.06):
			var i := i0 + j
			if i >= n:
				break
			var t := float(j) / RATE
			var noise := (rng.randf() * 2.0 - 1.0) * 0.6 * exp(-t / 0.008)
			var ring := exp(-t / 0.03) * (0.5 * sin(w * j) + 0.3 * sin(w * 1.58 * j))
			s[i] += amp * (noise + ring)
	return _wav(s, 0.5)


## Normalized to the given peak, as 16-bit samples.
static func _wav(s: PackedFloat32Array, peak: float) -> AudioStreamWAV:
	var top := 0.0
	for v in s:
		top = maxf(top, absf(v))
	var k := peak / maxf(top, 0.000001)
	var data := PackedByteArray()
	data.resize(s.size() * 2)
	for i in s.size():
		data.encode_s16(i * 2, int(clampf(s[i] * k, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
