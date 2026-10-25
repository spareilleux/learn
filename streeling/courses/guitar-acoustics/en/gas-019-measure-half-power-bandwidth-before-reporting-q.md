---
module_id: gas-019-measure-half-power-bandwidth-before-reporting-q
department: guitar-acoustics
course: "Measure Half-Power Bandwidth before Reporting Q"
level: advanced
prerequisites: ["gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Measure Half-Power Bandwidth before Reporting Q

> Authored model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening result, engine render, parser execution or production adoption is claimed.

A GA body-filter explanation reports a resonance center and calls its response narrow, without giving a width. The center alone cannot answer how selective the response is. We introduce a normalized power curve and derive the frequencies at which it falls to half its maximum. This is a width-measurement exercise, distinct from locating a pole or a spectral peak in the prerequisite.

The authored curve is chosen so that its crossing calculation can be solved directly. The listed samples include the center and both exact half-power edges; no interpolation algorithm is hidden in the answer. If a measured curve missed those crossings, a future analyst would need a declared estimator and frequency resolution. A sparse plot cannot create precision that its data do not support.

The control retains the same center and maximum while broadening the response. Its normalized samples share the same values at differently spaced frequencies, illustrating why axis labels belong with the array. The resulting bandwidth ratio changes even though a peak-only summary would report no change. Half amplitude would be a different threshold from half power and would select different edges on this curve. For this lesson Q is the declared center-to-bandwidth quotient; converting it into damping time, material loss or the engine’s pole radius would require a compatible physical or discrete-time model. The retained filter discussion supplies a concrete project boundary, not those missing equivalences.

## Read the retained project evidence

The prerequisite supplies the earlier operation and its evidence boundary. Inspect the linked project artifact before using the authored case to propose a change. Its existing observations keep their original scope: a retained source file or fixture does not establish current deployment. The fixed packet records exact inputs, prepared outputs and reading provenance. Local file hashes identify complete bytes; they do not enlarge the bounded passage actually read. A primary web page supports only the specific definition read, with no invented immutable revision or byte hash.

[Prerequisite](../../guitar-acoustics/en/gas-007-distinguish-body-poles-from-string-partials.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Fixed case and prepared quantities

```json
{
  "values": {
    "center_hz": 100,
    "halfwidth_hz": 5,
    "frequencies_hz": [
      90,
      95,
      100,
      105,
      110
    ]
  },
  "formula": "P(f)=1/(1+((f-f0)/b)^2); half_power_edges=[f0-b,f0+b]; bandwidth=2*b; Q=f0/bandwidth",
  "expected": {
    "relative_power": [
      0.2,
      0.5,
      1,
      0.5,
      0.2
    ],
    "half_power_edges_hz": [
      95,
      105
    ],
    "bandwidth_hz": 10,
    "Q": 10
  },
  "negative_control": {
    "values": {
      "center_hz": 100,
      "halfwidth_hz": 10,
      "frequencies_hz": [
        80,
        90,
        100,
        110,
        120
      ]
    },
    "expected": {
      "relative_power": [
        0.2,
        0.5,
        1,
        0.5,
        0.2
      ],
      "half_power_edges_hz": [
        90,
        110
      ],
      "bandwidth_hz": 20,
      "Q": 5
    }
  }
}
```

## Assumptions and evidence limits

Assume an isolated authored power curve with positive halfwidth and exact continuous crossings. Its Q is defined by the displayed quotient. No physical oscillator fit or discrete pole-radius conversion is implied.

## Interpret the operation before choosing an abstraction

Before revealing the answer key, write the input contract in your own words and derive the main result manually. Keep intermediate quantities or state transitions, rather than copying only a final number. Compare the negative control under the same rule and identify the input that changed. The model is a finite authored example. A matching calculation supports this example’s stated claim; it does not supply an observed user outcome or validate a production feature.

### Exercise 1

Locate the exact half-power edges in the main case.

<details><summary>Answer 1</summary>

Set the normalized power to half its peak; the edges lie one declared halfwidth on either side of the center.

</details>

### Exercise 2

Compute the full bandwidth and its Q quotient.

<details><summary>Answer 2</summary>

Subtract the two edges, then divide the center frequency by that full width, as displayed in the fixed case.

</details>

### Exercise 3

Why must the ordinate say power rather than amplitude?

<details><summary>Answer 3</summary>

Taking a half-amplitude threshold on this curve would change the selected frequencies and the reported width.

</details>

### Exercise 4

What does the broader control preserve and change?

<details><summary>Answer 4</summary>

It preserves center and maximum but doubles bandwidth and halves the declared Q quotient.

</details>

### Exercise 5

What falsifies a peak-only sharpness report?

<details><summary>Answer 5</summary>

The equal-center, unequal-width pair demonstrates that the peak center alone cannot determine this Q.

</details>

## Source-assisted learner task

Prepare a proposed resonance report with both axes, threshold type and crossing rule. Leave any conversion to the GA filter coefficients unresolved.

Retain your unaided answer before consulting a source or calculator. Then identify a precise source passage and revision, record every kind of assistance and keep the original answer alongside any correction. A proposed agent workflow or DSL must preserve the manual result and its countercase before its convenience can be assessed. If required inputs are absent, leave the decision unresolved rather than substituting a plausible value.

Write a falsifier as an observable disagreement with the stated rule, then say what additional observation would be needed at the next boundary. Use the exercise answers as prepared checks, not as a record of your attempt. The fixed packet contains a separate prepared criterion for every exercise; all learner decisions remain undecided until an actual response and review are retained. Report assistance, corrections and remaining limits with the final note so that arithmetic correctness is not confused with independent recall, musician judgment or runtime acceptance.
