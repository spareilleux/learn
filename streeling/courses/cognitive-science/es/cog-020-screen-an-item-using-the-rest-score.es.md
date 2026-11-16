---
module_id: "cog-020-screen-an-item-using-the-rest-score"
department: "cognitive-science"
course: "Examinar un ítem mediante la puntuación de los demás ítems"
title: "Examinar un ítem mediante la puntuación de los demás ítems"
level: "intermediate"
prerequisites: ["cog-008-choose-probes-that-distinguish-reasoning-models"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Examinar un ítem mediante la puntuación de los demás ítems

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un ítem de Learn recibe respuestas correctas de aproximadamente la mitad de un grupo construido. Eso no demuestra que distinga la habilidad prevista. Una clave mal etiquetada o una consigna ambigua podría favorecer al grupo con menor puntuación. Antes de reutilizar el ítem en una tarea de explicación asistida, compare su resultado con los demás ítems e inspeccione la consigna real.

Forme la clasificación con la puntuación restante, excluyendo el ítem objetivo. Incluirlo en su propia clasificación crea una asociación entre parte y todo que puede ocultar la pregunta. Nuestro diagnóstico pequeño divide puntuaciones distintas en mitades iguales. Después resta la fracción de aciertos inferior de la superior. La facilidad general es otro resumen que incluye todas las respuestas.

El caso fijo produce un contraste negativo pese a una facilidad intermedia. El control invierte las respuestas del ítem y mantiene la proporción global. El contraste cambia de signo. Así se muestra por qué el total de aciertos no sustituye la asociación con la puntuación restante. Conserve cada fila para que se examine si la clave, la adecuación del contenido o la redacción explican el patrón.

El texto primario trata la puntuación sin el ítem, la dependencia de la muestra y el supuesto de dimensionalidad de los índices tradicionales. Nuestro cálculo por mitades es un diagnóstico finito declarado, no todo ese método psicométrico. Un resultado bajo o negativo invita a investigar, no autoriza a eliminar automáticamente un ítem necesario por su contenido. Faltan alumnos reales, consentimiento apropiado, respuestas representativas y revisión del contenido. Un DSL adaptativo debería conservar esta incertidumbre sin convertir el contraste en una etiqueta universal de calidad.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: cog-008-choose-probes-that-distinguish-reasoning-models](../../cognitive-science/en/cog-008-choose-probes-that-distinguish-reasoning-models.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://www.cs.cas.cz/comps/PsychometricsBook/chapters/chapter5/chap5_item_analysis.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "rest_scores": [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7
    ],
    "item_correct": [
      1,
      1,
      1,
      0,
      1,
      0,
      0,
      0
    ]
  },
  "formula": "Sort records by distinct rest_score ascending; lower group is first half, upper group is last half. p=all correct/N; D=upper correct/upper size-lower correct/lower size. Rank excludes target item.",
  "expected": {
    "lower_correct": 3,
    "upper_correct": 1,
    "group_size": 4,
    "overall_fraction": 0.5,
    "discrimination": -0.5
  },
  "negative_control": {
    "values": {
      "rest_scores": [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7
      ],
      "item_correct": [
        0,
        0,
        0,
        1,
        0,
        1,
        1,
        1
      ]
    },
    "expected": {
      "lower_correct": 1,
      "upper_correct": 3,
      "group_size": 4,
      "overall_fraction": 0.5,
      "discrimination": 0.5
    },
    "why": "Reversing the item responses keeps ease unchanged but reverses the association with rest score."
  },
  "input_types": {
    "rest_scores": "even-length list of distinct integer scores excluding the item",
    "item_correct": "same-length binary integer list"
  },
  "assumptions": [
    "Fixed item and rest-score rubric; complete fictional records.",
    "Equal halves are an authored diagnostic convention, not a mandated psychometric standard."
  ],
  "limits": "A small descriptive contrast is neither causal learning evidence nor proof of item validity, dimensionality or population discrimination."
}
```

### Ejercicio 1

Calcule la facilidad global.

<details><summary>Respuesta 1</summary>

Hay `4` respuestas correctas de `8`, dando `0.5`. Esta cantidad ignora qué grupo de puntuación restante respondió correctamente.

</details>

### Ejercicio 2

Calcule el contraste con signo.

<details><summary>Respuesta 2</summary>

El grupo inferior acierta `3` y el superior `1`, cada uno entre `4`. El contraste es `-0.5`, una señal para investigar bajo este diagnóstico declarado.

</details>

### Ejercicio 3

Aplique el control de respuestas invertidas.

<details><summary>Respuesta 3</summary>

La fracción global sigue siendo `0.5`, pero el contraste pasa a `0.5`. Totales iguales no establecen patrones de discriminación iguales.

</details>

### Ejercicio 4

¿Por qué excluir el objetivo de la clasificación?

<details><summary>Respuesta 4</summary>

Evita que su resultado ayude a definir sus propios grupos de comparación. No demuestra que la puntuación restante mida una habilidad válida única ni elimina la incertidumbre muestral.

</details>

### Ejercicio 5

¿Debe el agente eliminar automáticamente el ítem?

<details><summary>Respuesta 5</summary>

No. Conserve consigna, clave e identidades y examine adecuación, ambigüedad y composición de la muestra. Un contraste negativo descriptivo no identifica por sí solo la causa.

</details>

## Tarea con consulta de fuentes

Prepare una nota de inspección de un ítem para un cuestionario de explicaciones propuesto de Learn.

**Referencia manual directa:** Clasifique según las puntuaciones restantes y complete a mano las fracciones de aciertos de ambos grupos.

**Criterio de refutación:** Un resumen de calidad considera equivalentes los casos de igual facilidad y contraste opuesto.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: Calcule la facilidad global. — Decisión sin resolver.
- Ejercicio 2: Calcule el contraste con signo. — Decisión sin resolver.
- Ejercicio 3: Aplique el control de respuestas invertidas. — Decisión sin resolver.
- Ejercicio 4: ¿Por qué excluir el objetivo de la clasificación? — Decisión sin resolver.
- Ejercicio 5: ¿Debe el agente eliminar automáticamente el ítem? — Decisión sin resolver.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
