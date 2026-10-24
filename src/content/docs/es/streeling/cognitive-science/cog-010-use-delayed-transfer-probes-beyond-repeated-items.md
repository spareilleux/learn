---
title: Usar pruebas diferidas de transferencia más allá de los elementos repetidos
description: Usar pruebas diferidas de transferencia más allá de los elementos repetidos — Ciencia cognitiva
sidebar:
  label: COG-010 · Usar pruebas diferidas de transferencia más allá de los elementos repetidos
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/es/cog-010-use-delayed-transfer-probes-beyond-repeated-items.es.md
---

:::note[Streeling University]
**COG-010** · Usar pruebas diferidas de transferencia más allá de los elementos repetidos · intermedio · 45 minutos

Generado por el departamento *Ciencia cognitiva* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/es/cog-010-use-delayed-transfer-probes-beyond-repeated-items.es.md) · [Mi diario](../../journal/)

Requisitos previos: [COG-007](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/), [COG-008](../../cognitive-science/cog-008-choose-probes-that-distinguish-reasoning-models/)
:::

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [cog-007-separate-unaided-recall-from-assisted-success.md](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/)
- [cog-008-choose-probes-that-distinguish-reasoning-models.md](../../cognitive-science/cog-008-choose-probes-that-distinguish-reasoning-models/)

Un agente de práctica anuncia buen rendimiento porque el aprendiz responde correctamente a preguntas repetidas. El equipo quiere saber si puede aplicar la misma regla a un voicing nuevo más tarde. Son preguntas que necesitan observaciones distintas. El requisito previo sobre asistencia conserva el historial de pistas, y el de diseño de pruebas pregunta si una respuesta distingue reglas candidatas. Esta lección organiza esas diferencias por exposición y demora de evaluación.

El paquete fijo contiene recuentos ficticios. Los elementos repetidos inmediatos, repetidos diferidos y nuevos diferidos tienen denominadores propios. Nuevo significa que no se practicó la pregunta exacta según la definición declarada; no garantiza que todas sus características sean desconocidas. Una afirmación de transferencia debe indicar qué cambió y qué regla sigue siendo aplicable. Sin ello, una puntuación diferida podría medir reconocimiento de la misma respuesta.

Una respuesta correcta a un elemento nuevo estuvo precedida por la exposición de la solución. Según nuestro criterio sin ayuda, no es elegible: elimínela tanto del numerador como del denominador elegible. Conserve los recuentos originales y el motivo de exposición. Un éxito excluido no se transforma en un error observado. No se proporciona un total de elementos ausentes, por lo que estas tasas observadas no representan a todas las personas invitadas.

Compare descriptivamente las tasas inmediata y diferida de elementos repetidos. Su diferencia no estima olvido causado por el tiempo: faltan historiales individuales y pruebas de asignación. La tasa de elementos nuevos tampoco estima un efecto causal de transferencia producido por GA. El control negativo utiliza solo preguntas repetidas. Puede mostrar éxito sobre ellas según su regla, pero no fabricar observaciones de elementos nuevos.

Para la tarea asistida por fuentes, examine las exclusiones por asistencia y la distinción entre modelos de predicción. Diseñe dos pruebas de voicing de GA donde cambie la digitación superficial y se declare el razonamiento requerido. Fije demora y política de exposición antes de cualquier intento. La referencia manual cruza categoría, demora, elegibilidad y respuesta. Pida a un asistente que critique posibles filtraciones de la solución. Rechace afirmaciones de transferencia basadas solo en repeticiones o respuestas asistidas rebautizadas como independientes.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "immediate_repeated": {
      "correct": 8,
      "observed": 10
    },
    "delayed_repeated": {
      "correct": 6,
      "observed": 10
    },
    "delayed_novel": {
      "correct": 3,
      "observed": 8
    },
    "novel_exposed_correct": 1
  },
  "formula": "rate=eligible correct/eligible observed; remove exposed item from both numerator and denominator",
  "expected": {
    "immediate_rate": 0.8,
    "delayed_repeated_rate": 0.6,
    "raw_novel_rate": 0.375,
    "eligible_novel_correct": 2,
    "eligible_novel_observed": 7,
    "eligible_novel_rate_fraction": "2/7",
    "repeated_rate_change": -0.2
  },
  "negative_control": "Repeating identical prompts cannot supply evidence of novel-item transfer.",
  "assumptions": [
    "Fictional counts, same rubric, declared delay, observed items only; exposed novel item is correct and ineligible."
  ],
  "limits": "No real learning, causal effect, optimal delay or psychometric validity is inferred."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Calcule las tasas de elementos repetidos.

<details>
<summary>Respuesta 1</summary>

Inmediata `8/10=0.8`; diferida `6/10=0.6`; cambio `-0.2`.

</details>

### Ejercicio 2

Calcule el rendimiento bruto de elementos nuevos.

<details>
<summary>Respuesta 2</summary>

`3/8=0.375`, antes de excluir la exposición a la respuesta.

</details>

### Ejercicio 3

Aplique la exclusión por exposición.

<details>
<summary>Respuesta 3</summary>

Aciertos elegibles `2`, observaciones `7`, tasa `2/7`; conserve el acierto excluido.

</details>

### Ejercicio 4

¿El control solo repetido demuestra transferencia?

<details>
<summary>Respuesta 4</summary>

No. No contiene observaciones de elementos nuevos según la definición declarada.

</details>

### Ejercicio 5

¿Qué debe conservar el registro real del aprendiz?

<details>
<summary>Respuesta 5</summary>

Identidad, características modificadas, demora, respuesta, ayuda y elegibilidad; no se aporta efecto causal.

</details>

[Paquete de pruebas fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
