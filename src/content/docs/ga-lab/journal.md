---
title: Journal
description: Dated notes of the Guitar Alchemist Lab — where each prototype's data comes from, the hypotheses written before measuring, what the measurements said, and what GA's code turned out to do.
sidebar:
  order: 99
---

## Progress

- [x] Lab scaffold: mission, outline of seven prototypes, CI workflow
- [x] P1, voicing space explorer: build step, page, measurements, lesson
- [x] P2, play a chord, see the universe
- [ ] P3, album covers
- [ ] P4, AI render pass
- [ ] P5, 3D-printable bracelets
- [ ] P6, full chain
- [ ] P7, playability model

## QA

What the lab found in GuitarAlchemist/ga while measuring, not while reading. Line numbers point at [`66bdd049`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e), the commit the index was exported from. None of these is a bug report yet: they are what the measurements showed.

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| The index and the two `FretDiagram` renderers agree on which string comes first | The index writes a diagram high E first; both renderers read it low E first | [`FretDiagram.cs:14`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Agents/FretDiagram.cs#L14), [`FretDiagram.tsx:8-11`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/ReactComponents/ga-react-components/src/components/FretDiagram.tsx#L8-L11) | Row 1000 is `1-2-x-5-x-1` for MIDI 65, 61, 55, 41; 30,000 sampled rows read high E first, 0 mismatches | Reproduced, fix being prepared |
| The React `FretDiagram` shows every fretted note | It drops a dot when the grid starts at the nut and the voicing reaches a fret below the last row | [`FretDiagram.tsx`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/ReactComponents/ga-react-components/src/components/FretDiagram.tsx#L31) lines 31 and 104 | 15,853 of 297,910 guitar voicings, 5.32 % | Reproduced, fix being prepared |
| `OptickIndexReader`'s summary describes the vectors it returns | It says "L2-normalized"; each partition is normalized, then scaled by the square root of its weight | [`OptickIndexReader.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Search/OptickIndexReader.cs) | Squared length 1.15 or 1.05, never 1 | Reproduced. The documentation is wrong, the behaviour is right: the dot product is the weighted partition cosine the search needs |
| Two voicings that sound and look different are two points | Voicings with the same pitch classes, the same top note and a similar shape collapse onto one vector | [`OptickIndexWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) | 121,768 of 297,910 guitar vectors are bit-for-bit copies of another, 40.9 %; the largest group holds 12 voicings of F♯ diminished with A on top | Reproduced. A consequence of the embedding rather than an obvious defect — to arbitrate before changing anything |
| The same commit exports the same index | Deduplication keeps the cheapest voicing of each group, generation runs in parallel, and ties go to whichever arrives first | [`OptickIndexWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) | Two exports of one build: every shared vector identical, 70 voicings present in one and missing from the other | Reproduced. The file's hash pins the data; the commit does not |
| `--export-max N` samples the index | It keeps the first N raw voicings in generation order, which starts high on the neck | [`OptickIndexWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) | `--export-max 3000` produced 2,641 vectors, 0 of them in the full index | Reproduced. A partial export cannot check a full one |
| A slash chord names its bass with the spelling of the key | Some names use the wrong enharmonic, for example `Gmaj7/Gb` instead of `Gmaj7/F♯` | index chord names | Seen while reading the largest duplicate groups | Reproduced, not yet counted |

## Experiments

Each prototype writes its hypotheses before the measuring script exists, and they are committed first. A refuted hypothesis stays here: it is the result that cost the most to get.

| Question | Hypothesis, written before measuring | Result | Verdict |
|---|---|---|---|
| How many dimensions does the voicing space really need? | Committed in [`hypotheses.md`](https://github.com/spareilleux/learn/blob/03f2bbb/code/ga-protos/p1-voicing-explorer/results/hypotheses.md) at `03f2bbb`; the file says which one was not blind | 3 components explain 22.2 % of the variance, 10 explain 48.0 %, 32 explain 84.7 %, 64 explain 99.9 % | The first two axes are mostly MORPHOLOGY, the third STRUCTURE, CONTEXT weighs nothing (2026-09-17) |
| Does a 3D view keep the neighbours the exact search finds? | H2 set a recall@10 threshold of 0.15; H3 predicted the full index would do worse than the sample | Recall@10 of 0.168 within the 30,000 sample, 0.348 against all guitar voicings; with 32 components, 0.693 and 0.787 | H2 missed its threshold, H3 was wrong — both refuted (2026-09-17) |
| Is WebGPU faster than WebGL 2 for 300,000 points? | A first series said 3.5 ms against 0.5 ms and looked like a finding | With `trackTimestamp`, the render pass takes 0.066 ms on WebGPU and 0.071 ms on WebGL 2 at 30,000 points, 0.26 ms for all 297,910, 2.3 ms for 3 million random points | The first series was a measuring mistake: 3.5 ms is how long `onSubmittedWorkDone` takes to resolve, not GPU work. The lesson quotes the second series (2026-09-17) |
| Does picking on the CPU hold at full index size? | H6 expected more than 16 ms at 297,910 points | 0.2 ms for 30,000, 1.4 ms for 297,910, 14 ms for 3 million | H6 refuted (2026-09-17) |
| Can the browser hold the whole index? | — | 156 MB loaded and decoded in 341 ms, 180 MB of JavaScript heap, 28 ms to find the ten exact neighbours | It can, and the lesson ships that mode (2026-09-17) |
| Can a chromagram in a page name the chord you play? | Eight figures predicted before any recording | 79.3 % of 624 synthetic strums named exactly — 89.1 % in root position, 50 % for inversions — and 11 of 17 CC0 recordings; estimating the notes before the chromagram was worth 39 points | Seven of the eight figures held; the oracle, the noise conditions and the recorded failures did not (2026-09-17) |

## 2026-09-16 — P1: where the data comes from

- GA's `main` was at [`66bdd049`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e) ("chore(quality): snapshot 2026-09-16"). The index isn't in the repository: `FretboardVoicingsCLI --export-embeddings` generates it into `state/voicings/optick.index`.
- I didn't rebuild it. The session measuring GA's performance had built `FretboardVoicingsCLI` in a clean clone at that commit and exported the index between 23:00 and 23:02 local time, in 149 seconds. Its log says "688,351 raw, 313,047 unique". I copied that file and pinned it by hash: 183,770,270 bytes, SHA-256 `1e91e4695bab8aa4bb451fdd1f199a4afaa4c4ad913f08acc5163c6ab07caa23`, 313,047 voicings (297,910 guitar, 7,795 bass, 7,342 ukulele), 124 dimensions, schema hash `0x37cd8ecf`, the one my CRC-32 of `EmbeddingSchema.CompactLayoutV4` gives.
- Row 1000 settles the string order. Its diagram is `1-2-x-5-x-1` and its MIDI notes are 65, 61, 55, 41: read string 1 first (high E + 1 = F4, 65), not low E first. On a chord chart, that shape is `1x5x21`. The build step checks all 30,000 sampled rows the same way: 0 mismatches.
- GA disagrees with itself here. [`FretDiagram.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Agents/FretDiagram.cs#L14) and the React [`FretDiagram.tsx`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/ReactComponents/ga-react-components/src/components/FretDiagram.tsx#L8-L11) take frets low E first; the index writes them high E first. The [GA AI course](../../ga-ai/02-optic-k-embeddings/) found the same split in an MCP tool's example.
- The index's vectors don't have unit length, although `OptickIndexReader`'s summary says "L2-normalized": each partition is normalized, then scaled by the square root of its weight, so a vector's squared length is the sum of the weights of its non-empty partitions, 1.15 or 1.05. The dot product is still the weighted partition cosine, which is what the search needs.

## 2026-09-16 — P1: hypotheses

- Written in [`results/hypotheses.md`](https://github.com/spareilleux/learn/blob/03f2bbb/code/ga-protos/p1-voicing-explorer/results/hypotheses.md) and committed in `03f2bbb`, before the measurement script existed.
- One of them isn't blind, and the file says so: a smoke test of the build step on 2,000 voicings had already printed that three components explain 22.2 % of the variance.

## 2026-09-17 — P1: measurements

- Three principal components explain 22.2 % of the variance, ten 48.0 %, 32 84.7 %, 64 99.9 %. The first two axes are mostly MORPHOLOGY, the third STRUCTURE; CONTEXT weighs nothing.
- Recall@10 of the 3D view against the exact neighbours: 0.168 within the 30,000 sample, 0.348 against all guitar voicings. With 32 components: 0.693 and 0.787. H2 missed its 0.15 threshold; H3, which predicted the full index would do worse, was wrong.
- 121,768 of the 297,910 guitar vectors are bit-for-bit copies of another voicing's vector. The largest group holds 12 voicings of F♯ diminished with A on top. Voicings with the same pitch classes, the same top note and a similar shape are the same point for OPTIC-K.
- GA's React `FretDiagram` drops a dot for 15,853 guitar voicings (5.32 %): the grid starts at the nut when the lowest fretted note is on fret 2, and a voicing reaching fret 6 needs a sixth row.

## 2026-09-17 — P1: two exports, one commit

- The performance session exported the index a second time from the same build. Matched by instrument and diagram, every shared vector is identical, but 70 voicings of one export are missing from the other: deduplication keeps the cheapest voicing of each group, the generator runs in parallel, and ties go to whichever arrives first. The file's hash pins the data; the commit doesn't.
- I tried to confirm the provenance by regenerating 3,000 guitar voicings with GA's CLI (`--export-max 3000`, 4.1 s under the heavy-work lock). It found 0 of their 2,641 vectors in the full index. The limit keeps the first 3,000 raw voicings in generation order, which started at fret 19; within that small set, deduplication kept high-neck voicings that lose to cheaper shapes in the full export. A partial export can't check a full one.

## 2026-09-17 — P1: frame times, measured twice

- First series: `render()` plus `onSubmittedWorkDone`, 120 frames at 1280 × 720 in headless Chromium 153 on the RTX 5080. WebGPU came out at 3.5 ms for 30,000 points and WebGL 2 at 0.5 ms. That looked like a finding, and it was a measuring mistake: WebGPU's number didn't change between 30,000 and 3 million points.
- Second series, with three.js's `trackTimestamp` and `resolveTimestampsAsync`: the render pass takes 0.066 ms on WebGPU and 0.071 ms on WebGL 2 for 30,000 points, 0.26 ms for all 297,910, 2.3 ms for 3 million random points. The 3.5 ms is the time `onSubmittedWorkDone` takes to resolve, not GPU work.
- `renderer.info.render.drawCalls` read 434 and then negative values in the probe, because three.js resets it at each animation frame and the probe awaits across frames. The lesson doesn't quote it.
- Picking by projecting every point on the CPU: 0.2 ms for 30,000, 1.4 ms for 297,910, 14 ms for 3 million. H6 expected more than 16 ms at 297,910.
- Local full-index mode: 156 MB loaded and decoded in 341 ms, 180 MB of JavaScript heap, 28 ms to find the ten exact neighbours of a voicing in the browser.

## 2026-09-17 — P1: publishing

- No pipeline for live demos existed on the site yet. `scripts/publish.mjs` builds the page with Vite (`base: './'`) into `public/ga-lab/p1/`, which Astro copies as is: 3.65 MB, plus a 241 KB screenshot. The lesson shows the screenshot and a button, and loads the page in an iframe only on click, through a small `LazyDemo` component that prefixes the site's base path.
- `scripts/check-published.mjs` serves `public/` under `/learn/` like GitHub Pages and opens the published page: WebGPU, 30,000 points, no error.

## 2026-09-17 — P2: play a chord, see the universe

- **P2 published.** The chord recognizer names 79.3 % of 624 synthetic strums exactly (89.1 % in root position, 50 % for inversions) and 11 of 17 CC0 recordings; estimating notes before the chromagram was worth 39 points. Seven of eight predicted figures held; the oracle, the noise conditions and the recorded failures did not. The audio never leaves the page (connect-src 'none'). [Lesson](../02-chord-universe/)

## To verify

- The explorer on macOS Safari and Firefox, with and without WebGPU: tested only in Chromium on Windows.
- Audio on mobile browsers, which may block the `AudioContext` until a tap.
