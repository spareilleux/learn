# P2 chord recognition: hypothesis and predictions

Written and committed before the first run of `node eval/evaluate.ts` on the corpus. The results are compared with
these numbers in lesson 2 of the Guitar Alchemist Lab, whether they hold or not.

## What was looked at before this file

- Unit tests (`tests/dsp.test.ts`) on one open C major and on ideal chroma vectors.
- A development set outside the corpus: roots D and G, 13 qualities, two root-position voicings each (the most common
  one and the first at fret 5 or higher), clean and "hard" (30 cents flat, strings +-8 cents, 12 dB SNR), seeds 90000
  and up, 104 clips. The corpus uses other seeds, other strum timings and detunings, and adds inversions, but its
  voicings v0 at roots D and G are the same fingerings. The DSP parameters were chosen on this set:
  - the classic chromagram (every peak folded into its pitch class) with harmonic templates recognized 71 of 104;
  - the note estimation (harmonic summation with cancellation) with binary templates, 92 of 104;
  - the same without tuning correction, 80 of 104.
- A smoke run of the harness on the first 20 corpus clips, which printed only timings: 0.3 ms per frame (median).

## Hypothesis

Estimating notes before folding them into pitch classes matters more than any other choice: the third, fifth and
seventh harmonics of a plucked string put energy on the fifth, the major third and the minor seventh of every note,
and a chromagram that keeps them turns triads into seventh chords. What remains after that is not a signal-processing
problem but a naming one: chords that share a pitch-class set (C6 and Am7, Csus2 and Gsus4, the four names of a
diminished seventh, the three of an augmented triad) can only be told apart by the bass, so their inversions will be
named after the bass note.

## Predictions (624 clips)

| Configuration | exact % | range |
|---|---|---|
| oracle (ideal pitch classes and bass) | 88 | 86 to 90 |
| main: notes, binary templates, whitening, bass, tuning | 72 | 62 to 82 |
| notes, harmonic templates | 62 | 50 to 72 |
| peaks folded (classic chroma), harmonic templates | 58 | 48 to 68 |
| peaks folded (classic chroma), binary templates | 45 | 30 to 55 |
| no whitening | 67 | 57 to 77 |
| no bass term | 60 | 50 to 70 |
| no tuning correction | 64 | 54 to 74 |

- Main configuration, by condition: clean 82, detuned 75, noisy 72, detuned and noisy 65 (each plus or minus 10).
- Main configuration, root position against inversions: about 78 against about 45.
- Without the bass term, the "same pitch-class set" accuracy stays within 2 points of the main configuration's, while
  the exact accuracy drops: the notes are found, the name is not.
- Quality accuracy is higher than exact accuracy for dim7 and aug (the quality is right, the root is one of the other
  names of the same set): dim7 quality 90 % or more.
- Most frequent mistakes, in some order: maj7 read as a major triad and m7 as a minor triad (the seventh is a fifth
  above the third, so it sits on the third's third harmonic and is cancelled with it), m7b5 read as dim, add9 read as
  a major triad or sus2, 6 read as m7 a minor third lower, sus4 read as sus2 a fourth higher, and inverted dim7 and aug
  named after their bass.
- Detection time after the strum (audio time, first frame with the exact stable label): median 230 ms, between 190 and
  330 ms. Frames are 186 ms long at 44.1 kHz, hops 46 ms, and a label needs 2 frames in a row.
- Compute per frame in Node.js on the author's machine: median about 0.3 ms, p95 under 1 ms, so the browser has more
  than 40 ms of slack per hop.

## Recorded corpus: predictions (added after the synthetic run, before the recorded one)

Written after the synthetic corpus was measured (main configuration: 79.3 % exact), and before running
`eval/recorded.ts` on the 17 CC0 recordings of `eval/recorded/sources.json`. Only the titles, descriptions and
durations had been read; none had been listened to or analyzed.

- Exact chord: 11 of 17, between 7 and 14. Real guitars have inharmonic strings, body resonances, pick noise and MP3
  coding; the synthetic Karplus-Strong strings have none of these.
- Root: 13 of 17. Most recordings are plain major and minor triads, which the synthetic run got right 90 % of the time.
- Likely failures: the pad through delay and reverb (177041), the recording through guitar plugins (334629, Asus4),
  the tremolo (584138), the "variation" of Dm (456801), whose extra notes may name another chord, and the percussive
  hit before the E chord (246288).
- The three-string F minor (8603) and the D major with F# in the bass (8495) are recognized: three distinct pitch
  classes, and no other chord of the 13 qualities has the same set.
