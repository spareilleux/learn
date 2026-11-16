---
title: Símbolos de acordes, canonicalización y significado en el DSL de GA
description: Símbolos de acordes, canonicalización y significado en el DSL de GA — Semiótica
sidebar:
  label: SEM-002 · Símbolos de acordes, canonicalización y significado en el DSL de GA
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/es/sem-002-chord-symbols-and-canonicalization.es.md
---

:::note[Streeling University]
**SEM-002** · Símbolos de acordes, canonicalización y significado en el DSL de GA · intermedio · 35 minutos

Generado por el departamento *Semiótica* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/es/sem-002-chord-symbols-and-canonicalization.es.md) · [Mi diario](../../journal/)

Requisitos previos: [SEM-001](../../semiotics/sem-001-signs-in-governance/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de traducciones todavía no redactadas, de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) documenta los borradores traducidos actuales, la importación y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Semiótica** | Nivel: intermedio | Etapa: Albedo | Duración: 35 minutos | Borrador en español; revisión pendiente, incluida la de una persona que domine el español

## Objetivos

Después de esta lección, podrás identificar el signo introducido, la estructura de acorde analizada, la representación canónica y la proyección de clases de altura en Guitar Alchemist (GA). Seguirás cinco ejemplos fijos por código o pruebas fijados, distinguirás equivalencia léxica de interpretación musical y diseñarás etiquetas que indiquen al usuario de GA qué transformación produjo cada valor.

## La pregunta del proyecto

Supón que un guitarrista introduce `Cmi7` en una herramienta de GA. Un resultado posterior muestra `Cm7`. ¿GA ha oído una interpretación, cambiado el acorde o normalizado un símbolo escrito? El [analizador de acordes](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Parsers/ChordParser.fs), el [generador de representación](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Generators/ChordRenderer.fs) y el [servicio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Services/ChordDslService.fs) fijados responden a una pregunta más acotada y útil: **¿Qué distinciones de la notación introducida sobreviven al análisis y la representación canónica y cuáles se eliminan por proyección?** Todos los enlaces de GA de esta lección fijan el commit `dc2e74cbd992a298f67efb928b5b3754615e1924`.

[SEM-001](../../semiotics/sem-001-signs-in-governance/) utilizó signos para examinar documentos de gobernanza. Aquí un **significante** es la cadena que escribe un músico, como `Cmi7`; el analizador produce una **interpretación** estructurada en un árbol de sintaxis abstracta (AST); y el generador emite un símbolo escrito preferido. Es una explicación computacional del comportamiento del código, no una prueba de lo que un intérprete oye o pretende. La escritura puede importar en una tonalidad o partitura aunque un cálculo agrupe notas por clase de altura. Trátalos como afirmaciones separadas con pruebas separadas.

## 1. Texto introducido y texto canónico

El servicio define `Normalize` como `Parse` seguido de `Render` si el análisis tiene éxito. El analizador acepta varios signos para la cualidad menor, incluidos `min`, `mi` y `-`; el generador escribe esa cualidad como `m`. Los [casos de prueba de normalización](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs) fijados incluyen `Cmi7 → Cm7` y `D-7 → Dm7`. La fuente explica por qué: raíz y componentes sobreviven en un AST, mientras los caracteres concretos de la cualidad menor se sustituyen por la convención del generador.

Es una transformación de muchos a uno en el texto. Solo con el resultado `Cm7` no se puede recuperar si el usuario escribió `Cmi7` o `Cm7`. Es útil para búsqueda, deduplicación y presentación coherente si la pantalla indica que muestra un símbolo canónico. Si la notación exacta importa para edición o procedencia, consérvala en un campo aparte de texto introducido. Un valor canónico no debería sobrescribir silenciosamente la única copia del texto introducido.

Las pruebas aquí son una **declaración** de prueba versionada y la implementación. Esta lección no ha vuelto a ejecutar la suite. Los casos nombrados pueden comprobarse en la fuente de pruebas, pero no demuestran que se analice toda notación que un guitarrista pudiera usar, que una interfaz llame al servicio ni que la cadena represente toda intención armónica.

### Ejercicio 1 — Seguir dos escrituras

¿Qué cadenas canónicas esperan las pruebas fijadas para `Cmi7` y `D-7`? ¿Qué parte cambia de cada signo escrito y qué se perdería si GA almacenara solo la salida canónica?

> **Respuesta:** Las salidas esperadas son `Cm7` y `Dm7`. Los marcadores menores introducidos `mi` y `-` pasan a ser `m`; las letras raíz y `7` permanecen. Si se guarda solo la salida, no puede reconstruirse la escritura original del marcador menor.

## 2. Un símbolo está compuesto por campos del analizador

