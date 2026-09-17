"""Writes the lab's API-format workflows. The JSON files are committed; this script is how they were made.

    python workflows/make_workflows.py     (from code/comfyui/ga-lab)

They build on the course's workflows: SDXL base 1.0 (lesson 1), the xinsir union ControlNet (lesson 6), noise-mask
and model inpainting (lesson 5), Pixel Art XL (lesson 7), Z-Image-Turbo in three formats (lesson 8), and on the GA
nodes' workflows in custom-nodes/ga/workflows. Node ids follow lesson 1: 4 loader, 5 latent, 6 and 7 prompts,
3 sampler, 8 decode, 9 save.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SDXL = "sd_xl_base_1.0.safetensors"
CONTROLNET = "xinsir_controlnet_union_sdxl_promax.safetensors"
NEG = "blurry, text, watermark, hands, fingers, people"
NECK = ("photograph of an acoustic guitar neck seen straight from the front, rosewood fretboard, nickel fret wires, "
        "six steel strings, round white marker dots on the strings, even studio light, sharp focus")


def node(class_type, title=None, **inputs):
    n = {"class_type": class_type, "inputs": inputs}
    if title:
        n["_meta"] = {"title": title}
    return n


def ckpt():
    return node("CheckpointLoaderSimple", ckpt_name=SDXL)


def text(t, clip=("4", 1)):
    return node("CLIPTextEncode", text=t, clip=list(clip))


def sampler(model, positive, negative, latent, steps=25, cfg=7.0, denoise=1.0, seed=42, sampler_name="euler",
            scheduler="normal"):
    return node("KSampler", seed=seed, steps=steps, cfg=cfg, sampler_name=sampler_name, scheduler=scheduler,
                denoise=denoise, model=list(model), positive=list(positive), negative=list(negative),
                latent_image=list(latent))


def decode(samples, vae=("4", 2)):
    return node("VAEDecode", samples=list(samples), vae=list(vae))


def save(images, prefix):
    return node("SaveImage", filename_prefix=prefix, images=list(images))


def stitch(a, b, direction):
    return node("ImageStitch", image1=list(a), direction=direction, match_image_size=True, spacing_width=0,
                spacing_color="white", image2=list(b))


def control(positive, negative, image, strength=0.8):
    return {
        "20": node("ControlNetLoader", control_net_name=CONTROLNET),
        "21": node("SetUnionControlNetType", control_net=["20", 0], type="canny/lineart/anime_lineart/mlsd"),
        "22": node("ControlNetApplyAdvanced", positive=list(positive), negative=list(negative), control_net=["21", 0],
                   image=list(image), strength=strength, start_percent=0.0, end_percent=1.0, vae=["4", 2]),
    }


def write(name, workflow):
    lines = [f"  {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}" for k, v in workflow.items()]
    with open(os.path.join(HERE, name), "w", encoding="utf-8", newline="\n") as f:
        f.write("{\n" + ",\n".join(lines) + "\n}\n")


def chord_neck():
    """Experiments 1 and 2: the GA line map drives the union ControlNet in canny mode, like lesson 6's Canny edges.
    Filled notes and no inlay rings (GA pack 846bd2d); node 23 records the map's layout JSON."""
    return {
        "4": ckpt(),
        "5": node("EmptyLatentImage", width=1344, height=768, batch_size=1),
        "6": text(NECK),
        "7": text(NEG),
        "3": sampler(("4", 0), ("22", 0), ("22", 1), ("5", 0)),
        "8": decode(("3", 0)),
        "9": save(("8", 0), "galab/neck"),
        "18": node("GAFretboardControlMap", "GA control map, the latent's size", source="chord", chord="C", key="C",
                   mode="Ionian", fret_start=0, fret_end=5, width=1344, height=768, line_width=4,
                   note_style="filled", inlays="hide"),
        "19": save(("18", 0), "galab/neck-map"),
        "23": node("PreviewAny", "the map's layout JSON, kept in the history for checks/dots.py", source=["18", 2]),
        **control(("6", 0), ("7", 0), ("18", 0)),
    }


def mode_cover():
    """Experiment 3: GA Scale Prompt writes the positive prompt; PreviewAny keeps its text in the history."""
    return {
        "4": ckpt(),
        "5": node("EmptyLatentImage", width=1024, height=1024, batch_size=1),
        "30": node("GAScalePrompt", key="C", mode="Ionian",
                   subject="abstract album cover for a guitar record, geometric shapes, no text"),
        "6": node("CLIPTextEncode", text=["30", 0], clip=["4", 1]),
        "7": text("text, letters, watermark, people"),
        "3": sampler(("4", 0), ("6", 0), ("7", 0), ("5", 0)),
        "8": decode(("3", 0)),
        "9": save(("8", 0), "galab/cover"),
        "31": node("PreviewAny", source=["30", 0]),
    }


