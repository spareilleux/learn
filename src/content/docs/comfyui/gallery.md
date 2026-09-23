---
title: Gallery
description: 'Every image this course rendered, with the model, the seed and the workflow that made it, and the page it illustrates — first renders, the same seed twice, steps and CFG sweeps, inpainting failures, Canny edges, quantized models compared, upscaling and seamless textures, and the drawings of the Guitar Alchemist nodes.'
sidebar:
  order: 98
---

Every image of this course, in the order the lessons render them. Each keeps the note written where it appears: the ComfyUI version, the model, the seed and the workflow, so that any of them can be rendered again. The workflows are in [`code/comfyui/workflows/`](https://github.com/spareilleux/learn/tree/main/code/comfyui/workflows), and each link below points at the exact revision that produced the image.

Several of these are failures, kept on purpose. A course that shows only what worked teaches half of it.

## [1. The node graph, installing, and a first image](../01-install-first-image/)

![A brass object on an old wooden workbench, lit by morning sun through a dusty window. It looks more like an ornate hourglass than a metronome: a tall glass body with a narrow waist, held in a brass frame on a round base.](../../../assets/comfyui/l01-metronome.webp)

*Rendered by ComfyUI v0.36.0: Stable Diffusion XL base 1.0, seed 42, 25 steps, `euler` sampler, `normal` scheduler, CFG 7, 1024 × 1024, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json), reduced to 768 × 768 for this page.*

## [2. Diffusion, and what makes an image reproducible](../02-diffusion-reproducibility/)

All the images below were rendered by ComfyUI v0.36.0 from the lesson 1 workflow with one input changed. Every image: Stable Diffusion XL base 1.0, 1024 × 1024, positive prompt "a brass metronome on an old wooden workbench, morning light through a window, dust in the air, photograph", negative prompt "blurry, text, watermark", workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json), reduced for this page. Unless the caption says otherwise: seed 42, 25 steps, CFG 7, `euler` sampler, `normal` scheduler.

![Five renders side by side. With 1 step, a dark reddish blur. With 4 steps, a dim, soft cone-shaped object in a dark room. With 10 steps, a clear brass object on a workbench by a window. With 25 and 50 steps, a sharper version of the same scene, the 50-step one with more tools on the bench.](../../../assets/comfyui/l02-steps.webp)

*Seed 42; 1, 4, 10, 25 and 50 steps.*

![Four renders side by side. With CFG 1, a washed-out, transparent glass lantern in a faded room. With CFG 3, a pale brass object in a hazy workshop. With CFG 7, the saturated brass object of lesson 1. With CFG 12, a more contrasted version with a square base.](../../../assets/comfyui/l02-cfg.webp)

*Seed 42; CFG 1, 3, 7 and 12.*

![Three renders side by side. euler with normal: the brass object of lesson 1. dpmpp_2m with karras: a very similar composition with small differences in the tools. euler_ancestral: a different object, a brass pyramid on a square base, in front of a sunlit window.](../../../assets/comfyui/l02-samplers.webp)

*Seed 42; `euler` with `normal`, `dpmpp_2m` with `karras`, `euler_ancestral` with `normal`.*

![Four renders side by side, all of a brass object on a workbench by a window. Seed 42: the ornate hourglass-like object. Seed 43: a pyramid-shaped object with a graduated scale, closer to a metronome. Seed 7: a squat hourglass on a square base, with a curtain. The second image of a batch of two with seed 42: a tall conical object next to a wooden stand.](../../../assets/comfyui/l02-seeds.webp)

*Seeds 42, 43 and 7; then the second image of a batch of two with seed 42 (`batch_size` 2).*

![Three panels. The first two are the two seed-42 renders, which look the same at this size. The third is a white image with dark lines where they differ, amplified eight times: the outline of the brass object, its glass, the tools on the bench and the window frame.](../../../assets/comfyui/l02-cold-warm.webp)

*Left: first run after starting the server. Middle: the same graph run again after the negative prompt was re-encoded. Right: where they differ, eight times amplified, dark where the difference is large.*

## [5. Img2img, inpainting and outpainting](../05-img2img-inpainting/)

