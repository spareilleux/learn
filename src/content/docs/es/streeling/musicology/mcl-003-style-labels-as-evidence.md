---
title: ¿Cuándo constituye una prueba una etiqueta de estilo?
description: "Musicología: las etiquetas de estilo como pruebas — Musicología"
sidebar:
  label: MCL-003 · ¿Cuándo constituye una prueba una etiqueta de estilo?
  order: 3
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/musicology/es/mcl-003-style-labels-as-evidence.es.md
---

:::note[Streeling University]
**MCL-003** · Musicología: las etiquetas de estilo como pruebas · intermedio · 35 minutos

Generado por el departamento *Musicología* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/musicology/es/mcl-003-style-labels-as-evidence.es.md) · [Mi diario](../../journal/)

Requisitos previos: [MCL-002](../../musicology/mcl-002-musical-form/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de traducciones todavía no redactadas, de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) documenta los borradores traducidos actuales, la importación y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Musicología** | Nivel: intermedio | Etapa: Albedo | Duración: 35 minutos | Borrador en español; revisión pendiente, incluida la de una persona que domine el español

## Objetivos

Después de esta lección, podrás distinguir una etiqueta de catálogo de una observación sobre una interpretación, leer un registro de progresión sin añadir datos ausentes de forma implícita, comparar entradas al nivel correcto y redactar para Guitar Alchemist (GA) una leyenda de estilo que identifique su fuente. También podrás especificar qué debe registrar una futura comprobación auditiva antes de justificar una afirmación sobre una grabación real.

## Pregunta del proyecto y límite de las pruebas

GA tiene un [catálogo de progresiones](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/ChordProgressions.yaml) versionado con campos como `Name`, `RomanNumerals`, `Category`, `Chords`, `Structure` y `Examples`. También tiene un [registro de dominio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Theory/Harmony/Progressions/ProgressionCorpusItem.cs) independiente que declara `StyleLabel`, `Chords` y `Source`. Ambos enlaces fijan el commit de GA `dc2e74cbd992a298f67efb928b5b3754615e1924`. **¿Cuándo puede una pantalla de GA mostrar la `Category` de una progresión como metadato del catálogo y qué pruebas respaldarían una afirmación sobre el estilo de una interpretación grabada?**

El catálogo responde a la primera parte: indica qué almacenó un editor en esa revisión. No puede responder por sí solo a la segunda. Una lista de acordes no es audio ni una transcripción con tiempos, instrumentación, articulación y contexto comprobados de forma independiente. Los ejemplos de canciones y las listas `UsedBy` del catálogo también son afirmaciones de la fuente; esta lección no los trata como historia musical verificada. La propiedad obligatoria `Source` del registro de código exige conservar la atribución, pero no demuestra que cada instancia haya sido auditada de forma independiente. El YAML y el registro C# son artefactos distintos; esta lección no afirma que exista un cargador o una correspondencia entre ellos.

En [MCL-002](../../musicology/mcl-002-musical-form/) estudiaste la forma. Aquí nos centramos en las pruebas detrás de una **etiqueta de estilo**. Una categoría de catálogo y una interpretación escuchada responden a preguntas diferentes.

## 1. Leer la unidad que lleva la etiqueta

Empieza por el registro de nivel superior `ii-V-I`. Tiene `Category: "Jazz"`, `InKey: "C Major"`, números romanos `ii7, V7, I` y acordes `Dm7, G7, Cmaj7`. Son cuatro campos distintos. La etiqueta pertenece a la entrada del catálogo; no es una propiedad medida en una forma de onda concreta. La tonalidad y la escritura de los acordes explican cómo figura esta instancia en el archivo. No establecen que toda interpretación de ii–V–I utilice esos voicings, que siempre sea jazz o que las canciones citadas empleen esta secuencia exacta cada vez.

Una pantalla de GA puede decir: «`ii-V-I` — categoría en el catálogo de GA: Jazz; ejemplo en do mayor: Dm7–G7–Cmaj7». La palabra *catálogo* aporta la procedencia de la etiqueta. «Grabación de jazz» necesitaría pruebas sobre la interpretación.

El código `ProgressionCorpusItem` refuerza el problema de la atribución. `StyleLabel` y `Source` son cadenas obligatorias y `Chords` tiene por defecto una lista vacía de solo lectura. Un valor obligatorio podría proceder de un editor, intérprete, oyente o clasificador. Una interfaz o exportación de datos debería mostrar la fuente y el tipo de afirmación en vez de tratar `StyleLabel` como una validación.

### Ejercicio 1 — Extraer sin reforzar la afirmación

Del catálogo fijado, indica la categoría, tonalidad, números romanos y nombres de acordes de `ii-V-I`. Después escribe una leyenda permitida y otra sin respaldo para una grabación que no has escuchado.

