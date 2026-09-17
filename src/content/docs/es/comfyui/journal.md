---
title: Diario
description: 'Notas de avance fechadas del curso de ComfyUI — ComfyUI v0.36.0 y SDXL base 1.0 fijados, una versión portable ejecutada con su propio directorio base, dos imágenes de una misma semilla, las salidas en el orden de un conjunto y los errores de validación del servidor, tamaños zlib que difieren según el sistema operativo, una CI solo en CPU en tres sistemas operativos, los modelos de las lecciones 5 a 8 y sus licencias, bordes Canny que difieren según la máquina, archivos cuantizados medidos en 16 GB, y puntos por verificar.'
sidebar:
  order: 99
---

## Progreso

- [x] ComfyUI v0.36.0 (commit `ee71d5c`), frontend 1.52.7, SDXL base 1.0 fijado por el hash del archivo
- [x] `check.sh`: comprobaciones de workflows sin conexión, conversión del formato de la interfaz al de la API comparada con la exportación del frontend, los clientes C# y Java contra ComfyUI en la CPU
- [x] CI en Ubuntu, Windows y macOS, sin GPU ni modelo
- [x] Lección 1: el grafo de nodos, la instalación y una primera imagen
- [x] Lección 2: la difusión, y qué hace reproducible una imagen
- [x] Lección 3: los workflows en JSON
- [x] Lección 4: la API HTTP y WebSocket desde C# y Java
- [x] Traducciones al francés y al español de las lecciones 1 a 4
- [x] Lección 5: img2img, inpainting y outpainting
- [x] Lección 6: ControlNet, bordes y profundidad
- [x] Lección 7: LoRA
- [x] Lección 8: modelos recientes, licencias, cuantización y VRAM
- [x] Traducciones al francés y al español de las lecciones 5 a 8
- [ ] Lección 9: escalado, texturas sin costuras y HDR

## 2026-09-16 — Versiones y configuración

- ComfyUI v0.36.0 se publicó la víspera, el 15 de septiembre de 2026, y es la última versión; su etiqueta apunta al commit [`ee71d5c`](https://github.com/Comfy-Org/ComfyUI/commit/ee71d5c4993f29086b27fde1629a945ae48425bf). La versión portable para Windows y NVIDIA ocupa 1.917.442.353 bytes e incluye Python 3.13.14 y PyTorch 2.13.0 para CUDA 13.0.
- El curso reutiliza una versión portable ya instalada en la máquina, y nunca escribe en ella: el servidor arranca con `--base-directory` apuntando a otro sitio, `--models-directory` apuntando a los modelos de la instalación, y `--database-url sqlite:///:memory:`.
- Un directorio base nuevo hizo que el servidor se detuviera al arrancar con `FileNotFoundError`, porque lista `custom_nodes` antes de crear nada. `server.sh` crea la carpeta vacía.
- `sd_xl_base_1.0.safetensors` tiene en la máquina el SHA-256 que indica Hugging Face, `31e35c80…7e5b`.
- Las páginas de primeros pasos y los ejemplos de la API de la documentación usan Stable Diffusion 1.5 a 512 × 512, no SDXL. La página de instalación manual usa conda; `venv` solo aparece en la página de comfy-cli. El tutorial de texto a imagen dice que `EmptyLatentImage` crea un latente de ruido; crea ceros, y es `KSampler` quien crea el ruido.

## 2026-09-16 — Primeros renders

- El primer render de SDXL tardó 14,71 segundos, de los que unos 4 fueron los 25 pasos de muestreo a 6,4 pasos por segundo. Con los modelos cargados, una nueva semilla tardó 4,6 segundos.
- El prompt pedía un metrónomo de latón; la semilla 42 dibujó algo parecido a un reloj de arena. La semilla 43 se acercó más.
- `nvidia-smi` mostró unos 7 GB más en uso durante el render. El log preparó 1.560 MB para los codificadores de texto, 4.896 MB para la UNet y 159 MB para el VAE.
- Las vistas previas del latente de `--preview-method taesd` ralentizaron el muestreo de 6,4 a 4,9 pasos por segundo.

![Un objeto de latón sobre un viejo banco de trabajo de madera, iluminado por el sol de la mañana a través de una ventana polvorienta. Parece más un reloj de arena ornamentado que un metrónomo: un cuerpo de vidrio alto con la cintura estrecha, sujeto en un marco de latón sobre una base redonda.](../../../../assets/comfyui/l01-metronome.webp)

*El primer render. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, semilla 42, 25 pasos, `euler`, `normal`, CFG 7, 1024 × 1024, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json).*

