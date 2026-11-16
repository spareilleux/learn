---
module_id: wml-006-preserve-the-origin-of-an-additive-cycle
department: world-music-languages
course: "Preserve the Origin of an Additive Cycle"
level: intermediate
prerequisites: ["wml-003-term-preservation-and-cultural-review", "mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Preserve the Origin of an Additive Cycle

> **Draft scope.** Authored pulse groups, exact finite enumeration and primary specification/source reading. Human technical, cultural, musician, fluent-language and learner reviews and deployed course HTML verification remain pending. No recording, performed tradition, translation panel or audio tool was tested.

## The project question

A localized GA exercise preserves the numbers in an additive rhythm but changes which group starts the bar. Has it preserved the requested pattern? A circular pattern and an anchored practice instruction answer different questions. This lesson gives a reviewer a numerical witness for the change without claiming that any of these invented patterns belongs to a particular musical culture.

[MCL-006](../../musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md) separates grouping from total duration and metronome units. The [MusicXML time reference](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/time/) permits additive numerator text. It does not give a translator permission to change the starting point of an authored exercise or attribute its performance to a tradition.

## 1. Keep the bar origin attached

Define seven equally spaced eighth-pulse positions, numbered 0 through 6, and repeat the cycle. In the authored pattern A, group lengths are 2, 2, 3; the group starts are 0, 2, 4. Pattern B uses lengths 3, 2, 2 and starts 0, 3, 5. Pattern C uses lengths 2, 3, 2 and starts 0, 2, 5.

All three total seven pulses. At the fixed bar origin they request different starts. These starts are mathematical grouping markers, not observations of loudness, stress, syllables or a musician's timing. A translator can preserve them while adapting counting prose, but needs an explicit instruction before rebasing them.

### Practice exercise 1: locate a translated change

A source exercise requests A and its translation requests B, both starting at the same bar line. Give the start sets and state what was preserved and changed.

> **Answer:** A starts at 0, 2, 4; B at 0, 3, 5. The total seven-pulse cycle was preserved. The ordered groups and their anchored starts changed. Equal total duration is insufficient to call the translated instruction identical.

## 2. Rebase a circular pattern explicitly

Keep A's circular events but declare its old pulse 4 to be the new origin. Subtract 4 from every old start and reduce modulo 7. The new starts are 0, 3, 5, with successive circular gaps 3, 2, 2: this is B. Rebasing at old pulse 2 instead gives C.

This calculation explains a particular equivalence: the patterns have the same circular gap sequence up to a cyclic choice of group start. It does not make them interchangeable against an unchanged bar line, accompaniment, lyric or other track. Preserve both the chosen equivalence and the origin transformation when comparing records.

### Practice exercise 2: recover the origin transform

Which old A group start becomes B's origin? Calculate the new start set, then explain why silently applying that transform to just one track can change an arrangement.

> **Answer:** Old pulse 4 becomes the origin. Subtracting 4 modulo 7 from 0, 2, 4 gives 3, 5, 0, or sorted starts 0, 3, 5. Rebasing only one track changes its alignment to tracks and bar references that were not rebased. A circular comparison does not erase that relative phase.

## 3. Separate pulse rotations from group-start choices

There are seven possible integer pulse shifts of A. All seven yield distinct onset sets. Only three of those sets include pulse 0 as a group start, corresponding to the three choices of original group boundary. Shifting A forward by 1 gives starts 1, 3, 5: the cycle still repeats every seven pulses, but its new pulse 0 is not a group start.

The [enumeration record](../../../../code/streeling/evidence/meter-picking-2026-10-22/anchored-cycles.json) keeps the shifts and the separately labelled group-start rebases. Treating “three cyclic permutations of the group list” as “all seven pulse phases” would confuse two different sets of comparisons.

### Practice exercise 3: count the right transformations

How many distinct pulse shifts does A have? How many place a group start at pulse 0? Give the starts after a forward shift of 1.

> **Answer:** There are seven distinct shifts, and three include a group start at 0. The shift by 1 gives starts 1, 3, 5. A new origin need not coincide with a grouping event unless that condition is required separately.

## 4. State what a circular code classifies

Choose any three distinct onset positions among the seven labelled pulse positions. Exact enumeration gives 35 anchored sets. Comparing them only up to integer rotation partitions them into five classes, each containing seven sets. This is a finite combinatorial result for this authored population. It is not a distribution of rhythms in recordings or a taxonomy of five traditions.

The three-onset restriction matters. As negative controls, an empty set and a set containing all seven pulses each have only one distinct rotation. Therefore “every pattern has seven distinct phases” is false once the population changes. Labels, event multiplicities, unequal spacing or richer performance data would also define a different classification problem.

### Practice exercise 4: bound the classification

Give the number of anchored three-onset sets and rotation classes in this seven-pulse population. Why does the empty-pattern control reject a universal seven-phase claim, and why do the five classes establish no cultural classification?

> **Answer:** There are 35 anchored sets and five classes of seven. The empty pattern is unchanged by every shift and has only one distinct rotation. These classes come from selected abstract positions and a chosen equivalence, not from evidence about communities, repertoire, musicians or performance practice.

## 5. Preserve notation and attribution separately

The pinned [GA time representation](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L115-L138) keeps an integer numerator and denominator; it does not retain this lesson's ordered group list or origin transform in those fields. The [selected parser](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L123-L138) also has the additive-text boundary discussed in MCL-006. This does not prove that every GA subsystem lacks richer data.

### Practice exercise 5: write a localization receipt

What should a review record retain when a translator intentionally changes A to B? Can a matching circular code authorize a named cultural or musical-equivalence claim?

> **Answer:** Retain the original and translated ordered groups, pulse unit, common bar reference, old-origin-to-new-origin transform, affected tracks, reason and reviewer decision. The A-to-B example rebases at old pulse 4. Circular equality alone authorizes no cultural, perceptual or arrangement-equivalence claim. Such claims require appropriate repertoire, musician and language evidence; none was gathered here.

The [prepared learner task](../../../../code/streeling/evidence/meter-picking-2026-10-22/learner-task.md) asks for an explicit origin comparison. Its existence is not an observed learner or cultural review outcome.
