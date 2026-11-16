extends Node
## A looping hum kept going in the web build. There, Godot's sample playback plays a looping stream
## once and stops, and playing it again once `playing` turned false left silences of 2 ms to 1.7 s
## (artpass/audio/NOTES.md, 2026-10-03, the drone's and the lift's hums). Here two players take turns:
## the next copy starts once the current one has played SHARE of the stream, timed by the clock times
## its pitch, and the two crossfade over FADE seconds. Starting half a take early, not just before the
## end, is what carries the hum over a stalled frame: the web build stalls for up to 0.7 s while it
## compiles what comes into view first, and no script runs then (artpass/audio/NOTES.md, 2026-10-04).
## Elsewhere the stream loops by itself and the owner's player alone plays, as before (--web-loops
## makes a native run take turns too, for tests).
##   var loop: Node = load("res://scripts/web_loop.gd").new()
##   add_child(loop); loop.configure(player)
##   loop.run(on, pitch, db)   # every frame: whether it sounds, its pitch and its level

const SHARE := 0.5            # of the stream a copy plays before the next starts
const FADE := 0.25            # s of crossfade

var voice: AudioStreamPlayer3D   # the owner's player
var twin := false                # true: two players taking turns
## starts: the hum began; handovers: the next copy took over; late_ms: the most a handover came after
## the current copy's end (a stall longer than what it had left); stall_ms: the longest frame seen.
var stats := {"starts": 0, "handovers": 0, "late_ms": 0.0, "stall_ms": 0.0}

var _other: AudioStreamPlayer3D
var _cur: AudioStreamPlayer3D
var _old: AudioStreamPlayer3D
var _len := 0.0                  # the stream's seconds at pitch 1
var _pos := 0.0                  # stream seconds the current copy has played
var _x := 0.0                    # the crossfade's wall seconds so far
var _on := false
var _last_us := 0


func configure(p: AudioStreamPlayer3D) -> void:
	voice = p
	twin = OS.has_feature("web") or OS.get_cmdline_user_args().has("--web-loops")
	if not twin or p.stream == null:
		twin = false
		return
	_len = p.stream.get_length()
	_other = p.duplicate() as AudioStreamPlayer3D
	_other.name = p.name + "Twin"
	# Deferred: the owner may be building its parent; the first handover is half a loop away.
	p.add_sibling.call_deferred(_other)


## Every frame. Returns true when the hum starts (it was silent).
func run(on: bool, pitch: float, db: float) -> bool:
	var now := Time.get_ticks_usec()
	var dt := float(now - _last_us) / 1e6 if _last_us > 0 else 0.0
	_last_us = now
	if not twin:
		var started := false
		if on:
			if not voice.playing:
				voice.play()
				stats.starts += 1
				started = true
			voice.pitch_scale = pitch
			voice.volume_db = db
		elif voice.playing:
			voice.stop()
		return started
	if not on:
		if _on:
			voice.stop()
			_other.stop()
			_old = null
			_on = false
		return false
	if not _on:
		_on = true
		_cur = voice
		_old = null
		_pos = 0.0
		_cur.pitch_scale = pitch
		_cur.volume_db = db
		_cur.play()
		stats.starts += 1
		return true
	stats.stall_ms = maxf(float(stats.stall_ms), dt * 1000.0)
	# What the current copy played since the last frame, at the pitch it had.
	_pos += dt * _cur.pitch_scale
	var k := 1.0
	if _old != null:
		_x += dt
		k = clampf(_x / FADE, 0.0, 1.0)
		if k >= 1.0:
			_old.stop()
			_old = null
		else:
			_old.pitch_scale = pitch
			_old.volume_db = db + linear_to_db(maxf(cos(k * PI * 0.5), 0.001))
	_cur.pitch_scale = pitch
	_cur.volume_db = db + (linear_to_db(maxf(sin(k * PI * 0.5), 0.001)) if _old != null else 0.0)
	if _len > 0.0 and _pos >= _len * SHARE:
		if _old != null:
			_old.stop()
		if _pos > _len:
			stats.late_ms = maxf(float(stats.late_ms), (_pos - _len) / maxf(pitch, 0.05) * 1000.0)
		_old = _cur
		_cur = _other if _cur == voice else voice
		_x = 0.0
		_pos = 0.0
		_cur.pitch_scale = pitch
		_cur.volume_db = db - 60.0
		_cur.play()
		stats.handovers += 1
	return false


## Whether a copy is sounding.
func is_on() -> bool:
	return _on if twin else voice.playing
