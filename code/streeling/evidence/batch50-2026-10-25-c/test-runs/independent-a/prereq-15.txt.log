---
module_id: wml-019-distribute-onsets-with-a-floor-lattice
department: world-music-languages
course: "Distribute Onsets with a Floor Lattice"
level: advanced
prerequisites: ["wml-006-preserve-the-origin-of-an-additive-cycle"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distribute Onsets with a Floor Lattice

> Authored model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening result, engine render, parser execution or production adoption is claimed.

A rhythm-practice proposal asks for a fixed number of attacks spread across a pulse cycle. Merely preserving the total event count does not specify their spacing. We construct a floor-lattice pattern, inspect all cyclic gaps including the wrap, and apply a declared rotation. The prerequisite already checks whether a supplied grouping’s origin survives translation; this lesson supplies a new construction operation before the origin check.

Take each event index times the pulse count, divide by the event count and round downward. The resulting integer starts distribute the authored events on the grid. Then rotate every start by the same amount and reduce modulo the cycle. Sorting is appropriate for displaying the anchored cycle, while the original event identity would need separate retention if a performance task distinguished individual strokes.

Our verification criterion is deliberately limited to the largest and smallest cyclic gaps differing by at most a single pulse. Do not inflate it into a complete definition of musical evenness or a claim about a named rhythm tradition. The clustered control keeps counts and rotation but fails that criterion. Omitting the wrap gap would hide its largest empty interval. A direct circle drawing therefore provides a useful baseline for any rhythm-generation DSL or agent suggestion. The retained additive-cycle course motivates preserving origin, group order and cultural boundaries. No recording, culturally validated pattern or actual GA rhythm output supplied these authored events.

## Read the retained project evidence

The prerequisite supplies the earlier operation and its evidence boundary. Inspect the linked project artifact before using the authored case to propose a change. Its existing observations keep their original scope: a retained source file or fixture does not establish current deployment. The fixed packet records exact inputs, prepared outputs and reading provenance. Local file hashes identify complete bytes; they do not enlarge the bounded passage actually read. A primary web page supports only the specific definition read, with no invented immutable revision or byte hash.

[Prerequisite](../../world-music-languages/en/wml-006-preserve-the-origin-of-an-additive-cycle.md)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Fixed case and prepared quantities

```json
{
  "values": {
    "pulse_count": 8,
    "onset_count": 3,
    "rotation": 1,
    "policy": "floor_lattice",
    "supplied_onsets": null
  },
  "formula": "base[i]=floor(i*N/K) for i=0..K-1 in floor_lattice, else supplied_onsets; rotated=sorted((base+rotation)%N); gaps=cyclic differences including wrap; balanced=max(gaps)-min(gaps)<=1",
  "expected": {
    "base_onsets": [
      0,
      2,
      5
    ],
    "rotated_onsets": [
      1,
      3,
      6
    ],
    "cyclic_gaps": [
      2,
      3,
      3
    ],
    "balanced": true
  },
  "negative_control": {
    "values": {
      "pulse_count": 8,
      "onset_count": 3,
      "rotation": 1,
      "policy": "supplied",
      "supplied_onsets": [
        0,
        1,
        2
      ]
    },
    "expected": {
      "base_onsets": [
        0,
        1,
        2
      ],
      "rotated_onsets": [
        1,
        2,
        3
      ],
      "cyclic_gaps": [
        1,
        1,
        6
      ],
      "balanced": false
    }
  }
}
```

## Assumptions and evidence limits

Assume distinct integer onsets on a uniform cyclic grid and positive counts within capacity. The gap criterion includes wraparound. It is the declared local spacing test, not a complete musical-evenness theorem or a cultural attribution.

## Interpret the operation before choosing an abstraction

Before revealing the answer key, write the input contract in your own words and derive the main result manually. Keep intermediate quantities or state transitions, rather than copying only a final number. Compare the negative control under the same rule and identify the input that changed. The model is a finite authored example. A matching calculation supports this example’s stated claim; it does not supply an observed user outcome or validate a production feature.

### Exercise 1

Construct every unrotated onset using the floor rule.

<details><summary>Answer 1</summary>

Use each event index rather than repeatedly rounding a running sum; the fixed starts are listed above.

</details>

### Exercise 2

Apply the declared rotation without changing event count.

<details><summary>Answer 2</summary>

Add the rotation modulo the cycle to every start and sort the resulting distinct anchored positions.

</details>

### Exercise 3

Compute all cyclic gaps, including the final wrap.

<details><summary>Answer 3</summary>

The gaps sum to the pulse count and satisfy the displayed maximum-minus-minimum criterion in the main case.

</details>

### Exercise 4

Why does the clustered control fail?

<details><summary>Answer 4</summary>

Its wrap gap is much larger than its adjacent gaps despite identical cycle and event counts.

</details>

### Exercise 5

What falsifies a count-only rhythm-preservation claim?

<details><summary>Answer 5</summary>

Equal event counts with unequal cyclic gap patterns show that cardinality alone cannot reconstruct the spacing.

</details>

## Source-assisted learner task

Draw both onset circles before assistance. Draft a GA practice instruction retaining generator rule, rotation and cyclic gaps without assigning a tradition.

Retain your unaided answer before consulting a source or calculator. Then identify a precise source passage and revision, record every kind of assistance and keep the original answer alongside any correction. A proposed agent workflow or DSL must preserve the manual result and its countercase before its convenience can be assessed. If required inputs are absent, leave the decision unresolved rather than substituting a plausible value.

Write a falsifier as an observable disagreement with the stated rule, then say what additional observation would be needed at the next boundary. Use the exercise answers as prepared checks, not as a record of your attempt. The fixed packet contains a separate prepared criterion for every exercise; all learner decisions remain undecided until an actual response and review are retained. Report assistance, corrections and remaining limits with the final note so that arithmetic correctness is not confused with independent recall, musician judgment or runtime acceptance.
