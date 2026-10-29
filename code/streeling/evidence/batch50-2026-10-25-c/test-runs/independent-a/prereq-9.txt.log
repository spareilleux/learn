---
module_id: gas-018-account-for-energy-at-an-impedance-junction
department: guitar-acoustics
course: "Account for Energy at an Impedance Junction"
level: advanced
prerequisites: ["gas-011-track-reflection-polarity-at-string-boundaries"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Account for Energy at an Impedance Junction

> Authored model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening result, engine render, parser execution or production adoption is claimed.

A guitar-model review sees a transmitted amplitude larger than the incident amplitude and calls it an energy source. That conclusion forgets the impedance attached to the wave variable. Use a deliberately simple pressure-wave junction to distinguish amplitude ratios from energy fractions before borrowing scattering language for a bridge. This is a new accounting operation beyond the prerequisite’s displacement-sign boundary; the variables are intentionally different.

The primary reading derives continuity of pressure and flow at a junction with positive real impedances. In our authored case the pressure transmission ratio exceeds unity, while the transmitted power fraction remains below unity. Squaring the transmission amplitude without its impedance ratio would give an invalid balance. The reflected and transmitted fractions sum to the incoming fraction under the stated ideal conditions. Their signs and directions must be interpreted with the declared traveling-wave convention.

The matched control does more than lower an arbitrary gain: it changes the boundary relation so that reflection vanishes. It does not silence the downstream wave. This distinction matters when a review proposes damping a return path by manipulating a transmission setting. Actual guitar bridges have more complicated interactions, and the current course supplies no measured impedance curve or calibrated coupling parameter. A direct table of pressure and weighted power is the required baseline before any scattering-node DSL proposal. Preserve the variable type instead of converting this result into a displacement-boundary rule.

## Read the retained project evidence

The prerequisite supplies the earlier operation and its evidence boundary. Inspect the linked project artifact before using the authored case to propose a change. Its existing observations keep their original scope: a retained source file or fixture does not establish current deployment. The fixed packet records exact inputs, prepared outputs and reading provenance. Local file hashes identify complete bytes; they do not enlarge the bounded passage actually read. A primary web page supports only the specific definition read, with no invented immutable revision or byte hash.

[Prerequisite](../../guitar-acoustics/en/gas-011-track-reflection-polarity-at-string-boundaries.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Primary reading](https://www.dsprelated.com/freebooks/pasp/Scattering_Impedance_Changes.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "incident_pressure": 1,
    "impedance_left": 1,
    "impedance_right": 3
  },
  "formula": "r=(Z2-Z1)/(Z1+Z2); t=1+r; reflected_fraction=r^2; transmitted_fraction=(Z1/Z2)*t^2; total=reflected_fraction+transmitted_fraction",
  "expected": {
    "pressure_reflection": 0.5,
    "pressure_transmission": 1.5,
    "reflected_fraction": 0.25,
    "transmitted_fraction": 0.75,
    "total": 1
  },
  "negative_control": {
    "values": {
      "incident_pressure": 1,
      "impedance_left": 1,
      "impedance_right": 1
    },
    "expected": {
      "pressure_reflection": 0,
      "pressure_transmission": 1,
      "reflected_fraction": 0,
      "transmitted_fraction": 1,
      "total": 1
    }
  }
}
```

## Assumptions and evidence limits

Assume normal plane-wave incidence, real positive impedances and a lossless junction without stored state. No wave arrives from the right. Pressure ratios here must not be substituted for the prerequisite’s string-displacement ratios.

## Interpret the operation before choosing an abstraction

Before revealing the answer key, write the input contract in your own words and derive the main result manually. Keep intermediate quantities or state transitions, rather than copying only a final number. Compare the negative control under the same rule and identify the input that changed. The model is a finite authored example. A matching calculation supports this example’s stated claim; it does not supply an observed user outcome or validate a production feature.

### Exercise 1

Derive the pressure reflection and transmission ratios.

<details><summary>Answer 1</summary>

Use the impedance difference over its sum for reflection, then add unity for pressure transmission under this convention.

</details>

### Exercise 2

Why is transmitted amplitude above unity not an energy violation?

<details><summary>Answer 2</summary>

The transmitted power uses the impedance ratio as well as squared pressure; amplitude alone is not a power fraction.

</details>

### Exercise 3

Check the complete power balance.

<details><summary>Answer 3</summary>

The displayed reflected and transmitted fractions sum to the full incoming fraction for the lossless junction.

</details>

### Exercise 4

What happens in the matched control?

<details><summary>Answer 4</summary>

Reflection vanishes while the pressure and power pass through under the matched boundary.

</details>

### Exercise 5

What rejects an unqualified guitar-bridge interpretation?

<details><summary>Answer 5</summary>

Missing wave-variable identity or a missing measured impedance model prevents carrying this plane-wave result into a calibrated bridge claim.

</details>

## Source-assisted learner task

Annotate a proposed GA scattering diagram with wave-variable types and a weighted-power ledger. Keep the matched boundary as a required countercase.

Retain your unaided answer before consulting a source or calculator. Then identify a precise source passage and revision, record every kind of assistance and keep the original answer alongside any correction. A proposed agent workflow or DSL must preserve the manual result and its countercase before its convenience can be assessed. If required inputs are absent, leave the decision unresolved rather than substituting a plausible value.

Write a falsifier as an observable disagreement with the stated rule, then say what additional observation would be needed at the next boundary. Use the exercise answers as prepared checks, not as a record of your attempt. The fixed packet contains a separate prepared criterion for every exercise; all learner decisions remain undecided until an actual response and review are retained. Report assistance, corrections and remaining limits with the final note so that arithmetic correctness is not confused with independent recall, musician judgment or runtime acceptance.