![Five images side by side. The first is lesson 1's photograph of a brass hourglass-like object on a workbench. The next four are watercolor-like versions: with denoise 0.3 and 0.5 the composition is identical and the style changes; with 0.7 the window and tools start to move; with 0.9 the object is simpler, the tools are different and the window has a new shape.](../../../assets/comfyui/l05-img2img.webp)

*Rendered by ComfyUI v0.36.0: Stable Diffusion XL base 1.0, seed 42, 25 steps, CFG 7, `euler`, `normal`, workflow [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-img2img.api.json) with the prompt "a watercolor painting of a brass metronome on an old wooden workbench, morning light through a window". From left to right: the starting image, then `denoise` 0.3, 0.5, 0.7 and 0.9.*

![Six crops of the front right of the workbench, each 340 by 240 pixels. The original has two small wooden objects. VAEEncodeForInpaint: the objects are gone, and a pale ellipse with a different wood texture shows where the mask was. Noise mask with denoise 1: a flat bluish stripe and a small white blob inside a visible ellipse. Noise mask with denoise 0.8: the two objects are still there, darker and harder, with a dark outline. Inpainting model with denoise 0.99: a brass bell lying on its side and a round wooden piece, in the same light as the rest of the bench.](../../../assets/comfyui/l05-inpaint.webp)

*Rendered by ComfyUI v0.36.0: Stable Diffusion XL base 1.0, and the SD-XL inpainting 0.1 UNet for the last crop; seed 42, 25 steps, CFG 7, `euler`, `normal`, prompt "a small brass bell on an old wooden workbench, morning light through a window, photograph". From left to right: the original, [`05-inpaint-vaeencode`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json), [`05-inpaint-noisemask`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-noisemask.api.json) with `denoise` 1 and 0.8, and [`05-inpaint-model`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json) with `denoise` 0.99. Each crop is the result pasted back into the original.*

![A wide image, 1536 by 1024 pixels reduced: the brass object on its workbench in the middle, with a workshop added on both sides: shelves and a lamp on the left, the window continued and a vise on the right.](../../../assets/comfyui/l05-outpaint.webp)

*Rendered by ComfyUI v0.36.0: SD-XL inpainting 0.1 UNet with the SDXL base 1.0 text encoders and VAE, seed 42, 25 steps, CFG 7, `euler`, `normal`, `denoise` 0.99, workflow [`05-outpaint.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-outpaint.api.json): 256 pixels added on the left and on the right, feathering 40.*

## [6. ControlNet: edges and depth](../06-controlnet/)

![Four images of 1024 pixels side by side. First, white edges on black: the outline of the hourglass-like object, its base, the window frame and the tools on the bench. Second, the same object carved in translucent blue ice, standing on its wooden base, in the same place and light. Third, a gray depth map: the object and its base in white, the bench in light gray, the window dark gray. Fourth, the object redrawn in polished wood with the same silhouette, with small wooden pieces around it.](../../../assets/comfyui/l06-canny-depth.webp)

*Rendered by ComfyUI v0.36.0: Stable Diffusion XL base 1.0 with xinsir's ControlNet union SDXL ProMax at `strength` 0.8, seed 42, 25 steps, CFG 7, `euler`, `normal`. From left to right: the edges of lesson 1's image, `Canny` 0.4 and 0.8; the render of [`06-canny.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/06-canny.api.json), prompt "a metronome carved from blue ice on an old wooden workbench, morning light through a window, photograph"; the Lotus depth map; the render of [`06-depth.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/06-depth.api.json), prompt "a small robot made of polished wood on an old wooden workbench, morning light through a window, photograph".*

![Three renders of the ice object side by side. With strength 0.3, the object has the same shape, the light is softer and the window bars are in slightly different places. With strength 1.0, the image is almost the same as with 0.8. With end percent 0.3, the image is almost the same as with the ControlNet on for every step.](../../../assets/comfyui/l06-strength.webp)

*Rendered by ComfyUI v0.36.0: Stable Diffusion XL base 1.0 with xinsir's ControlNet union SDXL ProMax, seed 42, 25 steps, CFG 7, `euler`, `normal`, workflow [`06-canny.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/06-canny.api.json). From left to right: `strength` 0.3, `strength` 1.0, and `strength` 0.8 with `end_percent` 0.3.*

## [7. LoRA: loading, stacking, and what training one involves](../07-lora/)

![Three pixel art images side by side. With strength 0.5, a detailed brass hourglass-like object on a workbench, in front of a window with trees, with fine pixels. With strength 1.0, a simpler object in a wooden room with bottles on a shelf, with coarser pixels. With strength 1.5, no metronome: a small table with a green flask, a framed picture and a window, in large flat pixels.](../../../assets/comfyui/l07-pixel-art.webp)

*Rendered by ComfyUI v0.36.0: Stable Diffusion XL base 1.0 with Pixel Art XL, seed 42, 25 steps, CFG 7, `euler`, `normal`, prompt "pixel art, a brass metronome on an old wooden workbench, morning light through a window", workflow [`07-lora.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lora.api.json). From left to right: `strength_model` and `strength_clip` 0.5, 1.0 and 1.5.*

![Four images side by side. SDXL base with 4 steps: a dark, blurry cone-shaped object in front of a window. LCM-LoRA: a sharp brass and glass instrument with a scale, on a bench by a window. SDXL-Lightning: a brass lantern-like object holding an hourglass, by a window, sharp. LCM-LoRA with Pixel Art XL: a pixel art wooden cabinet with a green tube inside a frame, on a brick wall.](../../../assets/comfyui/l07-few-steps.webp)

*Rendered by ComfyUI v0.36.0: Stable Diffusion XL base 1.0, seed 42, prompt "a brass metronome on an old wooden workbench, morning light through a window, dust in the air, photograph" for the first three. From left to right: [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/01-txt2img.api.json) with 4 steps, CFG 7, `euler`, `normal` and no LoRA; [`07-lcm.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lcm.api.json), LCM-LoRA, 4 steps, CFG 1, `lcm`, `sgm_uniform`; [`07-lightning.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lightning.api.json), SDXL-Lightning 4-step LoRA, 4 steps, CFG 1, `euler`, `sgm_uniform`; [`07-lora-stack.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lora-stack.api.json), LCM-LoRA at 1.0 and Pixel Art XL at 1.2, 8 steps, CFG 1.5, `lcm`, `sgm_uniform`, prompt "pixel art, a brass metronome on an old wooden workbench, morning light through a window".*

## [8. Recent models and their licenses, quantization and VRAM](../08-recent-models-quantization/)

![Four renders side by side, each a gold and black pyramid metronome on a worn wooden workbench in front of a window. bf16 and int8: nearly the same image, with a device with switches on the left. nvfp4 with the fp4 text encoder: the same kind of scene, with the metronome a little larger and books and a jar on the bench. nvfp4 with the bf16 text encoder: close to the previous one, with the objects arranged differently.](../../../assets/comfyui/l08-quantized.webp)

*Rendered by ComfyUI v0.36.0: Z-Image-Turbo, seed 42, 8 steps, CFG 1, `res_multistep`, `simple`, shift 3, prompt "a brass metronome on an old wooden workbench, morning light through a window, dust in the air, photograph", workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). From left to right: bf16 network with the bf16 text encoder; int8 convrot with fp8 mixed; nvfp4 with fp4 mixed; nvfp4 with bf16.*

