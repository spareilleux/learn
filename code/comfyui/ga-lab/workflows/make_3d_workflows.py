"""Writes the lab's image-to-3D workflows (experiment 11) and the CPU mesh fixture CI runs. Committed JSON, made here.

    python workflows/make_3d_workflows.py     (from code/comfyui/ga-lab)

Only nodes of core ComfyUI v0.36.0 (ee71d5c4), no custom node:
- ga-3d-hunyuan20, experiment 11's workflow, is the chain the Atlas lane (session learn-7e) ran on this machine
  with Hunyuan3D 2.0 (objets.py, maillage()): ImageOnlyCheckpointLoader hunyuan3d-dit-v2_fp16, CLIPVisionEncode
  center, Hunyuan3Dv2Conditioning, EmptyLatentHunyuan3Dv2 3072, KSampler seed 7, 30 steps, cfg 5, euler normal,
  VAEDecodeHunyuan3D (num_chunks 8000, octree_resolution 380), VoxelToMesh surface net 0.6, SaveGLB. Its object
  image comes from SDXL with Atlas's settings (30 steps, cfg 6.5, dpmpp_2m karras, white background prompt), in the
  same prompt. Atlas whitened the background afterwards with a flood fill outside ComfyUI; core has no model-free
  node for that, so here the prompt alone asks for the white background.
The two others are ready for when a model is chosen, and are not in experiment 11:
- Hunyuan3D 2.1 follows the blueprint "Image to Model (Hunyuan3d 2.1)" (blueprints/, and the template
  3d_hunyuan3d-v2.1.json of comfyui-workflow-templates-json 0.1.85): ImageOnlyCheckpointLoader, ModelSamplingAuraFlow
  shift 1, CLIPVisionEncode, Hunyuan3Dv2Conditioning, EmptyLatentHunyuan3Dv2 4096, KSampler 30 steps cfg 5,
  VAEDecodeHunyuan3D (num_chunks 8000, octree_resolution 256), VoxelToMesh surface net 0.6, SaveGLB.
- TRELLIS.2 follows the Trellis.2 branch of the template 3d_pixal3d_trellis2_image_to_model.json (same package):
  structure, 512 shape, upsampled shape and texture samplers with its CFG overrides and seeds, then the template's
  preview branch (decimate, smooth normals, paint vertex colors), saved with SaveGLB, and the raw shape saved too.
- These two get the input image the way their upstream pipelines expect it: background removed (BiRefNet), object cropped
  and centered on a square. Hunyuan3D 2.1's ImageProcessorV2 leaves a 15 % border on white (pad 1/0.85 = 1.18);
  Trellis2Conditioning's tooltip asks for pad_factor 1.0, on black as in the template.
- The object image itself is made in the same prompt by SDXL base 1.0 (lesson 1), from a prompt per object that the
  experiment sets, and saved: no course render shows a whole guitar, headstock, bridge or pick on a plain background.
Node ids: 3-9 SDXL (as in make_workflows.py), 30 saved crop, 40-42 preprocessing, 51-58 Hunyuan3D, 60-83 TRELLIS.2,
90 the final .glb, 91 the raw TRELLIS.2 shape.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SDXL = "sd_xl_base_1.0.safetensors"
OBJECT = ("product photograph of an electric guitar, the whole object in frame with white space around it, "
          "three-quarter view, plain white background, soft even studio light")
NEG = "text, watermark, logo, people, hands, cropped, cut off, several objects, clutter, shadow on the background"


def node(class_type, title=None, **inputs):
    n = {"class_type": class_type, "inputs": inputs}
    if title:
        n["_meta"] = {"title": title}
    return n


def sampler(model, positive, negative, latent, seed, steps, cfg, sampler_name="euler", scheduler="normal"):
    return node("KSampler", seed=seed, steps=steps, cfg=cfg, sampler_name=sampler_name, scheduler=scheduler, denoise=1.0,
                model=list(model), positive=list(positive), negative=list(negative), latent_image=list(latent))


def write(name, workflow, folder=HERE):
    lines = [f"  {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}" for k, v in workflow.items()]
    with open(os.path.join(folder, name), "w", encoding="utf-8", newline="\n") as f:
        f.write("{\n" + ",\n".join(lines) + "\n}\n")


def object_image(pad, background):
    """SDXL draws the object; BiRefNet masks it; ImageCropToMask centers it on a square."""
    return {
        "4": node("CheckpointLoaderSimple", ckpt_name=SDXL),
        "5": node("EmptyLatentImage", width=1024, height=1024, batch_size=1),
        "6": node("CLIPTextEncode", "object prompt, set by the experiment", text=OBJECT, clip=["4", 1]),
        "7": node("CLIPTextEncode", text=NEG, clip=["4", 1]),
        "3": sampler(("4", 0), ("6", 0), ("7", 0), ("5", 0), seed=42, steps=25, cfg=7.0),
        "8": node("VAEDecode", samples=["3", 0], vae=["4", 2]),
        "9": node("SaveImage", filename_prefix="galab/3d/object", images=["8", 0]),
        "40": node("LoadBackgroundRemovalModel", bg_removal_name="birefnet.safetensors"),
        "41": node("RemoveBackground", bg_removal_model=["40", 0], image=["8", 0]),
        "42": node("ImageCropToMask", images=["8", 0], masks=["41", 0], width=1024, height=1024, pad_factor=pad,
                   grow_mask=0, background=background),
        "30": node("SaveImage", filename_prefix="galab/3d/conditioning", images=["42", 0]),
    }


ATLAS_BACKGROUND = ("single isolated object centered, three-quarter view from slightly above, whole object in frame, "
                    "plain pure white background, soft even studio light, no shadow, product photograph, sharp focus")
ATLAS_NEG = ("text, watermark, logo, signature, frame, border, people, hands, lowres, blurry, jpeg artifacts, "
             "oversaturated, cropped, cut off, multiple objects, clutter, table, room, hands")


def hunyuan20():
    """Experiment 11: SDXL draws the object on white, Hunyuan3D 2.0 reads it, as in Atlas's maillage()."""
    return {
        "4": node("CheckpointLoaderSimple", ckpt_name=SDXL),
        "5": node("EmptyLatentImage", width=1024, height=1024, batch_size=1),
        "6": node("CLIPTextEncode", "object prompt, set by the experiment",
                  text="solid body electric guitar, " + ATLAS_BACKGROUND, clip=["4", 1]),
        "7": node("CLIPTextEncode", text=ATLAS_NEG, clip=["4", 1]),
        "3": sampler(("4", 0), ("6", 0), ("7", 0), ("5", 0), seed=5100, steps=30, cfg=6.5, sampler_name="dpmpp_2m",
                     scheduler="karras"),
        "8": node("VAEDecode", samples=["3", 0], vae=["4", 2]),
        "9": node("SaveImage", filename_prefix="galab/3d/object", images=["8", 0]),
        "51": node("ImageOnlyCheckpointLoader", "DiT, VAE and DINOv2 in one file",
                   ckpt_name="hunyuan3d-dit-v2_fp16.safetensors"),
        "53": node("CLIPVisionEncode", clip_vision=["51", 1], image=["8", 0], crop="center"),
        "54": node("Hunyuan3Dv2Conditioning", clip_vision_output=["53", 0]),
        "55": node("EmptyLatentHunyuan3Dv2", resolution=3072, batch_size=1),
        "56": sampler(("51", 0), ("54", 0), ("54", 1), ("55", 0), seed=7, steps=30, cfg=5.0),
        "57": node("VAEDecodeHunyuan3D", samples=["56", 0], vae=["51", 2], num_chunks=8000, octree_resolution=380),
        "58": node("VoxelToMesh", voxel=["57", 0], algorithm="surface net", threshold=0.6),
        "90": node("SaveGLB", mesh=["58", 0], filename_prefix="galab/3d/hunyuan20"),
    }


