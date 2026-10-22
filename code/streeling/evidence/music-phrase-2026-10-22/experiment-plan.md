# Music phrase decisions: production and analysis plan

## Learner problem and scope

Three remaining Music modules should help a guitarist assess an agent's phrase recommendation: choose a registered voice path across several chords; distinguish note attacks, held notes and authored harmonic boundaries; require a specific registered melody above an accompaniment. These are separate tasks from pairwise distance configuration, general meter vocabulary or naming chord inversions.

Produce MUS023, MUS024 and MUS025 in EN/FR/ES, with five corrected exercises per module, fixed data, a separate three-task learner packet and fifteen review criteria. Subject, fluent-language, player and participant reviews remain unperformed. The full original21-department/525-course reviewed and published goal remains active.

## Source boundary

Read GA source at dc2e74cbd992a298f67efb928b5b3754615e1924: AdvancedTabSolver, ProgressionStep, MusicXmlTypes and Tuning. Use anonymous immutable readback and exact Git-byte hashes. The primary GA checkout is user-dirty and read-only. Inspecting a method or its tests does not execute that method. The live get_chord_voicings request for Cmaj7 returned a tool error and no candidate data; retain that failed observation rather than attributing constructed candidates to GA.

No new production or lab program is part of this lot. Small hand calculations and temporary standard-library analysis produce retained JSON tables. They do not compile or run the tab solver, import/export MusicXML, render audio, assess comfort or observe the search UI. All fixtures below are authored examples, not generated GA suggestions or participant performances.

## Predictions written before the analysis run

For MUS023 use labeled registered voices and sum absolute semitone motion. Start [52,59], then Dm7 guide tones [53,60], then either G7-low [53,59] or G7-high [59,65], with the required Cmaj7 endpoint [64,71]. Predict greedy total26 versus full-path minimum24. With endpoint changed to [52,59], predict low-path4 versus high-path26. Keep one best prefix per state distinct from keeping only one state overall. No claim is made that these invented states or this objective are GA output or the full GA physical/style objective.

For MUS024 author note events with absolute quarter-note beat onsets/offsets and half-open active intervals. Notes43/62/65 span[0,2);59 spans[0,4);76 spans[1.5,4);48/64/67 span[2,4). Harmonic labels are separately authored G7 on[0,2) and Cmaj7 on[2,4). Predict sounding snapshots of4,5,5notes over[0,1.5),[1.5,2),[2,4), while attacks at2 are only48/64/67. Events59 and76 remain held across2. At120 quarter-notes per minute,1.5beats is750ms and2beats is1000ms. An onset at1.5 need not create an authored chord change; interpreting76 as an anticipation is an annotation, not automatic inference from the pitch set.

For MUS025 use standard low-to-high string pitches[40,45,50,55,59,64] and constructed Cmaj7 placements A[-1,3,2,0,0,0], B[-1,3,5,4,5,3], C[-1,3,2,0,0,-1], D[-1,3,5,4,8,0]. Predict highest sounding pitches64,67,59,67. Under an explicit arrangement contract requiring melody64 to be highest, only A qualifies. Requiring76 yields no candidate; pitch-class equality must not silently relax register. A coarse constructed position penalty uses the minimum positive fret and predecessor position3: predict costs1,0,1,0. This is not GA DifficultyScore or a comfort measurement.

## Falsifiers, alternatives and limits

Reject a prediction if independently calculated tables disagree. The simpler alternative is hand arithmetic on the small tables; a new optimizer, score parser or DSL would add maintenance without being needed for these learner tasks. Preserve source and analysis distinctions and reject any course wording that upgrades an authored fixture to executed GA behavior. Do not adopt a universal melody, phrase cost or normalization policy: these are task contracts whose usefulness depends on the musical aim. No timing, retention, unaided transfer or causal learning benefit is measured by source-assisted checking.

## Verification and delivery

Normalize owned text to UTF-8/LF before binding hashes. Independently review the numeric fixtures and each localized exercise/answer; audit task/rubric alignment; preserve null human outcomes. Regenerate from canonical streeling sources, run the existing generator tests and Astro build, inspect affected rendered links, commit explicit owned paths to the existing draft PR and read back anonymous immutable GitHub bytes. A draft-source readback is separate from deployed course HTML and from completion of the full university goal.