## 2026-09-16 — Una semilla, dos imágenes

- El mismo workflow y la misma semilla dieron `698e7867…` en un servidor recién arrancado, y otra vez tras los reinicios, y `5374ac40…` cada vez que el prompt negativo se volvía a codificar con la UNet ya cargada. Las dos imágenes difieren en una media de 0,92 niveles, y un 2,63 % de los píxeles difieren en más de 8.
- `--disable-dynamic-vram` dio `5374ac40…` también en la primera ejecución. `--deterministic` no cambió ninguno de los dos resultados. No he encontrado qué operación difiere.
- La primera imagen de un lote de dos difería de la imagen única con la misma semilla (media de 0,74), y la segunda imagen del lote no es la de la semilla 43.
- Un render con la semilla 43 hecho por el cliente Java, en otro arranque del servidor 20 minutos después, tenía los mismos píxeles que el primer render con la semilla 43.

![Tres paneles. Los dos primeros son los dos renders con la semilla 42, que a este tamaño parecen iguales. El tercero es una imagen blanca con líneas oscuras donde difieren, amplificadas ocho veces: el contorno del objeto de latón, su vidrio, las herramientas del banco y el marco de la ventana.](../../../../assets/comfyui/l02-cold-warm.webp)

*Las dos imágenes con la semilla 42. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, semilla 42, 25 pasos, `euler`, `normal`, CFG 7, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json). Izquierda: primera ejecución tras arrancar el servidor. Centro: el mismo grafo después de volver a codificar el prompt negativo. Derecha: dónde difieren, amplificado ocho veces.*

## 2026-09-16 — Los formatos JSON y la API

- Cargar el archivo de la API en el frontend y llamar a `app.graphToPrompt()` dio un archivo de la interfaz y una exportación de la API. El conversor en C#, que lee los nombres de los widgets del `input_order` de `/object_info` y se salta el widget de control de la semilla, produce la exportación byte a byte.
- Un PNG encolado desde el navegador registró la semilla 42 en su chunk `workflow`, y el frontend cambió la semilla a 140956311522585 justo después de encolar, porque su widget `control_after_generate` estaba en `randomize`.
- El servidor escribió `"cfg": 7.0` en el prompt del PNG para un frontend que envió `7`: la validación convierte las entradas `FLOAT` con `float()` y las reescribe.
- Un enlace a un nodo inexistente hizo que la validación del servidor lanzara un `KeyError` fuera de su bloque `try`. El servidor informó de dos errores donde la comprobación sin conexión encontró cinco; uno estaba archivado bajo el nodo 3 con el nombre de entrada del nodo 8, `samples`, y una traza que incluye la ruta de instalación del servidor.
- `check.sh` falló en su segunda ejecución: los dos nodos `SaveImage` se ejecutaron en el orden inverso. El servidor guarda las salidas validadas en un conjunto de Python, y los hashes de las cadenas se aleatorizan en cada arranque. `server.sh` fija ahora `PYTHONHASHSEED=0`.
- Una ejecución totalmente en caché sigue enviando `executed` por cada nodo de salida, con los nombres de archivo de la primera ejecución, y no escribe nada.
- La primera ejecución de la CI falló solo en Ubuntu: el mismo PNG de 64 × 48 se comprimió en 84 bytes allí y en 88 en Windows y macOS. `png-info` imprime ahora el tamaño descomprimido.
- El ejemplo de la API en Python del repositorio de ComfyUI espera `executing` con un nodo `null`. El servidor lo envía después de escribir el historial; los clientes se detienen en cambio con `execution_success`, `execution_error` o `execution_interrupted`.
- La documentación no enumera las rutas `/api/jobs`, el prefijo `/api` de todas las rutas ni los mensajes binarios de vista previa.

## 2026-09-16 — Modelos para las lecciones 5 a 8

