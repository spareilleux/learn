# Source-assisted audio evidence transfer task

Status: prepared, not administered. Use the three linked course sources and pinned evidence. Do not prefill a learner decision from the answer keys or AI content review. Record the actual response, elapsed time if observed, assistance, source references, confidence and unresolved questions. No duration, competence, listener preference or learning gain has been measured.

## GAS007 — Review a body-frequency proposal

An agent proposes a control named “110 Hz body peak” after inspecting the engine constructor.

1. Derive the isolated transfer function from the additive recurrence and identify the denominator signs.
2. Calculate the isolated maxima for the 110 Hz and 240 Hz sections at 44100 Hz; explain the endpoint condition and compare the first section's DC and 110 Hz gains.
3. Calculate the dry magnitude at 110 Hz by combining all five complex sections with the direct path, then compare it with the sum-of-magnitudes alternative.
4. Give a steady-input counterexample to the claim that this parameter inserts a sustained 110 Hz spectral line; distinguish startup ringing.
5. Specify evidence needed before claiming physical accuracy, including the paired acquisition boundary and the downstream stages to separate.

## AUD008 — Review a claimed gain improvement

An agent compares two output recordings and attributes a doubled partial amplitude to a changed filter.

1. Declare the boundary and transform conditions for the periodic two-tap fixture.
2. Compare paired complex coefficients across both excitation amplitudes.
3. Decide what can be reported at an analytically unexcited bin; calculate the apparent complex response in the weak-excitation noise control and explain its failure.
4. Explain the finite linear convolution with its last sample discarded, then propose a valid comparison boundary.
5. Specify a retained artifact sufficient for a qualified gain and phase question, without assuming an arbitrary transient STFT ratio is exact.

## INF008 — Review a waveform-identity claim

An agent receives a magnitude-only representation and claims that two guitar attacks are identical.

1. Derive the equal-magnitude identity for the two authored responses and assess every integer circular shift.
2. Identify a complex coefficient or phase that distinguishes the candidates.
3. Explain what zero-phase inverse transformation assumes and why this example does not settle all constrained overlapping-frame inversions.
4. Calculate the energy centroids and state what this descriptor cannot establish about hearing or pure delay.
5. Distinguish actual audio samples, canonical pitch-class vectors and actual chroma before defining the agent handoff.

## Review record

Use `reviewer-rubric.json` for five criteria per module. Preserve ambiguous and partially correct answers; do not silently rewrite them into success. The review requires actual learner answers before any learner decision. AI checks of the course answer keys, source transport, a static build and public source readback are separate records.
