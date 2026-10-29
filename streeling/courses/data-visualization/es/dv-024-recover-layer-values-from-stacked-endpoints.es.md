---
module_id: "dv-024-recover-layer-values-from-stacked-endpoints"
department: "data-visualization"
course: "Recuperar los valores de las capas a partir de extremos apilados"
level: "advanced"
prerequisites: ["dv-006-position-length-area-comparisons"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Recuperar los valores de las capas a partir de extremos apilados

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Un panel apila el tiempo de preparación y corrección de objetos [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md). El extremo superior representa el esfuerzo total, mientras que el segmento superior representa solo la corrección. Recupere cada capa restando extremos acumulados contiguos antes de comparar los objetos. Totales iguales pueden ocultar costes de corrección distintos; correcciones iguales pueden tener extremos diferentes si cambia la preparación. Esta operación inversa va más allá de elegir una escala común y no supone que se haya procesado un objeto real.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "endpoints": [
      [
        0,
        2,
        8
      ],
      [
        0,
        5,
        8
      ]
    ]
  },
  "formula": "layers[j]=endpoints[j+1]-endpoints[j]; compare final endpoints separately from last-layer differences",
  "expected": {
    "layers": [
      [
        2,
        6
      ],
      [
        5,
        3
      ]
    ],
    "equal_totals": true,
    "equal_last_layers": false
  },
  "negative_control": {
    "values": {
      "endpoints": [
        [
          0,
          2,
          8
        ],
        [
          0,
          5,
          11
        ]
      ]
    },
    "expected": {
      "layers": [
        [
          2,
          6
        ],
        [
          5,
          6
        ]
      ],
      "equal_totals": false,
      "equal_last_layers": true
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** Los vectores contienen extremos acumulados con su origen, no valores independientes de cada capa.

</details>

### Ejercicio 2

Recupere los valores de las capas y distinga igualdad de totales y de capas de corrección.

<details><summary>Respuesta 2</summary>

> **Respuesta:** Las diferencias contiguas recuperan `[[2,6],[5,3]]`; coinciden los totales, pero difieren las correcciones.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** Comparar los extremos superiores compara totales, no el esfuerzo de corrección.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** El control da `[[2,6],[5,6]]`; ahora coinciden las últimas capas y difieren los totales.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** Se necesitan etapas identificadas, una unidad común y tiempos reales antes de afirmar una mejora.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje los extremos acumulados de un registro de procesamiento Atlas, recupere cada etapa y distinga igualdad de totales y de últimas capas.

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

- [Requisito previo versionado: dv-006-position-length-area-comparisons](../../data-visualization/en/dv-006-position-length-area-comparisons.md)
- [Artefacto local conservado](../../../../code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://d3js.org/d3-shape/stack)
- [Expediente del caso construido](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
