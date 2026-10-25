---
module_id: "inf-017-merge-sum-count-summaries-before-taking-means"
department: "information-theory"
course: "Fusionar sumas y recuentos antes de calcular medias"
level: "intermediate"
prerequisites: ["inf-015-weight-sampled-telemetry-before-summarizing-failures"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Fusionar sumas y recuentos antes de calcular medias

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Las etapas paralelas resumen cantidades distintas de elementos ficticios de Learn. Promediar sus promedios da igual peso a las etapas y puede dar pesos distintos a los elementos. El curso previo corrige probabilidades de observación desiguales; aquí están todos los elementos y el problema procede únicamente de la partición.

Conserve una suma y un recuento como resumen componible. La suma por componentes tiene un resumen vacío neutro y conserva el total al reagrupar particiones disjuntas. Divida solo después de fusionar. La lectura SELECT de SQLite distingue filas de entrada y agregados, pero no justifica cambiar la unidad del promedio de elementos a trabajadores.

El caso principal está desequilibrado. El control reparte los mismos valores en grupos del mismo tamaño: el método ingenuo coincide entonces con el correcto y oculta el error. Un DSL debe declarar qué consultas admite el resumen. Suma y recuento dan una media, pero no identidades individuales ni una mediana exacta. La compacidad se evalúa frente a la pregunta del destinatario.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: inf-015-weight-sampled-telemetry-before-summarizing-failures](../../information-theory/en/inf-015-weight-sampled-telemetry-before-summarizing-failures.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://www.sqlite.org/lang_select.html)

## Modelo fijo y control

```json
{
  "values": {
    "partitions": [
      [
        2
      ],
      [
        4,
        6,
        8
      ]
    ]
  },
  "formula": "Each partition summary=(sum,count). Merge by componentwise addition; mean=total_sum/total_count. Naive mean averages nonempty partition means with equal partition weights.",
  "expected": {
    "summaries": [
      [
        2,
        1
      ],
      [
        18,
        3
      ]
    ],
    "merged": [
      20,
      4
    ],
    "mean": 5,
    "naive_mean": 4
  },
  "negative_control": {
    "values": {
      "partitions": [
        [
          2,
          4
        ],
        [
          6,
          8
        ]
      ]
    },
    "expected": {
      "summaries": [
        [
          6,
          2
        ],
        [
          14,
          2
        ]
      ],
      "merged": [
        20,
        4
      ],
      "mean": 5,
      "naive_mean": 5
    },
    "why": "Equal-sized partitions hide the naive reducer error; the unequal main case exposes it."
  },
  "assumptions": [
    "Disjoint partitions cover the same exact numeric items once.",
    "Arithmetic exact; empty summary is [0,0] and final empty mean undefined."
  ],
  "limits": "Sufficient only for arithmetic mean, not variance, quantiles, identity audits or unbiased population estimates.",
  "input_types": {
    "partitions": "list<list<real>>"
  }
}
```

### Ejercicio 1

Calcule los resúmenes de partición.

<details><summary>Respuesta 1</summary>

Son `[2,1]` y `[18,3]`, en orden suma y recuento. Declare unidades y orden.

</details>

### Ejercicio 2

Fusione y calcule la media global.

<details><summary>Respuesta 2</summary>

El par fusionado es `[20,4]`, que da media `5`. El tamaño de la partición determina su aportación.

</details>

### Ejercicio 3

Calcule la media ingenua de medias.

<details><summary>Respuesta 3</summary>

Las medias son `2` y `6`; su media con igual peso es `4`. Responde a otra pregunta de ponderación.

</details>

### Ejercicio 4

Aplique el control equilibrado.

<details><summary>Respuesta 4</summary>

Los resúmenes `[6,2]` y `[14,2]` dan `[20,4]`. Ambos métodos producen `5`; este control aislado no detecta el error.

</details>

### Ejercicio 5

¿Puede el par dar una mediana exacta?

<details><summary>Respuesta 5</summary>

No. Muchas colecciones comparten suma y recuento. Conserve más datos cuando la consulta necesite orden o identidades.

</details>

## Tarea con consulta de fuentes

Prepare una ficha de resumen componible de duraciones ficticias de revisión de Learn sin crear un reductor ejecutable.

**Referencia manual directa:** Calcule sumas y recuentos en papel, sume los pares y divida una vez.

**Criterio de refutación:** Cambiar solo las fronteras de partición altera la media declarada de los elementos.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