Un símbolo de acorde no se analiza como una etiqueta indivisible. El [tipo AST](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/ChordAst.fs) tiene `Root`, `RootAccidental`, `Quality` opcional, una lista de `Components` y `Bass` opcional. El analizador intenta una letra inicial de nota, alteración opcional, cualidad opcional, cero o más extensiones o alteraciones y bajo opcional tras barra. Después el generador escribe cada campo en un orden fijo. Esta separación permite preguntar qué denota un token en esta implementación en vez de adivinarlo solo por la tipografía.

En `EbΔ9`, el bemol pertenece a la raíz `E`, `Δ` selecciona la cualidad `Major` y `9` es una extensión. El generador escribe raíz `Eb`, cualidad mayor `maj` y extensión `9`, produciendo `Ebmaj9`. Esa pareja exacta de entrada y salida también aparece en las pruebas fijadas. El signo `Δ` es una convención de la gramática aceptada por el DSL; su cambio a `maj` es una decisión de representación. No indica el voicing, la tonalidad circundante ni la articulación del intérprete. Una interfaz podría mostrar «introducido: EbΔ9» y «canónico: Ebmaj9» para conservar la distinción.

El orden del analizador importa. Prueba ciertas extensiones de varios caracteres antes que componentes más cortos. Eso impide dividir `13` en `1` y `3`, y su comentario dice que `maj7` debe consumirse como extensión completa en vez de cualidad `maj` sola seguida de `7`. Son reglas de tokenización del código. No deben convertirse en afirmaciones sobre una norma universal de notación de acordes; otro sistema podría tokenizar de otra forma la misma escritura.

### Ejercicio 2 — Explicar una sustitución de glifo

Con el analizador, el generador y el caso de prueba fijados, ¿qué campos explican `EbΔ9 → Ebmaj9`? ¿Establece la prueba una digitación concreta de guitarra?

> **Respuesta:** La raíz `E` con bemol produce `Eb`; `Δ` aporta la cualidad `Major`; `9` es una extensión. El generador emite `Ebmaj9`. Esa aserción de entrada y salida no codifica ninguna digitación, por lo que no establece un voicing ni una interpretación sonora.

## 3. No confundir un campo del AST con la palabra mostrada

`Fmaj7/A` es una trampa útil para quien espera encontrar `Major` en el campo `Quality` del AST. En el analizador fijado, `maj` solo se bloquea cuando va seguido de un dígito; entonces `maj7` se consume como un token completo `Extension "maj7"`. Por tanto, el AST derivado de la fuente tiene raíz `F`, ningún valor explícito de cualidad (`Quality=None`), una extensión `maj7` y bajo `A`. El generador escribe raíz `F`, sin marcador de cualidad separado, componente `maj7` y bajo tras barra `/A`, produciendo `Fmaj7/A`. Las pruebas de normalización fijadas dan esa salida.

Esto **no** significa que un músico llamaría al acorde escrito «sin cualidad». Significa que la implementación almacena el marcador `maj7` bajo `Components` en vez de `Quality` en este análisis. Tratar los nombres de campos internos como una teoría completa del significado musical confundiría una representación informática con su objeto. Una vista diagnóstica puede decir «campo de cualidad analizada: ninguno» mientras una vista para músicos muestra el símbolo canónico. El campo del bajo registra notación con barra, no una nota grave medida en una toma concreta.

La misma distinción afecta a las explicaciones generadas. Si un asistente ve `Quality=None`, no debería afirmar con seguridad «aquí no hay cualidad mayor» sin considerar el componente `maj7`. Una buena explicación puede citar ambos campos y la representación canónica. Aquí la semiótica se convierte en una herramienta de calidad de producto: la estructura interna de signos es útil, pero sus etiquetas necesitan interpretación antes de llegar al músico.

### Ejercicio 3 — Examinar un análisis poco evidente

Para `Fmaj7/A`, identifica raíz, campo `Quality`, componente, bajo y salida canónica derivados de la fuente. ¿Por qué «no implica mayor» no es una conclusión sólida a partir solo de `Quality=None`?

> **Respuesta:** Raíz `F`; `Quality=None`; componente `Extension "maj7"`; bajo `A`; salida canónica `Fmaj7/A`. El analizador representa `maj7` como componente, así que el campo de cualidad vacío por sí solo no describe el símbolo completo.

## 4. Límites de tokens y alteraciones estructuradas

La prueba fijada de `C13#11b9` comprueba que el análisis tiene éxito, la raíz es `C` y el AST contiene **tres** componentes. El analizador explica la descomposición esperada: `13` es una extensión, `#11` una alteración y `b9` otra alteración. Es una interpretación de esa cadena exacta derivada de la fuente; la prueba afirma el recuento, pero no afirma independientemente los tres nombres de componentes. Distinguir estas dos clases de pruebas hace reproducible el ejercicio sin exagerar la cobertura.