![Four renders side by side. First, Z-Image-Turbo's bf16 render with seed 43: a pyramid metronome on a workbench. Then three FLUX.2 klein 4B renders with seeds 42, 43 and 44: each a dusty workshop with a window and a brass object on a worn bench, but the object is a stand with a crank or arms, not a metronome.](../../../assets/comfyui/l08-z-image-klein.webp)

*Rendered by ComfyUI v0.36.0. First: Z-Image-Turbo bf16, seed 43, settings as above. Then: FLUX.2 klein 4B distilled, bf16, with the Qwen3 4B text encoder, seeds 42, 43 and 44, 4 steps, CFG 1, `euler`, `Flux2Scheduler`, same prompt, workflow [`08-flux2-klein.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-flux2-klein.api.json).*

## [9. Upscaling, seamless textures and HDR](../09-upscaling-seamless-hdr/)

![Three 512 × 512 crops of the same guitar neck against a brick wall, enlarged four times. Nearest: square blocks of four pixels on the strings and frets. Lanczos: smooth but soft, with light halos along the frets. Real-ESRGAN: sharp frets and strings, flatter brick, and the fret wire drawn as clean bright lines.](../../../assets/comfyui/l09-upscale-methods.webp)

*Rendered by ComfyUI v0.36.0: the detail at (384, 384) of the first render of the next section, enlarged 4 × with `ImageScaleBy` `nearest-exact`, `ImageScaleBy` `lanczos`, and `ImageUpscaleWithModel` with `RealESRGAN_x4plus.safetensors`, workflow [`09-upscale-model.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-upscale-model.api.json). Each panel shows the middle 512 × 512 pixels of the 1024 × 1024 result, at 1:1.*

![Four panels. First, the whole 1024 × 1024 render: an acoustic guitar leaning against a brick wall next to a shop window with more guitars. Then the same 512 × 512 crop of three 2048 × 2048 versions: Lanczos, soft; Real-ESRGAN, sharp strings and brick; hires fix, with new wood grain and brick texture and the fret markers moved.](../../../assets/comfyui/l09-hires-fix.webp)

*Rendered by ComfyUI v0.36.0: Z-Image-Turbo nvfp4 with Qwen3 4B fp4 mixed, seed 42, 8 steps, CFG 1, `res_multistep`, `simple`, shift 3, prompt "an acoustic guitar leaning against a brick wall in a small music shop, warm evening light, photograph", workflow [`09-hires-fix.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-hires-fix.api.json). From left to right: the first pass; the crop (768, 768) to (1280, 1280) of Lanczos 2 ×, Real-ESRGAN then Lanczos 0.5, and the hires fix at denoise 0.33 with seed 42.*

![Four 512 × 512 crops of the guitar's headstock and neck against the brick wall, after the hires fix at denoise 0.2, 0.33, 0.5 and 0.7. At 0.2 the image is the upscaled one with a little more texture. At 0.33 the bricks gain grain. At 0.5 the mortar lines and brick stains change. At 0.7 the headstock is redrawn with different tuners, and the neck is narrower.](../../../assets/comfyui/l09-hires-denoise.webp)

*Rendered by ComfyUI v0.36.0: the same workflow and first pass, second pass denoise 0.2, 0.33, 0.5 and 0.7, crop (768, 256) to (1280, 768).*

![Three 512 × 512 crops of the same headstock and neck after a latent upscale and a second pass at denoise 0.3, 0.55 and 0.75. At 0.3 the image is covered with a fine noisy grain and the strings are doubled. At 0.55 it is clean, with the brick redrawn. At 0.75 the headstock and the fret markers are redrawn.](../../../assets/comfyui/l09-latent-denoise.webp)

*Rendered by ComfyUI v0.36.0: Z-Image-Turbo nvfp4, same first pass, `LatentUpscaleBy` `bislerp` 2 ×, second `KSampler` with 8 steps, `res_multistep`, `simple`, denoise 0.3, 0.55 and 0.75, workflow [`09-latent-upscale.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-latent-upscale.api.json).*

![Four 384 × 384 panels. A rosewood texture with vertical grain. The same texture offset by half, with a visible horizontal and vertical seam in the middle. A black square with a white cross, soft at its edges. The result, where the middle shows continuous grain and no hard line.](../../../assets/comfyui/l09-seamless-steps.webp)

*Rendered by ComfyUI v0.36.0: Z-Image-Turbo int8 convrot with Qwen3 4B fp8 mixed, seed 42 for both passes, 8 steps, CFG 1, `res_multistep`, `simple`, prompt "flat top-down photograph of dark rosewood, fine straight grain, even soft lighting, no shadows, wood texture", workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json). From left to right: the render, the offset, the mask, the result.*

