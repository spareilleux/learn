---
title: Distinguir puntos y desplazamientos bajo traslación
description: Distinguir puntos y desplazamientos bajo traslación — Semiótica
sidebar:
  label: SEM-023 · Distinguir puntos y desplazamientos bajo traslación
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/es/sem-023-keep-points-and-displacements-distinct-under-translation.es.md
---

:::note[Streeling University]
**SEM-023** · Distinguir puntos y desplazamientos bajo traslación · avanzado · 50 minutos

Generado por el departamento *Semiótica* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/es/sem-023-keep-points-and-displacements-distinct-under-translation.es.md) · [Mi diario](../../journal/)

Requisitos previos: [SEM-009](../../semiotics/sem-009-keep-units-in-a-composed-craft-instruction/), [SEM-006](../../semiotics/sem-006-preserve-orientation-across-scene-frames/)
:::

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Un DSL artesanal usa vectores numéricos iguales para posición y desplazamiento y traslada ambos por el origen del marco. Las unidades no detectan el error: ambos tienen longitud, pero solo los puntos reciben el origen. Con base identidad, traslade ambos puntos y réstelos para recuperar el desplazamiento sin cambios. Conserve el rol afín junto al valor antes de componer. Esto aísla traslación sin rotación ni escala y no añade adaptador de escena. Un desplazamiento no es una normal y una diferencia correcta no verifica importación ni medición física.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "p": [
      1,
      2,
      0
    ],
    "q": [
      4,
      6,
      0
    ],
    "translation": [
      10,
      -2,
      5
    ]
  },
  "formula": "point_world=p+translation componentwise; displacement=q-p; translated_difference=(q+translation)-(p+translation); never add translation to a displacement",
  "expected": {
    "p_world": [
      11,
      0,
      5
    ],
    "q_world": [
      14,
      4,
      5
    ],
    "displacement": [
      3,
      4,
      0
    ],
    "translated_difference": [
      3,
      4,
      0
    ]
  },
  "negative_control": {
    "values": {
      "p": [
        1,
        2,
        0
      ],
      "q": [
        4,
        6,
        0
      ],
      "translation": [
        -5,
        8,
        1
      ]
    },
    "expected": {
      "p_world": [
        -4,
        10,
        1
      ],
      "q_world": [
        -1,
        14,
        1
      ],
      "displacement": [
        3,
        4,
        0
      ],
      "translated_difference": [
        3,
        4,
        0
      ]
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** Ambos operandos tienen unidades de longitud, pero roles afines distintos.

</details>

### Ejercicio 2

Calcule ambos puntos mundiales y su diferencia relativa.

<details><summary>Respuesta 2</summary>

> **Respuesta:** Los puntos mundiales son `[11,0,5]` y `[14,4,5]`; su diferencia es `[3,4,0]`.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** Trasladar el desplazamiento asignaría incorrectamente un origen a una diferencia relativa.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** Los puntos del control son `[-4,10,1]` y `[-1,14,1]`; la diferencia sigue siendo `[3,4,0]`.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** Rotación, escala, normales e importación real necesitan otras transformaciones declaradas y evidencia.

</details>

## Tarea con fuentes y referencia manual directa

Anote posiciones Atlas y diferencias relativas con sus roles afines antes de cambiar solo el origen propuesto.

Con las respuestas ocultas, dibuje una tabla o un diagrama específico de la operación y calcule a mano el resultado principal. Este primer intento guardado constituye la referencia manual directa. Incluya las entradas, los valores intermedios, la regla de cada paso y el motivo de cualquier rechazo o valor sin resolver. Declare el criterio de refutación antes de pedir a un asistente que simplifique el trabajo. Una tabla corriente puede bastar; un DSL componible o un nodo agéntico necesita demostrar un beneficio adicional.

Consulte después el artefacto local y el pasaje primario enlazados. Registre la ubicación, la revisión, la definición utilizada y lo que esta no establece. Pida al asistente que cuestione una premisa y guarde la pregunta y su respuesta. Declare como ayuda cualquier calculadora, traducción o consulta documental. Compare el resultado asistido con la referencia inicial usando las mismas entradas. Rechace una explicación más breve si elimina una identidad, una condición o la distinción entre ejemplo construido y observación del proyecto.

Trate el control negativo como otro registro. Prediga su resultado antes de abrir la corrección y compare los campos modificados y los invariantes. Ante un desacuerdo, distinga error aritmético, error semántico y limitación de las premisas. Conserve el fallo, el diagnóstico, la corrección y la repetición en lugar de sobrescribir el primer intento. Entregue esas trazas con la explicación documentada y la incertidumbre restante. Este pequeño ciclo podrá apoyar el dogfooding; aquí no se ha medido una mejora real del aprendizaje o de la ejecución.

El expediente prepara un criterio por ejercicio sin completar las decisiones del aprendizaje. La respuesta real, el historial de ayuda, la corrección personal y la decisión siguen vacíos hasta que exista un intento. Revisión técnica, revisión lingüística, ejecución del motor, validación material, adopción y publicación requieren pruebas distintas. El cálculo finito solo establece la relación declarada bajo sus premisas. Antes de usarla en una escena o una herramienta de práctica, nombre la observación adicional y su umbral de rechazo; una solución preparada no equivale a aceptación.

## Criterio prospectivo de refutación

Se rechaza una respuesta si aplicar la operación mostrada a alguna entrada conservada contradice el resultado previsto, o si su explicación presenta el caso construido como una observación ya realizada en el proyecto.

## Criterios preparados para el alumno

- Conservar la respuesta correcta y el razonamiento intermedio del ejercicio 1, junto con el alcance de la afirmación. La decisión del aprendizaje sigue abierta.
- Conservar la respuesta correcta y el razonamiento intermedio del ejercicio 2, junto con el alcance de la afirmación. La decisión del aprendizaje sigue abierta.
- Conservar la respuesta correcta y el razonamiento intermedio del ejercicio 3, junto con el alcance de la afirmación. La decisión del aprendizaje sigue abierta.
- Conservar la respuesta correcta y el razonamiento intermedio del ejercicio 4, junto con el alcance de la afirmación. La decisión del aprendizaje sigue abierta.
- Conservar la respuesta correcta y el razonamiento intermedio del ejercicio 5, junto con el alcance de la afirmación. La decisión del aprendizaje sigue abierta.

## Fuentes y alcance de las afirmaciones

- [Requisito previo versionado: sem-009-keep-units-in-a-composed-craft-instruction](../../semiotics/sem-009-keep-units-in-a-composed-craft-instruction/)
- [Requisito previo versionado: sem-006-preserve-orientation-across-scene-frames](../../semiotics/sem-006-preserve-orientation-across-scene-frames/)
- [Artefacto local conservado](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://docs.godotengine.org/en/stable/classes/class_transform3d.html)
- [Expediente del caso construido](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
