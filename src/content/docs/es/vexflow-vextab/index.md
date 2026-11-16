---
title: VexTab y VexFlow — Misión
description: Notación y tablatura de guitarra en el navegador para desarrolladores que conocen C# o Java — VexTab, un pequeño lenguaje de texto, y VexFlow, la biblioteca JavaScript que lo dibuja, con cada ejemplo renderizado en SVG y comparado en CI en Windows, Linux y macOS, y el propio código VexTab de Guitar Alchemist puesto a prueba.
sidebar:
  label: Misión
  order: 0
---

:::note[Versiones estudiadas]
[VexTab](https://github.com/0xfe/vextab) **4.0.5**, publicado en npm el 2026-01-18 y construido a partir del commit [`3a5e00d`](https://github.com/0xfe/vextab/tree/3a5e00d858ae98934ba545f9bef5eb923e17e402) de `0xfe/vextab`, y el [VexFlow](https://www.vexflow.com/) **5.0.0** que incluye, construido a partir del commit [`0ca6f88`](https://github.com/vexflow/vexflow/tree/0ca6f889545c33cce851b420c24945f6eb685aeb) de `vexflow/vexflow`, sobre [Node.js](https://nodejs.org/) 24.21.0 con [jsdom](https://github.com/jsdom/jsdom) 30.1.1 y [opentype.js](https://opentype.js.org/) 2.0.0. El código del curso está en [`code/vexflow-vextab`](https://github.com/spareilleux/learn/tree/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab), con su propio `package.json` y su archivo de bloqueo, que fijan exactamente esas versiones. [`.github/workflows/vexflow-vextab-examples.yml`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/.github/workflows/vexflow-vextab-examples.yml) ejecuta [`check.sh`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/check.sh) en Linux, Windows y macOS: renderiza en SVG cada ejemplo de las lecciones, conserva cada mensaje de error que emite VexTab, pasa los textos de la lección 4 por el parser F# de Guitar Alchemist y lo compara todo con [`expected/`](https://github.com/spareilleux/learn/tree/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/expected).
:::

## Por qué aprendo esto

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) muestra voicings de guitarra, y un voicing se lee mejor como tablatura que como `x-3-2-0-1-0`. Al chatbot de GA se le pide que añada un bloque `vextab` a cada digitación que menciona; GA tiene una gramática VexTab en EBNF, un parser y un generador en F#, un visor en React y pruebas de extremo a extremo que esperan un SVG. Quería saber qué es VexTab, qué puede y qué no puede escribir, y si las piezas de GA que lo hablan coinciden con el original. La lección 4 responde a la última pregunta con mediciones, y la respuesta es, en su mayor parte, no.

## Para quién es este curso

Escribes C# o Java. Conoces el JavaScript de [JavaScript para desarrolladores de C#/Java](../javascript-for-csharp-java/): módulos, npm, funciones, objetos. Un poco de [React](../react-vite/) ayuda para la segunda tanda. Sabes leer una tablatura de guitarra: seis líneas, una por cuerda, números para los trastes. La teoría musical que necesitan las lecciones, nombres de notas, octavas, armaduras, se recuerda donde aparece, con enlaces a [Teoría musical para Guitar Alchemist](../music-theory-ga/).

## VexTab y VexFlow en una tabla

| | Qué es | Lo más parecido que ya conoces |
|---|---|---|
| [VexFlow](https://www.vexflow.com/) | Una biblioteca JavaScript que dibuja notación musical y tablatura, en SVG o en un canvas: pentagramas, notas, barras, ligaduras, bends, texto | Una API de dibujo con un motor de disposición, como el `DrawingContext` de WPF más un formateador |
| [VexTab](https://github.com/0xfe/vextab) | Un pequeño lenguaje de texto para notación y tablatura, y el JavaScript que lo analiza y llama a VexFlow | Un DSL compilado a llamadas sobre una API de objetos, como una plantilla Razor compilada a C# |
| `tabstave`, `notes`, `text`, `options` | Los cuatro tipos de línea de VexTab | Las instrucciones del DSL |
| El Artist | El objeto de VexTab que convierte las líneas analizadas en pentagramas y notas de VexFlow | El generador de código de un compilador |

## Al terminar este curso, sabré

- escribir VexTab para melodías, acordes y técnicas de guitarra, y leer los errores que emite;
- fijar armaduras, compases, claves y afinaciones, y saber cuáles cambian la notación y cuáles solo la tablatura;
- renderizar VexTab en SVG con Node, sin navegador, y probar el resultado;
- decir qué no puede expresar VexTab, y cuándo bajar a VexFlow;
- comprobar un programa que escribe VexTab, un chatbot o un generador, contra el parser real;
- *(segunda tanda)* dibujar la misma música con los propios objetos de VexFlow, renderizarla en React sin redibujar con cada token, y planificar el paso de VexFlow 4 a 5.

## Plan

| # | Lección | Lo que ya conoces |
|---|---|---|
| 1 | [Primer pentagrama, primera tablatura](01-first-stave/) | un DSL compilado a una API, un árbol sintáctico, `System.Xml.Linq` |
| 2 | [Técnicas de guitarra](02-guitar-techniques/) | la tablatura que lees: bends, slides, hammer-ons, acordes |
| 3 | [Armaduras, compases, claves y afinaciones](03-keys-time-tunings/) | armaduras, cejillas, drop D |
| 4 | [Caso práctico: el chatbot de GA escribe VexTab](04-ga-chatbot-vextab/) | FParsec o una biblioteca de combinadores de parsers, prompts de LLM |
| 5 | *Segunda tanda.* `Stave`, `StaveNote`, `Voice`, `Formatter`: lo que VexTab oculta, y una voz estricta que cuenta los tiempos | construcción de objetos, una pasada de disposición |
| 6 | *Segunda tanda.* `TabStave` y `TabNote`; mantener notación y tablatura sincronizadas | dos vistas de un mismo modelo |
| 7 | *Segunda tanda.* Renderizar en React sin redibujar con cada token recibido, y probarlo con Playwright (el `MemoizedVexTab` de GA) | `memo`, efectos, pruebas de extremo a extremo |
| 8 | *Segunda tanda.* Pasar los componentes de GA de VexFlow 4 a 5: qué cambió en la API, las fuentes y la medición de texto | una actualización de versión mayor |
| — | [Diario](journal/) | |

## Recursos

- El [tutorial de VexTab](https://vexflow.com/vextab/tutorial.html) de Mohit Cheppudira (0xfe), autor de VexTab, y su [README](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/README.md). La gramática es [`src/vextab.jison`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/vextab.jison).
- El [sitio de VexFlow](https://www.vexflow.com/), su [repositorio](https://github.com/vexflow/vexflow/tree/0ca6f889545c33cce851b420c24945f6eb685aeb) y su [referencia de la API](https://www.vexflow.com/build/docs/).
- [SMuFL](https://w3c.github.io/smufl/latest/), el estándar que numera los glifos musicales, y [Bravura](https://github.com/steinbergmedia/bravura), la fuente con la que VexFlow 5 los dibuja.
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), fijado en el commit [`17ccee6`](https://github.com/GuitarAlchemist/ga/tree/17ccee6885851e4b460ebd14d7f4cfb838f5541e) para la lección 4.
