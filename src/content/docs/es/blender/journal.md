---
title: Diario
description: 'Notas de avance fechadas del curso de Blender — Blender 5.2.2 LTS fijado, una instalación portable, scripts ejecutados en segundo plano y comparados en CI en tres sistemas operativos, un render de Cycles con los mismos píxeles en Windows, Linux y macOS, un error de espacio de color en una textura generada, lo que el exportador glTF descarta u omite por defecto, dos modelos de Hunyuan3D salidos de ComfyUI limpiados en Blender con lo que falló, y puntos por verificar.'
sidebar:
  order: 99
---

## Progreso

- [x] Blender 5.2.2 LTS (commit `d13f752e3b9c`), instalado desde el archivo comprimido portable
- [x] `check.sh`: el script `bpy` de cada lección ejecutado con `--background --factory-startup`, y su informe comparado con `expected/`
- [x] CI en Ubuntu, Windows y macOS, con Cycles en la CPU
- [x] Lección 1: la interfaz, y el archivo .blend como base de datos
- [x] Lección 2: modelado poligonal y modificadores
- [x] Lección 3: materiales, UV, y lo que glTF conserva de ellos
- [x] Lección 4: luces, cámaras, y el render con EEVEE y Cycles
- [x] Traducciones al francés y al español
- [x] Un pipeline de limpieza para modelos `.glb` generados en ComfyUI, probado con dos modelos de Hunyuan3D
- [ ] Lección 5: scripts con `bpy`

## 2026-09-16 — Versiones y configuración

- La página LTS de Blender enumera la 5.2.2 y la 4.5.14, ambas publicadas el 15 de septiembre de 2026. El curso fija la 5.2.2, etiqueta `v5.2.2`, commit `d13f752e3b9c4f8c261cda552b1021f8bcc0382c`.
- El archivo comprimido para Windows ocupa 404.453.484 bytes, y su SHA-256 coincide con `blender-5.2.2.sha256`. Se descomprime en una unidad aparte, y no se instala nada en el sistema.
- winget seguía ofreciendo la 5.2.1 el día en que salió la 5.2.2. El archivo de sumas de comprobación no enumera ninguna build para Intel en macOS, solo `macos-arm64`.
- Las páginas de projects.blender.org responden `403` a `curl`, pero su API no: `/api/v1/repos/blender/blender/raw/<path>?ref=<sha>` devolvió los archivos en el commit fijado. Los archivos de Python citados en las lecciones (el exportador glTF, las propiedades de Cycles) son idénticos a los de la build instalada, salvo por los finales de línea.
- Orden de la lección 1: `bpy` entra en cada lección desde la primera, en lugar de esperar a la lección 5; la misión explica por qué.

## 2026-09-16 — Los scripts, la CI y lo que mostraron

- La primera ejecución de CI pasó en los tres sistemas operativos. Cada job tardó alrededor de un minuto, del que `check.sh` ocupó entre 25 y 27 s; el resto es la descarga (unos 350 a 400 MB) y la descompresión. El render de referencia de 4.096 muestras de la lección 4 tardó entre 13 y 18 s en los runners, frente a 1,4 s en la CPU de 24 hilos del autor.
- El hash del render de Cycles de 16 muestras, en 8 bits tras AgX, fue el mismo en Windows y Linux sobre x86-64 y en macOS sobre Apple Silicon. Al principio `check.sh` lo imprimía sin compararlo; desde esa ejecución, lo compara.
- El archivo `.blend` guardado por la lección 1 ocupa 96.061 bytes en la máquina del autor y en el runner Linux, 96.053 en el runner Windows y 96.055 en el de macOS: su tamaño no se compara.
- La textura de palisandro generada salía al principio demasiado oscura. `Image.pixels` sobre una imagen sRGB de 8 bits guarda los valores dados como bytes, sin conversión, y el script había convertido antes el color a lineal. La lección 3 cuenta la historia.
- El exportador glTF descartó un Noise Texture conectado a la Roughness sin ningún mensaje en su log, dejando la rugosidad por defecto de glTF, 1. No aplica los modificadores salvo que se active `export_apply`. Y `export_format="GLTF_EMBEDDED"` se rechaza salvo que lo habilite una preferencia del add-on, aunque el manual documenta el formato.
- En la 5.2, leer `Material.use_nodes` imprime un `DeprecationWarning`: se eliminará en la 6.0. El enum de `RenderSettings.engine`, leído desde la clase, solo enumera `BLENDER_EEVEE`, aunque asignar `BLENDER_WORKBENCH` o `CYCLES` funciona.
- Las primeras luces (12, 3 y 15 W) eran demasiado fuertes para una escena de medio metro de ancho; la lección usa 3, 0,6 y 4 W.

