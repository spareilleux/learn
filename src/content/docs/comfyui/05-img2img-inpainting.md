---
title: '5. Img2img, inpainting and outpainting'
description: 'Starting from an image instead of noise — uploading it through the API, what denoise really changes in the schedule, three ways to repaint part of an image with SDXL and what each does to the masked pixels, pasting the result back so the rest of the image stays untouched, and extending a canvas — with the renders compared on one GPU and the mask nodes checked in CI.'
sidebar:
  order: 5
---

Code: the workflows [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-img2img.api.json), [`05-inpaint-vaeencode.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json), [`05-inpaint-noisemask.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-noisemask.api.json), [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json) and [`05-outpaint.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-outpaint.api.json); the upload in [`csharp/ComfyClient.cs`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/csharp/ComfyClient.cs), the mask image in [`csharp/Images.cs`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/csharp/Images.cs), and the workflow CI runs without a model in [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json).

Lessons 1 to 4 started every image from an empty latent, and `KSampler` filled it with noise. This lesson gives the sampler an existing image instead. The starting point is lesson 1's metronome, seed 42, and every render below uses SDXL base 1.0 or its inpainting variant.

## Sending an image to the server

A workflow can't read a file from the client's disk. `LoadImage` reads from the server's `input` folder, so a client first uploads the file with `POST /upload/image`: a multipart form with the file in a part named `image`, and optional `subfolder`, `type` and `overwrite` fields ([`server.py`, lines 397 to 467](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L397-L467)). The answer gives the name to put in `LoadImage`'s `image` input. The course's client does both with one option:

```text
comfy run http://127.0.0.1:8188 workflows/05-img2img.api.json --image 10.image=metronome.png
```

What happens when a name is already taken is not in the documentation. CI uploads the same file twice, then a different file with the same name, then that one again with `overwrite`, then a file into `../outside`:

```text
POST /upload/image pattern-hole.png: 200, name pattern-hole.png, subfolder "", type input
POST /upload/image pattern-hole.png: 200, name pattern-hole (1).png, subfolder "", type input
POST /upload/image pattern-hole.png: 200, name pattern-hole.png, subfolder "", type input
HttpRequestException: POST /upload/image: 400 
```

The first line is the second upload of identical bytes: the server compares a hash and keeps the existing file ([lines 423 to 432](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L423-L432)). Different bytes get a new name, and a client that assumes its own file name would read the old image. `overwrite` replaces the file. A subfolder that leaves the input folder is refused.

### The mask is the transparent part

`LoadImage` has two outputs: the image, and a mask computed from its alpha channel as `1 - alpha` ([`nodes.py`, lines 1784 to 1790](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1784-L1790)). Transparent pixels are the ones to repaint. An image without alpha gives a mask of zeros, 64 by 64 pixels whatever the image size. The course's tool makes the input for this lesson, instead of an image editor: `comfy cut` copies an image and makes an ellipse transparent, here around the small objects at the front right of the workbench.

```text
comfy cut metronome.png metronome-hole.png 850 860 120 80
metronome-hole.png: 1024 x 1024, 30176 transparent pixels, pixel SHA-256 051cb95373b4342f
```

A mask painted white on black in an image editor has no alpha. [`LoadImageMask`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1815-L1856) reads it with `channel` set to `red`, `green` or `blue`, and uses that channel as it is; with `channel` set to `alpha`, it inverts like `LoadImage`.

## Img2img: denoise

Img2img encodes the image with the VAE and passes that latent to `KSampler` instead of an empty one. `denoise` then decides how much of the image survives. Lesson 2 described sampling as a schedule of noise levels from high to zero. With `denoise` below 1, [`set_steps`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/samplers.py#L1431-L1441) computes a longer schedule and keeps only its end:

```python
new_steps = int(steps/denoise)
sigmas = self.calculate_sigmas(new_steps).to(self.device)
self.sigmas = sigmas[-(steps + 1):]
```

So `denoise` doesn't reduce the work: with 25 steps and `denoise` 0.5, ComfyUI builds a 50-step schedule and runs its last 25 steps, starting from a noise level halfway down. The server's progress bar showed 25 steps for every value, and the times were the same:

| denoise | Time, models loaded |
|---|---|
| 0.3 | 5.13 s |
| 0.5 | 4.63 s |
| 0.7 | 4.68 s |
| 0.9 | 4.88 s |

![Five images side by side. The first is lesson 1's photograph of a brass hourglass-like object on a workbench. The next four are watercolor-like versions: with denoise 0.3 and 0.5 the composition is identical and the style changes; with 0.7 the window and tools start to move; with 0.9 the object is simpler, the tools are different and the window has a new shape.](../../../assets/comfyui/l05-img2img.webp)

*Rendered by ComfyUI v0.36.0: Stable Diffusion XL base 1.0, seed 42, 25 steps, CFG 7, `euler`, `normal`, workflow [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-img2img.api.json) with the prompt "a watercolor painting of a brass metronome on an old wooden workbench, morning light through a window". From left to right: the starting image, then `denoise` 0.3, 0.5, 0.7 and 0.9.*

At 0.3 and 0.5 the sampler starts late enough that only textures and colors change. At 0.9 it starts from almost pure noise, and only the rough layout of light and dark is left.

## Inpainting, three ways

Inpainting repaints the masked part and keeps the rest. ComfyUI has three ways to do it with SDXL, and they don't do the same thing to the masked pixels.

| Workflow | Nodes | What the sampler starts from |
|---|---|---|
| `05-inpaint-vaeencode` | `VAEEncodeForInpaint`, base model | the image with the masked pixels set to mid-gray, `denoise` 1 |
| `05-inpaint-noisemask` | `VAEEncode`, `SetLatentNoiseMask`, base model | the unchanged image, with a noise mask |
| `05-inpaint-model` | `InpaintModelConditioning`, SDXL inpainting UNet | the unchanged image, and the grayed image and mask as extra inputs of the model |

[`VAEEncodeForInpaint`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L412-L450) replaces the masked pixels with gray before encoding, and rounds the mask to 0 or 1:

```python
m = (1.0 - mask.round()).squeeze(1)
for i in range(3):
    pixels[:,:,:,i] -= 0.5
    pixels[:,:,:,i] *= m
    pixels[:,:,:,i] += 0.5
```

Its `grow_mask_by` input only widens the noise mask, not the gray area. Neither the [inpainting tutorial](https://docs.comfy.org/tutorials/basic/inpaint) nor the node's page mentions the gray.

The noise mask is how the sampler keeps the rest of the image. At each step, [`KSamplerX0Inpaint`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/samplers.py#L634-L643) puts the original latent, noised to the current level, outside the mask, and puts it back again in the model's output:

```python
x = x * denoise_mask + self.inner_model.inner_model.scale_latent_inpaint(x=x, sigma=sigma, noise=self.noise, latent_image=self.latent_image, denoise_mask=denoise_mask) * latent_mask
out = self.inner_model(x, sigma, model_options=model_options, seed=seed)
if denoise_mask is not None:
    out = out * denoise_mask + self.latent_image * latent_mask
```

The base model has never been trained to fill a hole: it denoises the whole latent, and the mask throws away what it did outside. The [SD-XL inpainting 0.1](https://huggingface.co/diffusers/stable-diffusion-xl-1.0-inpainting-0.1) model is a UNet trained for it, with "5 additional input channels (4 for the encoded masked-image and 1 for the mask itself)". It is 5.1 GB in fp16, under the CreativeML Open RAIL++-M License like SDXL, and its card says "The model is intended for research purposes only." It has no text encoders or VAE of its own, so the workflow loads it with `UNETLoader` and takes the rest from the SDXL checkpoint. ComfyUI recognizes it from its 9 input channels ([`model_detection.py`, lines 1465 to 1469](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/model_detection.py#L1465-L1469)). [`InpaintModelConditioning`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L453-L502) builds those extra inputs: it grays the masked pixels like `VAEEncodeForInpaint`, encodes that as the extra latent, and returns the encoded **original** image as the latent to sample.

The model card's example sets `strength=0.99`, with the comment "make sure to use `strength` below 1.0", which is `denoise` in ComfyUI.

![Six crops of the front right of the workbench, each 340 by 240 pixels. The original has two small wooden objects. VAEEncodeForInpaint: the objects are gone, and a pale ellipse with a different wood texture shows where the mask was. Noise mask with denoise 1: a flat bluish stripe and a small white blob inside a visible ellipse. Noise mask with denoise 0.8: the two objects are still there, darker and harder, with a dark outline. Inpainting model with denoise 0.99: a brass bell lying on its side and a round wooden piece, in the same light as the rest of the bench.](../../../assets/comfyui/l05-inpaint.webp)

*Rendered by ComfyUI v0.36.0: Stable Diffusion XL base 1.0, and the SD-XL inpainting 0.1 UNet for the last crop; seed 42, 25 steps, CFG 7, `euler`, `normal`, prompt "a small brass bell on an old wooden workbench, morning light through a window, photograph". From left to right: the original, [`05-inpaint-vaeencode`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json), [`05-inpaint-noisemask`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-noisemask.api.json) with `denoise` 1 and 0.8, and [`05-inpaint-model`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json) with `denoise` 0.99. Each crop is the result pasted back into the original.*

- `VAEEncodeForInpaint` erased the objects. The sampler started from a gray patch and painted plain wood, and the mask's edge shows as a change of texture.
- The base model with a noise mask and `denoise` 1 had nothing to go on inside the mask, and painted something that fits neither the prompt nor the bench.
- At `denoise` 0.8, the same workflow kept the shapes of the objects, and only changed their tone.
- The inpainting model is the only one that drew something new, a bell lying on its side, in the light of the scene.

The same workflow with `denoise` 1.0 instead of 0.99 gave nearly the same image: a mean difference of 0.016 levels, and 0.01 % of the pixels by more than 8. The card's warning didn't show on this image.

## Paste the result back

A VAE doesn't give back the pixels it was given. Every workflow above decodes a full 1024 by 1024 image, including the part outside the mask. The course's `compare` command counts only the opaque pixels of a mask image, so it can measure that part:

```text
> comfy compare metronome.png inpaint-model_00001_.png --outside metronome-hole.png
identical pixels: no
compared: 1018400 opaque pixels of the mask
largest difference: 160 of 255, mean 1.888
pixels that differ: 96.34 %, by more than 8: 6.20 %

> comfy compare metronome.png inpaint-model-composite_00001_.png --outside metronome-hole.png
identical pixels: yes
compared: 1018400 opaque pixels of the mask
largest difference: 0 of 255, mean 0.000
pixels that differ: 0.00 %, by more than 8: 0.00 %
```

The decoded image changed 6.2 % of the pixels that nobody asked to repaint, mostly on edges and fine textures. The SD-XL inpainting card warns about it too: "The autoencoding part of the model is lossy." Each workflow therefore ends with [`ImageCompositeMasked`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_mask.py#L80-L104), which takes the decoded pixels inside the mask and the original ones outside. The two SaveImage nodes of each workflow save both versions.

## Outpainting

Outpainting is inpainting on a larger canvas. [`ImagePadForOutpaint`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L2003-L2065) adds a border filled with gray, and returns a mask that is 1 on the border and 0 on the original image. With `feathering`, the mask also rises inside the original, near the added sides, so that the sampler may change a band of the old pixels and the seam doesn't show. It skips feathering when the image is less than twice as wide or high as the feathering width ([line 2044](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L2044)).

![A wide image, 1536 by 1024 pixels reduced: the brass object on its workbench in the middle, with a workshop added on both sides: shelves and a lamp on the left, the window continued and a vise on the right.](../../../assets/comfyui/l05-outpaint.webp)

*Rendered by ComfyUI v0.36.0: SD-XL inpainting 0.1 UNet with the SDXL base 1.0 text encoders and VAE, seed 42, 25 steps, CFG 7, `euler`, `normal`, `denoise` 0.99, workflow [`05-outpaint.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-outpaint.api.json): 256 pixels added on the left and on the right, feathering 40.*

