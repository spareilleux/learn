---
module_id: gtr-007-carry-picking-phase-across-bar-lines
department: guitar-studies
course: "Carry Picking Phase Across Bar Lines"
level: intermediate
prerequisites: ["gtr-005-plan-which-string-keeps-ringing", "mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Carry Picking Phase Across Bar Lines

> **Draft scope.** Authored attack and motion-clock models, exact traces and pinned notation-source inspection. Human technical, musician, fluent-language and learner reviews and deployed course HTML verification remain pending. No guitarist, score importer, audio renderer or physical technique was tested.

## The project question

A guitar agent writes one bar of alternate picking and repeats it. Does restarting the directions at every bar preserve alternation? What happens when there is a rest or a tied continuation? A useful practice instruction states which events advance its direction state instead of silently treating a bar line as a reset.

We use one string, seven equally spaced eighth pulses per bar and an authored rule: consecutive attacks alternate D and U, starting D at absolute pulse 0. D and U mean down and up directions. They do not prescribe loudness, accent, speed, string crossing, effort or a preferred technique. [MusicXML's down-bow symbol](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/down-bow/) also represents a down-stroke on plucked instruments; the [up-bow symbol](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/up-bow/) likewise includes up-stroke. A notation symbol is distinct from a measured hand movement.

## 1. Carry the state through an odd bar

First place an attack at every pulse. Directions at absolute pulses 0 through 6 are D, U, D, U, D, U, D. The attack at pulse 7 must be U under the declared rule. Bar starts at pulses 0, 7, 14 and 21 therefore have directions D, U, D and U.

Resetting D at each bar instead creates D followed by D at the boundaries from pulse 6 to 7, 13 to 14 and 20 to 21. That can be an intentionally different instruction, but it is not strict alternation across those attacks. No judgment about a player's preferred picking strategy follows from the symbolic mismatch.

### Practice exercise 1: check the repeated bar

Give the direction at pulse 7 under continuous attack alternation and under a per-bar D reset. Identify the first repeated-direction boundary and the first bar start that restores the original bar-and-direction state.

> **Answer:** Continuous alternation gives U at pulse 7; resetting gives D. The first reset boundary is pulse 6 D followed by pulse 7 D. The original bar phase and picking direction return together at pulse 14, after two bars.

## 2. Include every relevant clock in a repeat claim

Add an independent authored marker repeating every four eighth pulses. It is a visual practice marker, not a performed accent. A complete state now includes position modulo 7 in the bar, modulo 4 in the marker and modulo 2 in the picking cycle. The first positive return of all three to their starting phases occurs at pulse 28, after four bars.

Pulse 14 restores the bar and picking state but has marker phase 2. At the explicitly declared quarter-note rate 120, each eighth pulse lasts 0.25 seconds, so pulse 28 occurs 7 seconds after pulse 0. The phase calculation itself does not establish actual playback timing.

### Practice exercise 2: test a complete repeat

At pulse 14, which phase has not returned? Give the first full return and its elapsed time under the stated rate. Is repeating just the two-bar direction pattern enough to reset every marker?

> **Answer:** The four-pulse marker is at phase 2. The full return is pulse 28, or 7 seconds at quarter-note rate 120. A two-bar repeat does not restore the marker; the return claim must name the state components being compared.

## 3. State what a rest advances

Now make within-bar pulse 3 silent in every bar. Under attack-driven alternation, a rest produces no attack and does not advance the attack counter. The first bar's attacked pulses 0, 1, 2, 4, 5, 6 have directions D, U, D, U, D, U. Six attacks occurred, so the next bar's first attack at absolute pulse 7 is D.

An independently authored pulse-clock policy instead alternates D/U motion on every eighth pulse, including silent ones. Its attack at pulse 4 is D and at pulse 7 is U. These policies agree before the first rest and then differ. Choosing between them requires the intended exercise; neither is a universal instruction for all guitar techniques.

### Practice exercise 3: distinguish silence from a state reset

Give the attack directions at pulses 4 and 7 for the attack-driven and pulse-clock policies with that repeated rest. What information must the agent add before claiming its directions are unambiguous?

> **Answer:** Attack-driven directions are U at pulse 4 and D at pulse 7. Pulse-clock directions are D at pulse 4 and U at pulse 7. Specify whether silent pulses advance a motion clock or only actual attacks advance alternation, together with the starting phase and any intentional resets.

## 4. Do not create an attack at a continuation

Return to the all-attack grid except that absolute pulse 7 is a continuation of the note attacked at pulse 6. Under this lesson's attack model it is not struck again. After the D attack at pulse 6, the next attack at pulse 8 is U. Inventing an attack at pulse 7 would consume that U and change pulse 8 to D.

The pinned [GA MusicXML note type](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L93-L109) has a tie field, while the [selected note parser](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L85-L115) assigns it no value. This static boundary is a reason to test a real import before deriving attack counts from its result. It is not a newly reproduced playback defect.

### Practice exercise 4: preserve attack identity

With pulse 7 a tied continuation, what direction belongs to the attack at pulse 8? How would a false reattack change the answer, and what does the inspected parser field fail to certify?

> **Answer:** The next real attack at pulse 8 is U. A false attack at pulse 7 would make pulse 8 D. The inspected parser's unpopulated tie field does not certify preservation of continuation identity through an actual importer or playback path; no such path was executed here.

## 5. Check a notation direction at the boundary

The [Guitar Pro project types](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/GuitarProTypes.fs#L45-L96) distinguish accent from stroke and pick-stroke effects, with direction strings. In the [inspected effect parser](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/GuitarProParser.fs#L129-L147), selected case 7 constructs a down pick-stroke. That branch is not a continuous cross-bar phase planner or proof of conformance to every actual binary file.

The [MusicXML technical parser](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L55-L80) lists string, fret and several techniques but not the up/down symbols linked above; unmatched child names are filtered out. Do not infer symbol support from the standard's existence or infer every GA path's behavior from this single branch.

### Practice exercise 5: prepare a useful round-trip probe

Why is a direction-capable data type or one down-stroke parser case insufficient to claim preservation of the exercise? Name the observations needed for a concrete next check.

> **Answer:** Capacity to store a direction does not demonstrate both directions being read, continued across bars or recovered after export. Use a pinned path with explicit D/U signs, an odd seven-attack bar, a rest with a declared counter policy and a tied continuation. Compare event identities, recovered directions and reset points; inspect score output and player execution separately. No successful round trip, preferred technique or physical playability was observed here.

The [fixed picking record](../../../../code/streeling/evidence/meter-picking-2026-10-22/picking-phase.json) keeps all policies and negative controls. [GTR-005](gtr-005-plan-which-string-keeps-ringing.md) separately checks string occupancy; a correct direction trace does not prove that a held-note assignment is feasible.
