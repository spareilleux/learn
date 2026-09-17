---
title: ComfyUI, de principiante a experto — Misión
description: 'Aprende ComfyUI, la aplicación de nodos para modelos de difusión, desde una primera imagen hasta la producción — el grafo de nodos, la difusión y la reproducibilidad, los workflows en JSON, la API HTTP y WebSocket desde C# y Java, la edición de imágenes, ControlNet, LoRA, los modelos recientes y sus licencias, el escalado y las texturas, el vídeo, los nodos personalizados y su seguridad, y su uso como servicio —, con renders medidos en una GPU y el resto comprobado en CI sin ella.'
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
El código del curso está en [`code/comfyui`](https://github.com/spareilleux/learn/tree/main/code/comfyui): workflows en los dos formatos JSON, una herramienta en C# y un cliente en Java. `check.sh` comprueba lo que funciona sin GPU y sin modelo: valida y convierte los workflows, arranca [ComfyUI](https://github.com/Comfy-Org/ComfyUI) **v0.36.0** con `--cpu`, ejecuta contra él los clientes de C# y Java sobre un workflow que no necesita ningún modelo, y compara cada salida con los archivos de `expected/`. Un workflow de GitHub, `comfyui-examples.yml`, lo ejecuta en Linux, Windows y macOS. Los renders, los tiempos y los hashes de píxeles de las lecciones vienen de una sola máquina: Windows 11, una NVIDIA GeForce RTX 5080 con 16 GB y la versión portable de ComfyUI, en septiembre de 2026. No se midió nada en otra GPU, otro driver u otro sistema operativo, y las lecciones lo dicen donde importa.
:::

## Por qué aprendo esto

Los demás cursos de aprendizaje automático del sitio cargan modelos desde el código: [Candle](../candle/) en Rust, y ONNX Runtime en el [curso de IA de GA](../ga-ai/). ComfyUI va al revés. Es una aplicación en la que conectas modelos en un grafo, en un navegador, y su biblioteca de plantillas abarca imágenes, vídeo, audio y modelos 3D.

Quiero saber cómo funciona bajo el grafo, qué hace reproducible una imagen y cómo un servicio en C# o Java puede usarlo como motor de render: por ejemplo, para generar texturas para este sitio y para GuitarAlchemist, que es el proyecto de la última lección.

## Para quién es este curso

Escribes C# o Java. Conoces HTTP, JSON y el código asíncrono. No necesitas saber Python ni PyTorch, ni cómo funcionan los modelos de difusión: la lección 2 explica lo que hace falta y enlaza a los artículos. Las imágenes de las lecciones se renderizaron en una GPU NVIDIA de 16 GB, y SDXL usó unos 7 GB; cómo caben los modelos posteriores en tarjetas más pequeñas es el tema de la lección 8. Sin GPU, puedes seguir igualmente las lecciones de JSON y de la API con el workflow para CPU que usa la CI.

## Al final de este curso, sabré

- instalar ComfyUI en Windows, Linux o macOS, y ejecutar un grafo de texto a imagen;
- explicar qué hacen las redes del checkpoint, la semilla, los pasos, el CFG, el sampler y el scheduler, y qué hace reproducible un render;
- leer, convertir, validar y comparar workflows en los dos formatos JSON;
- encolar workflows y seguirlos desde C# y Java con la API HTTP y WebSocket;
- editar imágenes con img2img, inpainting y outpainting, y controlarlas con ControlNet y LoRA;
- elegir un modelo reciente para una máquina y un uso, leer su licencia y hacerlo caber en la VRAM con pesos cuantizados;
- escalar imágenes, crear texturas sin costuras y generar vídeos cortos;
- juzgar el código de un nodo personalizado antes de instalarlo;
- ejecutar ComfyUI como servicio detrás de una API propia.

## Plan

| # | Lección | En términos de C# o Java |
|---|---|---|
| 1 | [El grafo de nodos, la instalación y una primera imagen](01-install-first-image/) | un grafo de flujo de datos, como los bloques de TPL Dataflow |
| 2 | [La difusión, y qué hace reproducible una imagen](02-diffusion-reproducibility/) | `new Random(seed)`, y el determinismo en coma flotante |
| 3 | [Los workflows en JSON: el formato de la interfaz, el formato de la API y los diffs](03-workflow-json/) | `System.Text.Json`, Jackson, un esquema |
| 4 | [La API HTTP y WebSocket desde C# y Java](04-http-websocket-api/) | `HttpClient`, `ClientWebSocket`, `java.net.http` |
| 5 | Img2img, inpainting y outpainting | — |
| 6 | ControlNet: poses, bordes y profundidad | — |
| 7 | LoRA: cargarlos, combinarlos y lo que supone entrenar uno | un plugin que modifica los pesos |
| 8 | Los modelos recientes y sus licencias, la cuantización y la VRAM | elegir una dependencia y su licencia |
| 9 | Escalado, texturas sin costuras y HDR | — |
| 10 | Vídeo | — |
| 11 | Los nodos personalizados y su seguridad | paquetes NuGet o Maven que ejecutan código al instalarse |
| 12 | ComfyUI en producción: un servicio, una cola, varias GPU | un worker detrás de una cola de trabajos |
| 13 | Proyecto: texturas para este sitio y para GuitarAlchemist | — |
| — | [Diario](journal/) | |

Las lecciones 5 a 13 son el plan; cambiarán a medida que las primeras me enseñen lo que importa.

## Modelos e imágenes

El curso empieza con [Stable Diffusion XL base 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0), bajo la licencia CreativeML Open RAIL++-M, y añade modelos lección a lección. Cada lección indica la licencia y el tamaño de descarga de cada modelo. No hay ningún archivo de modelo en el repositorio. Cada imagen del curso lleva un pie con su modelo, su semilla y su workflow, y ninguna imagen muestra a una persona real ni una marca.

## Recursos

- [Documentación de ComfyUI](https://docs.comfy.org/), y el [código fuente en v0.36.0](https://github.com/Comfy-Org/ComfyUI/tree/ee71d5c4993f29086b27fde1629a945ae48425bf).
- [Ejemplos de ComfyUI](https://comfyanonymous.github.io/ComfyUI_examples/), del autor original de ComfyUI.
- [Hub de modelos de Hugging Face](https://huggingface.co/models), donde se publican los modelos y sus fichas.
- R. Rombach et al., [High-Resolution Image Synthesis with Latent Diffusion Models](https://arxiv.org/abs/2112.10752), 2021, el artículo en el que se basa Stable Diffusion.