The server took 14.7 seconds for this 1536 by 1024 image, against 8.0 seconds for the same model at 1024 by 1024. The feathered mask is a gradient, and only `InpaintModelConditioning` and `SetLatentNoiseMask` keep it: `VAEEncodeForInpaint` rounds it to 0 or 1, which turns the feathering into a hard edge.

## What CI checks

Uploading and the mask nodes don't need a model. CI makes a 64 by 48 test pattern with a transparent ellipse, uploads it, and runs [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json) on the CPU: the mask of `LoadImage`, `ImagePadForOutpaint`, `ImageCompositeMasked`, and the `Canny` node of lesson 6. It compares the pixel hashes of the other four outputs on Linux, Windows and macOS:

```text
GET /view node 5: ci/padded_00001_.png, 96 x 56, pixel SHA-256 7ecd793c72d18001
GET /view node 7: ci/padded-mask_00001_.png, 96 x 56, pixel SHA-256 85051ce419e3c75f
GET /view node 3: ci/mask_00001_.png, 64 x 48, pixel SHA-256 7d894dc1b0ac1189
GET /view node 10: ci/composite_00001_.png, 64 x 48, pixel SHA-256 8b6753a52c0f4a66
```

Read with Pillow, the mask is 255 inside the ellipse and 0 outside, with a short ramp where `comfy cut` feathered the alpha. The padding is gray 127. Across the left edge of the original image, the padded mask goes 255, 113, 28 and 0, one value every 4 pixels: that is `feathering` 12 at work. The Canny hash is printed but not compared, because it differs from one machine to the next, as lesson 6 explains.

