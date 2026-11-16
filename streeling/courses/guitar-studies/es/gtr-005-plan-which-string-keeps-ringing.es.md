---
module_id: gtr-005-plan-which-string-keeps-ringing
department: guitar-studies
course: "Planificar qué cuerda debe seguir sonando"
level: intermediate
prerequisites: ["gtr-003-audit-voicing-playability"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Planificar qué cuerda debe seguir sonando

> **Alcance del borrador.** Nueva ejecución autónoma de funciones F# de posiciones sin modificar, inspección de fuentes fijadas a una revisión y cálculos creados para eventos sostenidos. Siguen pendientes las revisiones musicales, técnicas humanas, lingüísticas y con estudiantes, así como la verificación del HTML desplegado del curso. No se tocó ninguna guitarra ni se ejecutó un planificador temporal de GA o un motor de audio.

## La pregunta del proyecto

Una nota puede tocarse en varios lugares de una guitarra. ¿Elegir un lugar válido para cada nota de forma independiente produce una frase en la que todas las notas pedidas siguen sonando? Conservaremos las identidades de cuatro eventos y probaremos un modelo limitado: una nota sostenida de forma independiente por cuerda en cada instante, sin cambiar de cuerda dentro de un evento sostenido. Esto excluye las transferencias, los nuevos ataques y las técnicas especiales; no es una descripción universal de las posibilidades físicas de la guitarra.

## 1. Conciliar la numeración de cuerdas antes de componer funciones

Las [funciones MIDI de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MidiTypes.fs) fijadas a la revisión usan la afinación Standard `[40,45,50,55,59,64]`, con la cuerda 1 en el extremo grave. El [modelo de afinación C#](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs) inspeccionado normaliza su valor predeterminado colocando primero la cuerda más aguda. En toda esta lección, la numeración convencional de guitarra asigna la cuerda 1 al mi agudo E4 y la cuerda 6 al mi grave E2, con C4 = MIDI 60.

Para este caso de seis cuerdas, convierte un índice F# s en el índice convencional `7-s`. El [registro de la nueva ejecución](../../../../code/streeling/evidence/phrase-performance-2026-10-22/native-execution.json) documenta la carga del código fuente sin modificar mediante [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) con el SDK 10.0.113. Dieciséis casos de entrada cubren dos afinaciones, dos límites de traste y cuatro alturas. El adaptador de coordenadas y la búsqueda temporal son cálculos creados para el ejemplo, no un puente implementado ni una ejecución de C#.

### Ejercicio 1: convertir una posición devuelta

La función F# devuelve la cuerda 4, traste 5, para MIDI 60. ¿Qué cuerda convencional es y qué nota al aire verifica la altura? ¿Mantener el número de cuerda 4 sin cambios conservaría su significado entre estas convenciones inspeccionadas?

> **Respuesta:** `7-4=3`, la cuerda convencional de sol G3, con MIDI 55 al aire. Al sumar el traste 5 se obtiene 60. Mantener el número 4 identificaría en cambio la cuerda convencional de re D3, de modo que cambiaría el significado de la coordenada. El adaptador es específico del orden declarado de seis cuerdas.

## 2. Conservar las posiciones candidatas válidas

Con un traste máximo de 5, las salidas reales de la función dan estas posiciones convencionales:

| Altura | Posiciones candidatas de cuerda/traste convencionales |
| --- | --- |
| C4, MIDI 60 | cuerda 3 traste 5; cuerda 2 traste 1 |
| E4, MIDI 64 | cuerda 2 traste 5; cuerda 1 traste 0 |
| G4, MIDI 67 | cuerda 1 traste 3 |
| D4, MIDI 62 | cuerda 2 traste 3 |

Las llamadas independientes de selección de la mejor posición del código fuente eligen respectivamente las cuerdas 2, 1, 1 y 2. Cada posición produce la altura pedida. Las elecciones de E y G usan la misma cuerda, por lo que sus duraciones decidirán si pueden coexistir. La función responde a una pregunta estática; no es un solucionador temporal que haya fallado.

### Ejercicio 2: identificar la restricción que falta

¿Por qué E4 en la cuerda 1 traste 0 y G4 en la cuerda 1 traste 3, elegidas por separado, pueden entrar en conflicto aunque ambas posiciones sean válidas? ¿Qué observación hace falta además de la lista de alturas?

> **Respuesta:** Según el modelo declarado, no pueden sostenerse de forma independiente en la misma cuerda durante un solapamiento. Sus inicios, finales e identidades de evento determinan si existe ese solapamiento. Una lista de posiciones válidas por nota no basta para responder a la pregunta temporal.

## 3. Planificar una nota sostenida antes del ataque posterior

Usa estos eventos creados para el ejemplo en pulsos absolutos de negra. Cada intervalo incluye su inicio y excluye su final.

| Evento | Altura MIDI | Inicio | Final |
| --- | --- | --- | --- |
| C | 60 | 0 | 4 |
| E | 64 | 0 | 2 |
| G | 67 | 1 | 2 |
| D | 62 | 2 | 3 |

C y E tienen inicialmente tres asignaciones en cuerdas distintas. Solo C en la cuerda 3 traste 5 y E en la cuerda 2 traste 5 permiten incorporar el ataque de G en la cuerda 1 traste 3 sin mover un evento sostenido. En el pulso 2, E y G han terminado; D puede reutilizar la cuerda 2 en el traste 3. La enumeración exhaustiva de asignaciones da un plan completo con estos candidatos y supuestos.

### Ejercicio 3: preservar los eventos sostenidos

Indica el plan completo. ¿Por qué una elección inicial localmente válida de C en la cuerda 2 y E en la cuerda 1 puede fallar cuando llega G? ¿Mover silenciosamente cualquiera de las notas sostenidas a otra cuerda conserva la misma realización del evento?

> **Respuesta:** C usa la cuerda 3 traste 5; E la cuerda 2 traste 5; G la cuerda 1 traste 3; D la cuerda 2 traste 3. La otra elección inicial ocupa la única cuerda admisible de G mientras E debe continuar. Mover una nota sostenida exigiría un modelo de transferencia o nuevo ataque declarado por separado; este problema de asignación no lo permite de forma implícita.

## 4. Mostrar el conflicto en vez de inventar una digitación

Adelanta el inicio de D al pulso 1.5 y conserva su final en 3. Entre los pulsos 1.5 y 2, los cuatro eventos están activos. Con un límite de traste de 5, el conjunto de sus cuerdas admisibles se reduce a las cuerdas 1, 2 y 3. Cuatro eventos simultáneos independientes no pueden asignarse de forma inyectiva a esas tres cuerdas. No existe una asignación válida en este modelo, aunque cada evento tenga al menos una posición para su altura.

El [mapper de posiciones C#](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Analysis/FretboardPositionMapper.cs) fijado a la revisión ya filtra las cuerdas repetidas dentro de una forma de acorde simultáneo. No conserva la cuerda de un evento sostenido a lo largo de una frase temporizada. Son restricciones relacionadas con alcances distintos; este curso no ejecuta ni sustituye ese mapper.

### Ejercicio 4: enunciar la imposibilidad concreta

¿Qué testigo de solapamiento demuestra el conflicto de D anticipado? ¿Prueba que ningún guitarrista podrá tocar nunca esas alturas o que todas las rutas de GA están rotas?

> **Respuesta:** En el intervalo semiabierto de 1.5 a 2, cuatro eventos activos solo tienen tres cuerdas admisibles bajo la afinación Standard, el límite de traste y el supuesto de monofonía por cuerda. Eso demuestra la inviabilidad de este modelo de asignación declarado. Otros rangos, técnicas o cambios musicales son posibilidades distintas; no establece una imposibilidad física universal ni un fallo de todo el sistema.

## 5. Separar una solución del modelo de un resultado para el músico

Mantener el inicio anticipado, pero ampliar el límite de traste permitido a 10, da tres asignaciones completas; el límite de 9 sigue sin dar ninguna. Un plan ampliado usa C en la cuerda 4 traste 10, E en la cuerda 1 al aire, G en la cuerda 2 traste 8 y D en la cuerda 3 traste 7. Su amplitud entre trastes positivos es de 3. Esto verifica las alturas y la ocupación bajo el modelo, no el alcance de la mano del músico, el apagado de cuerdas, el timbre ni la limpieza de ejecución.

### Ejercicio 5: concretar la siguiente comprobación

Un agente afirma que el plan ampliado tiene una «tocabilidad demostrada». Reformula la afirmación e identifica las observaciones todavía necesarias para la decisión del guitarrista.

> **Respuesta:** El plan satisface las restricciones declaradas de altura, tiempo, ocupación de cuerdas y rango ampliado. Un guitarrista aún debe comprobar la digitación real, el sostenimiento independiente, el apagado de cuerdas, las transiciones limpias y el sonido en contexto. Aquí no hubo ningún ensayo con un músico, por lo que esos resultados siguen sin verificar.

El [registro fijo de ocupación](../../../../code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json) conserva los candidatos, los planes y el testigo de solapamiento. [GAA-005](../../guitar-alchemist-academy/en/gaa-005-repair-a-phrase-without-hiding-the-change.md) compara posibles cambios de la petición en lugar de ocultarlos dentro de una supuesta solución.
