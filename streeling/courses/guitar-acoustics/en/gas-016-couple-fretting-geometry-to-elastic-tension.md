---
module_id: gas-016-couple-fretting-geometry-to-elastic-tension
department: guitar-acoustics
course: "Couple Fretting Geometry to Elastic Tension"
level: advanced
prerequisites: ["gas-013-retune-with-an-explicit-tension-assumption"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Couple Fretting Geometry to Elastic Tension

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

Shortening a string and stretching it are coupled when contact displaces its path. A nominal half-length prediction can therefore differ from an elastic prediction even before stiffness dispersion is considered. This course builds a deliberately simple contact geometry for a [GA](https://github.com/GuitarAlchemist/ga) explanation. Its arbitrary dimensions are not specifications for setting up an instrument.

## Read the retained evidence

The elasticity source limits proportional stress and strain to a linear range. We replace a material specification with an explicitly authored axial spring. The prerequisite supplies the tension and length dependence; the retained engine’s frequency field does not measure either physical quantity.

[Prerequisite](../../guitar-acoustics/en/gas-013-retune-with-an-explicit-tension-assumption.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Primary reading](https://openstax.org/books/university-physics-volume-1/pages/12-3-stress-strain-and-elastic-modulus)

[Primary reading](https://www.phys.unsw.edu.au/jw/strings.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "length_m": 1,
    "midpoint_displacement_m": 0.01,
    "axial_stiffness_n_per_m": 1000,
    "initial_tension_n": 10,
    "linear_density_kg_per_m": 0.001
  },
  "formula": "segment=sqrt((L/2)^2+h^2); extension=2*segment-L; tension=T0+K*extension; f=sqrt(tension/mu)/(2*segment); ideal_f=sqrt(T0/mu)/L; cents=1200*log2(f/ideal_f)",
  "expected": {
    "extension_m": 0.0001999800039989008,
    "tension_n": 10.1999800039989,
    "ideal_f_hz": 100,
    "frequency_hz": 100.9747574562156,
    "error_cents": 16.79361678856818
  },
  "negative_control": {
    "values": {
      "length_m": 1,
      "midpoint_displacement_m": 0,
      "axial_stiffness_n_per_m": 1000,
      "initial_tension_n": 10,
      "linear_density_kg_per_m": 0.001
    },
    "expected": {
      "extension_m": 0,
      "tension_n": 10,
      "ideal_f_hz": 100,
      "frequency_hz": 100,
      "error_cents": 0
    }
  }
}
```

## Keep the geometric and constitutive assumptions separate

The path calculation is a geometric statement. The conversion from extension to tension is a constitutive assumption about the selected spring. A precise diagram can therefore coexist with an inaccurate material model. Keeping these steps separate lets a reviewer reject the spring calibration without discarding the useful observation that displacing contact changes the total path.

Linear density is held fixed here to isolate that coupling. An actual stretched string also redistributes its mass along a changed length, and contact can introduce friction or unequal segment tensions. A more detailed model would have to say how those effects are measured or approximated. Adding such details without input evidence would make the calculation longer while hiding rather than resolving uncertainty. The present result is deliberately conditional on its simpler assumptions.

The comparison frequency belongs to a projected half-length at the initial tension. It is not the open-string fundamental. Confusing those references would manufacture a much larger cent difference and misdiagnose the source of sharpening. Write the reference beside the ratio before evaluating logarithms. For a proposed GA explanation, the direct diagram plus equation is the baseline to preserve. A physical calibration would additionally need measured geometry, axial response and output pitch with uncertainties; changing a digital frequency field supplies none of those observations.

### Exercise 1

Find the displaced segment length and total extension. Why use both segments?

<details><summary>Answer 1</summary>

The string path contains the symmetric pair, although only one half is declared vibrating. Ignoring the other segment undercounts the total elastic extension.

</details>

### Exercise 2

Derive the new tension from extension and axial stiffness. Is the stiffness a Young modulus?

<details><summary>Answer 2</summary>

The displayed tension follows the declared spring law. Its stiffness has force-per-length units; a Young modulus would require area and reference length before becoming this coefficient.

</details>

### Exercise 3

Compare actual modeled frequency with the ideal half-length value. Which effects compete?

<details><summary>Answer 3</summary>

Extra tension raises the wave speed, while the displaced segment is longer than its projected half. Both enter the frequency formula; the stated net cent error follows this authored case.

</details>

### Exercise 4

Apply zero displacement. Which residual must vanish?

<details><summary>Answer 4</summary>

Extension, tension increment and cent error all vanish. A nonzero residual in this control rejects the geometry or reference arithmetic.

</details>

### Exercise 5

Can this calculation select a real action height or prove a GA control is physical?

<details><summary>Answer 5</summary>

No. Compliance, density change, contact location and material response need measurement. The retained software frequency parameter does not supply those inputs.

</details>

## Source-assisted learner task

Sketch both segments, derive the main and control values manually, then identify the software field that remains only a requested frequency. Write a falsifier based on a measured geometry and frequency discrepancy, with uncertainty stated before any proposed calibration.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
