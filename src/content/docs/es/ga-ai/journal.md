---
title: Diario
description: Notas de progreso fechadas — la fijación de GA, la compilación contra el host del chatbot sin conexión, las ejecuciones de CI y una condición de carrera del precalentamiento, y las diferencias encontradas entre el código de IA de Guitar Alchemist, sus comentarios y sus documentos.
sidebar:
  order: 99
---

## Progreso

- [x] Programa del curso: .NET 10, con referencias a `GA.Business.ML`, `FretboardVoicingsCLI` y `GaChatbot.Api` en un commit fijado
- [x] CI: la salida de cada lección se compara con su archivo esperado en tres sistemas operativos, sin modelo, sin clave de API y sin GPU
- [x] Lección 1: el mapa
- [x] Lección 2: embeddings OPTIC-K
- [x] Lección 3: el índice y la búsqueda
- [x] Lección 4: el chatbot y sus agentes
- [ ] Ejecutar el chatbot con Ollama y capturar lo que responden los agentes (con fecha, fuera de la CI)

## 2026-09-14 — Por qué este curso

La petición, el 2026-09-14: un curso sobre el índice OPTIC-K, sobre todo el código de aprendizaje automático y de agentes de GA, y sobre lo que el chatbot intenta conseguir. El curso está en *Aprendizaje automático*, junto a [IX](../../machine-learning-ix/): trata de construir y usar embeddings, un índice vectorial y un enrutador de tipo clasificador dentro de un producto, no de usar agentes de programación, que es lo que cubre *Desarrollo asistido por IA*.

## 2026-09-14 — Fijar GA y compilar contra el host del chatbot

