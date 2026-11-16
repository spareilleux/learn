---
module_id: wml-005-declare-note-name-conventions
department: world-music-languages
course: "Declarar la convención de nombres de notas antes de interpretar B"
level: intermediate
prerequisites: ["wml-003-term-preservation-and-cultural-review"]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Declarar la convención de nombres de notas antes de interpretar B

> **Alcance del borrador.** Documentación primaria, código público de GA fijado a una revisión, una tabla de decisiones creada para el curso y respuestas reales de la herramienta de transposición de acordes. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML del curso desplegado. No se entrega ningún adaptador lingüístico nuevo ni se ejecuta el analizador de C#.

## La pregunta del proyecto

Un guitarrista envía a un agente «B, capo 2». Una transposición impecable puede responder a la pregunta musical equivocada si el agente elige la convención de nombres incorrecta. La [tabla de idiomas de LilyPond 2.24](https://lilypond.org/doc/v2.24/Documentation/notation/writing-pitches#note-names-in-other-languages) establece una distinción explícita útil: su vocabulario inglés tiene B para si natural, mientras que su vocabulario alemán usa H para si natural y B para si bemol. La lección utiliza esas dos **convenciones declaradas**; la nacionalidad, el idioma de la interfaz y la ubicación del músico no determinan qué convención utiliza una partitura de acordes concreta.

[WML-003](wml-003-term-preservation-and-cultural-review.md) conserva los términos y la responsabilidad de revisión. Aquí la tarea es más acotada: determinar qué altura representa un símbolo antes de pasarlo a GA. La [tabla de decisiones creada para el curso](../../../../code/streeling/evidence/pitch-context-2026-10-22/language-decisions.json) es un recurso didáctico, no un servicio de normalización instalado.

## 1. Leer un símbolo junto con su convención

En esta tabla, las grafías de salida usan los nombres de notas ingleses y las clases de altura toman C como 0. Se omiten deliberadamente la octava y la cualidad del acorde.

| Convención declarada | Símbolo de entrada | Salida en notación inglesa | Clase de altura | Decisión |
| --- | --- | --- | --- | --- |
| Inglesa | B | B | 11 | resuelto |
| Inglesa | Bb | Bb | 10 | resuelto |
| Alemana | B | Bb | 10 | resuelto |
| Alemana | H | B | 11 | resuelto |
| sin especificar | B | sin resolver | sin resolver | preguntar por la convención |
| Inglesa | H | sin resolver | sin resolver | fuera del vocabulario declarado |

### Ejercicio 1: resolver la discrepancia

Dos partituras de acordes contienen B. Una declara nombres ingleses; la otra declara nombres alemanes. Indica la salida en notación inglesa y la clase de altura de cada una. ¿Tiene necesariamente alguna un error de escritura?

> **Respuesta:** El B inglés da B, clase 11; el B alemán da Bb, clase 10. Ninguna tiene necesariamente un error. Sus convenciones declaradas dan significados diferentes al mismo símbolo.

## 2. Examinar la interfaz de entrada real de GA

En el commit público de GA `dc2e74cbd992a298f67efb928b5b3754615e1924`, [NaturalNote](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Primitives/Notes/NaturalNote.cs) reconoce de A a G. El [PitchParser](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs) genérico selecciona la sintaxis de alteraciones con sostenidos o bemoles y espera una octava. Su patrón no incluye la alternativa H. Esto es una inspección del código fuente, no una nueva ejecución de esa ruta de C#. Además, su patrón sin anclajes impide tratar la inspección como una garantía general de validación estricta de toda la entrada.

Las grafías inglesas canónicas de los ejemplos alemanes declarados serían B y Bb. Una interfaz de alturas que incluya octava necesitaría además una octava declarada, por ejemplo B4 o Bb4. Una interfaz de símbolos de acordes tiene otro contrato: una B sola puede nombrar la fundamental de un acorde sin indicar un registro. La sintaxis propia de LilyPond para notas en minúsculas y octavas no es la sintaxis de entrada de GA.

### Ejercicio 2: elegir la representación de destino

Una fuente declara nombres alemanes y contiene H en la octava 4. Da una grafía inglesa que incluya la octava. ¿Qué debe establecerse antes de convertir una B sola de una partitura cuya convención no está especificada?

> **Respuesta:** H en la octava 4 se convierte en B4 según la convención declarada. Para la B sin convención especificada, establece primero la convención de nombres; añade una octava solo si el destino necesita una altura absoluta. El nombre de una fundamental por sí solo no proporciona registro.

## 3. Una operación posterior correcta no puede reparar una suposición anterior

Las [pruebas reales de la herramienta](../../../../code/streeling/evidence/pitch-context-2026-10-22/theory-tool-probes.json) registran la transposición de acordes de GA: subir B 2 semitonos devolvió C#, y subir Bb 2 devolvió C. Estas respuestas concuerdan con la aritmética de clases de altura: `(11+2)%12 = 1` y `(10+2)%12 = 0`. Se desconoce la revisión del servicio. Estas llamadas no ejecutan un adaptador de nombres alemanes ni demuestran que el analizador desplegado coincida con el commit inspeccionado.

La discrepancia de un semitono empieza en la interpretación. Reintentar la misma transposición, añadir una cadena de agentes más elaborada o aumentar la confianza conservaría la premisa equivocada.

### Ejercicio 3: rastrear el error

Un agente interpreta silenciosamente una B sin convención especificada como inglesa y aplica un capo 2. Compara esa respuesta con la interpretación alemana declarada. ¿Qué dato ausente explica la discrepancia?

> **Respuesta:** El B inglés lleva a C#, clase 1; el B alemán primero se convierte en Bb y lleva a C, clase 0. El dato ausente es la convención de nombres de notas. La operación de transposición puede ser aritméticamente correcta en ambas ramas.

## 4. Conservar contexto suficiente para revertir una decisión

Una propuesta de traspaso debería conservar el símbolo original, la convención declarada, la grafía canónica, la decisión de interpretación y las pruebas de la fuente. Es una propuesta orientativa de estructura de datos, no un nuevo esquema obligatorio para el ecosistema. Para el H alemán, conservar solo el B canónico pierde la grafía original aunque preserve la clase de altura elegida. Para una B sin resolver, conserva la ambigüedad en lugar de convertirla en una clase arbitraria con una advertencia en otro lugar.

No deduzcas un vocabulario entero a partir de una sustitución conveniente. Un adaptador general necesitaría alteraciones, convenciones de octava, sintaxis válida, comportamiento ante símbolos no admitidos y una declaración de la fuente que pueda revisarse. Esta pequeña tabla no pretende implementarlo todo.

### Ejercicio 4: conservar la distinción adecuada

Compara un B inglés y un H alemán después de que ambos se conviertan en B canónico. ¿Son el mismo texto original? Indica el contexto que un agente debería conservar si después debe explicar su decisión.

> **Respuesta:** No son el mismo texto original. Conserva el símbolo original y la convención declarada, la salida canónica y las pruebas de la interpretación. La igualdad de una clase de altura derivada no implica igualdad de procedencia ni de notación.

## 5. Verificar el tratamiento de la ambigüedad antes de ampliar el vocabulario

Usa las seis filas como ejercicio con acceso a las fuentes. Las cuatro filas resueltas deben conservar la correspondencia declarada. La B sin convención especificada debe quedar sin resolver; el H inglés está fuera del vocabulario declarado en este ejercicio. Distingue esas dos razones en lugar de reducirlas a un mismo valor predeterminado considerado satisfactorio.

Estas decisiones describen el comportamiento esperado de una interfaz propuesta, no el comportamiento medido de un nuevo componente de GA. [MCL-005](../../musicology/en/mcl-005-preserve-written-and-sounding-pitch.md) añade una distinción posterior a la grafía: una altura escrita codificada puede necesitar una transposición declarada para identificar su sonido.

### Ejercicio 5: rechazar una medida de éxito engañosa

Un adaptador devuelve una clase de altura para las seis filas y comunica una cobertura completa. Asigna la clase 11 a la B sin convención especificada y la clase 11 al H inglés. ¿Cumple la tabla declarada? Indica los resultados exigidos.

> **Respuesta:** No. Solo las cuatro filas resueltas tienen clases de altura declaradas. La B sin convención especificada necesita la convención; el H inglés está fuera del vocabulario declarado. Devolver un número para cada entrada oculta dos casos sin resolver o no admitidos y no demuestra una interpretación correcta.

## Tarea del estudiante con acceso a las fuentes

Completa la [tarea preparada](../../../../code/streeling/evidence/pitch-context-2026-10-22/learner-task.md) antes de abrir su rúbrica. Explica una discrepancia dependiente de la convención y redacta un traspaso que preserve el caso sin resolver. Se permite consultar las fuentes y usar una calculadora; aún no se han registrado respuestas reales de estudiantes ni decisiones de revisión.
