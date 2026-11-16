# Guitar-audio course transfer and reproducible exercise inputs

Status: draft source transfer, not a publication or review approval. Seven modules are being added in EN/FR/ES: GAS001, AUD002, PHY002, AUD003, AUD004, GAS002 and GAS003. They teach onset alignment, level matching, transform choice, transient preservation, wavelet evidence, brightness controls and decay calibration using GA/IX artifacts.

## Provenance and reproducibility

`import.json` binds thirteen archived authored source files to Demerzel `17f82a4b4b913d7c64942a3d3ff670abf4e6f85c`, records every link change, and binds the eight newly drafted FR/ES translations separately. Initial Learn source-copy metadata remains unchanged; this supplement has its own provenance. Only EN/FR/ES sources move into Learn. PT/IT/DE, research cycles and original review records remain in Demerzel.

The nine unique exercise dependencies referenced by these sources were retrieved anonymously from immutable raw archive URLs and matched byte-for-byte to Git. They include the two WAVs, provenance and audio attribution, unchanged measurement/renderer/benchmark scripts, measurement outputs and AUD003's bounded IX probe. `public-exercise-inputs.json` records each observation. The linked fixture README credits collegefishiesd and the source dataset and preserves its stated CC BY-SA 4.0 attribution for the recorded WAV. Learn does not copy or modify that recording.

The unchanged archived measurement script and synthetic time-frequency benchmark were rerun from those verified downloaded bytes in a separate temporary directory. Both complete JSON objects match their saved archive outputs exactly, including every synthetic event score. `reproduction.json`, `measurements-rerun.json` and `synthetic-rerun.json` preserve this check. No engine rebuild or parameter candidate, IX executable run, ComfyUI workflow, browser AudioWorklet capture or listening trial was performed.

AUD004's synthetic advantage hypothesis remains rejected: the measured 2.279 ms improvement is below its declared 5 ms threshold. Detection and frequency-separation checks passing do not erase that failure. AUD003's archived limited IX denoising probe also remains a failed proposed noise-reduction gate; the binary was not attested to its referenced source revision. These are useful negative results, not successful guitar-engine changes.

Two mutable ComfyUI references in GAS001 were replaced in all three locales with source links pinned to `46aad33e4d4c0696582611bf450dd93742fa9090`. The audio-node source contains LoadAudio, PreviewAudio and SaveAudio classes; the cited audio blueprint is accessible at the same revision. `comfyui-source-links.json` records this source inspection without claiming a workflow execution.

## Assessment boundaries

Every module includes five answered exercises. Source-localized drafts preserve technical values, distinctions and immutable input URLs. Independent AI content/translation checks can find defects and establish static consistency; they cannot supply a human subject or fluent-language approval or an observed human learner result.

The strict AUD002 illustrative `<1.8 dB` rule and GAS003's separate `<=1.8 dB` classroom rule are intentionally different; they are not project acceptance standards. Proposed brightness `0.90` and decay `0.9976` candidates remain unrun. These sources do not establish guitar realism or a benefit in a real-time WASM engine.

`learner-tasks.md` provides answer-free tasks. `review-rubric.json` gives a separate scoring guide and exact English source bindings; withhold it during a learner trial. Existing archive AI review/preflight records are historical and do not automatically approve new Learn blobs. Human review of AUD001 still awaits the user's selected reviewer; no additional approval has been invented.

## Import chronology

Archived first-person execution reports and historical 'not imported/not run' statements describe the source's pre-transfer state. This transfer's reproduction and later synchronization/build records are reported here separately. Any later deployment must receive its own revision-bound anonymous readback. The previously observed deployment `09b13e7f` does not contain these candidate modules.

## Verification completed for this transfer

The final package has 21 localized source files and 105 answered exercises. All 18 targeted project script tests pass. The cumulative Astro build succeeded with 1,621 pages; 33 affected course/department/overview pages have 780 checked article links and no unresolved internal links, and deliberate missing-page/anchor controls were detected. No new implementation code or CI gate is introduced.

The generated candidate catalog now contains 117 English, 111 French and 111 Spanish modules across 22 departments. Within the original 21-department goal, 116 distinct English core course codes exist in this candidate and 409 source slots remain. These are source counts, not reviewed/published completion counts. Personal journals and the initial Demerzel source-copy metadata remain unchanged.

An initial incorrect test-file lookup accidentally triggered Node's broad test discovery: 86 tests passed and one unrelated Tauri frontend test could not resolve its package under direct Node execution. The corrected explicit three-file project-script run passed all 18 tests. No full-suite pass is claimed. See `validation.json` for this distinction and `content-audit.json` for the independent static source/translation review.
