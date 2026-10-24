---
module_id: "cs-019-preserve-lexical-bindings-when-composing-fragments"
department: "computer-science"
course: "Preserve Lexical Bindings When Composing Fragments"
level: "intermediate"
prerequisites: ["cs-006-ixql-pipeline-composition"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Preserve Lexical Bindings When Composing Fragments

> This lesson uses an authored fixed case and inspected sources. Counts, times, labels and signals are invented teaching inputs. Human technical review, fluent-language review, actual learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A teammate proposes composing agent pipeline fragments by concatenating their text. Both fragments use a convenient temporary name. The result still looks readable, yet a free reference can accidentally refer to the new local binding. The composition prerequisite follows stage dependencies; this lesson follows binding identity inside a stage. The problem can arise before any tool runs, so a successful arithmetic example alone cannot establish safe composition.

Our explanatory fragment adds an incremented argument to a value supplied by its surrounding scope. The same printed name is used locally and in that surrounding scope. The intended free reference must keep its original binding. In naive textual substitution it instead sees the local value, producing another answer. Renaming the local binding and every reference bound by it preserves the intended meaning; changing arbitrary occurrences of the spelling can alter free references as well.

The [Racket](https://docs.racket-lang.org/guide/pattern-macros.html) guide’s lexical-scope example demonstrates why introduced identifiers need binding discipline. We use that concept without claiming that IXQL is a Racket macro language. The retained [F#](https://learn.microsoft.com/dotnet/fsharp/) helper receives functions with lexical parameters and passes successful values to callbacks. It does not implement a textual fragment expander. Reading its parameter scope is useful precisely because composition of functions and concatenation of source text have different obligations.

The control deliberately makes the outer value equal to the local value. Both calculations then agree despite different binding structures. This is a deceptive success case: value equality masks capture. A prospective DSL proposal should retain free-variable sets and binding identities, then test unequal values. A source-assisted learner can mark the intended arrows between occurrences and definitions on paper; introducing a new parser is unnecessary to answer this question.

## Sources and project boundary

Read the prerequisite before using the model. Inspect the linked retained project artifact at the revision recorded in the packet, and identify the field or branch that supports the stated source observation. The source gives a representation or declared behavior; it does not turn the invented case into an observed project result. The primary reading supplies the named concept within its stated scope.

[Prerequisite: cs-006-ixql-pipeline-composition](../../computer-science/en/cs-006-ixql-pipeline-composition.md)

[Retained project artifact](../../../../code/streeling/functional-composition/vendor/GaAsync.fs)

[Primary reading: Racket Guide, section 16.1.2, read 2026-10-24](https://docs.racket-lang.org/guide/pattern-macros.html)

[Primary reading: Microsoft F# documentation, read 2026-10-24](https://learn.microsoft.com/dotnet/fsharp/)

## Fixed model and control

```json
{
  "values": {
    "outer_x": 10,
    "argument": 3,
    "local_name": "x",
    "local_increment": 1
  },
  "formula": "local=argument+local_increment; lexical_result=local+outer_x; captured_result=local+local; renamed_result=local+outer_x, renaming only the bound local identifier.",
  "expected": {
    "lexical_result": 14,
    "captured_result": 8,
    "renamed_result": 14
  },
  "negative_control": {
    "values": {
      "outer_x": 4,
      "argument": 3,
      "local_name": "x",
      "local_increment": 1
    },
    "expected": {
      "lexical_result": 8,
      "captured_result": 8,
      "renamed_result": 8
    },
    "why": "Coincidental equal values hide capture; one agreeing execution is not proof of hygiene."
  },
  "assumptions": [
    "One local binding and one intended free outer reference.",
    "Exact integers and pure expressions; this is explanatory notation, not IXQL syntax."
  ],
  "limits": "No parser, macro expander or GA DSL change is supplied; capture must be reasoned about by binding identity."
}
```

### Exercise 1

Compute the local value and the intended lexical result from the main case.

<details><summary>Answer 1</summary>

The local value is `4`; the intended result is `14`. The outer contribution remains `10` because the free reference keeps its surrounding binding. The argument is not itself the outer value.

</details>

### Exercise 2

What answer does the stipulated captured interpretation produce, and why?

<details><summary>Answer 2</summary>

It produces `8`, adding local `4` twice. The arithmetic is internally consistent but the reference denotes the wrong binding. A numeric discrepancy exposes the semantic error rather than a calculation mistake.

</details>

### Exercise 3

What must a valid alpha-renaming change?

<details><summary>Answer 3</summary>

It changes the bound local name and only occurrences bound by that definition. It preserves the free outer reference and yields `14`. Global spelling replacement does not by itself establish this relationship.

</details>

### Exercise 4

Apply the control. Why does agreement fail to prove safe composition?

<details><summary>Answer 4</summary>

Both interpretations yield `8` when the outer value is `4`. Equal values hide different bindings. The control is an agreement trap, so structural scope analysis must accompany the main counterexample.

</details>

### Exercise 5

What should an assistant retain when proposing a reusable fragment?

<details><summary>Answer 5</summary>

Retain its inputs, free identifiers, local binding identities and intended source context. Reject the proposal if renaming changes a free reference or if it cites this fixed table as proof of an implemented hygienic DSL.

</details>

## Source-assisted learner task

Start with a paper table before revealing the answers. Copy the inputs and their units, apply the declared operation, and retain intermediate results. This direct calculation is the manual baseline against which an assistant or a proposed composable notation must be compared. A shorter response has no demonstrated advantage if it loses an input identity, a failure category or the counterexample.

Then inspect the precise source passage recorded in the packet. Quote only the small field or branch needed for your explanation and record its revision. Ask an assistant to challenge one assumption after you have saved your first answer. Retain the prompt, reply, accepted corrections and rejected suggestions. Source lookup and calculator use are allowed; record them as assistance so the result cannot be mistaken for unaided recall.

Apply the changed input in the negative control and state an observable falsifier before making a recommendation. An unexpected control result requires checking the calculation and assumptions before changing a project workflow. Submit the original answer, corrected answer, assistance history and remaining uncertainty together. The packet prepares five learner criteria, one per exercise, with undecided decisions. Prepared solutions and author checks do not fill those decisions. A future dogfood comparison needs actual attempts on the same task and a retained manual baseline; no new agent mechanism or DSL implementation is required by this lesson.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
