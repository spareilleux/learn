---
title: Diario
description: Notas fechadas del curso VexTab y VexFlow — lo que resultaron hacer VexTab 4.0.5 y VexFlow 5.0.0, lo que hace frente a ellos el código VexTab de Guitar Alchemist, y a qué distancia de Chrome queda el renderizado sin navegador, con las hipótesis escritas antes de medir.
sidebar:
  order: 99
---

## Progreso

- [x] Misión y plan
- [x] Código del curso: renderizado sin navegador, `check.sh`, CI en Linux, Windows y macOS
- [x] Lección 1: primer pentagrama, primera tablatura
- [x] Lección 2: técnicas de guitarra
- [x] Lección 3: armaduras, compases, claves y afinaciones
- [x] Lección 4: caso práctico, el chatbot de GA escribe VexTab
- [ ] Lección 5: los propios objetos de VexFlow, una voz estricta
- [ ] Lección 6: `TabStave` y `TabNote`
- [ ] Lección 7: renderizar en React, probar con Playwright
- [ ] Lección 8: pasar GA de VexFlow 4 a 5

## QA

Lo que el curso encontró en el software que enseña, y en el código de Guitar Alchemist que lo usa. Los enlaces a VexTab apuntan a [`3a5e00d`](https://github.com/0xfe/vextab/tree/3a5e00d858ae98934ba545f9bef5eb923e17e402), el commit a partir del cual se construyó el 4.0.5 de npm; los de VexFlow a [`0ca6f88`](https://github.com/vexflow/vexflow/tree/0ca6f889545c33cce851b420c24945f6eb685aeb), el 5.0.0 que incluye; los de GA a [`17ccee6`](https://github.com/GuitarAlchemist/ga/tree/17ccee6885851e4b460ebd14d7f4cfb838f5541e). Cada medida es una salida de `check.sh`, comparada en CI. Todavía no se ha comunicado nada a los proyectos; una búsqueda en las issues de VexTab y de VexFlow no encontró ningún informe previo de estos puntos.

| Lo esperado | Lo que pasa | Dónde | Medida | Estado |
|---|---|---|---|---|
| `strings=4` dimensiona el dibujo para cuatro líneas de tablatura | La opción sigue siendo una cadena; VexFlow calcula la altura del pentagrama como `("4" + 4) * 13` | [`StaveBuilder.ts:141`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/StaveBuilder.ts#L141), [`VexTabParser.ts:86-89`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/vextab/VexTabParser.ts#L86-L89), VexFlow [`stave.ts:142`](https://github.com/vexflow/vexflow/blob/0ca6f889545c33cce851b420c24945f6eb685aeb/src/stave.ts#L142) | Dibujo de 712 px de alto para `strings=4`, 842 para 5, 1102 para 7, frente a 270 para seis cuerdas; lo mismo en Chrome | Reproducido con Node y en Chrome ([lección 3](../03-keys-time-tunings/#el-número-de-cuerdas)) |
| `$G$` después de un acorde dibuja el texto G | Cualquier texto que coincida con un nombre de nota sustituye el número de traste de la cuerda más grave del acorde, y no se dibuja ninguna anotación | [`ArticulationBuilder.ts:362`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArticulationBuilder.ts#L362), [`:461`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArticulationBuilder.ts#L461) | `$G$ $C$ $D$` sobre tres acordes: 0 anotaciones, 3 números de traste sustituidos; `$.big.G$` y `$D $` se dibujan como texto | Reproducido. Documentado como una función para notas sueltas; una trampa para los nombres de acorde ([lección 2](../02-guitar-techniques/#anotaciones)) |
| `$.italic.let ring$` está en cursiva | VexTab pasa el estilo como tercer argumento de VexFlow 5, el grosor | [`ArticulationBuilder.ts:298-302`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArticulationBuilder.ts#L298-L302), VexFlow [`element.ts:392`](https://github.com/vexflow/vexflow/blob/0ca6f889545c33cce851b420c24945f6eb685aeb/src/element.ts#L392) | El SVG dice `font-weight="italic"`, sin `font-style` | Reproducido |
| El logotipo `vexflow.com` está centrado y en cursiva | Se mide antes de fijar su fuente, así que se coloca con el ancho de la fuente equivocada, y sale recto por la misma razón que arriba | [`ArtistRenderer.ts:262-266`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArtistRenderer.ts#L262-L266) | x = 187,78 en un dibujo de 600 px con notación (Chrome: 188,52), | Reproducido con Node y en Chrome (H2) |
| `X/6` es una nota apagada en la cuerda 6 | El analizador léxico lee `X` como un nombre de nota, así que 6 pasa a ser una octava: la notación dibuja una cabeza de nota en x donde iría si6, en y = 0, medio fuera del dibujo | [`vextab.jison:84`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/vextab.jison#L84), [`NoteBuilder.ts:264-266`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/NoteBuilder.ts#L264-L266) | Misma posición en Chrome, a menos de 0,67 px | Reproducido con Node y en Chrome (H3). La tablatura es correcta |
| La afinación `eb` de VexFlow es la estándar medio tono más baja | La cuerda 6 es `Db/3`, un tono más baja | VexFlow [`tuning.ts:16`](https://github.com/vexflow/vexflow/blob/0ca6f889545c33cce851b420c24945f6eb685aeb/src/tuning.ts#L16) | La cuerda 6 al aire se dibuja como do♯3 (escrito), donde se quería mi♭3; la línea no ha cambiado en `main` de VexFlow | Reproducido ([lección 3](../03-keys-time-tunings/#afinaciones)) |
| `V` dibuja un vibrato áspero | VexTab llama a `setHarsh` solo si existe, y el `Vibrato` de VexFlow 5 no lo tiene | [`ArticulationBuilder.ts:635-640`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArticulationBuilder.ts#L635-L640), VexFlow [`vibrato.ts`](https://github.com/vexflow/vexflow/blob/0ca6f889545c33cce851b420c24945f6eb685aeb/src/vibrato.ts#L86) | `7v` y `8V` dibujan los mismos tres glifos U+EAB0 | Reproducido |
| Cinco negras en un compás de 4/4 se rechazan | Se dibujan: las voces de VexTab están en modo soft | [`ArtistRenderer.ts:67`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArtistRenderer.ts#L67) | `l01-overfull` se renderiza | Reproducido. Deliberado, por lo que dice el código ([lección 1](../01-first-stave/#duraciones-y-barras-de-compás)) |
| Los bloques `vextab` del chatbot de GA son VexTab | Usan un formato de tokens de GA, `string/fret`, sin `tabstave` ni `notes` | GA [`PlayableNotationFormatter.cs:15-25`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.ML/Notation/PlayableNotationFormatter.cs#L15-L25), [`:59-71`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.ML/Notation/PlayableNotationFormatter.cs#L59-L71) | 12 de 12 bloques (8 acordes para principiantes, el ejemplo del prompt, 3 pruebas e2e) rechazados por VexTab 4.0.5 y por el parser F# de GA | Reproducido, no comunicado a GA ([lección 4](../04-ga-chatbot-vextab/#los-resultados)) |
| El cliente de chat de GA dibuja los bloques `vextab`, como afirma su prueba e2e | `MemoizedVexTab` los imprime en un `<pre>` | GA [`MemoizedVexTab.tsx:11-28`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Apps/ga-client/src/components/Chat/MemoizedVexTab.tsx#L11-L28), [`vextab-rendering.spec.ts:94-99`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Apps/ga-client/tests/e2e/vextab-rendering.spec.ts#L94-L99) | Leído, no ejecutado; la prueba unitaria es `it.skip` | Leído en el código, no ejecutado. Si la especificación e2e se ejecuta en la CI de GA está *por verificar* |
| El campo de traza `notation.renderer` de GA dice qué dibujó la notación | Es la constante `"vexflow"` | GA [`OrchestratedChatApplicationService.cs:336`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs#L336) | 45 trazas de referencia: 44 con `added_count` 0, una con 8 | Leído en el código y en las trazas |
| El parser F# de GA lee lo que escribe su generador, y los ejemplos de su gramática | `str`, `ch` y `pint` se comen el espacio en blanco que los sigue, incluido el espacio con el que empieza la siguiente opción de tabstave | GA [`VexTabParser.fs:22-29`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.DSL/Parsers/VexTabParser.fs#L22-L29), [`:330`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.DSL/Parsers/VexTabParser.fs#L330) | La ida y vuelta falla en la columna 51 o 52 para 6 de 6 textos analizables; 0 de 4 ejemplos EBNF se analizan | Reproducido con los archivos de GA compilados sin cambios, no comunicado a GA |
| El parser F# de GA acepta VexTab | Difiere en las técnicas (después de la cuerda), los bemoles (`b`), las duraciones en mitad de línea, las series de trastes, los taps, las anotaciones y las tonalidades menores | GA [`VexTabParser.fs:85`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.DSL/Parsers/VexTabParser.fs#L85), [`:239-244`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.DSL/Parsers/VexTabParser.fs#L239-L244), [`:413-420`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.DSL/Parsers/VexTabParser.fs#L413-L420) | De 32 textos, el parser de GA acepta 6 y VexTab 17; coinciden en «ok» en 4 | Reproducido, no comunicado a GA |

## Experimentos

| Pregunta | Hipótesis, escrita antes de medir | Resultado | Veredicto |
|---|---|---|---|
| ¿El renderizado sin navegador (jsdom, texto medido con opentype.js) coloca los glifos donde lo hace Chrome? | H1: a menos de 1,0 px en x y en y para cada elemento de texto de `l01-notation`, `l02-chords` y `l03-keys`, si Chrome carga Bravura y Academico ([`hypotheses.md`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/results/hypotheses.md), confirmado en `284eb7e` antes de cualquier ejecución en el navegador) | 157 elementos de texto en cinco dibujos: \|dx\| máx. 0,74 px, \|dy\| máx. 0,67 px, tamaños iguales ([`browser-2026-09-24.txt`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/results/browser-2026-09-24.txt)). Las dos primeras ejecuciones estaban mal, mira [la entrada](#2026-09-24--sin-navegador-frente-a-chrome) | Confirmada |
| ¿El logotipo descentrado es un artefacto del entorno sin navegador? | H2: Chrome lo dibuja con una x a menos de 1 px de 187,78. No a ciegas | Chrome: 188,52 | Confirmada |
| ¿Chrome también dibuja `X/6` en la octava 6? | H3: sí, en la misma y. No a ciegas | Misma posición, dentro de los 0,67 px de arriba | Confirmada |
| ¿El dibujo de 712 px de `strings=4` es un artefacto de jsdom? | H4: el SVG de Chrome mide 712 px de alto. No a ciegas | 600 × 712 | Confirmada |

## 2026-09-24 — Qué VexTab, qué VexFlow

El `vextab` 4.0.5 de npm se publicó el 2026-01-18; sus fuentes son idénticas al commit `3a5e00d` de `0xfe/vextab` (comprobado archivo por archivo con SHA-1). Su `dist/main.prod.js` incluye VexFlow 5.0.0, `Vex.Flow.BUILD.ID` `0ca6f889…`, y recrea encima el espacio de nombres `Vex.Flow` de VexFlow 4. Instalar `vexflow` a su lado no cambia nada para VexTab; el curso fija `vexflow` 5.0.0 de todos modos, para la lección 5. GA, en cambio, usa VexFlow `^4.2.5`, y distribuye un `vexflow.js` 4.2.5 para la API de su chatbot.

## 2026-09-24 — Renderizar sin navegador

El bundle quiere `window`, `self`, `document` y `getComputedStyle`; jsdom se los da. Lo que no da es la medición de texto: VexFlow mide cada glifo con un canvas. Primer intento, node-canvas 3.2.3 con `registerFont` sobre los archivos OTF de Bravura y Academico: en Windows no carga estas fuentes de tipo CFF y mide en silencio con una fuente sans-serif de reserva. Sustituido por un pequeño contexto que mide con [opentype.js](https://opentype.js.org/) a partir de los mismos archivos OTF ([`lib/env.cjs`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/lib/env.cjs)), pasado a VexFlow con `Element.setTextMeasurementCanvas`. La salida es la misma en los tres sistemas operativos de la CI, así que los SVG pueden compararse byte a byte tras renumerar los identificadores y redondear a dos decimales.

## 2026-09-24 — Sin navegador frente a Chrome

Hipótesis escritas y confirmadas primero en un commit (`284eb7e`). Después, los mismos cinco archivos pasados por el bundle de navegador en Chrome 153 sin interfaz, releyendo cada `<text>` ([`browser/`](https://github.com/spareilleux/learn/tree/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/browser)).

La primera ejecución dio una diferencia de 204 px en el logotipo y glifos ilegibles: la página de prueba no tenía `<meta charset="utf-8">`, Chrome decodificó el bundle como Windows-1252, y cada punto de código SMuFL se convirtió en caracteres corruptos. Un error de medición, no un resultado. La segunda ejecución estaba desfasada en un elemento en `l02-vibrato-mute`: `compare.mjs` omitía los elementos `<text>` sin atributo `y`, y VexFlow no escribe ninguno cuando y vale 0, que es el caso del glifo de la nota apagada. Corregido leyendo cada atributo por separado, con uno ausente como 0. La tercera ejecución es la de la tabla: 0,74 px como mucho, en el logotipo.

## 2026-09-24 — El VexTab de GA, ejecutado

Clon parcial (sin blobs, disperso) de GA en `17ccee6`, nueve archivos. El formateador C# compila por separado; los tres archivos F# compilan sin cambios con FParsec 1.1.1 sobre .NET 10, como lo referencia GA. Resultados en la [lección 4](../04-ga-chatbot-vextab/). Lo que esperaba al empezar: que los bloques del chatbot usaran un dialecto antiguo de VexTab. Lo que salió: no usan ningún dialecto de VexTab, el cliente no los dibuja, y el propio parser de GA rechaza la salida de su propio generador. VexTab, mientras tanto, lee sin problemas la salida del generador de GA. No se ha enviado nada a GA: los hallazgos están en el informe para el usuario, que decide.

## Por verificar

- Si las especificaciones Playwright de `ga-client` se ejecutan en la CI de GA; si lo hacen, `vextab-rendering.spec.ts` debería fallar en `not.toBeVisible()`. No se ejecutaron aquí.
- La afinación `eb` en un navegador: el valor está en la tabla de VexFlow y el dibujo sin navegador muestra do♯3, pero la comparación con el navegador no incluía `l03-tuning`.
- Firefox y Safari: la comparación con el navegador solo se hizo en Chrome sin interfaz, en Windows.
- Si VexFlow 4, tal como lo usa GA, tiene el orden de argumentos de `setFont` que hacía de `italic` un estilo en él: no comprobado, ya que el curso fija VexFlow 5.

## Preguntas abiertas

- ¿La sustitución del traste por anotaciones con nombre de nota debe aplicarse a los acordes, o solo a las notas sueltas? El código la aplica a la cuerda más grave de cualquier grupo de notas.
- ¿Debería VexTab convertir `strings=` en número y pasar el número? Ya existe un `parseInt`, una línea por encima de la que lo olvida.
