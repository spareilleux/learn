# Functional composition course tranche — 2026-10-22

## Scope and status

Three new project-useful English drafts: CS-010 (dependent fail-fast computation), CS-011 (absence and failure boundaries), and NET-005 (fan-out results and dependency joins). Their French and Spanish drafts are part of this tranche. Human subject, fluent-language and learner reviews remain pending. No deployment, public course HTML readback, extension release or current agent-fleet measurement is claimed.

## Source and experiment

`public-input-readback.json` records anonymous immutable GA inputs compared byte-for-byte with local Git objects at `dc2e74cbd992a298f67efb928b5b3754615e1924`, plus documentation URL checks. The unchanged module and MIT notice are retained under `code/streeling/functional-composition/vendor/`; `source.json` binds them. The supplied C# tests were inspected but not executed as a suite.

`native-execution.json` records actual F# Interactive execution with SDK `10.0.113` on Windows. The new teaching assertion runner executes the unchanged module with synthetic inputs. Two runs produced identical JSON observations; 24 assertions passed without compiler warnings. Three temporary negative controls detect a wrong expected result, a broken bind error path and discarded fan-out successes. Canonical source remained unchanged. Initial serializer and documentation-URL preparation failures are retained in that receipt.

The important observation is bounded: returned errors permit partial-result collection, while the tested unwrapped exception escapes. Wrapped exception information is retained through `fromAsync`. The examples do not establish cancellation safety, throughput, durability, arbitrary heterogeneous evidence, or a universal algebraic proof.

## Review and learner boundaries

`lab-static-review.json` is an independent native AI static review of the lab only, including manifest hashes and license. It is not formal CE review or human review. Its optional note about one-sided zip-error coverage is outside the two-error example taught here; no claim of complete branch coverage is made.

`learner-task.md` supplies required inputs and primary-source lookups while withholding answer observations. `reviewer-rubric.json` is separate; all learner fields remain null. This is overlapping source-assisted reasoning, not independent transfer or causal learning evidence.

Code review: skipped (ce-code-review unavailable). The earlier top-level CE attempt terminated without a usable receipt and its transport/cleanup must not be retried; native AI review and host diff inspection are recorded separately. Local source review is not permission to call the courses reviewed or published.

## Integration

`bindings.json` binds all nine source files after locale checks. `validation.json` records actual generator tests, site build, rendered links and source inventory when those checks finish. The original 21-department target remains 525 reviewed and published courses; source-file counts are a separate preparation metric.
