---
title: Laboratorio Guitar Alchemist — Misión
description: Prototipos de principio a fin construidos sobre los datos y el código reales de Guitar Alchemist — cada uno parte de una hipótesis escrita antes de medir nada, y publica sus cifras y sus fracasos.
sidebar:
  label: Misión
  order: 0
---

## Por qué este laboratorio

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) tiene mucha maquinaria: un índice de 313.047 voicings incrustados en el espacio OPTIC-K, reconocimiento de acordes, la geometría del mástil, un mástil en 3D, generadores de imágenes y de modelos. Los demás cursos del sitio desmontan cada pieza: [la teoría musical](../music-theory-ga/), [la IA de GA](../ga-ai/), [three.js](../threejs/), [ComfyUI](../comfyui/), [Blender](../blender/). Este laboratorio junta las piezas en cosas que se pueden ver, oír y tener en la mano, y se pregunta cada vez si la idea funciona de verdad.

Cada prototipo sigue el mismo contrato.

1. **Una hipótesis, confirmada primero en un commit.** Antes de cualquier medición, un archivo de la carpeta `results/` del prototipo dice lo que espero, con cifras. Si vi una cifra antes de escribirla, el archivo lo dice.
2. **Mediciones.** Las cifras salen de un script del repositorio, ejecutado en una máquina con nombre, con los datos fijados: el commit de GA, el SHA-256 del archivo, la semilla de la muestra.
3. **Fracasos publicados.** Una predicción que resulta falsa se queda en la lección, junto a lo que pasó en su lugar.

## Para quién es este laboratorio

Escribes C# o Java, has seguido al menos uno de los cursos sobre GA, y tienes curiosidad por ver cómo son los datos de GA cuando dejas de leerlos a través de una API. Cada prototipo indica en qué lecciones se apoya. El código es JavaScript para el navegador y Node.js, más lo que necesite cada prototipo.

## Requisitos previos

- [Node.js](https://nodejs.org/) 24 y [Git](https://git-scm.com/downloads). En Windows, ejecuta los comandos desde Git Bash.
- Un navegador con [WebGPU](https://developer.mozilla.org/docs/Web/API/WebGPU_API): un Chrome o un Edge recientes. En otros, los prototipos recurren a WebGL 2.
- Para los modos locales que leen todo el índice de GA: un clon de [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) y unos 200 MB para el archivo del índice. Las páginas publicadas solo necesitan un navegador.
- Ayuda como base: la [lección 2](../ga-ai/02-optic-k-embeddings/) y la [lección 3](../ga-ai/03-index-and-search/) del curso sobre la IA de GA, la [lección 5](../machine-learning-ix/05-dimensionality-reduction/) del curso de aprendizaje automático con IX, y la [lección 8](../threejs/08-performance-instancing-batching-lod/) del curso de three.js.

## Plan

| # | Prototipo | Pregunta | Estado |
|---|---|---|---|
| P1 | [Explorador del espacio de voicings](01-voicing-explorer/) | ¿Se puede ver el espacio de voicings de GA en tres dimensiones, y qué esconde la imagen? | publicado |
| P2 | [Toca un acorde, mira el universo](02-chord-universe/) | Reconocimiento de acordes en el navegador: FFT, estimación de notas, plantillas sobre las calidades de acordes de GA, mástil 3D, brazalete y acorde siguiente; 624 rasgueos sintéticos y 17 grabaciones CC0, predicciones primero | publicado |
| P3 | Portadas de álbum | ¿Puede un modelo de difusión hacer una portada que diga algo cierto sobre una progresión de acordes? | previsto |
| P4 | Pasada de render con IA | ¿Mejora una textura o una iluminación generadas las escenas 3D de GA, medidas frente al render simple? | previsto |
| P5 | Pulseras imprimibles en 3D | ¿Puede una pulsera de clases de altura convertirse en un objeto imprimible, de los datos de GA a una malla que pase un slicer? | previsto |
| P6 | Cadena completa | Del micrófono al acorde, al voicing, a la imagen y al objeto, de una vez: ¿dónde se rompe? | previsto |
| P7 | Modelo de tocabilidad | ¿Predice un modelo pequeño entrenado en la CPU lo difícil que es tocar un voicing mejor que el coste escrito a mano en GA? | previsto |
| — | [Diario](journal/) | | |

## Recursos

- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), el código y los datos que lee cada prototipo.
- El código del laboratorio: [`code/ga-protos`](https://github.com/spareilleux/learn/tree/main/code/ga-protos), una carpeta por prototipo, probada por [`.github/workflows/ga-protos-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ga-protos-examples.yml).
- [three.js](https://threejs.org/) y su [WebGPURenderer](https://threejs.org/docs/pages/WebGPURenderer.html), [Vite](https://vite.dev/), y la [Web Audio API](https://developer.mozilla.org/docs/Web/API/Web_Audio_API).
- Clifton Callender, Ian Quinn y Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://doi.org/10.1126/science.1153021), *Science* 320, 2008: las equivalencias OPTIC que dan nombre a la incrustación de GA.