![Four tiled previews, each a 2 × 2 repeat. Rosewood as rendered: a clear grid of hard seams. Rosewood after the repair: no hard seams, with slightly darker and lighter blocks still visible. Pale maple as rendered: a grid of seams. Maple after the repair: no hard seams, with soft vertical bands of lighter and darker wood.](../../../assets/comfyui/l09-seamless.webp)

*Rendered by ComfyUI v0.36.0: the same workflow and model. From left to right: rosewood as rendered, repaired; maple, prompt "flat top-down photograph of pale maple wood, a planed board with fine straight grain, even soft lighting, wood texture", as rendered, repaired. Each panel is a 2048 × 2048 repeat shown at 512 × 512.*

## [11. Custom nodes, and their security](../11-custom-nodes-and-security/)

![Six chord charts in a row, black on white, low E string on the left and the nut at the top. C: a cross over string 6, dots on fret 3 of string 5, fret 2 of string 4 and fret 1 of string 2, circles over strings 3 and 1. G: dots on fret 3 of strings 6 and 1 and fret 2 of string 5, three open strings. A minor: a cross, then dots on fret 2 of strings 4 and 3 and fret 1 of string 2. F: dots on fret 1 of strings 6, 2 and 1, fret 3 of strings 5 and 4, fret 2 of string 3. E7: dots on fret 2 of string 5 and fret 1 of string 3, four open strings. B minor seven flat five: crosses over strings 6 and 1, dots on frets 2, 3, 2 and 3 of strings 5 to 2.](../../../assets/comfyui/l11-chord-diagrams.webp)