> **Respuesta:** Categoría `Jazz`; tonalidad `C Major`; números romanos `ii7, V7, I`; acordes `Dm7, G7, Cmaj7`. Permitida: «El catálogo de GA etiqueta `ii-V-I` como Jazz y ofrece Dm7–G7–Cmaj7 en do mayor». Sin respaldo: «Esta grabación no escuchada es jazz porque contiene Dm7–G7–Cmaj7». El archivo proporciona los campos de la primera afirmación; no proporciona ninguna observación de la grabación.

## 2. Contar lo codificado; separar las descripciones

La entrada `12-Bar Blues` aporta una pista estructural más sólida que un nombre solo. Su lista `RomanNumerals` tiene doce posiciones: `I, I, I, I, IV, IV, I, I, V, IV, I, V`. Su lista `Chords` también tiene doce: `E, E, E, E, A, A, E, E, B, A, E, B`. La entrada indica `InKey: "E Major"` y `Category: "Blues"`. Si interpretamos cada posición como un compás en la plantilla prevista, las posiciones 5 y 6 son `IV`/`A`; la posición 9 es `V`/`B`; la posición 12 es `V`/`B`, un posible turnaround de regreso al primer `I`/`E`. La aritmética de posiciones se puede comprobar en el archivo. El tempo real, la duración de los compases, las repeticiones, las omisiones y las cualidades de acordes interpretadas siguen siendo desconocidos.

El campo `Structure` del mismo registro dice «forma lírica AAB sobre 12 compases». Sus listas de acordes no contienen letra ni audio, por lo que no pueden demostrar de forma independiente una organización AAB de la letra. Podemos comunicar la descripción del catálogo, pero no afirmar que sus acordes demuestran que un cantante concreto interpretó versos AAB. Una toma concreta exigiría comprobarlo directamente.

### Ejercicio 2 — Contar y localizar

¿Cuántas posiciones de acordes contiene la lista `Chords` de nivel superior de `12-Bar Blues` fijada? ¿Cuáles son las posiciones 5, 6, 9 y 12? ¿Puede esa lista por sí sola verificar la descripción lírica AAB de la entrada?

> **Respuesta:** Hay doce posiciones. Numerando desde uno, 5 = `A`, 6 = `A`, 9 = `B` y 12 = `B`. No: la lista `Chords` contiene símbolos de acordes, no palabras ni una estructura vocal grabada. AAB es una descripción adicional del catálogo.

## 3. Una etiqueta de forma no es un arreglo interpretado

`Rhythm Changes` ilustra otra estructura de registro. Tiene `Category: "Jazz"` y `Structure: "AABA form with specific harmonic rhythm"`. En lugar de una lista `Chords` o `RomanNumerals` de nivel superior, tiene una `ASection` y una `BSection`. La sección A enumera `I, vi, ii, V` sobre `Bb, Gm, Cm, F`; la sección B enumera `III, VI, ii, V` sobre `D, G, Cm, F`. Un lector puede comparar esas plantillas de sección, pero no aplanarlas y afirmar que constituyen una interpretación completa. La fuente no especifica cuántas veces se toca cada segmento de cuatro acordes, cuánto dura cada acorde, el ritmo armónico real ni qué tocó una banda concreta.

«AABA» nombra un orden de secciones por encima de los eventos individuales de acordes. Esbozar A–A–B–A desde las dos listas interpreta el catálogo; no documenta una toma. Una anotación de interpretación requeriría límites de secciones, marcas temporales y una referencia a una grabación o partitura. Este registro no codifica un número total de compases.

### Ejercicio 3 — Identificar el nivel superior ausente

Indica el primer acorde de `ASection` y `BSection` de `Rhythm Changes` y si el registro tiene una lista `Chords` de nivel superior. ¿Qué queda sin verificar sobre una interpretación?

> **Respuesta:** `ASection` comienza por `Bb`; `BSection` comienza por `D`. El registro no tiene una lista `Chords` de nivel superior. Su `Structure` AABA y las listas de secciones no verifican los tiempos de las secciones, las repeticiones, la duración o la instrumentación de una interpretación concreta, ni siquiera que el intérprete siguiera la plantilla.

## 4. Un texto de catálogo repetido no es corroboración independiente

El registro `I-vi-IV-V` tiene en el nivel superior `Category: "Pop"`, un ejemplo en do mayor `C, Am, F, G` y un elemento anidado de `Variations` llamado `vi-IV-I-V`, con `Am, F, C, G` y `Context: "Pop ballad version"`. La variación anidada no declara su propia `Category`; está bajo un elemento padre que sí lo hace. En otra parte, el mismo YAML contiene una entrada independiente de nivel superior `vi–IV–I–V (Pop Loop)`, con rayas cortas en el nombre, `Category: "Pop"`, `InKey: "C Major"` y `Chords: ["Am", "F", "C", "G"]`.

Las dos apariciones muestran el mismo orden de cuatro acordes en una variación anidada y una entrada independiente. No son estudios auditivos independientes ni pruebas de que toda canción que utilice esos acordes sea una balada pop. El `Context` de la variación es prosa editorial, no una característica medida de una grabación. Una pantalla debería nombrar la relación entre padre e hijo.

