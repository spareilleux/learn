---
title: Artifacts
description: Interactive pages built with Claude while working on my projects — maps, audits and simulators that complement the courses.
---

While working on my repositories with [Claude Code](https://code.claude.com/docs/en/overview), some analyses end up as an interactive page (an *artifact*) rather than a lesson: a map, an audit, a simulator. They are hosted on claude.ai, open in any browser, and are linked here and from the courses they illustrate.

:::note[Snapshots, not courses]
Each artifact is dated and describes a repository at one point in time. Unlike the lessons, they are not kept up to date. Some are in French only.
:::

## AI-assisted development

### Playbook SDLC × IX

[Open the artifact](https://claude.ai/code/artifact/9e67e00d-d2a6-4490-b2ed-d485e34be6ab) · French · 2026-09-13 · IX at `2a84de4`

The twelve plays of Anthropic's [AI-Native SDLC Playbook](https://academy.claude.com/courses/ai-native-sdlc-playbook) (plan, design, build, test, deploy, maintain) checked one by one against what the IX and Demerzel repositories actually do. Each play gets a verdict in the ecosystem's six-valued logic, the evidence behind it, and the gap to close. It ends with the five priority gaps and four lesson ideas for the agentic AI series: tests that pass without testing anything, hooks as approval gates, separation of duties with an agent, and deciding before implementing.

### Demerzel × ComfyUI — Governed Asset Pipeline

[Open the artifact](https://claude.ai/code/artifact/cc15cb21-c3f9-486a-b758-4127000246c8) · English · 2026-07-18

How [ComfyUI](https://docs.comfy.org/) image generation was wired into Demerzel as a governed provider: every texture request goes through a budget gate, runs locally on the GPU, and leaves a provenance record (seed, workflow hash, prompt, consumer). The budget gate is interactive — pick a provider and a cost and watch it allow, block or fail closed.

## Music and guitar

### Banc de Placement

[Open the artifact](https://claude.ai/code/artifact/f685cdc7-8e42-4b1f-9711-c9abb14d378a) · French and English · 2026-08-20

A 3D bench for placing two microphones on an acoustic guitar. Move the microphones and read the path difference, the time offset and the frequency of the first comb-filter notch when the two channels are summed to mono. It can overlay the model on a camera feed to check a real setup.

### Atlas des Douze

[Open the artifact](https://claude.ai/artifact/Qh4oMxFH5aPx9dYC4xGjyn) · French and English · 2026-09-17 · GA at `a826864`

Eleven interactive 3D plates (three.js WebGPU) for the Music theory for Guitar Alchemist course: the twelve pitch classes set out as a workshop, a neck, a helix, bracelets, the seven modes, the interval vector, the circle of fifths, the chords of a key, a cadence machine, OPTIC-K and tunings. Each plate's side rail explains what it shows and where the course and GA diverge. Some stone and wood textures were generated with ComfyUI (SDXL base 1.0), and the page says so next to each one.
