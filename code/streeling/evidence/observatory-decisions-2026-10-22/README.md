# Observatory control, scenarios and values

This packet supports CYB005, FUT004 and PHI004 in English, French and Spanish. It contains fixed numerical analysis, original scientific figures and prepared source-assisted tasks. No new production or teaching-lab program is delivered.

## Inputs and boundaries

- experiment-plan.md records the constructions and predictions before numerical analysis.
- primary-readback.json binds three anonymously fetched public GA files byte-for-byte to commit76efbffd5af82b46c3146957a6bd4504008eeb89. The dirty primary checkout is not the teaching snapshot or a run target.
- source-controller.json describes the inspected success block: factor0.05 smoothing, three bounded bounce levels,16ms default budget,0.65 recovery ratio and strict elapsed-time guard greater than1second. Its configured-variant guard is distinct from the runtime RTX toggle, which is not checked in that block. A query availability guard is not explicit numerical validation. Failed queries leave stored state unchanged within that block while the clock still advances.
- control-traces.json contains authored open-loop inputs, a memoryless two-state rule, an advisory persistence/dwell rule, boundary comparisons, invalid/missing-input controls and a constant-high no-op counterexample. Neither rule was run against a renderer or simulated plant response. The source-like exponential recurrence is arithmetic, not native source execution or an observed startup latency.
- scenario-decisions.json contains invented loss-point tables, regret and conditional expected-loss calculations. The labels do not certify real implementations. Probabilities are stipulated; loss scales and scenario completeness are assumptions. Adding an omitted scenario reverses the minimax-regret choice.
- value-tradeoffs.json contains separate invented detail/adjacent-overhead attributes, dominance, score weights, ties, a hypothetical hard constraint and a unit-error control. It records no benchmark, elicited preference, stakeholder agreement or ethical mandate.
- control-state-traces.png and two-attribute-options.png are original scientific figures of these authored examples. Their symbolic axes/labels are explained in each localized course. No third-party media or illustration was copied.
- execution.json records installed analysis versions and the temporary analysis script's hash. The script lives outside the deliverable; no renderer, source controller, GPU test or dependency installation was invoked.
- image-source-readback.json verifies three immutable raw PNG URLs, their actual image MIME type, decoder validity and exact committed bytes. Its negative control shows why a200HTML GitHub file page is insufficient. Two figures were published first to make immutable image references available.
- image-link-fixes.json records nine image-target-only replacements: six new course sources and the three prior PHY007 locale sources. No exercise, prose, metadata or image bytes changed. The older PHY007 review receipt continues to bind historical bytes; the current content review separately checks the amended pages. No generator code changed.
- learner-task.md and reviewer-rubric.json prepare three tasks and fifteen criteria. Outcomes remain null.
- data-audit.json and content-audit.json bind independent AI checks to their declared inputs; they are not human, fluent-language, learner or operational approval.
- rendered-images.json checks final built HTML references and anonymous decoded PNG bytes for all nine image occurrences. This is not a public deployed-HTML or browser-rendering receipt.

## Primary reading

The official [MathWorks Relay documentation](https://www.mathworks.com/help/simulink/slref/relay.html) was read for stateful hysteresis between distinct thresholds. [RAND's own Robust Decision Making page](https://www.rand.org/pubs/tools/TL320/tool/robust-decision-making.html) was read for decision framing, uncertainties and evaluation across futures. The authored [Stanford Encyclopedia of Philosophy Decision Theory entry](https://plato.stanford.edu/entries/decision-theory/) was read for beliefs, values and normative choice. The courses use brief independently written explanations and original exercises, not copied examples, figures or prose.

The browsing tool returned readable page content for all three. Separate direct requests returned403 for MathWorks and RAND and200 for Stanford; failed direct requests are retained and do not claim successful page-byte attestation. official-links.json records the course URLs and these separate observations.

## Limits and next evidence

The public README's adaptive rendering results are historical reports, not fresh binary attestation or current hardware performance. The earlier inconclusive coexistence follow-up remains inconclusive. This packet does not fill that evidence gap with synthetic numbers.

Any production controller proposal needs separately declared quality, response-delay, adjacent-task and resource constraints, appropriate authority, and actual controlled outcomes. These authored hypotheses do not ratify a policy or promise stable control, universally optimal choices, exponential progress or preparedness for every future. Human technical review, fluent-language review, learner attempts, user preference elicitation, live outcomes and deployed HTML verification remain pending.
