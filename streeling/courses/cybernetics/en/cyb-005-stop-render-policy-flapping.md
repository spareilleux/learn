---
module_id: cyb-005-stop-render-policy-flapping
department: cybernetics
course: "Stop a Render Policy from Flapping"
level: intermediate
prerequisites: ["cyb-004-observe-before-correcting-a-feedback-loop"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Stop a Render Policy from Flapping

> **Draft scope.** Pinned source inspection and constructed observation/decision traces. Human technical review, fluent-language review, learner attempts, live control outcomes and deployed course HTML verification remain pending. No renderer or GPU experiment was run for this lesson.

## The project question

An Observatory agent lowers visual detail after a slow frame, raises it after a faster frame, then lowers it again. Repeated intervention can become part of the disturbance. Three different mechanisms help reason about that behavior: **hysteresis** separates entry and exit thresholds; **persistence** requires repeated qualifying observations; **dwell time** limits how soon another change is permitted. They answer different questions and can delay useful correction.

The [public BRUTAL prototype](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) supplies a concrete case. Its [adaptive source block](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L2916-L2936) adjusts path-tracing bounces. We inspect immutable source at GA commit `76efbffd5af82b46c3146957a6bd4504008eeb89`; this is not an attestation of the current dirty checkout or a live binary.

## 1. Read the existing controller precisely

The source begins with three bounces and a smoothed GPU time of zero. Successful timing queries update the smoothed value with factor 0.05. With a configured `--pt` shader variant (`pt.Length > 0`) and elapsed time **strictly greater than one second** since the last change, the controller reduces one bounce if smoothed GPU time exceeds its budget and the count is above one. It increases one bounce below 65 percent of budget when the count is below three. The default budget is 16 ms, making the recovery threshold 10.4 ms.

The variant is configured from capability and argument checks. A separate runtime toggle, `rtxOn`, affects the parameter sent to rendering. This adaptive block does not check that toggle. Its configuration guard therefore does not attest that path tracing is actively rendering when a decision occurs.

A failed or unavailable query skips this update block. It leaves the stored smoothing, bounce count and last-change time unchanged there; clock time still advances. The inspected block contains no explicit finite/nonnegative validation of a successfully returned elapsed GPU time. API success, available observation and numerical validity must not be treated as identical guarantees.

### Practice exercise 1: apply the strict source guard

Assume a successful query, a configured `--pt` variant, smoothed time 17 ms, budget 16 ms and three bounces. The last change was at time 1. What happens at time 2, then at time 2.001 if the other inputs are unchanged? Does the adaptive guard additionally require the runtime toggle?

> **Answer:** At time 2 the elapsed interval equals one second, so the strict guard does not permit a change. At time 2.001 it exceeds one second, so the count decreases from three to two. The guard checks the configured variant, not the separate runtime toggle. This is arithmetic applied to the inspected predicates, not execution of the renderer.

## 2. Separate a neutral band from a delayed response

The official [MathWorks Relay documentation](https://www.mathworks.com/help/simulink/slref/relay.html) describes state retention between distinct switching thresholds. Our original teaching example uses a two-state setting: high detail is 1 and low detail is 0. It lowers detail strictly above 16 ms and raises it strictly below 10.4 ms. Inside that band, including equality at either threshold, it retains its current state.

This example is a different controller from the source: it uses two settings, no exponential smoothing, two consecutive qualifying valid observations and a minimum elapsed dwell of three seconds. These are advisory teaching choices, not installed policy or validated production thresholds. A neutral-band observation resets the candidate streak. A qualifying streak survives a dwell block; a successful change resets it.

### Practice exercise 2: use the memory in hysteresis

The teaching controller is currently low. Its next observation is 14 ms. Should it raise detail? Would a memoryless rule that chooses high whenever time is at most 16 ms make the same decision?

> **Answer:** The hysteretic rule retains low: 14 ms is not below its 10.4 ms recovery threshold. The memoryless rule chooses high because 14 ms is at most 16 ms. The neutral band's meaning depends on the current state; it is not a third detail setting or evidence that the system is healthy.

## 3. Trace persistence and dwell independently

The authored observations at integer seconds 1 through 17 are `[15,17,15,17,15,14,17,17,14,10,10,14,17,17,10,10,10]` ms. Initial state is high, and initial last-change time is zero. These values are synthetic open-loop inputs: they do not change in response to the policy's actions.

The memoryless rule changes at seconds `[2,3,4,5,7,9,13,15]`, eight times. The teaching policy changes at `[8,11,14,17]`, four times. At second 16, two recovery observations have accumulated, but only two seconds have passed since the change at 14. At second 17, the qualifying streak remains and the three-second dwell requirement is met.

![Constructed GPU-time observations and two setting traces](https://raw.githubusercontent.com/spareilleux/learn/218a2bffc18fe2251956197e882cb6c7ea5d7962/code/streeling/evidence/observatory-decisions-2026-10-22/control-state-traces.png)

The upper plot shows the authored observation and thresholds. In the lower plot, `q_N` is the memoryless rule and `q_H` the teaching policy; 1 means high detail and 0 low detail. It shows decision traces, not a measured improvement in frame pacing or image quality.

### Practice exercise 3: identify which guard blocks a change

Give the two rules' change counts. Why does the teaching policy recover at second 17 instead of second 16? Is the later action caused by an insufficient recovery streak?

> **Answer:** The counts are eight and four. At second 16 the recovery streak already reaches two, but the elapsed dwell is only two seconds. At second 17 dwell reaches three seconds and the continuing streak permits recovery. Dwell, rather than insufficient persistence, blocks the earlier change.

## 4. Count observations before converting them into time

For the source-like exponential recurrence, let every successful constructed observation equal 20 ms and start the smoothed value at zero. After n updates, the value is `20*(1-0.95^n)`. It first exceeds 16 ms at update 32. That is a statement about updates, not a measured 32-frame or 32-second startup delay. Query cadence, the time guard and other conditions still matter.

The source also chooses its time base: recording uses `frame/60.0`, while ordinary operation uses elapsed clock seconds. A recording-time guard can therefore refer to a virtual frame timeline. A controller description that omits its time base can conceal a different rate limit than the reader expects.

### Practice exercise 4: interpret smoothing latency

Does the threshold crossing at update 32 establish when the first source bounce change occurs? Name the additional conditions and distinguish recording time from wall time.

> **Answer:** No. The recurrence establishes only a constructed smoothing crossing. A source change also requires a successful query, a configured variant, a count that can change and elapsed time strictly above one second. Update cadence must be known to map updates to time. Recording uses the frame timeline divided by 60; ordinary operation uses elapsed clock time.

## 5. Test responsiveness as well as switch count

For the teaching trace `[17,null,17,17]`, the missing observation resets persistence, so a change down occurs at second 4. The same authored policy treats zero, negative and nonfinite inputs as invalid, retains state and resets its streak. This explicit policy is not a claim that the inspected source implements those numerical checks.

A controller that never changes has zero switches, yet fails the constructed requirement to respond to persistent over-budget input. Fewer interventions alone is therefore an incomplete objective. The strongest counterargument to persistence and dwell is delayed response to a real overload. A simpler fixed setting may suffice if adaptation adds complexity without improving the actual task.

### Practice exercise 5: write a falsifiable next step

An agent reports “four switches instead of eight proves better control.” Use the missing-data and no-op controls to repair that conclusion and specify a test that could reject the proposed policy.

> **Answer:** The authored trace shows fewer decisions under one rule; it measures no plant response. Missing data must reset its stated streak, while a no-op rule demonstrates why switch count alone is inadequate. A bounded real comparison should measure response delay, adjacent-task performance and visual quality under declared conditions. Reject deployment if those outcomes violate their declared limits, even when switches fall. No such comparison occurred here.

The [fixed control record](../../../../code/streeling/evidence/observatory-decisions-2026-10-22/control-traces.json) and [source boundary record](../../../../code/streeling/evidence/observatory-decisions-2026-10-22/source-controller.json) support the exercises. [FUT-004](../../futurology/en/fut-004-scenario-test-an-observatory-renderer.md) asks how policy choices change across assumed futures; [PHI-004](../../philosophy/en/phi-004-separate-performance-tradeoffs-from-values.md) examines the values hidden in a performance objective.
