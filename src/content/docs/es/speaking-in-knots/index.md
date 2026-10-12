---
title: Hablar en nudos — Misión
description: 'Escribir los nudos como un texto que IX puede comprobar — primero dos presentaciones, el original en francés y su copia en inglés, luego las palabras de trenza, su cierre y el polinomio de Jones calculado con el corchete de Kauffman, comprobado contra los valores que afirman las pruebas de IX y contra el Knot Atlas, con un diario cuyas entradas pueden repetirse todas.'
sidebar:
  label: Misión
  order: 0
---

## Las dos presentaciones

El curso parte de una presentación construida mientras IX aprendía a leer, comprobar y dibujar nudos. Existe en dos idiomas, y esta página enlaza las dos:

- **[Parler en nœuds](https://claude.ai/artifact/7v3cgP2wAARzvxgDgA8iEq)**: el original, en francés, 52 diapositivas.
- **[Speaking in Knots](https://claude.ai/artifact/V9yPov2hxYxNWZApXrNxYF)**: su copia en inglés, diapositiva por diapositiva, hecha a partir de la versión `1791174928-7d71` de la presentación francesa.

La presentación recorre nueve partes: por qué un nudo necesita un texto que IX pueda comprobar; las cuatro formas de escribir un nudo, con el código de Gauss en detalle; qué comprueba IX y cómo rechaza; las palabras de trenza y los nombres de la tabla de nudos; ejemplos, del texto al render final en ComfyUI; los nudos marineros en 3D, dibujados a mano, comprobados y dotados de volumen por IX, y luego renderizados; lo que IX saca de los nudos (errores al anudar, invención, pipelines, archivos `.knot` y los cómics de Jean-Pierre Petit); el estado de las pull requests; y el método, con sus revisiones adversarias.

:::caution[Lo que el curso reproduce, y lo que no]
Solo una parte de lo que muestra la presentación está en el código publicado de IX. Las palabras de trenza, el polinomio de Jones y una disposición 3D de las hebras están en la [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366), publicada, probada por la CI de IX y todavía abierta. El código de Gauss, el lenguaje `.knot`, la cuerda apoyada y el bucle 3D viven en ramas locales que aún no se han publicado: sus cifras vienen de la presentación y el curso no las reproduce. La lección 1 solo enseña lo que se puede comprobar desde el código publicado, y el [diario](journal/) dice cómo.
:::

## Cómo se prueba este curso

El código del curso está en [`code/speaking-in-knots`](https://github.com/spareilleux/learn/tree/main/code/speaking-in-knots): un script de Python que calcula el polinomio de Jones del cierre de una trenza con la suma de estados del corchete de Kauffman, solo con la biblioteca estándar. `check.sh` lo ejecuta contra los valores que afirman las pruebas de IX en el commit [`e8684cf`](https://github.com/GuitarAlchemist/ix/tree/e8684cf) sobre palabras de hasta 6 cruces (26 comprobaciones), lo ejecuta con cada palabra de trenza que citan las lecciones, ejecuta una comprobación por mutación (seis errores deliberados, cada uno de los cuales debe hacer fallar la primera comprobación) y compara cada salida con los archivos de `expected/`. Ningún workflow de CI lo ejecuta todavía: se ejecutó a mano en Windows 11 con Python 3.14.3, y Linux y macOS están *por verificar*. El lado de IX lo prueba la CI de IX.

## Por qué aprendo esto

Un nudo dibujado en papel es fácil de mostrar y difícil de comprobar. Un nudo escrito como texto puede comprobarlo un programa: cuántas hebras tiene, si se cierra en un solo lazo o en varios, y si dos textos describen el mismo nudo. IX, la caja de herramientas en Rust del ecosistema GuitarAlchemist, aprendió a hacerlo, y este curso sigue lo que aprendió, una pieza comprobable cada vez.

## A quién va dirigido este curso

Escribes código y nunca has estudiado teoría de nudos. No hacen falta matemáticas más allá de los polinomios: las lecciones definen cada objeto antes de usarlo, y cada número que citan viene de una ejecución que puedes repetir. Leer Rust ayuda a seguir el código de IX, pero no es imprescindible.

## Al terminar este curso, sabré

- escribir un nudo o un enlace como una palabra de trenza, y decir de qué está hecho su cierre;
- calcular un polinomio de Jones con el corchete de Kauffman, y distinguir un nudo de su imagen especular;
- leer una tabla de nudos, sabiendo qué elecciones de quiralidad hace;
- decir qué comprueba IX en el texto de un nudo y cuándo lo rechaza;
- repetir cada entrada del diario del curso y comprobar su resultado.

## Plan

| # | Lección | En términos de desarrollador |
|---|---|---|
| 1 | [Las palabras de trenza y el polinomio de Jones](01-braid-words/) | un parser, una permutación y una suma sobre 2^n casos |
| 2 | El código de Gauss: un nudo como la lista de sus cruces | un formato de serialización con un validador |
| 3 | Lo que IX rechaza, y por qué | errores tipados |
| 4 | Los nudos marineros en 3D: de un dibujo a un tubo comprobado | un pipeline geométrico con controles en cada etapa |
| — | [Diario](journal/) | |

Las lecciones 2 a 4 son el plan: cada una espera a que se publique el código de IX que enseña.

## Recursos

- IX, [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366): el crate `ix-knot` y la herramienta `ix_braid`, en el commit [`e8684cf`](https://github.com/GuitarAlchemist/ix/tree/e8684cf).
- [The Knot Atlas](https://katlas.org/), la tabla de nudos con la que se compara el curso.
- J. W. Alexander, «A lemma on systems of knotted curves», *Proceedings of the National Academy of Sciences* 9 (1923), 93–95: todo nudo y todo enlace es el cierre de una trenza.
- L. H. Kauffman, «State models and the Jones polynomial», *Topology* 26 (1987), 395–407: el corchete que calcula la lección.