## Key takeaways

- Upload input images with `POST /upload/image`, and use the name the server returns: identical bytes keep the existing name, different bytes get a new one.
- `LoadImage` makes its mask from transparency, as `1 - alpha`. A black-and-white mask without alpha goes through `LoadImageMask` with a color channel.
- `denoise` starts the sampler partway down a longer schedule. It changes how much of the image survives, not how many steps run.
- `VAEEncodeForInpaint` grays the masked pixels and needs `denoise` 1. A noise mask keeps the image under it. An inpainting model, fed by `InpaintModelConditioning`, is the one that paints something new in context.
- The VAE changes pixels everywhere: paste the result back with `ImageCompositeMasked`.

## Your turn

Take a photograph of your own and remove something from it with each of the three routes, on the same mask and the same seed. Compare the results outside the mask with `compare`: the route matters less than knowing which pixels you kept. Then repaint the same area at denoise 0.4, 0.7 and 1, and note where your subject stops being recognisable.

## Exercises

1. With 20 steps and `denoise` 0.4, how many noise levels does `set_steps` compute, how many does it keep, and how many steps run?
2. Render `05-inpaint-vaeencode` with `denoise` 0.5. What do you expect inside the mask, and why?
3. Make a mask with a soft edge, with `comfy cut`'s last argument set to 24 pixels, and run `05-inpaint-model` and `05-inpaint-vaeencode` on it. Which one keeps the soft edge?

