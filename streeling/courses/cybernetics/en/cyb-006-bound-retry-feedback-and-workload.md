---
module_id: cyb-006-bound-retry-feedback-and-workload
department: cybernetics
course: "Bound Retry Feedback Before Adding Workers"
level: intermediate
prerequisites: ["cyb-004-observe-before-correcting-a-feedback-loop", "net-007-separate-dag-readiness-from-admission"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Bound Retry Feedback Before Adding Workers

> **Draft scope.** Pinned public IX source, bounded tool-response evidence and authored probability, workload and delayed-completion models. Human technical review, fluent-language review, learner attempts and deployed course HTML verification remain pending. No real retry controller, queue benchmark, cancellation or external write was executed.

## The project question

An agent sees no terminal result and launches another attempt. That may help a transient failure, but it may also add work while the first attempt is still active. The [AWS Builders' Library discussion of timeouts and retries](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/) explains this feedback risk. This lesson builds explicit small models so an IX controller proposal can be challenged before being installed.

The public [IX runner](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-agent/src/tools.rs#L408-L450), at commit `456df065ee837e33b5bbe22a4df0616a4fcb76e5`, dispatches a step and exits on error. The inspected result model has no retry-attempt lifecycle. This bounded source observation does not prove that no other IX component can retry. [NET-007](../../network-science/en/net-007-separate-dag-readiness-from-admission.md) separates graph readiness from capacity; retries consume that capacity too.

## 1. Count attempts separately from logical requests

The [authored retry model](../../../../code/streeling/evidence/retry-admission-2026-10-22/retry-load-model.json) assumes independent attempts, failure probability 1/2 and at most 3 attempts per logical request. It enumerates eight equally likely pre-sampled outcome strings of length 3. Outcomes after the first success are unused counting devices, not additional executed attempts.

One attempt always occurs. A second occurs with probability 1/2; a third with probability 1/4. Expected work is therefore `1+1/2+1/4 = 7/4` attempts. Only three consecutive failures exhaust the limit, giving terminal failure probability 1/8 and success probability 7/8. These are model values, not measured tool reliability or confidence in a real artifact.

### Practice exercise 1: calculate retry amplification

Under the declared assumptions, calculate expected attempts and success probability. In the pre-sampled string SFF, how many attempts actually execute? Does the model execute all three outcomes for every request?

> **Answer:** Expected attempts are 7/4 and success probability is 7/8. SFF executes only its first attempt because it succeeds. Later pre-sampled outcomes are ignored; the enumeration represents probabilities and does not force three executions after success.

## 2. Compare offered workload with attempt capacity

Suppose a fluid mean-rate illustration receives 6 logical requests per second and can process 10 attempts per second. Under the same independent model, expected demand is `6*7/4 = 10.5` attempts per second. It exceeds capacity by 0.5 attempt-work units per second, or 15 over 30 seconds. That last value is mean offered-work excess, not a sample showing exactly 15 queued jobs.

The logical arrival boundary is `10/(7/4) = 40/7` requests per second. Remaining strictly below it leaves spare mean-rate capacity in this simplified illustration. Equality supplies no spare capacity and is not a general stochastic-queue stability proof. Real costs, correlated failures, finite buffers and scheduling require actual measurements.

### Practice exercise 2: locate the bottleneck

Calculate the offered attempt rate and the logical arrival boundary. Can the fact that 6 is less than 10 establish spare capacity? What does the number 15 represent here?

> **Answer:** Offered demand is 10.5 attempts per second and the boundary is 40/7 logical requests per second. Comparing 6 logical requests directly with 10 attempts mixes units and ignores retries. The 15 represents mean excess attempt-work demand over 30 seconds under the fluid assumptions, not an observed queue length.

## 3. Separate smoothing from reducing expected work

Backoff changes when an attempt is offered; jitter spreads synchronized retries. Under this fixed independent-outcome model, changing retry times alone does not alter the probabilities 1/2 or 1/4 that later attempts are needed. It therefore does not change expected attempts 7/4. In an actual load-dependent system, delaying an attempt might change its failure probability; that is a different model needing evidence.

The persistent-failure control instead gives every attempt failure probability 1. Three attempts then consume 3 units and produce no success. Blindly retrying a permanent validation error cannot be justified by the earlier transient-failure calculation. A useful controller proposal needs failure classification, a bounded attempt policy and a test against the simpler single-attempt baseline.

### Practice exercise 3: challenge an improvement claim

A proposal adds random retry delays and claims to reduce expected attempts from 7/4 without changing the independent failure model. Is that derived from these assumptions? What happens in the persistent-failure control?

> **Answer:** No. Timing changes alone leave the fixed attempt probabilities and expected work unchanged. A reduction would need a changed, supported outcome model or policy. In the persistent-failure control, the limit permits 3 failed attempts and success remains 0.

## 4. A timeout does not prove that work stopped

The [authored delayed-completion trace](../../../../code/streeling/evidence/retry-admission-2026-10-22/delayed-completion-model.json) starts attempts for one logical request at ticks 0, 1 and 2. Each lasts 3 ticks, so they complete at 3, 4 and 5. Immediately after the third start, 3 attempts are active. A one-tick observation timeout was shorter than the work duration; the first attempt remained active by construction.

A two-slot admission rule prevents the third start. It leaves starts at 0 and 1, completions at 3 and 4 and a peak of 2 active attempts. Accepting the first result at 3 does not, in this model, cancel the second attempt. Capacity admission, cancellation acknowledgement and deduplication of intended effects are separate mechanisms. No real remote task was stopped or restarted for this exercise.

### Practice exercise 4: follow the late attempt

Give completion times and peak active attempts in the unbounded trace and the two-slot trace. After accepting the first result at tick 3, can the controller assume the second attempt has stopped?

> **Answer:** The first trace completes at 3, 4 and 5 with peak 3. The two-slot trace completes at 3 and 4 with peak 2. It cannot assume the second attempt stopped: this model supplies no cancellation acknowledgement, and that attempt remains active until 4.

## 5. Make the controller proposal falsifiable

The [actual IX probes](../../../../code/streeling/evidence/retry-admission-2026-10-22/execution-tool-probes.json) include an error from a deliberately unknown tool. They provide no full partial-results packet. That missing packet does not prove that all previous work was absent. An external controller that relaunches an entire pipeline after every missing aggregate could repeat completed effects.

A proposed controller should name the logical request and each attempt separately, observe starts and terminal states, bound admission and retry work, and state how it handles unknown outcomes. Compare it against a single-attempt baseline using accepted outcomes, total attempts, active work and unresolved effects. Reject an apparent gain that only increases launched attempts while accepted results stay flat. These are candidate evaluation criteria, not a new installed IX policy. [PHI-005](../../philosophy/en/phi-005-test-idempotence-beyond-replayed-values.md) examines the evidence required to call repeated effects idempotent.

### Practice exercise 5: choose a discriminating observation

A controller claims recovery because it launched 3 attempts instead of 1. Accepted logical results remain at 1, and one earlier attempt has unknown status. Does this prove improvement? Name two observations needed before broadening the policy.

> **Answer:** No. Launched attempts measure effort, not improved accepted outcomes. Observe each attempt's start and terminal or acknowledged cancellation state, and reconcile the intended external effect using its logical identity. Also compare total attempt work and accepted results against the baseline; an unknown earlier outcome cannot be replaced by an assumed stop.

## Source-assisted learner task

Use the [prepared task](../../../../code/streeling/evidence/retry-admission-2026-10-22/learner-task.md) to reconstruct the probability enumeration, unit-consistent workload and delayed trace. Explain a rejection criterion for a retry proposal. Actual learner, human-review and runtime-controller outcomes remain pending.
