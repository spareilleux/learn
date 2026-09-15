---
title: Journal
description: Dated progress notes — GA pin, building against the chatbot host offline, CI runs and a warm-up race, and the differences found between Guitar Alchemist's AI code, its comments and its documents.
sidebar:
  order: 99
---

## Progress

- [x] Course program: .NET 10, referencing `GA.Business.ML`, `FretboardVoicingsCLI` and `GaChatbot.Api` at a pinned commit
- [x] CI: every lesson's output compared with its expected file on three OSes, with no model, no API key and no GPU
- [x] Lesson 1: the map
- [x] Lesson 2: OPTIC-K embeddings
- [x] Lesson 3: the index and search
- [x] Lesson 4: the chatbot and its agents
- [ ] Run the chatbot with Ollama and capture what the agents answer (dated, outside CI)

## 2026-09-14 — Why this course

The request, on 2026-09-14: a course on the OPTIC-K index, on all of GA's machine learning and agent code, and on what the chatbot is trying to accomplish. The course sits under *Machine Learning*, next to [IX](../../machine-learning-ix/): it is about building and using embeddings, a vector index and a classifier-style router inside a product, not about using coding agents, which is what *AI-assisted development* covers.

## 2026-09-14 — Pinning GA and building against the chatbot host

- GA is pinned on [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), the commit the [music theory course](../../music-theory-ga/) uses. The author's local clone is never used: [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/fetch-ga.sh) makes a blobless, sparse clone in `code/ga-ai/.ga`, ignored by Git, with 17 project folders and GA's research PDFs excluded.
- On Windows, the first checkout failed on paths longer than 260 characters; `git config core.longpaths true` before the checkout fixes it. As in the music theory course, `MSYS_NO_PATHCONV=1` stops Git Bash from rewriting the sparse patterns.
- The course project references `GaChatbot.Api` directly and starts it with `WebApplicationFactory<Program>`. Two details were needed: an assembly attribute, `WebApplicationFactoryContentRootAttribute`, pointing at the host's folder inside the clone ([`GaAi.csproj`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/GaAi/GaAi.csproj#L20-L28)); and no top-level statements in the course program, whose generated `Program` class would clash with the host's.
- The author's machine runs Ollama. Left alone, the host would have used it, and the outputs would have differed from CI's. The course sets the Ollama address to `http://127.0.0.1:9`, closed on the author's machine and on the runners.
- GA's chat memory defaults to files under `~/.ga`. The course registers its own `MemoryStore` and `ChatTranscriptStore` on a fresh folder next to the program; `~/.ga` was checked to be unchanged after a run.
- The first corpus, 5 frets and a window of 4, had 77,140 voicings and took 33 seconds to embed. 3 frets and a window of 3 give 15,360 voicings in about 8 seconds, enough for every point of lesson 3.
- Exception messages differ between systems (socket errors). Lesson 4 prints only the exception type and the innermost GA frame, `file:line`, deduplicated and sorted.
- Local build of GA's projects and the course: about 23 seconds after the first restore; a full check of the four lessons, 40 seconds.

## 2026-09-14 — CI

