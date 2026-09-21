# Research: Can TypeSafe System One genuinely reduce tokens and cost?

Date: 2026-09-20

## Question

Can TypeSafe AI's Jev/System One reduce token consumption or total cost for the
GA, Gaia, and Demerzel workloads, rather than merely move usage to another
provider?

## Short answer

**Plausible for narrow decisions, not yet proven for these repositories.** Jev
does not replace a coding or reasoning agent. It can reduce *expensive-provider*
tokens and dollars when it replaces a closed decision, filters context before a
generative call, or prevents an unnecessary large-model call. It can increase
total work when it is added as a verifier and most items still escalate.

The defensible optimization target is therefore not "tokens" in the abstract.
Token counts from different model families use different tokenizers and should
not be added as though they were one unit. Measure all of the following:

1. tokens consumed by each provider and category;
2. total dollar cost at the price in effect on the run date;
3. successful-task rate and safety errors;
4. latency and retry rate.

No TypeSafe or model-provider API call was made for this note. The percentage
savings for the three repositories is unknown until the experiment below is
run.

## Source snapshot

Only first-party sources were used.

| Source | Snapshot or review date | What it establishes |
| --- | --- | --- |
| [TypeSafe launch note](https://typesafe.ai/blog/introducing-system-one-models-and-jev) | Published 2026-09-15 | Vendor architecture, pricing and benchmark claims, including its own caveats |
| [TypeSafe introduction](https://docs.typesafe.ai/introduction) | Read 2026-09-20 | Typed questions, parallel independent evaluation, no text generation |
| [TypeSafe model card](https://docs.typesafe.ai/models) | Read 2026-09-20 | Jev 1.13 price, limits, aliases, language support and data handling |
| [How to build with TypeSafe](https://docs.typesafe.ai/concepts/how-to-build-with-system-one) | Read 2026-09-20 | Keep control flow and deterministic work in code; use narrow model judgments |
| [Jev 1.13 jaggedness](https://docs.typesafe.ai/model-jaggedness/jev-1.13) | Last reviewed by vendor 2026-09-17 | Known weaknesses: literal interpretation, math, counting, dates, long distractor state and prompt injection |
| [Parallel questions cookbook](https://docs.typesafe.ai/cookbooks/parallel_questions) | Read 2026-09-20 | Vendor A/B of one batched request versus repeated Jev requests |
| [Skill suggestion cookbook](https://docs.typesafe.ai/cookbooks/skill_suggestion) | Published run rendered 2026-07-31 | Progressive skill selection and measured selection-error rates |
| [SDE cascade cookbook](https://docs.typesafe.ai/cookbooks/sde_cascade) | Read 2026-09-20 | Cheap extractor, Jev verifier and expensive-model escalation pattern |
| [System One adapter README](https://github.com/typesafe-ai/system-one-adapter-python/blob/adffc2eab300a4fa3c0e92252d4ffd6ceaa53700/README.md) | `adffc2e` (`v0.2.0`) | Same request contract on an LLM; aggregate token and retry telemetry |
| [Python SDK responses](https://docs.typesafe.ai/sdk/python/api/types/responses) | Read 2026-09-20 | Jev responses expose input and output token counts when reported |
| [OpenAI token accounting](https://help.openai.com/en/articles/4936856-wha) | Read 2026-09-20 | Input, cached-input, output and reasoning token categories are distinct |
| [Claude prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) | Read 2026-09-20 | Cache-write, cache-read, uncached-input and output accounting |

## What the mechanism actually does

Jev takes one `state` plus typed `Choice`, `Score`, and `Noul` questions. It
returns values and probability distributions rather than generating prose.
Questions are evaluated independently and in parallel against the same state.
TypeSafe currently bills Jev 1.13 input at USD 0.042 per million tokens and does
not bill output tokens. The API still reports output token usage: "free output"
is a price statement, not a claim that no output tokens exist.

This creates four possible sources of savings:

1. **Replace generation with a closed decision.** A route, label, risk band or
   yes/no gate no longer needs a prose answer, JSON repair, or corrective retry.
2. **Avoid a large-model call.** A cheap generator plus Jev verifier can accept
   easy cases and send only uncertain or failed cases to the expensive model.
3. **Shrink later context.** Jev can filter retrieved passages, candidate skills,
   or review findings before the generative agent sees them.
4. **Share state across independent questions.** One request ingests the state
   once and evaluates many questions. TypeSafe's 13-question cookbook reports a
   12.2x cost reduction and 10.0x sequential-latency reduction versus thirteen
   separate *Jev* requests over a roughly 54,000-character document. That result
   demonstrates batching within Jev; it is not evidence of a 12.2x saving versus
   a coding agent.

The TypeSafe skill-suggestion cookbook illustrates an important nuance. It
keeps the agent's complete 16,089-character skill index in its prompt so prefix
caching remains stable, then adds one suggested skill name. It reduced wrong and
needless skill loads in the vendor experiment, but it does **not** directly
remove that base roster from the agent prompt. Token savings, if any, would come
from avoiding wrong `skill_view` calls and the irrelevant skill bodies those
calls would have loaded. That needs a separate token measurement.

## Token and cost ledger

| Category | Expected direction when Jev is useful | How it can grow |
| --- | --- | --- |
| Expensive-model uncached input | Down if Jev filters context or avoids the call | Unchanged if the full prompt is still sent; up if Jev output is appended |
| Expensive-model cached input | Down only if calls are avoided | A warm cache may already make the baseline cheap, narrowing Jev's benefit |
| Expensive-model visible output | Down when generation is replaced or skipped | Unchanged on escalation; extra if the pipeline asks for an explanation |
| Expensive-model reasoning tokens | Down when a reasoning call is skipped | Can be unchanged or higher if Jev introduces another review/revision loop |
| Jev input | New usage in every Jev arm | Grows with state, instructions, criteria and number of questions |
| Jev output | New usage, currently unbilled | Still record it; zero price is not zero work and pricing can change |
| Retries and malformed-output repair | Usually down for typed shape | Network retries remain; LLM adapter correction retries can multiply tokens |
| Total dollars | Down only if avoided model cost exceeds Jev plus added calls | Up when escalation is common, prompts are small/cached, or Jev makes errors |

Raw Jev tokens and raw OpenAI/Anthropic tokens are not a meaningful single total
because tokenization differs. Report provider-specific token counts, bytes or
characters of byte-identical input, and dollars. A secondary "expensive-model
tokens avoided" metric is useful because it is within one tokenizer.

## Claims versus facts

### Directly inspectable facts

- The SDK and HTTP contract constrain the response shape to declared question
  types and expose probability-bearing answers.
- The current model card lists USD 0.042 per million input tokens and free
  output, a 64k per-request context budget, and a 32k budget for `state` plus the
  longest question.
- The SDK exposes `input_tokens` and `output_tokens` when the API reports them.
- The official LLM adapter exposes totals across retries, malformed-structure
  retry counts, latency, and the individual provider attempts, making a fair
  comparison instrumentable.
- Jev cannot write code or prose. TypeSafe explicitly describes it as a software
  primitive, not an agent.

### Vendor claims that still require independent verification

- The launch note's 40x-200x speed range and the workflow site's larger cost and
  speed ratios are TypeSafe measurements, not independent results for our data.
- TypeSafe says its published workflow gains are likely at the high end of
  real-world gains and acknowledges possible workflow-author bias.
- "Cannot hallucinate" should be read narrowly as "cannot return a value outside
  the declared type/schema." The same official documentation says Jev can select
  the wrong valid answer, take wording too literally, mishandle numeric and date
  reasoning, degrade with irrelevant context, and be influenced by prompt
  injection in state.
- Calibration and self-consistency must be measured on our distribution and
  language. English is currently the model's strongest language.

## Reproducible A/B benchmark

Run two complementary experiments. The first tests Jev as a direct decision
engine. The second tests whether it actually removes expensive agent work.

### Corpus and labels

1. Build immutable, sanitized fixtures from historical GA, Gaia and Demerzel
   artifacts. Store a SHA-256 for each canonical JSON fixture.
2. Include easy, ambiguous, adversarial and "none of the above" cases. Preserve
   the production distribution in the scored test set.
3. Establish labels with deterministic facts where possible. For subjective
   decisions, use blind human adjudication with a written rubric. Do not use
   Astra or Fable consensus as the sole ground truth for a benchmark that will
   compare against those families.
4. Split development and test data before writing thresholds. Never tune on the
   final test set. Determine the final sample size from a power analysis for the
   chosen quality margin and minimum worthwhile dollar saving. A small pilot can
   debug the harness but cannot justify a savings claim.

### Experiment 1: direct closed-decision replacement

Use the same canonical `state` and question objects for both arms.

- **Arm A, LLM:** TypeSafe's pinned `system-one-adapter` with one exact provider
  model snapshot, native structured output enabled, the same question semantics,
  and a fixed reasoning/effort setting.
- **Arm B, Jev:** `TypeSafeClient` with the exact model id `jev-1.13.0`, not the
  moving `jev-latest` alias.

This experiment necessarily changes the model. It holds the task, input bytes,
question schema and evaluation fixed. It answers whether Jev is a cheaper
decision engine at an acceptable quality level; it does not isolate routing.

### Experiment 2: end-to-end cascade or router

Hold the generative models and their prompts identical across arms.

- **Arm A, current path:** every item goes through the existing fixed cheap and/or
  frontier model path.
- **Arm B, Jev path:** the same cheap generator (if any) runs first; Jev makes one
  pre-registered gate decision; items that fire the gate go to the exact same
  frontier model and prompt used by Arm A. The fallback on Jev failure is also
  fixed before the run.

This experiment isolates whether Jev avoids enough frontier calls to pay for
itself without losing quality. Do not let the Jev arm receive less source content
unless filtering is the feature being tested; in that case, record the filtered
and retained bytes explicitly.

### Execution controls

- Pin all model ids, SDK versions, prompts, schemas, thresholds and price cards.
- Serialize state and questions canonically; keep fixture bytes identical between
  comparable calls.
- Randomize and interleave arm order to reduce time-of-day and service-load bias.
- Run cold-cache and production-realistic warm-cache strata separately. Do not
  compare a cold LLM baseline with a warm Jev path.
- Repeat nondeterministic cases enough times to estimate variance; choose the
  repeat count before seeing results.
- Cap retries identically where semantics permit. Record every attempt and error.
- Do not stop early when a favorable result appears.

### Metrics per item and per arm

Record a machine-readable row with:

- fixture id and SHA-256, workload, language, expected label/action;
- provider, exact model id, SDK version, prompt/schema version;
- uncached input, cached input/cache-write/cache-read, visible output and reasoning
  tokens when exposed;
- Jev input and output tokens separately;
- provider calls, retries, malformed-structure retries and fallback/escalation;
- wall-clock latency plus p50/p95 summaries;
- billed or price-card dollars, with price date and currency;
- exact-match or rubric score, success, false accept, false reject, and human
  review outcome;
- bytes retained or removed before any downstream generative call.

OpenAI distinguishes regular input, cached input, output and internal reasoning
tokens. Claude reports uncached `input_tokens`, `cache_creation_input_tokens`,
`cache_read_input_tokens` and output tokens. Missing telemetry is "unknown," not
zero.

Primary outcomes:

```text
quality_adjusted_cost = total_dollars / successful_tasks
frontier_tokens_avoided = baseline_frontier_tokens - treatment_frontier_tokens
net_dollars_saved = baseline_total_dollars - treatment_total_dollars
escalation_rate = escalated_items / all_items
```

Report confidence intervals for cost and quality deltas, not only means. Publish
the full distribution because a cheap average can hide costly or unsafe tails.

## Repository-specific candidates

These are benchmark candidates, not implementation recommendations until they
pass the test.

### GA

- **RAG passage filter:** use deterministic retrieval first, then Jev to mark
  relevance, contradiction and prompt-injection risk before a fixed Sol/Astra
  answerer. Measure downstream context bytes, answer correctness and citation
  support.
- **Skill or specialist router:** choose one music-theory/analysis capability, or
  no skill, before the agent loads a large skill body. Measure wrong loads,
  needless loads, tool calls and loaded skill tokens.
- **Citation checker:** after deterministic quote lookup, classify whether local
  context supports a generated musical or architectural claim. This may reduce
  expensive re-review, but it adds a Jev call to every checked citation.

Do not give Jev pitch arithmetic, interval counting, date comparison or code
generation; those conflict with the published jaggedness profile.

### Gaia

- **Issue and review routing:** map an issue/review result to a bounded lane,
  specialist, or human escalation. Keep authorization, budgets and side effects
  in code.
- **Candidate-evidence semantic gate:** after deterministic receipt/schema/SHA
  checks, judge narrow semantic claims such as whether evidence actually supports
  a declared result. A high-confidence pass can avoid a full frontier review only
  if false accepts remain below the pre-registered safety bound.
- **Agent-trace observability:** classify an already-completed trace for likely
  human review. This matches one of TypeSafe's published workflow shapes, but our
  Gaia traces and labels must be evaluated independently.

Jev must never decide merge authority, spend authority, registry history, expiry,
job counts, or cryptographic identity. Those remain deterministic controls.

### Demerzel

- **Artifact-to-tribunal routing:** select the relevant reviewer/pipeline or
  reject all choices, reducing irrelevant context loaded by a general agent.
- **Semantic contract support:** run deterministic JSON Schema and invariant
  validation first; use Jev only for a narrow question such as whether narrative
  evidence supports a typed claim.
- **Evidence triage:** rank or filter passages before a fixed governance reviewer,
  then measure whether the smaller context preserves the final verdict.

Jev must not replace constitutional rules, IXQL execution, numeric thresholds,
temporal ordering, signatures or final accountable authority.

## Confounders and failure modes

- **Prompt caching:** a long stable LLM prompt can be cheap on cache reads. A Jev
  comparison that ignores cache categories exaggerates savings.
- **Subscription versus API accounting:** avoiding API tokens can save dollars;
  avoiding turns inside a flat-rate or quota-based Codex/Claude plan may not map
  linearly to dollars. Jev introduces its own marginal API charge.
- **Different tokenizers:** identical bytes need not produce identical token
  counts. Compare provider-specific tokens and dollars, not a cross-provider sum.
- **Batching:** Jev's large batching win compares one Jev request with many Jev
  requests. The correct baseline may already batch or cache its context.
- **Escalation prevalence:** a verifier saves money only when enough cases avoid
  the expensive rung. High escalation produces Jev cost plus the original cost.
- **Error asymmetry:** a false accept in an authority or safety gate can cost far
  more than many correct cheap decisions. Average accuracy is insufficient.
- **State construction:** extracting or summarizing state may itself consume
  tokens. Charge preprocessing to the treatment arm.
- **Model and price drift:** `jev-latest`, provider aliases and price cards move.
  Pin ids and retain the rate sheet used for each run.
- **Language mix:** French repository discussion and multilingual artifacts may
  underperform the English benchmark. Stratify by language.
- **Untrusted state:** TypeSafe documents that adversarial state can steer Jev.
  Include prompt-injection fixtures and never convert model confidence into
  authority.
- **Provider failures and retries:** rate limits, timeouts and malformed LLM
  adapter outputs can change both cost and latency. Measure all attempts.

## Acceptance and rejection criteria

Pre-register concrete numerical bounds from repository risk tolerance before
running. The optimization is accepted only if all required conditions hold on
the untouched test set:

1. the lower confidence bound on dollar saving exceeds the team's minimum
   worthwhile saving;
2. quality is non-inferior to baseline within the pre-registered margin;
3. false accepts for authority/safety-sensitive cases stay below their stricter
   bound (often zero in the finite test set, followed by continued monitoring);
4. p95 latency meets the path's service-level objective;
5. the result survives the production-realistic cache stratum and includes all
   retries, preprocessing, Jev calls and fallback calls;
6. savings occur on each intended repository workload, or deployment is limited
   to only the workload where they occur.

Reject or narrow the integration if any of these are observed:

- no statistically supported dollar reduction;
- quality or safety outside the agreed margin;
- most items escalate, leaving Jev as pure overhead;
- savings disappear with realistic LLM prompt caching;
- the benefit depends on hand-tuned test prompts or a moving model alias;
- the workflow needs generation, multi-hop reasoning, precise arithmetic or
  authority rather than a bounded semantic decision.

## Recommended first experiment

Start with the lowest-authority, easiest-to-label case: **GA or Demerzel passage
filtering before a fixed answer/review model**. It provides deterministic source
passages, measurable retained bytes, a direct downstream-token effect, and no
merge or execution authority. In parallel, run the direct decision-engine A/B on
the same relevance labels through the official System One adapter.

Do not begin with Gaia merge/readiness authority. Once the harness proves savings
and false-accept behavior on filtering, reuse it for Gaia's non-authoritative
review routing, still with deterministic gates and human/host authority intact.
