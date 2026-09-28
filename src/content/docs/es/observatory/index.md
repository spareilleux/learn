---
title: Observatorio interactivo
description: Explora un prototipo 3D de Godot con un modelo de Blender y texturas generadas localmente con ComfyUI.
sidebar:
  label: Observatorio
  order: 0
---

[Abrir el observatorio 3D](../../demos/observatory/) en un navegador de escritorio compatible con WebGL 2. La primera carga descarga aproximadamente 47 MB de motor y escena. No se admiten teléfonos ni tabletas: se necesita un teclado y un ratón.

Haz clic en la escena para mirar alrededor. Muévete con **WASD** o **ZQSD**; mantén **Shift** para correr. **Esc** libera el ratón. Si el navegador no permite capturar el puntero, mantén pulsado el botón derecho y arrastra para mirar. Las teclas **1–7** cambian el punto de vista; **F** activa el vuelo libre, **E/Espacio** sube y **C** baja. La cámara permite explorar, pero aún no hay un personaje con colisiones. La captura del ratón se verificó en la versión nativa; su comportamiento en una ventana normal de Chrome, Edge o Firefox aún debe probarse. Comunica cualquier problema específico del navegador.

El prototipo incluye un portal de acero texturizado creado en Blender y dos texturas generadas localmente con ComfyUI: mármol con el modelo SDXL 1.0 ya almacenado, y un ornamento de pilar con SDXL 1.0 y ControlNet Union SDXL. El renderizado nativo más rico usa Godot Forward+: reflejos en pantalla, iluminación indirecta y resplandor. La versión web usa el renderizador Compatibility de WebGL 2, donde algunos efectos nativos se reducen o no están disponibles. Ninguna versión afirma usar trazado de rayos por hardware en tiempo real: Blender Cycles horneó las texturas de acero, pero no renderiza la escena interactiva.

La sala sigue siendo estilizada, sobre todo los libros y el haz central. Es un prototipo jugable, no un entorno fotorrealista terminado. Los cursos de [Blender](../blender/) y [ComfyUI](../comfyui/) explican las herramientas de creación de assets.

Créditos y licencias: [Godot Engine y bibliotecas incluidas](../../demos/observatory/LICENSES.txt); [licencia del modelo SDXL 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/blob/main/LICENSE.md) (CreativeML Open RAIL++-M); [ControlNet Union SDXL](https://huggingface.co/xinsir/controlnet-union-sdxl-1.0) (Apache-2.0). Las texturas generadas son assets, no una redistribución de los pesos de los modelos.