def seamless_wood():
    """Experiment 4: generate, roll by half (the seams move to a center cross), repaint the cross, blend it softly."""
    wf = {
        "4": ckpt(),
        "5": node("EmptyLatentImage", width=1024, height=1024, batch_size=1),
        "6": text("seamless texture, flat top-down scan of rosewood fretboard wood, straight grain, even lighting, "
                  "no frets, no strings"),
        "7": text("frets, strings, inlays, border, vignette, shadow, text, watermark"),
        "3": sampler(("4", 0), ("6", 0), ("7", 0), ("5", 0)),
        "8": decode(("3", 0)),
        "40": save(("8", 0), "galab/wood-raw"),
        "41": node("ImageCrop", "top left", image=["8", 0], width=512, height=512, x=0, y=0),
        "42": node("ImageCrop", "top right", image=["8", 0], width=512, height=512, x=512, y=0),
        "43": node("ImageCrop", "bottom left", image=["8", 0], width=512, height=512, x=0, y=512),
        "44": node("ImageCrop", "bottom right", image=["8", 0], width=512, height=512, x=512, y=512),
        "45": stitch(("44", 0), ("43", 0), "right"),
        "46": stitch(("42", 0), ("41", 0), "right"),
        "47": {**stitch(("45", 0), ("46", 0), "down"), "_meta": {"title": "rolled by half: the seams are the center cross"}},
        "50": node("SolidMask", value=0.0, width=1024, height=1024),
        "51": node("SolidMask", value=1.0, width=160, height=1024),
        "52": node("MaskComposite", destination=["50", 0], source=["51", 0], x=432, y=0, operation="add"),
        "53": node("SolidMask", value=1.0, width=1024, height=160),
        "54": node("MaskComposite", "cross to repaint", destination=["52", 0], source=["53", 0], x=0, y=432,
                   operation="add"),
        "55": node("VAEEncode", pixels=["47", 0], vae=["4", 2]),
        "56": node("SetLatentNoiseMask", samples=["55", 0], mask=["54", 0]),
        "57": sampler(("4", 0), ("6", 0), ("7", 0), ("56", 0), denoise=0.75),
        "58": decode(("57", 0)),
        "60": node("MaskToImage", mask=["54", 0]),
        "61": node("ImageBlur", image=["60", 0], blur_radius=31, sigma=10.0),
        "62": node("ImageToMask", "soft cross, so the repaint blends in", image=["61", 0], channel="red"),
        "63": node("ImageCompositeMasked", destination=["47", 0], source=["58", 0], x=0, y=0, resize_source=False,
                   mask=["62", 0]),
        "64": save(("63", 0), "galab/wood-tile"),
        "65": stitch(("63", 0), ("63", 0), "right"),
        "66": stitch(("65", 0), ("65", 0), "down"),
        "67": node("ImageScaleBy", image=["66", 0], upscale_method="area", scale_by=0.5),
        "68": save(("67", 0), "galab/wood-tile-2x2"),
    }
    return wf


def inlays(model_inpaint):
    """Experiment 5: a neck without chord dots from the GA map (stage A, fixed seed), then inlays repainted in the
    mask of the map's inlay positions (stage B), with the base model and a noise mask, or with the inpainting UNet."""
    wf = {
        "4": ckpt(),
        "5": node("EmptyLatentImage", width=1344, height=768, batch_size=1),
        "6": text("photograph of a guitar neck seen straight from the front, plain ebony fretboard without markers, "
                  "nickel fret wires, six steel strings, even studio light, sharp focus"),
        "7": text(NEG),
        "3": sampler(("4", 0), ("22", 0), ("22", 1), ("5", 0), seed=7),
        "8": decode(("3", 0)),
        "9": save(("8", 0), "galab/inlay-base"),
        "18": node("GAFretboardControlMap", "no chord: the map keeps frets, strings and inlay rings", source="chord",
                   chord="xxxxxx", key="C", mode="Ionian", fret_start=0, fret_end=12, width=1344, height=768,
                   line_width=4),
        **control(("6", 0), ("7", 0), ("18", 0), strength=0.7),
        "10": node("LoadImageMask", "inlay mask, from the map's geometry", image="inlay-mask.png", channel="red"),
        "11": text("mother-of-pearl dot inlays set in the fretboard"),
        "12": decode(("13", 0)),
        "14": save(("15", 0), "galab/inlay"),
        "15": node("ImageCompositeMasked", destination=["8", 0], source=["12", 0], x=0, y=0, resize_source=False,
                   mask=["10", 0]),
    }
    if model_inpaint:
        wf.update({
            "16": node("UNETLoader", "SDXL inpainting UNet", unet_name="sdxl_inpainting_0.1_unet_fp16.safetensors",
                       weight_dtype="default"),
            "17": node("InpaintModelConditioning", positive=["11", 0], negative=["7", 0], vae=["4", 2], pixels=["8", 0],
                       mask=["10", 0], noise_mask=True),
            "13": sampler(("16", 0), ("17", 0), ("17", 1), ("17", 2), seed=42),
        })
    else:
        wf.update({
            "16": node("VAEEncode", pixels=["8", 0], vae=["4", 2]),
            "17": node("SetLatentNoiseMask", samples=["16", 0], mask=["10", 0]),
            "13": sampler(("4", 0), ("11", 0), ("7", 0), ("17", 0), seed=42, denoise=0.9),
        })
    return wf


