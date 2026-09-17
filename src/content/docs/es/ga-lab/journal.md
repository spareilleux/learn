---
title: Diario
description: Notas fechadas del Laboratorio Guitar Alchemist — de dónde vienen los datos de cada prototipo, las hipótesis escritas antes de medir, lo que dijeron las mediciones, y lo que hace de verdad el código de GA.
sidebar:
  order: 99
---

## Avance

- [x] Esqueleto del laboratorio: misión, plan de siete prototipos, workflow de CI
- [x] P1, explorador del espacio de voicings: paso de construcción, página, mediciones, lección
- [x] P2, toca un acorde, mira el universo
- [ ] P3, portadas de álbum
- [ ] P4, pasada de render con IA
- [ ] P5, pulseras imprimibles en 3D
- [ ] P6, cadena completa
- [x] P7, modelo de tocabilidad

## QA

Lo que el laboratorio encontró en GuitarAlchemist/ga midiendo, no leyendo. Los números de línea apuntan a [`66bdd049`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e), el commit desde el que se exportó el índice. Ninguno de estos puntos es todavía un informe de error: es lo que mostraron las mediciones.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| El índice y los dos `FretDiagram` coinciden en qué cuerda va primero | El índice escribe el diagrama con el mi agudo primero; ambos render lo leen con el mi grave primero | [`FretDiagram.cs:14`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Agents/FretDiagram.cs#L14), [`FretDiagram.tsx:8-11`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/ReactComponents/ga-react-components/src/components/FretDiagram.tsx#L8-L11) | La fila 1000 da `1-2-x-5-x-1` para las notas MIDI 65, 61, 55, 41; 30 000 filas muestreadas se leen con el mi agudo primero, 0 discrepancias | Reproducido, corrección en preparación |
| El `FretDiagram` de React muestra todas las notas pisadas | Pierde un punto cuando la rejilla empieza en la cejuela y el voicing llega a un traste más allá de la última fila | [`FretDiagram.tsx`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/ReactComponents/ga-react-components/src/components/FretDiagram.tsx#L31), líneas 31 y 104 | 15 853 voicings de guitarra de 297 910, el 5,32 % | Reproducido, corrección en preparación |
| El resumen de `OptickIndexReader` describe los vectores que devuelve | Dice «L2-normalized»; cada partición se normaliza y luego se multiplica por la raíz cuadrada de su peso | [`OptickIndexReader.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Search/OptickIndexReader.cs) | Norma al cuadrado de 1,15 o 1,05, nunca 1 | Reproducido. La documentación es falsa, el comportamiento es correcto: el producto escalar da el coseno ponderado por partición que la búsqueda necesita |
| Dos voicings que suenan y se digitan distinto son dos puntos | Los voicings con las mismas clases de altura, la misma nota aguda y una forma parecida colapsan en un solo vector | [`OptickIndexWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) | 121 768 vectores de guitarra de 297 910 son copias bit a bit de otro, el 40,9 %; el grupo mayor contiene 12 voicings de fa sostenido disminuido con la arriba | Reproducido. Consecuencia del embedding más que defecto evidente — hay que arbitrarlo antes de cambiar nada |
| El mismo commit exporta el mismo índice | La deduplicación conserva el voicing más barato de cada grupo, la generación es paralela y los empates van al primero que llega | [`OptickIndexWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) | Dos exportaciones de una misma compilación: todos los vectores comunes idénticos, 70 voicings presentes en una y ausentes de la otra | Reproducido. Lo que fija los datos es el hash del archivo, no el commit |
| `--export-max N` muestrea el índice | La opción conserva los N primeros voicings en bruto en orden de generación, que empieza alto en el mástil | [`OptickIndexWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) | `--export-max 3000` produjo 2 641 vectores, 0 de ellos en el índice completo | Reproducido. Una exportación parcial no puede verificar una completa |
| Un acorde con bajo nombra su bajo con la grafía de la tonalidad | Algunos nombres usan la enarmonía equivocada, por ejemplo `Gmaj7/Gb` en vez de `Gmaj7/F♯` | nombres de acordes del índice | Visto al leer los mayores grupos de duplicados | Reproducido, aún sin contar |
| `barreRequired` es verdadero para un acorde con cejilla | Pide el mismo traste en tres cuerdas *adyacentes*, así que la cejilla de fa en forma de mi `133211` — cuerdas 1, 2 y 6 en el traste 1 — no es una cejilla, mientras que la forma de la `x13331` sí lo es | [`VoicingPhysicalAnalyzer.cs:219-233`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingPhysicalAnalyzer.cs#L219-L233) | `133211` y el `xx3211` de cuatro cuerdas salen ambos a exactamente 4.50 | Reproducido (P7) |
| `minimumFingers` cuenta dedos | Cuenta *trastes distintos*, con tope en 4 | [`VoicingPhysicalAnalyzer.cs:102-103`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingPhysicalAnalyzer.cs#L102-L103) | Am `x02210` y Am7 `x02010` salen ambos a 2.29; lo mismo para E frente a E7 y D frente a Dsus4 | Reproducido (P7) |
| La etiqueta `Difficulty` y el `DifficultyScore` coinciden | El rango «Beginner» de la etiqueta pide una separación de como mucho 64 mm, menos de dos trastes junto a la cejuela, así que el acorde de do al aire es «Intermediate»; y `141404`, etiquetado «Advanced», sale a 4.65, el percentil 26 del índice | [`VoicingPhysicalAnalyzer.cs:105-112`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingPhysicalAnalyzer.cs#L105-L112) | 3.50 y «Intermediate» para `x32010` | Reproducido (P7) |
| Un voicing que nadie puede tocar obtiene una puntuación alta | 101 967 voicings de guitarra de 297 883 (34.2 %) no tienen ninguna digitación legal bajo un modelo de mano de cuatro dedos, y la puntuación más alta que GA da a uno de ellos es 7.73, dentro del rango de los acordes corrientes, así que `maxDifficulty: 8` los devuelve | [`VoicingFilterService.cs:53-70`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Apps/ga-server/GaApi/Services/VoicingFilterService.cs#L53-L70) | La búsqueda de [`fingering.mjs`](https://github.com/spareilleux/learn/blob/main/code/ga-protos/p7-playability/src/lib/fingering.mjs) sobre todo el índice | Reproducido (P7). El modelo de mano es mío y no tiene pulgar, así que el 34.2 % es una cota superior |

## Experimentos

Cada prototipo escribe sus hipótesis antes de que exista el script de medición, y se commitean primero. Una hipótesis refutada se queda aquí: es el resultado que más caro costó.

| Pregunta | Hipótesis, escrita antes de medir | Resultado | Veredicto |
|---|---|---|---|
| ¿Cuántas dimensiones necesita de verdad el espacio de voicings? | Commiteadas en [`hypotheses.md`](https://github.com/spareilleux/learn/blob/03f2bbb/code/ga-protos/p1-voicing-explorer/results/hypotheses.md) en `03f2bbb`; el archivo dice cuál no era ciega | 3 componentes explican el 22,2 % de la varianza, 10 el 48,0 %, 32 el 84,7 %, 64 el 99,9 % | Los dos primeros ejes son sobre todo MORPHOLOGY, el tercero STRUCTURE, CONTEXT no pesa nada (2026-09-17) |
| ¿Una vista 3D conserva los vecinos que encuentra la búsqueda exacta? | H2 fijaba un umbral de recall@10 de 0,15; H3 predecía que el índice completo sería peor que la muestra | Recall@10 de 0,168 dentro de la muestra de 30 000, 0,348 sobre todos los voicings de guitarra; con 32 componentes, 0,693 y 0,787 | H2 falló su umbral, H3 se equivocó — ambas refutadas (2026-09-17) |
| ¿WebGPU es más rápido que WebGL 2 para 300 000 puntos? | Una primera serie decía 3,5 ms frente a 0,5 ms y parecía un hallazgo | Con `trackTimestamp`, la pasada de render tarda 0,066 ms en WebGPU y 0,071 ms en WebGL 2 con 30 000 puntos, 0,26 ms con los 297 910, 2,3 ms con 3 millones de puntos aleatorios | La primera serie era un error de medición: los 3,5 ms son lo que tarda `onSubmittedWorkDone` en resolverse, no trabajo de GPU. La lección cita la segunda serie (2026-09-17) |
| ¿La selección en CPU aguanta al tamaño del índice completo? | H6 esperaba más de 16 ms con 297 910 puntos | 0,2 ms para 30 000, 1,4 ms para 297 910, 14 ms para 3 millones | H6 refutada (2026-09-17) |
| ¿Puede el navegador con el índice entero? | — | 156 MB cargados y decodificados en 341 ms, 180 MB de heap de JavaScript, 28 ms para encontrar los diez vecinos exactos | Sí, y la lección entrega ese modo (2026-09-17) |
| ¿Un cromagrama en una página puede nombrar el acorde que tocas? | Ocho cifras predichas antes de grabar nada | El 79,3 % de los 624 rasgueos sintéticos nombrados exactamente — 89,1 % en estado fundamental, 50 % en las inversiones — y 11 de las 17 grabaciones CC0; estimar las notas antes del cromagrama valía 39 puntos | Siete de las ocho cifras se sostuvieron; el oráculo, las condiciones de ruido y los fallos grabados, no (2026-09-17) |
| ¿Puede un modelo pequeño entrenado en un solo núcleo de CPU superar el coste de tocabilidad escrito a mano de GA? | Doce cifras commiteadas en [`hypotheses.md`](https://github.com/spareilleux/learn/blob/c6a9937/code/ga-protos/p7-playability/results/hypotheses.md) en `c6a9937` | El boosting de gradiente alcanza un Spearman de 0.964 contra el objetivo y un acierto por pares de 0.921, donde la puntuación de GA alcanza 0.596 y 0.715; una recta de mínimos cuadrados sobre la separación física sola alcanza 0.794 | Sí, pero el hallazgo es que los tres indicadores extra de GA le cuestan más de lo que le aportan (2026-09-17) |
| ¿Cuántos de los voicings de guitarra de GA pueden tocar cuatro dedos? | H11: más del 98 % | El 65.8 %: la búsqueda no encuentra ninguna digitación legal para 101 967 de 297 883 | Gravemente refutada, y partió el prototipo en dos: una tarea de ordenación sobre lo que se puede tocar, una pregunta de sí o no sobre el resto (2026-09-17) |
| ¿Separar por voicing en lugar de por acorde favorece al modelo? | H6: la separación ingenua sobrestima los árboles potenciados en 0.005 a 0.05 de Spearman | 0.0005; la separación por forma transportada lo mueve 0.002 | Refutada. La separación por grupo solo cuesta algo cuando el grupo lleva información que las variables no tienen, y aquí ambos lados se leen en el mismo diagrama (2026-09-17) |
| ¿Es la búsqueda de digitación lo bastante cara como para valer la pena sustituirla por un modelo? | H12: el modelo puntúa un voicing al menos 50 veces más rápido | 3.8 veces: 0.0145 ms frente a 0.0558 ms | Refutada. La premisa del prototipo era falsa; lo que el modelo compra son 949 kB que se embarcan sin el modelo de mano (2026-09-17) |

## 2026-09-16 — P1: de dónde vienen los datos

- La rama `main` de GA estaba en [`66bdd049`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e) («chore(quality): snapshot 2026-09-16»). El índice no está en el repositorio: `FretboardVoicingsCLI --export-embeddings` lo genera en `state/voicings/optick.index`.
- No lo reconstruí. La sesión que mide el rendimiento de GA había compilado `FretboardVoicingsCLI` en un clon limpio en ese commit y exportado el índice entre las 23:00 y las 23:02, hora local, en 149 segundos. Su registro dice «688,351 raw, 313,047 unique». Copié ese archivo y lo fijé por su huella: 183.770.270 bytes, SHA-256 `1e91e4695bab8aa4bb451fdd1f199a4afaa4c4ad913f08acc5163c6ab07caa23`, 313.047 voicings (297.910 de guitarra, 7.795 de bajo, 7.342 de ukelele), 124 dimensiones, huella de esquema `0x37cd8ecf`, la que da mi CRC-32 de `EmbeddingSchema.CompactLayoutV4`.
- La fila 1000 resuelve el orden de las cuerdas. Su diagrama es `1-2-x-5-x-1` y sus notas MIDI son 65, 61, 55, 41: se lee primero la cuerda 1 (mi agudo + 1 = fa 4, 65), no el mi grave. En un diagrama de acordes, esa forma se escribe `1x5x21`. El paso de construcción comprueba del mismo modo las 30.000 filas de la muestra: 0 discrepancias.
- GA no está de acuerdo consigo mismo en esto. [`FretDiagram.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Agents/FretDiagram.cs#L14) y el componente React [`FretDiagram.tsx`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/ReactComponents/ga-react-components/src/components/FretDiagram.tsx#L8-L11) toman los trastes con el mi grave primero; el índice los escribe con el mi agudo primero. El [curso sobre la IA de GA](../../ga-ai/02-optic-k-embeddings/) encontró la misma divergencia en el ejemplo de una herramienta MCP.
- Los vectores del índice no tienen longitud 1, aunque el resumen de `OptickIndexReader` dice «L2-normalized»: cada partición se normaliza y luego se multiplica por la raíz cuadrada de su peso, de modo que el cuadrado de la longitud de un vector es la suma de los pesos de sus particiones no vacías, 1,15 o 1,05. El producto escalar sigue siendo el coseno ponderado por partición, que es lo que necesita la búsqueda.

## 2026-09-16 — P1: hipótesis

- Escritas en [`results/hypotheses.md`](https://github.com/spareilleux/learn/blob/03f2bbb/code/ga-protos/p1-voicing-explorer/results/hypotheses.md) y confirmadas en el commit `03f2bbb`, antes de que existiera el script de medición.
- Una de ellas no es ciega, y el archivo lo dice: una prueba rápida del paso de construcción con 2.000 voicings ya había mostrado que tres componentes explican el 22,2 % de la varianza.

## 2026-09-17 — P1: mediciones

- Tres componentes principales explican el 22,2 % de la varianza, diez el 48,0 %, 32 el 84,7 %, 64 el 99,9 %. Los dos primeros ejes son sobre todo MORPHOLOGY, el tercero STRUCTURE; CONTEXT no pesa nada.
- Exhaustividad a 10 de la vista 3D frente a los vecinos exactos: 0,168 dentro de la muestra de 30.000, 0,348 frente a todos los voicings de guitarra. Con 32 componentes: 0,693 y 0,787. H2 no alcanzó su umbral de 0,15; H3, que predecía un resultado peor en el índice completo, era falsa.
- 121.768 de los 297.910 vectores de guitarra son copias bit a bit del vector de otro voicing. El grupo más grande reúne 12 voicings de fa sostenido disminuido con la arriba. Voicings con las mismas clases de altura, la misma nota aguda y una forma parecida son el mismo punto para OPTIC-K.
- El componente React `FretDiagram` de GA pierde un punto en 15.853 voicings de guitarra (5,32 %): la cuadrícula empieza en la cejuela cuando la nota pisada más baja está en el traste 2, y un voicing que llega al traste 6 necesita una sexta fila.

## 2026-09-17 — P1: dos exportaciones, un solo commit

- La sesión de rendimiento exportó el índice una segunda vez con la misma compilación. Emparejando por instrumento y diagrama, cada vector común es idéntico, pero faltan en una exportación 70 voicings de la otra: la deduplicación conserva el voicing más barato de cada grupo, el generador corre en paralelo, y a igual coste gana el primero que llega. Es la huella del archivo la que fija los datos, no el commit.
- Intenté confirmar la procedencia regenerando 3.000 voicings de guitarra con la herramienta de GA (`--export-max 3000`, 4,1 s bajo el cerrojo de trabajos pesados). Ninguno de sus 2.641 vectores está en el índice completo. El límite conserva los 3.000 primeros voicings brutos en orden de generación, que empezaba en el traste 19; dentro de ese conjunto pequeño, la deduplicación conservó voicings altos en el mástil, que pierden frente a formas más baratas en la exportación completa. Una exportación parcial no puede comprobar una completa.

## 2026-09-17 — P1: tiempos de fotograma, medidos dos veces

- Primera serie: `render()` más `onSubmittedWorkDone`, 120 fotogramas a 1280 × 720 en Chromium 153 sin interfaz, con la RTX 5080. WebGPU daba 3,5 ms para 30.000 puntos y WebGL 2 0,5 ms. Parecía un hallazgo, y era un error de medición: la cifra de WebGPU no cambiaba entre 30.000 y 3 millones de puntos.
- Segunda serie, con `trackTimestamp` y `resolveTimestampsAsync` de three.js: la pasada de render tarda 0,066 ms en WebGPU y 0,071 ms en WebGL 2 para 30.000 puntos, 0,26 ms para los 297.910, 2,3 ms para 3 millones de puntos aleatorios. Los 3,5 ms son lo que tarda `onSubmittedWorkDone` en resolverse, no trabajo de la GPU.
- `renderer.info.render.drawCalls` mostraba 434 y después valores negativos en la sonda, porque three.js lo pone a cero en cada fotograma de animación y la sonda espera de un fotograma a otro. La lección no lo cita.
- La selección proyectando cada punto en la CPU: 0,2 ms para 30.000, 1,4 ms para 297.910, 14 ms para 3 millones. H6 esperaba más de 16 ms para 297.910.
- Modo local con el índice completo: 156 MB cargados y decodificados en 341 ms, 180 MB de montón JavaScript, 28 ms para encontrar los diez vecinos exactos de un voicing en el navegador.

## 2026-09-17 — P1: publicación

- El sitio aún no tenía una cadena para demos en vivo. `scripts/publish.mjs` construye la página con Vite (`base: './'`) en `public/ga-lab/p1/`, que Astro copia tal cual: 3,65 MB, más una captura de pantalla de 241 KB. La lección muestra la captura y un botón, y solo carga la página en un iframe al hacer clic, mediante un pequeño componente `LazyDemo` que añade la ruta base del sitio.
- `scripts/check-published.mjs` sirve `public/` bajo `/learn/` como GitHub Pages y abre la página publicada: WebGPU, 30.000 puntos, ningún error.

## 2026-09-17 — P2: toca un acorde, mira el universo

- **P2 publicado.** El reconocedor nombra exactamente el 79,3 % de 624 rasgueos sintéticos (89,1 % en estado fundamental, 50 % en inversiones) y 11 de 17 grabaciones CC0; estimar las notas antes del cromagrama vale 39 puntos. Siete de ocho cifras previstas se cumplieron; el oráculo, las condiciones de ruido y los fallos grabados no. El sonido nunca sale de la página (connect-src 'none'). [Lección](../02-chord-universe/)

## 2026-09-17 — P7: la etiqueta que no existe

- La pregunta es si un modelo supera al `DifficultyScore` de GA, y la puntuación de GA no puede ser a la vez el solucionario. Por eso P7 construye un objetivo: [`fingering.mjs`](https://github.com/spareilleux/learn/blob/main/code/ga-protos/p7-playability/src/lib/fingering.mjs) enumera todas las formas legales de poner los dedos 1 a 4 sobre las notas pisadas — cualquier dedo puede hacer cejilla, una cejilla puede sujetar parte de un traste y pasar por debajo de notas más altas — y se queda con la más barata. La geometría de trastes y cuerdas es la de GA; cada peso es una constante que elegí yo y que está listada en `WEIGHTS`.
- Tres comprobaciones sobre ese objetivo, y ninguna es una demostración: 32 juicios por parejas sobre formas canónicas en [`annotations.json`](https://github.com/spareilleux/learn/blob/main/code/ga-protos/p7-playability/results/annotations.json), cuyo anotador está nombrado en el fichero (este modelo, a partir de reglas escritas, no un guitarrista); una lista de lo que dicen los métodos; y la propia puntuación de GA. La búsqueda coincide con las 25 parejas de confianza alta de 25, GA con 22, la lista con 19. La puntuación perfecta de la búsqueda mide coherencia interna — la misma cabeza escribió el modelo de mano y el protocolo — y el fichero lo dice.
- Leer las cinco líneas de GA antes de medir nada encontró cuatro cosas, todas en la tabla de QA de arriba: el indicador de cejilla falla con la cejilla de fa, `minimumFingers` cuenta trastes, una cejilla completa y un fa de cuatro cuerdas salen con la misma puntuación, y la etiqueta `Difficulty` contradice al `DifficultyScore`.

## 2026-09-17 — P7: hipótesis

- Doce predicciones numeradas en [`results/hypotheses.md`](https://github.com/spareilleux/learn/blob/c6a9937/code/ga-protos/p7-playability/results/hypotheses.md), commiteadas en `c6a9937` antes de que `train.mjs` se hubiera ejecutado sobre dato alguno, sintético o real.
- H0 está marcada como «vista, no ciega»: la comprobación de las anotaciones ya se había ejecutado cuando se escribió el fichero, y sus tres números constan allí como mediciones, no como predicciones. No se movieron cuando después se generalizó la búsqueda.

## 2026-09-17 — P7: lo que la búsqueda rechaza

- La primera versión de la búsqueda solo dejaba hacer cejilla al índice, y solo sobre todas las notas del traste más bajo. Rechazaba el 61.9 % del índice de guitarra. Al dejar que cualquier dedo haga cejilla, sobre parte de un traste, pasando por debajo de notas más altas, se baja al 34.2 % — 101 967 voicings de 297 883 sin ninguna digitación legal.
- Lo que queda es realmente intocable: `x12345` necesita cinco dedos en cinco trastes, y `103212` tiene dos notas en el traste 1 a ambos lados de una cuerda al aire, así que ninguna de las dos cejillas que haría falta es posible.
- Esas filas no tienen rango, así que el experimento se parte en dos: la tarea de ordenación las descarta, y un segundo modelo responde a si un voicing se puede digitar siquiera. Separando por acorde, el boosting de gradiente alcanza un acierto de 0.903 frente a una referencia mayoritaria de 0.663, y un AUC de 0.973; la puntuación de GA, leída como ordenación para la misma pregunta, alcanza 0.677.

## 2026-09-17 — P7: mediciones

- Un núcleo de un Intel Core Ultra 9 285K, Node.js v24.12.0, sin GPU, sin dependencias. 297 883 voicings, 195 916 de ellos digitables, separados por acorde en 118 243 / 38 287 / 39 386. La ejecución completa — tres separaciones, seis predictores cada una, intervalos por bootstrap de 200 vueltas remuestreados por acorde, y el modelo de viabilidad — tardó 302 segundos; construir el conjunto de datos desde el índice de 183 MB tardó 7.8 segundos.
- Spearman contra el objetivo, filas reservadas: boosting de gradiente 0.964, MLP 0.959, bosque aleatorio 0.957, ridge 0.906, una recta sobre la separación física sola 0.794, la puntuación de GA 0.596, la lista de reglas 0.449, la media 0. Acierto por pares entre acordes: 0.921 frente al 0.715 de GA.
- Los árboles potenciados ponen 0.723 de su ganancia en `diagonalMm`, la pareja de notas pisadas más ancha medida *a través* de las cuerdas además de a lo largo del mástil — y no la separación a lo largo del mástil de GA, que retiene 0.028. El indicador de cejilla de GA retiene 0.011; el modelo reconstruye las cejillas a partir de `maxAtMinFret`, que cuenta las cuerdas del traste más bajo sin preguntar si son adyacentes, exactamente la prueba que el indicador de GA falla.
- Tamaños: 949 kB para 300 árboles potenciados, 11.9 MB para 60 árboles de bosque profundos, 15.4 kB para el MLP, 1.24 kB para la ridge.
- Cuatro predicciones falsas (H2, H6, H11, H12), dos acertadas a medias (H9, H10). [Lección](../07-playability-model/)
- Un fallo que conviene recordar, encontrado por una separación que fallaba: el primer hash de grupo era un FNV-1a simple, cuyos bits altos apenas se mueven entre `chord0` y `chord39`. Una separación lee precisamente esos bits altos, así que los cuarenta acordes acababan en el conjunto de entrenamiento y el de prueba salía vacío. Un finalizador murmur3 lo arregló, y ahora una prueba comprueba que los tres lados reciben 60/20/20 de tres mil claves casi idénticas.

## Por verificar

- El explorador en Safari y Firefox en macOS, con y sin WebGPU: probado solo en Chromium en Windows.
- El sonido en navegadores móviles, que pueden bloquear el `AudioContext` hasta un toque.
- El objetivo de P7: los 32 juicios por parejas los hizo este modelo a partir de reglas escritas, no un guitarrista, y las constantes del modelo de mano — separaciones cómodas, penalizaciones de cejilla y de apagado — están elegidas, no medidas sobre un intérprete. Un guitarrista ordenando unos cientos de parejas sustituiría a ambos.
- El 34.2 % de voicings no digitables de P7 es una cota superior: la búsqueda no tiene pulgar por encima del mástil, ni cuerda apagada con la mano izquierda, ni nota sujeta por dos dedos.
