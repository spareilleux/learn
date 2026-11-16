---
module_id: "net-015-condense-mutual-dependencies-before-ordering-work"
department: "network-science"
course: "Condense Mutual Dependencies Before Ordering Work"
level: "intermediate"
prerequisites: ["net-009-detect-global-cycles-in-a-panel-stack"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Condense Mutual Dependencies Before Ordering Work

> This lesson uses authored fixed inputs and inspected source passages. The numbers, histories and labels are teaching constructions. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A Demerzel planning sketch contains several cycles. Listing one cycle proves that a topological schedule of the original graph is unavailable, but it does not show which tasks belong to the same mutually dependent region. Strongly connected components provide that partition while preserving every task’s identity inside its region.

NetworkX documents contraction of strongly connected components and states that the resulting graph is acyclic. Our fixed labels are authored, and no graph package is executed. Check reachability in both directions before grouping nodes. A one-way path is not enough to merge its endpoints. Then remove internal edges only in the condensed view and retain the member map.

A DAG between groups permits reasoning about intergroup ordering. It does not solve the dependencies within a group. Those could require revising a contract, splitting a task or specifying an iterative model. Adding a return edge can merge formerly separate groups, as the control shows. An agent must not treat contraction as evidence that a runnable schedule or safe parallel execution has been delivered.

## Sources and project boundary

The retained Learn helper separates frontmatter, heading and body in `parseModule`, and indexes English module names in `englishModuleKeys`. Those inspected representations let a task name its source and metadata; they do not implement the authored operation. The retained practice record instead distinguishes retrieval metrics from learner evidence. Inspect the particular file linked below and retain only the observation it actually supports. No model input in this lesson was estimated from that file.

[Prerequisite: net-009-detect-global-cycles-in-a-panel-stack](../../network-science/en/net-009-detect-global-cycles-in-a-panel-stack.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Primary reading](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.components.condensation.html)

## Fixed model and control

```json
{
  "values": {
    "nodes": [
      "a",
      "b",
      "c",
      "d",
      "e"
    ],
    "edges": [
      [
        "a",
        "b"
      ],
      [
        "b",
        "a"
      ],
      [
        "b",
        "c"
      ],
      [
        "c",
        "d"
      ],
      [
        "d",
        "c"
      ],
      [
        "d",
        "e"
      ]
    ]
  },
  "formula": "Group nodes by mutual reachability (including zero-length self path); sort members and components lexically. Emit unique edges between distinct components. Count SCCs and condensed edges.",
  "expected": {
    "components": [
      [
        "a",
        "b"
      ],
      [
        "c",
        "d"
      ],
      [
        "e"
      ]
    ],
    "component_count": 3,
    "condensed_edges": [
      [
        "ab",
        "cd"
      ],
      [
        "cd",
        "e"
      ]
    ],
    "condensed_edge_count": 2
  },
  "negative_control": {
    "values": {
      "nodes": [
        "a",
        "b",
        "c",
        "d",
        "e"
      ],
      "edges": [
        [
          "a",
          "b"
        ],
        [
          "b",
          "a"
        ],
        [
          "b",
          "c"
        ],
        [
          "c",
          "d"
        ],
        [
          "d",
          "c"
        ],
        [
          "d",
          "e"
        ],
        [
          "e",
          "a"
        ]
      ]
    },
    "expected": {
      "components": [
        [
          "a",
          "b",
          "c",
          "d",
          "e"
        ]
      ],
      "component_count": 1,
      "condensed_edges": [],
      "condensed_edge_count": 0
    },
    "why": "One return dependency makes every node mutually reachable; hiding only the obvious local cycles would miss the larger component."
  },
  "assumptions": [
    "Exact finite directed dependency graph; condensed labels concatenate sorted unique single-letter names.",
    "An edge means a dependency relation only, not a legal execution trigger."
  ],
  "limits": "Contraction identifies coupled groups; it does not resolve a cycle, execute a fixed point or authorize simultaneous writes.",
  "input_types": {
    "nodes": "set<unique single-letter string>",
    "edges": "list<[node,node]>"
  }
}
```

### Exercise 1

Find the mutual-dependency groups.

<details><summary>Answer 1</summary>

The groups are `[a,b]`, `[c,d]` and `[e]`, so the component count is `3`. Each pair in a group has paths both ways.

</details>

### Exercise 2

Write the condensed edges.

<details><summary>Answer 2</summary>

They are `ab->cd` and `cd->e`, totaling `2`. Internal edges are represented by membership rather than retained as group self-loops.

</details>

### Exercise 3

Does the DAG resolve the original cycles?

<details><summary>Answer 3</summary>

No. It orders groups only. The internal dependencies and original node identities remain unresolved and must stay recoverable.

</details>

### Exercise 4

Apply the return-edge control.

<details><summary>Answer 4</summary>

All nodes form `[a,b,c,d,e]`; there is `1` component and `0` condensed edges. The return path couples the entire graph.

</details>

### Exercise 5

Why retain the membership map?

<details><summary>Answer 5</summary>

Without it, a concise acyclic picture could conceal which real tasks still depend on each other. Contraction is a view, not permission to merge effects.

</details>

## Source-assisted learner task

Prepare a dependency-region map for a fictional Demerzel review plan.

**Direct manual baseline:** Mark all mutually reachable pairs, form equivalence classes and draw only interclass edges.

**Falsifier:** One-way reachability merges groups or a condensed DAG is reported as a resolved execution schedule.

Save a first answer before opening the corrected exercises. Copy the input identities and units, write the intermediate quantities, and distinguish the calculation from the interpretation. A correct number with the wrong denominator, state boundary or counting unit does not meet the task. Retain a surprising intermediate result rather than changing the input to make the final answer look plausible.

Read the cited primary passage within the scope recorded in the packet. Compare its actual definition with the authored rule in the fixed model. The reference may motivate a concept without specifying our entire model. Record the version or date, the passage used and the exact assumption you imported. An accessible page or a successful file read is not evidence that a claim has been verified.

Inspect the retained project artifact and one prerequisite. Separate what the file actually represents from what this new task hypothesizes. Preserve source revision and assistance history. Ask an assistant to challenge an assumption only after saving the manual baseline, then keep its prompt, reply, accepted correction and rejected suggestion. Source lookup and calculator use are permitted assistance, not unaided recall.

Run the changed input through the same reasoning on paper. State the falsifier before proposing an agent abstraction or a composable DSL expression. If an abstraction drops the counterexample or changes the accepted endpoint, it fails this task even if its response is shorter. Compare a direct table or typed record first; no new language or production engine is required.

Submit original and corrected answers together with the control result, source passage and remaining uncertainty. The packet prepares a separate criterion for each exercise, with every learner decision undecided. An answer key, a byte hash and an author self-check are different evidence from an actual learner attempt. A future dogfood comparison must retain actual attempts on the same versioned task and the direct baseline before claiming a useful change.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
