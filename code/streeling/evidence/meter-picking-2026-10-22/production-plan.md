---
execution: knowledge-work
base_learn_commit: a1c02b0caa244c11106337380656902026b7a431
source_ga_commit: 76efbffd5af82b46c3146957a6bd4504008eeb89
---

# Preserve meter units, anchored additive groups and picking phase

Produce MCL006 (meter grouping versus duration and tempo unit), WML006 (anchored versus circular additive pattern and cultural attribution), GTR007 (pick direction across odd bars and rests), EN/FR/ES with five corrected exercises per module. Inspect pinned GA MIDI/rhythm and guitar notation boundaries identified by read-only source exploration. Read actual W3C MusicXML4 time/beat-unit and up/down-stroke definitions. Historical source/test text is not live playback or fresh implementation validation.

## Predictions before calculation

- An authored7/8 bar at quarter=120 lasts7/4seconds; eighth=120 makes it7/2seconds. With24divisions per quarter it spans84divisions. A2/4+3/8 composite also spans84divisions but explicitly separates4+3eighths, not automatically2+2+3. Equal total duration does not preserve grouping.
- Authored additive groups A=(2,2,3), B=(3,2,2), C=(2,3,2) have anchored starts{0,2,4},{0,3,5},{0,2,5} on a seven-pulse cycle. Rebasing A at its pulse4 boundary yields B; rebasing at2 yields C. The three group-start rotations share a circular gap pattern but differ at a fixed bar origin. All seven pulse rotations of the three-onset pattern are distinct. Pulse zero need not stay a group start after an arbitrary shift. Translation of counting prose must not silently choose another phase or invent a tradition/performer accent from these authored integers.
- Stipulate one attack at each eighth pulse with strict alternate D/U on consecutive attacks, starting D at absolute pulse0. Seven attacks per bar makes bar-start direction alternate D,U,D,U and restore after two bars14pulses. An independent authored four-pulse marker restores after28pulses relative to the seven-pulse bar; with D/U included the full state also restores at28. Resetting D at each bar creates consecutive D attacks across odd-length bar boundaries.
- Distinguish attack-driven alternation from an independently stipulated continuous eighth-motion clock. With one rest at within-bar pulse3, attack-driven alternation has six attacks per bar and starts each bar D; clock-driven motion still flips direction at that silent pulse and starts the next bar U. A tied continuation is not a new attack. These models do not establish a preferred technique, accent, timbre or player feasibility.

## Gates

Check exact rational unit calculations, grouping/rebase/orbit enumeration, picking traces including rests/tied continuation and phase state. Independently audit fixed data and pinned source bytes. Independently review45localized exercise-answer pairs and15prepared learner criteria. Preserve numeric/inline/fenced/URL parity andUTF8LFnoBOM. Run existing18generator tests, source sync, full Astro build, changed articles links and repeat-sync equality. Protect source.json and3journals; normal explicit-path commit/push to existing Draft201 only after reviewed hashes and branch/remote/PR-owner recheck; anonymous immutable public byte readback. Human, musician, fluent-language and learner reviews, actual playback/import/export and public deployed HTML stay unverified until observed. No new production code, runnable lab, audio renderer, dependency install, paid API or host test is emitted/run.
