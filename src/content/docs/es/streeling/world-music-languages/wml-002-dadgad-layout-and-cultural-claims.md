---
title: "DADGAD: datos de afinación y afirmaciones culturales"
description: "Músicas del mundo e idiomas: DADGAD en una respuesta de GA sobre afinaciones — Músicas y lenguas del mundo"
sidebar:
  label: WML-002 · DADGAD
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/es/wml-002-dadgad-layout-and-cultural-claims.es.md
---

:::note[Streeling University]
**WML-002** · Músicas del mundo e idiomas: DADGAD en una respuesta de GA sobre afinaciones · intermedio · 35 minutos

Generado por el departamento *Músicas y lenguas del mundo* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/es/wml-002-dadgad-layout-and-cultural-claims.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-001](../../world-music-languages/wml-001-guitar-around-the-world/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/voicing-learning-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Músicas del Mundo e Idiomas** | Nivel: intermedio | Etapa: Albedo | Duración: 35 minutos | Borrador español pendiente de revisión

## Objetivos

Al terminar esta lección, podrás leer una afinación de seis cuerdas en el orden que utiliza un skill de GA, comprobar sus cambios respecto a la afinación estándar, distinguir un conjunto de alturas de cuerdas al aire de un estilo o una interpretación, y señalar los comentarios culturales de una fuente como afirmaciones que requieren más pruebas. También podrás describir qué demuestra una consulta determinista de una tabla sin tratar su valor numérico de confianza como prueba de autoridad musical o cultural.

## Pregunta del proyecto y límites de la evidencia

Un guitarrista pregunta a Guitar Alchemist (GA): «¿Qué es la afinación DADGAD?». El skill [`AlternateTuningsSkill` en la revisión fijada](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs) contiene una entrada DADGAD y código que da formato a una respuesta cuerda por cuerda. La entrada también ofrece una frase «Por qué usarla» que relaciona esta afinación con las músicas celtas, el folk modal y una «forma de tocar con aires de la India». **¿Qué partes de esa respuesta puede verificar un guitarrista en la tabla de afinaciones y cuáles requieren consultar a músicos, grabaciones o fuentes históricas?** Esta lección fija el commit de GA `dc2e74cbd992a298f67efb928b5b3754615e1924` para todas las afirmaciones sobre el código.

[WML-001](../../world-music-languages/wml-001-guitar-around-the-world/) presenta varias tradiciones de guitarra. Aquí auditamos una sola respuesta dirigida a músicos. El código versionado y el [código fuente de las pruebas](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.ML.Tests/Unit/AlternateTuningsSkillTests.cs) permiten una lectura reproducible de las fuentes; no aportan una interpretación grabada en DADGAD ni evidencia independiente de las asociaciones culturales enumeradas. El ciclo de redacción de la fuente inglesa no realizó ninguna sesión con el chatbot de GA, prueba con un instrumento físico ni estudio con oyentes, y no produjo ninguna traducción; este archivo es un borrador español cuya revisión lingüística sigue pendiente.

## 1. Colocar las cuerdas en el orden correcto

Las observaciones del skill indican expresamente **de grave a agudo**, es decir, de la cuerda 6 a la cuerda 1. Su array de afinación estándar es `E, A, D, G, B, E`, y su array DADGAD es `D, A, D, G, A, D`. El código que da formato a la respuesta muestra las seis notas en ese orden, numera cada fila con `6 - i` y marca los extremos grave y agudo. Es una convención de orden de este skill de GA, no una convención universal del software. Invertir el array conservaría las letras, pero asignaría notas incorrectas a las cuerdas.

| Cuerda de guitarra | 6 (grave) | 5 | 4 | 3 | 2 | 1 (aguda) |
|---|---|---|---|---|---|---|
| Estándar | E | A | D | G | B | E |
| Entrada DADGAD de GA | D | A | D | G | A | D |
| Cambio en semitonos | −2 | 0 | 0 | 0 | −2 | −2 |

Tres cuerdas cambian respecto a la afinación estándar de la fuente: la cuerda 6 E→D, la cuerda 2 B→A y la cuerda 1 E→D. Cada una baja un tono, o dos semitonos; las cuerdas 5, 4 y 3 mantienen sus notas al aire. La tabla permite verificar los *nombres de las notas de destino* y las diferencias. No mide la afinación real del instrumento, no indica cuánto cambia la tensión de una cuerda concreta ni certifica que una guitarra determinada esté ajustada de forma segura para esta afinación. Esas son comprobaciones prácticas aparte.

En otro idioma, conserva tanto la secuencia de notas como su dirección. Una frase traducida que significara por error de agudo a grave cambiaría la instrucción aunque preservara todas las letras. Mostrar las cuerdas numeradas junto a la secuencia reduce esa ambigüedad. La denominación de las notas también requiere revisión para el idioma de destino; el borrador inglés no proporciona terminología de guitarra aprobada en francés, español u otros idiomas.

### Ejercicio 1 — Leer la orientación

A partir del skill en la revisión fijada, coloca `D A D G A D` en las cuerdas 6 a 1. ¿Cuáles son las notas al aire más grave y más aguda, y por qué resultaría engañoso presentar la secuencia al revés?

> **Respuesta:** Las cuerdas 6, 5, 4, 3, 2, 1 corresponden respectivamente a D, A, D, G, A, D. Ambas cuerdas exteriores son D. El código ordena las notas de grave a agudo; invertir la secuencia cambia la nota asignada a cada cuerda numerada, aunque unos extremos simétricos hagan que la primera y la última letra parezcan tranquilizadoras.

### Ejercicio 2 — Comprobar cada cambio

Compara la afinación estándar `E A D G B E` de la fuente con su entrada DADGAD. ¿Qué cuerdas cambian, cuántos semitonos y cuáles permanecen iguales?

> **Respuesta:** Las cuerdas 6, 2 y 1 bajan dos semitonos cada una: E→D, B→A y E→D. Las cuerdas 5 A, 4 D y 3 G no cambian. El texto `VsStandard` del skill dice lo mismo, y la diferencia de cada fila se deduce de los dos arrays.

## 2. Las cuerdas al aire explican una categoría sonora, no una cultura

Haz sonar *sobre el papel las cuerdas al aire indicadas*: D, A, D, G, A, D. Al eliminar las repeticiones quedan D, G y A. Respecto a D, G es una cuarta y A una quinta; el conjunto no contiene la tercera F ni F♯. Eso respalda la descripción breve «Dsus4 al aire» que ofrece el skill para el conjunto de alturas sin pisar los trastes. No especifica un ritmo, adorno, melodía, intérprete ni contexto cultural. Una grabación podría utilizar la afinación sin apenas hacer sonar sus cuerdas al aire.

La misma fuente incluye una entrada distinta, Open D: `D, A, D, F#, A, D`. Respecto a DADGAD, solo cambia la cuerda 3, de G a F♯, un semitono más bajo. Sus notas distintas al aire son D, F♯ y A, la tríada de D mayor. Esta comparación permite, en principio, oír la distinción estructural y comprobarla en el archivo. No demuestra que toda la música tocada en cualquiera de las dos afinaciones siga un único vocabulario armónico. Las notas pisadas, los slides, los bends, la posición de la cejilla y la técnica pueden modificar el resultado.

«DADGAD presenta al aire un conjunto de notas de acorde con cuarta suspendida» es una afirmación derivada de los nombres de las notas según una nomenclatura habitual de acordes. «Este guitarrista toca música auténtica de la tradición X» requeriría evidencia sobre la obra, el músico, el contexto comunitario y la práctica musical. El nombre de una afinación por sí solo no permite llegar a esa conclusión. Aunque dos grabaciones utilizaran exactamente las mismas cuerdas al aire, las afirmaciones culturales sobre ellas podrían ser distintas.

### Ejercicio 3 — Comparar dos afinaciones abiertas

Indica los nombres de las notas distintas en las entradas DADGAD y Open D. ¿Qué cuerda difiere, cuánto cambia y por qué la fuente llama Dsus4 y D mayor, respectivamente, a sus conjuntos de notas al aire?

> **Respuesta:** DADGAD contiene {D, G, A}; Open D contiene {D, F♯, A}. La cuerda 3 cambia de G a F♯, un semitono hacia abajo. Respecto a D, D–G–A aporta fundamental, cuarta y quinta sin tercera, por lo que «Dsus4» describe el conjunto al aire. D–F♯–A incorpora la tercera mayor, por lo que «D mayor» describe el conjunto al aire de Open D. Ninguna de las dos etiquetas identifica una tradición interpretada.

## 3. Leer la procedencia de la respuesta

`ExecuteAsync` comprueba patrones de afinaciones con nombre antes de intentar una búsqueda inversa de seis notas. La expresión regular de DADGAD reconoce el nombre seguido o separado por guiones y lo relaciona con la clave `dadgad` de la tabla. Si hay una coincidencia directa por nombre, `AnswerTuning` muestra la secuencia de grave a agudo, las filas de las cuerdas, una explicación `VsStandard` y el campo `Flavor` de la entrada bajo «Por qué usarla». El resultado satisfactorio establece `Confidence = 1.0f` y devuelve cadenas de evidencia que identifican el skill y la consulta de la tabla de afinaciones.

Ese valor de confianza pertenece a la **respuesta de consulta de la tabla** en esta implementación. No es una probabilidad independiente de que cada frase de `Flavor` sea histórica o culturalmente correcta. Una única función da formato tanto a los datos mecánicos de las notas como al texto descriptivo de una respuesta; compartir ese formato no otorga el mismo respaldo a ambos tipos de afirmación. El código no incluye citas junto al campo `Flavor` de DADGAD. Por ello, esta lección presenta su lenguaje cultural como *lo que dice la fuente*, no como una descripción verificada de una tradición o un músico.

El skill también define `CanHandle(message) => false`, con un comentario que indica que utiliza enrutamiento semántico. Esa línea no demuestra que un chatbot en funcionamiento dirija aquí un mensaje concreto de un usuario. El archivo de pruebas comprueba búsquedas por nombre e inversas para algunas afinaciones y controles de alteraciones; no contiene una prueba de resultado específica de DADGAD. Nuestros resultados de DADGAD se deducen de la tabla y del código de formato. Ejecutar una prueba del skill en una revisión fijada para esta pregunta exacta y comprobar una traza real del chatbot serían pasos de verificación aparte.

### Ejercicio 4 — Interpretar la confianza de forma limitada

Alguien que lee el código ve `Confidence = 1.0f` junto a una respuesta DADGAD generada. ¿Qué establece el código sobre ese valor y por qué no puede validar la frase sobre las músicas celtas, el folk modal y la forma de tocar «con aires de la India»? ¿Puede esta fuente por sí sola demostrar que el chatbot de GA mostró la respuesta a un usuario?

> **Respuesta:** `Result` asigna 1.0 a una respuesta satisfactoria de consulta de la tabla y adjunta evidencia del skill y de la tabla. `AnswerTuning` añade a esa respuesta el texto sin citas de `Flavor`; el valor numérico no comprueba ese texto de forma independiente. `CanHandle` devuelve false y la lección no dispone de una traza de enrutamiento, por lo que la fuente no puede demostrar que un chatbot en funcionamiento mostrara esta respuesta.

## 4. Traducir una afirmación sin reforzarla

La frase «Por qué usarla» de la entrada DADGAD dice que esta afinación es «apreciada para las músicas celtas, el folk modal y la forma de tocar con aires de la India», y menciona artistas y una grabación. Esas asociaciones pueden orientar una pregunta, pero el código no aporta un análisis directo de grabaciones ni una historia cultural citada que las respalde. La expresión «con aires de la India» es especialmente amplia: no identifica ningún músico, género, repertorio, región ni técnica. Su traducción no debe convertirse en una afirmación de que esta afinación representa la música de la India en general. La palabra «celta», que abarca más de una comunidad y práctica musical, exige el mismo cuidado.

Un texto útil para el producto puede distinguir los niveles: «La tabla de afinaciones alternativas de GA indica DADGAD como D–A–D–G–A–D, cuerdas 6→1. Su descripción opcional asocia esta afinación con varios estilos; aquí no se han comprobado esas asociaciones». Un músico puede utilizar las notas especificadas para cada cuerda y conocer a la vez el estado de los comentarios culturales. Al localizar el contenido, conserva la orientación numerada, mantén exactos los nombres y símbolos de afinación y pide a un músico y a un revisor nativo del idioma que evalúen los términos de tradiciones y técnicas. Una traducción fluida que convierta «la fuente lo asocia» en «esto es auténtico de» cambia la afirmación.

Para una interpretación concreta, una afirmación cultural más fuerte necesitaría una grabación o partitura identificada, contexto aportado por los músicos pertinentes o por estudios especializados y una explicación de los rasgos que se comparan. Durante este ciclo no se analizó ninguna interpretación. La tabla de afinaciones tampoco puede establecer si las cuerdas, el ajuste de una guitarra o la técnica del intérprete hacen cómoda esta configuración. Las indicaciones del producto deben evaluarse en el instrumento y con las personas a las que se dirigen.

### Ejercicio 5 — Elegir un texto defendible

¿Qué texto está respaldado por el skill en la revisión fijada? **A:** «La tabla DADGAD de GA indica D–A–D–G–A–D de grave a agudo; su texto descriptivo asocia la afinación con las músicas celtas, el folk modal y una forma de tocar “con aires de la India”». **B:** «DADGAD demuestra que esta grabación es música auténtica de la India». Indica una comprobación adicional antes de formular una afirmación cultural sobre una grabación concreta.

> **Respuesta:** A atribuye correctamente las notas y asociaciones a la fuente de GA. B carece de respaldo: ni la tabla de afinaciones ni una frase de `Flavor` sin citas identifican o analizan una grabación ni validan su autenticidad. Examina una interpretación identificada con conocimientos musicales o culturales pertinentes y un criterio explícito antes de formular una afirmación más limitada sobre esa grabación.

## Límites y próxima comprobación

Esta lección es una lectura de las fuentes en una revisión fijada. No ejecutó `AlternateTuningsSkill`, no dirigió una pregunta al chatbot, no tocó una guitarra, no escuchó una grabación ni validó la historia cultural y las asociaciones con artistas. Los cinco ejercicios comprueban datos de las fuentes y deducciones explícitas; no miden el aprendizaje. Una próxima comprobación consistiría en añadir y ejecutar una prueba de búsqueda por nombre de DADGAD sobre una compilación fijada, comparar una respuesta capturada con sus campos de origen y revisar por separado el texto cultural con los músicos pertinentes y revisores nativos del idioma. La revisión de esta traducción, la revisión del contenido por personas competentes, las pruebas con alumnos, la sincronización y compilación de Learn, la lectura pública anónima y la publicación siguen pendientes.
