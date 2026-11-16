# Tempo maps, clock domains and playback latency

Execution: knowledge-work. Produce MCL007, NET008 and PM007 with five corrected exercises and a transfer task each, in English, French and Spanish. Correct the source-reachability wording of existing MCL004 and MCL006 in all three locales. Keep the full 525-course, 21-original-department goal active.

## Baseline and chronology

The starting Learn commit is `6dd306fc88bb4f74050a6becac8dfc6b8301d03d`, with 216 English core sources and 217 in each locale including IX Research. This plan follows source reading and hand-worked examples but precedes the packet's external numerical verification. It is not a preregistration of a physical or browser experiment. No runnable lab, parser patch, scheduler, clock service or new production DSL is in scope.

## Source and correction boundary

Read three public GA files at `76efbffd5af82b46c3146957a6bd4504008eeb89`: MIDI types, parser and the selected dashboard progression component. Read the parser again at MCL004's earlier pin `dc2e74cbd992a298f67efb928b5b3754615e1924`. The anonymous downloads match immutable Git objects; both parser revisions have identical bytes.

The parser masks status with `0xF0` before matching a `0xFF` meta-event arm. A byte-mask enumeration should show that arm cannot be selected through this match. Its tempo/time-signature bodies are therefore conditional branch interpretations, not valid predictions of successful parsing through the shown entry path. Preserve earlier numerical examples while making that limit explicit in MCL004/006. The same selected bodies return tempo without delta time; a deliberately modeled projection can demonstrate loss even if dispatch were corrected. That projection must never be called actual full-parser output.

The header also reads the division word into a nonnegative integer, so the selected SMPTE expression should predict an unsigned-high-byte sign error for the authored 25-fps header. Treat this as source-derived arithmetic, not a fresh F# failure capture or a repository-wide compatibility claim. Do not repair GA on a checkout owned by other work.

## Authored calculations

- MCL007: integrate a PPQN tempo map across its segments; retain note boundaries, meta-event locations and raw microseconds per quarter. Compare two event streams that collapse under a hypothetical branch projection but have different absolute ticks and seconds. Separate the 25-fps SMPTE example and explicit byte-mask/SMPTE predictions from parser execution.
- NET008: fit an explicitly assumed affine relation between audio seconds and performance milliseconds from two authored anchor pairs. Compare offset, rate and unit mistakes. Propagate bounded anchor errors, then use a held-out value to reject the combined affine/error assumptions. Do not treat a fitted relation as observed clock synchronization, an implemented cross-agent protocol or a reliable unqualified extrapolation.
- PM007: contrast requested deadlines, callback execution, scheduled oscillator times and separately observed output. Use authored sequential endpoint records to expose a faster computation with a worse user-boundary result, and preserve the source's physical-string-index scheduling even for muted strings. Specify an actual acquisition and approval decision rather than inventing a measured improvement.

## Primary reading

Read actual Microsoft MIDI timing and Mido library documentation; distinguish their scope from the complete MIDI specification PDF, which is not claimed read. Read the dated Web Audio 1.1 and High Resolution Time working drafts with their draft status explicit, plus the HTML timers body. Do not infer a browser's effective feature support from a specification or source name.

## Review, verification and publication

Independent AI data/source and content reviews must bind exact inputs. Include 15 course-source files, 75 exercise-answer pairs across new and amended courses, and 15 prepared criteria for the new learner tasks. No actual human, musician, fluent-language or learner approval is supplied. Verify source/locale parity, direct URLs, existing generator tests, sync, the complete static build, changed article links and repeat-sync equality. Temporary verification wrappers remain outside the repository.

Use explicit-path commits and normal push to existing Draft PR201, followed by anonymous immutable byte comparison of every changed file. Preserve `streeling/source.json` and the three journals. Keep publication of source/generated files distinct from deployed HTML and real playback evidence.
