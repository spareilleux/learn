---
title: "16. Interoperability: preserving behaviour, not just the drawing"
description: A hand-written PNML model of agent admission, read, analysed, written and read again, and compared on what it does rather than how it looks; the same model with its release forgotten; two malformed files; and an inhibitor arc the reader used to swallow without a word.
sidebar:
  order: 16
---

Full code: [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). This lesson is printed by `dotnet run --project Examples -c Release -- l16`, compared with [`expected/l16.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l16.txt). Its input files, and the predictions written before the first run, are in [`interop/`](https://github.com/spareilleux/learn/tree/main/code/petri-nets/interop).

[Lesson 11](../11-tools-and-interoperability/) showed two things:
- PNML is a syntax plus a type URI;
- every net of the course survives a round trip through the writer and the reader, byte for byte.

That tested the writer against its own reader. This lesson asks the question a second tool raises: once a net has gone through a file, does it still **do** the same thing? The drawing may move. The behaviour must not.

## Three kinds of file, three kinds of promise

Files that "contain a Petri net" hold three different things, and only one of them can be checked for behaviour.

| Kind | What it holds | What it can tell you | Example format |
|---|---|---|---|
| A model | places, transitions, arcs and their weights, the initial marking | every run the net allows | [PNML](https://www.pnml.org/) of type P/T, [TINA](https://projects.laas.fr/tina/manuals/tina.html)'s `.net` |
| An event log | cases and the events that happened in them, in order | the runs that were **observed**, not the ones that were possible | XES, which [pm4py's `write_xes`](https://processintelligence.solutions/app/static/api/2.7.17/api/pm4py.write.html) writes |
| A visual export | nodes, edges, positions, labels | the picture | [DOT](https://graphviz.org/doc/info/lang.html), the Graphviz language |

- **A log is evidence about some runs.** A model can be mined from it, which is the process mining of [lesson 10](../10-workflows/). The log does not contain the model: a run that never happened is not in it.
- **DOT's grammar defines nodes, edges, graphs, subgraphs and clusters, with attributes.** A token count written in a DOT file is a label; nothing reads it as a marking.

**PNML is typed, and the type is not a promise.** The type URI tells a reader which language the file is in. It does not promise that the reader implements every extension a tool may add on top.

Two primary sources show how much the exchange depends on the tool:
- **TINA's manual** says that `tina` reads a net in textual form (`.net`, `.pnml`, `.tpn`) or in graphical form (`.ndr`, or `.pnml` with graphics). It has a flag, `-inh`, that *"removes inhibitor and read arcs from the input net"*. There, dropping part of the semantics is an option the user asks for by name.
- **pm4py's `write_pnml`** takes an initial marking **and a final marking**. It writes the workflow-net view of lesson 10, which a plain P/T net does not have.

## The model

Two agent jobs share an admission step that only one of them can hold at a time. A job needs a tested candidate before it is admitted, and gives its capacity back when it finishes.

| Place | Initial | Meaning |
|---|---|---|
| `waiting` | 2 | jobs whose candidate has not been tested yet |
| `tested` | 0 | jobs whose candidate passed its tests: the prerequisite for admission |
| `capacity` | 2 | free slots; a job needs 2, so one job runs at a time |
| `running` | 0 | admitted jobs |
| `done` | 0 | finished jobs |

| Transition | Consumes | Produces |
|---|---|---|
| `test` | `waiting` | `tested` |
| `admit` | `tested`, `capacity` ×2 | `running` |
| `finish` | `running` | `done`, `capacity` ×2: the release |

[`admission.pnml`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/admission.pnml) was written by hand, not by this course's writer. It is written the way a drawing tool would write it: a `<graphics>` position on every node, and the net's name on the `<page>`.

Unlike the earlier lessons of this course, the predictions were committed to a file before the first run: [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/preregistration.md), hashed at 10:54 EDT on 2026-09-27. All of them held.

## E1: read, analyse, write, read again

The program computes what the net **means**, as lines that can be compared. It does that after the first parse, and again after writing the net and parsing it back. The two listings are compared in full, so a line that only one of them has counts as a difference:

```text
== E1: the admission net, read, written and read again ==
places:      waiting tested capacity running done
transitions: test admit finish
initial:     waiting=2 tested=0 capacity=2 running=0 done=0
arcs:        waiting->test, test->tested, tested->admit, capacity->admit x2, admit->running, running->finish, finish->done, finish->capacity x2
enabled:     test
states:      9
dead:        waiting=0 tested=0 capacity=2 running=0 done=2  after test test admit finish admit finish
bounds:      waiting<=2 tested<=2 capacity<=2 running<=1 done<=2
capacity + 2*running = 2 in every state: yes
after the round trip, same meaning: yes
second write identical to the first: yes
positions in the input: 9, in the output: 0
```

- **What survives:**
  - the ids;
  - the marking;
  - both weights of 2;
  - the enabled set;
  - all 9 reachable markings;
  - the one dead marking;
  - the bounds.
- **The dead marking is the proper end:** both jobs are done and the capacity is back to 2.
- **`running<=1` is the property the model exists for.** There is never a double admission. The conserved sum `capacity + 2·running = 2` is the same fact written as an invariant ([lesson 5](../05-invariants/)).
- **The 9 positions are gone,** because the writer drops layout (lesson 11). That is not a failure: nothing in the comparison depends on where a place is drawn.

What this comparison covers is the **bounded reachable behaviour**: all 9 markings are enumerated, and none is left out. It is not an execution of real jobs. It is not a fairness proof either: the graph says a waiting job *can* finish, not that a scheduler will let it ([lesson 4](../04-properties/)).

## E2: the release forgotten

[`admission-no-release.pnml`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/admission-no-release.pnml) is the same net, with `finish` producing only `done`:

```text
== E2: the same net with the release forgotten ==
states:      7
dead:        waiting=0 tested=1 capacity=0 running=0 done=1  after test test admit finish
bounds:      waiting<=2 tested<=2 capacity<=2 running<=1 done<=1
```

- **The dead marking is not an end.** One job is tested and will never be admitted, because the capacity it waits for was never returned.
- **The path is the useful part: `test test admit finish`.** It is a counterexample anyone can replay, in this analyser or in another tool, and it points at the transition that forgot something.

## E3: files that are wrong

```text
malformed-arc.pnml      refused: ArgumentException: Arc finish -> finished does not join a place and a transition. (Parameter 'arcs')
malformed-marking.pnml  refused: FormatException: The input string 'two' was not in a correct format.
```

- **Both files are refused, as predicted:** an arc to a node that does not exist, and an initial marking written `two`.
- **The second message is `int.Parse`'s.** It does not say which place was wrong. That is observed and left as it is: the refusal is correct, only its wording is poor.

## E4: a feature the reader does not model

An inhibitor arc lets a transition fire only when a place is **empty** ([lesson 15](../15-limits-and-what-comes-next/)). It is not in the P/T grammar.

[`inhibitor-arc.pnml`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/inhibitor-arc.pnml) replaces the capacity place with one such arc, from `running` to `admit`. The arc is marked with a `<type>` child, the way tools that model more than P/T nets mark an arc's kind:

```xml
<arc id="r-inhibits-admit" source="running" target="admit">
  <type value="inhibitor"/>
</arc>
```

Before this lesson, the reader accepted the file:

```text
inhibitor-arc.pnml      READ: 3 states, dead: waiting=0 tested=2 running=0 done=0
```

**That is a different net.** The reader took the inhibitor arc for an ordinary consuming arc. So `admit` needed a job already running, no job was ever admitted, and the net stopped with both jobs tested.

There was no error and no warning. This is the worst outcome an exchange can have: a file that parses, and means something else.

The reader now refuses an arc whose kind is not `normal`, and says why ([`Pnml.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Pnml.cs)). It looks for the kind in a `<type>` or an `<arctype>` child, written as an attribute (`<type value="inhibitor"/>`) or as a label (`<type><text>inhibitor</text></type>`), and a child that states no kind is refused too:

