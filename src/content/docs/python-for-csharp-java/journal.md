---
title: Journal
description: Dated progress notes for the Python course — installing Python 3.14.7 with uv 0.12.14 without touching the machine's Python, surprises in uv, CPython and mypy, what the lessons found in the Python code of GuitarAlchemist/ga, ix and tars, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Python 3.14.7 and uv 0.12.14 pinned in the course's own project, [`code/python-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/python-for-csharp-java), with mypy 2.3.1 and pytest 9.1.1 in `uv.lock`
- [x] `check.sh`: mypy on the project and on each error snippet, every example, script and solution run, pytest, the C# and Java comparisons compiled and run, all compared with `expected/` on Windows
- [ ] CI on Linux, Windows and macOS (*to verify*: the workflow is written, not yet pushed)
- [x] Lesson 1: installing and running Python
- [x] Lesson 2: the execution model
- [x] Lesson 3: built-in types and collections
- [x] Lesson 4: functions
- [ ] Lesson 5: classes

## 2026-09-15 — Installing Python without touching the machine

- The machine already had a system Python and uv 0.10.4 on its `PATH`, and other projects use their own virtual environments. The course had to leave all of them alone. I downloaded the uv 0.12.14 binary into a scratch folder and pointed `UV_PYTHON_INSTALL_DIR`, `UV_CACHE_DIR` and `UV_TOOL_DIR` there, with `UV_PYTHON_INSTALL_REGISTRY=0` so that the Windows registry doesn't learn about the interpreter, and `UV_NO_MODIFY_PATH=1`. `uv python install 3.14.7` then downloaded a build from [python-build-standalone](https://github.com/astral-sh/python-build-standalone) into that folder only. Lesson 1 shows the ordinary installation, which is what a reader wants.
- Python 3.14.7 was released on 2026-08-05. On Windows, python.org now recommends the [Python install manager](https://docs.python.org/3.14/using/windows.html); the traditional installer and the `py` launcher that came with it are deprecated since 3.14. Lesson 1 installs with uv on the three OSes, and mentions the install manager.
- **uv 0.12.0 changed `uv init`.** It now creates a packaged project by default: a `src/hello/__init__.py`, a `[project.scripts]` entry and the `uv_build` backend, where 0.11 created a single `main.py`. `uv init --no-package` gives the old layout. Tutorials written before 2026 show the old files; lesson 1 shows the new ones, from `check.sh`.
- The course's `pyproject.toml` sets `[tool.uv] package = false`: the course is a folder of examples, not a package to install.

## 2026-09-15 — Surprises while writing lessons 1-4

**`uv init` inside a project adds a workspace member.** `check.sh` creates lesson 1's `hello` project in `out/`, under the course's project, and the first run of `uv init` added `members = ["out/uv-demo/hello"]` to the course's `pyproject.toml` and locked it again. `--no-workspace` stops that. A reader who runs `uv init` in a subfolder of a uv project gets the same edit.

**`uv tree` filters by platform.** On Windows, `uv tree` lists `colorama` under pytest; on Linux it wouldn't, since the lock file records it with `marker = "sys_platform == 'win32'"`. Lesson 1 uses `uv tree --universal`, which prints the same tree on the three OSes. The lock file itself is the same everywhere, which is the point of it.

**Resolutions change every day.** `uv add httpx==0.28.1` pins httpx, not its dependencies: `anyio`, `certifi` and `idna` resolve to whatever is newest. `check.sh` sets `UV_EXCLUDE_NEWER=2026-09-15T00:00:00Z` for lesson 1's demo project, so that the tree in the lesson doesn't change when certifi publishes a release.

**A `.python-version` that contradicts `requires-python` is a hard error**, exit code 2, not a warning; lesson 1's third exercise shows the message.

**Python 3.14's messages are better than the tutorials show.** A list used as a dict key now says `cannot use 'list' as a dict key (unhashable type: 'list')`, where 3.13 said `unhashable type: 'list'`; the traceback puts carets under the failing part of the expression; `is` with a literal and an invalid escape sequence are `SyntaxWarning`s, printed when the file is compiled. The disassembly of lesson 1 shows 3.14's `LOAD_FAST_BORROW_LOAD_FAST_BORROW`, a superinstruction that older articles about `dis` don't have.

**mypy 2.3.1 misses more than I expected in strict mode.** It reports no error for lesson 2's `UnboundLocalError`, for a list used as a dict key, for `is` with a literal, for an invalid escape sequence, or for a mutable default argument. Nor for `ordered = tuning.sort()`, which assigns `None`. It does catch every wrong call of lesson 4, and the subscript of a `dict.get` result that can be `None` (lesson 2). It refused the `i=i` lambda (`Cannot infer type of lambda`), which moved from `examples/` to `errors/`. Lessons 2 to 4 say, for each error snippet, whether mypy finds it.

**`round` isn't the bug in lesson 1.** I first wrote that `f"{25.875:.2f}"` prints `25.87`; it prints `25.88`. The total of lesson 1 prints `25.87` because the float computation gives `25.874999999999996`. Lesson 3 now uses lesson 1's own formula, and shows the `Decimal` version.

**A set's order depends on `PYTHONHASHSEED`.** With seed 1 and 2, `{'E', 'A', 'D', 'G', 'B'}` prints in two different orders; `check.sh` fixes the seed for those two lines, and every other example sorts its sets before printing them.

**.NET and Java disagree about changing a collection while iterating it.** `Dictionary.Remove` inside a `foreach` doesn't throw since .NET Core 3.0, `List.Remove` does, and Java's `LinkedHashMap` throws `ConcurrentModificationException`. Lesson 3 prints all three.

**pytest 9 reads `[tool.pytest]`** in `pyproject.toml`, with native TOML types; older versions only read `[tool.pytest.ini_options]`. The course uses the new table.

**`dotnet run file.cs` caches the build.** As in the TypeScript course, a second run of an unchanged file doesn't call the compiler, so `check.sh` runs `dotnet clean` then `dotnet run --no-cache` on each C# comparison. `compare/global.json` pins the SDK to 10.0.100 with `latestFeature`, since the machine also has a .NET 11 preview.

**The CI can't be pushed yet.** The GitHub token used for pushing has no `workflow` scope, and GitHub refuses a push that adds a file under `.github/workflows/`. The code and the lessons are pushed; [`python-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/python-examples.yml) waits for `gh auth refresh -s workflow`. Until it runs, the Linux and macOS parts of lesson 1 are *to verify*.

