# Streeling University: course fixtures

The programs and data that produce the reproducible evidence of Streeling modules. Each module folder,
`code/streeling/<department>/<module>/`, holds:

- `analyze.py`, `scenarios.json`, `results.json` and `README.md`;
- with observed repository data, also `extract.py` and `observed-input.json`.

The folder's `README.md` documents the module's inputs, self-checks and limits. The modules themselves are in
[`streeling/courses/`](../../streeling/courses/).

These folders came from GuitarAlchemist/Demerzel at `1beb089`, where the programs lived in `scripts/streeling_fixtures/`
and the data in `state/streeling/fixtures/`. The data files are byte for byte the same. The programs changed only in
how they find their folder, and in `extract.py` the `--repo-root` argument is now required.

## Running one

From the repository root, Python 3.9 or later, standard library only:

```text
python -I -B code/streeling/psychohistory/psy-005/analyze.py --check
python -I -B code/streeling/psychohistory/psy-005/extract.py --repo-root <Demerzel clone>
```

- `analyze.py` recomputes `results.json` from `scenarios.json` and, where present, `observed-input.json`. `--check`
  compares a fresh run with the saved file and writes nothing; `--output <file>` writes elsewhere.
- `extract.py` reads its sources in a clone of [GuitarAlchemist/Demerzel](https://github.com/GuitarAlchemist/Demerzel)
  and rewrites `observed-input.json`. It pins each source by Git blob id at the commit it names, `4b03838` for every
  module here, and refuses to run when a source differs. Some extracts also read the commit history, so the clone needs
  its full history; its blobs can be left out (`git clone --filter=blob:none`). `analyze.py` reads only the saved
  snapshot, so it keeps working whatever happens in Demerzel.

## Checking them all

```text
python code/streeling/check.py
python code/streeling/check.py --demerzel <Demerzel clone>
```

The first command checks that every module folder holds its files and that every program compiles, then runs every
`analyze.py --check`. With `--demerzel`, it also checks the clone out at each extract's pinned commit, runs `extract.py`
into a scratch file and requires it to equal `observed-input.json`. The clone's working tree is changed, so give it a
clone of its own.

[`.github/workflows/streeling-fixtures.yml`](../../.github/workflows/streeling-fixtures.yml) runs the analyses on
Windows, Linux and macOS with Python 3.9, 3.12 and 3.14, and the extracts on Linux.
