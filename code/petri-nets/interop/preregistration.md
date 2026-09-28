# Lesson 16 — pre-registration

Written 2026-09-27 before any of these experiments ran, at `e3cb4be` of this repository. The only analyser used is this course's own (`PetriNets`, .NET SDK 10.0.112). TINA, pm4py and Graphviz are not installed on this machine; nothing below involves them.

## The model

`admission.pnml`, written by hand, not by the course's writer: two agent jobs, one admission at a time.

| Place | Initial | Meaning |
|---|---|---|
| `waiting` | 2 | jobs whose candidate has not been tested |
| `tested` | 0 | jobs whose candidate passed its tests: the prerequisite for admission |
| `capacity` | 2 | free slots; a job needs 2, so only one job runs at a time |
| `running` | 0 | admitted jobs |
| `done` | 0 | finished jobs |

| Transition | Consumes | Produces |
|---|---|---|
| `test` | `waiting` | `tested` |
| `admit` | `tested`, `capacity` ×2 | `running` |
| `finish` | `running` | `done`, `capacity` ×2 (the terminal release) |

The file also carries what a drawing tool writes: `<graphics>` positions on every node and the net's name on the `<page>`.

## Experiments, with the prediction written before the run

**E1 — round trip.** Parse `admission.pnml`, analyse it, write it with `Pnml.Write`, parse that, analyse again, write again.
Prediction:
- Both parses give the same place and transition ids and the initial marking `[2, 0, 2, 0, 0]`.
- Both keep the weight 2 on `capacity → admit` and on `finish → capacity`.
- The enabled set at the initial marking is `{test}`.
- There are **9** reachable states and **1** dead state, `done = 2, capacity = 2`, which is the proper end.
- The bound of `running` is 1: no double admission.
- `capacity + 2·running = 2` holds in every reachable state.
- The second write is byte-identical to the first.
- The graphics are dropped. Layout is not semantics, so that is not a failure.

Falsifier: any difference in ids, marking, weights, enabled set, state count, dead states or bound.

**E2 — the release forgotten.** `admission-no-release.pnml` is E1 with `finish` producing only `done`.
Prediction:
- **7** reachable states and **1** dead state, `waiting 0, tested 1, capacity 0, running 0, done 1`: a job that passed its tests and is never admitted.
- The shortest path to it has **4** firings. The exact sequence depends on the search order, so it is not predicted.

**E3 — malformed files.** Both are predicted to be refused with an exception, not read:
- (a) an arc whose target id names no node;
- (b) an initial marking written `two`.

Falsifier: either file parses.

**E4 — a feature the reader does not support.** `inhibitor-arc.pnml` models admission with an inhibitor arc from `running` to `admit`, instead of `capacity`: admit only when nothing runs.
- The arc carries `<type value="inhibitor"/>`, an extension outside the P/T grammar.
- Under inhibitor semantics this net has **9** reachable states, like E1.
- **Desired behaviour:** the P/T reader refuses the file, and says why.
- **Predicted behaviour at `e3cb4be`**, from reading `Pnml.Parse` (it reads only `source`, `target` and `inscription` on an arc): the file is **accepted**, and the arc is read as an ordinary arc of weight 1. Then `admit` needs a token in `running` that never comes. That gives **3** reachable states and a dead state with `tested = 2`.

If E4 behaves as predicted, it is a defect: the semantics were changed without a word. The correction must fail first at that seam, in a unit test on `Pnml.Parse`, and pass after.

## Stop conditions

- Nothing here claims what TINA, a PNML tool other than this one, XES or DOT would do. Those are recipes for later.
- State-space analysis is not execution of real jobs and not a fairness proof.
