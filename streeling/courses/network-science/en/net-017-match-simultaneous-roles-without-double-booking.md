---
module_id: "net-017-match-simultaneous-roles-without-double-booking"
department: "network-science"
course: "Match Simultaneous Roles without Double Booking"
title: "Match Simultaneous Roles without Double Booking"
level: "intermediate"
prerequisites: ["net-003-worker-lane-coverage-and-fragility", "net-014-bound-throughput-with-a-capacity-cut"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Match Simultaneous Roles without Double Booking

> This is an authored mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A Demerzel capability table gives every requested role at least one named candidate. A coordinator then assumes the roles can all run together. That inference double-books a worker when several roles have only the same candidate. The earlier coverage course counts available routes per class; this lesson asks whether distinct workers can occupy all simultaneous roles.

Draw a bipartite graph with roles on one side and workers on the other. An edge means the declared worker may fill that role. A matching uses no vertex twice. To show feasibility, write the complete matching. To show infeasibility, find a subset of roles whose combined candidate set is smaller than the subset. Those roles cannot receive distinct workers, regardless of how flexible unrelated roles are.

In the fixed case, drafting and review each have a candidate but share the same sole candidate. The translation role has alternatives, which do not repair that obstruction. The control adds a review edge and permits a full assignment. Retain both the assignment witness and the deficient subset; a headline count of covered roles loses the reason that the first case fails.

NetworkX documents maximum-cardinality bipartite matching. Our tiny example is solved by inspection and explicit neighbour counting, without installing or executing the package. The throughput prerequisite concerns capacities across a network; here worker exclusivity and role identity are the central contract. Real human review may additionally require independence, expertise and consent. Candidate declarations do not establish any of those conditions. A future agent scheduler must preserve such constraints before treating this finite matching as permission to dispatch work.

## Sources and project boundary

The retained Learn helper separates metadata, title and body, and indexes English module identities. Inspect that representation when naming the artifact and its revision. It does not implement this lesson’s model or supply its invented inputs.

[Prerequisite: net-003-worker-lane-coverage-and-fragility](../../network-science/en/net-003-worker-lane-coverage-and-fragility.md)

[Prerequisite: net-014-bound-throughput-with-a-capacity-cut](../../network-science/en/net-014-bound-throughput-with-a-capacity-cut.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.bipartite.matching.maximum_matching.html)

## Fixed model and negative control

```json
{
  "values": {
    "candidates": {
      "draft": [
        "w1"
      ],
      "review": [
        "w1"
      ],
      "translate": [
        "w2",
        "w3"
      ]
    }
  },
  "formula": "Choose injective role-to-worker assignments over candidate edges, allowing unfilled roles. Maximize assigned count, then choose lexicographically smallest sorted [role,worker] list. For each role subset U compute neighbours N(U); deficient if len(N(U))<len(U). Choose obstruction by smallest subset size, then lexical role list.",
  "expected": {
    "all_roles_covered": true,
    "maximum_count": 2,
    "matching": [
      [
        "draft",
        "w1"
      ],
      [
        "translate",
        "w2"
      ]
    ],
    "obstruction": {
      "roles": [
        "draft",
        "review"
      ],
      "workers": [
        "w1"
      ],
      "deficiency": 1
    }
  },
  "negative_control": {
    "values": {
      "candidates": {
        "draft": [
          "w1"
        ],
        "review": [
          "w1",
          "w2"
        ],
        "translate": [
          "w2",
          "w3"
        ]
      }
    },
    "expected": {
      "all_roles_covered": true,
      "maximum_count": 3,
      "matching": [
        [
          "draft",
          "w1"
        ],
        [
          "review",
          "w2"
        ],
        [
          "translate",
          "w3"
        ]
      ],
      "obstruction": null
    },
    "why": "An extra review candidate removes the bottleneck and permits distinct workers for every role."
  },
  "input_types": {
    "candidates": "mapping of role strings to unique worker-string lists"
  },
  "assumptions": [
    "Each role requires one worker and each worker occupies at most one role in this simultaneous window.",
    "Candidate edges are hypothetical admissibility declarations, not live staffing or trust evidence."
  ],
  "limits": "A matching is a finite allocation witness, not authority, competence validation, independent human review or an actual dispatched fleet."
}
```

### Exercise 1

Does marginal coverage pass?

<details><summary>Answer 1</summary>

Yes: every role has at least one candidate, so coverage is `true`. This says nothing yet about distinct simultaneous assignments.

</details>

### Exercise 2

Find the allocation obstruction.

<details><summary>Answer 2</summary>

Roles `[draft,review]` have neighbours `[w1]`, giving deficiency `1`. No injective assignment can fill both roles in the same window.

</details>

### Exercise 3

Give a maximum fixed matching.

<details><summary>Answer 3</summary>

The declared tie rule selects `[[draft,w1],[translate,w2]]`, with size `2`. Leaving review unfilled is explicit; silently reusing the drafting worker would violate exclusivity.

</details>

### Exercise 4

Apply the extra-edge control.

<details><summary>Answer 4</summary>

The full matching is `[[draft,w1],[review,w2],[translate,w3]]`, with size `3`; the deficient-subset field is `null`. All worker identities remain distinct.

</details>

### Exercise 5

Does a matching prove independent review?

<details><summary>Answer 5</summary>

No. Distinct identifiers do not establish distinct humans, independent sources, expertise or authorization. Add those constraints explicitly and retain their evidence before dispatch.

</details>

## Source-assisted learner task

Review a simultaneous-role proposal for a fictional Demerzel course-production window.

**Direct manual baseline:** Draw candidate edges, construct an injective assignment or count a deficient role subset.

**Falsifier:** The proposal fills every role only by assigning one worker twice in the same window.

Save a first answer before opening the solutions. Identify the input types, the comparison boundary and the quantity that the task asks you to preserve. Draw the smallest table or diagram that permits every intermediate result to be checked. Keep an unexpected result; editing the premises until a preferred conclusion appears would destroy the counterexample.

Read the linked prerequisite and the bounded primary passage. Record the source revision, the definition actually used and the assumptions you imported. The project artifact supplies a real representation to inspect, while the fixed model supplies invented inputs. Neither a document name nor an accessible URL establishes a production result. Explain what would need to be observed before using the calculation in an operational decision.

State the direct manual baseline and its falsifier before proposing a composable DSL or an agent abstraction. Ask an assistant to challenge your manual answer only after saving it. Retain the prompt, the reply, the source passage it cites and the correction you accept or reject. A shorter expression is useful only if it preserves the operation, the control and the refusal boundary. Compare it with a plain table first.

Submit the original answer, intermediate quantities, corrected answer and control together. Label source consultation and calculator use as assistance. A future dogfood comparison should use the same task version and retain failures as well as successes; otherwise changing the question can masquerade as improvement. The prepared criteria below remain undecided until a learner actually attempts the task. An answer key and an author check establish neither learning nor adoption.

## Prepared learner criteria

- Exercise 1: Does marginal coverage pass? — Decision undecided.
- Exercise 2: Find the allocation obstruction. — Decision undecided.
- Exercise 3: Give a maximum fixed matching. — Decision undecided.
- Exercise 4: Apply the extra-edge control. — Decision undecided.
- Exercise 5: Does a matching prove independent review? — Decision undecided.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
