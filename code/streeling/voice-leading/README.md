# Native voice-leading characterization

Run from the repository root with installed Node and .NET SDK **10.0.113** on PATH:

```sh
node code/streeling/voice-leading/run.mjs ../streeling-voiceleading-new-run
```

The output directory must be fresh, outside this checkout, with an existing parent. The controller copies the lab there, checks the vendored hashes, compiles and executes there, and retains `results.json`, `commands.json`, stdout/stderr logs, and all build/cache files there. No package dependencies, installs, network services, or NUnit are required. `NuGet.Config` clears package sources; `global.json` requires the installed SDK. A missing SDK, source mismatch, failed build, missing check, or failed check exits nonzero. Windows is the only assessed OS.

`source.json` identifies GA commit `dc2e74cbd992a298f67efb928b5b3754615e1924`, immutable source/test links and SHA-256 hashes. The two source files and MIT license are byte-unchanged; `VoiceLeadingOptions.cs` retains its UTF-8 BOM. `MetadataAdapter.cs` supplies only a clearly marked compile-only `JetBrains.Annotations.PublicAPIAttribute` stand-in plus the global using needed by the options file. This is a standalone assembly, **not the original GA assembly**. The adapter changes no distance arithmetic. The named upstream tests were inspected; NUnit and dependent GA classes are not compiled.

`expected-cases.json` was written before probe/controller implementation. It fixes independent scalar expectations and the proposed counterexample. The native probe executes the unchanged actual `VoiceLeadingSpace` and options classes. Its independent oracle enumerates every indexed target permutation, including all 5,040 permutations for the retained seven-voice upstream fixture. It does not use sorting or cyclic search. Scope is these finite integer, equal-cardinality cases with at most seven voices; no random fuzzing or general proof is claimed.

The counterexample is `[60,63,65]` to `[60,65,75]` with O/P enabled and T/I disabled. The source's three cyclic candidate costs are `4,10,6`; its scalar is 4. The exhaustive oracle has a zero-cost assignment `[60,75,65]`. `ORIGINAL_EXPECTED_EQUIVALENCE_SATISFIED=false` is retained independently from `probe_completed` and `characterization_pass`: a successful characterization reproduces this disagreement and does not certify GA correctness. The modulo-12 input variant returns 0 for this example; it is a workaround for this case, not a general fix or a claim of physical voice continuity. Vendored code is never changed.

The ordered/permuted and register cases distinguish octave equivalence from assignment. Octave equivalence alone does not choose a voice assignment. The original API returns a scalar, not a voice witness. In the ambiguous `[60,62]` to `[64,65]` example, the oracle supplies both equal-cost assignments `[64,65]` and `[65,64]`, with raw pitch motions `[4,3]` and `[5,2]`. Oracle `motions` are registered target-minus-source differences; `voiceCosts` are the corresponding absolute or octave-circular costs. These witnesses are teaching output, not a GA feature or a performer continuity plan.

For register-shifted triads, the simple teaching intersection counts are zero absolute common notes and three common pitch classes. They are **not GA CommonTones output**. The local two-candidate comparison reverses the ranking (native: targetNear 1 before targetSame 4; oracle: targetSame 0 before targetNear 1). This constructed comparison does not execute upstream KNN or the UI.

This lab characterizes a pinned method with retained expected cases. It does not alter GA production, build the full GA solution, run its full suite, introduce an alternative production engine, or claim broad edge-case coverage. Empty input and mismatched cardinality characterize the two explicitly retained source behaviors.