```csharp
foreach (var marker in element.Elements().Where(child => child.Name.LocalName is "type" or "arctype"))
{
    var kind = (string?)marker.Attribute("value") ?? Text(marker);
    if (kind != "normal")
        throw new NotSupportedException($"Arc {(string?)element.Attribute("id") ?? $"{source} -> {target}"} is of type {kind ?? "(unstated)"}; the P/T reader reads ordinary arcs only.");
}
```

```text
inhibitor-arc.pnml      refused: NotSupportedException: Arc r-inhibits-admit is of type inhibitor; the P/T reader reads ordinary arcs only.
```

**That is all it recognises.** A kind recorded any other way, inside a `<toolspecific>` block for instance, is not seen, and such an arc is still read as an ordinary one.

A unit test, `An_arc_the_reader_does_not_model_is_refused_not_read_as_an_ordinary_arc`, pins the fix:
- it failed before the fix (1 of the 5 PNML tests failed);
- it passes after (5 of 5), and so does the whole course (92 tests, 19 compared outputs).

An arc typed `normal` is still read: it says the arc is ordinary, and the test checks that as a control.

**The review found the first version too narrow:** it read only the attribute form of `<type>`. `An_arc_kind_given_as_a_label_or_an_arctype_is_refused_too` covers the label form, the `<arctype>` child in both forms and an empty `<type/>`. Its 4 cases failed before the second fix and pass after. Its control, `An_arc_kind_that_says_normal_is_read_as_an_ordinary_arc`, passes on both sides. The whole course now runs 99 tests and 19 compared outputs.

