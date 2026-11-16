---
module_id: mcl-009-preserve-pickup-offsets-in-bar-addresses
department: musicology
course: "Conservar el desfase de anacrusa en las direcciones de compás"
level: intermediate
prerequisites: ["mcl-006-preserve-meter-grouping-and-tempo-units", "mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Conservar el desfase de anacrusa en las direcciones de compás

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Un agente localiza una nota por compás y pulso, pero trata la anacrusa como un compás completo. Desplaza entonces todos los tiempos posteriores. Este curso separa identidad escrita y duración real en una partitura construida de una voz. No analiza archivos ni deduce una interpretación expresiva de la notación.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: mcl-006-preserve-meter-grouping-and-tempo-units](../../musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Prerrequisito: mcl-007-integrate-a-midi-tempo-map-before-scheduling](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefacto del proyecto conservado](../../../../streeling/courses/musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Paquete de datos construidos](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Referencia primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/measure-partwise/)

## 1. Ejercicio 1

Use etiquetas `0`, `1`, `2`, con duraciones reales `[1,4,4]` en negras. La primera es una anacrusa construida. Las etiquetas identifican; no multiplican una duración. Las sumas prefijas dan `[0,1,5]` desde el origen del extracto.

¿En qué posiciones absolutas comienzan los compases?

> **Respuesta.** En `[0,1,5]`; la anacrusa aporta 1 negra, no 4.

## 2. Ejercicio 2

Sitúe un evento en desfase local 1, contado desde cero, del compás 2. La coordenada absoluta es `5+1=6`. Explicitar la convención evita confundir desfase y número visible de pulso. La dirección local sigue ligada al compás aunque cambie el origen del extracto.

Dé la coordenada absoluta del evento.

> **Respuesta.** Son 6 negras desde este origen; conserve también etiqueta 2 y desfase local 1.

## 3. Ejercicio 3

A 120 negras por minuto constantes, cada negra dura .5 segundos. La coordenada 6 corresponde a 3 segundos. Un mapa de tempo requeriría integrar como en el prerrequisito. Corregir anacrusa e integrar tempo resuelve problemas distintos; deben mantenerse ambos cuando proceda.

Convierta el evento a segundos con esa velocidad.

> **Respuesta.** `6*60/120=3` segundos; no se midieron ataque expresivo ni latencia grabada.

## 4. Ejercicio 4

Como control negativo, sustituya la duración real de anacrusa por 4. Los comienzos pasan a `[0,4,8]` y la misma dirección local da 9 negras. El error es 3 negras, equivalentes aquí a 1.5 segundos. El texto de dirección puede seguir igual aunque el modelo desplace el evento.

¿Qué error crea el atajo?

> **Respuesta.** Añade 3 negras, equivalentes a 1.5 segundos con el tempo declarado.

## 5. Ejercicio 5

MusicXML permite identificadores textuales y describe numeración implícita relacionada con anacrusas. Lea la definición junto al prerrequisito. Eso no convierte la suma en un importador general: acordes, voces, desplazamientos y divisiones variables requieren tratamiento explícito. El informe debe conservar dirección y coordenada acumulada.

¿El número de compás determina el tiempo transcurrido?

> **Respuesta.** No. Hacen falta duraciones reales, desfase local, origen y tempo; la numeración no basta.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
