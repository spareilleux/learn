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
- [x] Lección 9: escalado, texturas sin costuras y HDR
- [ ] Lección 10: vídeo
- [x] Lección 11: los nodos personalizados y su seguridad
- [x] Lección 12: ComfyUI en producción
- [x] Lección 15: audio, leído en el código fuente
- [x] Una sección «tu turno» en cada lección escrita, y una galería de las treinta imágenes
- [ ] Lección 13: texturas para este sitio y para GuitarAlchemist
- [ ] Lección 14: el laboratorio Guitar Alchemist

## QA

Lo que este curso encontró en ComfyUI v0.36.0, en su documentación y en los archivos que carga, ejecutándolos en lugar de leer lo que se dice de ellos. Los enlaces de código apuntan a [`ee71d5c`](https://github.com/Comfy-Org/ComfyUI/tree/ee71d5c4993f29086b27fde1629a945ae48425bf), el commit que el curso fija. Ninguno de estos puntos es todavía un informe de error: es lo que mostraron las mediciones.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| Una carpeta base nueva arranca el servidor | El arranque se detiene con `FileNotFoundError`: el servidor lista `custom_nodes` en la carpeta nueva antes de que nada la cree | `--base-directory` | Reproducido en cada carpeta base nueva | Reproducido; [`server.sh`](https://github.com/spareilleux/learn/blob/main/code/comfyui/server.sh) crea primero la carpeta vacía |
| `--base-directory` no toca la instalación | Migró la base `user/comfyui.db` heredada de la instalación, dejó un `.bak` al lado y copió la base en la carpeta de prueba | `--base-directory` sin `--database-url` | El original se restauró desde la copia; ambos SHA-256 coincidían | Reproducido; se evita con `--database-url sqlite:///:memory:` ([Verificación de ComfyUI para la escena orbital](#2026-09-19--verificación-de-comfyui-para-la-escena-orbital)) |
| El tutorial de inicio describe `EmptyLatentImage` | Dice que el nodo crea un latente de ruido. El nodo crea ceros, y es `KSampler` quien hace el ruido | [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), frente al [tutorial de texto a imagen](https://docs.comfy.org/get_started/first_generation) | Leído en el código del nodo en el commit fijado | Reproducido. La documentación es falsa, el comportamiento es correcto |
| El mismo grafo y la misma semilla dan los mismos píxeles | La imagen cambia cuando la indicación negativa se vuelve a codificar con la UNet ya cargada | [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), `CLIPTextEncode` y `KSampler` | `698e7867…` en un servidor recién arrancado, `5374ac40…` en caliente: 0,92 niveles de diferencia media, 2,63 % de los píxeles por encima de 8. `--deterministic` no cambió nada | Reproducido. La operación responsable sigue sin identificarse ([Una semilla, dos imágenes](#2026-09-16--una-semilla-dos-imágenes)) |
| Una imagen dentro de un lote es igual a esa semilla renderizada sola | La primera imagen del lote difiere del render suelto | [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), `EmptyLatentImage` y `KSampler` | 0,74 niveles de diferencia media | Reproducido |
| La validación enumera todos los problemas de un prompt | Un enlace a un nodo que no existe lanza un `KeyError` fuera del bloque `try`, y el servidor responde con una traza que lleva su ruta de instalación | [`execution.py:932-933`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L932-L933) | El servidor informó de 2 errores donde la comprobación sin conexión encontró 5; uno estaba archivado bajo el nodo 3 con el nombre de entrada del nodo 8, `samples` | Reproducido |
| El PNG registra lo que el cliente envió | La validación convierte cada entrada `FLOAT` con `float()` y reescribe el valor en el prompt que se guarda | [`execution.py:995-997`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L995-L997) | El frontend envió `7` para `cfg`; el prompt escrito en el PNG contiene `"cfg": 7.0` | Reproducido. Sin efecto en la imagen, y suficiente para romper una comparación byte a byte de dos prompts |
| Los nodos de salida se ejecutan en un orden estable | Las salidas validadas se guardan en un conjunto de Python, cuyo orden de recorrido sigue al hash de cadenas aleatorizado | [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py) | `check.sh` falló en su segunda ejecución: los dos `SaveImage` se ejecutaron en el otro orden | Reproducido; resuelto en el curso con `PYTHONHASHSEED=0` |
| `POST /upload/image` tiene un comportamiento documentado | Bytes idénticos conservan el nombre existente; bytes distintos reciben `name (1).png` | [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py) | Ambos casos observados; ninguno está documentado | Reproducido. La documentación calla |
| La página de `SetUnionControlNetType` enumera los tipos que el nodo tiene | La página enumera 13 tipos, el nodo tiene 8 | [`nodes_controlnet.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_controlnet.py), frente a su [documentación](https://docs.comfy.org/built-in-nodes/SetUnionControlNetType) | Los 8 nombres se leyeron en el código del nodo | Reproducido. Tomar los nombres del código |
| Los metadatos de un LoRA describen sus tensores | Los metadatos del LCM-LoRA y su título dicen rango 1 y alfa 1 | `sdxl_LCM_lora_rank1.safetensors` | Sus tensores dan rango 64 y alfa 8 | Reproducido. Los metadatos del archivo son falsos; leer los tensores ([Modelos para las lecciones 5 a 8](#2026-09-16--modelos-para-las-lecciones-5-a-8)) |
| El nombre de un archivo cuantizado dice lo que contiene | `qwen_3_4b_fp8_mixed` contiene 12 capas nvfp4, y `qwen_3_4b_fp4_mixed` contiene 58 capas fp8 | Los codificadores de texto Z-Image-Turbo de Comfy-Org | Contadas en las cabeceras | Reproducido. «mixed» es el aviso: leer la cabecera |
| `nvidia-smi` muestra lo que un modelo necesita | La VRAM dinámica toma lo que está libre, así que la cifra no dice nada del modelo | `--disable-dynamic-vram` y las líneas de puesta en escena del registro | De 12,5 a 15,3 GB en uso en todas las configuraciones, desde 19,4 GB de pesos bf16 hasta nvfp4 | Reproducido. Los tamaños puestos en escena en el registro son las cifras útiles |
| La documentación de la API enumera las rutas que sirve el servidor | Faltan las rutas `/api/jobs`, el prefijo `/api` en todas las rutas y los mensajes binarios de vista previa | [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py) | Leído en la tabla de rutas en el commit fijado | Reproducido. La documentación está incompleta |
| `execution_success` significa que el render puede leerse en `/history` | Se envía antes de que se escriba el historial. El mismo `prompt_id` enviado dos veces se ejecuta dos veces y sobrescribe su entrada, y una reconexión no reproduce nada | [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py), [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py) | Cada caso se provocó en un servidor de CPU y se registraron sus respuestas | Reproducido; tratado en el worker del curso ([ComfyUI en producción](#2026-09-16--comfyui-en-producción)) |
| `LoadImage` enumera los archivos que el servidor sabe leer | Enumera aquellos cuyo tipo MIME empieza por `image`, y esa tabla pertenece a la máquina, no a ComfyUI | [`folder_paths.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/folder_paths.py#L229-L253) | `.exr` no tiene ningún tipo MIME en esta máquina Windows ni en el ejecutor `macos-latest`, y vale `image/aces` en `ubuntu-latest`, todas con Python 3.13 | Reproducido en tres máquinas por [`data/mime-info.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/mime-info.py). Un EXR escrito por `SaveImageAdvanced` no puede tomarse de la lista en dos de las tres |
| La licencia de un reempaquetado cubre los archivos que entrega | [Comfy-Org/TRELLIS.2](https://huggingface.co/Comfy-Org/TRELLIS.2) está etiquetado MIT y entrega `clip_vision/dino_v3_vit_l.safetensors`, que está bajo la licencia DINOv3, sin una copia de esa licencia | El árbol de archivos del repositorio | Leído en la ficha del modelo y en el árbol | Reproducido. Un reempaquetado no cambia la licencia de un archivo. Esto no es asesoramiento legal |
| La licencia de un modelo rige lo que se hace con los pesos | La [licencia Hunyuan 3D 2.0](https://huggingface.co/tencent/Hunyuan3D-2/blob/9cd649ba6913f7a852e3286bad86bfa9a2d83dcf/LICENSE) restringe además dónde pueden mostrarse sus salidas: cláusula 5.c, Territorio que excluye la Unión Europea, el Reino Unido y Corea del Sur | Cláusulas 1.l y 5.c, leídas en el commit `9cd649ba` | Dos renders ya se habían publicado en este sitio, y fueron retirados | Reproducido. El curso no publica ninguna salida de Hunyuan3D ([Un modelo 3D publicado antes de leer su licencia](#2026-09-17--un-modelo-3d-publicado-antes-de-leer-su-licencia)) |

## Experimentos

Una fila por experimento medido. La columna de hipótesis dice qué se predijo **antes** de que el número existiera; donde el curso midió primero y entendió después, lo dice, en lugar de inventar una predicción que ya conocería la respuesta.

| Pregunta | Hipótesis | Resultado medido | Veredicto | Pruebas |
|---|---|---|---|---|
| ¿Un `denoise` menor que 1 acorta el render? | No escrita de antemano. Lo que se ponía a prueba es la lectura que invita la palabra: menos pasos para menos eliminación de ruido | Los 25 pasos se ejecutaron con todos los valores de 0,3 a 0,9, en 4,6 a 5,1 s | Refutada: `denoise` arranca el muestreador a mitad de un calendario de la misma longitud | [Img2img, inpainting, ControlNet y LoRA](#2026-09-16--img2img-inpainting-controlnet-y-lora), [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/05-img2img.api.json) |
| ¿Las dos imágenes de la semilla 42 vienen de la puesta en escena de la VRAM dinámica? | Escrita antes del render: desactivar la VRAM dinámica debería devolver los píxeles del arranque en frío | `--disable-dynamic-vram` dio la huella en caliente `5374ac40…` ya en la primera ejecución, y los mismos píxeles que con VRAM dinámica, en 78,87 s frente a 63,93 | No concluyente: la hipótesis falló y la operación responsable sigue siendo desconocida | [Una semilla, dos imágenes](#2026-09-16--una-semilla-dos-imágenes), [Modelos recientes y cuantización](#2026-09-16--modelos-recientes-y-cuantización) |
| ¿El modelo de inpainting de SD-XL exige un `strength` menor que 1,0, como dice su ficha? | La instrucción de la ficha hacía las veces de predicción | 1,0 y 0,99 difieren en el 0,01 % de los píxeles en más de 8 niveles | Refutada en esta imagen; una imagen no es una respuesta general | [Img2img, inpainting, ControlNet y LoRA](#2026-09-16--img2img-inpainting-controlnet-y-lora), [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/05-inpaint-model.api.json) |
| ¿Qué cuesta la cuantización en imagen y qué aporta en velocidad? | No escrita de antemano | int8 con el codificador fp8: del 9 al 15 % de los píxeles difieren de bf16 en más de 8, a 3,1 pasos por segundo frente a 1,5. nvfp4 con fp4: del 62 al 74 %, a 3,7-4,1 | Confirmada para int8, refutada para nvfp4: no es una imagen degradada sino otra disposición de la misma escena | [Modelos recientes y cuantización](#2026-09-16--modelos-recientes-y-cuantización), [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/08-z-image-turbo.api.json) |
| ¿Sigue haciendo falta un ControlNet después de los primeros pasos? | Escrita en la lección antes del render: la disposición se decide pronto, así que `end_percent` a 0,3 debería conservar la composición | El ControlNet guió 8 de los 25 pasos, y la imagen fue casi la misma que con él activo todo el tiempo | Confirmada | [Img2img, inpainting, ControlNet y LoRA](#2026-09-16--img2img-inpainting-controlnet-y-lora), [`06-canny.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/06-canny.api.json) |
| ¿Un LoRA ralentiza el muestreo? | No escrita de antemano. La suposición que se pone a prueba es que unos pesos añadidos cuestan tiempo en cada paso | Cambiar de LoRA costó de 4 a 5 s antes del primer paso; una imagen LCM-LoRA de 4 pasos tardó después 1,16 s | Refutada: el parche se calcula una vez, al cargar el modelo | [Img2img, inpainting, ControlNet y LoRA](#2026-09-16--img2img-inpainting-controlnet-y-lora), [`07-lcm.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/07-lcm.api.json) |
| ¿Una cruz más ancha elimina la costura de una textura desplazada y repintada? | Escrita tras el primer fracaso y antes del segundo render: 384 píxeles de cruz, 128 de difuminado y denoise 1 deberían cerrarla | La cruz de 160 píxeles redujo la costura a la mitad, de 13,4 a 5,2 niveles en la fila central, pero dejó una línea moteada y un salto de tono. La cruz ancha eliminó la línea; el salto de tono se quedó | Confirmada, con una reserva: la costura desapareció, la diferencia de tono entre las mitades no | [Escalado, texturas sin costuras y HDR](#2026-09-16--escalado-texturas-sin-costuras-y-hdr), [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/09-seamless.api.json) |
| ¿Un PNG de 16 bits o un EXR de un render son de verdad HDR? | No escrita de antemano. La expectativa que se pone a prueba es que un contenedor más amplio lleva más | 256 niveles por canal en el PNG de 16 bits de un render de 8 bits, y ningún valor por encima de 1,0 en el EXR: el VAE acota su salida entre 0 y 1 | Refutada: el contenedor es HDR, el contenido no | [Escalado, texturas sin costuras y HDR](#2026-09-16--escalado-texturas-sin-costuras-y-hdr), [`09-exr.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/09-exr.api.json) |
| ¿El decodificado VAE por baldosas cambia la imagen? | No escrita de antemano | 0,93 niveles de diferencia media a 2048 × 2048, donde un decodificado simple también cabía en la GPU | Confirmada: pequeña, y no nula — decodificar de forma simple cuando cabe | [Escalado, texturas sin costuras y HDR](#2026-09-16--escalado-texturas-sin-costuras-y-hdr), [`09-hires-fix.api.json`](https://github.com/spareilleux/learn/blob/main/code/comfyui/workflows/09-hires-fix.api.json) |
| ¿La salida del nodo `Canny` es comparable entre máquinas? | Escrita antes de pasar por CI: un filtro de bordes con salida de aspecto entero debería dar los mismos píxeles en todas partes | Cuatro máquinas dieron cuatro huellas de píxeles; los tres ejecutores de CI encontraron 467 píxeles de borde, la máquina del autor 464 | Refutada: es código en coma flotante. La CI imprime los números a título informativo en lugar de compararlos | [Img2img, inpainting, ControlNet y LoRA](#2026-09-16--img2img-inpainting-controlnet-y-lora), [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/comfyui/check.sh) |
| ¿En qué paso del `canny` de Kornia dejan de coincidir las máquinas? | No escrita de antemano: la lección pedía el paso sin nombrar ninguno | La entrada es idéntica en cuatro máquinas; el desenfoque gaussiano separa tres grupos, el gradiente espacial las cuatro, todas las magnitudes difieren, y los contornos umbralizados son idénticos, 1461 píxeles de 3072 | Respondida, en dos mitades: la divergencia empieza en la primera convolución y siempre está ahí; solo llega a la salida cuando hay píxeles cerca de un umbral | [`data/canny-steps.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/canny-steps.py), [lección 6](../06-controlnet/#en-qué-paso-dejan-de-coincidir) |
| ¿Qué hace el indicador `convrot` de un checkpoint int8? | Escrita en la lección 8 antes de leer el kernel: una rotación de grupos de pesos antes de cuantizar, para repartir los valores grandes y que una sola escala se ajuste mejor | comfy-kitchen 0.2.34 rota cada grupo de 256 canales de entrada con una matriz de Hadamard regular, simétrica y ortogonal: el peso fuera de línea, las activaciones en línea. Sobre un peso con un valor atípico por fila, el error de ida y vuelta int8 es del 5,7 % sin rotación y del 0,76 % con ella | Confirmada, con una cifra. Al ser su propia inversa, la matriz deja el producto intacto; solo cambia lo que el int8 tiene que contener | [`data/convrot.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/convrot.py), [lección 8](../08-recent-models-quantization/) |

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

## 2026-09-16 — Los nodos personalizados y su seguridad

- ComfyUI v0.36.0 importa cada paquete con `exec_module` antes de leer `NODE_CLASS_MAPPINGS`; `prestartup_script.py` se ejecuta antes, y el JavaScript de `WEB_DIRECTORY` se ejecuta en el navegador. `hook_breaker_ac10a0.py` restaura una función después de cargar los paquetes; nada más separa un paquete del proceso.
- ComfyUI-Manager es ahora el paquete pip `comfyui_manager==4.2.2`, fijado en `manager_requirements.txt`. Los 42 archivos `.py`, `.json` y `.md` de su wheel en PyPI son idénticos a la etiqueta `4.2.2`, commit `bd4ede22`. Filtra las instalaciones según el nivel de seguridad, la dirección de escucha y dos nuevas opciones, y busca al arrancar nombres de paquetes maliciosos conocidos; nada lee el código de un paquete.
- El paquete de Guitar Alchemist (GA Chord Diagram, GA Fretboard Control Map, GA Scale Prompt) calcula a partir de las tablas de afinación y de escalas de GA en el commit `a826864f`, dibuja con Pillow sin fuentes, y pasa 14 pruebas unitarias solo con NumPy y Pillow. Cargado en un directorio base desechable, con el Python de la versión portable, en la CPU, se importó en 0,0 s, se ejecutó en 0,06 s, y `SaveImage` escribió los mismos píxeles que el PNG esperado de la prueba. `--disable-all-custom-nodes`, `--whitelist-custom-nodes ga` y una carpeta `.disabled` se comportaron como dice el código fuente.
- El script de auditoría se ejecutó sobre seis paquetes fijados el 16 de septiembre de 2026: ComfyUI-GGUF, comfyui_controlnet_aux, ComfyUI-Impact-Pack, ComfyUI-VideoHelperSuite, rgthree-comfy y ComfyUI_essentials. Ningún hallazgo sugiere mala intención. Impact-Pack instala `onnxruntime` con pip la primera vez que se ejecuta un detector ONNX, y su `install.py` descarga un `.pth` de SAM. rgthree-comfy envía el SHA-256 de un archivo de modelo a Civitai cuando la interfaz pide su información. comfyui_controlnet_aux tiene 72 llamadas a `torch.load` sin `weights_only`, seguras por defecto solo con PyTorch 2.6 o posterior.
- Un pickle cuya carga llama a `print` se ejecutó con `pickle.loads` y con `torch.load(weights_only=False)`; `torch.load(weights_only=True)` lo rechazó con PyTorch 2.13.

## 2026-09-16 — ComfyUI en producción

- Leído en ComfyUI v0.36.0: un único hilo `prompt_worker` ejecuta un prompt a la vez; un cliente puede elegir un `prompt_id`, que debe ser un UUID en minúsculas; el mismo identificador enviado dos veces se ejecuta dos veces y sobrescribe su entrada de historial; `execution_success` se envía antes de escribir el historial; `execution_interrupted` se difunde a todos; una reconexión no reproduce nada. Un script de grabación provocó estos casos en un servidor CPU y guardó las respuestas.
- Un worker en C# y en Java con las mismas líneas de log: una cola en memoria (un `Channel` en C#, una `LinkedBlockingQueue` e hilos virtuales en Java) o RabbitMQ, el identificador del job como `prompt_id`, un archivo de reserva y `done.json` para la idempotencia, backoff exponencial con full jitter, los 400 y los errores de ejecución normales a las cartas muertas, las faltas de memoria y los 5xx reintentados, una interrupción al vencer el plazo, un pool de GPU que elige el servidor con menos prompts delante, y la gestión de SIGTERM con un periodo de gracia.
- Un ComfyUI falso en ASP.NET Core reproduce las respuestas grabadas según un guion de fallos. Pasan 11 pruebas de xUnit y 9 de JUnit, y los dos workers imprimen las mismas transcripciones en Windows, Linux y macOS en la CI. Contra un ComfyUI real en CPU, el worker de C# ejecutó cuatro jobs (un duplicado, una carta muerta), y el de Java, en el mismo servidor, encontró los prompts terminados en el historial sin volver a ejecutarlos.
- La primera ejecución de la CI se bloqueó en Linux y macOS: los servidores falsos sobrevivían a `kill`. Ahora esperan SIGTERM con `PosixSignalRegistration`.
- El experimento «del acorde al mástil» del laboratorio GA se ejecuta como veinte jobs con un CSV de resultados contra el servidor falso. Los adaptadores de RabbitMQ, las notas de despliegue y una ejecución en GPU siguen por verificar.

## 2026-09-16 — Modelos para las lecciones 9 y 10

- Descargados en el disco de modelos y comprobados con el SHA-256 de la API de árbol de Hugging Face: `RealESRGAN_x4plus.safetensors` (66.857.836 bytes, BSD-3-Clause), `film_net_fp16.safetensors` (68.882.302 bytes), y para Wan 2.2 TI2V 5B, bajo Apache 2.0, `wan2.2_ti2v_5B_fp16.safetensors` (9.999.658.848 bytes), `umt5_xxl_fp8_e4m3fn_scaled.safetensors` (6.735.906.897 bytes) y `wan2.2_vae.safetensors` (1.409.400.960 bytes). Los 18,1 GB de Wan tardaron 10 minutos.
- El reempaquetado de Comfy-Org no tiene ningún archivo fp8 de TI2V 5B, solo fp16.

## 2026-09-16 — Escalado, texturas sin costuras y HDR

- La regla de la RAM eligió el modelo en cada arranque del servidor: Z-Image-Turbo nvfp4 con 22 GB de RAM libre, int8 con 24 GB. La RAM libre bajó a 9 GB durante los renders int8.
- Un paso de muestreo tardó unos 0,3 segundos a 1024 × 1024 y de 2,2 a 2,8 segundos a 2048 × 2048.
- Un `VAEDecode` normal del latente de 2048 × 2048 cupo en la GPU; su imagen difiere de la de `VAEDecodeTiled` en 0,93 niveles de media.
- El escalado en el espacio latente dejó un grano ruidoso y cuerdas duplicadas con un denoise de 0,3.
- El PNG de 16 bits de `SaveImageAdvanced` hecho a partir de un render de 8 bits tiene 256 niveles por canal, y su EXR no tiene ningún valor por encima de 1,0. El cliente de C# se detenía en el primer PNG de 16 bits: ahora los decodifica, y lista los archivos EXR y AVIF por tamaño.
- El primer intento de textura sin costuras, con una cruz de 160 píxeles, 64 píxeles de difuminado y un denoise de 0,7, redujo las costuras a la mitad (de 13,4 a 5,2 niveles en la fila central) pero dejó una línea moteada y un escalón de tono. Un denoise de 0,9 no ayudó; una cruz de 384 píxeles con 128 píxeles de difuminado, sí.
- "Pale maple" (arce claro) dibujó hojas de arce talladas en la madera. "Pale maple wood, a planed board" (madera de arce clara, una tabla cepillada) dibujó una tabla.

![Tres paneles. Una repetición 2 × 2 de una textura de palisandro, con líneas horizontales y verticales tenues a través de cada mosaico. Un recorte del centro de esa textura, donde una fila de motas oscuras cruza la veta y la mitad inferior es más clara. Una repetición 2 × 2 de una madera clara con una gran hoja de arce tallada en cada mosaico.](../../../../assets/comfyui/journal-l09-seamless-failures.webp)

*Los fallos, antes de la corrección. ComfyUI v0.36.0: Z-Image-Turbo nvfp4 con Qwen3 4B fp4 mixed, semilla 42, 8 pasos, CFG 1, `res_multistep`, `simple`, workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json) con su cruz ajustada a 160 píxeles, 64 de difuminado y un denoise de 0,7. De izquierda a derecha: el palisandro repetido 2 × 2; los 512 × 512 píxeles centrales del palisandro; el prompt "flat top-down photograph of pale maple, subtle straight grain, even soft lighting, no shadows, wood texture" (foto cenital de arce claro, con veta fina y recta, luz suave y uniforme, sin sombras, textura de madera), repetido 2 × 2.*

## 2026-09-17 — Un modelo 3D publicado antes de leer su licencia

- El 16 de septiembre, la sesión Atlas generó un metrónomo y un gramófono como mallas 3D, a partir de imágenes de SDXL, con Hunyuan3D 2.0 y los nodos del núcleo de ComfyUI. El diario del curso de Blender publicó sus renders a las 00:23 del 17 de septiembre, en el commit `a165915`.
- Al leer la licencia para el experimento de imagen a 3D del laboratorio GA, la sesión learn-33 encontró la cláusula 5.c de la [Tencent Hunyuan 3D 2.0 Community License](https://huggingface.co/tencent/Hunyuan3D-2/blob/9cd649ba6913f7a852e3286bad86bfa9a2d83dcf/LICENSE): «You must not use, reproduce, modify, distribute, or display the Tencent Hunyuan 3D 2.0 Works, Output or results of the Tencent Hunyuan 3D 2.0 Works outside the Territory. Any such use outside the Territory is unlicensed and unauthorized under this Agreement.» El Territorio excluye la Unión Europea, el Reino Unido y Corea del Sur, y este sitio es público. Nuestro error: los renders se publicaron antes de que nadie leyera la cláusula 5.c.
- A las 00:44, el usuario decidió: Hunyuan3D se queda en la máquina local, y todo lo que se publique usa TRELLIS.2 (MIT, con DINOv3 bajo su propia licencia) o modelos construidos con código. El curso de Blender retiró los dos renders en el commit `c8a5a33` y describe con palabras lo que mostraban.
- TRELLIS.2 pide aquí unos 23 GB de RAM libre, y el proyecto original pide 24 GB de VRAM; no se ha ejecutado. Los dos objetos se están remodelando con `bpy` en su lugar: el diario de Blender cuenta ese lado de la historia, [antes](../../blender/journal/#2026-09-17--modelos-generados-en-comfyui-limpiados-en-blender) y [después](../../blender/journal/#2026-09-22--modelar-en-bpy-frente-a-imagen3d).
- La lección 8 tiene ahora una sección sobre [leer la licencia antes de publicar una salida](../08-recent-models-quantization/#leer-la-licencia-antes-de-publicar-una-salida), con las cláusulas y la comparación de las tres rutas. Ninguna imagen de Hunyuan3D aparece en este curso.

## 2026-09-19 — Verificación de ComfyUI para la escena orbital

Un servidor CPU separado (0.36.0, localhost:8193) confirmó las clases de nodos del workflow Canny del curso, el checkpoint SDXL y el ControlNet union instalados. No se envió ningún prompt; inferencia GPU: 0 s. Después se detuvo el servidor. Efecto inesperado: `--base-directory` por sí solo movió el antiguo `user/comfyui.db` de la instalación a un `.bak` y lo copió al directorio de prueba. Se restauró el archivo original desde esa copia sin sobrescribir otro archivo; ambos SHA-256 coinciden. Se conservó la copia. Las próximas pruebas aisladas deben indicar `--database-url sqlite:///:memory:` o una URL de base exclusiva de la prueba. La inferencia y la calidad de imagen siguen por verificar.

## 2026-09-19 — Preprocesamiento real de Blender a ComfyUI

El render Blender v2 se copió al directorio de entrada ComfyUI aislado. `LoadImage → Canny → SaveImage` terminó correctamente en CPU en **3.731 s** (marcas del historial); se inspeccionó la imagen. Se conservan los bordes de anillos, pilares y pasillo. Es una imagen de control, no una escena generada por SDXL ni geometría 3D nueva. ID: `7f26de5e-5d83-455c-97be-1e3401e9ba5f`. Salida: `C:/tmp/blender-comfy-scenes-20260919/comfy-base/output/orbital-study/canny-edges_00001_.png`. La base explícita en memoria evitó la migración anterior; el hash de la base de la instalación no cambió. Tiempo GPU y llamadas API de pago: **0**. Se aplazó la inferencia SDXL para no cargar ambos modelos con solo unos 10 GiB de RAM disponibles.

## 2026-09-22 — Un flujo verificado antes de la GPU, y un fallo en nuestro propio verificador

- Los flujos de la lección 10 estaban escritos pero nunca ejecutados: la máquina no ha tenido la memoria libre para Wan 2.2. En lugar de esperar, se arrancó un servidor de ComfyUI sin ningún modelo, en CPU, solo para guardar su `/object_info`: 957 clases de nodos, 1,85 MB. El servidor se detuvo enseguida.
- Frente a ese archivo, los 26 flujos del curso están bien. `Wan22ImageToVideoLatent`, `CreateVideo`, `SaveVideo`, `FrameInterpolationModelLoader` y `FrameInterpolate` están en el núcleo en la v0.36.0, `film_net_fp16` aparece en la lista del cargador, y los nombres de los archivos de Wan 2.2 son los que ve el servidor: las rutas de modelos adicionales son correctas. La lección 10 puede lanzarse en cuanto haya memoria.
- La verificación anunció primero que `SaveVideo` no tenía una entrada `format.codec`, en los tres flujos. Se equivocaba, y el fallo era nuestro: [`Workflow.cs`](https://github.com/spareilleux/learn/blob/main/code/comfyui/csharp/Workflow.cs) solo leía las entradas `required` y `optional` de primer nivel, mientras que un `COMFY_DYNAMICCOMBO_V3` lleva sus hijos dentro de sus opciones. Ahora las recorre, y comprueba también las claves de opción. La lección 3 tiene [la sección](../03-workflow-json/#entradas-con-un-punto-en-el-nombre), y `check.sh` un juego de pruebas con los tres errores posibles de una entrada con punto.
- Un verificador que nunca ha fallado no demuestra nada. Este tiene ya un archivo que debe fallar, y las cuatro líneas nuevas de `expected/03-validate.txt` son lo que debe imprimir.
- El mismo día, cada lección escrita recibió una sección «tu turno» — la 9 era la única que terminaba con algo que hacer en la propia máquina — y las treinta imágenes del curso se reunieron en una [galería](../gallery/), cada una con el flujo que la hizo, en la revisión que la hizo.

## 2026-09-22 — Dónde deja Canny de coincidir, y qué rota `convrot`

- La pregunta abierta de la lección 6 tiene respuesta. [`data/canny-steps.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/canny-steps.py) calcula un hash por paso del filtro de Kornia sobre un patrón de 64 por 48 construido con aritmética entera, y `check.sh` lo ejecuta en las tres máquinas de la CI. La entrada son los mismos bytes en todas partes. El desenfoque gaussiano ya separa la máquina del autor de los runners, y el runner Apple Silicon de los dos x86; el gradiente espacial difiere en las cuatro, aunque Windows y Linux coincidían un paso antes: la misma convolución toma un camino distinto según la compilación. Todas las magnitudes difieren, y su suma sigue imprimiendo 2729.489258.
- Los contornos, en cambio, son idénticos en las cuatro máquinas: 1461 píxeles de 3072, un solo hash. Este patrón son áreas planas y bordes duros, así que nada queda cerca de un umbral. Esa es la otra mitad de la respuesta: la divergencia siempre está ahí, desde la primera convolución; es la imagen la que decide si se ve. [La lección 6](../06-controlnet/#en-qué-paso-dejan-de-coincidir) tiene la tabla.
- `convrot` era una suposición escrita en la lección 8, «una rotación de grupos de pesos antes de cuantizar». comfy-kitchen 0.2.34 la confirma y dice cuál: una matriz de Hadamard regular, simétrica y ortogonal, sobre grupos de 256 canales de entrada; el peso fuera de línea, las activaciones en línea, fusionado en el cuantizador por filas. Al ser su propia inversa, deja el producto intacto y solo cambia lo que el int8 tiene que contener. [`data/convrot.py`](https://github.com/spareilleux/learn/blob/main/code/comfyui/data/convrot.py) la reconstruye, idéntica a la de la biblioteca con tamaños 16, 64 y 256, y mide el error de ida y vuelta sobre un peso con un valor atípico por fila: 5,7 % sin rotación, 0,76 % con ella.
- El punto sobre EXR de la lección 9 ganó la consecuencia que importa al compartir: un flujo construido donde `.exr` tiene un tipo MIME designa una imagen que la lista de la máquina siguiente no ofrecerá. El archivo sigue siendo válido; el render deja de ser reproducible.

## Por verificar

- SDXL en Linux con CUDA, y en Apple Silicon con MPS: la máquina con GPU del curso usa Windows; la CI solo instala las builds para CPU.
- Qué operación hace que los codificadores de texto den resultados distintos según la UNet esté cargada o no, y si ocurre con otras GPU u otros drivers.
- Si un sampler ancestral da la misma imagen en la CPU y en la GPU para una semilla: el ruido de sus pasos se genera en el dispositivo.
- Si un hash perceptual sería estable en los casos de la lección 2.
- Las cadenas de ControlNet, `start_percent`, y el paso exacto en que cae el nivel de ruido de un porcentaje, que la lección calculó pero no renderizó.
- Entrenar un LoRA con los nodos experimentales de ComfyUI, y cuánto de los 16 GB necesita para SDXL.
- Varios LoRA apilados en el otro orden: la misma imagen, y el mismo hash de píxeles o no.
- La ruta emulada de nvfp4 y fp8 en una GPU sin sus kernels; la máquina del curso solo tiene una GPU de la serie RTX 50.
- Por qué la red nvfp4 de Z-Image muestreaba más rápido con el codificador de texto bf16 que con el fp4.
- Muestrear los mosaicos de `SplitImageToTileList` y unirlas con `ImageMergeTileList`: si se ven costuras con un denoise bajo.
- Si el `EXRLoader` de three.js lee en un navegador el EXR sin comprimir de ComfyUI.
- Cómo muestran los navegadores el AVIF HLG de `SaveImageAdvanced`.
- Los tiempos de render en caliente con `--disable-dynamic-vram`, en una máquina con suficiente RAM libre.
- `execution_interrupted` tal como lo imprimen los clientes, y `POST /interrupt` con un id de prompt: hace falta una ejecución lo bastante larga que interrumpir, y por tanto un modelo.

## Preguntas abiertas

No son mediciones pendientes —esas están arriba— sino decisiones que este curso no ha tomado.

- ¿Merece una issue en ComfyUI que `LoadImage` dependa de la tabla MIME de la máquina, o es el comportamiento deseado? Una llamada a `mimetypes.add_type` para los formatos que el propio ComfyUI escribe lo arreglaría en una línea, y cambiaría lo que una instalación existente enumera.
- ¿Qué parte de dos compilaciones x86 de la misma versión de PyTorch hace que sus convoluciones difieran: la vectorización, el paralelismo o la biblioteca de álgebra lineal? La sonda por pasos muestra *que* difieren desde la primera, no por qué.
- ¿Cuándo mover el anclaje? Todas las mediciones de aquí están atadas a ComfyUI v0.36.0 en un commit concreto, y eso es lo que les da sentido; nada dice qué será de ellas en la v0.37.