## 2026-09-16 — Imágenes

- Los renders vienen de `scripts/render_images.py`: Cycles en la CPU para las imágenes de las lecciones, y Cycles con OptiX y EEVEE para los tiempos, ejecutados bajo el bloqueo de GPU de la máquina, ya que otros trabajos comparten la GPU.
- La captura de la interfaz viene de Blender arrancado con ventana y un script que selecciona el cubo, aparta el puntero y llama a `bpy.ops.screen.screenshot` desde un temporizador. Con `--factory-startup`, la pantalla de bienvenida Quick Setup tapaba el viewport, así que la captura usó una carpeta de configuración de usuario aparte (`BLENDER_USER_CONFIG`) cuyas preferencias desactivan la pantalla de bienvenida. Al salir desde el script, Blender escribió igualmente `quit.blend` en la carpeta temporal del sistema.

## 2026-09-17 — Modelos generados en ComfyUI, limpiados en Blender

La petición: modelos 3D reales salidos de ComfyUI, llevados a Blender y mostrados aquí con lo que salió mal. Atlas, otra sesión de trabajo de este proyecto, generó un metrónomo y un gramófono con ComfyUI (ver el [curso de ComfyUI](../../comfyui/)), en dos pasos:

1. [SDXL base 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0) dibujó cada objeto solo sobre fondo blanco, visto de tres cuartos y ligeramente desde arriba: 1024 × 1024 px, 30 pasos, CFG 6,5, `dpmpp_2m` con el planificador `karras`, semillas 5101 (metrónomo) y 5110 (gramófono).
2. [Hunyuan3D 2.0](https://github.com/Tencent-Hunyuan/Hunyuan3D-2), con los pesos fp16 reempaquetados por Comfy-Org ([`hunyuan3d-dit-v2_fp16`](https://huggingface.co/Comfy-Org/hunyuan3D_2.0_repackaged)) y los nodos nativos de ComfyUI ([tutorial de Comfy](https://docs.comfy.org/tutorials/3d/hunyuan3D-2)), convirtió cada imagen en una malla: `ImageOnlyCheckpointLoader` → `CLIPVisionEncode` (crop `center`) → `Hunyuan3Dv2Conditioning` → `EmptyLatentHunyuan3Dv2` (resolution 3072) → `KSampler` (30 steps, CFG 5, `euler`/`normal`, seed 7) → `VAEDecodeHunyuan3D` (8000 chunks, octree resolution 380) → `VoxelToMesh` (surface net, threshold 0.6) → `SaveGLB`. ComfyUI v0.36.0.

La licencia de Hunyuan3D 2.0 indica que no se aplica en la Unión Europea, el Reino Unido ni Corea del Sur. Aquí solo se publican renders de los modelos; los archivos `.glb` quedan fuera del repositorio.

Después, Blender ejecutó [`scripts/glb_pipeline.py`](https://github.com/spareilleux/learn/blob/9480173/code/blender/scripts/glb_pipeline.py) en segundo plano sobre cada archivo. Fusiona vértices por distancia, quita las partes flotantes, recalcula las normales, escala a un tamaño real, diezma, informa de la malla antes y después, renderiza una turntable con Cycles, exporta un `.glb` con los modificadores aplicados y lo vuelve a leer. La CI lo ejecuta sobre una pequeña púa construida en `bpy`, con los defectos de una malla generada (`scripts/pipeline_check.py`), con y sin remesh de vóxeles: los informes, remesh incluido, fueron idénticos en los tres runners.

![Metrónomo, de izquierda a derecha: la imagen de SDXL; la malla tras la primera limpieza, con la esfera y el péndulo convertidos en relieve y una superficie rugosa; tras un remesh de vóxeles de 1,2 mm, más lisa, con el mismo relieve; la parte trasera tras el remesh, una cara plana que la imagen no mostraba](../../../../assets/blender/comfy3d-metronome.webp)

![Gramófono, de izquierda a derecha: la imagen de SDXL, con una línea de suelo bajo el mueble; la malla tras la primera limpieza, con la bocina llena de triángulos rotos y una losa bajo el mueble; tras un remesh de vóxeles de 3 mm, una bocina cerrada, con algunos fragmentos de la losa en el suelo; la vista lateral tras el remesh](../../../../assets/blender/comfy3d-gramophone.webp)

Lo que dijeron los informes:

| | Metrónomo | Gramófono |
|---|---|---|
| `.glb` de Hunyuan3D | 15.944.172 bytes | 17.421.112 bytes |
| Vértices, triángulos | 438.348, 890.140 | 433.806, 1.017.760 |
| Aristas no manifold | 19.084 | 189.748 |
| Partes sueltas | 86 | 20 |
| UV, texturas | ninguna, ninguna | ninguna, ninguna |
| Decimate a 20.000 triángulos | 882.644 → 43.302, objetivo no alcanzado | 1.004.809 → 317.253, objetivo no alcanzado |
| `.glb` limpio, sin remesh | 632.484 bytes | 5.835.300 bytes |
| Remesh de vóxeles, luego Decimate | 1,2 mm: 223.100 → 20.000 | 3 mm: 195.848 → 20.000 |
| Tras el remesh: aristas no manifold, partes sueltas | 0, 1 | 0, 3 |
| `.glb` limpio, con remesh | 361.100 bytes | 361.000 bytes |

- **Sin textura, así que sin iluminación horneada.** El fallo previsto, la iluminación pintada en la textura, no ocurrió: este workflow solo produce la forma, con un material vacío y sin mapa UV. La madera, el latón y la esfera de las imágenes de SDXL se pierden; colores y materiales hay que hacerlos en Blender.
- **Topología.** Una surface net construye su superficie sobre una rejilla de vóxeles. Donde una pared es más fina que un vóxel, como la bocina del gramófono, probablemente ambas caras caen sobre las mismas aristas: el informe contó allí 189.748 aristas no manifold, frente a 19.084 en el metrónomo macizo. [Decimate](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/decimate.html) en modo Collapse se detuvo muy por encima de su objetivo en ambos modelos, y la primera versión del pipeline solo mostraba el ratio pedido. El informe muestra ahora los triángulos obtenidos y avisa cuando no se alcanza el objetivo.
- **Remesh de vóxeles.** El [modificador Remesh](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/remesh.html) en modo Voxel reconstruye una superficie cerrada. Después, Decimate alcanzó exactamente 20.000 triángulos, y ninguna de las dos mallas tenía bordes ni aristas no manifold. Su coste: se pierde el detalle más pequeño que un vóxel, y las paredes finas se rompen en migajas. El pipeline pasa ahora su filtro de partes flotantes una segunda vez tras el remesh; quitó 22 migajas del metrónomo y 2 del gramófono. Los dos fragmentos que quedan en el gramófono tienen cada uno más del 1 % de las caras.
- **Parte trasera inventada.** La parte trasera y los lados del metrónomo, que la imagen no muestra, salieron como caras planas y verosímiles. La esfera grabada, las marcas de la escala y el péndulo de la imagen se volvieron relieve en la cara delantera: Hunyuan3D lee el detalle pintado como forma.
- **El fondo.** La línea donde el suelo blanco se junta con la pared blanca bajo el gramófono se volvió una losa bajo el mueble. El filtro de partes flotantes la conservó, y el remesh solo la rompió en fragmentos. La solución va antes del paso 3D, en el recorte de la imagen.
- **Detalles menores.** El metrónomo tenía un vértice sin ninguna cara: glTF lo descarta, así que el tamaño releído era menor que el escrito. El pipeline borra ahora esos vértices. El origen se vuelve a poner abajo tras el remesh sin volver a escalar, por lo que el metrónomo remallado mide 22,98 cm de alto en lugar de 23.
- **Tiempo, en la máquina del autor.** De 17 a 29 s por modelo para todo el pipeline, importación y exportación incluidas; de 0,15 a 0,36 s por imagen de turntable a 512 × 512 px y 32 muestras, Cycles en la CPU. Los tamaños reales (23 cm y 60 cm de alto) son elecciones para esta prueba, no medidas.

## Por verificar

- La instalación con winget, Snap y Flathub, y las versiones que ofrecen.
- Los comandos de PowerShell de descarga y extracción de la lección 1, tal como están escritos.
- La interfaz en WSLg.
- EEVEE en una máquina sin GPU, y si los arranques posteriores más rápidos de EEVEE vienen de una caché de shaders en disco.
- Si los renders en GPU con una semilla fija son reproducibles, entre ejecuciones y entre GPU.
