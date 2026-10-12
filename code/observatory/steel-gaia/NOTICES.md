# Asset provenance and notices

The shell geometry, Godot script, shader and Blender builder were authored for this Observatory project. No external mesh or reference image is bundled. Publication does not assign a new blanket license to the author's project.

| Published texture | Origin | SHA-256 |
|---|---|---|
| `steel_brushed_metalrough.png` | Procedural Blender noise nodes and roughness bake in the existing `artpass/blender/steel_portal.py`, function `bake_brushed_steel`; G roughness, B metal | `5ff2536465d123be778e64d362517af8e02a2a0cc5793b84955b25be33971496` |
| `steel_brushed_normal.png` | Same authored procedural Blender bake; normal map | `37132094bf4d642dd486743dbd57ff2489afeb6f9e2aeaffe8f6c3f42395705c` |
| `steel_grime.png` | Existing local SDXL 1.0 output, postprocessed by `provenance/make_maps.py`; R stains, G streaks | `3383502576071b76ef94967c845086675ebe2ccaea376a45836574b9e4eafeb8` |

The first two PNGs are also embedded byte-for-byte inside `steel_portal_gaia.glb`. Their source generation was procedural; they were reused without rebaking for this geometry pass.

The salissure source PNG contains the same embedded workflow as `provenance/steel-grime.api.json`: cached `sd_xl_base_1.0.safetensors`, seed 20261001, 30 steps, dpmpp_2m / karras, cfg 6.0. Source SHA-256: `9408455d6f486a79044fd94e72c7b222e446016492af62ab7c1afdcd89a737b5`. Its NumPy/Pillow postprocessing was reproduced in memory without an inference and yielded the published asset's exact bytes. The raw source image and model weights are not bundled. `make_maps.py` is retained as historical provenance: it contains its original local path and also processes stone and ornament maps, which are outside this lot.

SDXL 1.0's [CreativeML Open RAIL++-M license](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/blob/main/LICENSE.md) was checked at the primary source on 2026-10-06. Its generated-output provision does not claim rights in outputs; the model's usage restrictions still apply. That model license is not a blanket license for this whole project.

No panorama, marble, book grain, stained-glass, sculpture, third-party model weights, engine executable, NVIDIA library or engine export template is redistributed in this lot. The full-scene evidence JSON refers to the sky used by the existing capture harness: [ESO/S. Brunier, Milky Way panorama eso0932a](https://www.eso.org/public/images/eso0932a/), with the harness's CC BY 4.0 credit. No image pixels from that panorama are bundled here.

Godot and Blender remain separately installed tools. Their respective licenses do not automatically license authored scene assets. Existing engine notices in `public/demos/observatory/` continue to apply to that prebuilt Web package.
