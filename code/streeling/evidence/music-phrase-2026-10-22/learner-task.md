# Source-assisted tasks: musical phrase decisions

Status: prepared, not performed. Read MUS023, MUS024 and MUS025 and their fixed JSON data. Source inspection and a calculator are allowed. Keep reviewer-rubric.json closed until you record an answer. All examples are constructed; neither the GA tab solver nor a score importer, audio renderer or player was observed in this analysis. The failed live voicing request supplied no candidates.

## MUS023: choose a whole phrase for a stated ending

For the high ending in phrase-paths.json, calculate every edge along both complete paths, then give the two totals and the path selected by a nearest-next-choice rule. Explain the two different decisions “keep one prefix per state” and “keep one state overall,” using the actual prefix costs. Recalculate after changing the ending to the low shell. State the cost rule, voice-identity/register assumptions, candidate-pool limit and which requirement changed. Audit a proposed handoff calling24 “GA's measured total physical cost,” using the pinned solver's internal terms and separate formatted report.

## MUS024: preserve the note events across a chord change

Using timed-events.json, list sounding pitches in all three intervals and the releases, attacks and held pitches at beat2. Distinguish the authored G7/Cmaj7 harmonic boundary from the extra onset at1.5, and identify the status of the anticipation label. Count actual note events and the hypothetical attacks produced by retriggering every snapshot, including the shared B's occurrences. Convert1.5beats,2beats and the full4beat phrase to milliseconds at120 quarter-notes per minute. Explain the unit/scale checks needed before using beat values as DurationMs or MusicXML duration values, and identify when tempo is additionally needed. Specify which original data and executed conversion evidence would be needed for an exact articulation-preserving export.

## MUS025: keep the melody instead of only its pitch class

Decode the four Cmaj7 placements using the explicitly low-to-high tuning and mute convention in melody-constraints.json. For each candidate identify whether it contains E at any octave, contains registered E4, and has E4 as its highest sounding pitch. Explain candidate D's B-string/high-e order and why taking the last sounding array entry fails the highest-pitch contract. Calculate the minimum-positive-fret position and the secondary penalty from predecessor position3. Apply the hard melody condition before the soft score, then repeat with required top E5. State which candidates were constructed, what the failed tool request actually established, and what remains unmeasured about playing comfort.

## Record sheet

Keep participant answers, allowed assistance, fixture/source digests, arithmetic, any commands actually executed, unresolved questions and criterion decisions. Participant and reviewer outcomes stay null until supplied by the relevant people. Source-assisted AI checking is separate from human subject review, fluent-language approval, a player trial, unaided transfer and public HTML publication. None of those outcomes is measured here.
