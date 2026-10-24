---
module_id: "cs-020-audit-evidence-join-multiplicity"
department: "computer-science"
course: "Audit Evidence Join Multiplicity"
level: "intermediate"
prerequisites: ["cs-008-compose-exact-source-review-verdicts", "inf-010-keep-joint-outcomes-when-composing-verdicts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Audit Evidence Join Multiplicity

> This lesson uses an authored fixed case and inspected sources. Counts, times, labels and signals are invented teaching inputs. Human technical review, fluent-language review, actual learner attempts, runtime execution, production adoption and publication decisions remain undecided.

An agent combines a review table with a test table and reports the joined row count as the number of validated artifacts. A join can produce more rows than either input because every matching pair survives. The exact-source review prerequisite asks whether receipts name the right bytes; the joint-outcome prerequisite asks what paired verdicts preserve. This course adds a different issue: the multiplicity introduced when several receipts share a key.

Write the matching review/check pairs for each artifact before counting. The artifact with several reviews and several checks produces their Cartesian combinations. Those rows can be useful for navigation, but they are not separate artifacts, additional reviewers or independent test runs. Flattening the join and then calculating a pass percentage can silently weight artifacts according to how many receipts they have.

[SQLite](https://www.sqlite.org/lang_select.html)’s SELECT documentation defines joins through a Cartesian product followed by constraints. Our fixed tables use that mathematical bag interpretation without running a database. The Learn helper instead keeps a set of module keys. Reading the set insertion shows another representation with another counting meaning: membership does not preserve the combinations needed for a receipt audit. Neither representation is universally preferable; the project question determines the unit being counted.

[W3C](https://www.w3.org/TR/2013/REC-prov-dm-20130430/) provenance distinguishes entities, activities and their relations. Keep the original receipt identities attached to joined rows so a reviewer can recover that distinction. The changed-input control removes a check while preserving artifact coverage. If a report claims that the same artifacts vanished merely because its row count fell, it confuses multiplicity with coverage. A proposed DSL join should state its key, row semantics and aggregation unit before an agent produces a status sentence.

## Sources and project boundary

Read the prerequisite before using the model. Inspect the linked retained project artifact at the revision recorded in the packet, and identify the field or branch that supports the stated source observation. The source gives a representation or declared behavior; it does not turn the invented case into an observed project result. The primary reading supplies the named concept within its stated scope.

[Prerequisite: cs-008-compose-exact-source-review-verdicts](../../computer-science/en/cs-008-compose-exact-source-review-verdicts.md)

[Prerequisite: inf-010-keep-joint-outcomes-when-composing-verdicts](../../information-theory/en/inf-010-keep-joint-outcomes-when-composing-verdicts.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading: SQLite SELECT documentation, section 2.1, read 2026-10-24](https://www.sqlite.org/lang_select.html)

[Primary reading: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

## Fixed model and control

```json
{
  "values": {
    "left": [
      {
        "artifact": "a",
        "review": "r1"
      },
      {
        "artifact": "a",
        "review": "r2"
      },
      {
        "artifact": "b",
        "review": "r3"
      }
    ],
    "right": [
      {
        "artifact": "a",
        "check": "t1"
      },
      {
        "artifact": "a",
        "check": "t2"
      },
      {
        "artifact": "b",
        "check": "t3"
      }
    ]
  },
  "formula": "Inner equality join on artifact emits every matching row pair; count rows and distinct artifact keys separately.",
  "expected": {
    "joined_rows": 5,
    "distinct_artifacts": 2,
    "rows_per_artifact": {
      "a": 4,
      "b": 1
    }
  },
  "negative_control": {
    "values": {
      "left": [
        {
          "artifact": "a",
          "review": "r1"
        },
        {
          "artifact": "a",
          "review": "r2"
        },
        {
          "artifact": "b",
          "review": "r3"
        }
      ],
      "right": [
        {
          "artifact": "a",
          "check": "t1"
        },
        {
          "artifact": "b",
          "check": "t3"
        }
      ]
    },
    "expected": {
      "joined_rows": 3,
      "distinct_artifacts": 2,
      "rows_per_artifact": {
        "a": 2,
        "b": 1
      }
    },
    "why": "Removing one check changes join multiplicity without changing artifact coverage."
  },
  "assumptions": [
    "Bag semantics; exact equality on retained artifact key.",
    "Review rows and check rows are not assumed independent trials."
  ],
  "limits": "Artifact key is simplified; real matching also requires revision and scope. No query or production data was executed."
}
```

### Exercise 1

Enumerate how many joined rows each artifact contributes.

<details><summary>Answer 1</summary>

Artifact `a` contributes `4` pairs and `b` contributes `1`, giving `5` joined rows. Each review of an artifact pairs with each check of that artifact; this is not one row per artifact.

</details>

### Exercise 2

How many distinct artifacts are represented, and does the joined count prove independent review?

<details><summary>Answer 2</summary>

There are `2` distinct artifacts. A joined row repeats source receipts in several combinations. It supplies no new reviewer identity, independence guarantee or executed test beyond those original receipts.

</details>

### Exercise 3

Apply the control that removes one check. What changes and what stays equal?

<details><summary>Answer 3</summary>

The joined count becomes `3`, with `2` rows for `a` and `1` for `b`. Distinct artifacts remain `2`. Multiplicity changes while coverage under this key remains unchanged.

</details>

### Exercise 4

Why can taking a percentage over joined rows distort an artifact-level summary?

<details><summary>Answer 4</summary>

An artifact with more matching receipts receives more weight. Define whether the denominator is artifacts, reviews, checks or joined pairs before aggregating. A correct row calculation cannot repair an unstated counting unit.

</details>

### Exercise 5

What must be added before applying this simplified key to exact-source evidence?

<details><summary>Answer 5</summary>

Retain source revision and receipt scope along with artifact identity, then check the intended matching relation manually. This table does not authorize matching different revisions or promote a declaration into a runtime observation.

</details>

## Source-assisted learner task

Start with a paper table before revealing the answers. Copy the inputs and their units, apply the declared operation, and retain intermediate results. This direct calculation is the manual baseline against which an assistant or a proposed composable notation must be compared. A shorter response has no demonstrated advantage if it loses an input identity, a failure category or the counterexample.

Then inspect the precise source passage recorded in the packet. Quote only the small field or branch needed for your explanation and record its revision. Ask an assistant to challenge one assumption after you have saved your first answer. Retain the prompt, reply, accepted corrections and rejected suggestions. Source lookup and calculator use are allowed; record them as assistance so the result cannot be mistaken for unaided recall.

Apply the changed input in the negative control and state an observable falsifier before making a recommendation. An unexpected control result requires checking the calculation and assumptions before changing a project workflow. Submit the original answer, corrected answer, assistance history and remaining uncertainty together. The packet prepares five learner criteria, one per exercise, with undecided decisions. Prepared solutions and author checks do not fill those decisions. A future dogfood comparison needs actual attempts on the same task and a retained manual baseline; no new agent mechanism or DSL implementation is required by this lesson.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
