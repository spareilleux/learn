---
title: Proyectar primeras retiradas por cohortes de assets artesanales
description: Proyectar primeras retiradas por cohortes de assets artesanales — Futurología
sidebar:
  label: FUT-014 · Proyectar primeras retiradas por cohortes de assets artesanales
  order: 14
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/futurology/es/fut-014-project-first-retirements-from-craft-asset-cohorts.es.md
---

:::note[Streeling University]
**FUT-014** · Proyectar primeras retiradas por cohortes de assets artesanales · avanzado · 45 minutos

Generado por el departamento *Futurología* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/futurology/es/fut-014-project-first-retirements-from-craft-asset-cohorts.es.md) · [Mi diario](../../journal/)

Requisitos previos: [FUT-010](../../futurology/fut-010-project-weave-density-before-a-scene-expansion/), [PSY-021](../../psychohistory/psy-021-conservation-claims/)
:::

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Una futura biblioteca artesanal prevé sustituir assets antiguos de bordado y escultura cuando su representación deje de ser adecuada. El recuento total no fecha ese trabajo. Bibliotecas del mismo tamaño pueden tener fechas de introducción y supuestos de duración diferentes. Aquí se proyectan primeras retiradas por cohortes. Las masas fraccionarias son asignaciones de planificación inventadas, no fallos observados ni probabilidades estimadas a partir de adopción.

Para cada cohorte introducida, desplace la asignación de edades al calendario y multiplíquela por su masa. Sume contribuciones que llegan al mismo período. Esta convolución finita conserva masa total si el horizonte incluye todas las retiradas asignadas, pero el resultado nuevo es el perfil temporal y su pico. La identidad anterior de inventario no aporta ese calendario de edades. El pico puede ocurrir cuando las introducciones ya disminuyen porque coinciden cohortes antiguas.

El control de menor duración conserva introducciones y cambia solo edad de retirada. Desplaza y aumenta el pico manteniendo masa total. Trate con cuidado los reemplazos: este modelo termina en la primera retirada de los assets originales. Reintroducir sustitutos crearía un modelo de renovación con más hipótesis y horizonte. Una nota de planificación agentiva debe vincular registro de introducción, regla de edad y horizonte, y comparar la proyección con decisiones reales si más adelante se registran.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "introduced_by_period": [
      2,
      3,
      1,
      0
    ],
    "retirement_age_mass": {
      "2": 0.5,
      "3": 0.5
    },
    "output_periods": 7
  },
  "formula": "first_retirements[t]=sum(introduced[c]*age_mass[t-c] for c in cohort periods, absent ages contribute zero); total=sum(first_retirements)",
  "expected": {
    "first_retirements": [
      0,
      0,
      1,
      2.5,
      2,
      0.5,
      0
    ],
    "total": 6,
    "peak_period": 3,
    "peak_mass": 2.5
  },
  "negative_control": {
    "values": {
      "introduced_by_period": [
        2,
        3,
        1,
        0
      ],
      "retirement_age_mass": {
        "1": 1
      },
      "output_periods": 7
    },
    "expected": {
      "first_retirements": [
        0,
        2,
        3,
        1,
        0,
        0,
        0
      ],
      "total": 6,
      "peak_period": 2,
      "peak_mass": 3
    }
  }
}
```

### Ejercicio 1

Halle el primer período con retiradas.

<details><summary>Respuesta 1</summary>

Es el período `2`, con masa `1`. Antes ninguna cohorte alcanza la edad declarada.

</details>

### Ejercicio 2

Derive el pico por contribuciones.

<details><summary>Respuesta 2</summary>

El período `3` combina `1` de la primera cohorte y `1.5` de la siguiente, dando `2.5`.

</details>

### Ejercicio 3

Escriba el perfil completo de primeras retiradas.

<details><summary>Respuesta 3</summary>

Es `[0,0,1,2.5,2,0.5,0]`, total `6`. El horizonte incluye la última retirada asignada.

</details>

### Ejercicio 4

Aplique el control de menor duración.

<details><summary>Respuesta 4</summary>

El perfil es `[0,2,3,1,0,0,0]`, con pico `3` en período `2`. Igual total no implica igual necesidad de capacidad.

</details>

### Ejercicio 5

¿Se incluyen retiradas repetidas de sustitutos?

<details><summary>Respuesta 5</summary>

No. Solo primeras retiradas de cohortes originales. La renovación necesita reglas de introducción y duración de cada reemplazo.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje una tabla de cohorte y calendario para una biblioteca de bordado propuesta y sume diagonales a mano. Compare con una previsión del asistente basada solo en el total y conserve ambas reglas como hipótesis.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

El control de duración refuta una previsión de pico idéntico siempre que coincidan los totales introducidos.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: fut-010-project-weave-density-before-a-scene-expansion](../../futurology/fut-010-project-weave-density-before-a-scene-expansion/)
- [Prerrequisito confirmado: psy-021-conservation-claims](../../psychohistory/psy-021-conservation-claims/)
- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://docs.python.org/3/library/itertools.html#itertools.product)
- [Paquete inventado](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
