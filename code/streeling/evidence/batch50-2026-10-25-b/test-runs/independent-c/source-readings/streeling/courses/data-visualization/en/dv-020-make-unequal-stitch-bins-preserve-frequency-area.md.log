---
module_id: "dv-020-make-unequal-stitch-bins-preserve-frequency-area"
department: "data-visualization"
course: "Make Unequal Stitch Bins Preserve Frequency Area"
level: "advanced"
prerequisites: ["dv-011-retain-raw-counts-behind-normalized-heatmaps"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Make Unequal Stitch Bins Preserve Frequency Area

> Draft for technical and fluent-language review. The numerical inputs, labels and expected results are authored teaching cases. They are not new physical material tests, native scene runs, learner observations or production outcomes. Human and learner decisions remain undecided.

## Project operation and interpretation

An embroidery review groups stitch lengths into narrow short-stitch bins and wider long-stitch bins. Plotting raw counts as heights while retaining those unequal widths makes a wider rectangle look more frequent even when the counts match. The operation here assigns frequency to bar area and density to height. It changes what a chart encodes without changing any underlying stitch record or claiming that the illustrated counts came from IX.

Write every bin boundary before drawing rectangles. Divide each count by the total and then by its bin width. Multiplying the resulting height by the width recovers the relative frequency. The vertical unit is inverse length; it is not a percentage for the individual bar. A density can exceed unity when a narrow bin contains substantial mass, so a chart must not reject a height merely because it exceeds a probability bound.

The control changes counts so the density heights coincide while the areas differ. It challenges an assistant that summarizes tallest bars as most common ranges without checking width. For a proposed Learn craft dashboard, retain raw counts, edges, units, edge ownership and the normalized density together. Missing or excluded stitches need their own count outside this finite input. A histogram with a carefully labeled axis still cannot prove an acceptable stitch size, an unbroken fibre or successful learner recognition of a pattern.

Read the committed prerequisite and the scoped primary passage before calculating. Make a small ledger with separate columns for source definition, authored premise, derived result and future observation. A documentation page supports only the claim within its inspected scope. A source parameter, mathematical answer and runtime observation have different evidential roles; an assistant’s confident summary cannot exchange those roles. The evidence packet retains the source revision and the reading boundary so another reviewer can challenge a precise statement.

Work first with the answer panels closed. Draw the table or diagram required by this operation and retain the intermediate quantities, including units or identity conventions. That handwritten derivation is the direct manual baseline. Only then consult an assistant or translation aid. Keep the question, the source location cited, the suggestion received and the change accepted or rejected. Compare the assisted result with the retained first attempt on identical inputs. A shorter answer is not an improvement when it omits a precondition or invents a completed project trial.

## Fixed model and changed-input control

```json
{
  "values": {
    "edges_mm": [
      0,
      1,
      3
    ],
    "counts": [
      4,
      4
    ]
  },
  "formula": "width_i=edge[i+1]-edge[i]; N=sum(counts); density_i=count_i/(N*width_i); area_i=density_i*width_i",
  "expected": {
    "widths_mm": [
      1,
      2
    ],
    "sample_count": 8,
    "density_per_mm": [
      0.5,
      0.25
    ],
    "areas": [
      0.5,
      0.5
    ]
  },
  "negative_control": {
    "values": {
      "edges_mm": [
        0,
        1,
        3
      ],
      "counts": [
        4,
        8
      ]
    },
    "expected": {
      "widths_mm": [
        1,
        2
      ],
      "sample_count": 12,
      "density_per_mm": [
        0.3333333333333333,
        0.3333333333333333
      ],
      "areas": [
        0.3333333333333333,
        0.6666666666666666
      ]
    }
  }
}
```

### Exercise 1

Find bin widths and the denominator.

<details><summary>Answer 1</summary>

Widths are `[1,2] mm` and the total is `8`. The second interval is wider even though its raw count matches.

</details>

### Exercise 2

Calculate density heights.

<details><summary>Answer 2</summary>

They are `[0.5,0.25] per mm`. Each height divides relative frequency by the corresponding width, rather than merely dividing by the total.

</details>

### Exercise 3

Recover the encoded masses.

<details><summary>Answer 3</summary>

The areas are `[0.5,0.5]`, summing to `1`. Equal frequency does not require equal density when widths differ.

</details>

### Exercise 4

Interpret the changed-count control.

<details><summary>Answer 4</summary>

Both heights become `0.3333333333333333 per mm`, while masses are `[0.3333333333333333,0.6666666666666666]`. Equal height does not mean equal count.

</details>

### Exercise 5

May a density be read as exact-length failure probability?

<details><summary>Answer 5</summary>

No. It is mass per unit length over an interval. Failure labels, a continuous model and population evidence are not present.

</details>

## Source-assisted task and direct baseline

Draw two unequal rectangles by hand and label their raw count, width, height and area. Prepare an embroidery-dashboard caption and ask an assistant to challenge its use of the word frequency before adopting any chart DSL.

Treat the control as a separate input record. Preserve the main case, write a prediction for the changed input and explain which premise changes. When a result disagrees with your first answer, distinguish arithmetic error, interpretation error and a model limitation. Keep a failed attempt beside its correction rather than replacing it. The task asks for a reviewable evidence note before proposing a DSL node or agent workflow; a manual table may already meet the project need.

Submit the baseline, source locations, corrected explanation, control outcome and prospective falsifier together. The prepared criteria below are questions for a future reviewer, not accepted learner results. Actual learner answer, assistance history, corrected answer and learner decision remain empty until a real attempt is retained. Technical review, fluent-language review, runtime execution, production adoption and publication each require their own applicable evidence. A passing finite calculation would establish only the stated operation under its premises.

## Prospective falsifier

A caption equating the control’s equal bar heights with equal sample counts is refuted by its unequal masses.

## Prepared learner criteria

- For exercise 1: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 2: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 3: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 4: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 5: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: dv-011-retain-raw-counts-behind-normalized-heatmaps](../../data-visualization/en/dv-011-retain-raw-counts-behind-normalized-heatmaps.md)
- [Retained project source](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://www.itl.nist.gov/div898/handbook/eda/section3/histogra.htm)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
