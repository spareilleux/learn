---
module_id: mcl-011-keep-repeats-separate-from-written-bar-identity
department: musicology
course: "Distinguir las repeticiones de la identidad de los compases escritos"
level: intermediate
prerequisites: ["mcl-002-musical-form", "mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Distinguir las repeticiones de la identidad de los compases escritos

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Un alumno pide volver a la segunda aparición de un compás. Su identificador escrito no distingue dos visitas durante la reproducción. Expandimos un plan de repetición acotado preservando identidad escrita. Recorrido, tiempo transcurrido y notación permanecen separados; no se implementa un intérprete general ni se afirma una ejecución musical.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: mcl-002-musical-form](../../musicology/en/mcl-002-musical-form.md)

[Prerrequisito: mcl-007-integrate-a-midi-tempo-map-before-scheduling](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefacto del proyecto conservado](../../../../streeling/courses/musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Paquete de datos construidos](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Referencia primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/repeat/)

## 1. Ejercicio 1

Declare A, B y C, de cuatro negras cada uno. El recorrido construido es `[A,B,A,B,C]`. La identidad escrita no cambia al volver. Una visita necesita su propia ocurrencia; de otro modo las anotaciones posteriores pueden sobrescribir las anteriores.

¿Cuántos compases escritos y visitas hay?

> **Respuesta.** Hay 3 compases escritos y 5 visitas; B tiene 2 visitas.

## 2. Ejercicio 2

Acumular duraciones de visitas da `[0,4,8,12,16]` en negras. El segundo B comienza en 12 y el primero en 4. Por tanto, B más desfase local no basta para señalar una visita concreta.

¿Dónde empieza el segundo B?

> **Respuesta.** En la coordenada 12; conserve por separado identidad escrita B y segunda ocurrencia.

## 3. Ejercicio 3

El recorrido dura 20 negras. Deduplicar a `[A,B,C]` da solo 12. Este control muestra que igualdad del conjunto de compases no conserva visitas ordenadas ni duración. A la vez, representar otra visita no exige copiar el compás con nueva identidad escrita.

¿Qué error temporal causa deduplicar?

> **Respuesta.** El total baja de 20 a 12 negras: se pierden 8.

## 4. Ejercicio 4

La definición MusicXML distingue dirección y número de repeticiones en su contexto. Aquí el recorrido se aporta explícitamente, sin deducirlo de sintaxis arbitraria. Finales alternativos, anidamientos y saltos quedan fuera. Lo no admitido debe seguir sin resolver en vez de recibir una expansión plausible sin probar.

¿El ejemplo certifica toda interpretación de repeticiones?

> **Respuesta.** No. Solo se comprueba el recorrido dado de cinco visitas; otros casos necesitan reglas y pruebas.

## 5. Ejercicio 5

El curso conservado explica cómo convertir coordenadas en tiempo según un mapa de tempo. Aplíquelo tras elegir visita y origen. Una anotación futura debe identificar revisión de partitura, compás, visita, posición local y tempo. Los campos facilitan revisión sin imponer un esquema nuevo.

¿Qué distingue una anotación de segunda visita?

> **Respuesta.** Identidad de visita y contexto de recorrido; B por sí solo no identifica la segunda ocurrencia.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