Los caracteres `#` y `b` modifican aquí grados numerados del símbolo; no son la alteración de la raíz. El analizador maneja una alteración opcional inmediatamente después de la letra y luego lee componentes posteriores. Un sistema que solo dijera «contiene sostenido y bemol» borraría esa sintaxis y probablemente confundiría al lector. Una presentación estructurada podría decir «raíz do; extensión 13; grado 11 con sostenido; grado 9 con bemol», conservando el `C13#11b9` original para comparar.

El ejemplo no establece un voicing real, un inventario de notas en un instrumento concreto ni si un guitarrista preferiría esa notación. Demuestra la descomposición del analizador y la forma de la aserción versionada. Una comprobación real de ejecución llamaría a la compilación fijada con esa entrada y compararía su AST; una afirmación auditiva requeriría una interpretación grabada separada.

### Ejercicio 4 — Contar componentes con precisión

¿Cuántos componentes exige la prueba fijada de `C13#11b9`? Nombra las categorías derivadas de la fuente y explica por qué la raíz sigue siendo `C`.

> **Respuesta:** La prueba exige tres componentes. Las alternativas del analizador producen `Extension "13"`, `Alteration(Sharp, "11")` y `Alteration(Flat, "9")`. La raíz es `C` porque el analizador de raíz consume la primera letra y no hay alteración inmediatamente después; los `#` y `b` posteriores pertenecen a los componentes.

## 5. Una proyección es una afirmación distinta de la escritura

La [closure `domain.projectChord`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L424-L486) fijada acepta un `symbol` y los `fields` solicitados. Entre otros campos, puede emitir `root` a partir de la letra y alteración analizadas y `pc` de un cálculo de semitonos módulo doce. En la correspondencia de notas de la fuente, do vale cero, re dos, un sostenido suma uno y un bemol resta uno. Por tanto, la fuente predice `root=C#`, `pc=1` para `C#` y `root=Db`, `pc=1` para `Db`. Son resultados deducidos para esta pareja fija, **no** un resultado ejecutado de la closure en esta lección.

Las cadenas de raíz difieren, pero sus números proyectados de clase de altura coinciden. Proyectar ambas a `1` elimina deliberadamente la escritura. Puede ser útil para comparar cromáticamente, pero no autoriza a sustituir la raíz introducida en una partitura ni a afirmar una función armónica idéntica. Do sostenido y re bemol pueden tener implicaciones de escritura diferentes en contexto. Ni `root` ni `pc` por sí solos indican tonalidad, intención del guitarrista, afinación ni octava de una nota sonora. Una interfaz útil etiqueta los valores como «símbolo introducido», «símbolo canónico», «raíz analizada» y «clase de altura de la raíz», para que la igualdad en un campo no parezca igualdad en todo.

El analizador termina con `run pChord` y no muestra una exigencia explícita de fin de entrada. Es una razón basada en el código para probar qué ocurre con texto sobrante antes de anunciar una validación estricta de toda la cadena. Esta lección no afirma que un ejemplo mal formado se acepte o rechace en ejecución. Tampoco deduce que una pantalla concreta de GA muestre actualmente los campos proyectados de la closure. La recomendación de producto es mostrar claramente la procedencia cuando una pantalla los use.

### Ejercicio 5 — Comparar signos y una proyección numérica

Para las entradas `C#` y `Db`, predice `root` y `pc` desde la fuente fijada de `domain.projectChord`. ¿Qué igualdad se establece y qué conclusión más fuerte necesitaría contexto musical?

> **Respuesta:** La fuente predice `C#`: `root=C#`, `pc=1`; `Db`: `root=Db`, `pc=1`. Sus proyecciones de clase de altura de la raíz son iguales y sus escrituras de raíz difieren. Una `pc` igual no demuestra notación, función tonal, voicing ni interpretación escuchada idénticos.

## Límites y siguiente comprobación

Esta lección lee una implementación fijada y pruebas versionadas; no afirma una nueva ejecución de pruebas, observación de una interfaz activa ni estudio auditivo. Las pruebas cubren ejemplos nombrados, no todas las escrituras. La falta de un control explícito de fin de entrada invita a una prueba específica del límite, no es un resultado de ejecución medido. Las etiquetas propuestas son una aplicación de diseño, no una afirmación del comportamiento actual. Una validación futura debería ejecutar los casos en una compilación fijada, inspeccionar una ruta real de llamada de interfaz y preguntar a estudiantes si distinguen valores introducidos, canónicos, analizados y proyectados. La revisión humana de la materia, las pruebas con estudiantes y la publicación siguen pendientes; este borrador en español requiere revisión de una persona que domine el español.