## What was not run here

**TINA is not installed on this machine, and neither pm4py nor Graphviz is.** The next step is a recipe, not a result:

```bash
# Pending: TINA is not installed on this machine. This command has not been run.
tina -R interop/admission.pnml
```

- **What it would check.** `-R` builds the marking reachability graph. Its counts should match E1's: 9 markings, one dead marking, the one where both jobs are done.
- **What else would be a result:**
  - `inhibitor-arc.pnml` read by TINA, which does model inhibitor arcs;
  - the same file with `-inh`.
- **Pending as well:**
  - an XES log of simulated runs, checked against the model;
  - a DOT picture, which would check nothing about behaviour.

## Key takeaways

- **Compare what a net means, not how its file looks:** ids, marking, weights, enabled transitions, the reachable markings, the dead ones and the bounds.
- **A log records runs, a drawing records positions; only a model records behaviour.**
- **The worst failure is silent.** A net that parses and means something else is worse than a refusal. Refuse what you do not model, and say what it was.
- **A dead marking with its path is a counterexample you can replay.** A state space is neither an execution nor a fairness proof.

## Exercises

1. Give the model three jobs (`waiting` = 3). Predict the number of reachable markings before running, then check.
2. E1 has a dead marking, and nobody calls it a deadlock. Why not, and what would make the difference explicit?
3. An arc typed `<type value="reset"/>` empties its place. What does the reader do with it now, and what would it have done before this lesson?
4. Which of these proves that two tools agree on a net? Identical PNML text; identical DOT; identical state counts; reachability graphs identical up to renaming of the markings.

<details>
<summary>Solutions</summary>

**1.** Sixteen. At most one job runs, because `running<=1`.
- With `running = 0`, the three jobs are spread over `waiting`, `tested` and `done`: C(5, 2) = 10 ways.
- With `running = 1`, the other two are spread the same way: C(4, 2) = 6 ways.

Run on a copy of `interop/` with `waiting` set to 3:

```text
initial:     waiting=3 tested=0 capacity=2 running=0 done=0
states:      16
dead:        waiting=0 tested=0 capacity=2 running=0 done=3  after test test test admit finish admit finish admit finish
bounds:      waiting<=3 tested<=3 capacity<=2 running<=1 done<=3
capacity + 2*running = 2 in every state: yes
```

**2.** E1's dead marking is the intended end: every job is done and the capacity is back. A deadlock is a dead marking that is **not** the intended end, like E2's.

The net alone cannot tell them apart. A **final marking** does, which is what a workflow net adds (lesson 10), and why `pm4py.write_pnml` asks for one.

**3.** It is refused:

```text
inhibitor-arc.pnml      refused: NotSupportedException: Arc r-inhibits-admit is of type reset; the P/T reader reads ordinary arcs only.
```

Before the fix, the reader read only `source`, `target` and `inscription`. It would have taken the arc for an ordinary one, consuming one token instead of emptying the place. That is the same silent change as the inhibitor arc.

**4.** Only the last one.
- **The text** is neither necessary nor sufficient. Layout, ids and element order can differ for the same net. And two readers can read the same text differently, as this reader did with E4 before the fix.
- **DOT** says nothing about behaviour.
- **Equal counts** are necessary, not sufficient.
- **Reachability graphs identical up to renaming**, with the transitions labelled, are the behavioural statement for a bounded net.

</details>

## Sources

- [PNML](https://www.pnml.org/), the format's home, and ISO/IEC 15909-2:2011, as cited in lesson 11.
- [TINA manual](https://projects.laas.fr/tina/manuals/tina.html), LAAS-CNRS: input formats, `-R`, `-inh`. Read 2026-09-27; TINA itself not run.
- [pm4py 2.7.17, `pm4py.write`](https://processintelligence.solutions/app/static/api/2.7.17/api/pm4py.write.html): the signatures of `write_pnml` (initial and final marking) and `write_xes`. Read 2026-09-27; pm4py not run.
- [The DOT language](https://graphviz.org/doc/info/lang.html), Graphviz: an abstract grammar for nodes, edges, graphs, subgraphs and clusters.