- Run [34917150100](https://github.com/spareilleux/learn/actions/runs/34917150100), for commit `43f009d`: lessons 1 to 3 passed everywhere, lesson 4 passed on Windows and failed on Linux and macOS. On those two, the warnings of the semantic intent router appeared under the first request as well.
- Cause: `IntentEmbeddingWarmupService` starts the embedding of the intents in the background when the host starts, and its warnings land in whichever request is running. Fix in commit [`8e335d7`](https://github.com/spareilleux/learn/commit/8e335d7): the course waits for the warm-up's last log line before sending requests. Lesson 4 tells the story.
- Run [34917602262](https://github.com/spareilleux/learn/actions/runs/34917602262), for `8e335d7`: green on the three systems, 1 min 34 s on Linux, 1 min 50 s on macOS, 3 min 2 s on Windows, clone and build included.

## 2026-09-14 — Differences found in GA's code (commit a826864)

Each item says where the course program shows it. None was reported upstream.

Embeddings (lesson 2):

1. `VoicingDocumentFactory` sets `RootPitchClass` and `MidiBassNote` from `MidiNotes[0]` ([lines 37-38](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L37-L38)). GA builds voicings string 1 (high E) first, so that note is the **top** note. ROOT, MODAL, MORPHOLOGY's bass and the inversion are computed from it; the search filter uses `MidiNotes.Min()`, the real bass. Shown by `l2`, "From a chord shape to GA's voicing document" (open C: root E, inversion 1), and by `l3`'s Cmaj7 search.
2. The inversion compares that note with the chord's root name, parsed by `PitchClass.Parse` ([lines 43-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L43-L44)), which reads note names as digits: `"A"` is 10 and `"E"` is 11. A root-position E minor, `022000`, gets `Inversion = -1`. Reproduced with a separate program referencing `GA.Business.ML`, not part of the course's CI: `PitchClass.Parse("E") = 11`, and `022000 Em ChordId.RootPitchClass="E" doc.RootPitchClass=4 inversion=-1`. The [music theory course](../../music-theory-ga/journal/) found the same parser behaviour.
3. `VoicingHarmonicAnalyzer` passes `intervalSpread > 12` into `IsRootless` and `false` into `IsOpenVoicing` of the positional record `VoicingCharacteristics` ([lines 31-43](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingHarmonicAnalyzer.cs#L31-L43)). Every voicing spanning more than an octave is "rootless". Shown by `l2`, "VoicingCharacteristics and PerceptualQualities".
4. `VoicingAnalyzer` builds `new PerceptualQualities(curVoiceChars.Consonance, 0, 0, "Neutral", "Medium")` for a record declared `(Brightness, ConsonanceScore, Roughness, ...)` ([line 164](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingAnalyzer.cs#L164)). `ConsonanceScore` is always 0, the document's `Consonance` too, and CONTEXT's tension `1.0 - doc.Consonance` is always 1. This is the constant dimension of issue [#616](https://github.com/GuitarAlchemist/ga/issues/616), whose analysis blames only the literals next to it. Same section of `l2`, and the CONTEXT row of `l3`'s "Dimensions that never vary".
5. `EmbeddingSchema.AtonalModalDim` is 17 while the registry gives ATONAL_MODAL 64 slots; `ModalVectorService` allocates 17 ([line 116](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs#L116)) and `WriteInto` doesn't check lengths: 47 slots are always zero (`l3`). `HierarchyDim` is 8 against 15 (`l2`, "Loose constants"). Both partitions have weight 0, so search is not affected.
6. STRUCTURE is not invariant to transposition (221 of 222 set classes, `l2`), as GA's own sweep and `TheoryVectorService`'s comment say; `RootVectorService`'s summary still claims "genuinely O+P+T+I-invariant" ([lines 3-7](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/RootVectorService.cs#L3-L7)).
7. The similarity weights add up to 1.15; a vector scores 1.15 against itself (`l2`). Not a bug, but "cosine" is misleading in logs and thresholds.
8. Versions in comments and documents: the newest schema document is v1.4.1, `OPTIC-K_Embedding_Schema.md` describes v1.3.1 (109 dimensions), `MusicalEmbeddingGenerator` says 228 ([line 13](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L13)) and 216 ([line 55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L55)), `CompactDimension`'s comment says 112, `OptickIndexWriter` and `MusicalQueryEncoder` say 112, `ExtensionsEnd`'s comment says it equals `TotalDimension`. The code computes 240 and 124.

Index and search (lesson 3):

9. Nine of the 33 named MODAL slots are never set on the 15,360-voicing corpus: LocrianNatural6, DorianSharp4, LydianSharp2, AlteredDoubleFlat7, DorianFlat2, LydianAugmented, MixolydianFlat6, LocrianNatural2, Diminished. `ModalVectorService` looks modes up by display names such as `"Locrian ♮6"` and returns silently when nothing is found; a name mismatch is the likely cause (*to verify*).
10. 37 of the 124 searched dimensions are always zero and 4 constant on that corpus (`l3`); #616 reports 40 dead dimensions on the live index.
11. `ApplyFilters` matches the quality as a substring of the stored name: the `Am7` filter accepts `Gbm7(shell)/A`, and the empty quality of `C` accepts any name with C in the bass, including `C + E (Major 3rd)` and `Am/C` ([lines 296-329](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L296-L329)).
12. `OptickSearchStrategy.FindSimilarVoicingsAsync` always returns an empty list (known, commented at [lines 75-92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L75-L92)). `MusicalQueryEncoder` leaves the interval-class vector out of queries (known, commented).

Diagrams and MCP tools:

13. Two orders for the same diagram string: `VoicingGenerator`, the index and the MCP tool's parser read string 1 (high E) first; `PlayableNotationFormatter` reads the low E first ([lines 31-53](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Notation/PlayableNotationFormatter.cs#L31-L53)). The chatbot's tablature for `3-0-x-2-3-x` (Cmaj7) is `6/3 5/0 3/2 2/3`, the notes G A A D (`l4`).
14. `ga_generate_voicing_embedding`'s description says "228-dim" and gives `'x-3-2-0-1-0' for Cmaj7` ([lines 42-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L42-L44)); the tool's parser reads it as Dsus2/E (`l2`), and read low E first it would be C, not Cmaj7.
15. `ga_get_embedding_schema` lists ten partitions, without ROOT, with the loose `HierarchyDim` and `AtonalModalDim` ([lines 69-91](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L69-L91)). Read in the code, not run by the course.

Chatbot (lessons 1 and 4):

16. Without an embedding server, every message that no guard catches ends in HTTP 500. `SemanticRouter.RouteAsync` doesn't catch the exception of `EnsureEmbeddingsInitializedAsync` ([lines 68-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/SemanticRouter.cs#L68-L104)), so its keyword fallback is unreachable; the host's fallback to a direct model call throws too. "What is the relative minor of C major?" fails although `skill.relativekey` answers it with confidence 1.00 (`l4`).
17. The legacy `CanHandle` path sends that same question to `ScaleInfo`, not to the relative-key skill (`l4`).
18. `skill.fretspan` has no example prompt, and `SemanticIntentRouter` skips intents without examples: it can never be routed to (`l1`).
19. `ProductionOrchestrator.AnswerStreamingAsync` (from [line 154](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Services/ProductionOrchestrator.cs#L154)) has the voicing guard but not the algebra fast path of `AnswerAsync`. Read in the code, not run.
20. `IntentEmbeddingWarmupService` starts its work fire-and-forget; fine for a server, but a host's logs then depend on timing (the CI failure above).

Documents:

21. `docs/architecture/chat-surfaces.md` says in its 2026-05-13 status that `GaChatbot.Api` is canonical and serves the public demo ([lines 16-21](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/docs/architecture/chat-surfaces.md#L16-L21)), while later sections say the deployed page calls SignalR on GaApi and treat both as parallel-to-canonical (lines 215-223 and 262).
22. GA's `CLAUDE.md` says ix produces `optick.index`; in GA's code and in its `optic-k-rebuild` skill, `FretboardVoicingsCLI` writes it. `CLAUDE.md` names `GA.Business.Core.Harmony` and `GA.Business.Core.Fretboard` as layer 3; the voicing generator and analyzer live in `GA.Domain.Services`.

Leads not checked by the course, noted earlier from reading GA's documents (*to verify*): `GaChatbotCli` may fail to resolve its services; the backlog and the roadmap disagree on some statuses; GA's documents give several sizes for the live index (161, 168, 175, 176 and 660 MB).
