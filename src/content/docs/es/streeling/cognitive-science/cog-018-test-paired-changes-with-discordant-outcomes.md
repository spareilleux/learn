---
title: Contrastar cambios emparejados con resultados discordantes
description: Contrastar cambios emparejados con resultados discordantes — Ciencia cognitiva
sidebar:
  label: COG-018 · Contrastar cambios emparejados con resultados discordantes
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/es/cog-018-test-paired-changes-with-discordant-outcomes.es.md
---

:::note[Streeling University]
**COG-018** · Contrastar cambios emparejados con resultados discordantes · intermedio · 45 minutos

Generado por el departamento *Ciencia cognitiva* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/es/cog-018-test-paired-changes-with-discordant-outcomes.es.md) · [Mi diario](../../journal/)

Requisitos previos: [COG-009](../../cognitive-science/cog-009-counterbalance-practice-order-before-comparing-interfaces/), [COG-011](../../cognitive-science/cog-011-measure-rubric-disagreement-before-adjudication/)
:::

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un agente de práctica de GA informa de que una explicación revisada responde correctamente a más ítems. Si ambas versiones se juzgan sobre los mismos ítems, los resultados están emparejados. Tratar los totales como muestras independientes pierde ese emparejamiento. Conserve qué ítems cambian de dirección antes de elegir una comparación estadística o afirmar una ayuda útil.

Construya la tabla con aciertos compartidos, fallos compartidos y ambas direcciones discordantes. La diferencia de exactitud usa todos los ítems emparejados. El contraste direccional condicional solo usa pares discordantes: los resultados compartidos no indican qué versión gana entre los cambios. Bajo la hipótesis nula declarada, cada dirección es igualmente probable en cada par discordante independiente.

El cálculo exacto duplica la menor cola binomial y la limita a la unidad. El caso fijo tiene una diferencia descriptiva considerable, pero su probabilidad bilateral sigue por encima del umbral convencional habitual. No hay contradicción: magnitud del efecto y evidencia bajo un modelo nulo responden a preguntas distintas. Un porcentaje grande no garantiza un contraste decisivo.

El control equilibra las direcciones discordantes manteniendo el número de ítems. El requisito ya enseña desacuerdo emparejado bruto; esta operación añade una comparación probabilística con supuestos explícitos de independencia y asignación. Un ítem que fallan ambas versiones sigue importando para la utilidad aunque no entre en el tamaño condicional. Ningún alumno probó estas explicaciones ni se asignaron interfaces. Una comparación futura de dogfood debería conservar evaluación oculta, orden, identidades y todos los pares fallidos antes de pedir una síntesis al asistente.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: cog-009-counterbalance-practice-order-before-comparing-interfaces](../../cognitive-science/cog-009-counterbalance-practice-order-before-comparing-interfaces/)

[Requisito previo: cog-011-measure-rubric-disagreement-before-adjudication](../../cognitive-science/cog-011-measure-rubric-disagreement-before-adjudication/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.binomtest.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "both_correct": 2,
    "old_only": 1,
    "new_only": 7,
    "both_wrong": 2
  },
  "formula": "n=old_only+new_only; k=min(old_only,new_only); exact two-sided p=min(1,2*sum(comb(n,j),j=0..k)/2**n) for n>0; if n=0 set p=1. Total includes all four cells. Report accuracy difference=(new_only-old_only)/total.",
  "expected": {
    "paired": 12,
    "discordant": 8,
    "old_correct": 3,
    "new_correct": 9,
    "accuracy_difference": 0.5,
    "p_value": 0.0703125
  },
  "negative_control": {
    "values": {
      "both_correct": 2,
      "old_only": 4,
      "new_only": 4,
      "both_wrong": 2
    },
    "expected": {
      "paired": 12,
      "discordant": 8,
      "old_correct": 6,
      "new_correct": 6,
      "accuracy_difference": 0,
      "p_value": 1
    },
    "why": "Balanced discordant directions remove the directional evidence while keeping pair count fixed."
  },
  "input_types": {
    "both_correct": "nonnegative integer",
    "old_only": "nonnegative integer",
    "new_only": "nonnegative integer",
    "both_wrong": "nonnegative integer"
  },
  "assumptions": [
    "Independent pairs; under the null each discordant direction is equally likely.",
    "Same binary criterion for matched items; no missing pairs; test and alternatives declared in advance."
  ],
  "limits": "Authored counts are not learner responses. This is not a causal effect without an appropriate allocation and observation design."
}
```

### Ejercicio 1

¿Qué denominador corresponde a cada cálculo?

<details><summary>Respuesta 1</summary>

Hay `12` ítems emparejados, pero `8` pares discordantes. La exactitud usa todos los ítems; el contraste binomial condicional usa las discordancias.

</details>

### Ejercicio 2

Calcule el cambio descriptivo.

<details><summary>Respuesta 2</summary>

La versión anterior acierta `3`, la nueva `9`, y la diferencia es `0.5`. Conserve la tabla: los totales solos no mantienen qué ítems cambiaron.

</details>

### Ejercicio 3

Calcule la probabilidad bilateral exacta.

<details><summary>Respuesta 3</summary>

Es `0.0703125`, obtenida de ambas colas simétricas. No es una probabilidad posterior de equivalencia de las explicaciones ni de fracaso de la ayuda.

</details>

### Ejercicio 4

Aplique el control equilibrado.

<details><summary>Respuesta 4</summary>

Ambas versiones aciertan `6`; la diferencia es `0` y la probabilidad `1`. Siguen existiendo desacuerdos, pero sus direcciones se equilibran.

</details>

### Ejercicio 5

¿Qué conclusión causal se justifica?

<details><summary>Respuesta 5</summary>

Ninguna con recuentos inventados. Hacen falta asignación adecuada, identidades emparejadas, evaluación común y justificación de independencia; varios ítems de un mismo alumno pueden incumplirla.

</details>

## Tarea con consulta de fuentes

Prepare el análisis emparejado de explicaciones de GA antes de recopilar respuestas de alumnos.

**Referencia manual directa:** Rellene la tabla y enumere la cola binomial simétrica con combinaciones enteras.

**Criterio de refutación:** El resumen propuesto cambia el denominador emparejado o pierde la dirección discordante.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: ¿Qué denominador corresponde a cada cálculo? — Decisión sin resolver.
- Ejercicio 2: Calcule el cambio descriptivo. — Decisión sin resolver.
- Ejercicio 3: Calcule la probabilidad bilateral exacta. — Decisión sin resolver.
- Ejercicio 4: Aplique el control equilibrado. — Decisión sin resolver.
- Ejercicio 5: ¿Qué conclusión causal se justifica? — Decisión sin resolver.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
