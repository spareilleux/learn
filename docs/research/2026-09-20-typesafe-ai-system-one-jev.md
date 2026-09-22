# TypeSafe AI System One and Jev — source notes

Research date: 2026-09-20. Only first-party TypeSafe AI sources were used. No API call, console session, credential, or paid service was used.

## Verified product facts

- Jev is TypeSafe AI's first System One model. It evaluates a `state` against typed questions and returns structured answers rather than generated prose: <https://docs.typesafe.ai/introduction>.
- The public primitives are `Choice`, `Score`, and `Noul`. Choice returns an option, a probability distribution, and confidence; Score returns a probability-weighted score, its level legend, probabilities, and confidence; Noul returns a number from 0 to 1: <https://docs.typesafe.ai/primitives> and <https://docs.typesafe.ai/api>.
- Questions in one request share the same state and are evaluated independently. TypeSafe recommends atomic questions and composition in ordinary code: <https://docs.typesafe.ai/introduction>.
- The HTTP endpoint is `POST https://api.typesafe.ai/v1/systemone`, authenticated with a bearer token. `state`, `model`, and `questions` are required: <https://docs.typesafe.ai/api>.
- The current official model page lists Jev 1.13 (`jev-1.13.0`) at $42 per billion or $0.042 per million input tokens; output tokens are free. It lists 64k total context, a 32k state-plus-longest-question limit, text-only input, 250,000 tokens/s and 1,200 requests/minute. Those limits may change without notice: <https://docs.typesafe.ai/models>.
- `jev-latest` is a moving alias. The response reports the concrete model; workflows with calibrated thresholds should pin a version until a deliberate upgrade: <https://docs.typesafe.ai/models>.
- Confidence is derived from the returned probability distribution and is not itself semantic proof. TypeSafe recommends domain-specific thresholds, conservative starting values, tests on your data, and higher thresholds for higher-stakes actions: <https://docs.typesafe.ai/confidence>.
- Direct HTTP clients should back off on HTTP 429 and 529; official SDKs do so by default: <https://docs.typesafe.ai/api>.
- TypeSafe's launch post claims Jev is optimized for structured decisions, parallel sampling, and calibrated outputs, while explicitly describing Jev as early access and discussing possible evaluation bias: <https://typesafe.ai/blog/introducing-system-one-models-and-jev>.

## Important boundary

The API's closed answer shapes prevent arbitrary text fields or options from appearing in a valid response. That is a schema/shape property. It does not prove that the selected option, score, probability, or Noul value is correct for a particular domain. A safe integration therefore validates both the response contract and task accuracy on held-out cases, then keeps authority and irreversible effects outside the model call.

## Course implications

- Start with a deterministic fixture replay that exercises validation, thresholds, and routing without a key.
- Make the live probe opt-in, read `TYPESAFE_API_KEY` only from the environment, never print it, issue exactly one bounded request, and stop before the request when its local estimated input-cost ceiling is exceeded.
- Record exact request digest, response model ID, token usage, latency, decision, and estimated input cost. Do not record the authorization header.
- Treat every proposed Gaia, GA, Demerzel, IX, and TARS use case as a hypothesis until tested against a labeled corpus from that repository.
