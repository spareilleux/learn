# Weave scene course tranche — 2026-10-22

## Scope and status

VC008 (save/query), PHY006 (units/bounds) and SEM005 (hit identity) are new English course drafts with French and Spanish mirrors. Their common input is the existing synthetic VC007 weave fixture. This tranche provides native Godot GDScript evidence; it creates no IX exporter, ComfyUI/Blender extension, observatory integration, browser export or GitHub product release. Subject, fluent-language and learner review and public course HTML readback remain pending.

## Reproduction and source boundary

Use [the teaching adapter](../../weave-godot/README.md) from the Learn root with Node.js, Python and Godot 4.6.1 installed on PATH. The common command accepts a new output directory outside the checkout and two externally supplied files. Its README gives immutable download links and exact SHA-256 digests. The controller records actual supplied input hashes; the caller must compare them with the pinned provenance. It does not download inputs, install packages or enforce source authenticity from a filename.

`public-input-readback.json` records anonymous HTTP 200 and exact local Git byte comparisons for the unchanged Demerzel evaluator/spec/license at f23ccae6c049d9066a1be2221c68f3b0bcf48373. Three current IX origami sources at d7c22fdd6a62becb66b9d7246ea85850e7c55854 are context only, without a new IX execution or export attestation. Direct requests to Godot documentation returned 403; separate web-tool reads returned the official 4.6 page text. These observations are retained separately, without inventing successful direct HTTP statuses.

## Declared model and executed result

`experiment-plan.md` and the adapter's `expected-cases.json` declared the model and expectations before implementation, not as an external preregistration. A 3-by-3 plain-weave base repeated 2-by-2 yields 36 crossings. The unchanged checker reports 0 adjacency violations for global parity and 12 for restarted tile parity. Only the former enters scene construction.

Each crossing has two disconnected box proxies: warp along world Z, weft along world X, 4 mm length,2 mm full thickness,5 mm pitch. One scene unit represents 1 metre. Upper/lower centre heights plus/minus1.5 mm leave 1 mm of vertical AABB separation. There is no continuous yarn, tension, bending or cloth-contact model.

The final controller successfully packed and saved a scene, freed the original, loaded saved bytes and instantiated them before observation. `good-godot-report.json` contains 190 passing native checks: 36 crossing parents, 72 meshes/static bodies/collision shapes, two shared mesh/shape/material resources per kind and 36 correct crossing/upper-strand ray results. `w2-f0` hits warp; `w3-f0` hits weft. Its observed X is 0.0150000005960464 m and the gap is 0.00100000004749745 m, against nominal 0.015 m/0.001 m with the declared 1e-7 tolerance. These are float representations, not physical measurements.

`crossings.json` has SHA-256 `05ff96258db853cfdf31bbe53f4589e0a4d088045449035036123a0577056ab1`. `native-scene.tscn` retains exact saved-scene bytes, whose digest is recorded in the native report. `execution.json` binds the five final teaching files, commands, versions, exits, stdout/stderr and scratch outputs. `results.json` extracts the bounded outcomes. These are scripted physics probes, not human selections or rendered images.

## Negative controls and failed attempts

Final-source scratch copies change one field only. Setting builder MM_TO_M to 1 rejects at `independent_world_metres` and also breaks clearance/ray checks. Replacing only the collider crossing_id with wrong-crossing rejects `ray_crossing_identity` and its aggregate while geometry and upper-strand checks pass. Choosing restarted-tile-parity rejects `semantic_admission` before a project is created. Run exits are 0 for the admitted baseline and 1 for each expected rejection; a nonzero native exit alone does not identify the violated contract, so inspect the named report entries.

Dogfooding exposed a launch-path failure. Earlier WinGet-link attempts sometimes timed out before script execution; one earlier worker run completed with a Mono assembly-discovery error. The retained host launcher attempt timed out after 60 seconds with no new native report. Prepending the installed executable's directory to PATH did not change the chosen launcher, because the real binary has a different basename. That attempted comparison was therefore inconclusive about a direct launch. Explicitly invoking the same resolved executable then passed in 0.5707436999946367 seconds with empty stderr. The final Windows controller finds godot.exe on PATH and resolves the link before launching; all four final runs completed with empty native stderr where Godot ran. This demonstrates a successful local correction, not a universal startup-performance, C# assembly or runtime-reliability claim. Failed logs and both characterization receipts remain in this folder; scratch directories were not discarded or overwritten.

## Agentic and learner conclusions

The concrete loop was: declare checks, run an actual consumer boundary, separate startup failure from model failure, compare one launch condition, apply the correction, rerun final sources and reject controlled defects. A running wrapper, planned assertion or aggregate exit is weaker than a digest-bound native observation with a named gate. The source manifest and small adapter are the baseline against which any future composable DSL must earn its added cost. Neither this run nor a larger graph establishes exponential progress or educational preference over the cheaper parity checker and labeled 2D grid.

`learner-task.md` permits source assistance and `reviewer-rubric.json` has 15 criteria across 3 tasks, with outcomes null. No participant performance, unaided transfer, causal learning, rendering cost or accessibility comparison was measured. Windows was exercised; Linux/WSL and macOS remain to verify.

Code review: skipped (ce-code-review unavailable). The earlier top-level CE review terminated without a usable receipt; rejected transport/cleanup operations must not be retried. Native independent checking and a host diff scan are separate evidence, not formal CE or human approval. Bindings, locale checks, rendered-link checks and integration validation are recorded when completed. The original 525-course reviewed/published objective remains incomplete.

## Byte discipline

Owned copied textual receipts use UTF-8 and LF before audit hash binding. The failed native stdout copy omits its extra terminal blank line to satisfy Git whitespace checks; the original scratch log is retained. The saved scene is retained byte-for-byte. Verify every bound Git-index blob against its canonical bytes before committing; parsed JSON equality alone does not prove byte equality. Protected journals and original source-copy provenance remain outside this tranche.
