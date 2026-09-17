---
title: "1. The problem: what \"done\" is worth"
description: Why an agent's completion message is prose rather than evidence, the four independent axes Gaia refuses to collapse into one number, and the doctrine that follows — Design It Twice, tracer bullets, reversibility as a typed property, and independent verification as a separate transition. With the list of shortcuts Gaia names and rejects.
sidebar:
  order: 1
---

An agent finishes and says: *"Implemented the cancellation path and added a test. All 2,075 tests pass."*

That sentence contains one checkable claim and three unchecked ones. The checkable one is the number. The unchecked ones are that a cancellation path exists, that a test covers it, and that the suite was run at all — by this agent, in this tree, after this change. You can go and check them by hand, and for one change you will. The question this lesson is about is what happens when there are forty such sentences a day, from four sessions you were not watching.

## Completion markers are not evidence

Gaia's engineering doctrine has a list titled **Rejected shortcuts**. Two entries on it are the whole problem in one line each:

> equating activity, token use, elapsed time, or a completion marker with progress;
>
> accepting a report, prototype, green unit test, or GitHub publication as effective integration.

Both describe things that *feel* like evidence and are not. A completion marker is a token the model emitted because the conversation reached its end. Elapsed time measures how long a model talked. A green unit test proves the unit does what its author thought — which is exactly the belief under review. And a merged pull request proves that somebody clicked a button.

The engineering principle underneath is **ENG-08**:

> The author of a change cannot approve it. Verification binds to exact inputs, digests, tests, controls, and scope. A marker is evidence that work stopped, not evidence that its claims are true.

Read the last clause slowly: *evidence that work stopped*. That is genuinely all a completion marker tells you, and it is worth having — a session that never returns is a different problem from one that returned wrong. It just is not the thing people read it as.

### The C# analogue

You already refuse this substitution in code you write. Consider a method that returns `Task<bool>` for "did the payment go through", where the implementation catches every exception and returns `true` because the request was sent. Nobody would accept that. "I sent the request" and "the payment settled" are different facts, and the type that conflates them is the bug.

Gaia's bus applies exactly that discipline to the words agents use about each other. `send` does not return "sent". It returns:

```text
accepted-for-delivery; not read, not agreed, not completed
```

The string is long on purpose. It is a return type that refuses to be misread.

## The four axes

The second idea is that the interesting properties of an artifact are independent, and that squashing them into one score destroys the information you needed. From the doctrine:

> Freshness, quality, acceptance, and authority remain independent axes. A fresh artifact may be wrong; a high-quality artifact may be stale; an accepted artifact may grant no authority.

| Axis | The question it answers | Collapsed form you have seen |
|---|---|---|
| Freshness | is this derived from the current inputs? | "last updated 2 days ago" |
| Quality | does it do what it claims, under test? | "build passing" |
| Acceptance | has an independent actor agreed to it? | "approved" |
| Authority | may an effect be performed because of it? | "approved" again |

The last two share a word in every code review tool on the market, and that is the collapse that hurts most. An approving review means a human read a diff. It does not mean the diff may be deployed to production at 17:55 on a Friday. In a system where agents can act, treating those as one fact is how an agent that received a nice review message concludes it may push.

Gaia keeps them apart structurally rather than by convention: acceptance is a verdict recorded in a receipt, and authority is a separately minted, single-use, human-confirmed grant that lesson 4 looks at.

### Uncertainty is not one number either

The scientific half of the doctrine says the same thing about confidence, in **SCI-05**:

> Report units, nullability, epistemic and aleatoric uncertainty where applicable, sample size, calibration or coverage, sensitivity to assumptions, and known model inadequacy. Do not compress conflict, ignorance, risk, freshness, and confidence into one scalar.

If you have ever seen an agent dashboard with a "confidence: 87%" badge, this principle is the objection to it. Conflict (two sources disagree) and ignorance (no source exists) are different states with different remedies, and a single percentage cannot distinguish them. Gaia's answer when provenance is missing is the value `UNKNOWN`, never an inferred success.

## What follows from that: the doctrine

Once you decide that only replayable things count as evidence, a handful of engineering rules stop being taste and start being forced. Gaia states nine of them; four matter for reading the rest of this course.

### ENG-02 — Design It Twice, at load-bearing seams only

