---
module_id: "net-013-trace-causal-concurrency-with-vector-clocks"
department: "network-science"
course: "Trace Causal Concurrency with Vector Clocks"
level: "intermediate"
prerequisites: ["net-008-map-clock-domains-before-ordering-events", "inf-012-retain-event-order-in-a-handoff-summary"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Trace Causal Concurrency with Vector Clocks

> This lesson uses an authored fixed case and inspected sources. Counts, times, labels and signals are invented teaching inputs. Human technical review, fluent-language review, actual learner attempts, runtime execution, production adoption and publication decisions remain undecided.

Two agents edit different evidence notes and send messages to a coordinator. A wall-clock sorting rule may list one first even when neither action depends on the other. The clock-domain prerequisite aligns physical coordinates; the event-summary prerequisite preserves order. This lesson adds a causal partial order that can explicitly leave two events incomparable. A total list is convenient for display, but its order does not automatically describe causation.

Each vector component records knowledge of events at a fixed node. Compare vectors component by component. One precedes another only when every component is no greater and at least one is smaller. If each has a component the other lacks, neither dominates and the events are concurrent under the model. Summing components or comparing printed vectors lexicographically loses that distinction.

[Lamport](https://lamport.azurewebsites.net/pubs/time-clocks.pdf)’s original paper defines happened-before using local sequence, message send/receive and transitivity. The author’s [Cambridge](https://www.cl.cam.ac.uk/teaching/2021/ConcDisSys/dist-sys-notes.pdf) notes extend the practical representation to vector clocks and describe the receive operation. Merge the incoming and local vectors with componentwise maximum, then increment the receiving node’s component. This records both incoming causal knowledge and the receive event; adding only the message’s scalar total would not preserve that information.

The retained [F#](https://learn.microsoft.com/dotnet/fsharp/) source declares parallel result composition. It cannot supply timestamps or prove which real callback happened first. Our vectors are authored and assume all relevant communication is modeled, with no identity reuse. A proposed agent trace envelope remains advisory until a real task compares its retained relationships with a manually drawn message graph. Concurrency also says nothing about whether two writes are authorized or safe; that requires the project’s separate ownership and effect contract.

## Sources and project boundary

Read the prerequisite before using the model. Inspect the linked retained project artifact at the revision recorded in the packet, and identify the field or branch that supports the stated source observation. The source gives a representation or declared behavior; it does not turn the invented case into an observed project result. The primary reading supplies the named concept within its stated scope.

[Prerequisite: net-008-map-clock-domains-before-ordering-events](../../network-science/en/net-008-map-clock-domains-before-ordering-events.md)

[Prerequisite: inf-012-retain-event-order-in-a-handoff-summary](../../information-theory/en/inf-012-retain-event-order-in-a-handoff-summary.md)

[Retained project artifact](../../../../code/streeling/functional-composition/vendor/GaAsync.fs)

[Primary reading: Lamport 1978, Communications of ACM 21(7), pp. 558-565](https://lamport.azurewebsites.net/pubs/time-clocks.pdf)

[Primary reading: Kleppmann, Cambridge Distributed Systems 2020/21](https://www.cl.cam.ac.uk/teaching/2021/ConcDisSys/dist-sys-notes.pdf)

[Primary reading: Microsoft F# documentation, read 2026-10-24](https://learn.microsoft.com/dotnet/fsharp/)

## Fixed model and control

```json
{
  "values": {
    "a": [
      2,
      0
    ],
    "b": [
      0,
      3
    ],
    "receiver_local": [
      0,
      3
    ],
    "incoming": [
      2,
      0
    ],
    "receiver_index": 1
  },
  "formula": "a precedes b iff every a[i]<=b[i] and at least one strict; concurrent iff neither precedes nor equal; receive=max(local,incoming) componentwise then increment receiver component.",
  "expected": {
    "a_before_b": false,
    "b_before_a": false,
    "concurrent": true,
    "receive_clock": [
      2,
      4
    ],
    "a_before_receive": true
  },
  "negative_control": {
    "values": {
      "a": [
        2,
        0
      ],
      "b": [
        3,
        1
      ],
      "receiver_local": [
        3,
        1
      ],
      "incoming": [
        2,
        0
      ],
      "receiver_index": 1
    },
    "expected": {
      "a_before_b": true,
      "b_before_a": false,
      "concurrent": false,
      "receive_clock": [
        3,
        2
      ],
      "a_before_receive": true
    },
    "why": "Componentwise dominance replaces incomparability when causal knowledge includes the earlier event."
  },
  "assumptions": [
    "Fixed node identities and component order.",
    "Clocks are generated by the stated local-event/send/receive discipline with complete modeled communication."
  ],
  "limits": "Authored vectors are not live agent traces; omitted channels or restarted identities invalidate causal interpretation. No physical duration or permission follows."
}
```

### Exercise 1

Compare the main vectors componentwise. Is either event causally earlier?

<details><summary>Answer 1</summary>

Neither dominates: `a=[2,0]` is greater in the first component and `b=[0,3]` in the second. Thus `concurrent=true`. Their component sums cannot supply a happened-before relation.

</details>

### Exercise 2

Compute the receive vector, keeping the increment order explicit.

<details><summary>Answer 2</summary>

The maximum is `[2,3]`; incrementing receiver component `1` gives `[2,4]`. Merge occurs before the receive increment. The node index refers to the fixed declared component ordering.

</details>

### Exercise 3

Does the original event precede this receive event?

<details><summary>Answer 3</summary>

Yes. `[2,0]` is componentwise no greater than `[2,4]` and is strictly smaller in one component, so `a_before_receive=true`. This is a causal relation, without a time-duration estimate.

</details>

### Exercise 4

Apply the dominance control and contrast it with the main case.

<details><summary>Answer 4</summary>

For `b=[3,1]`, `a_before_b=true` and `concurrent=false`. The receive clock is `[3,2]`. Additional causal knowledge changes the order relation rather than merely changing a displayed timestamp.

</details>

### Exercise 5

What can invalidate an actual trace interpretation?

<details><summary>Answer 5</summary>

Missing message channels, reset counters, reused node identities or changed component order break the model assumptions. A total display order or source declaration of parallelism cannot fill missing trace evidence or authorize concurrent writes.

</details>

## Source-assisted learner task

Start with a paper table before revealing the answers. Copy the inputs and their units, apply the declared operation, and retain intermediate results. This direct calculation is the manual baseline against which an assistant or a proposed composable notation must be compared. A shorter response has no demonstrated advantage if it loses an input identity, a failure category or the counterexample.

Then inspect the precise source passage recorded in the packet. Quote only the small field or branch needed for your explanation and record its revision. Ask an assistant to challenge one assumption after you have saved your first answer. Retain the prompt, reply, accepted corrections and rejected suggestions. Source lookup and calculator use are allowed; record them as assistance so the result cannot be mistaken for unaided recall.

Apply the changed input in the negative control and state an observable falsifier before making a recommendation. An unexpected control result requires checking the calculation and assumptions before changing a project workflow. Submit the original answer, corrected answer, assistance history and remaining uncertainty together. The packet prepares five learner criteria, one per exercise, with undecided decisions. Prepared solutions and author checks do not fill those decisions. A future dogfood comparison needs actual attempts on the same task and a retained manual baseline; no new agent mechanism or DSL implementation is required by this lesson.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
