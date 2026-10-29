---
module_id: cog-005-separate-pitch-estimates-from-listener-reports
department: cognitive-science
course: "Separate Pitch Estimates from Listener Reports"
level: intermediate
prerequisites: ["cog-004-score-a-pitch-discrimination-task", "gas-005-separate-a-partial-peak-from-a-period"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separate Pitch Estimates from Listener Reports

> **Draft scope.** Original mathematical signal contrasts and a prepared listening-task design. Human technical, musician/listener, fluent-language and learner reviews and deployed course HTML verification remain pending. No participant, played stimulus, perceptual response or learning outcome was observed.

## The project question

A guitar agent predicts a repetition frequency, then treats a listener who reports another pitch as mistaken. It has changed the question from “what did the person hear?” into “which answer matches my algorithm?” A useful dogfooding exercise keeps those two outcomes separate.

The [indexed abstract of Oxenham's 2012 review](https://pubmed.ncbi.nlm.nih.gov/23015422/) describes repetition rate as a principal physical correlate of pitch while emphasizing interactions that complicate perception. Only that abstract was read for this lesson; no full-paper protocol or recording was replicated. The original examples below compare explicit numerical predictions. They establish no universal percept or individual listener classification.

## 1. State the response before choosing its answer key

A technical task can ask for a supplied signal's fundamental period. Its answer follows the declared mathematics. A perceptual task can ask which of two sounds seems higher to the participant, or ask them to match a reference tone. That outcome is a recorded response with its own units and procedure. It is not automatically the same variable as a spectral peak, recurrence lag, realism preference or learning score.

If the goal is algorithmic accuracy against a known constructed frequency, declare that reference and scoring rule. If the goal is to investigate perception, preserve the participant's response before interpreting it. “Different from the detector” can be an observation; “wrong” requires a justified task-specific criterion.

### Practice exercise 1: separate the outcomes

An evaluator asks “Which sounds higher?” but scores only agreement with an autocorrelation result. What distinction has been lost, and what should be retained?

> **Answer:** The evaluator has substituted a model-defined technical reference for a perceptual response. Retain the actual question, stimulus conditions, participant choice or match, and the separate algorithm prediction. Agreement may be analyzed under an explicit hypothesis, but it does not retroactively define what the participant heard or measure realism or learning.

## 2. Construct opposing numerical predictions

The [original controls](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/synthetic-periods.json) use one-second, zero-phase cosine sums with amplitudes 0.3, 0.2 and 0.1 at sample rate 48000 Hz:

| Complex | Supplied components, Hz | Strongest component, Hz | Fundamental repetition rate, Hz |
| --- | --- | --- | --- |
| A | 1000, 1200, 1400 | 1000 | 200 |
| B | 1050, 1200, 1350 | 1050 | 150 |

The strongest component rises by 50 Hz from A to B, while the repetition frequency falls by 50 Hz. Their cent changes are approximately +84.467193470 and -498.044999135, respectively. These are two opposing numerical comparisons, not a prediction that every listener must use either one or even experience one unambiguous pitch.

### Practice exercise 2: preserve the conflict

Which complex is higher under the strongest-component comparison, and which under the fundamental-repetition comparison? Can this table alone determine an actual participant's choice?

> **Answer:** B is higher by the strongest-component comparison, 1050 versus 1000 Hz. A is higher by fundamental repetition, 200 versus 150 Hz. The mathematical conflict motivates a response task; it supplies no observed participant choice or proof that all perception follows one rule.

## 3. Mathematical level matching does not certify playback

For the unfaded coherent controls, the mean-square value is `(0.3²+0.2²+0.1²)/2 = 0.07`, so both RMS values are approximately 0.264575131. Their zero-phase peaks are 0.6. Those equalities concern the original arrays. The analysis generated no listening WAVs and played nothing.

A real trial needs prepared playback artifacts, onset/offset treatment, verified level and format, a recorded playback chain and a procedure that avoids revealing the intended answer. Applying fades changes the arrays; remeasure the actual artifacts instead of copying the unfaded RMS value into their metadata. Numerical RMS matching also does not establish equal perceived loudness or remove every spectral cue.

### Practice exercise 3: distinguish a fixture from a ready trial

Compute the mathematical mean-square and RMS values. An agent then adds fades and claims the final stimuli are already matched and tested. What evidence is missing?

> **Answer:** Mean square is 0.07 and RMS is approximately 0.264575131 for each unfaded coherent array. The actual faded/encoded artifacts need hashes, new level/peak measurements, playback conditions and a captured presentation trial. Equal unfaded arithmetic is neither an executed playback test nor equal perceived loudness. No listening artifacts or participants were produced here.

## 4. Keep order, instructions and interpretation independent

Before a future trial, define the participant response, instructions, permitted familiarization, presentation order and analysis. Counterbalance A/B and B/A presentations without exposing the mathematical labels. Record actual stimulus identities, order, response and any exclusions. Do not coach participants to choose the detector's answer while claiming to study an unprompted perception.

An unambiguous pure-tone control can check whether the participant understood the requested direction under its stated conditions. It does not establish that an ambiguous complex must be judged by the same cue. A matched-tone task may reveal different information from a forced comparison; changing the task changes the outcome. [COG-004](cog-004-score-a-pitch-discrimination-task.md) separately treats response keys and exact chance scoring.

### Practice exercise 4: repair a biased procedure

The interface labels A “200 Hz, correct” before asking which sounds higher. The evaluator then calls disagreement a hearing error. Propose a better procedure and a bounded interpretation.

> **Answer:** Hide the model labels during the perceptual task, declare the question and counterbalanced order, retain actual responses and use suitable comprehension controls. Compare responses with separate algorithm predictions afterward under a stated hypothesis. Disagreement alone does not diagnose a hearing problem or prove the participant misunderstood an ambiguous complex. No such participant test occurred here.

## 5. Return different evidence to different decisions

For detector calibration, use the known constructed periods and explicitly defined tolerances. For an engine tuning task, retain the estimator's reference, uncertainty and actual rendered inputs. For a perception or preference claim, require the corresponding participant procedure and observations. For learning, require an appropriate learner assessment. None can be supplied merely by changing the name of a numerical score.

The [retained guitar analysis](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/native-pitch-windows.json) has four high-scoring recurrence estimates that fail its declared nominal-reference proximity check. That is a concrete warning about score interpretation, not evidence of what a guitarist heard. The prepared task in this packet remains unperformed and its outcomes remain null.

### Practice exercise 5: write the agent's conclusion

An agent claims “High periodicity confidence proves listeners prefer the corrected guitar.” Replace this with supported statements and the missing evidence.

> **Answer:** The recurrence score describes waveform agreement under the declared estimator; it is not calibrated perceptual confidence. Constructed controls verify selected mathematical predictions, and retained-window reports fail the stated nominal-reference check. Listener pitch, guitar preference and any benefit from a correction need their own actual stimuli, comparison protocol and responses. No correction, preference or listening result was observed here.
