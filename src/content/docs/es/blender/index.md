---
title: Blender para desarrolladores — Misión
description: 'Aprende Blender como desarrollador C# o Java que nunca ha hecho 3D — el archivo .blend como base de datos de bloques de datos, el modelado poligonal y los modificadores, los materiales de nodos, las UV y la exportación a glTF, las luces y el render con EEVEE y Cycles —, con cada lección guiada por scripts bpy ejecutados en segundo plano y comprobados en CI en Windows, Linux y macOS, en torno a un diapasón de guitarra construido desde código.'
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
El código del curso está en [`code/blender`](https://github.com/spareilleux/learn/tree/main/code/blender): scripts de Python para [Blender](https://www.blender.org/) **5.2.2 LTS**, ejecutados con `blender --background --factory-startup`. `check.sh` ejecuta el script de cada lección y compara su informe (listas de objetos, número de vértices y de caras, valores de materiales, el contenido de una exportación glTF, medidas de ruido y el hash de una imagen renderizada) con los archivos de `expected/`. Un workflow, `blender-examples.yml`, descarga Blender de download.blender.org y lo ejecuta en Linux, Windows y macOS, con Cycles en la CPU. Las capturas de pantalla, los tiempos en GPU y los renders de EEVEE vienen de una sola máquina: Windows 11, una NVIDIA GeForce RTX 5080, en septiembre de 2026.
:::

## Por qué aprendo esto

El [curso de three.js](../threejs/) del sitio carga modelos glTF, y GuitarAlchemist dibuja un mástil de guitarra en 3D en el navegador. Hasta ahora, esos modelos se escriben desde código, primitiva a primitiva. Blender es donde se suelen crear los modelos 3D, y es gratuito, de código abierto y programable en Python de principio a fin.

Quiero entender cómo guarda Blender una escena, cómo modelar, texturizar e iluminar algo sencillo pero real, y cómo exportarlo para la web. También quiero manejarlo con scripts, porque ahí es donde un desarrollador aporta más a un pipeline 3D: exportaciones por lotes, escenas generadas y comprobaciones en CI.

## Para quién es este curso

Escribes C# o Java, y nunca has hecho 3D. No hace falta conocer bien Python: los scripts son cortos, y el [curso de Python](../python-for-csharp-java/) cubre el lenguaje. Necesitas un ratón con rueda; una tarjeta gráfica ayuda para EEVEE y para el viewport, pero todos los scripts del curso se ejecutan en la CPU, como en la CI.

## Otro orden: scripts desde la lección 1

La mayoría de los tutoriales de Blender dejan los scripts para el final. Este curso trae `bpy`, la API de Python de Blender, a cada lección desde la primera, por dos razones. Un desarrollador entiende antes un modelo de datos imprimiéndolo que haciendo clic por la interfaz. Y un script que construye una escena da un resultado comprobable: los mismos números de vértices, los mismos valores de materiales y, como muestra la lección 4, los mismos píxeles renderizados en tres sistemas operativos.

Por eso cada lección tiene dos mitades: lo que haces en la interfaz, y cómo se ve lo mismo en `bpy`. La lección 5 profundiza después en la propia API.

## Al final de este curso, sabré

- orientarme en la interfaz de Blender, y explicar qué contiene un archivo `.blend`;
- modelar con mallas y modificadores, y leer la topología de una malla;
- construir materiales de nodos con el Principled BSDF, desplegar UV y usar texturas de imagen;
- iluminar una escena, y elegir entre EEVEE y Cycles, el número de muestras y la eliminación de ruido;
- escribir scripts `bpy` que construyen, comprueban y renderizan escenas sin ventana;
- construir geometría procedural con Geometry Nodes;
- animar con fotogramas clave, armaduras y restricciones;
- exportar glTF 2.0 para three.js, y saber qué conserva y qué descarta el exportador;
- escribir un add-on y empaquetarlo como extensión;
- ejecutar renders y exportaciones en CI.

## Plan

| # | Lección | En términos de C# o Java |
|---|---|---|
| 1 | [La interfaz, y el archivo .blend como base de datos](01-interface-data-blocks/) | un modelo de objetos con recuento de referencias, y la reflexión |
| 2 | [Modelado poligonal y modificadores](02-modeling-modifiers/) | una cadena de decoradores, evaluada de forma perezosa |
| 3 | [Materiales, UV, y lo que glTF conserva de ellos](03-materials-uv-gltf/) | un grafo de flujo de datos, y un serializador con pérdidas |
| 4 | [Luces, cámaras, y el render con EEVEE y Cycles](04-lighting-rendering/) | una estimación de Monte Carlo, y un `Random` con semilla |
| 5 | Scripts con `bpy`: datos, operadores, contexto y línea de comandos | la API que hay detrás de la interfaz |
| 6 | Geometry Nodes: el modelado procedural como programa de flujo de datos | LINQ sobre vértices |
| 7 | Animación: fotogramas clave, curvas, armaduras y restricciones | — |
| 8 | Exportar para la web: glTF 2.0, Draco, meshopt y KTX2, cargados en three.js | — |
| 9 | Add-ons: operadores, paneles y propiedades, empaquetados como extensión | una API de plugins, y un registro de paquetes |
| 10 | Un pipeline automatizado: renders y exportaciones por lotes, y pruebas de scripts `bpy` en CI | — |
| 11 | Escultura y retopología (visión general) | — |
| 12 | Simulación: física, partículas y fluidos (visión general, con su coste de cómputo) | — |
| 13 | Proyecto: un mástil de guitarra para GuitarAlchemist, exportado a glTF y mostrado en three.js | — |
| — | [Diario](journal/) | |

Las lecciones 5 a 13 son el plan; cambiarán a medida que las primeras me enseñen lo que importa.

## El modelo del curso

Todas las lecciones trabajan sobre el mismo objeto: un diapasón de guitarra de 22 trastes con una escala de 648 mm (25,5 pulgadas), construido por [`scripts/fretboard.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py). Los trastes están donde los pone el temperamento igual, algo que un modificador no sabe hacer y un script hace en una línea. No hay ningún archivo `.blend` en el repositorio: los scripts reconstruyen la escena cada vez.

![El diapasón del curso renderizado con Cycles: una tabla de palisandro, trastes de alpaca y marcadores de nácar](../../../../assets/blender/l03-fretboard.webp)

## Recursos

- [Manual de Blender 5.2](https://docs.blender.org/manual/en/5.2/) y [referencia de la API de Python](https://docs.blender.org/api/5.2/).
- [El código fuente de Blender](https://projects.blender.org/blender/blender), en la [etiqueta v5.2.2](https://projects.blender.org/blender/blender/src/tag/v5.2.2) (commit `d13f752e3b9c`).
- [Versiones LTS de Blender](https://www.blender.org/download/lts/), con sus periodos de soporte.
- Khronos, [especificación de glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html), y el [repositorio del exportador glTF](https://github.com/KhronosGroup/glTF-Blender-IO).
