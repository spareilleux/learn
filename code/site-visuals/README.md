# Site illustrations — provenance

Two pieces of conceptual art: the home page hero (`src/assets/home/research-observatory.webp`) and the image at the top of the machine-learning-ix course (`src/assets/machine-learning-ix/ix-machine-city.webp`). They are decoration. Neither shows how any software works.

## How they were made

- Generated on 2026-09-26 on the author's machine, with no download and no paid service.
- Software: [ComfyUI](https://docs.comfy.org/) 0.36.0 (portable build).
- Model: [Z-Image-Turbo](https://huggingface.co/Tongyi-MAI/Z-Image-Turbo), bf16, with the `qwen_3_4b` text encoder and the `z_image_ae` autoencoder, in the [Comfy-Org repackage](https://huggingface.co/Comfy-Org/z_image_turbo). Licence Apache 2.0. The [ComfyUI course, lesson 8](../../src/content/docs/comfyui/08-recent-models-quantization.md) covers this model.
- Workflow: `z-image.base.api.json`, the ComfyUI course's `ga-lab/workflows/ga-z-image.api.json`, with 8 steps, cfg 1.0, `res_multistep`, AuraFlow shift 3 and no negative prompt. Each job changes only the prompt, the seed and the size, which is 1344 × 768.
- The prompts are in `jobs.json`. They name no film, book, actor or logo: the inspirations are described, not quoted.
- The exact graphs sent for the two chosen images are `workflow-home-20260927.api.json` and `workflow-ix-20260927.api.json`.
- Timings are in `generation-log.json`, one job at a time on an RTX 5080 (16 GB), wall clock from queueing to completion:

  | Job | Time | Kept |
  |---|---:|---|
  | home, seed 20260926 | 443.1 s, which includes loading the models from disk | no |
  | home, seed 20260927 | 72.2 s | **yes** |
  | ix, seed 20260926 | 253.5 s | no |
  | ix, seed 20260927 | 37.1 s | **yes** |

  The spread is model loading, not sampling: 16 GB cannot hold the 12 GB diffusion model and the 8 GB text encoder together, so ComfyUI swaps them.

## How they were checked and edited

I looked at all four candidates, then zoomed into every area that could hold lettering.
- **Home, seed 20260927**, kept for its orrery dome and its centred beam of light. The model drew a readable "5" at the top of the dome. The top 48 rows are cropped, so the asset is 1344 × 720.
- **IX, seed 20260927**, kept because it shows the rock walls, the bridge and the shaft of daylight better. A 36 × 20 pixel indicator panel on the left carried three glyph-like marks. It is blurred.

`postprocess.py` reproduces both WebP files byte for byte from the two PNG outputs. The PNGs are not in the repository: re-run the workflows to get them, but a different GPU or ComfyUI version may not give identical pixels (*to verify*).

The captions on the pages say "conceptual art" and give this provenance, in the three languages.
