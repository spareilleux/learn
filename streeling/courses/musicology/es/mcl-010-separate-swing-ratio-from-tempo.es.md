---
module_id: mcl-010-separate-swing-ratio-from-tempo
department: musicology
course: "Distinguir la proporción de swing del tempo"
level: intermediate
prerequisites: ["mcl-004-model-timing-without-inventing-a-style", "mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Distinguir la proporción de swing del tempo

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Un agente cambia una proporción de swing ralentizando toda la frase. Modifica la duración total del pulso cuando se pedía redistribuirlo internamente. Separamos ambos controles con un modelo construido de dos notas. El modelo no define géneros ni predice decisiones temporales de intérpretes reales.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: mcl-004-model-timing-without-inventing-a-style](../../musicology/en/mcl-004-model-timing-without-inventing-a-style.md)

[Prerrequisito: mcl-006-preserve-meter-grouping-and-tempo-units](../../musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Artefacto del proyecto conservado](../../../../streeling/courses/musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Paquete de datos construidos](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Referencia primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/swing/)

## 1. Ejercicio 1

Estipule 120 negras por minuto y dos eventos nominales por negra. El pulso dura .5 segundos. La proporción 2:1 asigna dos partes al primer evento y una al segundo. El denominador es la suma de partes.

¿Cuánto dura el pulso y cuántas partes contiene?

> **Respuesta.** Dura .5 segundos y contiene 3 partes de proporción.

## 2. Ejercicio 2

Las duraciones son `(.5)*2/3=1/3` y `(.5)*1/3=1/6` segundos. Suman .5: es la comprobación de conservación del pulso. Redondear cada evento antes de acumular muchos pulsos puede añadir error; conserve fracciones exactas al verificar el ejemplo.

Calcule duraciones y suma.

> **Respuesta.** Son `1/3` y `1/6` segundos, y suman `.5` segundos.

## 3. Ejercicio 3

Mantenga el tempo y cambie a proporción 1:1. Ambos eventos duran .25 segundos. No cambia el pulso total, pero sí la frontera interna. Así se distingue redistribución de ralentización. En cambio, modificar el tempo global escala ambas duraciones manteniendo su proporción en este modelo.

¿Qué cambia entre proporciones al mismo tempo?

> **Respuesta.** Cambia la división interna; la duración total sigue siendo .5 segundos.

## 4. Ejercicio 4

Como control negativo, ralentice el ritmo igual a 60 negras por minuto. Cada evento dura .5 segundos, con total 1 segundo. No coinciden ni duraciones ni suma con el caso 2:1 original. Sentir una frase más lenta no implementa un cambio de proporción a tempo fijo.

¿El ritmo igual ralentizado reproduce la pareja original?

> **Respuesta.** No. `[.5,.5]` difiere de `[1/3,1/6]` y cambia el total de .5 a 1 segundo.

## 5. Ejercicio 5

La referencia MusicXML define proporciones nominales y límites de aplicación. El curso conservado aporta el requisito separado de unidad de tempo. Una propuesta GA debe identificar eventos elegibles e interacción con ligaduras y cambios de tempo. Una palabra genérica de estilo no proporciona esas políticas.

¿Qué debe acompañar la proporción en una entrega?

> **Respuesta.** Unidad de pulso, tempo, tipo elegible, proporción y casos no admitidos; no se deduce estilo interpretado ni identidad cultural.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
