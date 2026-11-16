---
execution: knowledge-work
---

# Intonation, interference and discrimination evidence

## Deliverables and project decisions

Produce WML004 on preserving intonation beyond a twelve-step catalog, PHY007 on separating two-tone beating from damping, and COG004 on scoring a two-interval pitch-discrimination task. Place them in the existing World Music & Languages, Physics and Cognitive Science departments. Each course has English, French and Spanish sources and five corrected exercises. Prepare three source-assisted learner tasks and fifteen criteria with null participant and human-review outcomes. The complete goal remains 525 reviewed and publicly readable core courses in 21 departments.

The project decisions are whether a GA handoff retained an intended pitch offset, whether a changing envelope establishes damping, and whether a discrimination score establishes more than its tested task. These are separate questions. Preserve the earlier guitar candidate's failed decay gate; the new toy signals cannot reverse it.

## Sources and boundaries

Use anonymous, byte-matched public GA source at dc2e74cbd992a298f67efb928b5b3754615e1924: WorldScalesConfig.fs, MaqamScales.yaml, MidiNote.cs, Pitch.cs, Tuning.cs, FretboardPositionMapper.cs, MidiTypes.fs and the Rust engine's lib.rs. The world-scale model documents integer semitone intervals, a pitch-class string and a tuning annotation; do not turn its plain strings into an enforced enum or claim it validates every catalog value. The MIDI/fret mapper is a discrete boundary. The audio entry point takes a floating frequency; that signature does not prove exact synthesized pitch. Inspect these specific surfaces without claiming all GA behavior has been audited.

Use NIST's musical-cent definition, the OpenStax beat equation, the official SciPy binomial documentation, the primary auditory-procedure abstract indexed at PMID 528924 and the musician-authored MaqamWorld Rast page. Read their actual contents. Copy no third-party audio, diagrams, prose or exercises; all generated media and problems are original constructions. The 5:4 ratio is a mathematical counterexample, not a prescribed intonation for Rast or another musical tradition. Record the actual GA chord-interval probe separately; interval names do not attest cents or a runtime source revision.

## Before-analysis predictions

- Define C4 from reference A4 = 440 Hz and twelve equal steps as 440*2^((60-69)/12). Construct f_a = (5/4)*C4 and f_b = 440*2^((64-69)/12). The first lies below the second, at about 386.314 versus 400 cents above C4. Their nearest-step projection both gives MIDI 64, losing a residual of about -13.686 cents in one case. This nearest-step projection is an explicitly authored teaching policy, not an observed GA conversion function.
- The stored Rast pitch classes should reconstruct mask 2741; its approx-12tet flag must remain attached. Equality of that mask to a major-scale pitch-class set does not establish a performed tradition or an exact intonation. An advisory cents/reference record is a proposal, not an implemented schema.
- For equal-amplitude cosines with a = 0.125, x(t) = a*cos(2*pi*f_a*t) + a*cos(2*pi*f_b*t) equals 2*a*cos(pi*(f_b-f_a)*t)*cos(2*pi*((f_a+f_b)/2)*t). Check the numerical identity within 1e-10. The unsigned envelope recurs with period 1/abs(f_b-f_a), about 0.385 seconds. A dip can recover with no component damping.
- Measure 20 ms RMS windows centered at the first constructive recurrence, the following destructive point and the next constructive recurrence. Predict a dip at least 10 dB below the first peak and a recovered peak within 1 dB. Repeat those fixed windows with both component frequencies equal as a control; it should not show the large dip. These are constructed signals, not a new GA engine run or observed physical-guitar explanation.
- Generate two one-second cosine WAV assets for a proposed sequential pitch task and one four-second mixture illustration, mono PCM16 at 44100 Hz. Apply a 10 ms boundary fade. For the two task assets, match float RMS to 0.05 before PCM16 conversion; retain the actual decoded RMS difference and never call it perceptual loudness equality. Quantize with nearest-even rounding of sample*32768, verify range and maximum reconstruction error no larger than 0.5/32768. The mathematical figure uses the untapered model; label that boundary.
- Author a balanced twenty-trial answer key and a synthetic trace with five specified errors. It should score 15/20; an always-first response should score 10/20. The public key and fixed order are arithmetic fixtures, not an administered blinded schedule or participant results.
- Under independent fair guesses, compute exact binomial tails with integer combinations and crosscheck SciPy sf(k-1,20,0.5). The smallest integer success count with one-sided tail at most 0.05 should be 15. Fourteen should miss the rule. For eight independent complete tests selected after the fact, compute 1-(1-q)^8 using q equal to the actual discrete tail at that threshold. State independence and multiple-selection limits explicitly.

## Verification and delivery

Record installed numerical/plotting versions and asset/source hashes; install nothing. Temporary analysis produces fixed JSON, original WAVs and an original scientific plot; no new production or teaching-lab program is delivered. Inspect the figure and independently audit formulas, actual samples, synthetic scoring and source boundaries. Review all nine courses and fifteen criteria, normalize text to UTF-8 without BOM and LF before hash binding, synchronize Learn, run existing generator tests and build, then check changed article links and sync idempotence. Commit explicit owned paths to the existing draft PR and anonymously read back immutable bytes. Human, fluent-language, learner, listening and deployed-HTML gates remain separate.
