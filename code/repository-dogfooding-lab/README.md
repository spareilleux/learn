# Repository Dogfooding Lab

The JSON registry is the source of truth. The renderer validates promotion invariants and emits four opportunity views plus a course-method matrix.

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

An opportunity score orders investigation. It never changes status, grants authority, or proves adoption.

The `jev-petri-fixture.json` case is synthetic, not a live provider result. Its parity test binds it to the Jev stress harness; the focused C# tests in `../petri-nets/Tests/JevEvidenceGateTests.cs` compare an unsafe advisory-to-effect net with a guarded net. This is a local specification experiment, not a Gaia or IX integration.

The optional Gaia publication-seam check pins `GuitarAlchemist/gaia` to commit `c94df3f5a53cd9f472e8a97b656dc23d7c940389` and requires its production source to be clean. Use a separate Gaia checkout and set `GAIA_REPO` to its absolute path before running `node gaia-publication-authority-check.mjs`. It injects fake authority and GitHub effects: a wrong intent revision must stop before commit; a matching mock revision follows the simulated commit/push/PR path. No GitHub network effect, real signed grant, concurrent replay, crash recovery, or race-freedom claim is involved.
