---
module_id: mus-016-recover-voice-correspondence
department: music
course: Una distancia mínima no identifica las voces
level: intermediate
alchemical_stage: albedo
prerequisites: [mus-015-choose-voice-leading-equivalences]
estimated_duration: "60 minutes"
produced_by: codex-project-lab
version: "1.0.0"
---

# Una distancia mínima no identifica las voces

## Pregunta del proyecto y entregable

Un agente de GA dispone de una distancia mínima. ¿Puede decirle a un guitarrista qué línea sigue cada nota? Produce dos tablas de correspondencia explícitas, trasládalas a dos cuerdas de guitarra e identifica lo que la puntuación no permite decidir. Lee primero [MUS-015](mus-015-choose-voice-leading-equivalences.md): una distancia depende de las equivalencias elegidas.

El [método de distancia de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Atonal/VoiceLeadingSpace.cs) fijado devuelve un escalar. No devuelve una asignación, un movimiento con signo, una elección de cuerda ni una duración. El [laboratorio didáctico](https://github.com/spareilleux/learn/tree/codex/streeling-craft-transfer-20261022/code/streeling/voice-leading) enumera las asignaciones de forma independiente para pequeños casos fijos y conserva algunos testigos. Esos testigos son nuevos resultados didácticos, no una función existente de la API de GA.

## 1. Recuperar dos asignaciones igualmente mínimas

Toma el origen `[60,62]` y la colección de destino `[64,65]`. Activa las equivalencias de octava y permutación; desactiva la transposición y la inversión. El escalar nativo es 7. La enumeración exhaustiva encuentra dos asignaciones con ese mismo coste:

| Plan | Primera voz identificada | Segunda voz identificada | Movimientos con signo | Coste circular total |
|---|---|---|---|---:|
| A | 60 → 64 | 62 → 65 | +4, +3 | 7 |
| B | 60 → 65 | 62 → 64 | +5, +2 | 7 |

Ambos movimientos de voz son menores que media octava, por lo que aquí cada coste circular de pareja es igual al valor absoluto de su movimiento teniendo en cuenta el registro. Esa igualdad es específica de estas parejas; en otros casos, el coste con equivalencia de octava puede ocultar una octava.

### Ejercicio práctico 1

¿Una distancia de 7 selecciona únicamente el plan A? Explícalo usando ambas sumas.

> **Respuesta:** No. El plan A cuesta 4 + 3 = 7 y el plan B cuesta 5 + 2 = 7. El escalar descarta qué correspondencia lo produjo. Una regla de desempate podría elegir una, pero sería una política adicional.

## 2. Distinguir la identidad de una voz del orden de las alturas

Al principio, la primera voz es la más grave: 60 está por debajo de 62. En el plan A sigue siendo la más grave, ya que 64 está por debajo de 65. En el plan B, la primera voz identificada termina por encima de la segunda, ya que 65 está por encima de 64. El orden relativo de las alturas se invierte. Llamar «primera voz» a la entrada de destino más grave después de ordenar cambiaría implícitamente la identidad de las voces del plan B.

Este es un ejemplo de correspondencia discreta. No hemos especificado duraciones de notas ni trayectorias continuas de altura. No demuestra un cruce audible durante una interpretación grabada. Del mismo modo, un movimiento total pequeño no demuestra por sí solo la aceptabilidad estilística ni la ausencia de intervalos paralelos.

### Ejercicio práctico 2

Para una tarea que exige que las voces identificadas conserven su orden relativo de altura en los extremos, ¿qué plan cumple ese requisito?

> **Respuesta:** El plan A. El plan B invierte el orden en los extremos aunque su coste total también sea 7. Declara el requisito de orden explícitamente; no se puede recuperar a partir del mínimo por sí solo.

## 3. Colocar las mismas notas en una guitarra

La [afinación predeterminada fijada](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs) incluye las cuerdas al aire G3 = 55 y B3 = 59 en esta convención numérica. Avanzar un traste añade un semitono. Usa los nombres de las cuerdas para conservar su identidad:

| Estado | Cuerda de sol | Cuerda de si | Alturas identificadas resultantes |
|---|---|---|---|
| Origen | Traste 5 | Traste 3 | 60, 62 |
| Destino del plan A | Traste 9 | Traste 6 | 64, 65 |
| Destino del plan B | Traste 10 | Traste 5 | 65, 64 |

Estas colocaciones son construidas y se han comprobado mediante sumas. No las generó un solucionador de digitaciones de GA ni las tocó un participante. Que una voz permanezca en una cuerda es una posible regla de identidad; una línea musical también puede cambiar de cuerda. Por tanto, la identidad de la cuerda y la de la voz musical deben declararse por separado.

### Ejercicio práctico 3

Verifica las dos notas del plan B a partir de las alturas de las cuerdas al aire. ¿La inversión del orden de las alturas requiere que las cuerdas intercambien sus posiciones físicas?

> **Respuesta:** 55 + 10 = 65 y 59 + 5 = 64. No. La cuerda de sol sigue siendo la cuerda de sol y la cuerda de si sigue siendo la cuerda de si; la elección de trastes puede invertir las alturas relativas que producen. No se afirma que haya un cruce físico de cuerdas.

## 4. Examinar un testigo y los límites de sus pruebas

En los [resultados nativos conservados](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/native-results.json), busca `ambiguous_plan`. Registra `minimumAssignmentCount` como 2 y conserva los dos `witnesses`. Sus `motions` son las diferencias destino menos origen teniendo en cuenta el registro; los `voiceCosts` son costes absolutos o circulares de octava según los ajustes del caso. Lee estos campos por separado.

Para repetir la ejecución, sigue las instrucciones de MUS-015 con [Node.js](https://nodejs.org/api/cli.html) y [.NET](https://learn.microsoft.com/dotnet/core/tools/dotnet-build) ya instalados. La ejecución independiente utiliza las fuentes sin cambios en un ensamblado separado con un adaptador de anotaciones documentado. Windows está evaluado; Linux / WSL y macOS siguen por verificar. La ejecución no procesa la tabla de colocaciones en la guitarra mediante un solucionador.

### Ejercicio práctico 4

Para el contraejemplo separado `[60,63,65]` emparejado con `[60,75,65]`, ¿por qué puede `motions` contener 12 mientras que cada entrada circular de `voiceCosts` es 0?

> **Respuesta:** La segunda altura identificada sube de 63 a 75, un movimiento de 12 semitonos teniendo en cuenta el registro. La equivalencia de octava asigna a esa pareja un coste circular de 0. El testigo conserva la diferencia teniendo en cuenta el registro; el objetivo elegido ignora su componente de octava.

## 5. Redactar un traspaso orientado a la interpretación

Un traspaso útil indica la colección de alturas, la correspondencia seleccionada, la regla de identidad, la política de desempate y las preguntas instrumentales pendientes. Para este ejercicio, selecciona el plan A si se exige conservar el orden de las alturas en los extremos. Deja sin evaluar la elección de dedos, la comodidad y la articulación hasta que un intérprete pruebe una colocación concreta. El [dossier de revisión](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/learner-task.md) presenta una tarea que puede comprobarse a partir de las pruebas sin inventar un resultado de escucha.

### Ejercicio práctico 5

Un agente escribe «distancia 7, por tanto la digitación más fácil». Sustituye esa afirmación por una declaración defendible.

> **Respuesta:** «Ambas asignaciones declaradas tienen coste 7 con las equivalencias indicadas. Seleccionamos el plan A para conservar el orden de las alturas en los extremos. Su colocación en el traste 9 de la cuerda de sol y en el traste 6 de la cuerda de si es construida; la comodidad y la elección de dedos aún requieren una prueba instrumental». Continúa con la [clasificación de candidatos](mus-017-audit-voice-leading-rankings.md).
