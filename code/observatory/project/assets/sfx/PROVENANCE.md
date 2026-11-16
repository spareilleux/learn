# Sounds chosen by ear

Chosen by the author on 2026-10-03 from local takes of Stable Audio 3 Small SFX
(`stable_audio_3_small_sfx.safetensors`, text encoder `t5gemma_b_b_ul2.safetensors`, 8 steps,
cfg 1.0, lcm/simple), run in a local ComfyUI 0.36.0.
Licence: Stability AI Community License (accepted by the author 2026-10-03, "Oui, j'accepte"); Gemma Terms of Use for T5Gemma. Credit due where the Observatory is published: "Powered by Stability AI".

Each file is the take's A/B cut from `artpass/audio/ab/`: mono, its lead silence cut, faded at the
length the cue can last, and matched to the K-weighted loudness of the synthesized cue it replaces
(the gain below). `scripts/sfx_takes.gd` swaps each in; a cue without a file keeps its synthesized
sound. The full record: `artpass/audio/choices.json`, `logs/sfx.jsonl`, `takes-table.md`.

| Cue | Choice | Take | File | A/B gain | SHA-256 |
|---|---|---|---|---|---|
| curio_wheel-whoosh | 2 | seed 2026100301: "a short soft whoosh, a heavy cloth swept quickly through the air, close and dry" | 0.600 s, 44100 Hz, 1 ch | +7.0 dB | `d6424c89a69d15b5` |
| curio_wheel-click | 2 | seed 2026100311: "a single click of a small brass lamp switch, close, dry, crisp" | 0.150 s, 44100 Hz, 1 ch | +8.6 dB | `afc8ec2674aab7c4` |
| curio_wheel-tock | 2 | seed 2026100321: "a single soft wooden tock, a small hardwood block tapped once, dry" | 0.126 s, 44100 Hz, 1 ch | +5.3 dB | `36f1c3ae43180eaa` |
| curio_wheel-squeak | 2 | seed 2026100331: "a small rubber toy squeezed once, a short bright squeak" | 0.222 s, 44100 Hz, 1 ch | +0.7 dB | `ed1339c4e9166289` |
| curio_wheel-quack | 2 | seed 2026100341: "a single short duck quack, close, dry" | 0.269 s, 44100 Hz, 1 ch | +4.0 dB | `3232f7bae3d5c117` |
| curio_wheel-spell | 2 | seed 2026100351: "a magic wand spell, a quick rising shimmer of tiny bells with a fizz of sparkles" | 1.058 s, 44100 Hz, 1 ch | +21.9 dB | `dd930aed24f927c1` |
| curio_wheel-chime | 1 | seed 2026100360: "a single low bronze hand bell struck once, warm, ringing out and fading" | 0.822 s, 44100 Hz, 1 ch | +4.2 dB | `6b580b1e57194c1f` |
| curio_wheel-clank | 2 | seed 2026100371: "a heavy steel slab set down on a polished marble floor, one short metallic footstep, a dull thud with a brief ring" | 0.300 s, 44100 Hz, 1 ch | -2.4 dB | `39456466f21203cc` |
| curio_wheel-beep | 2 | seed 2026100381: "two short soft electronic beeps, the second one higher, a small friendly machine" | 0.500 s, 44100 Hz, 1 ch | +15.4 dB | `a1d999098afbd222` |
| drone-hum | 3d, then synthesised (below) | seed 2026100392: "a small quadcopter drone flying close overhead, loud bright buzzing propellers and a high electric motor whine, steady and constant" | 12.000 s, 22050 Hz, 1 ch (take 3d: 2.312 s, 44100 Hz) | the take's RMS, -25.8 dBFS (take 3d: variant d, pitch x 0.8, low-pass 3000 Hz, +3.3 dB) | `57e9fe96038c6947` (take 3d: `9e7adb0d9a8b790a`) |
| lift-hum | 2 | seed 2026100401: "an old electric elevator motor running steadily, low mechanical hum and soft whir, constant" | 1.850 s, 44100 Hz, 1 ch | +15.2 dB | `8fb1c4c42673f590` |
| lift-bell | 2 | seed 2026100411: "an old elevator arrival bell, one small clear bell ding" | 1.488 s, 44100 Hz, 1 ch | +10.3 dB | `a862662797c95b51` |
| lift-rattle | 2 | seed 2026100421: "an old folding brass elevator gate sliding shut, a quick rattle of metal bars ending in a clack" | 0.532 s, 44100 Hz, 1 ch | +7.8 dB | `ca4492ca261db9c1` |
| hologram_ix-open | 2 | seed 2026100431: "a soft rising hologram power-up shimmer, smooth glassy tone gliding upward, gentle" | 1.201 s, 44100 Hz, 1 ch | +15.2 dB | `f058554677f99cdb` |
| hologram_ix-close | 1 | seed 2026100440: "a soft falling hologram power-down shimmer, smooth glassy tone gliding downward, gentle" | 1.600 s, 44100 Hz, 1 ch | +32.3 dB | `a2b206d1dddd6cb9` |
| hologram_ix-step | 2 | seed 2026100451: "a single glassy pluck, a crystal glass tapped once, short and bright" | 0.600 s, 44100 Hz, 1 ch | +8.8 dB | `cb1e837ea058a194` |
| fresco_frieze-settle | 1 | seed 2026100460: "tiny glass mosaic tiles settling into place, a gentle rain of small glass clinks over a soft resonant tone" | 3.600 s, 44100 Hz, 1 ch | +15.3 dB | `0e0cfa39adabc319` |
| seldon_recording-shimmer | 2 | seed 2026100471: "a soft warm shimmering pad swelling slowly, with tiny glittering sparkles, calm, no voice" | 3.900 s, 44100 Hz, 1 ch | +14.9 dB | `f162e8a4e867503b` |

18 files, 2,189,792 bytes as 16-bit PCM before import.

Since 2026-10-12, `drone-hum.wav` is no longer take 3d. The author asked for the hum « beaucoup moins
fort et plus uniforme (Pas d'effet de boucle) ». `artpass/foundation/audio/make_hum.py` synthesises the
take's timbre: its measured lines as steady sines, and a pink noise floor. It reads no audio and runs no
model, so the Stability AI credit does not cover this file. Take 3d stays in the Foundation copy's
baseline commit and in `artpass/foundation/audio/old/` (`.gdignore`: not imported, not built).

A choice like `3d` is an adjustment of take 3 (the skill sound-ab's `variants.py`), made after the
author's reservation about the take: its file is the variant as heard on the page, with its pitch,
low-pass and level baked in, so the scene plays it as it is.

In the scene, the clank plays 4.5 dB under its file (`sfx_takes.gd` `GAIN_DB`): it repeats 12 to 23
times a second, and its 0.30 s carry 4.5 dB more energy than the synthesized 0.16 s
(`artpass/audio/event_energy.py`, `web-after-v31b/`). The hologram's step plays at 0.70 of its
pitch (`TUNE`).