def hunyuan21():
    wf = object_image(1.18, "#FFFFFF")
    wf.update({
        "51": node("ImageOnlyCheckpointLoader", "DiT, VAE and DINOv2 in one file", ckpt_name="hunyuan_3d_v2.1.safetensors"),
        "52": node("ModelSamplingAuraFlow", model=["51", 0], shift=1.0),
        "53": node("CLIPVisionEncode", clip_vision=["51", 1], image=["42", 0], crop="center"),
        "54": node("Hunyuan3Dv2Conditioning", clip_vision_output=["53", 0]),
        "55": node("EmptyLatentHunyuan3Dv2", resolution=4096, batch_size=1),
        "56": sampler(("52", 0), ("54", 0), ("54", 1), ("55", 0), seed=42, steps=30, cfg=5.0),
        "57": node("VAEDecodeHunyuan3D", samples=["56", 0], vae=["51", 2], num_chunks=8000, octree_resolution=256),
        "58": node("VoxelToMesh", voxel=["57", 0], algorithm="surface net", threshold=0.6),
        "90": node("SaveGLB", mesh=["58", 0], filename_prefix="galab/3d/hunyuan21"),
    })
    return wf


def trellis2():
    wf = object_image(1.0, "#000000")
    wf.update({
        "60": node("CLIPVisionLoader", "DINOv3 ViT-L/16", clip_name="dino_v3_vit_l.safetensors"),
        "61": node("UNETLoader", unet_name="trellis_2_int8_convrot.safetensors", weight_dtype="default"),
        "62": node("VAELoader", "structure and shape decoders", vae_name="trellis_2_shape_vae_bf16.safetensors"),
        "63": node("VAELoader", "texture decoder", vae_name="trellis_2_texture_vae_bf16.safetensors"),
        "64": node("Trellis2Conditioning", clip_vision_model=["60", 0], image=["42", 0]),
        "65": node("EmptyTrellis2LatentStructure", batch_size=1),
        "66": node("CFGOverride", model=["61", 0], cfg=1.0, start_percent=0.667, end_percent=1.0),
        "67": node("RescaleCFG", model=["66", 0], multiplier=0.7),
        "68": node("ModelSamplingSD3", model=["67", 0], shift=5.0),
        "69": sampler(("68", 0), ("64", 0), ("64", 1), ("65", 0), seed=56, steps=12, cfg=7.5),
        "70": node("VaeDecodeStructureTrellis2", samples=["69", 0], vae=["62", 0], resolution="32"),
        "71": node("Trellis2ShapeStage", positive=["64", 0], negative=["64", 1], voxel=["70", 0]),
        "72": node("CFGOverride", model=["61", 0], cfg=1.0, start_percent=0.769, end_percent=1.0),
        "73": node("RescaleCFG", model=["72", 0], multiplier=0.5),
        "74": sampler(("73", 0), ("71", 0), ("71", 1), ("71", 2), seed=42, steps=20, cfg=7.5),
        "75": node("Trellis2UpsampleStage", positive=["71", 0], negative=["71", 1], shape_latent=["74", 0],
                   vae=["62", 0], target_resolution=1024),
        "76": sampler(("73", 0), ("75", 0), ("75", 1), ("75", 2), seed=42, steps=12, cfg=7.5, scheduler="simple"),
        "77": node("VaeDecodeShapeTrellis", samples=["76", 0], vae=["62", 0]),
        "78": node("Trellis2TextureStage", positive=["75", 0], negative=["75", 1], shape_latent=["76", 0]),
        "79": sampler(("61", 0), ("78", 0), ("78", 1), ("78", 2), seed=43, steps=12, cfg=1.0),
        "80": node("VaeDecodeTextureTrellis", samples=["79", 0], vae=["63", 0], shape_subdivides=["77", 1]),
        "81": node("DecimateMesh", mesh=["77", 0], target_face_count=200000, placement_mode="midpoint"),
        "82": node("MeshSmoothNormals", mesh=["81", 0], crease_angle=180.0),
        "83": node("PaintMesh", mesh=["82", 0], voxel_colors=["80", 0]),
        "90": node("SaveGLB", mesh=["83", 0], filename_prefix="galab/3d/trellis2"),
        "91": node("SaveGLB", "raw shape, before decimation", mesh=["77", 0], filename_prefix="galab/3d/trellis2-raw"),
    })
    return wf


def mesh_cpu():
    """CI fixture, no model: the box of tests/fixtures/cube.glb loaded, decimated, smoothed and saved twice."""
    return {
        "1": node("Load3DAdvanced", model_file="3d/galab-cube.glb", viewport_state={}, width=64, height=64),
        "2": node("Get3DComponents", model_3d=["1", 0]),
        "3": node("DecimateMesh", mesh=["2", 0], target_face_count=0, placement_mode="midpoint"),
        "4": node("MeshSmoothNormals", mesh=["3", 0], crease_angle=180.0),
        "5": node("SaveGLB", mesh=["4", 0], filename_prefix="galab/ci-mesh"),
        "6": node("SaveGLB", mesh=["2", 0], filename_prefix="galab/ci-raw"),
    }


def main(folder=HERE, ci_folder=None):
    write("ga-3d-hunyuan20.api.json", hunyuan20(), folder)
    write("ga-3d-hunyuan21.api.json", hunyuan21(), folder)
    write("ga-3d-trellis2.api.json", trellis2(), folder)
    write("mesh-cpu.api.json", mesh_cpu(), ci_folder or os.path.join(os.path.dirname(folder), "tests", "ci"))


if __name__ == "__main__":
    main()
