---
module_id: mus-025-keep-the-melody-in-a-voicing
department: music
course: Mantener la melodía exigida en un voicing
level: intermediate
alchemical_stage: albedo
prerequisites: [mus-012-chord-formulas-essential-tones-doubling, mus-016-recover-voice-correspondence, mus-024-preserve-attacks-and-harmonic-boundaries]
estimated_duration: "60 minutes"
produced_by: codex-project-analysis
version: "1.0.0"
---

# Mantener la melodía exigida en un voicing

## Pregunta del proyecto y entrega

Una sugerencia de acompañamiento contiene las notas correctas del acorde, pero la melodía se pierde entre ellas. Para este ejercicio de arreglo, la melodía exigida debe ser la **altura sonora más aguda, en el registro solicitado**. Filtra los candidatos según ese requisito explícito antes de comparar una penalización secundaria de posición. Es un contrato de arreglo elegido, no una regla universal que obligue a que toda melodía sea la voz más aguda.

El [punto de entrada del solucionador de tablaturas de GA en la versión de referencia](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L52) recibe conjuntos de alturas y genera posiciones sin un argumento explícito de función melódica en la firma de ese método. No deduzcas de ello una garantía sobre la voz más aguda. Esta observación del código fuente tiene un alcance más limitado que una afirmación sobre todas las funciones de GA. La solicitud de voicings en directo [falló](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/ga-voicings-probe.json), por lo que todos los candidatos siguientes se han construido deliberadamente y no se atribuyen a esa herramienta.

## 1. Decodificar los candidatos antes de ordenarlos

