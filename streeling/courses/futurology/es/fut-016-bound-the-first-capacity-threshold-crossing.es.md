---
module_id: "fut-016-bound-the-first-capacity-threshold-crossing"
department: "futurology"
course: "Acotar el primer cruce de un umbral de capacidad"
level: "advanced"
prerequisites: ["fut-010-project-weave-density-before-a-scene-expansion"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Acotar el primer cruce de un umbral de capacidad

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Una escena de bordado propuesta aumenta su inventario de cruces en cada periodo. Una fecha única oculta la incertidumbre de esa premisa. Evalúe ambos factores de crecimiento declarados en el mismo horizonte discreto y busque el primer periodo que alcanza la capacidad. La trayectoria rápida da el cruce más temprano y la lenta el más tardío porque cada valor de periodo positivo crece con el factor. Un cruce ausente sigue ausente; no extrapole fuera del horizonte ni presente estas cotas como límites de confianza.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "initial": 8,
    "growth_bounds": [
      1.25,
      1.5
    ],
    "capacity": 18,
    "last_period": 4
  },
  "formula": "load[t]=initial*growth**t for integer t in [0,last_period]; crossing=min(t with load[t]>=capacity), or null; earliest=min(non-null crossings); latest=max(crossings) only if all cross",
  "expected": {
    "paths": [
      [
        8,
        10,
        12.5,
        15.625,
        19.53125
      ],
      [
        8,
        12,
        18,
        27,
        40.5
      ]
    ],
    "crossings": [
      4,
      2
    ],
    "earliest": 2,
    "latest": 4
  },
  "negative_control": {
    "values": {
      "initial": 8,
      "growth_bounds": [
        1.25,
        1.5
      ],
      "capacity": 50,
      "last_period": 4
    },
    "expected": {
      "paths": [
        [
          8,
          10,
          12.5,
          15.625,
          19.53125
        ],
        [
          8,
          12,
          18,
          27,
          40.5
        ]
      ],
      "crossings": [
        null,
        null
      ],
      "earliest": null,
      "latest": null
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** Los factores ordenados son `1.25` y `1.5`; el horizonte incluye el periodo `0`.

</details>

### Ejercicio 2

Encuentre ambos primeros periodos de cruce y la ventana correspondiente.

<details><summary>Respuesta 2</summary>

> **Respuesta:** Los primeros cruces son `[4,2]`, así que la ventana acotada es `[2,4]`. La igualdad con la capacidad cuenta.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** Las cotas de crecimiento son premisas, no frecuencias observadas ni un intervalo de confianza.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** Con capacidad `50`, ambos cruces son `null`; ninguna trayectoria la alcanza hasta el periodo `4`.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** Mida la carga y calibre el crecimiento antes de adoptar una fecha; el inventario no es tiempo de renderizado.

</details>

## Tarea con fuentes y referencia manual directa

Tabule ambas trayectorias de inventario Atlas y marque el primer cruce dentro del horizonte retenido.

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

- [Requisito previo versionado: fut-010-project-weave-density-before-a-scene-expansion](../../futurology/en/fut-010-project-weave-density-before-a-scene-expansion.md)
- [Artefacto local conservado](../../../../code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://docs.python.org/3/library/math.html)
- [Expediente del caso construido](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
