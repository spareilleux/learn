---
title: Playable observatory
description: Explore a Godot 3D prototype built with a Blender model and locally generated ComfyUI textures.
sidebar:
  label: Observatory
  order: 0
---

[Open the 3D observatory](../demos/observatory/) in a desktop browser with WebGL 2. The first load downloads about 51 MB of engine and scene data. Phones and tablets are not supported: this prototype needs a keyboard and mouse.

Click the scene to look around. Move with **WASD** (or **ZQSD**); hold **Shift** to sprint. **Esc** releases the mouse. If your browser does not grant pointer lock, hold the right mouse button and drag to look. Press **1–7** for camera viewpoints, or **F** for free flight, then **E/Space** to rise and **C** to descend. This is an exploratory camera, not yet a collision-aware game controller. Mouse capture was verified in the native build, but its behavior in ordinary Chrome, Edge and Firefox windows still needs testing; please report browser-specific problems.

This prototype contains a Blender-authored, textured steel portal and textures generated locally with ComfyUI. The marble, the grain of the book bindings, the tooled stone, the grime on the steel and three stained-glass panels (sun and moon, an elven tree, an alembic) come from cached SDXL 1.0; the pier ornament comes from SDXL 1.0 with cached ControlNet Union SDXL. Shaders turn them into leather and cloth bindings with raised bands and gilt rules, dressed stone with joints and coffers, brushed steel and backlit stained glass. The balustrade has turned bronze balusters under a walnut handrail.

The source scene's richer desktop rendering uses Godot Forward+ features, including screen-space reflections, indirect light, volumetric fog and glow. The browser build uses Godot's WebGL 2 Compatibility renderer, so those desktop-only effects are reduced or absent: the stained glass throws no shafts of light there, and the books, bronze and steel get simple stand-ins for the missing indirect light. Neither build claims real-time hardware ray tracing; Blender Cycles baked the steel textures, but does not render the interactive scene.

The room is still stylized, especially its central beam, and the lettering on the book spines is decorative glyphs, not readable titles. This is a playable prototype, not a finished photorealistic environment. The [Blender course](../blender/) and [ComfyUI course](../comfyui/) explain the tools behind the asset pipeline.

Credits and notices: [Godot Engine and bundled libraries](../demos/observatory/LICENSES.txt); [SDXL 1.0 model license](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/blob/main/LICENSE.md) (CreativeML Open RAIL++-M); [ControlNet Union SDXL](https://huggingface.co/xinsir/controlnet-union-sdxl-1.0) (Apache-2.0). The generated textures are assets, not redistributed model weights.