Utiliza la [afinación estándar de la versión de referencia](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs), expresada aquí de E grave a e agudo como `[40,45,50,55,59,64]`, con C4 = 60. La [indexación interna de la afinación de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs#L82) comienza por la cuerda más aguda; este conjunto de datos utiliza explícitamente el orden de grave a agudo. Un número de traste suma esa cantidad de semitonos; −1 significa cuerda silenciada y 0 significa cuerda al aire en este conjunto de datos. Los [datos conservados](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/melody-constraints.json) enumeran cada cuerda y cada altura.

| Candidato | Trastes, de E grave a e agudo | Altura sonora más aguda |
|---|---|---:|
| A | −1, 3, 2, 0, 0, 0 | 64 |
| B | −1, 3, 5, 4, 5, 3 | 67 |
| C | −1, 3, 2, 0, 0, −1 | 59 |
| D | −1, 3, 5, 4, 8, 0 | 67 |

Los cuatro contienen las clases de altura C, E, G, B: Cmaj7 con distintos registros y duplicaciones. El contenido del acorde por sí solo no determina qué altura queda arriba.

### Ejercicio práctico 1

Decodifica las alturas sonoras de A y B en orden de cuerdas. ¿Cuál tiene E4 arriba?

> **Respuesta:** A da `[48,52,55,59,64]`; B da `[48,55,59,64,67]`. Solo A tiene E4 = 64 arriba. B contiene E4, pero también G4 = 67, que es más agudo. Son comprobaciones aritméticas de posiciones construidas, no interpretaciones grabadas ni voicings generados.

## 2. Distinguir tres preguntas sobre la melodía

Cada candidato contiene la clase de altura 4, E. Los candidatos A, B y D contienen la altura 64 en su registro concreto. Solo A tiene 64 como altura sonora más aguda. Estas pruebas responden a preguntas distintas: pertenencia a las notas del acorde, presencia en el registro exigido y el contrato específico sobre la voz superior.

En [MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/duration/), el [modelo de nota](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L93) puede conservar una etiqueta de voz. Esa etiqueta identifica una voz escrita; no debe sustituirse de forma implícita por una ordenación de alturas. Si la tarea musical asigna la melodía a una voz interior, el predicado de altura máxima de esta lección no es el contrato adecuado.

### Ejercicio práctico 2

¿Qué candidatos superan cada prueba: contiene E en cualquier octava; contiene E4; tiene E4 arriba?

> **Respuesta:** Cualquier E: A, B, C y D. E4 presente: A, B y D. E4 arriba: solo A. El candidato C contiene E3 = 52 en lugar de E4, y su altura más aguda es B3 = 59. No sustituyas una prueba por otra.

## 3. Una cuerda más aguda no tiene por qué producir la altura más aguda

En D, la cuerda de B en el traste 8 suena como 59 + 8 = 67, mientras que la cuerda de e agudo al aire suena como 64. Por tanto, la última cuerda no silenciada de la matriz no contiene la altura más aguda. Para este contrato, calcula el máximo de las alturas que suenan en lugar de tomar la última entrada de la matriz.

Esto es posible porque el orden de las cuerdas y el de las alturas sonoras son distintos. El ejemplo no afirma que la digitación sea cómoda, que se haya tocado un cruce de cuerdas ni que una melodía concreta tenga continuidad física a lo largo de una frase. MUS-016 distingue las identidades de las voces de las cuerdas; MUS-024 distingue las notas sostenidas de los ataques.

### Ejercicio práctico 3

Para D, identifica la altura más aguda y su cuerda, y después la altura de la última cuerda que suena. ¿Conservar la última entrada sonora impondría la condición exigida de E4 arriba?

> **Respuesta:** La más aguda es G4 = 67 en la cuerda de B, traste 8. La última entrada sonora es e agudo al aire = 64. No: aceptar D a partir de esa entrada ignoraría el G4 más agudo. Una posición en el orden de las cuerdas no garantiza el orden de las alturas.

## 4. Aplicar el requisito musical antes de la preferencia flexible

Como preferencia secundaria deliberadamente aproximada, define la posición de un candidato como su traste positivo mínimo. Con una posición anterior de 3, define la penalización como la diferencia absoluta de posición. Las posiciones de A, B, C y D son 2, 3, 2 y 3; las penalizaciones son 1, 0, 1 y 0.

Esta penalización construida no es la puntuación de dificultad de GA, su término de inercia ni su objetivo físico completo. Ignora muchos aspectos de la ejecución. El mínimo sin restricciones incluye B y D, que incumplen el requisito de E4 arriba. Filtrar primero deja A, cuya penalización secundaria es 1. Una penalización flexible menor no debe anular de forma implícita un requisito musical obligatorio.

### Ejercicio práctico 4

Aplica la condición melódica obligatoria y después la penalización secundaria de posición. ¿Qué candidato queda y qué afirmación sobre la ejecución sigue sin estar respaldada?

> **Respuesta:** Solo queda A y tiene una penalización de 1. Ni el cálculo del traste positivo mínimo ni la prueba melódica establecen la elección de dedos, la comodidad de la apertura de la mano ni la facilidad de ejecución. Para ello se necesita una prueba concreta al instrumento y un criterio explícito para el intérprete.

## 5. Preservar el registro cuando el conjunto de candidatos está vacío

Cambia la melodía superior exigida a E5 = 76. Ningún candidato conservado la alcanza. Una prueba limitada a clases de altura seguiría aceptando el E4 superior de A, pero está una octava por debajo de la nota solicitada. Informa de que el conjunto de soluciones factibles está vacío; obtener otros candidatos o cambiar el requisito del arreglo es una decisión aparte.

Entrega la altura y la función de la melodía, la afinación, los candidatos decodificados, los resultados exactos del filtro, el objetivo secundario y las preguntas de ejecución pendientes. El [material para el alumno](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/learner-task.md) comprueba estas afirmaciones sin aportar un resultado de participantes ni fingir que se ha publicado una extensión de GA que tenga en cuenta la función melódica.

### Ejercicio práctico 5

Un agente responde a la solicitud de E5 con A porque su altura más aguda tiene la misma clase de altura. ¿Qué debería decir la transferencia en su lugar?

> **Respuesta:** «Ninguno de los cuatro candidatos construidos tiene 76 como altura sonora más aguda. A tiene 64, una octava más abajo, y no cumple el requisito indicado». Mantén la restricción exacta de registro salvo que una nueva decisión de arreglo la cambie. Ningún voicing devuelto en directo ni resultado de ejecución al instrumento justifica relajarla aquí.
