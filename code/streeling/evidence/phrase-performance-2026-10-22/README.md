# Phrase timing, string occupancy and explicit repairs

This packet supports MCL004, GTR005 and GAA005. It separates actual native helper calls, observed MCP replies, immutable source inspection and authored numerical examples. It does not implement a new GA phrase planner or establish a performed style, physical playability, listening preference or learner outcome.

## What was actually executed

`native-execution.json` records an unchanged public `MidiTypes.fs` loaded by F# Interactive under the explicitly selected installed SDK 10.0.113. Sixteen cases cover Standard and Drop D, maximum frets 5 and 10, and MIDI pitches 60, 64, 67 and 62. Native position, best-position, pitch-name and position-to-pitch results are in `native-positions.json`. Temporary wrappers and numerical analysis stayed outside the deliverable; their hashes and logs are bound by the receipts. There was no full GA build, dependency installation, C# mapper run, MIDI parser run, GPU execution or audio playback.

`ga-tuning-probes.json` retains the two actual tuning-tool responses. Their values do not attest a deployed source revision or a temporal solver. `primary-readback.json` binds four anonymously retrieved GA files to commit `dc2e74cbd992a298f67efb928b5b3754615e1924` and records the separate primary page reads. The journal and source-import metadata are preserved.

## What the authored examples establish

- F# string 1 is the lowest string in the inspected tuning order. The C# default tuning is normalized highest first. The six-string conversion `7-s` is an authored coordinate adapter, not an executed integration.
- At fret cap 5, the base four-event phrase has one fixed-string assignment. Moving D's onset to beat 1.5 while keeping its offset at 3 produces four active events with only three eligible strings during the half-open interval from 1.5 to 2. This proves infeasibility within the declared independent-sustain model, not universal physical impossibility.
- Delaying D's attack or releasing E earlier yields one assignment each and changes duration. Expanding the cap to 10 preserves the requested pitches and times and yields three assignments with positive-fret spans 3, 7 and 7. Cap 9 and Drop D at cap 5 remain infeasible. Omitting D solves a different event set. These are explicit alternatives, not authorized edits or musician-approved fingerings.
- The invented onset table has mean absolute residuals of 33.75 ms, approximately 9.583333333 ms and 3.75 ms under straight, fixed 2:1 and fitted-common-fraction models. The fitted fraction is `131/208`, estimated on the scored data. This establishes in-sample fit only.
- The parser's inspected integer-BPM expression gives 115 for 520000 microseconds per quarter. A hypothetical four-quarter reconstruction differs from 2.08 seconds by approximately 6.956521739 ms. No parser or playback drift was observed.
- A common strictly increasing map of every event boundary preserves overlap. Moving only D's onset from 1.5 to 2 changes overlap and shortens it; the authored map gives 200 ms, whereas a separate constant 120-quarter-note-per-minute reference gives 250 ms.

`string-occupancy.json`, `repair-options.json` and `timing-models.json` retain the fixed calculations and assumptions. `data-audit.json` is an independent AI audit, including a separate native helper rerun; it is not human review.

## Review and learner boundaries

`learner-task.md` and `reviewer-rubric.json` prepare source-assisted tasks and fifteen criteria. They contain no participant answers or reviewer decisions. Content review covers all nine localized sources and forty-five exercise-answer pairs. Human technical, musician, fluent-language and learner reviews remain pending. No recording or study participant was used. The research support for tempo/role-dependent timing is limited to the publisher abstract and author-hosted page; the full paper and full MIDI specification were not read.

Generation, build, link and idempotence receipts cover local built artifacts. Anonymous immutable GitHub byte readback is distinct from deployed course HTML verification. The original 525-course goal remains incomplete until the required department coverage and review gates are satisfied.