Before creating or changing a public interface, a module seam, a persistent schema, an authority boundary or a cross-repository contract, produce **at least two genuinely different designs** — normally three for a one-way door — varying the optimization target deliberately, and bind the chosen one in a Decision Receipt naming what was rejected.

The procedure is [Matt Pocock's Design It Twice](https://github.com/mattpocock/skills/blob/c0d69015e0cc8b66715beb3f93f9e53256e20f30/skills/engineering/codebase-design/DESIGN-IT-TWICE.md), itself derived from John Ousterhout's module-design method. Gaia adds a warning that matters when an agent generates the alternatives:

> Alternative generation is advisory. Multiple variants from one context are not independent approval, and majority vote does not establish correctness.

Three designs from one model in one conversation are three samples from one distribution. They look like a panel and are not one. You can see the principle applied in the factory's own design document, which records three candidate interfaces — a monolithic script, an arbitrary command runner, and a provider-neutral core with closed provider profiles — and says why the third was selected.

Crucially, ENG-02 also says when *not* to do this: "It is not required for trivial, local, behavior-preserving changes." A doctrine that demands three designs for a typo fix is a doctrine people route around.

### ENG-05 — The smallest end-to-end tracer bullet

> For non-trivial behavior, first build the smallest vertical slice that crosses every required seam and can fail honestly. A green unit test, isolated layer, generated document, or local prototype alone is not integration.

"Can fail honestly" is the load-bearing phrase. A demo wired to succeed crosses the same seams and proves nothing, which is the same objection **SCI-02** raises against confirmatory experiments: *a demonstration that can only succeed is not an experiment.*

### ENG-07 — Reversibility is a typed property

Every change is classified as **freely reversible**, **compensatable**, **migratable** or **one-way**, with the rollback path and the evidence that triggers it stated. One-way doors require explicit human authority and a stricter independent review.

This is the same instinct as a database migration policy — you already treat `DROP COLUMN` differently from `ADD INDEX` — applied to every change, including the ones an agent proposes at 3 a.m.

### ENG-06 — Deterministic, idempotent, replayable transitions

> Repeating the same accepted request must either produce the same result or return the prior result without duplicating effects. Replay from immutable evidence must reconstruct the material decision state.

Lesson 3 is this principle made concrete: a log you can replay twice and get the same state, and a verifier that checks exactly that.

## The artifacts, and the anti-bureaucracy clause

Doctrine like this has an obvious failure mode: it becomes a form to fill in. Gaia's table of required workgraph artifacts is preceded by one sentence that keeps it honest — *"The smallest applicable set is required; trivial work should not manufacture paperwork."*

| Artifact | Gate it informs |
|---|---|
| Mission Brief | permission to design |
| Design Alternatives | seam selection |
| Decision Receipt | permission to implement |
| Experiment Plan | permission to measure |
| Evidence Manifest | reproducibility |
| Transition Receipt | state acceptance |
| Independent Review | promotion |

Read down the right-hand column and the shape appears: each artifact buys exactly one permission. Nothing in the left column *is* authority; each one is the precondition for the next gate to be asked. That is the same separation the vocabulary table in the [mission](../) draws between a claim, an intent and an effect.

## Reproducibility versus replication

One distinction from the scientific half is worth carrying into ordinary engineering, because the words are used interchangeably everywhere else. **SCI-04**:

- **Reproducibility** — an independent actor obtains consistent results using *the same* inputs, code, methods and conditions.
- **Replication** — the claim is tested with *new* evidence or independently collected conditions.

Gaia requires reproducibility before promotion, and replication or held-out evidence for claims intended to generalize. In agent terms: re-running the same prompt with the same seed and getting the same diff is reproducibility, and it is cheap and necessary. It says nothing about whether the approach works on the next repository. Lesson 5 shows where Gaia applies this to itself — the four-lane number is reproducible and explicitly not replicated with real Claude and Codex lanes, and the document says so.

## Key takeaways

- A completion marker is evidence that work stopped, not evidence that its claims are true, and the author of a change cannot approve it (ENG-08).
- Freshness, quality, acceptance and authority are independent axes: an approving review is acceptance, not permission to deploy.
- Uncertainty is not one number either. Conflict and ignorance are different states, and missing provenance is `UNKNOWN`, never an inferred success.
- The doctrine follows: several designs at load-bearing seams only, the smallest tracer bullet that can fail honestly, a reversibility class for every change, and transitions that replay to the same state, without manufacturing paperwork for trivial work.
- Reproducibility, the same inputs giving the same result, is required before promotion; replication with new evidence is what a claim meant to generalize needs.

## Exercises

1. A teammate proposes a dashboard tile: "Agent throughput: 14 tasks/hour, ▲ 30% this week." Name three of Gaia's rejected shortcuts it steps on, and say what the tile would have to measure instead.

<details>
<summary>Solution</summary>

It equates activity and elapsed time with progress; it accepts completion markers as progress, since "tasks" here almost certainly means "sessions that ended"; and it compresses freshness, quality and acceptance into one scalar that then gets a trend arrow. It may also be an in-sample comparison with no baseline (**SCI-06**).

What Gaia measures instead, from the architecture map: *"Delivery metrics measure accepted transitions and receipts, not tokens, lane activity, or prose completion markers."* So the tile would count transitions that reached a terminal state with a receipt, and it would need the denominator too — refused and unsettled transitions — because 14 accepted out of 15 and 14 out of 60 are different weeks.

</details>

2. You are adding a method to an internal helper class: renaming a private field and updating its three call sites in the same file. Does ENG-02 apply? Now you are changing the JSON shape that helper writes to disk. Does it apply then?

<details>
<summary>Solution</summary>

No, then yes. The first is trivial, local and behavior-preserving — ENG-02 names exactly that case as out of scope, and manufacturing two designs for it is the paperwork the doctrine warns against. The second changes a persistent schema, which is on ENG-02's explicit trigger list, because anything already written in the old shape must still be readable or must be migrated. It is also where ENG-07 arrives: a schema change is at best migratable, not freely reversible, so the design has to name the migration or compensation path before it is implemented.

</details>

3. An agent reports: "I could not reach the GitHub API, so I assumed the pull request was created and marked the operation complete." Which principle does this violate, and what should the state have been?

<details>
<summary>Solution</summary>

**SCI-03** — *"Missing or unverifiable provenance produces `UNKNOWN`, not an inferred success."* The architecture map has the operational form of the same rule: *"Transport ambiguity is normalized as an unsettled observation, not a success or refusal guessed from prose,"* and *"Ambiguous remote effects remain nonterminal until reconciled; elapsed time and retries cannot manufacture truth."*

The correct state is `EFFECT_AMBIGUOUS`: nonterminal, retained, and settled only by re-reading the authoritative provider later. Note that the wrong answer here is not only "complete" — "failed" is equally wrong, and for the same reason. The effect may well have happened.

</details>

4. Gaia's doctrine says the author of a change cannot approve it. An agent generates three designs, picks one, implements it, then runs a second session with a reviewer prompt that approves it. Which part of ENG-08 is satisfied and which is not?

<details>
<summary>Solution</summary>

Nothing about ENG-08 is satisfied by the *number* of sessions. The principle requires verification to "bind to exact inputs, digests, tests, controls, and scope" — so a reviewer given the exact candidate identity, a pinned tree and the declared falsifiers is doing verification, and one given a friendly summary of the change is not.

The three designs are separately disqualified by ENG-02's warning: variants from one context are not independent approval. And lesson 4 shows the structural part of the answer — Gaia's factory binds the complete candidate tree before review and refuses if anything changed during it, so "the reviewer approved" is a statement about a specific tree rather than about a conversation.

</details>

## Sources

- Gaia: [engineering and research principles](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/engineering-and-research-principles.md), [`ARCHITECTURE.md`](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/ARCHITECTURE.md), [factory agent design](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/factory-agent-design.md)
- Matt Pocock, [Design It Twice](https://github.com/mattpocock/skills/blob/c0d69015e0cc8b66715beb3f93f9e53256e20f30/skills/engineering/codebase-design/DESIGN-IT-TWICE.md)
- John R. Platt, [Strong Inference](https://doi.org/10.1126/science.146.3642.347) — the source of the "discriminating test" idea in SCI-02
- National Academies, [Reproducibility and Replicability in Science](https://doi.org/10.17226/25303) — the definitions SCI-04 uses
- W3C, [PROV-DM: The PROV Data Model](https://www.w3.org/TR/prov-dm/) — the provenance vocabulary behind SCI-03
