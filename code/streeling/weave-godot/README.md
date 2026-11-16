# Weave scene roundtrip

This standalone teaching adapter tests whether the admitted synthetic plain-weave
fixture survives native Godot scene serialization and physics queries. The existing
2D checker is the simpler semantic baseline. This lab does not measure educational
benefit, continuous yarn, cloth mechanics, GPU rendering, or IX export.

Prerequisites: Node.js, Python (`python` on Windows, `python3` on Linux/WSL and
macOS), and Godot **4.6.1** available as `godot` on `PATH`. The controller uses only
the Node standard library. The public command has the same spelling on each OS;
only Windows has been exercised for this lab. No install or network access occurs.
On Windows the controller finds `godot.exe` on `PATH` and resolves its filesystem
link before launching it. This matters for the installed WinGet Mono build: the
link launch timed out, while explicitly launching the same resolved executable
completed this GDScript trial. The actual executable path is retained in the report;
this local result is not a general Godot performance or reliability claim.

From the Learn repository root, supply a **new** output directory and the existing,
unchanged evaluator and fixture as external files:

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json
```

For example, with the author machine's external cache:

```text
node code/streeling/weave-godot/run.mjs C:/tmp/my-new-weave-trial C:/tmp/streeling-weave-scene-20261022/evaluate_weave.py C:/tmp/streeling-weave-scene-20261022/weave-trial.json
```

Those two external inputs originate at Demerzel commit
`f23ccae6c049d9066a1be2221c68f3b0bcf48373`. The runner records their actual SHA-256
digests; the caller must verify them against the source provenance. It does not
download or replace them. The teaching code is not a production validator or DSL.

The evaluator must report zero global-parity violations and 12 restarted-tile
violations. Only the zero-violation variant is admitted. A semantic negative control
uses the same command with a fourth argument:

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json restarted-tile-parity
```

This must exit nonzero at `semantic_admission`, before making a Godot project.
There is no validation bypass. An existing output directory is rejected.

After admission the runner writes 36 source-bound crossings (`w<x>-f<y>`, millimetre
coordinates, warp-over boolean), copies this tiny project into the output directory,
and invokes headless Godot. All caches, logs, generated JSON and `weave.tscn` stay in
that new directory. The source checkout and existing Godot applications are untouched.

Each crossing has two **box proxies**, with warp along world Z and weft along world
X. The 4 mm segment lengths, 2 mm thickness and 5 mm pitch do not represent connected
yarn. Upper/lower centres at +/-1.5 mm leave a 1 mm AABB gap. The builder converts
millimetres to metres. Its independent checks expect world X = 0.015 m at `w3-f0`,
so changing only the builder scale to metres-per-millimetre = 1 fails the check.

Godot saves `project/weave.tscn`, frees the original, loads the saved bytes and
instantiates them, then waits for physics frames. It checks the loaded 36 parents,
72 meshes, 72 static bodies and 72 collision shapes, including two shared resources
of each mesh/shape/material kind. The loaded transforms, AABBs, metadata and 36
downward `PhysicsDirectSpaceState3D.intersect_ray` results are recorded. These are
automated physics probes, not user clicks. `w2-f0` must hit warp; `w3-f0` must hit
weft. There is no camera or rendered-view claim.

Inspect `run-report.json`, `semantic-report.json`, `crossings.json`,
`godot-report.json`, `godot.stdout.log`, `godot.stderr.log`, and the native scene.
Success requires an explicit passing report and exit code 0. Named checks and
nonzero exits report failures; the code does not rely on Godot assertions. A Godot
startup/script error is bounded by a 60-second timeout and retained in the logs.

`expected-cases.json` records the chosen expectations before implementation. For
additional negative controls, copy this source directory to a new scratch location
and mutate only the builder's `MM_TO_M` constant, or only the static body's
`crossing_id` assignment. Run that copy with a separate new output directory.
`independent_world_metres` and `ray_crossing_identity`, respectively, must reject
the results. Keep the unmodified source and all control outputs for comparison.

## Pinned external inputs

Download or otherwise retrieve these two unchanged files before running the public
command, and compare their bytes with the digests. Keep the upstream
[MIT license](https://github.com/GuitarAlchemist/Demerzel/blob/f23ccae6c049d9066a1be2221c68f3b0bcf48373/LICENSE)
with the cache. The controller records, but does not enforce, these pinned hashes.

- [evaluate_weave.py](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py): `43ba4e1a245ebc8c9d2ab34a9219419ad136ef73d021c1073e1f123e69479d9f`.
- [weave-trial.json](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json): `da33830148b1ee98a1c004e0b89a86770f438da369e059cbdad06803da3a1955`.

The [dated evidence](../evidence/weave-scene-2026-10-22/README.md) distinguishes
startup failures, the successful direct-executable characterization and subsequent
final-controller checks. A passing GDScript trial does not validate a C# project.
