---
module_id: gtr-015-sample-a-vibrato-without-erasing-its-motion
department: guitar-studies
course: "Sample a Vibrato Without Erasing Its Motion"
level: advanced
prerequisites: ["gtr-013-judge-a-bend-with-an-uncertainty-budget"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Sample a Vibrato Without Erasing Its Motion

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

A pitch trace that appears flat can hide motion between samples. For a [GA](https://github.com/GuitarAlchemist/ga) practice explanation, distinguish vibrato rate, cent extent and observation grid before judging whether a player sustained a fixed pitch. We author a continuous trajectory and inspect selected instants. Its extrema and its sampled values answer different questions.

## Read the retained evidence

The notation reference includes wavy-line playback attributes for ornaments. It does not make those fields our sinusoidal cents model. The retained intonation packet supplies a frequency-reference convention, not a vibrato performance.

[Prerequisite](../../guitar-studies/en/gtr-013-judge-a-bend-with-an-uncertainty-budget.md)

[Retained project artifact](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/wavy-line/)

[Primary reading](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

## Fixed case and prepared quantities

```json
{
  "values": {
    "base_hz": 440,
    "extent_cents": 25,
    "rate_hz": 2,
    "times_s": [
      0,
      0.125,
      0.25,
      0.375,
      0.5
    ]
  },
  "formula": "c(t)=extent*sin(2*pi*rate*t); f(t)=base*2^(c(t)/1200)",
  "expected": {
    "cents": [
      0,
      25,
      0,
      -25,
      0
    ],
    "period_s": 0.5,
    "peak_to_peak_cents": 50
  },
  "negative_control": {
    "values": {
      "base_hz": 440,
      "extent_cents": 25,
      "rate_hz": 4,
      "times_s": [
        0,
        0.125,
        0.25,
        0.375,
        0.5
      ]
    },
    "expected": {
      "cents": [
        0,
        0,
        0,
        0,
        0
      ],
      "period_s": 0.25,
      "peak_to_peak_cents": 50
    }
  }
}
```

## Specify a gesture before evaluating its sampled trace

Rate describes repetitions per elapsed time, while extent describes displacement around the pitch reference. A performer can change either quantity independently. The selected trajectory is symmetric in cents, which means its upper and lower frequencies are multiplicative reciprocals relative to the carrier. A chart symmetric in hertz would describe a different gesture. Name that coordinate before interpreting an average pitch or a peak excursion.

The sample times are observations of the trajectory, not a complete definition of it. In particular, the faster control cannot be reconstructed from its retained samples alone. A flat continuous pitch fits those samples too. Even knowledge of the sampling interval does not tell the receiver which continuous curve occurred without an additional bandwidth or model assumption. A confident motion label would therefore exceed the supplied evidence.

For a future tool, preserve the raw time-stamped estimates, estimator uncertainty and intended gesture separately. A graphical smooth line drawn between sparse points is an interpolation proposal, not a measured performance between them. The direct sketch should expose this gap before a DSL adds a vibrato instruction or an agent grades it. A denser trace could test the proposed motion, but real tracking must also distinguish pitch change from changing partial salience or an octave error.

### Exercise 1

Distinguish extent from peak-to-peak excursion in the main trajectory.

<details><summary>Answer 1</summary>

Extent is the one-sided cent amplitude. Peak-to-peak excursion is twice that value, as shown in the authored results; neither is a measurement of a player.

</details>

### Exercise 2

Evaluate the main trajectory at the declared times and identify its period.

<details><summary>Answer 2</summary>

The listed cent vector alternates through the positive and negative extrema. The period follows the reciprocal of the rate; it is independent of the carrier frequency.

</details>

### Exercise 3

How does the cent curve become a frequency curve?

<details><summary>Answer 3</summary>

Use the displayed exponential relationship. Adding a constant number of hertz instead would not preserve a symmetric cent excursion around the reference.

</details>

### Exercise 4

Apply the faster control. Does its all-zero sample vector prove no vibrato?

<details><summary>Answer 4</summary>

No. The observation grid lands on zero crossings, while the continuous extent remains unchanged. This is a concrete counterexample to inferring no motion from these samples.

</details>

### Exercise 5

What would reject a claim that this grid identifies vibrato extent?

<details><summary>Answer 5</summary>

Different continuous extents or rates compatible with the same sampled vector defeat identification. Retain sampling times, phase assumptions and a denser independent observation before scoring a performance.

</details>

## Source-assisted learner task

Sketch both continuous curves and mark the sample instants before using a calculator. Explain the control’s hidden motion, then propose a pitch-trace receipt for a future practice tool. Compare a direct manual plot with any notation or agent proposal; do not claim a recording was analyzed.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
