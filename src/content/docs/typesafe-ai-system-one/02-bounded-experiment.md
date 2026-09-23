---
title: "2. A reproducible, cost-bounded experiment"
description: Run the deterministic fixture first, inspect the contract and routing tests, then prepare one optional live Jev call with a local request-size guard, explicit stop conditions and an evidence record.
sidebar:
  order: 2
---

The experiment starts with a falsifiable question:

> Can a typed probabilistic recommendation be inserted into a Gaia-style gate without letting the provider create authority or an unbounded cost?

The hypothesis is narrower than “Jev is good”: the same deterministic routing policy should accept a valid closed response, refuse an invented option, refuse malformed probabilities, and route to human review when explicit authority is absent. A live call is only a later measurement of model behavior.

## Phase A — offline baseline

From the repository root:

```bash
cd code/typesafe-ai-system-one
python typesafe_lab.py mock
python -m unittest -v
```

Measured locally on 2026-09-20 with Python 3.14.2:

```text
{
  "mode": "mock",
  "model": "mock-jev-course/1",
  "decision": "human_review:no_explicit_authority",
  "request_sha256": "67c1ee4bcd36b497f60872c0715d435b364c3b7743ad06f9be543071af044a1b"
}

Ran 14 tests in 0.078s
OK
```

The fourteen tests establish only local properties, including these representative checks:

| Test | What it proves | What it does not prove |
|---|---|---|
| fixture validates | the saved response matches the subset the lab consumes | TypeSafe produced it |
| absent authority refuses dispatch | the policy keeps authority in code | the 0.9 threshold is calibrated |
| unknown Choice is rejected | invented options cannot enter the decision path | the known option is correct |
| probabilities sum to 1 | malformed distributions fail closed | probabilities are calibrated |

## Phase B — optional one-call probe

Do not paste the key into a command argument because shell history and process inspection may retain it. Set `TYPESAFE_API_KEY` in your own environment using your operating system's secret-handling method, then run:

```bash
python typesafe_lab.py live --out live-result.json
```

The script:

- refuses before network access if the environment variable is absent;
- builds one request for the pinned `jev-1.13.0` model;
- counts UTF-8 request bytes as a local size proxy, not a billed-token estimate;
- refuses if the payload exceeds 2,500 bytes or its **$0.000105 byte-based cost proxy** at the rate reviewed on 2026-09-22;
- sends exactly one request with a 20-second timeout;
- refuses redirects so the bearer token stays bound to the configured API origin;
- performs no automatic retry on 429, 529, timeout or network failure;
- never prints or writes the authorization header;
- validates the response and requires the exact pinned model before routing it;
- requires authority from trusted local code rather than from the model's Noul answer;
- records time, concrete model ID, provider usage, request digest, byte-based pre-call proxy and decision, but not the full provider response.

The byte count limits local request size. It is **not** a proven upper bound on billed tokens or dollars: server-side framing and account billing controls are separate. The response's `usage.input_tokens` is the quantity to multiply by the then-current official input price. Obtain separate approval before a paid call.

:::caution[Live probe not run]
The live probe is **to verify**. No API request was made while writing this course. There is no measured latency, token count, answer, cost or calibration result to report yet.
:::

## Stop conditions

Stop the experiment immediately when any condition is true:

- the key is absent or appears in output;
- the local byte/proxy limit is exceeded;
- the response does not match the closed contract;
- the provider returns 401, 422, 429, 529, a timeout, or any unexpected status;
- the concrete model differs from the pinned version;
- the decision would authorize, merge, deploy, publish or delete; the one-call limit does not guarantee a dollar ceiling;
- the input contains a secret, personal data, proprietary content without approval, or more repository context than the question needs.

## Evidence table to fill after the live run

| Field | Required evidence | Current state |
|---|---|---|
| request identity | SHA-256 from the script | mock only |
| model | concrete response `model` | untested live |
| usage | `input_tokens`, `output_tokens` | untested live |
| cost | input tokens × current official price | untested live |
| latency | script `elapsed_ms` | untested live |
| shape | validator passed | mock passed; live untested |
| policy outcome | exact `decision` | mock refused dispatch |
| task quality | result against a pre-labeled answer | untested |

One successful call is a connectivity probe, not an evaluation. The next useful experiment is a versioned corpus containing clear cases, boundary cases and deliberate counterexamples, scored before thresholds are changed.

## Exercises

1. Why does the script pin `jev-1.13.0` rather than use `jev-latest`?

<details>
<summary>Solution</summary>

Because an alias can move without a code change. Thresholds and measured accuracy belong to the concrete model that produced them. Pinning makes replay and regression comparison meaningful.

</details>

2. The provider documents SDK retries, but this probe refuses to retry. Is that a bug?

<details>
<summary>Solution</summary>

No. The experiment's budget is exactly one call. Automatic retry would make the spend and number of observations ambiguous. Production code may use bounded exponential backoff, but its retry count and worst-case cost must be explicit and separately tested.

</details>

## Sources

- TypeSafe AI: [API reference](https://docs.typesafe.ai/api), [models and pricing](https://docs.typesafe.ai/models), [quick start](https://docs.typesafe.ai/introduction/quickstart)
- Course code: [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one)
