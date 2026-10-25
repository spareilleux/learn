---
title: Corregir el acuerdo de revisión por los marginales de etiquetas
description: Corregir el acuerdo de revisión por los marginales de etiquetas — Ciencia cognitiva
sidebar:
  label: COG-019 · Corregir el acuerdo de revisión por los marginales de etiquetas
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/es/cog-019-correct-review-agreement-for-label-marginals.es.md
---

:::note[Streeling University]
**COG-019** · Corregir el acuerdo de revisión por los marginales de etiquetas · intermedio · 45 minutos

Generado por el departamento *Ciencia cognitiva* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/es/cog-019-correct-review-agreement-for-label-marginals.es.md) · [Mi diario](../../journal/)

Requisitos previos: [COG-011](../../cognitive-science/cog-011-measure-rubric-disagreement-before-adjudication/)
:::

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un coordinador de Streeling observa un acuerdo bruto alto y quiere declarar fiable la rúbrica. Si ambos evaluadores eligen sobre todo la misma etiqueta, un modelo de marginales ya espera parte de ese acuerdo. El curso de desacuerdo conserva las celdas emparejadas, pero limita explícitamente su alcance al acuerdo bruto. Aquí se añade la corrección por azar sin convertir una tabla construida en revisión humana.

Calcule el acuerdo observado con la diagonal. Obtenga después las fracciones de aprobación y rechazo de cada evaluador. Multiplique las fracciones coincidentes entre evaluadores y súmelas para obtener el acuerdo esperado bajo el modelo de etiquetas independientes. Normalice el exceso por el margen restante sobre esa referencia. El denominador importa tanto como el numerador; no basta restar una constante a la exactitud bruta.

En el caso fijo difieren los marginales. Usar una tasa conjunta de aprobación cambiaría el modelo de comparación. Mantenga cada marginal ligado a su evaluador y conserve los artefactos discutidos para adjudicación. El control convierte todas las calificaciones en aprobación. El acuerdo bruto es perfecto, pero se anula el denominador de corrección. Informe un resultado indefinido en lugar de inventar una puntuación corregida perfecta.

La documentación de scikit-learn define esta versión empírica de kappa. La tabla pequeña exacta no necesita ningún paquete y su definición no prescribe un umbral de publicación. Un acuerdo alto puede coexistir con un solucionario incorrecto compartido o etiquetas copiadas. La tarea consiste en comunicar acuerdo bruto y corregido, supuestos y límite degenerado. Una expresión de revisión componible debe mantener visible ese límite sin convertir un resultado indefinido en aprobación.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: cog-011-measure-rubric-disagreement-before-adjudication](../../cognitive-science/cog-011-measure-rubric-disagreement-before-adjudication/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://scikit-learn.org/stable/modules/generated/sklearn.metrics.cohen_kappa_score.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "both_pass": 6,
    "A_only": 2,
    "B_only": 0,
    "both_fail": 2
  },
  "formula": "N=sum(cells); po=(both_pass+both_fail)/N; pA=(both_pass+A_only)/N; pB=(both_pass+B_only)/N; pe=pA*pB+(1-pA)*(1-pB); kappa=(po-pe)/(1-pe), null if pe=1.",
  "expected": {
    "N": 10,
    "observed_agreement": 0.8,
    "expected_agreement": 0.56,
    "kappa_fraction": "6/11"
  },
  "negative_control": {
    "values": {
      "both_pass": 10,
      "A_only": 0,
      "B_only": 0,
      "both_fail": 0
    },
    "expected": {
      "N": 10,
      "observed_agreement": 1,
      "expected_agreement": 1,
      "kappa_fraction": null
    },
    "why": "Unanimous use of one category makes the correction denominator zero."
  },
  "input_types": {
    "both_pass": "nonnegative integer",
    "A_only": "nonnegative integer",
    "B_only": "nonnegative integer",
    "both_fail": "nonnegative integer"
  },
  "assumptions": [
    "Same artifacts and binary rubric for both fictional raters; positive total.",
    "Chance model uses product of empirical per-rater marginals, not an actual random rater experiment."
  ],
  "limits": "Kappa is not validity, independence, fairness or a universal acceptance threshold. No human review occurred."
}
```

### Ejercicio 1

Calcule el acuerdo observado.

<details><summary>Respuesta 1</summary>

La diagonal contiene `8` de `10` ítems, dando `0.8`. Describe etiquetas coincidentes, no la corrección de respuestas ni el origen independiente de las calificaciones.

</details>

### Ejercicio 2

Calcule el acuerdo esperado con marginales separados.

<details><summary>Respuesta 2</summary>

Las fracciones de aprobación son `0.8` y `0.6`; el acuerdo esperado es `0.56`. Agrupar los marginales implementaría otro modelo de referencia.

</details>

### Ejercicio 3

Calcule la puntuación corregida.

<details><summary>Respuesta 3</summary>

Kappa es `6/11`. Conserve la tabla bruta: un escalar corregido no identifica los artefactos discutidos necesarios para adjudicación.

</details>

### Ejercicio 4

Aplique el control de aprobación total.

<details><summary>Respuesta 4</summary>

Los acuerdos observado y esperado son `1`; la puntuación corregida es `null`. Se anula el denominador y no debe fabricarse un kappa perfecto.

</details>

### Ejercicio 5

¿Autoriza la puntuación la publicación?

<details><summary>Respuesta 5</summary>

No. Corrección, identidad del artefacto, independencia y autoridad necesitan evidencias propias. Una estadística no sustituye una revisión técnica o lingüística ausente.

</details>

## Tarea con consulta de fuentes

Prepare una nota de acuerdo sobre calificaciones emparejadas ficticias de una rúbrica de Streeling.

**Referencia manual directa:** Rellene la tabla, conserve ambos marginales y calcule la corrección como fracción exacta.

**Criterio de refutación:** El resumen agrupa marginales distintos o inventa una puntuación definida con denominador cero.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: Calcule el acuerdo observado. — Decisión sin resolver.
- Ejercicio 2: Calcule el acuerdo esperado con marginales separados. — Decisión sin resolver.
- Ejercicio 3: Calcule la puntuación corregida. — Decisión sin resolver.
- Ejercicio 4: Aplique el control de aprobación total. — Decisión sin resolver.
- Ejercicio 5: ¿Autoriza la puntuación la publicación? — Decisión sin resolver.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