def bracelet_img2img():
    """Experiment 6: lesson 5's img2img from a rasterized pitch-class bracelet."""
    return {
        "4": ckpt(),
        "10": node("LoadImage", "bracelet, rasterized by the runner", image="bracelet.png"),
        "11": node("VAEEncode", pixels=["10", 0], vae=["4", 2]),
        "6": text("an ornate circular brass astrolabe engraved with twelve points, seven of them set with glowing "
                  "amber gems, on dark velvet, photograph"),
        "7": text("blurry, text, watermark"),
        "3": sampler(("4", 0), ("6", 0), ("7", 0), ("11", 0), denoise=0.5),
        "8": decode(("3", 0)),
        "9": save(("8", 0), "galab/bracelet"),
    }


def lora_catalogue():
    """Experiment 7: lesson 7's Pixel Art XL, strength 0 included (the LoRA loaded with no effect)."""
    return {
        "4": ckpt(),
        "5": node("EmptyLatentImage", width=1024, height=1024, batch_size=1),
        "50": node("LoraLoader", model=["4", 0], clip=["4", 1], lora_name="pixel-art-xl.safetensors",
                   strength_model=1.0, strength_clip=1.0),
        "6": text("pixel art, an acoustic guitar standing on a plain background, catalogue item", clip=("50", 1)),
        "7": text("blurry, text, watermark, people", clip=("50", 1)),
        "3": sampler(("50", 0), ("6", 0), ("7", 0), ("5", 0)),
        "8": decode(("3", 0)),
        "9": save(("8", 0), "galab/catalogue"),
    }


def z_image(unet, text_encoder):
    """Experiment 8: lesson 8's Z-Image-Turbo graph with a GA prompt."""
    return {
        "1": node("UNETLoader", "Diffusion model", unet_name=unet, weight_dtype="default"),
        "2": node("CLIPLoader", "Text encoder", clip_name=text_encoder, type="lumina2", device="default"),
        "3": node("VAELoader", vae_name="z_image_ae.safetensors"),
        "4": node("ModelSamplingAuraFlow", model=["1", 0], shift=3.0),
        "5": node("CLIPTextEncode", text="a guitar neck made of polished rosewood floating over a circle of twelve "
                                         "glowing pitch-class dots, seven of them lit, alchemist's workshop, photograph",
                  clip=["2", 0]),
        "6": node("ConditioningZeroOut", "No negative prompt", conditioning=["5", 0]),
        "7": node("EmptySD3LatentImage", width=1024, height=1024, batch_size=1),
        "8": sampler(("4", 0), ("5", 0), ("6", 0), ("7", 0), steps=8, cfg=1.0, sampler_name="res_multistep",
                     scheduler="simple"),
        "9": decode(("8", 0), vae=("3", 0)),
        "10": save(("9", 0), "galab/z-image"),
    }


def diagram_upscale(refine, model=False):
    """Experiment 9: a small GA chord diagram scaled 4 times (Lanczos, or an upscale model), then optionally redrawn
    by SDXL img2img. RealESRGAN x4plus is the upscale model lesson 9 is likely to use: to verify when it is written."""
    wf = {
        "1": node("GAChordDiagram", chord="C", size=256),
        "2": node("ImageScaleBy", image=["1", 0], upscale_method="lanczos", scale_by=4.0),
        "9": save(("2", 0), "galab/diagram-scaled"),
        "30": save(("1", 0), "galab/diagram-small"),
    }
    if refine:
        wf.update({
            "4": ckpt(),
            "11": node("VAEEncode", pixels=["2", 0], vae=["4", 2]),
            "6": text("clean black and white guitar chord diagram, crisp vector lines, solid black dots, white paper"),
            "7": text("blurry, jpeg artifacts, color, shading, texture"),
            "3": sampler(("4", 0), ("6", 0), ("7", 0), ("11", 0), denoise=0.3),
            "8": decode(("3", 0)),
            "9": save(("8", 0), "galab/diagram-refined"),
        })
    if model:
        wf.update({
            "20": node("UpscaleModelLoader", model_name="RealESRGAN_x4plus.pth"),
            "2": node("ImageUpscaleWithModel", upscale_model=["20", 0], image=["1", 0]),
        })
    return wf