Para un futuro estudio de estilo, selecciona interpretaciones reales y registra el intervalo analizado, las características observadas, quién asignó la etiqueta y los desacuerdos. Una secuencia de acordes es una clave de búsqueda; también importan la interpretación, la producción y el contexto cultural. Define las etiquetas antes de puntuar ejemplos.

### Ejercicio 4 — Comparar niveles

¿Dónde aparece `vi-IV-I-V` bajo `I-vi-IV-V`, qué cuatro acordes usa y cómo difiere como registro la entrada independiente de nivel superior `vi–IV–I–V (Pop Loop)`? ¿La duplicación valida de forma independiente un género?

> **Respuesta:** Es un elemento anidado de `Variations` con `Context: "Pop ballad version"` y acordes `Am, F, C, G`; no tiene un campo `Category` propio. El `vi–IV–I–V (Pop Loop)` independiente es un registro de nivel superior con su propia `Category: "Pop"` y el mismo orden de acordes. Ambos son afirmaciones de un solo catálogo, así que su repetición no verifica de forma independiente el género de ninguna grabación.

## 5. Redactar una leyenda y un siguiente paso comprobable

Una leyenda rigurosa de GA separa tres capas. Primero, identifica el **objeto almacenado**: una entrada de progresión con nombre en una revisión fijada. Segundo, identifica la **afirmación almacenada**: una etiqueta de categoría o forma y los ejemplos de acordes explícitamente enumerados. Tercero, indica el **estado de evaluación de la interpretación**: aquí no se ha evaluado ninguna grabación. Este patrón es útil incluso cuando el catálogo es correcto, porque el lector distingue lo comprobable de lo que requiere trabajo adicional. Un enlace de revisión permite a otro estudiante reproducir la consulta después; un enlace sin fijar podría apuntar silenciosamente a datos modificados.

Supón que una pantalla presenta la plantilla `12-Bar Blues` junto a una grabación subida. Antes de analizarla, puede decir: «Plantilla del catálogo de GA: Blues; ejemplo en mi mayor, doce posiciones de acordes enumeradas». No debería decir todavía «el archivo subido es una interpretación de blues». Una futura comprobación podría pedir a dos oyentes formados que marquen límites de secciones y eventos de acordes en un intervalo temporal especificado, conservar la referencia de audio y las versiones de anotación y comparar sus hallazgos con una regla de coincidencia declarada. Por ejemplo, exigir que al menos diez de las doce posiciones armónicas esperadas coincidan en orden, informando de desviaciones y desacuerdos. Ese umbral es una **regla de estudio propuesta**, no un criterio validado de género ni una prueba ejecutada para este borrador. Cumplirlo respaldaría una coincidencia con la plantilla; un juicio estilístico más amplio seguiría necesitando una rúbrica definida y pruebas relevantes de la interpretación.

La cadena obligatoria `Source` de `ProgressionCorpusItem` podría apuntar a un catálogo, partitura, anotación o archivo de audio. Necesita una interpretación específica para cada afirmación. Una futura correspondencia de YAML al corpus necesitaría verificación antes de suponer que `Category` y `StyleLabel` están sincronizados.

### Ejercicio 5 — Elegir un texto de producto defendible

Redacta una frase para una pantalla de GA que muestre la entrada `12-Bar Blues` del catálogo junto a un archivo subido sin escuchar. Después nombra dos observaciones o registros necesarios antes de afirmar algo sobre el estilo interpretado del archivo.

> **Respuesta:** «La plantilla `12-Bar Blues` del catálogo de GA está clasificada como Blues y enumera doce posiciones de acordes en mi mayor; el archivo subido no se ha evaluado». Para una afirmación posterior, conserva un intervalo de audio identificado con anotaciones temporales de acordes/secciones y una rúbrica de estilo declarada aplicada por revisores identificados o un clasificador validado. La entrada del catálogo solo respalda la leyenda de la plantilla, no el género del archivo.

## Límites y base de investigación

Esta es una lección de lectura de fuentes, no un análisis de audio. No se probó ninguna grabación, edición de partitura, transcripción temporal, salida de clasificador ni acuerdo entre oyentes. Las descripciones, ejemplos de canciones, nombres `UsedBy` e implicaciones históricas del catálogo siguen sin verificarse en este ciclo. El umbral auditivo propuesto es un ejercicio de diseño de una comprobación refutable; no está calibrado. El código fijado muestra declaraciones de un registro de dominio, no comprobaciones de procedencia en ejecución ni una ruta de importación desde YAML demostrada. La revisión humana de la materia, las pruebas con estudiantes y la publicación siguen pendientes; este borrador en español requiere revisión de una persona que domine el español.

Las pruebas primarias son el [catálogo de progresiones de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/ChordProgressions.yaml) fijado y la [declaración `ProgressionCorpusItem`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Theory/Harmony/Progressions/ProgressionCorpusItem.cs) fijada. La confianza de la lección se refiere a la extracción de campos y recuentos de esa revisión exacta, no a la verdad independiente de sus asociaciones de género o canciones.
