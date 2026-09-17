---
title: Diario
description: 'Notas de avance fechadas del curso de ComfyUI — ComfyUI v0.36.0 y SDXL base 1.0 fijados, una versión portable ejecutada con su propio directorio base, dos imágenes de una misma semilla, las salidas en el orden de un conjunto y los errores de validación del servidor, tamaños zlib que difieren según el sistema operativo, una CI solo en CPU en tres sistemas operativos, y puntos por verificar.'
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
- [x] Traducciones al francés y al español
- [ ] Lección 5: img2img, inpainting y outpainting

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

## 2026-09-16 — Una semilla, dos imágenes

- El mismo workflow y la misma semilla dieron `698e7867…` en un servidor recién arrancado, y otra vez tras los reinicios, y `5374ac40…` cada vez que el prompt negativo se volvía a codificar con la UNet ya cargada. Las dos imágenes difieren en una media de 0,92 niveles, y un 2,63 % de los píxeles difieren en más de 8.
- `--disable-dynamic-vram` dio `5374ac40…` también en la primera ejecución. `--deterministic` no cambió ninguno de los dos resultados. No he encontrado qué operación difiere.
- La primera imagen de un lote de dos difería de la imagen única con la misma semilla (media de 0,74), y la segunda imagen del lote no es la de la semilla 43.
- Un render con la semilla 43 hecho por el cliente Java, en otro arranque del servidor 20 minutos después, tenía los mismos píxeles que el primer render con la semilla 43.

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

## Por verificar

- SDXL en Linux con CUDA, y en Apple Silicon con MPS: la máquina con GPU del curso usa Windows; la CI solo instala las builds para CPU.
- Qué operación hace que los codificadores de texto den resultados distintos según la UNet esté cargada o no, y si ocurre con otras GPU u otros drivers.
- Si un sampler ancestral da la misma imagen en la CPU y en la GPU para una semilla: el ruido de sus pasos se genera en el dispositivo.
- Si un hash perceptual sería estable en los casos de la lección 2.
- `execution_error` y `execution_interrupted` tal como los imprimen los clientes, `POST /interrupt` con un id de prompt, y borrar un prompt encolado: ninguna ejecución los ha producido todavía.
