---
module_id: gas-013-retune-with-an-explicit-tension-assumption
department: guitar-acoustics
course: "Retune with an Explicit Tension Assumption"
level: intermediate
prerequisites: ["gas-009-estimate-tuning-error-from-integer-delay-length"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Retune with an Explicit Tension Assumption

> Authored example and source reading. No new guitar performance, audio or parser execution, participant response or production adoption is claimed. Human technical, fluent-language and learner decisions remain pending.

A digital engine accepts a frequency parameter, while a physical guitar changes pitch through length, tension and mass distribution. Treating those operations as interchangeable hides assumptions. A project explanation of retuning should identify which physical quantity remains fixed before predicting load. We use an authored ideal string to derive a tension ratio and then deliberately change length. The calculation is an explanatory analogue for GA controls, not advice to apply a particular load to an instrument.

## Read the retained evidence

The retained voice state stores frequency and delay-related quantities. It does not turn the requested frequency into a measured physical string tension. OpenStax derives string wave speed from tension divided by linear density. Combined with the fixed-end fundamental relation, this gives the model below. The prerequisite studied integer digital delay; the new boundary here is the meaning of a physical retuning claim.

[Prerequisite](../../guitar-acoustics/en/gas-009-estimate-tuning-error-from-integer-delay-length.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Primary reading](https://openstax.org/books/university-physics-volume-1/pages/16-3-wave-speed-on-a-stretched-string)

### Exercise 1

Use length `0.5 m`, linear density `0.008 kg/m` and initial tension `80 N`. Wave speed is `sqrt(T0/mu)`, and fundamental frequency is that speed divided by `2*L`. Calculate with consistent SI units rather than inserting a millimetre length into a metre expression. The deliberately simple parameters are teaching inputs, not measurements of a named string.

What is the initial fundamental frequency?

<details><summary>Answer 1</summary>

It is `100 Hz` under `initial_f=sqrt(T0/mu)/(2*L)`. This describes the authored ideal string, not a measured guitar note.

</details>

### Exercise 2

Request a target of `150 Hz` while holding length and linear density fixed. Solving the same relation gives `target_T=mu*(2*L*target_f)^2`, so target tension is `180 N`. The square is essential: a frequency multiplier does not act as a linear tension multiplier. A digital control need not expose this mechanical interpretation at all.

What target tension follows from these fixed assumptions?

<details><summary>Answer 2</summary>

The target is `180 N`. Frequency rises by a factor `1.5`, while tension rises by its square, `2.25`, for this fixed length and density.

</details>

### Exercise 3

The load increase is `100 N`, obtained from `180-80`. Knowing that difference does not supply allowable stress: cross-sectional area, material behavior, construction and instrument limits were not supplied. A course or agent should retain that unresolved boundary instead of translating a valid mathematical prediction into a safe operating instruction.

May the computed tension certify that this retuning is safe?

<details><summary>Answer 3</summary>

No. The model predicts `180 N` and an increase of `100 N`; it supplies no material or instrument acceptance evidence. Mechanical feasibility and safety remain unresolved.

</details>

### Exercise 4

For the negative control, set the vibrating length to `1/3 m`, retaining density `0.008 kg/m`, tension `80 N` and target `150 Hz`. The initial frequency is already `150 Hz`, and required target tension remains `80 N`. This falsifies a universal claim that reaching the target always requires the earlier tension multiplier.

What changes when the length assumption changes?

<details><summary>Answer 4</summary>

The control needs `80 N`, with ratio `1`, because shortening the length already gives `150 Hz`. The earlier `2.25` ratio was conditional on the original length.

</details>

### Exercise 5

A guitarist fretting a note and a musician retuning an open string change different parts of this model. Real fretting can also alter tension slightly, and wound strings are not perfectly uniform ideal media. A future engine comparison should therefore state which idealization its parameter intends to represent and measure the resulting pitch separately from any inferred physical mechanism.

What observation would reject the fixed-length tension prediction?

<details><summary>Answer 5</summary>

Under verified unchanged length and density, an observed frequency inconsistent with the square-root relation beyond a declared uncertainty would reject this ideal prediction. Without those controls, the result cannot isolate tension as the cause.

</details>

## Source-assisted learner task

Prepare a note explaining a frequency control to a guitarist. Derive the original and shortened-length cases manually and label all units. Inspect the retained frequency/delay fields and distinguish their software meaning from physical load. State a falsifying measurement and the additional material evidence needed before making an actual retuning recommendation. Do not substitute the authored parameters for an instrument specification.

First retain your answer before revealing the prepared corrections. Use the manual table or calculation as the baseline for any calculator, source lookup or agent assistance, and record that assistance. Keep the original response and the corrected response separately. Match each exercise to a prepared criterion in the fixed packet; those criteria have no learner decisions yet. Record an actual source passage and its revision, then distinguish what it establishes from your proposed next step. Report any missing input as unresolved. A mathematically correct answer supports the stated example; human review, runtime execution and learner acceptance require their own retained observations.