- El disco de la máquina del curso estaba casi lleno, así que los nuevos archivos de modelos fueron a otra unidad, declarada a ComfyUI con `--extra-model-paths-config`. Cada archivo se descargó de una revisión fijada de Hugging Face y se comprobó con el SHA-256 que indica Hugging Face, y su licencia se leyó en la ficha del modelo en ese momento.
- Pixel Art XL está bajo CreativeML Open RAIL-M, no bajo la RAIL++-M de SDXL. Su ficha dice que no hace falta ninguna palabra de activación, y sus metadatos fijan `instance_prompt: pixel art`.
- Los metadatos del LCM-LoRA dicen rango 1 y alfa 1, y su título `sdxl_LCM_lora_rank1`; sus tensores tienen rango 64 y alfa 8.
- El codificador de texto Qwen3 4B tiene el mismo SHA-256 en los repositorios de Z-Image-Turbo y de FLUX.2 klein de Comfy-Org.

## 2026-09-16 — Img2img, inpainting, ControlNet y LoRA

- `denoise` no cambió el número de pasos: se ejecutaron 25 pasos para cada valor de 0,3 a 0,9, en 4,6 a 5,1 segundos.
- Subir bytes idénticos con un nombre ya usado devolvió el nombre existente; unos bytes distintos recibieron `name (1).png`. Ninguno de los dos comportamientos está documentado.
- `VAEEncodeForInpaint` pone en gris los píxeles enmascarados, cosa que el tutorial no dice. Con `denoise` a 0,5, el resultado fue una elipse gris plana.

![Tres recortes de la parte delantera del banco de trabajo. Primero: una elipse gris plana con un leve sombreado donde estaban los objetos. Segundo: una elipse nítida de madera pálida y áspera, con un borde oscuro a lo largo de su parte superior. Tercero: dos objetos de madera nuevos sobre el banco, sin ningún borde visible.](../../../../assets/comfyui/journal-l05-failures.webp)

*Dos fallos de inpainting y la solución, antes de volver a pegar el resultado. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, semilla 42, 25 pasos, CFG 7, `euler`, `normal`. De izquierda a derecha: [`05-inpaint-vaeencode.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json) con `denoise` 0,5; el mismo workflow con `denoise` 1 y una máscara con un borde suavizado de 24 píxeles; [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json), la UNet SD-XL inpainting 0.1 con `denoise` 0,99, sobre la misma máscara suavizada.*

- La ficha de SD-XL inpainting dice que se mantenga `strength` por debajo de 1,0; 1,0 y 0,99 dieron aquí casi la misma imagen (un 0,01 % de los píxeles difieren en más de 8).
- El resultado de inpainting decodificado cambió en más de 8 niveles un 6,2 % de los píxeles fuera de la máscara; volver a pegarlo con `ImageCompositeMasked` los dejó idénticos.
- La página de documentación de `SetUnionControlNetType` enumera 13 tipos; el nodo tiene 8.
- La primera ejecución en la CI del nodo `Canny` falló en los tres sistemas operativos: cuatro máquinas dieron cuatro hashes de píxeles. Los tres runners encontraron 467 píxeles de borde, y la máquina del autor 464. La CI ahora los imprime a título informativo.

![Líneas de borde blancas sobre fondo negro, dibujadas con píxeles gruesos: un panal de celdas onduladas sacado del patrón de prueba del curso.](../../../../assets/comfyui/journal-canny-ci.webp)

*La salida del nodo `Canny` en la máquina del autor, hash de píxeles `77af5cb1b7e93a5c`, 464 píxeles de borde, ampliada cuatro veces sin suavizado. ComfyUI v0.36.0 en la CPU, sin modelo, umbrales 0,05 y 0,15, workflow [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json). Los tres runners de la CI dibujaron cada uno 467 píxeles de borde, con otros tres hashes.*

- Con `end_percent` a 0,3, el ControlNet guió 8 de los 25 pasos, y la imagen fue casi la misma que con él activo en todos los pasos.
- Un LoRA cuesta tiempo antes del primer paso, no durante el muestreo: cambiar de LoRA tardó de 4 a 5 segundos más, y una imagen de 4 pasos con el LCM-LoRA tardó después 1,16 segundos.

## 2026-09-16 — Modelos recientes y cuantización

- Z-Image-Turbo en bf16 con su codificador de texto bf16, 19,4 GB de pesos, se ejecutó en la GPU de 16 GB con la VRAM dinámica: 63,93 segundos el primer render, y luego 5,93 segundos a 1,5 pasos por segundo. int8 con el codificador de texto fp8 fue a 3,1 pasos por segundo, y nvfp4 a entre 3,7 y 4,1.
- `nvidia-smi` mostró de 12,5 a 15,3 GB en uso en todas las configuraciones: la VRAM dinámica usa lo que está libre. Los tamaños preparados en el log son las cifras útiles.
- Las imágenes int8 se mantuvieron cerca de las de bf16 (entre un 9 y un 15 % de los píxeles difieren en más de 8); las imágenes nvfp4 mostraron la misma escena dispuesta de otra forma (entre un 62 y un 74 %).

![Cuatro renders uno al lado del otro, cada uno un metrónomo piramidal dorado y negro sobre un banco de trabajo de madera gastado delante de una ventana. Los dos primeros son casi iguales; los dos últimos muestran la misma escena con los objetos dispuestos de otra forma.](../../../../assets/comfyui/l08-quantized.webp)

*ComfyUI v0.36.0: Z-Image-Turbo, semilla 42, 8 pasos, CFG 1, `res_multistep`, `simple`, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). De izquierda a derecha: bf16 con el codificador de texto bf16, int8 con fp8, nvfp4 con fp4, nvfp4 con bf16.*

- `qwen_3_4b_fp8_mixed` tiene 12 capas nvfp4, y `qwen_3_4b_fp4_mixed` tiene 58 capas fp8. El archivo nvfp4 de Z-Image mantiene sus cuatro bloques de refinado en bf16.
- Con `--disable-dynamic-vram`, el primer render en bf16 tardó 78,87 segundos y dio los mismos píxeles que con la VRAM dinámica. El segundo render se detuvo cuando la máquina, compartida con otros trabajos, se quedó sin RAM. Un lote bf16 anterior se había detenido del mismo modo: el servidor ocupaba 14,5 GB de RAM. Ahora cada servidor solo arranca cuando los pesos de la configuración, más un margen, caben en la RAM libre.
- FLUX.2 klein 4B dibujó un soporte de latón, no un metrónomo, con las semillas 42, 43 y 44; Z-Image-Turbo dibujó un metrónomo cada vez.

![Cuatro renders uno al lado del otro. Primero, el metrónomo piramidal de Z-Image-Turbo sobre un banco de trabajo. Después, tres renders de un taller polvoriento hechos por FLUX.2 klein 4B, cada uno con un soporte de latón con manivela o brazos sobre un banco gastado en lugar de un metrónomo.](../../../../assets/comfyui/l08-z-image-klein.webp)

*ComfyUI v0.36.0. Primero: Z-Image-Turbo bf16, semilla 43, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). Después: FLUX.2 klein 4B, semillas 42, 43 y 44, 4 pasos, CFG 1, `euler`, workflow [`08-flux2-klein.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-flux2-klein.api.json).*