*Drawn by the GA Chord Diagram node with Pillow, not by a diffusion model: `C`, `G`, `Am`, `F`, `E7` and `Bm7b5`, 256 pixels each, the images of [`expected/`](https://github.com/spareilleux/learn/tree/22f2bf71c21d2cc4f426c0e917e7e19dbfca5bc3/code/comfyui/custom-nodes/ga/expected).*

![Two fretboard maps, one above the other. Above, white lines on black: the neck from the nut to fret 5, six strings, a thick nut on the left, two small inlay circles, and the C major chord as white rings: fret 3 on the A string, fret 2 on the D string, fret 1 on the B string, and two rings left of the nut for the open G and high E strings. Below, the depth version of A Aeolian from fret 5 to fret 12: a grey fingerboard, lighter strings and fret wires, and white dots on every note of the A minor scale.](../../../assets/comfyui/l11-control-maps.webp)

*Drawn by the GA Fretboard Control Map node with Pillow: the `lines` output for the chord `C`, frets 0 to 5, and the `depth` output for A Aeolian, frets 5 to 12; both 1024 × 1024, cropped around the neck and reduced.*

## [Journal](../journal/)

![A brass object on an old wooden workbench, lit by morning sun through a dusty window. It looks more like an ornate hourglass than a metronome: a tall glass body with a narrow waist, held in a brass frame on a round base.](../../../assets/comfyui/l01-metronome.webp)

*The first render. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, seed 42, 25 steps, `euler`, `normal`, CFG 7, 1024 × 1024, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json).*

![Three panels. The first two are the two seed-42 renders, which look the same at this size. The third is a white image with dark lines where they differ, amplified eight times: the outline of the brass object, its glass, the tools on the bench and the window frame.](../../../assets/comfyui/l02-cold-warm.webp)

*The two seed-42 images. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, seed 42, 25 steps, `euler`, `normal`, CFG 7, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json). Left: first run after starting the server. Middle: the same graph after the negative prompt was encoded again. Right: where they differ, amplified eight times.*

![Three crops of the front of the workbench. First: a flat gray ellipse with faint shading where the objects were. Second: a sharp ellipse of pale, rough wood with a dark rim along its top. Third: two new wooden objects on the bench, with no visible edge.](../../../assets/comfyui/journal-l05-failures.webp)

*Two inpainting failures and the fix, before pasting back. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, seed 42, 25 steps, CFG 7, `euler`, `normal`. From left to right: [`05-inpaint-vaeencode.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json) with `denoise` 0.5; the same workflow with `denoise` 1 and a mask with a 24-pixel soft edge; [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json), the SD-XL inpainting 0.1 UNet with `denoise` 0.99, on the same soft mask.*

![White edge lines on black, drawn in blocky pixels: a honeycomb of wavy cells drawn from the course's test pattern.](../../../assets/comfyui/journal-canny-ci.webp)

*The `Canny` node's output on the author's machine, pixel hash `77af5cb1b7e93a5c`, 464 edge pixels, enlarged four times without smoothing. ComfyUI v0.36.0 on the CPU, no model, thresholds 0.05 and 0.15, workflow [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json). The three CI runners each drew 467 edge pixels, with three other hashes.*

![Four renders side by side, each a gold and black pyramid metronome on a worn wooden workbench in front of a window. The first two are nearly the same; the last two show the same scene with the objects arranged differently.](../../../assets/comfyui/l08-quantized.webp)

*ComfyUI v0.36.0: Z-Image-Turbo, seed 42, 8 steps, CFG 1, `res_multistep`, `simple`, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). From left to right: bf16 with the bf16 text encoder, int8 with fp8, nvfp4 with fp4, nvfp4 with bf16.*

![Four renders side by side. First, Z-Image-Turbo's pyramid metronome on a workbench. Then three FLUX.2 klein 4B renders of a dusty workshop, each with a brass stand with a crank or arms on a worn bench instead of a metronome.](../../../assets/comfyui/l08-z-image-klein.webp)

*ComfyUI v0.36.0. First: Z-Image-Turbo bf16, seed 43, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). Then: FLUX.2 klein 4B, seeds 42, 43 and 44, 4 steps, CFG 1, `euler`, workflow [`08-flux2-klein.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-flux2-klein.api.json).*

![Three panels. A 2 × 2 repeat of a rosewood texture, with faint horizontal and vertical lines across each tile. A crop of the middle of that texture, where a row of dark speckles runs across the grain and the lower half is lighter. A 2 × 2 repeat of pale wood with a large carved maple leaf in each tile.](../../../assets/comfyui/journal-l09-seamless-failures.webp)

*Failures, before the fix. ComfyUI v0.36.0: Z-Image-Turbo nvfp4 with Qwen3 4B fp4 mixed, seed 42, 8 steps, CFG 1, `res_multistep`, `simple`, workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json) with its cross set to 160 pixels, 64 of feather and denoise 0.7. From left to right: rosewood repeated 2 × 2; the middle 512 × 512 pixels of the rosewood; the prompt "flat top-down photograph of pale maple, subtle straight grain, even soft lighting, no shadows, wood texture", repeated 2 × 2.*
