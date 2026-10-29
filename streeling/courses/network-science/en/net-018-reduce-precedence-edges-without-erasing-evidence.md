---
module_id: "net-018-reduce-precedence-edges-without-erasing-evidence"
department: "network-science"
course: "Reduce Precedence Edges without Erasing Evidence"
title: "Reduce Precedence Edges without Erasing Evidence"
level: "intermediate"
prerequisites: ["net-015-condense-mutual-dependencies-before-ordering-work"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Reduce Precedence Edges without Erasing Evidence

> This is an authored mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

An IX pipeline sketch accumulates direct arrows between tasks that are already ordered through other tasks. The drawing becomes difficult to inspect. Removing arrows can simplify the view, but only after choosing what the arrows mean. If an arrow carries a specific artifact or authorization, another path is not automatically a substitute for that direct obligation.

For this lesson every edge means precedence alone. In an acyclic graph, an edge is redundant when its endpoints remain connected in the same direction without that edge. Test the alternate path before removing the arrow from the simplified view. Compare the full reachability relation before and after, rather than only the number of nodes or whether a topological order still exists.

The fixed graph contains a complete chain and several shortcuts. The chain suffices to preserve all ordered reachable pairs. The control removes a middle chain edge. A former shortcut then becomes necessary because the alternate route has disappeared. This shows why a reduction belongs to a specific graph revision; an edge labelled redundant yesterday can become essential after another edit.

The NetworkX documentation states the DAG requirement and warns that its returned reduction does not copy edge or node data automatically. We use that as a concrete reminder about representation loss, without running the library. The component prerequisite solves cycles by grouping them; reduction is a different operation on an already acyclic graph. Keep the unreduced source graph and all evidence records. A DSL view may hide redundant precedence arrows, but it must not silently erase provenance, payload constraints or approval semantics that the model never represented.

## Sources and project boundary

The retained Learn helper separates metadata, title and body, and indexes English module identities. Inspect that representation when naming the artifact and its revision. It does not implement this lesson’s model or supply its invented inputs.

[Prerequisite: net-015-condense-mutual-dependencies-before-ordering-work](../../network-science/en/net-015-condense-mutual-dependencies-before-ordering-work.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.dag.transitive_reduction.html)

## Fixed model and negative control

```json
{
  "values": {
    "nodes": [
      "A",
      "B",
      "C",
      "D"
    ],
    "edges": [
      [
        "A",
        "B"
      ],
      [
        "B",
        "C"
      ],
      [
        "A",
        "C"
      ],
      [
        "C",
        "D"
      ],
      [
        "A",
        "D"
      ],
      [
        "B",
        "D"
      ]
    ]
  },
  "formula": "For a DAG retain edge [u,v] iff deleting that edge leaves no directed u-to-v path. Sort edge lists lexicographically. Count ordered distinct reachable node pairs before and after. Never apply this DAG rule to a cyclic graph.",
  "expected": {
    "retained_edges": [
      [
        "A",
        "B"
      ],
      [
        "B",
        "C"
      ],
      [
        "C",
        "D"
      ]
    ],
    "removed_edges": [
      [
        "A",
        "C"
      ],
      [
        "A",
        "D"
      ],
      [
        "B",
        "D"
      ]
    ],
    "reachable_pairs_before": 6,
    "reachable_pairs_after": 6
  },
  "negative_control": {
    "values": {
      "nodes": [
        "A",
        "B",
        "C",
        "D"
      ],
      "edges": [
        [
          "A",
          "B"
        ],
        [
          "A",
          "C"
        ],
        [
          "C",
          "D"
        ],
        [
          "A",
          "D"
        ],
        [
          "B",
          "D"
        ]
      ]
    },
    "expected": {
      "retained_edges": [
        [
          "A",
          "B"
        ],
        [
          "A",
          "C"
        ],
        [
          "B",
          "D"
        ],
        [
          "C",
          "D"
        ]
      ],
      "removed_edges": [
        [
          "A",
          "D"
        ]
      ],
      "reachable_pairs_before": 5,
      "reachable_pairs_after": 5
    },
    "why": "Removing the middle chain edge makes the former shortcut necessary to preserve reachability."
  },
  "input_types": {
    "nodes": "ordered finite unique strings",
    "edges": "unique directed node pairs forming a DAG"
  },
  "assumptions": [
    "Edges mean precedence only, without latency, required payload, direct authorization or evidence semantics.",
    "Every reachability relation of the supplied DAG is the preservation target."
  ],
  "limits": "Do not delete production dependencies or receipts from this drawing exercise. Equivalent reachability need not preserve data or authority contracts."
}
```

### Exercise 1

Give the fixed reduced edge set.

<details><summary>Answer 1</summary>

It is `[[A,B],[B,C],[C,D]]`. The removed shortcuts are `[[A,C],[A,D],[B,D]]`; each has an alternate directed path in the fixed graph.

</details>

### Exercise 2

Check the preservation target.

<details><summary>Answer 2</summary>

There are `6` ordered distinct reachable pairs before and `6` after. Equal counts alone are insufficient in general; the actual pair sets must also agree.

</details>

### Exercise 3

Which control edges remain necessary?

<details><summary>Answer 3</summary>

The reduction is `[[A,B],[A,C],[B,D],[C,D]]`; only `[[A,D]]` is removed. Reachable-pair counts remain `5` before and `5` after.

</details>

### Exercise 4

May a redundant arrow’s receipt be deleted?

<details><summary>Answer 4</summary>

No. Precedence reachability does not encode receipt identity, direct data transfer or authority. Retain those records separately and keep the unreduced graph available.

</details>

### Exercise 5

Why reject cyclic input to this operation?

<details><summary>Answer 5</summary>

The declared reduction rule assumes a DAG. Condense or otherwise resolve cycles with an explicitly justified model before applying it; do not silently reuse the same uniqueness claim.

</details>

## Source-assisted learner task

Simplify a fictional IX precedence drawing while preserving its source evidence.

**Direct manual baseline:** For each edge draw an alternate path or mark it necessary, then compare reachable pair sets.

**Falsifier:** The simplified drawing loses a reachable ordered pair or treats hidden edge data as preserved.

Save a first answer before opening the solutions. Identify the input types, the comparison boundary and the quantity that the task asks you to preserve. Draw the smallest table or diagram that permits every intermediate result to be checked. Keep an unexpected result; editing the premises until a preferred conclusion appears would destroy the counterexample.

Read the linked prerequisite and the bounded primary passage. Record the source revision, the definition actually used and the assumptions you imported. The project artifact supplies a real representation to inspect, while the fixed model supplies invented inputs. Neither a document name nor an accessible URL establishes a production result. Explain what would need to be observed before using the calculation in an operational decision.

State the direct manual baseline and its falsifier before proposing a composable DSL or an agent abstraction. Ask an assistant to challenge your manual answer only after saving it. Retain the prompt, the reply, the source passage it cites and the correction you accept or reject. A shorter expression is useful only if it preserves the operation, the control and the refusal boundary. Compare it with a plain table first.

Submit the original answer, intermediate quantities, corrected answer and control together. Label source consultation and calculator use as assistance. A future dogfood comparison should use the same task version and retain failures as well as successes; otherwise changing the question can masquerade as improvement. The prepared criteria below remain undecided until a learner actually attempts the task. An answer key and an author check establish neither learning nor adoption.

## Prepared learner criteria

- Exercise 1: Give the fixed reduced edge set. — Decision undecided.
- Exercise 2: Check the preservation target. — Decision undecided.
- Exercise 3: Which control edges remain necessary? — Decision undecided.
- Exercise 4: May a redundant arrow’s receipt be deleted? — Decision undecided.
- Exercise 5: Why reject cyclic input to this operation? — Decision undecided.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
