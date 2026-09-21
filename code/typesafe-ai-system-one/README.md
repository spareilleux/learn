# TypeSafe AI System One lab

The default path is offline and deterministic. It validates a saved response and exercises the same routing policy the optional live probe uses.

```bash
python typesafe_lab.py mock
python -m unittest -v
```

The live path is deliberately opt-in. It reads `TYPESAFE_API_KEY` from the process environment, never prints it, makes at most one request, and refuses locally if the estimated input-cost ceiling is exceeded.

```bash
python typesafe_lab.py live --out live-result.json
```

Do not commit `live-result.json`. The lab stores only validated decision metadata, usage, timing and request digest, but live evidence still belongs outside source control.

The repository-support benchmark adds twelve sanitized, labeled GA/Gaia/Demerzel cases. Planning and mock scoring are free and networkless:

```bash
python jev_benchmark.py plan
python jev_benchmark.py mock
```

The live benchmark is a separate operation: one batched request plus the same twelve questions sent separately, exactly thirteen calls and no retries. It requires both `TYPESAFE_API_KEY` and `JEV_BENCHMARK_APPROVED=YES`. Inspect the plan and obtain explicit approval before setting the approval variable.
