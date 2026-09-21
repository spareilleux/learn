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
