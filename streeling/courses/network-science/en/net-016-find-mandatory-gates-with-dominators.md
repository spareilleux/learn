---
module_id: "net-016-find-mandatory-gates-with-dominators"
department: "network-science"
course: "Find Mandatory Gates with Dominators"
title: "Find Mandatory Gates with Dominators"
level: "intermediate"
prerequisites: ["net-004-semantic-backpressure-and-evidence-dependencies"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Find Mandatory Gates with Dominators

> This is an authored mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A Learn workflow drawing places a review box before publication. That picture can still permit a second route that skips the box. To ask whether review is structurally unavoidable, fix the entry node and publication target, then examine every allowed route between them. Position on a diagram or frequency of use does not establish necessity.

In this graph an edge means an allowed next step. It does not mean that all incoming nodes must complete, as an evidence join would. A vertex dominates the target when every entry-to-target path contains it. Include the entry and target themselves in the intersection, then identify the proposed intermediate gate. Record a bypass path if one exists; that path explains the failed necessity claim more clearly than a percentage.

The fixed graph has two branches that reunite at review. Both routes cross the gate. The control adds a direct branch to publication, so the old gate is no longer mandatory even though the original routes remain. Keeping the same gate label or adding another green badge would not remove the new path. A structural audit needs the full route inventory and its version.

The NetworkX documentation supplies the directed entry-relative dominance concept. Our path enumeration is a small manual alternative, not a new graph runtime. The evidence-dependency prerequisite asks whether particular receipts satisfy a rule; this lesson asks whether every route actually encounters that rule. A gate can dominate and still perform the wrong check. Conversely, a missing graph edge does not prove a production bypass exists. Source inspection and actual revision-bound traversal evidence are needed before making either operational claim.

## Sources and project boundary

The retained Learn helper separates metadata, title and body, and indexes English module identities. Inspect that representation when naming the artifact and its revision. It does not implement this lesson’s model or supply its invented inputs.

[Prerequisite: net-004-semantic-backpressure-and-evidence-dependencies](../../network-science/en/net-004-semantic-backpressure-and-evidence-dependencies.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.dominance.immediate_dominators.html)

## Fixed model and negative control

```json
{
  "values": {
    "nodes": [
      "S",
      "A",
      "B",
      "R",
      "P"
    ],
    "edges": [
      [
        "S",
        "A"
      ],
      [
        "S",
        "B"
      ],
      [
        "A",
        "R"
      ],
      [
        "B",
        "R"
      ],
      [
        "R",
        "P"
      ]
    ],
    "start": "S",
    "target": "P",
    "candidate": "R"
  },
  "formula": "Enumerate all simple directed start-to-target paths. Dominators are their vertex-set intersection ordered by nodes. Candidate mandatory iff it belongs to that intersection; bypass is lexicographically first path omitting candidate or null. Require at least one target path.",
  "expected": {
    "dominators": [
      "S",
      "R",
      "P"
    ],
    "candidate_mandatory": true,
    "bypass": null
  },
  "negative_control": {
    "values": {
      "nodes": [
        "S",
        "A",
        "B",
        "R",
        "P"
      ],
      "edges": [
        [
          "S",
          "A"
        ],
        [
          "S",
          "B"
        ],
        [
          "A",
          "R"
        ],
        [
          "B",
          "R"
        ],
        [
          "R",
          "P"
        ],
        [
          "B",
          "P"
        ]
      ],
      "start": "S",
      "target": "P",
      "candidate": "R"
    },
    "expected": {
      "dominators": [
        "S",
        "P"
      ],
      "candidate_mandatory": false,
      "bypass": [
        "S",
        "B",
        "P"
      ]
    },
    "why": "An added publication route avoids the declared review gate."
  },
  "input_types": {
    "nodes": "ordered list of unique strings",
    "edges": "directed pairs of listed nodes",
    "start": "listed node",
    "target": "reachable listed node",
    "candidate": "listed node"
  },
  "assumptions": [
    "Graph edges mean allowed traversal, not AND-required evidence joins.",
    "Graph includes every allowed route for the stated entry and target."
  ],
  "limits": "Dominance is relative to the graph and entry. It is not authorization, successful review, runtime enforcement or security certification."
}
```

### Exercise 1

Find the fixed target’s dominators.

<details><summary>Answer 1</summary>

In the declared node order they are `[S,R,P]`. Every allowed route reaches the review node; the entry and target also belong by definition.

</details>

### Exercise 2

Exhibit the control’s bypass.

<details><summary>Answer 2</summary>

The path `[S,B,P]` omits `R`. Dominators become `[S,P]`, and the mandatory-gate claim becomes `false`.

</details>

### Exercise 3

Does dominance prove review success?

<details><summary>Answer 3</summary>

No. It proves route membership under the graph interpretation. The gate’s actual predicate, evidence identity and authority still need separate validation.

</details>

### Exercise 4

May the same graph represent an all-required join?

<details><summary>Answer 4</summary>

Only after redefining its semantics. Allowed-choice paths and conjunctive prerequisite edges answer different questions; a route bypass is not automatically an unsatisfied AND condition.

</details>

### Exercise 5

What happens if publication is unreachable?

<details><summary>Answer 5</summary>

Do not report a satisfied gate from an empty path intersection. Report the unreachable target separately; our model requires a reachable target before evaluating necessity.

</details>

## Source-assisted learner task

Audit whether a proposed Learn publication route must encounter its review gate.

**Direct manual baseline:** Draw every allowed route from the chosen entry and intersect their vertex sets.

**Falsifier:** A permitted entry-to-publication path omits the supposedly mandatory gate.

Save a first answer before opening the solutions. Identify the input types, the comparison boundary and the quantity that the task asks you to preserve. Draw the smallest table or diagram that permits every intermediate result to be checked. Keep an unexpected result; editing the premises until a preferred conclusion appears would destroy the counterexample.

Read the linked prerequisite and the bounded primary passage. Record the source revision, the definition actually used and the assumptions you imported. The project artifact supplies a real representation to inspect, while the fixed model supplies invented inputs. Neither a document name nor an accessible URL establishes a production result. Explain what would need to be observed before using the calculation in an operational decision.

State the direct manual baseline and its falsifier before proposing a composable DSL or an agent abstraction. Ask an assistant to challenge your manual answer only after saving it. Retain the prompt, the reply, the source passage it cites and the correction you accept or reject. A shorter expression is useful only if it preserves the operation, the control and the refusal boundary. Compare it with a plain table first.

Submit the original answer, intermediate quantities, corrected answer and control together. Label source consultation and calculator use as assistance. A future dogfood comparison should use the same task version and retain failures as well as successes; otherwise changing the question can masquerade as improvement. The prepared criteria below remain undecided until a learner actually attempts the task. An answer key and an author check establish neither learning nor adoption.

## Prepared learner criteria

- Exercise 1: Find the fixed target’s dominators. — Decision undecided.
- Exercise 2: Exhibit the control’s bypass. — Decision undecided.
- Exercise 3: Does dominance prove review success? — Decision undecided.
- Exercise 4: May the same graph represent an all-required join? — Decision undecided.
- Exercise 5: What happens if publication is unreachable? — Decision undecided.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
