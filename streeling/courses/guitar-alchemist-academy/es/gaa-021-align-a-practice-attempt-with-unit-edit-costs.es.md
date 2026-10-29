---
module_id: "gaa-021-align-a-practice-attempt-with-unit-edit-costs"
department: "guitar-alchemist-academy"
course: "Alinear un intento musical con costes unitarios de edición"
level: "advanced"
prerequisites: ["gaa-019-retrieve-overlapping-interval-motifs"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Alinear un intento musical con costes unitarios de edición

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Un guitarrista inserta una nota antes de una frase por lo demás correcta. Una comparación posición por posición convierte la inserción en varios errores aparentes. Declare costes unitarios de inserción, eliminación y sustitución y complete la tabla finita de Levenshtein. Así obtiene una puntuación mínima de alineación sin confundirla con búsqueda exacta de motivos contiguos. La puntuación no incluye ritmo, digitación ni expresión. Pueden existir alineaciones empatadas; sin una regla de desempate, conserve la distancia sin inventar un diagnóstico único.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "target": [
      60,
      62,
      64
    ],
    "attempt": [
      60,
      61,
      62,
      64
    ]
  },
  "formula": "D[i,0]=i; D[0,j]=j; D[i,j]=min(D[i-1,j]+1,D[i,j-1]+1,D[i-1,j-1]+(target[i-1]!=attempt[j-1])); distance=D[len(target),len(attempt)]",
  "expected": {
    "table": [
      [
        0,
        1,
        2,
        3,
        4
      ],
      [
        1,
        0,
        1,
        2,
        3
      ],
      [
        2,
        1,
        1,
        1,
        2
      ],
      [
        3,
        2,
        2,
        2,
        1
      ]
    ],
    "distance": 1
  },
  "negative_control": {
    "values": {
      "target": [
        60,
        62,
        64
      ],
      "attempt": [
        64,
        62,
        60
      ]
    },
    "expected": {
      "table": [
        [
          0,
          1,
          2,
          3
        ],
        [
          1,
          1,
          2,
          2
        ],
        [
          2,
          2,
          1,
          2
        ],
        [
          3,
          2,
          2,
          2
        ]
      ],
      "distance": 2
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** Las filas indexan prefijos objetivo y las columnas prefijos del intento; los prefijos vacíos fijan el borde.

</details>

### Ejercicio 2

Encuentre la distancia principal y una edición de secuencia que atestigüe ese coste.

<details><summary>Respuesta 2</summary>

> **Respuesta:** La distancia inferior derecha es `1`; eliminar la nota insertada `61` proporciona un testigo.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** La puntuación depende de símbolos ordenados, no solo de pertenencia a un conjunto de clases de altura.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** El control invertido tiene distancia `2`; un conjunto de notas igual no implica una frase igual.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** La tabla no atribuye un error a destreza motora, escucha o atención sin observaciones.

</details>

## Tarea con fuentes y referencia manual directa

Complete a mano la tabla de prefijos antes de proponer comentarios sobre una nota insertada.

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

- [Requisito previo versionado: gaa-019-retrieve-overlapping-interval-motifs](../../guitar-alchemist-academy/en/gaa-019-retrieve-overlapping-interval-motifs.md)
- [Artefacto local conservado](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)
- [Lectura primaria](https://docs.python.org/3/library/math.html)
- [Expediente del caso construido](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
