---
module_id: "inf-013-value-an-evidence-probe-by-expected-information"
department: "information-theory"
course: "Value an Evidence Probe by Expected Information"
level: "intermediate"
prerequisites: ["inf-001-entropy-of-governance", "cog-008-choose-probes-that-distinguish-reasoning-models"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Value an Evidence Probe by Expected Information

> This lesson uses an authored fixed case and inspected sources. Counts, times, labels and signals are invented teaching inputs. Human technical review, fluent-language review, actual learner attempts, runtime execution, production adoption and publication decisions remain undecided.

Several explanations fit a failed agent handoff. A teammate proposes another probe because it produces a detailed report. Detail is useful only if the outcome distinguishes the explanations that matter. The probe-design prerequisite looks for separating responses; this lesson calculates the expected uncertainty left by a declared partition of hypotheses. It keeps the probability model explicit instead of treating the longest report as the most informative one.

The prior assigns equal probability to the authored alternatives. A deterministic probe groups hypotheses by the outcome they predict. Within each group, renormalize the original probabilities before calculating entropy. Average those posterior entropies using the probability of each outcome. This expectation is formed before seeing the probe result. It does not describe a measured report or justify changing the prior after an unrecorded conversation.

[Shannon](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf)’s original entropy definition supplies the logarithmic uncertainty measure. Here base choice gives bits, and equally likely alternatives permit a direct counting check. The balanced partition leaves the same number of alternatives after either outcome. The constant-output control leaves all alternatives possible. That contrast explains why repeating a summary with no new distinguishing observation can add words without adding information under the model.

The retained project record explicitly rejects treating a reread as another trial. It also warns that historical renderer results do not calibrate an authored prior. A composable probe stage could carry the hypothesis set, likelihood model and outcome identity; whether that makes review easier remains a dogfood hypothesis. The direct baseline is a handwritten partition and entropy table. Information gain alone cannot choose the best product action because probe cost and the consequences of remaining errors require another decision model.

## Sources and project boundary

Read the prerequisite before using the model. Inspect the linked retained project artifact at the revision recorded in the packet, and identify the field or branch that supports the stated source observation. The source gives a representation or declared behavior; it does not turn the invented case into an observed project result. The primary reading supplies the named concept within its stated scope.

[Prerequisite: inf-001-entropy-of-governance](../../information-theory/en/inf-001-entropy-of-governance.md)

[Prerequisite: cog-008-choose-probes-that-distinguish-reasoning-models](../../cognitive-science/en/cog-008-choose-probes-that-distinguish-reasoning-models.md)

[Retained project artifact](../../../../code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Primary reading: Shannon 1948 corrected reprint, section 6](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf)

## Fixed model and control

```json
{
  "values": {
    "hypotheses": [
      "a",
      "b",
      "c",
      "d"
    ],
    "probabilities": [
      0.25,
      0.25,
      0.25,
      0.25
    ],
    "probe_outcomes": [
      "left",
      "left",
      "right",
      "right"
    ]
  },
  "formula": "H=-sum(p*log2(p)); expected posterior entropy=sum(P(outcome)*H(hypothesis|outcome)); information gain=prior entropy-expected posterior entropy.",
  "expected": {
    "prior_bits": 2,
    "expected_posterior_bits": 1,
    "information_gain_bits": 1,
    "outcome_probabilities": {
      "left": 0.5,
      "right": 0.5
    }
  },
  "negative_control": {
    "values": {
      "hypotheses": [
        "a",
        "b",
        "c",
        "d"
      ],
      "probabilities": [
        0.25,
        0.25,
        0.25,
        0.25
      ],
      "probe_outcomes": [
        "same",
        "same",
        "same",
        "same"
      ]
    },
    "expected": {
      "prior_bits": 2,
      "expected_posterior_bits": 2,
      "information_gain_bits": 0,
      "outcome_probabilities": {
        "same": 1
      }
    },
    "why": "An outcome shared by all hypotheses cannot reduce uncertainty."
  },
  "assumptions": [
    "Prior probabilities are authored and sum to unity.",
    "Each hypothesis deterministically predicts one error-free probe outcome."
  ],
  "limits": "Bits quantify this model uncertainty, not task utility, truth, time savings or observed experimental evidence."
}
```

### Exercise 1

Compute the prior entropy of the authored alternatives.

<details><summary>Answer 1</summary>

The prior entropy is `2` bits. Each alternative has probability `0.25`, and the entropy equals `log2(4)`. This is uncertainty inside the stipulated model, not uncertainty measured from actual agent failures.

</details>

### Exercise 2

Calculate outcome probabilities and expected posterior entropy.

<details><summary>Answer 2</summary>

The outcomes `left` and `right` each have probability `0.5`. Each leaves two equally likely alternatives with entropy `1` bit, so the expected posterior entropy is `1` bit.

</details>

### Exercise 3

What is the main information gain, and when is that expectation defined?

<details><summary>Answer 3</summary>

It is `2-1=1` bit, defined before the outcome is observed. An actual outcome would select a particular posterior group; its probability and identity must be retained rather than replaced by the expectation.

</details>

### Exercise 4

Apply the constant-output control and explain the result.

<details><summary>Answer 4</summary>

The only outcome has probability `1`, posterior entropy stays `2` bits and information gain is `0`. The probe cannot distinguish any hypothesis despite producing an output message.

</details>

### Exercise 5

Does the most informative probe necessarily produce the best project decision?

<details><summary>Answer 5</summary>

No. Probe cost, decision consequences, model misspecification and noisy outcomes can matter. These quantities are not supplied here. Retain the manual partition and reject an assistant claim that authored information gain proves a real investigation succeeded.

</details>

## Source-assisted learner task

Start with a paper table before revealing the answers. Copy the inputs and their units, apply the declared operation, and retain intermediate results. This direct calculation is the manual baseline against which an assistant or a proposed composable notation must be compared. A shorter response has no demonstrated advantage if it loses an input identity, a failure category or the counterexample.

Then inspect the precise source passage recorded in the packet. Quote only the small field or branch needed for your explanation and record its revision. Ask an assistant to challenge one assumption after you have saved your first answer. Retain the prompt, reply, accepted corrections and rejected suggestions. Source lookup and calculator use are allowed; record them as assistance so the result cannot be mistaken for unaided recall.

Apply the changed input in the negative control and state an observable falsifier before making a recommendation. An unexpected control result requires checking the calculation and assumptions before changing a project workflow. Submit the original answer, corrected answer, assistance history and remaining uncertainty together. The packet prepares five learner criteria, one per exercise, with undecided decisions. Prepared solutions and author checks do not fill those decisions. A future dogfood comparison needs actual attempts on the same task and a retained manual baseline; no new agent mechanism or DSL implementation is required by this lesson.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
