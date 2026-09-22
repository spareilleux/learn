---
title: Diario
description: 'Notas de avance fechadas del curso de Blender — Blender 5.2.2 LTS fijado, una instalación portable, scripts ejecutados en segundo plano y comparados en CI en tres sistemas operativos, un render de Cycles con los mismos píxeles en Windows, Linux y macOS, un error de espacio de color en una textura generada, lo que el exportador glTF descarta u omite por defecto, dos objetos modelados en bpy frente a los dos mismos generados a partir de una imagen, dos modelos de Hunyuan3D salidos de ComfyUI limpiados en Blender con lo que falló, y puntos por verificar.'
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
- [x] Dos modelos procedurales en `bpy`, comparados con los generados
- [ ] Lección 5: scripts con `bpy`

## Experimentos

Cada fila es una pregunta que el curso midió, con la hipótesis tal como estaba escrita antes de la medición. Una hipótesis refutada es un resultado y se queda aquí.

| Pregunta | Hipótesis, escrita antes | Resultado | Veredicto | Dónde |
|---|---|---|---|---|
| ¿Da el mismo script `bpy` el mismo informe en Windows, Linux y macOS? | Sí, con Cycles en el procesador y semillas fijas. | Los informes son idénticos en los tres ejecutores, incluido el remallado por vóxeles, y la huella del render de 16 muestras coincide en x86-64 y en Apple Silicon. | Confirmada | [2026-09-16](#2026-09-16--los-scripts-la-ci-y-lo-que-mostraron) · [`check.sh`](https://github.com/spareilleux/learn/blob/0c94215/code/blender/check.sh) |
| ¿Lleva un modelo generado desde una imagen su iluminación pintada en la textura? | Sí — ese era el fallo esperado antes de lanzar la tubería. | Este flujo solo saca la forma: sin mapa UV, sin textura, un material vacío. El fallo esperado no podía ocurrir. | Refutada | [2026-09-17](#2026-09-17--modelos-generados-en-comfyui-limpiados-en-blender) · [`glb_pipeline.py`](https://github.com/spareilleux/learn/blob/0c94215/code/blender/scripts/glb_pipeline.py) |
| ¿Alcanza Decimate en modo Collapse un objetivo de 20.000 triángulos en una malla de superficie net? | Sí, para eso está la proporción. | 43.302 triángulos en el metrónomo y 317.253 en el gramófono: fallado en ambos, por 19.084 y 189.748 aristas no manifold. | Refutada | [2026-09-17](#2026-09-17--modelos-generados-en-comfyui-limpiados-en-blender) · [`glb_pipeline.py`](https://github.com/spareilleux/learn/blob/0c94215/code/blender/scripts/glb_pipeline.py) |
| ¿Da un remallado por vóxeles previo una malla que Decimate pueda llevar al objetivo? | Sí, a costa del detalle menor que un vóxel. | 20.000 triángulos exactos en ambos, 0 aristas no manifold, ningún borde. Las paredes finas se rompen en migas, que retira una segunda pasada del filtro de islas. | Confirmada | [2026-09-17](#2026-09-17--modelos-generados-en-comfyui-limpiados-en-blender) · [`glb_pipeline.py`](https://github.com/spareilleux/learn/blob/0c94215/code/blender/scripts/glb_pipeline.py) |
| ¿Basta una vista previa en procesador con pocas muestras para juzgar un encuadre antes de gastar tiempo de GPU? | Sí. | 6,698 s y 7,025 s con 24 muestras; el primer encuadre ponía pilares atravesando los anillos focales y se rechazó a ojo. | Confirmada para el encuadre, no para la calidad final de la imagen | [2026-09-19](#2026-09-19--catedral-orbital-encuadre-antes-de-la-generación) · [`orbital_cathedral.py`](https://github.com/spareilleux/learn/blob/0c94215/code/blender/scripts/orbital_cathedral.py) |
| ¿Qué aporta modelar en `bpy` frente a imagen→3D, para los dos mismos objetos? | Una malla mucho más ligera y limpia, pagada en detalle y en líneas de código. | 3.370 y 5.950 triángulos frente a 890.140 y 1.017.760; 0 aristas no manifold frente a 19.084 y 189.748; piezas nombradas, materiales y animaciones, por unas 510 líneas. | Confirmada | [2026-09-22](#2026-09-22--modelar-en-bpy-frente-a-imagen3d) · [`atlas_check.py`](https://github.com/spareilleux/learn/blob/0c94215/code/blender/scripts/atlas_check.py) |
| ¿Vale una oclusión horneada por vértice sus 40 KB en una página en tiempo real? | Sí: multiplicar el término ambiental por ella asentaría los objetos sobre sus superficies. | Sobre el término ambiental, del 4 al 5 % de los píxeles se mueven una media de 1,2/255 — nada. Sobre el término difuso, con la exposición fijada, la dispersión de la luminancia crece de 1,44 a 1,95. | Refutada sobre el término ambiental, confirmada sobre el difuso | [2026-09-22](#2026-09-22--oclusión-horneada-en-los-vértices-y-distinguir-un-efecto-real-de-una-imagen-más-oscura) · scripts no publicados |

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

La petición: modelos 3D reales salidos de ComfyUI, llevados a Blender y mostrados aquí con lo que salió mal. La generación es obra de Atlas, otra sesión de trabajo de este proyecto, con su script `objets.py` (no publicado): produjo un metrónomo y un gramófono con ComfyUI (ver el [curso de ComfyUI](../../comfyui/)), en dos pasos:

1. [SDXL base 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0) dibujó cada objeto solo sobre fondo blanco, visto de tres cuartos y ligeramente desde arriba: 1024 × 1024 px, 30 pasos, CFG 6,5, `dpmpp_2m` con el planificador `karras`, semillas 5101 (metrónomo) y 5110 (gramófono).
2. [Hunyuan3D 2.0](https://github.com/Tencent-Hunyuan/Hunyuan3D-2), con los pesos fp16 reempaquetados por Comfy-Org ([`hunyuan3d-dit-v2_fp16`](https://huggingface.co/Comfy-Org/hunyuan3D_2.0_repackaged)) y los nodos nativos de ComfyUI ([tutorial de Comfy](https://docs.comfy.org/tutorials/3d/hunyuan3D-2)), convirtió cada imagen en una malla: `ImageOnlyCheckpointLoader` → `CLIPVisionEncode` (crop `center`) → `Hunyuan3Dv2Conditioning` → `EmptyLatentHunyuan3Dv2` (resolution 3072) → `KSampler` (30 steps, CFG 5, `euler`/`normal`, seed 7) → `VAEDecodeHunyuan3D` (8000 chunks, octree resolution 380) → `VoxelToMesh` (surface net, threshold 0.6) → `SaveGLB`. ComfyUI v0.36.0.

La licencia de Hunyuan3D 2.0 no se aplica en la Unión Europea, el Reino Unido ni Corea del Sur, y su cláusula 5.c prohíbe mostrar los resultados fuera de ese territorio. Este sitio se puede leer allí, así que aquí no se publican ni los modelos ni sus renders: los hallazgos se describen con palabras.

El pipeline de limpieza lo escribió para este curso L2, la sesión que lo redacta. Blender ejecutó [`scripts/glb_pipeline.py`](https://github.com/spareilleux/learn/blob/9480173/code/blender/scripts/glb_pipeline.py) en segundo plano sobre cada archivo. Fusiona vértices por distancia, quita las partes flotantes, recalcula las normales, escala a un tamaño real, diezma, informa de la malla antes y después, renderiza una turntable con Cycles, exporta un `.glb` con los modificadores aplicados y lo vuelve a leer. La CI lo ejecuta sobre una pequeña púa construida en `bpy`, con los defectos de una malla generada (`scripts/pipeline_check.py`), con y sin remesh de vóxeles: los informes, remesh incluido, fueron idénticos en los tres runners.

Lo que mostraron los renders en turntable. El metrónomo conservó su pirámide, su base y su llave de cuerda; la esfera, las marcas de la escala y el péndulo de la imagen salieron en relieve en la cara delantera, con una superficie rugosa antes del remesh y más lisa después. La bocina del gramófono estaba llena de triángulos rotos antes del remesh y cerrada después, y una losa bajo el mueble se rompió en unos pocos fragmentos.

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

## 2026-09-19 — Catedral orbital: encuadre antes de la generación

Este estudio procedural reutiliza `stage.aim` y `stage.area_light` del curso. Hipótesis previa: una vista previa en CPU con pocas muestras basta para evaluar el encuadre antes de usar la GPU para ComfyUI.

- Windows, Blender 5.2.2 LTS, Cycles CPU, 8 hilos, 24 muestras, 1100 × 700 píxeles, 314 objetos.
- Primer render: **6.698 s**. La cámara oblicua colocó pilares delante de los anillos; la inspección visual descartó ese encuadre.
- Segundo render: **7.025 s**. La cámara centrada deja visibles los anillos y el pasillo. Ambos procesos terminaron con código 0; el script comprueba los objetos y la salida PNG.
- Veredicto: confirmado para detectar este defecto de encuadre, no para la calidad final. Tiempo total de render: **13.723 s**; render en GPU: **0 s**.
- Código: `code/blender/scripts/orbital_cathedral.py`. Evidencia local: `C:/tmp/blender-comfy-scenes-20260919/orbital-v1/` y `orbital-v2/`, cada una con PNG, blend editable e informe JSON. No se han publicado.
- No se modificó la escena abierta del usuario. MCP no respondió; el estudio se creó en un proceso separado con configuración de fábrica.
- ComfyUI no estaba disponible en el puerto 8188. No hubo inferencia ComfyUI, API de pago ni descarga de modelos. El código del artefacto Claude sigue sin leerse: es un estudio original, no una adaptación.
- Advertencias no fatales: asignaciones `use_nodes` obsoletas y rutas de pinceles integrados que Blender no pudo convertir en relativas. Linux/macOS, portabilidad del blend, refinamiento de materiales y la etapa ComfyUI quedan **por verificar**.

## 2026-09-22 — Modelar en bpy frente a imagen→3D

Los mismos dos objetos, un metrónomo y un gramófono, se hicieron dos veces: generados desde una imagen de SDXL por Hunyuan3D 2.0 (la entrada anterior), y luego modelados en `bpy`. El segundo camino se eligió tras leer la licencia de Hunyuan3D, cuya cláusula 5.c prohíbe mostrar sus resultados fuera de un territorio que excluye la Unión Europea, el Reino Unido y Corea del Sur — el curso de ComfyUI cuenta esa cara en la [lección 8](../../comfyui/08-recent-models-quantization/#leer-la-licencia-antes-de-publicar-una-salida). Los scripts los escribió un agente de la sesión orquestadora; se conservan en el curso, en [`scripts/atlas/`](https://github.com/spareilleux/learn/blob/50da8f8/code/blender/scripts/atlas/), porque hacen concreta la comparación.

![Dos modelos hechos en bpy, renderizados con Workbench: un metrónomo de madera con su escala graduada y su péndulo, y un gramófono con bocina de revolución, un disco y su etiqueta](../../../../assets/blender/atlas-bpy-models.webp)

| | Hunyuan3D 2.0, ya limpiado | Modelado en `bpy` |
|---|---|---|
| Metrónomo: triángulos | 890.140, luego 43.302 tras Decimate, 20.000 tras un remesh de vóxeles | 3.370 |
| Gramófono: triángulos | 1.017.760, luego 317.253, 20.000 tras un remesh | 5.950 |
| `.glb` | 15,9 MB y 17,4 MB en bruto; 361 KB cada uno tras el remesh | 91.176 y 150.944 bytes |
| Aristas no manifold | 19.084 y 189.748 | 0 y 0 |
| Piezas, nombres | un solo bloque, `Material_0` | `corps`, `tige`, `poids`; `caisse`, `pavillon`, `disque`, `etiquette`, `repere` |
| Animación | ninguna | péndulo ±19,99° en 1,5 s; disco 720° en 1,54 s |
| Materiales | ninguno | un color Principled por pieza |
| Escala y ejes | hay que darlos a mano después | 1 unidad de alto, base en el origen, frente hacia +Z |

- **Lo que aporta el código.** Cada pieza es un objeto con nombre: la página que carga el modelo puede darle a cada una su material y animarla. El péndulo del metrónomo gira alrededor de un pivote, y el disco del gramófono alrededor de otro; ambas animaciones salen en el glTF y se repiten limpiamente. Nada queda a interpretación: la altura vale exactamente 1, la base está en el origen, el frente mira hacia +Z.
- **Lo que cuesta.** Unas 510 líneas de modelado para los dos objetos, más 120 para la verificación, y el modelo es exactamente tan detallado como dice el código: la escala del metrónomo son doce marcas extruidas, no una placa grabada; la madera es un color, no una veta. Un modelo de imagen→3D da en un minuto una forma que llevaría una hora modelar, con los defectos descritos en la entrada anterior.
- **Releer el archivo.** [`scripts/atlas_check.py`](https://github.com/spareilleux/learn/blob/50da8f8/code/blender/scripts/atlas_check.py) construye los dos modelos y luego abre cada `.glb` dos veces: una como bytes, analizando el bloque JSON para mostrar el árbol de nodos, los materiales y los muestreadores de animación, y otra por el importador, para los triángulos y la caja envolvente. La curva de rotación se desenrolla clave a clave, de modo que el informe muestra ángulos reales en lugar de cuaterniones: `0.000 s: 0.00 deg, 0.367 s: 19.99 deg, 0.750 s: 0.00 deg`, y si la primera clave es igual a la última. La CI compara todo el informe con `expected/`.
- **Los ejes de glTF.** Blender trabaja con Z hacia arriba y el frente hacia −Y; el exportador escribe Y hacia arriba y el frente hacia +Z. La verificación muestra la caja envolvente en los ejes de glTF, que es lo que ve quien consume el archivo: `x [-0.2495, 0.2495], y [0.0000, 1.0000], z [-0.1747, 0.1747]`.
- **Un detalle del exportador.** Los 720° del disco en 1,54 s se escriben en 155 claves, y no en dos claves con un número de vueltas: glTF guarda las rotaciones como cuaterniones, que no saben decir «dos vueltas». Un reproductor que interpola entre dos cuaterniones toma el camino corto, así que una vuelta completa hay que partirla en claves.
- **Memoria.** Aquí Blender solo se inicia con al menos 12 GB de memoria libre. La víspera, un bake de Cycles de otra escena se cayó dentro de Embree mientras construía su BVH, con 1 GB libre en una máquina de 64 GB.

## 2026-09-22 — Oclusión horneada en los vértices, y distinguir un efecto real de una imagen más oscura

La pregunta viene de otra página de este proyecto, el [Banc de Placement](../../artifacts/#banc-de-placement): una sala dibujada por un motor WebGL2 escrito a mano — una guitarra, un escritorio, una alfombra, seis luces puntuales — donde nada se apoya del todo en nada. ¿Valdría su peso en una página una oclusión horneada en Blender y entregada a razón de un byte por vértice? Nada se modificó en esa página: el horneado, el sombreador parcheado y las tres mediciones de abajo corrieron todos sobre una copia local.

**El horneado.** Una captura sin pantalla de la página sacó sus llamadas de dibujo — 803 dibujos sobre 518 mallas — de las cuales 220 no se mueven nunca. Esas se reconstruyeron en Blender y se hornearon con Cycles en un atributo de color por punto, `bpy.ops.object.bake(type="AO", target="VERTEX_COLORS")`: 21.533 vértices, 25,9 s para la pasada de oclusión ambiental y 24,4 s para la indirecta. Un byte por vértice son 21.533 bytes; llevado en base64 dentro del JSON de la página, 39.856. Una copia parcheada de la página lo vincula como atributo de vértice y multiplica por él un término de su sombreador.

**Dos cifras, tres mediciones.** Los mismos tres ángulos de cámara cada vez, y los mismos dos números: el porcentaje de píxeles cuya luminancia Rec.601 se mueve más de 4,5/255, y el desplazamiento de la luminancia media. Las tres vistas se llaman abajo `default`, `low-left` y `high-right`.

| | píxeles cambiados | desplazamiento medio | luminancia media | dispersión de la luminancia |
|---|---|---|---|---|
| oclusión sobre el término ambiental | 4,2, 5,0, 4,4 % | 1,23, 1,24, 1,30 | −0,4 | −0,16, −0,10, −0,07 |
| también sobre lo que difunden las seis luces | 47,8, 35,6, 52,1 % | 6,98, 5,64, 6,84 | −6,1 | −1,27, −0,18, −0,57 |
| las mismas, con la exposición devuelta | 58,3, 41,2, 59,7 % | 6,84, 6,25, 6,52 | 0,0 | +1,44, +1,82, +1,95 |

- **El primer camino casi no cambia nada.** Multiplicar solo el término ambiental por la oclusión mueve del 4 al 5 % de los píxeles, una media de 1,2 sobre 255. En ese sombreador el coeficiente ambiental va de 0,026 a 0,105 según el material: el término que pondera pesa poco en el color final, así que había poco que quitar. 40 KB por eso es un mal negocio.
- **El segundo parecía espectacular, y ahí estaba el problema.** Multiplicar por la oclusión lo que difunden las seis luces oscurece toda la imagen: la luminancia media pierde 6,1 sobre 255, cerca del 10 % de exposición. Un 0,9 uniforme sobre la imagen entera también «cambiaría» el 48 % de los píxeles, y no mostraría absolutamente nada. La tercera medición devuelve entonces la luminancia media a donde estaba — una sola ganancia en luz lineal, como funciona una exposición, y no sobre los bytes sRGB — y vuelve a hacer las dos mismas preguntas.
- **El porcentaje de píxeles cambiados subió, del 47,8 al 58,3 %.** Deshacer el oscurecimiento debía hacerlo caer. La ganancia por sí sola empuja casi cada píxel más allá del umbral: esa cifra medía la exposición, en los dos sentidos, y por tanto no podía responder a la pregunta. **Un porcentaje de píxeles cambiados no significa nada sin control de exposición** — y una cifra que sube cuando se quita el factor que estorba no es una medida débil, es la medida equivocada.
- **Lo que responde es la dispersión de la luminancia.** Una exposición pura deja intacta la desviación típica una vez deshecha la ganancia, y eso es exactamente lo que hace el camino ambiental: +0,04, +0,09, +0,11, ruido. El camino difuso la ensancha en 1,44, 1,82 y 1,95 mientras la media se queda fija — el lado iluminado sube mientras los huecos bajan. Eso es el contraste local, por definición. El criterio se generaliza: para saber si un efecto es real o solo más oscuro, se fija la media y se mira la dispersión.
- **La comprobación cruzada.** El desplazamiento medio apenas se mueve cuando se devuelve la exposición, 6,98 → 6,84 en la primera vista: el oscurecimiento no era su causa. Dos cifras reaccionan al reajuste en sentidos opuestos — una se alimenta de él, la otra lo ignora — y ambas apuntan en la misma dirección. Eso es lo que hace sólido el veredicto.
- **Veredicto: confirmado.** La oclusión horneada por vértice compra aquí sombras de contacto reales, por unos 40 KB, pero solo en el segundo camino: sobre el término difuso, no sobre el ambiental solo.
- **Dónde se detiene, al mismo nivel que el resultado.** Tres vistas de una sola escena. Y solo están horneados los 220 dibujos estáticos: una sombra horneada está pegada a su geometría, de modo que un objeto movido sobre un suelo horneado ni se lleva su sombra ni recibe ninguna. La técnica solo vale para lo que no se mueve, y quien la retome debe saberlo antes de presupuestar los bytes.
- **Sin publicar.** El horneado, la página parcheada y el script de medición viven fuera del repositorio y no se publican; el artefacto mismo no se tocó.

## Por verificar

- La instalación con winget, Snap y Flathub, y las versiones que ofrecen.
- Los comandos de PowerShell de descarga y extracción de la lección 1, tal como están escritos.
- La interfaz en WSLg.
- EEVEE en una máquina sin GPU, y si los arranques posteriores más rápidos de EEVEE vienen de una caché de shaders en disco.
- Si los renders en GPU con una semilla fija son reproducibles, entre ejecuciones y entre GPU.
