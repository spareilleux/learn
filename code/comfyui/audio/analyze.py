#!/usr/bin/env python3
"""Lesson 15: what key and tempo a generated clip is really in, and which chords it plays.

    python analyze.py FILE...                  key, tempo and duration of each file, one line each
    python analyze.py --chords FILE            the best chord template for each bar (4 beats)
    python analyze.py --synth OUT.wav          writes the test signal: C major chords at 120 BPM

The key is the Krumhansl-Kessler method: the clip's mean chroma is correlated with the 24 rotations of the
major and minor key profiles, and the best correlation wins. The tempo is librosa's beat tracker. Both are
estimates, with known failure modes: relative major and minor keys (C major and A minor share their notes)
and tempo octaves (60, 120 and 240 BPM fit the same pulse). The lesson reports them as such.
"""
import argparse
import sys
import wave

import numpy as np

NOTES = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
# Krumhansl and Kessler (1982) probe-tone profiles, starting on the tonic.
MAJOR = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
MINOR = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])
CHORDS = {"maj": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10]}


def key_scores(chroma_mean):
    scores = []
    for tonic in range(12):
        for mode, profile in (("major", MAJOR), ("minor", MINOR)):
            r = np.corrcoef(np.roll(profile, tonic), chroma_mean)[0, 1]
            scores.append((float(r), f"{NOTES[tonic]} {mode}"))
    return sorted(scores, reverse=True)


def chord_name(chroma):
    best = None
    for root in range(12):
        for quality, intervals in CHORDS.items():
            template = np.zeros(12)
            template[[(root + i) % 12 for i in intervals]] = 1
            r = np.corrcoef(template, chroma)[0, 1]
            if best is None or r > best[0]:
                best = (float(r), NOTES[root] + ("" if quality == "maj" else quality))
    return best


def load(path, sr=22050):
    import librosa
    y, sr = librosa.load(path, sr=sr, mono=True)
    return y, sr


def analyze(path):
    import librosa
    y, sr = load(path)
    chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
    scores = key_scores(chroma.mean(axis=1))
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
    return {
        "duration": len(y) / sr,
        "key": scores[0][1], "key_r": scores[0][0],
        "second": scores[1][1], "second_r": scores[1][0],
        "bpm": float(np.atleast_1d(tempo)[0]),
    }


def bars(path, beats_per_bar=4):
    import librosa
    y, sr = load(path)
    _, beats = librosa.beat.beat_track(y=y, sr=sr)
    chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
    bounds = list(beats[::beats_per_bar]) + [chroma.shape[1]]
    out = []
    for start, end in zip(bounds, bounds[1:]):
        if end - start < 2:
            continue
        r, name = chord_name(chroma[:, start:end].mean(axis=1))
        out.append((float(librosa.frames_to_time(start, sr=sr)), name, r))
    return out


def synth(path, bpm=120, seconds=16, sr=22050):
    """C, F, G, C major triads, one bar each, with a click on every beat: a signal whose answer is known."""
    t_beat = 60 / bpm
    n = int(seconds * sr)
    y = np.zeros(n)
    progression = [[60, 64, 67], [65, 69, 72], [67, 71, 74], [60, 64, 67]]
    beat = 0
    while beat * t_beat < seconds:
        start = int(beat * t_beat * sr)
        chord = progression[(beat // 4) % 4]
        length = min(int(t_beat * sr), n - start)
        t = np.arange(length) / sr
        envelope = np.exp(-3 * t)
        for midi in chord:
            y[start:start + length] += 0.2 * envelope * np.sin(2 * np.pi * 440 * 2 ** ((midi - 69) / 12) * t)
        click = min(int(0.01 * sr), n - start)
        y[start:start + click] += 0.8 * np.exp(-np.arange(click) / (0.002 * sr)) * np.random.default_rng(beat).standard_normal(click) * 0.3
        beat += 1
    y = (y / np.abs(y).max() * 0.8 * 32767).astype(np.int16)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sr)
        f.writeframes(y.tobytes())


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("files", nargs="*")
    parser.add_argument("--chords", action="store_true")
    parser.add_argument("--synth")
    args = parser.parse_args(argv)
    if args.synth:
        synth(args.synth)
        return 0
    for path in args.files:
        if args.chords:
            print(path)
            for time, name, r in bars(path):
                print(f"  {time:6.2f} s  {name:6} r={r:.2f}")
            continue
        a = analyze(path)
        print(f"{path}: {a['duration']:.1f} s, key {a['key']} (r={a['key_r']:.2f}; next {a['second']}, "
              f"r={a['second_r']:.2f}), tempo {a['bpm']:.1f} BPM")
    return 0


if __name__ == "__main__":
    sys.exit(main())