<details>
<summary>Solution 1</summary>

`int(20 / 0.4)` is 50, so it computes the schedule for 50 steps, which has 51 noise levels, and keeps the last 21 of them. The sampler runs 20 steps between those 21 levels, starting at the level where step 30 of the 50-step schedule would have been.

</details>

<details>
<summary>Solution 2</summary>

The masked pixels were gray before encoding, and `denoise` 0.5 starts from a level where the image's large shapes are kept. The sampler should therefore keep a gray blob in the mask. The render confirmed it, and more strongly than expected: a flat gray ellipse with only a faint shading, and no wood texture at all. At half the noise range, SDXL treated the gray as part of the picture.

</details>

<details>
<summary>Solution 3</summary>

```text
comfy cut metronome.png metronome-soft.png 850 860 120 80 24
```

`InpaintModelConditioning` passes the mask as it is, so the sampler's noise mask keeps the gradient, and the composite blends across it. `VAEEncodeForInpaint` rounds the mask, so the result has a hard edge where alpha crosses one half.

The renders, seed 42, agree. With the inpainting model, two new wooden objects sit on the bench, and no edge shows even in the decoded image before compositing. With `VAEEncodeForInpaint`, the decoded image has a sharp ellipse of pale, rougher wood, with a dark rim along its top edge.

</details>

## Sources

- ComfyUI documentation: [image to image](https://docs.comfy.org/tutorials/basic/image-to-image), [inpainting](https://docs.comfy.org/tutorials/basic/inpaint), [outpainting](https://docs.comfy.org/tutorials/basic/outpaint), [server routes](https://docs.comfy.org/development/comfyui-server/comms_routes).
- ComfyUI at v0.36.0: [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), [`comfy/samplers.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/samplers.py), [`comfy_extras/nodes_mask.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_mask.py), [`comfy/model_detection.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/model_detection.py), [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py).
- Model card: [SD-XL Inpainting 0.1](https://huggingface.co/diffusers/stable-diffusion-xl-1.0-inpainting-0.1).
