extends RefCounted
## The sounds the author chose by ear on 2026-10-03 (artpass/audio/choices.json), each a local
## Stable Audio 3 Small SFX take (Stability AI Community License: "Powered by Stability AI" on the
## Observatory's page). Each file is the take's A/B cut (artpass/audio/ab/): mono, its lead silence
## cut, faded at the length the cue can last, and matched to the loudness of the synthesized cue it
## replaces. A script asks here for its cue; when the file is not in the build it gets null, or its
## fallback, and keeps its synthesized cue.

const DIR := "res://assets/sfx/"
## The pitch to play a take at, so that it sits where its synthesized cue did. The hologram's step was
## a pluck on A5 that climbs a pentatonic by up to 16 semitones; the take's strongest partial is at
## 2513 Hz, so it is brought down to A6 (1760 Hz) and climbs to 4.4 kHz instead of 6.3.
const TUNE := {"hologram_ix-step": 1760.0 / 2512.7}
## A level, in dB, for a take that repeats and overlaps. The A/B cuts match the synthesized cue's gated
## loudness; a TARS's clank comes 12 to 23 times a second, so what adds up is each one's energy: the
## take's 0.30 s carry 4.5 dB more of it than the synthesized 0.16 s (artpass/audio/event_energy.py),
## which raised the web capture's walk by 5.4 LU and its peak to -0.2 dBFS (web-after-v31/).
const GAIN_DB := {"curio_wheel-clank": -4.5}


## The take for this cue, or null when its file is not in the build.
static func take(cue: String) -> AudioStreamWAV:
	var path := DIR + cue + ".wav"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStreamWAV


## The take for this cue, or the fallback.
static func pick(cue: String, fallback: AudioStream) -> AudioStream:
	var t := take(cue)
	if t == null:
		return fallback
	return t


## A take looping over its whole length, or the fallback. The web build replays a looping sample
## from its start each time it ends, whatever its loop points, so the cut closes over the whole file.
static func pick_loop(cue: String, fallback: AudioStream) -> AudioStream:
	var t := take(cue)
	if t == null:
		return fallback
	var w := t.duplicate() as AudioStreamWAV
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = int(round(w.get_length() * w.mix_rate))
	return w


## Swaps in the take of every cue of a script's table that has one in the build; returns their names.
static func pick_all(sounds: Dictionary, prefix: String) -> Array:
	var swapped := []
	for key in sounds.keys():
		var t := take(prefix + str(key))
		if t != null:
			sounds[key] = t
			swapped.append(str(key))
	return swapped


## The pitch factor for a cue's stream: its TUNE when the stream is the take, else 1.
static func tune(cue: String, stream: AudioStream) -> float:
	if stream == null or not stream.resource_path.begins_with(DIR):
		return 1.0
	return float(TUNE.get(cue, 1.0))


## The level to add, in dB, for a cue's stream: its GAIN_DB when the stream is the take, else 0.
static func gain_db(cue: String, stream: AudioStream) -> float:
	if stream == null or not stream.resource_path.begins_with(DIR):
		return 0.0
	return float(GAIN_DB.get(cue, 0.0))
