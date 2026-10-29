---
module_id: gtr-017-check-contact-continuity-during-finger-substitution
department: guitar-studies
course: "Check Contact Continuity During Finger Substitution"
level: advanced
prerequisites: ["gtr-011-test-barre-coverage-before-calling-a-shape-playable"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Check Contact Continuity During Finger Substitution

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

A held note may keep the same string and fret while its supporting finger changes. A pitch-only plan hides whether the replacement arrives before the original finger leaves. For [GA](https://github.com/GuitarAlchemist/ga) practice instructions, we check the contact timeline before calling a substitution continuous. This adds a time condition to static fingering geometry.

## Read the retained evidence

The retained occupancy packet tracks musical events on strings. It does not describe individual finger contact. Use its explicit event boundary as a prompt to keep a separate contact ledger; the proposed ledger is teaching material rather than a changed project schema.

[Prerequisite](../../guitar-studies/en/gtr-011-test-barre-coverage-before-calling-a-shape-playable.md)

[Retained project artifact](../../../../code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

## Fixed case and prepared quantities

```json
{
  "values": {
    "required_interval_s": [
      0,
      1
    ],
    "contacts": [
      {
        "finger": "index",
        "interval_s": [
          0,
          0.6
        ]
      },
      {
        "finger": "ring",
        "interval_s": [
          0.5,
          1
        ]
      }
    ]
  },
  "formula": "merge half-open contact intervals at the same string/fret; gaps=required_interval minus union; overlap=max(0,min(ends)-max(starts)); continuous=(gaps empty)",
  "expected": {
    "union_s": [
      [
        0,
        1
      ]
    ],
    "gaps_s": [],
    "overlap_s": 0.1,
    "continuous": true
  },
  "negative_control": {
    "values": {
      "required_interval_s": [
        0,
        1
      ],
      "contacts": [
        {
          "finger": "index",
          "interval_s": [
            0,
            0.6
          ]
        },
        {
          "finger": "ring",
          "interval_s": [
            0.7,
            1
          ]
        }
      ]
    },
    "expected": {
      "union_s": [
        [
          0,
          0.6
        ],
        [
          0.7,
          1
        ]
      ],
      "gaps_s": [
        [
          0.6,
          0.7
        ]
      ],
      "overlap_s": 0,
      "continuous": false
    }
  }
}
```

## Treat substitution as a contact handoff

The musical event and the finger event have different identities. Keeping the former stable does not imply that the latter is continuous. Conversely, a finger change does not necessarily request another note onset. This distinction matters when a practice instruction frees one finger for the next chord while asking the current note to continue. The timeline must explain the overlap rather than infer it from the unchanged target pitch.

The declared half-open intervals make boundary handling explicit. A replacement starting exactly when the original contact ends would have no modeled gap, although it would also have no positive overlap margin. Whether that boundary is reliable for a player is another question. Timing uncertainty could turn an apparently exact handoff into a gap, so a real task would retain estimated contact times or a deliberate overlap margin rather than treating this ideal schedule as measured technique.

Our union operation ignores competing demands on either finger. A finger may need to release elsewhere before it can provide the proposed contact, and the same string position can still buzz despite continuous nominal coverage. Those missing constraints limit the result to a necessary schedule check. The manual ledger is sufficient to reject the delayed control. Only after it passes should a proposed planner combine finger availability, reach and observed clean sustain; no such planner or performance is delivered here.

### Exercise 1

Identify what stays fixed and what changes in the main ledger.

<details><summary>Answer 1</summary>

The intended string, fret and held-note interval stay fixed; finger identity changes. A pitch list alone has no field that can express this handoff.

</details>

### Exercise 2

Merge the contact intervals. Is every required instant covered?

<details><summary>Answer 2</summary>

The main union covers the required half-open interval. The overlap provides simultaneous modeled contact during the substitution rather than a new musical attack.

</details>

### Exercise 3

Calculate overlap duration. Does overlap prove clean sound?

<details><summary>Answer 3</summary>

The duration is listed above. It establishes scheduled contact coexistence only; pressure and contact quality were not specified or measured.

</details>

### Exercise 4

Apply the delayed control and locate its uncovered interval.

<details><summary>Answer 4</summary>

The displayed gap breaks continuity despite unchanged pitch labels. A checker that compares only target notes cannot distinguish this failure.

</details>

### Exercise 5

What would falsify a claimed continuous contact plan?

<details><summary>Answer 5</summary>

Any uncovered portion of the required interval rejects the schedule. Observed buzz or interruption could separately reject physical success even when this necessary condition passes.

</details>

## Source-assisted learner task

Draw both timelines manually before consulting answers. Compare musical-event occupancy with finger contact, then propose the smallest additional handoff record. Retain the gap control and distinguish a failed schedule from a failed performance; neither performance has been attempted.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
