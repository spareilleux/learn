---
title: Diario
description: 'Notas de avance fechadas del curso de Blender — Blender 5.2.2 LTS fijado, una instalación portable, scripts ejecutados en segundo plano y comparados en CI en tres sistemas operativos, un render de Cycles con los mismos píxeles en Windows, Linux y macOS, un error de espacio de color en una textura generada, lo que el exportador glTF descarta u omite por defecto, y puntos por verificar.'
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

## Por verificar

- La instalación con winget, Snap y Flathub, y las versiones que ofrecen.
- Los comandos de PowerShell de descarga y extracción de la lección 1, tal como están escritos.
- La interfaz en WSLg.
- EEVEE en una máquina sin GPU, y si los arranques posteriores más rápidos de EEVEE vienen de una caché de shaders en disco.
- Si los renders en GPU con una semilla fija son reproducibles, entre ejecuciones y entre GPU.
