---
execution: knowledge-work
base_learn_commit: c9b075001d9b120d68a16affb9498ab1979f926e
source_ga_commit: 76efbffd5af82b46c3146957a6bd4504008eeb89
---

# Pluck coordinates and attack-clock course production plan

Produce GAS006 (ideal triangular pluck modes versus GA excitation), GTR006 (physical picking distance versus fretted length) and AUD007 (per-sample attack envelope versus milliseconds), each in EN/FR/ES with five corrected exercises and a prepared transfer task. Root owns English and fixed evidence. Scoped translator owns six locale sources; independent reviewers own their separate receipts. No production code, new runnable lab, guitar performance, DSP render, host, ComfyUI generation or dependency installation is delivered or executed.

## Predictions before fixed calculations

- The pinned Rust source chooses a velocity-dependent normalized delay-buffer offset, quantizes it to an integer and applies a clipped tent window to filtered noise. This is not a fixed-peak triangular physical displacement with zero initial velocity. Existing pluck_mix/brightness lessons are prerequisites, not repeated content.
- For an ideal flexible, uniform, fixed-end, linear string, normalized coordinate u=x/L from the bridge and peak displacement h at p give a piecewise triangular initial condition. Its modal coefficient is B_n/h=2 sin(n*pi*p)/(pi^2*n^2*p*(1-p)). At p=1/2 even modes vanish, p=1/5 every fifth, p=1/10 every tenth. Modal displacement coefficients are not bridge-force, microphone or listener measurements. Finite mode sums are approximations; sharp corners require bandlimiting in a sampled implementation.
- Ideal equal-tempered fretting at fret k gives vibrating length L_k=L_0*2^(-k/12). With L_0=650mm and bridge-relative hand distance d=65mm, p=d/L_k changes from1/10 open to1/5 at fret12 and2/5 at fret24. Keeping p=1/10 instead requires d=65,32.5,16.25mm. An authored geometry hypothesis is not an observed player's motion or the engine's current convention.
- GA's effective attack multiplier is frequency-adjusted, clamped and multiplied once per active voice sample while attack_level>1e-3. For profile0 at low E it is near0.988; the isolated positive envelope follows A[n]=A0*r^n until its threshold stops updates. Its exact continuous extension has tau=-1/(Fs*ln(r)); a fixed r has a shorter duration at48k than44.1k. Matching milliseconds would require r_new=r_old^(Fs_old/Fs_new), a proposed isolated coefficient translation, not a completed whole-engine fix.
- Calculate threshold crossings as first integer n with A0*r^n<=1e-3, and distinguish n updates from inclusion of sample index0. Current-source floating-point arithmetic, voice admission, body filters, clipping and audio output are not reproduced by this real-arithmetic envelope calculation.

## Sources and synthesis

Read three public GA Rust/bridge/worklet files at the pinned commit. Read Julius O. Smith's primary ideal-plucked-string and one-pole-time-constant sections. Read Kirk McDonald's Princeton Ph205 lecture21 PDF for the fixed-end triangular coefficient derivation; direct HTTP download works even if web open fails. Record transport failures separately. Use fixed model arithmetic and independent quadrature/recomputation to verify, without fabricating a synth run or physical recording.

## Gates

Independent numeric/source review, independent45localized exercise-answer pairs and15learner criteria; locale metadata/URL/code/numeric parity. Existing18generator tests, sync, full Astro build, rendered routes/links/anchors and repeat-sync byte equality. Preserve source.json and three journals. Explicit add/commit paths and normal push to existing Draft201 after fresh branch/origin/PR/head checks, with no PR title/body rewrite. Anonymous immutable GitHub byte readback is source publication, not deployed HTML or human approval. Human technical, fluent-language, musician and learner outcomes remain null until observed.
