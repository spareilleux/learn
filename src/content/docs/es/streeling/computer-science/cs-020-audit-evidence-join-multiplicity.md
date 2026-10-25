---
title: Auditar la multiplicidad de una unión de evidencias
description: Auditar la multiplicidad de una unión de evidencias — Ciencias de la computación
sidebar:
  label: CS-020 · Auditar la multiplicidad de una unión de evidencias
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-020-audit-evidence-join-multiplicity.es.md
---

:::note[Streeling University]
**CS-020** · Auditar la multiplicidad de una unión de evidencias · intermedio · 45 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-020-audit-evidence-join-multiplicity.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-008](../../computer-science/cs-008-compose-exact-source-review-verdicts/), [INF-010](../../information-theory/inf-010-keep-joint-outcomes-when-composing-verdicts/)
:::

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un agente combina una tabla de revisiones con otra de pruebas y comunica el número de filas unidas como cantidad de artefactos validados. Una unión puede producir más filas que cada entrada, porque conserva todas las parejas coincidentes. El prerrequisito de revisión comprueba los bytes identificados; el de resultados conjuntos conserva veredictos emparejados. Esta lección añade otra cuestión: la multiplicidad creada cuando varios recibos comparten una clave.

Escriba las parejas revisión/prueba de cada artefacto antes de contar. Un artefacto con varias revisiones y varias pruebas produce sus combinaciones cartesianas. Esas filas pueden facilitar la navegación, pero no constituyen artefactos nuevos, revisores adicionales ni ejecuciones independientes. Calcular después un porcentaje sobre la tabla aplanada puede ponderar cada artefacto según cuántos recibos tenga.

La documentación SELECT de [SQLite](https://www.sqlite.org/lang_select.html) define las uniones mediante un producto cartesiano seguido de restricciones. Las tablas fijadas usan esa interpretación de multiconjunto sin ejecutar ninguna base de datos. La utilidad de Learn conserva en cambio un conjunto de claves. Su inserción muestra una representación con otro significado de recuento: la pertenencia no conserva las combinaciones necesarias para auditar recibos. Ninguna representación es siempre preferible; la pregunta del proyecto determina la unidad.

La procedencia [W3C](https://www.w3.org/TR/2013/REC-prov-dm-20130430/) distingue entidades, actividades y relaciones. Conserve la identidad de cada recibo original en las filas para recuperar esa distinción. El control elimina una prueba manteniendo la cobertura de artefactos. Si un informe afirma que desaparecieron artefactos porque bajó el número de filas, confunde multiplicidad y cobertura. Una unión DSL propuesta debe declarar clave, semántica de filas y unidad de agregación antes de que un agente redacte el estado.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: cs-008-compose-exact-source-review-verdicts](../../computer-science/cs-008-compose-exact-source-review-verdicts/)

[Prerrequisito: inf-010-keep-joint-outcomes-when-composing-verdicts](../../information-theory/inf-010-keep-joint-outcomes-when-composing-verdicts/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria: SQLite SELECT documentation, section 2.1, read 2026-10-24](https://www.sqlite.org/lang_select.html)

[Lectura primaria: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

## Modelo fijado y control

```json
{
  "values": {
    "left": [
      {
        "artifact": "a",
        "review": "r1"
      },
      {
        "artifact": "a",
        "review": "r2"
      },
      {
        "artifact": "b",
        "review": "r3"
      }
    ],
    "right": [
      {
        "artifact": "a",
        "check": "t1"
      },
      {
        "artifact": "a",
        "check": "t2"
      },
      {
        "artifact": "b",
        "check": "t3"
      }
    ]
  },
  "formula": "Inner equality join on artifact emits every matching row pair; count rows and distinct artifact keys separately.",
  "expected": {
    "joined_rows": 5,
    "distinct_artifacts": 2,
    "rows_per_artifact": {
      "a": 4,
      "b": 1
    }
  },
  "negative_control": {
    "values": {
      "left": [
        {
          "artifact": "a",
          "review": "r1"
        },
        {
          "artifact": "a",
          "review": "r2"
        },
        {
          "artifact": "b",
          "review": "r3"
        }
      ],
      "right": [
        {
          "artifact": "a",
          "check": "t1"
        },
        {
          "artifact": "b",
          "check": "t3"
        }
      ]
    },
    "expected": {
      "joined_rows": 3,
      "distinct_artifacts": 2,
      "rows_per_artifact": {
        "a": 2,
        "b": 1
      }
    },
    "why": "Removing one check changes join multiplicity without changing artifact coverage."
  },
  "assumptions": [
    "Bag semantics; exact equality on retained artifact key.",
    "Review rows and check rows are not assumed independent trials."
  ],
  "limits": "Artifact key is simplified; real matching also requires revision and scope. No query or production data was executed."
}
```

### Ejercicio 1

Enumere cuántas filas unidas aporta cada artefacto.

<details><summary>Respuesta 1</summary>

El artefacto `a` aporta `4` parejas y `b` aporta `1`, para un total de `5` filas. Cada revisión de un artefacto se empareja con cada prueba del mismo; no es una fila por artefacto.

</details>

### Ejercicio 2

¿Cuántos artefactos distintos hay y demuestra el recuento revisión independiente?

<details><summary>Respuesta 2</summary>

Hay `2` artefactos distintos. Una fila unida repite recibos en varias combinaciones. No aporta otra identidad de revisor, garantía de independencia ni prueba ejecutada adicional.

</details>

### Ejercicio 3

Aplique el control que elimina una prueba. ¿Qué cambia y qué permanece igual?

<details><summary>Respuesta 3</summary>

El total pasa a `3` filas, con `2` para `a` y `1` para `b`. Siguen existiendo `2` artefactos distintos. Cambia la multiplicidad, mientras la cobertura bajo esta clave permanece igual.

</details>

### Ejercicio 4

¿Por qué un porcentaje sobre filas unidas puede distorsionar un resumen por artefacto?

<details><summary>Respuesta 4</summary>

Un artefacto con más recibos coincidentes recibe mayor peso. Defina si el denominador cuenta artefactos, revisiones, pruebas o parejas antes de agregar. Un cálculo correcto no repara una unidad de recuento implícita.

</details>

### Ejercicio 5

¿Qué debe añadirse antes de aplicar esta clave simplificada a evidencia de bytes exactos?

<details><summary>Respuesta 5</summary>

Conserve revisión y alcance del recibo junto con la identidad, y compruebe manualmente la relación prevista. La tabla no autoriza unir revisiones diferentes ni convertir una declaración en observación de ejecución.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
