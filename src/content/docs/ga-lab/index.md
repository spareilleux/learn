---
title: Guitar Alchemist Lab — Mission
description: End-to-end prototypes built on Guitar Alchemist's real data and code — each one starts from a hypothesis written down before any measurement, and publishes its numbers and its failures.
sidebar:
  label: Mission
  order: 0
---

## Why this lab

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) has a lot of machinery: an index of 313,047 voicings embedded in the OPTIC-K space, chord recognition, fretboard geometry, a 3D neck, generators for images and models. The other courses on this site take each piece apart: [the music theory](../music-theory-ga/), [GA's AI](../ga-ai/), [three.js](../threejs/), [ComfyUI](../comfyui/), [Blender](../blender/). This lab puts pieces together into things you can see, hear and hold, and asks each time whether the idea actually works.

Every prototype follows the same contract.

1. **A hypothesis, committed first.** Before any measurement, a file in the prototype's `results/` folder says what I expect, with numbers. If I saw a number before writing it down, the file says so.
2. **Measurements.** The numbers come from a script in the repository, run on a named machine, with the data pinned: GA's commit, the file's SHA-256, the sample's seed.
3. **Failures published.** A prediction that turns out wrong stays in the lesson, next to what happened instead.

## Who this lab is for

You write C# or Java, you have followed at least one of the GA courses, and you are curious about what GA's data looks like when you stop reading it through an API. Each prototype says which lessons it builds on. The code is JavaScript for the browser and Node.js, and whatever each prototype needs beyond that.

## Prerequisites

- [Node.js](https://nodejs.org/) 24 and [Git](https://git-scm.com/downloads). On Windows, run the commands from Git Bash.
- A browser with [WebGPU](https://developer.mozilla.org/docs/Web/API/WebGPU_API): a recent Chrome or Edge. The prototypes fall back to WebGL 2 elsewhere.
- For the local modes that read GA's whole index: a clone of [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) and about 200 MB for the index file. The published pages need nothing but a browser.
- Helpful background: [lesson 2](../ga-ai/02-optic-k-embeddings/) and [lesson 3](../ga-ai/03-index-and-search/) of the GA AI course, [lesson 5](../machine-learning-ix/05-dimensionality-reduction/) of the IX machine learning course, and [lesson 8](../threejs/08-performance-instancing-batching-lod/) of the three.js course.

## Outline

| # | Prototype | Question | State |
|---|---|---|---|
| P1 | [Voicing space explorer](01-voicing-explorer/) | Can you see GA's voicing space in three dimensions, and what does the picture hide? | published |
| P2 | [Play a chord, see the universe](02-chord-universe/) | Chord recognition in the browser: FFT, note estimation, template matching over GA's chord qualities, 3D neck, bracelet and next chord; 624 synthetic strums and 17 CC0 recordings, predictions first | published |
| P3 | Album covers | Can a diffusion model make a cover that says something true about a chord progression? | planned |
| P4 | AI render pass | Does a generated texture or lighting pass make GA's 3D scenes better, measured against the plain render? | planned |
| P5 | 3D-printable bracelets | Can a pitch-class bracelet become a printable object, from GA's data to a mesh that passes a slicer? | planned |
| P6 | Full chain | Microphone to chord to voicing to image to object, in one run: where does it break? | planned |
| P7 | Playability model | Can a small model trained on the CPU predict how hard a voicing is to play better than GA's hand-written cost? | planned |
| — | [Journal](journal/) | | |

## Resources

- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), the code and data every prototype reads.
- The code of this lab: [`code/ga-protos`](https://github.com/spareilleux/learn/tree/main/code/ga-protos), one folder per prototype, tested by [`.github/workflows/ga-protos-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ga-protos-examples.yml).
- [three.js](https://threejs.org/) and its [WebGPURenderer](https://threejs.org/docs/pages/WebGPURenderer.html), [Vite](https://vite.dev/), and the [Web Audio API](https://developer.mozilla.org/docs/Web/API/Web_Audio_API).
- Clifton Callender, Ian Quinn and Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://doi.org/10.1126/science.1153021), *Science* 320, 2008: the OPTIC equivalences GA's embedding is named after.