## 2026-09-15 — What the lessons found in GuitarAlchemist/ga (cc42d21)

I cloned [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) at [`cc42d21`](https://github.com/GuitarAlchemist/ga/commit/cc42d215504631e168daf3bdf2c6d47b5c9fbe93) into a scratch folder, installed each Python project with the course's uv, and scanned the Python files with a small script based on the `ast` module (mutable defaults, bare `except`, annotations).

- **A bug: HTTP 400 becomes 500 in the knowledge-graph service.** In [`Apps/ga-graphiti-service/main.py`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/ga-graphiti-service/main.py#L102-L115), each endpoint raises `HTTPException(status_code=400, ...)` inside a `try` whose `except Exception as e` raises `HTTPException(status_code=500, detail=str(e))`. `HTTPException` is an `Exception`, so the 400 is caught and the client receives a 500 whose detail is `400: episode has no user`. The same shape is at lines 111, 127, 143 and 159. Reproduction, reduced to FastAPI 0.121 with a `TestClient`: the script prints `500 {'detail': '400: episode has no user'}`. The fix is an `except HTTPException: raise` before the general clause. Lesson 7 (errors) will use it; I haven't opened an issue.
- **The governance agent has no lock file.** [`Apps/demerzel-agent/pyproject.toml`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/pyproject.toml) declares lower bounds only (`acp-sdk>=0.2.0`), and the [README](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/README.md) says `uv sync`, which resolves today's versions: `acp-sdk` 1.0.3 on 2026-09-15, a major version above the bound. The imports still work.
- **Its entry point is never installed.** `[project.scripts] demerzel = "src.server:main"` needs a build system, and the file has none: `uv sync` prints a warning that it skips the entry points, and `uv run demerzel` then found an unrelated `demerzel.exe` elsewhere on my `PATH`. The top-level package is also named `src`. Lesson 1 explains packaged projects; lesson 8 will come back to the layout.
- **Importing the governance service can fail.** [`src/services/governance.py`, lines 13-28](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/services/governance.py#L13-L28), calls `find_governance_root()` at module level, which raises `FileNotFoundError` when no `governance/demerzel` folder is found, so any import of the module, a test's included, fails outside the repository. The environment variable `DEMERZEL_ROOT` is only read after the walk up the parent folders, so it can't override a folder that exists. Lesson 2 reduces it, and its third exercise reads the root lazily.
- **Errors swallowed.** The same file has `except Exception: continue` or equivalent at lines 46-56, 83 and 130, and `src/services/github.py` at lines 33 and 53; [`epistemic_agent.py`, lines 145-148](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L145-L148), has `except ValueError: pass`. For lesson 7.
- **Collections by hand.** The tensor summary and the `where` filter of `epistemic_agent.py` are exercises 1 and 3 of lesson 3.
- **The service's image** uses `python:3.11-slim` and uv 0.10.4 with a `requirements.txt` of lower bounds, so each image build can resolve different versions.
- **Scripts with undeclared dependencies.** [`Scripts/train-router-head.py`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L22-L25) imports NumPy and scikit-learn, and nothing in the repository declares them; a PEP 723 block would (lesson 1, exercise 2). It also reads JSON with `json.load(open(path))`, without `with` or an encoding (lines 63, 66 and 71). `Scripts/validate_optick_sae_artifacts.py` catches the `ImportError` of `jsonschema` at lines 34-39. Two scripts start with a UTF-8 BOM, which Python accepts.
- **No mutable default argument** in any Python file of the three repositories, according to the `ast` scan.

## 2026-09-15 — GuitarAlchemist/ix (2190c68) and tars (26c5f67)

- **IX** trains its sparse autoencoder from [`crates/ix-optick-sae/python`](https://github.com/GuitarAlchemist/ix/tree/2190c685e3664488c9a3d0c1388c96b868a178cb/crates/ix-optick-sae/python), with a `requirements.txt` of lower bounds and no lock; the code imports `Dict`, `List` and `Optional` from `typing` (lesson 3), and its tests use `unittest` with a `sys.path` edit instead of pytest (lesson 9).
- **TARS commits a virtual environment.** [`Scripts/tts-venv`](https://github.com/GuitarAlchemist/tars/tree/26c5f67252c84f1b9da48a415c58b0725cb5b45c/Scripts/tts-venv) holds 2,691 files: a Windows `python.exe`, pip, Flask and NumPy 2.2.4's compiled wheel for CPython 3.12, added in commit `2402545` on 2025-04-01. It works on one OS and one Python version, and weighs on every clone. A `pyproject.toml` and a lock file would replace it (lesson 1).
- **TARS's Python tools declare nothing.** Seven of the 23 scripts in [`tools/python`](https://github.com/GuitarAlchemist/tars/tree/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python) import `requests`, `aiohttp` or `websockets`, and the folder has no dependency file. 272 of their 288 functions have no return annotation.
- **Invalid escape sequences** in `implementation-starter.py`, line 184, and `meta-programming-demo.py`, line 497, reported by Python 3.14.7 (lesson 3).
- **Bare or swallowing `except`** in `autonomous-quality-loop.py` (lines 388, 408, 462, 482 and 491), `tars-mcp-client.py` (89), `tars-evolve-cli.py` (443 and 462) and `real-multimedia-processor.py` (142). For lesson 7.

## 2026-09-15 — This site

- The [machine learning course](../../machine-learning-ix/01-data-and-evaluation/) installs NumPy and scikit-learn with `pip install` into whatever Python is on the `PATH`. The versions are pinned, which is good, but the packages land in the system or user Python, and they can conflict with another project's. A PEP 723 block and `uv run --script`, or a small uv project in `code/`, would isolate them. I haven't changed that course.

## To verify

- Lesson 1's installation on Linux and macOS: the output of `uv python install` and the build names, from the CI's logs once the workflow runs.
- `check.sh` on the three OSes: the outputs were captured on Windows, and path separators, line endings and the C# culture could differ.
- The behaviour of the Python install manager on Windows, which I didn't install on this machine.
