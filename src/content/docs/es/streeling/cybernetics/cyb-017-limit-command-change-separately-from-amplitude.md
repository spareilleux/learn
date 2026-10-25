---
title: Limitar el cambio de mando por separado de su amplitud
description: Limitar el cambio de mando por separado de su amplitud — Cibernética
sidebar:
  label: CYB-017 · Limitar el cambio de mando por separado de su amplitud
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/es/cyb-017-limit-command-change-separately-from-amplitude.es.md
---

:::note[Streeling University]
**CYB-017** · Limitar el cambio de mando por separado de su amplitud · intermedio · 45 minutos

Generado por el departamento *Cibernética* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/es/cyb-017-limit-command-change-separately-from-amplitude.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CYB-011](../../cybernetics/cyb-011-prevent-integral-accumulation-under-saturation/)
:::

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un mando puede permanecer dentro de su rango y cambiar demasiado rápido. El requisito previo sobre saturación limita la amplitud y sigue un integrador. Aquí no hay integrador: limitamos la diferencia entre mandos aplicados sucesivos. El agente debe conservar el valor aplicado y el intervalo de actualización.

El resumen del artículo citado presenta las restricciones de velocidad como un problema de modelado. Nuestros dos recortes se declaran de forma independiente; no reproducen su método de optimización. Respete primero el intervalo de amplitud y después el alcanzable desde el mando anterior. Un valor inicial admisible garantiza el solapamiento de ambos intervalos.

La salida final de una secuencia corta puede diferir de la petición. Ese residuo es una consecuencia prevista de la restricción. Comprobar solo la amplitud oculta el nuevo requisito. Un DSL debe declarar las unidades y conservar el estado aplicado; sustituirlo por la última petición cambia el siguiente intervalo.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: cyb-011-prevent-integral-accumulation-under-saturation](../../cybernetics/cyb-011-prevent-integral-accumulation-under-saturation/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://arxiv.org/abs/1903.05508)

## Modelo fijo y control

```json
{
  "values": {
    "requests": [
      4,
      4,
      0
    ],
    "initial_command": 0,
    "rate_per_second": 2,
    "dt_seconds": 0.5,
    "lower": 0,
    "upper": 4
  },
  "formula": "First clip requested amplitude to [lower,upper]; then clip it to [previous-rate*dt,previous+rate*dt]. Initial command is inside amplitude range.",
  "expected": {
    "amplitude_only": [
      4,
      4,
      0
    ],
    "commands": [
      1,
      2,
      1
    ],
    "deltas": [
      1,
      1,
      -1
    ],
    "final": 1
  },
  "negative_control": {
    "values": {
      "requests": [
        4,
        4,
        0
      ],
      "initial_command": 0,
      "rate_per_second": 8,
      "dt_seconds": 0.5,
      "lower": 0,
      "upper": 4
    },
    "expected": {
      "amplitude_only": [
        4,
        4,
        0
      ],
      "commands": [
        4,
        4,
        0
      ],
      "deltas": [
        4,
        0,
        -4
      ],
      "final": 0
    },
    "why": "A wide rate bound makes these requests feasible without changing the amplitude range."
  },
  "assumptions": [
    "Uniform positive time step, initial command within bounds, no plant.",
    "Rate bound applies to applied command differences, not derivative estimates."
  ],
  "limits": "No physical actuator, settling guarantee or anti-windup policy was tested.",
  "input_types": {
    "requests": "list<real command units>",
    "initial_command": "real",
    "rate_per_second": "nonnegative real command units/second",
    "dt_seconds": "positive real",
    "lower": "real",
    "upper": "real >= lower"
  }
}
```

### Ejercicio 1

Calcule el cambio permitido por actualización.

<details><summary>Respuesta 1</summary>

`2*0.5=1` unidad de mando. La velocidad por segundo se multiplica por el intervalo real.

</details>

### Ejercicio 2

Calcule los mandos y sus diferencias.

<details><summary>Respuesta 2</summary>

Los mandos son `[1,2,1]` y las diferencias `[1,1,-1]`. Todas cumplen el límite declarado.

</details>

### Ejercicio 3

¿Por qué la petición final no produce cero?

<details><summary>Respuesta 3</summary>

El mando previo es `2`; solo se permite un cambio de magnitud `1`, así que el valor aplicado es `1`.

</details>

### Ejercicio 4

Aplique el control de velocidad amplia.

<details><summary>Respuesta 4</summary>

Los mandos son `[4,4,0]`, las diferencias `[4,0,-4]` y el valor final `0`. El rango de amplitud no cambia.

</details>

### Ejercicio 5

¿Reducir dt a la mitad conserva el salto permitido?

<details><summary>Respuesta 5</summary>

No. A igual velocidad, se reduce a la mitad el cambio por actualización. Esto describe la restricción, no una respuesta física medida.

</details>

## Tarea con consulta de fuentes

Anote una traza ficticia de control de carga de GA con límites de amplitud y cambio.

**Referencia manual directa:** Escriba columnas de petición, valor recortado, mando previo aplicado e intervalo admisible.

**Criterio de refutación:** Un salto supera velocidad por intervalo o la petición anterior sustituye al mando aplicado.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