## Por verificar

- SDXL en Linux con CUDA, y en Apple Silicon con MPS: la máquina con GPU del curso usa Windows; la CI solo instala las builds para CPU.
- Qué operación hace que los codificadores de texto den resultados distintos según la UNet esté cargada o no, y si ocurre con otras GPU u otros drivers.
- Si un sampler ancestral da la misma imagen en la CPU y en la GPU para una semilla: el ruido de sus pasos se genera en el dispositivo.
- Si un hash perceptual sería estable en los casos de la lección 2.
- Las cadenas de ControlNet, `start_percent`, y el paso exacto en que cae el nivel de ruido de un porcentaje, que la lección calculó pero no renderizó.
- El `canny` de Kornia: qué paso hace que los bordes difieran entre máquinas.
- Entrenar un LoRA con los nodos experimentales de ComfyUI, y cuánto de los 16 GB necesita para SDXL.
- Varios LoRA apilados en el otro orden: la misma imagen, y el mismo hash de píxeles o no.
- La ruta emulada de nvfp4 y fp8 en una GPU sin sus kernels; la máquina del curso solo tiene una GPU de la serie RTX 50.
- Por qué la red nvfp4 de Z-Image muestreaba más rápido con el codificador de texto bf16 que con el fp4.
- Qué hace la opción `convrot` de int8 en los kernels de comfy-kitchen.
- Los tiempos de render en caliente con `--disable-dynamic-vram`, en una máquina con suficiente RAM libre.
- `execution_error` y `execution_interrupted` tal como los imprimen los clientes, `POST /interrupt` con un id de prompt, y borrar un prompt encolado: ninguna ejecución los ha producido todavía.