- GA está fijado en [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit que usa el [curso de teoría musical](../../music-theory-ga/). El clon local del autor no se usa nunca: [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/fetch-ga.sh) hace un clon parcial sin blobs y disperso en `code/ga-ai/.ga`, ignorado por Git, excluyendo 17 carpetas de proyecto y los PDF de investigación de GA.
- En Windows, el primer checkout falló con rutas de más de 260 caracteres; `git config core.longpaths true` antes del checkout lo resuelve. Como en el curso de teoría musical, `MSYS_NO_PATHCONV=1` impide que Git Bash reescriba los patrones del checkout disperso.
- El proyecto del curso referencia directamente `GaChatbot.Api` y lo arranca con `WebApplicationFactory<Program>`. Hicieron falta dos detalles: un atributo de ensamblado, `WebApplicationFactoryContentRootAttribute`, que apunta a la carpeta del host dentro del clon ([`GaAi.csproj`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/GaAi/GaAi.csproj#L20-L28)); y ninguna instrucción de nivel superior en el programa del curso, cuya clase `Program` generada chocaría con la del host.
- La máquina del autor ejecuta Ollama. Sin intervenir, el host lo habría usado, y las salidas habrían sido distintas de las de la CI. El curso fija la dirección de Ollama en `http://127.0.0.1:9`, cerrada en la máquina del autor y en los runners.
- La memoria de chat de GA usa por defecto archivos bajo `~/.ga`. El curso registra su propio `MemoryStore` y su propio `ChatTranscriptStore` sobre una carpeta nueva junto al programa; se comprobó que `~/.ga` no cambia tras una ejecución.
- El primer corpus, 5 trastes y una ventana de 4, tenía 77.140 voicings y tardaba 33 segundos en calcular sus embeddings. 3 trastes y una ventana de 3 dan 15.360 voicings en unos 8 segundos, suficiente para cada punto de la lección 3.
- Los mensajes de excepción varían entre sistemas (errores de socket). La lección 4 solo imprime el tipo de excepción y el marco de GA más interno, `file:line`, sin duplicados y ordenados.
- Compilación local de los proyectos de GA y del curso: unos 23 segundos después de la primera restauración; una comprobación completa de las cuatro lecciones, 40 segundos.

## 2026-09-14 — CI

- Ejecución [34917150100](https://github.com/spareilleux/learn/actions/runs/34917150100), para el commit `43f009d`: las lecciones 1 a 3 pasaron en todas partes, y la lección 4 pasó en Windows y falló en Linux y macOS. En esos dos sistemas, los avisos del enrutador semántico de intenciones aparecían también bajo la primera petición.
- Causa: `IntentEmbeddingWarmupService` lanza en segundo plano el cálculo de los embeddings de las intenciones cuando arranca el host, y sus avisos caen en la petición que se esté ejecutando. Corrección en el commit [`8e335d7`](https://github.com/spareilleux/learn/commit/8e335d7): el curso espera la última línea de log del precalentamiento antes de enviar peticiones. La lección 4 cuenta la historia.
- Ejecución [34917602262](https://github.com/spareilleux/learn/actions/runs/34917602262), para `8e335d7`: en verde en los tres sistemas, 1 min 34 s en Linux, 1 min 50 s en macOS y 3 min 2 s en Windows, clon y compilación incluidos.

## 2026-09-14 — Diferencias encontradas en el código de GA (commit a826864)

Cada punto indica dónde lo muestra el programa del curso. Ninguno se ha comunicado a GA.

Embeddings (lección 2):

1. `VoicingDocumentFactory` asigna `RootPitchClass` y `MidiBassNote` a partir de `MidiNotes[0]` ([líneas 37-38](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L37-L38)). GA construye los voicings empezando por la cuerda 1 (E aguda), así que esa nota es la nota **más aguda**. ROOT, MODAL, el bajo de MORPHOLOGY y la inversión se calculan a partir de ella; el filtro de búsqueda usa `MidiNotes.Min()`, el bajo real. Lo muestran `l2`, "From a chord shape to GA's voicing document" (C abierto: fundamental E, inversión 1), y la búsqueda de Cmaj7 de `l3`.
2. La inversión compara esa nota con el nombre de la fundamental del acorde, leído por `PitchClass.Parse` ([líneas 43-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L43-L44)), que lee los nombres de nota como dígitos: `"A"` vale 10 y `"E"` vale 11. Un Em en estado fundamental, `022000`, recibe `Inversion = -1`. Reproducido con un programa aparte que referencia `GA.Business.ML`, fuera de la CI del curso: `PitchClass.Parse("E") = 11`, y `022000 Em ChordId.RootPitchClass="E" doc.RootPitchClass=4 inversion=-1`. El [curso de teoría musical](../../music-theory-ga/journal/) encontró el mismo comportamiento del parser.
3. `VoicingHarmonicAnalyzer` pasa `intervalSpread > 12` a `IsRootless` y `false` a `IsOpenVoicing` del record posicional `VoicingCharacteristics` ([líneas 31-43](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingHarmonicAnalyzer.cs#L31-L43)). Todo voicing que abarca más de una octava es "rootless". Lo muestra `l2`, "VoicingCharacteristics and PerceptualQualities".
4. `VoicingAnalyzer` construye `new PerceptualQualities(curVoiceChars.Consonance, 0, 0, "Neutral", "Medium")` para un record declarado `(Brightness, ConsonanceScore, Roughness, ...)` ([línea 164](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingAnalyzer.cs#L164)). `ConsonanceScore` vale siempre 0, la `Consonance` del documento también, y la tensión de CONTEXT, `1.0 - doc.Consonance`, vale siempre 1. Es la dimensión constante de la issue [#616](https://github.com/GuitarAlchemist/ga/issues/616), cuyo análisis solo culpa a los literales de al lado. La misma sección de `l2`, y la fila CONTEXT de "Dimensions that never vary" de `l3`.
5. `EmbeddingSchema.AtonalModalDim` vale 17 mientras que el registro da 64 posiciones a ATONAL_MODAL; `ModalVectorService` reserva 17 ([línea 116](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs#L116)) y `WriteInto` no comprueba las longitudes: 47 posiciones valen siempre cero (`l3`). `HierarchyDim` vale 8 frente a 15 (`l2`, "Loose constants"). Las dos particiones tienen peso 0, así que la búsqueda no se ve afectada.
6. STRUCTURE no es invariante a la transposición (221 de 222 clases de conjuntos, `l2`), como dicen el propio barrido de GA y el comentario de `TheoryVectorService`; el resumen de `RootVectorService` todavía afirma "genuinely O+P+T+I-invariant" ([líneas 3-7](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/RootVectorService.cs#L3-L7)).
7. Los pesos de similitud suman 1,15; un vector puntúa 1,15 frente a sí mismo (`l2`). No es un error, pero "coseno" induce a confusión en los logs y en los umbrales.
8. Versiones en comentarios y documentos: el documento de esquema más reciente es v1.4.1, `OPTIC-K_Embedding_Schema.md` describe v1.3.1 (109 dimensiones), `MusicalEmbeddingGenerator` dice 228 ([línea 13](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L13)) y 216 ([línea 55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L55)), el comentario de `CompactDimension` dice 112, `OptickIndexWriter` y `MusicalQueryEncoder` dicen 112, y el comentario de `ExtensionsEnd` dice que es igual a `TotalDimension`. El código calcula 240 y 124.

Índice y búsqueda (lección 3):

9. Nueve de las 33 posiciones MODAL con nombre no se activan nunca en el corpus de 15.360 voicings: LocrianNatural6, DorianSharp4, LydianSharp2, AlteredDoubleFlat7, DorianFlat2, LydianAugmented, MixolydianFlat6, LocrianNatural2, Diminished. `ModalVectorService` busca los modos por nombres visibles como `"Locrian ♮6"` y vuelve en silencio cuando no encuentra nada; la causa probable es un nombre que no coincide (*por verificar*).
10. 37 de las 124 dimensiones buscadas valen siempre cero y 4 son constantes en ese corpus (`l3`); la #616 indica 40 dimensiones muertas en el índice en producción.
11. `ApplyFilters` compara la calidad como subcadena del nombre almacenado: el filtro `Am7` acepta `Gbm7(shell)/A`, y la calidad vacía de `C` acepta cualquier nombre con C en el bajo, incluidos `C + E (Major 3rd)` y `Am/C` ([líneas 296-329](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L296-L329)).
12. `OptickSearchStrategy.FindSimilarVoicingsAsync` devuelve siempre una lista vacía (conocido, comentado en las [líneas 75-92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L75-L92)). `MusicalQueryEncoder` deja el vector interválico fuera de las consultas (conocido, comentado).

Diagramas y herramientas MCP:

13. Dos órdenes para la misma cadena de diagrama: `VoicingGenerator`, el índice y el parser de la herramienta MCP leen primero la cuerda 1 (E aguda); `PlayableNotationFormatter` lee primero la E grave ([líneas 31-53](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Notation/PlayableNotationFormatter.cs#L31-L53)). La tablatura del chatbot para `3-0-x-2-3-x` (Cmaj7) es `6/3 5/0 3/2 2/3`, las notas G A A D (`l4`).
14. La descripción de `ga_generate_voicing_embedding` dice "228-dim" y da `'x-3-2-0-1-0' for Cmaj7` ([líneas 42-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L42-L44)); el parser de la herramienta lo lee como Dsus2/E (`l2`), y leído empezando por la E grave sería C, no Cmaj7.
15. `ga_get_embedding_schema` enumera diez particiones, sin ROOT, con las constantes sueltas `HierarchyDim` y `AtonalModalDim` ([líneas 69-91](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L69-L91)). Leído en el código, no ejecutado por el curso.

Chatbot (lecciones 1 y 4):

16. Sin servidor de embeddings, todo mensaje que no captura ninguna guarda termina en HTTP 500. `SemanticRouter.RouteAsync` no captura la excepción de `EnsureEmbeddingsInitializedAsync` ([líneas 68-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/SemanticRouter.cs#L68-L104)), así que su respaldo por palabras clave es inalcanzable; el respaldo del host, una llamada directa al modelo, también lanza una excepción. "What is the relative minor of C major?" falla aunque `skill.relativekey` la responde con una confianza de 1.00 (`l4`).
17. La antigua vía `CanHandle` envía esa misma pregunta a `ScaleInfo`, no a la skill de tonalidad relativa (`l4`).
18. `skill.fretspan` no tiene ningún prompt de ejemplo, y `SemanticIntentRouter` se salta las intenciones sin ejemplos: nunca se puede enrutar hacia ella (`l1`).
19. `ProductionOrchestrator.AnswerStreamingAsync` (desde la [línea 154](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Services/ProductionOrchestrator.cs#L154)) tiene la guarda de voicings pero no la vía rápida de álgebra de `AnswerAsync`. Leído en el código, no ejecutado.
20. `IntentEmbeddingWarmupService` lanza su trabajo sin esperarlo (lanzar y olvidar); está bien para un servidor, pero entonces los logs de un host dependen de los tiempos (el fallo de CI de arriba).

Documentos:

21. `docs/architecture/chat-surfaces.md` dice en su estado del 2026-05-13 que `GaChatbot.Api` es la superficie canónica y sirve la demo pública ([líneas 16-21](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/docs/architecture/chat-surfaces.md#L16-L21)), mientras que secciones posteriores dicen que la página desplegada llama a SignalR en GaApi y tratan las dos como paralelas a la canónica (líneas 215-223 y 262).
22. El `CLAUDE.md` de GA dice que ix produce `optick.index`; en el código de GA y en su skill `optic-k-rebuild`, lo escribe `FretboardVoicingsCLI`. `CLAUDE.md` nombra `GA.Business.Core.Harmony` y `GA.Business.Core.Fretboard` como capa 3; el generador y el analizador de voicings están en `GA.Domain.Services`.

Pistas no comprobadas por el curso, anotadas antes al leer los documentos de GA (*por verificar*): puede que `GaChatbotCli` no consiga resolver sus servicios; el backlog y la hoja de ruta no coinciden en algunos estados; los documentos de GA dan varios tamaños para el índice en producción (161, 168, 175, 176 y 660 MB).
