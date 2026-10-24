---
module_id: wml-009-translate-rhythmic-terms-without-changing-counted-units
department: world-music-languages
course: "Traducir términos rítmicos sin cambiar las unidades contadas"
level: intermediate
prerequisites: ["wml-006-preserve-the-origin-of-an-additive-cycle", "mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Traducir términos rítmicos sin cambiar las unidades contadas

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Una traducción conserva el número 6, pero cambia qué se cuenta. La igualdad del numeral no basta para comprobar localización. Definimos una consigna inventada con unidad explícita y comparamos dos propuestas por duración y comienzos de grupos. La tarea comprueba unidades semánticas sin atribuir vocabulario ni prácticas a una cultura.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: wml-006-preserve-the-origin-of-an-additive-cycle](../../world-music-languages/en/wml-006-preserve-the-origin-of-an-additive-cycle.md)

[Prerrequisito: mcl-006-preserve-meter-grouping-and-tempo-units](../../musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Artefacto del proyecto conservado](../../../../streeling/courses/musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Paquete de datos construidos](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Ejercicio 1

La fuente pide seis corcheas a 120 negras por minuto. Cada unidad vale .5 negras, con total 3 negras y 1.5 segundos. Conserve juntos cantidad y unidad. Puede reformularse la instrucción, pero debe poder recuperarse la magnitud operativa.

Calcule la duración original en negras y segundos.

> **Respuesta.** Son 3 negras, equivalentes a 1.5 segundos con la unidad de tempo indicada.

## 2. Ejercicio 2

A conserva seis corcheas. B pide seis negras. B mantiene el numeral, pero suma 6 negras y 3 segundos. Este control descubre una sustitución de unidad semántica. La revisión debe mostrarla sin depender del número de palabras iguales ni de un término métrico familiar.

¿Qué duración pide B?

> **Respuesta.** Pide 6 negras, o 3 segundos, el doble del original.

## 3. Ejercicio 3

Añada grupos `[3,3]` en corcheas, con comienzos `[0,3]`. Conservar duración no autoriza reagrupar como `[2,2,2]`, con comienzos `[0,2,4]`. La comprobación de unidades incorpora así fronteras ordenadas. No describen intensidad interpretada: son marcadores construidos.

Dé ambas listas e indique qué no demuestra igualar totales.

> **Respuesta.** Son `[0,3]` y `[0,2,4]`; totales iguales no demuestran agrupación idéntica.

## 4. Ejercicio 4

Puede conservarse un término local con glosa en lugar de sustituirlo por un supuesto equivalente universal. El registro propuesto guarda término, unidad contada, grupos, unidad de tempo y justificación. Una convención ausente sigue sin resolver. Idioma de interfaz y ubicación no determinan el conteo musical.

¿Qué hacer si falta la unidad contada?

> **Respuesta.** Conserve el término y obtenga su unidad operativa, sin elegir silenciosamente una duración plausible.

## 5. Ejercicio 5

Lea los ejemplos de unidades y comienzos anclados de los prerrequisitos antes de preparar la consigna. La operación añadida es un registro que recalcula la cantidad contada. No es un diccionario ni prueba de aprobación lingüística. Mantenga abiertas las decisiones de revisión.

¿Cuál es la referencia manual de aceptación?

> **Respuesta.** Igualar duración, unidades contadas y grupos anclados ordenados; los juicios lingüístico y musical siguen pendientes y separados.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
