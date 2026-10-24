---
execution: knowledge-work
base_learn_commit: 94dc86a6348d825897887284efec7c54dc4d3aed
source_ix_commit: 456df065ee837e33b5bbe22a4df0616a4fcb76e5
---

# Retry and admission course production plan

Produce NET007 (DAG readiness versus runtime admission), CYB006 (retry workload as feedback), PHI005 (idempotence and observational limits) in English/French/Spanish. Five corrected exercises each, independent data/source and content audits, 15 prepared learner criteria, generator/build/link/idempotence checks, exact public source readback. English/evidence/integration has one writer; scoped translation and review workers own named files. No new runnable lab or production controller/schema is delivered. Temporary calculations outside repository produce fixed authored evidence only.

## Predictions before probes/calculations

- The pinned IX DAG rejects cycles, self-loops, duplicates and missing dependencies. A diamond a→b,c→d has levels [a],[b,c],[d] and readiness width2, independent of any worker limit. A graph with eight independent nodes has readiness width8. Static readiness is not an observation of actual concurrency.
- Read-only ix_pipeline info probes should expose topology for those small graphs and reject a cycle. Actual service revision is unknown; retain any differing/error result. No NL pipeline compiler or model/provider call is allowed.
- The inspected ix-agent run_pipeline loops over topological order, dispatches one tool at a time and exits on error before emitting its final aggregate. Two identical three-step ix_stats-only calls should return correct deterministic numeric values. Since the exposed tool schema has no asset_name field, do not bypass it to request caching; no cache-hit experiment is asserted.
- A deliberate unknown-tool step in a three-node pure-statistics pipeline should produce an error rather than a final partial-results object. Whether an earlier tool actually ran cannot be established from the final error alone. No external-effect tool is called; all computations are bounded arrays.
- With independent per-attempt failure probability1/2 and at most3 attempts, an authored 8-equally-likely-outcome model should yield expected attempts7/4, success7/8 and terminal failure1/8. A fluid mean-rate illustration with6 logical arrivals/second and capacity10 attempts/second then demands10.5 attempts/second; stability requires logical arrival below40/7 per second. This is an assumption-bound model, not a queue benchmark or production capacity measurement. Backoff changes timing, not these fixed-model outcome probabilities.
- An authored delayed-completion trace starts attempts at times0,1,2, each lasting3 ticks. It has peak3 active attempts and completions3,4,5. A two-slot admission control prevents the third start but does not cancel the second already-running attempt. A timeout observation is not proof of stopped work.
- Pure state transition set7 is idempotent while increment is not. Equal response labels can hide different final states; retrying with the same logical deduplication key versus a fresh key must be modeled separately. The pinned cache key binds asset/tool/resolved arguments; a cache hit is not by itself proof of durable external-effect deduplication. These are authored mathematical controls, not a delivered effect executor.

## Actual sources and bounds

Read five public IX files and their exact bytes at the pinned commit, including DAG, executor, editor-facing legacy runner, spec and architecture documentation. Distinguish the ix-pipeline parallel executor from ix-agent's sequential run_pipeline and the canonical PipelineSpec validator from the legacy tool surface. Read actual F# existing course prerequisites only where needed to prevent repetition, RFC9110 idempotence and AWS Builders' Library retry/idempotence guidance. Do not claim bounded search proves repository-wide absence of retries/backpressure.

## Finish

Independent review all fixed inputs/results and all45localized exercise-answer pairs/15learnercriteria. Keep human/fluent/learner outcomes null. Existing18 generator tests, sync, Astro build, all changed article links/anchors and repeat-sync byte equality. Preserve original source.json and three journals. Explicit owned staging/commit, normal push existing Draft201, anonymous exact-byte immutable54-ish-file readback (actual count derived). No PR title/body rewrite or automatic merge. Deployed HTML and human review remain separate full-goal requirements.

## Subsequent source-inspection correction

The initial description of ix-pipeline as a parallel executor followed its comments and was too strong. Reading the actual multi-node branch found direct compute calls inside synchronous iterator.map().collect(), with no thread spawning. Preserve this correction and teach source control flow rather than inferring parallel execution from comments or readiness levels. Neither this source observation nor a missing capacity field proves that the deployed service launches unbounded threads. The actual tool responses also show a changed sibling order between identical requests; their service revision is unknown and must not be identified with the pinned deterministic-order source.
