---
title: Examinar lecturas y escrituras antes de cambiar el orden
description: Examinar lecturas y escrituras antes de cambiar el orden — Ciencias de la computación
sidebar:
  label: CS-022 · Examinar lecturas y escrituras antes de cambiar el orden
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-022-check-read-write-footprints-before-reordering.es.md
---

:::note[Streeling University]
**CS-022** · Examinar lecturas y escrituras antes de cambiar el orden · intermedio · 45 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-022-check-read-write-footprints-before-reordering.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-017](../../computer-science/cs-017-test-pipeline-rewrites-with-counterexamples/)
:::

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Dos etapas de agente escriben archivos distintos y un coordinador propone ejecutarlas en cualquier orden. Sin embargo, la etapa del informe también lee el manifiesto que escribe la primera. Tener destinos diferentes no demuestra independencia. La huella debe incluir tanto las entradas como las salidas.

La guía de aislamiento de SQLite distingue conexiones separadas y escrituras serializadas. Esas garantías pertenecen a esa base de datos. Aquí declaramos un contrato estático más limitado para etapas ficticias de Learn: cada nombre identifica una ubicación mutable, leer no la modifica y las huellas están completas. Compare las escrituras de cada etapa con todos los recursos que toca la otra. Las lecturas compartidas son inocuas con estas premisas; cualquier solapamiento con una escritura exige conservar o justificar el orden.

La prueba rechaza deliberadamente etapas que podrían conmutar mediante otro argumento, como dos asignaciones de la misma constante. Un conflicto indica que esta condición suficiente no justifica la permutación; no demuestra resultados distintos en toda ejecución. El estado oculto invalida un resultado favorable, de modo que el DSL propuesto debe exponer los efectos.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: cs-017-test-pipeline-rewrites-with-counterexamples](../../computer-science/cs-017-test-pipeline-rewrites-with-counterexamples/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://www.sqlite.org/isolation.html)

## Modelo fijo y control

```json
{
  "values": {
    "a": {
      "reads": [
        "source"
      ],
      "writes": [
        "manifest"
      ]
    },
    "b": {
      "reads": [
        "manifest"
      ],
      "writes": [
        "report"
      ]
    }
  },
  "formula": "conflicts=(Wa intersect (Rb union Wb)) union (Wb intersect (Ra union Wa)); sort unique names; independent iff conflicts empty.",
  "expected": {
    "conflicts": [
      "manifest"
    ],
    "independent": false
  },
  "negative_control": {
    "values": {
      "a": {
        "reads": [
          "source"
        ],
        "writes": [
          "manifest"
        ]
      },
      "b": {
        "reads": [
          "source"
        ],
        "writes": [
          "report"
        ]
      }
    },
    "expected": {
      "conflicts": [],
      "independent": true
    },
    "why": "Removing the read-after-write dependency leaves disjoint writes and shared read-only input."
  },
  "assumptions": [
    "Exact resource names cover every read and write; stages otherwise deterministic.",
    "No clocks, network effects, hidden mutable state or failures are represented."
  ],
  "limits": "Empty conflicts is a sufficient footprint check under these assumptions, not universal commutativity or a concurrent runtime.",
  "input_types": {
    "a": "{reads:set<string>,writes:set<string>}",
    "b": "{reads:set<string>,writes:set<string>}"
  }
}
```

### Ejercicio 1

Encuentre el conflicto del caso fijo.

<details><summary>Respuesta 1</summary>

`manifest` pertenece a las escrituras de la primera etapa y las lecturas de la segunda. La lista es `[manifest]`, por lo que `independent=false`.

</details>

### Ejercicio 2

¿Por qué no bastan salidas diferentes?

<details><summary>Respuesta 2</summary>

La segunda etapa consume un valor que cambia la primera. Invertirlas puede leer un manifiesto anterior aunque las escrituras sean disjuntas.

</details>

### Ejercicio 3

Aplique el control con lectura compartida.

<details><summary>Respuesta 3</summary>

Ambas leen `source` y escriben recursos distintos. La lista es `[]` e `independent=true` si las huellas están completas.

</details>

### Ejercicio 4

¿Un conflicto prueba que no conmutan?

<details><summary>Respuesta 4</summary>

No. Es una condición suficiente de independencia. Otro argumento podría demostrar equivalencia pese al solapamiento, pero la huella sola no lo hace.

</details>

### Ejercicio 5

Nombre un efecto oculto que refutaría el resultado.

<details><summary>Respuesta 5</summary>

Una escritura no declarada en una caché compartida invalida la premisa de completitud. Consérvela y recalcule; una intersección vacía de listas incompletas no es una prueba.

</details>

## Tarea con consulta de fuentes

Anote las lecturas y escrituras de etapas ficticias de Learn y pida a un asistente que justifique o rechace cambiar su orden.

**Referencia manual directa:** Calcule en papel las intersecciones de las escrituras con las lecturas y escrituras de la otra etapa.

**Criterio de refutación:** Se omite una dependencia de lectura tras escritura o se da por cubierto un efecto no declarado.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