def neck_pan(frames=12, width=1024, height=512):
    """Experiment 10a: a pseudo-video with no video model: one wide SDXL neck (from the GA map, frets 0 to 12),
    cropped at sliding offsets and saved as an animated WebP. Camera pan only; nothing moves in the scene."""
    wide = 2048
    wf = {
        "4": ckpt(),
        "5": node("EmptyLatentImage", width=wide, height=height, batch_size=1),
        "6": text(NECK),
        "7": text(NEG),
        "3": sampler(("4", 0), ("22", 0), ("22", 1), ("5", 0)),
        "8": decode(("3", 0)),
        "9": save(("8", 0), "galab/pan-wide"),
        "18": node("GAFretboardControlMap", source="chord", chord="Am", key="C", mode="Ionian", fret_start=0,
                   fret_end=12, width=wide, height=height, line_width=4),
        **control(("6", 0), ("7", 0), ("18", 0)),
    }
    previous = None
    for i in range(frames):
        crop_id, batch_id = str(100 + i), str(200 + i)
        wf[crop_id] = node("ImageCrop", image=["8", 0], width=width, height=height,
                           x=round(i * (wide - width) / (frames - 1)), y=0)
        if previous is None:
            previous = crop_id
        else:
            wf[batch_id] = node("ImageBatch", image1=[previous, 0], image2=[crop_id, 0])
            previous = batch_id
    wf["300"] = node("SaveAnimatedWEBP", images=[previous, 0], filename_prefix="galab/pan", fps=8.0, lossless=False,
                     quality=80, method="default")
    return wf


def wan_video():
    """Experiment 10b: Wan 2.2 TI2V 5B text to video, the template ComfyUI documents (to verify on v0.36.0)."""
    return {
        "1": node("UNETLoader", unet_name="wan2.2_ti2v_5B_fp16.safetensors", weight_dtype="default"),
        "2": node("CLIPLoader", clip_name="umt5_xxl_fp8_e4m3fn_scaled.safetensors", type="wan", device="default"),
        "3": node("VAELoader", vae_name="wan2.2_vae.safetensors"),
        "4": node("ModelSamplingSD3", model=["1", 0], shift=8.0),
        "5": node("CLIPTextEncode", text="macro shot of a single guitar string vibrating after being plucked, "
                                         "rosewood fretboard, shallow depth of field, slow motion", clip=["2", 0]),
        "6": node("CLIPTextEncode", text="blurry, text, watermark, hands", clip=["2", 0]),
        "7": node("Wan22ImageToVideoLatent", vae=["3", 0], width=1280, height=704, length=49, batch_size=1),
        "8": sampler(("4", 0), ("5", 0), ("6", 0), ("7", 0), steps=20, cfg=5.0, sampler_name="uni_pc",
                     scheduler="simple"),
        "9": decode(("8", 0), vae=("3", 0)),
        "10": node("SaveAnimatedWEBP", images=["9", 0], filename_prefix="galab/wan", fps=24.0, lossless=False,
                   quality=80, method="default"),
    }


if __name__ == "__main__":
    write("ga-chord-neck.api.json", chord_neck())
    write("ga-mode-cover.api.json", mode_cover())
    write("ga-seamless-wood.api.json", seamless_wood())
    write("ga-inlays-noisemask.api.json", inlays(False))
    write("ga-inlays-model.api.json", inlays(True))
    write("ga-bracelet-img2img.api.json", bracelet_img2img())
    write("ga-lora-catalogue.api.json", lora_catalogue())
    write("ga-z-image.api.json", z_image("z_image_turbo_bf16.safetensors", "qwen_3_4b.safetensors"))
    write("ga-diagram-upscale.api.json", diagram_upscale(False))
    write("ga-diagram-refine.api.json", diagram_upscale(True))
    write("ga-diagram-esrgan.api.json", diagram_upscale(False, model=True))
    write("ga-neck-pan.api.json", neck_pan())
    write("ga-wan-video.api.json", wan_video())
