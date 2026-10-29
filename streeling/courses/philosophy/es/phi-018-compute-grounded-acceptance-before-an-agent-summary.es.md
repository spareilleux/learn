---
module_id: "phi-018-compute-grounded-acceptance-before-an-agent-summary"
department: "philosophy"
course: "Calcular la aceptación fundamentada antes de un resumen agéntico"
level: "advanced"
prerequisites: ["phi-001-how-to-argue-well", "phi-008-separate-a-test-oracle-from-a-specification"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Calcular la aceptación fundamentada antes de un resumen agéntico

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Un debate agéntico propuesto contiene argumentos y ataques dirigidos, pero su resumen cuenta apoyos. Calcule la defensa: un conjunto defiende un argumento cuando ataca a todos sus atacantes. Empiece con el conjunto vacío y reúna los argumentos defendidos hasta el punto fijo finito. Esta extensión fundamentada depende del grafo suministrado, no del número de votos ni de la confianza. El grafo es construido; su aceptación no verifica contenido, credibilidad, ataques ausentes ni autorización. Un desacuerdo cíclico puede quedar sin resolver sin hacer falsos todos los argumentos.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "arguments": [
      "A",
      "B",
      "C"
    ],
    "attacks": [
      [
        "A",
        "B"
      ],
      [
        "B",
        "C"
      ]
    ]
  },
  "formula": "F(S)={a: every b attacking a is attacked by some s in S}; iterate S0=empty,S_next=F(S) until equality; out={a attacked by grounded}; undecided=remaining arguments",
  "expected": {
    "iterations": [
      [],
      [
        "A"
      ],
      [
        "A",
        "C"
      ],
      [
        "A",
        "C"
      ]
    ],
    "grounded": [
      "A",
      "C"
    ],
    "out": [
      "B"
    ],
    "undecided": []
  },
  "negative_control": {
    "values": {
      "arguments": [
        "A",
        "B",
        "C"
      ],
      "attacks": [
        [
          "A",
          "B"
        ],
        [
          "B",
          "C"
        ],
        [
          "C",
          "A"
        ]
      ]
    },
    "expected": {
      "iterations": [
        [],
        []
      ],
      "grounded": [],
      "out": [],
      "undecided": [
        "A",
        "B",
        "C"
      ]
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** Un ataque es dirigido; defender exige contraatacar a cada atacante.

</details>

### Ejercicio 2

Enumere las iteraciones de defensa y su punto fijo fundamentado.

<details><summary>Respuesta 2</summary>

> **Respuesta:** La iteración da `[[],[A],[A,C],[A,C]]`, con conjunto fundamentado `[A,C]`.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** El conjunto rechazado `[B]` registra ataques de argumentos aceptados, no prueba que una fuente sea falsa.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** El control tiene conjuntos fundamentado y rechazado vacíos; `[A,B,C]` siguen sin decidir.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** Contenido real, integridad de ataques y autoridad necesitan revisión independiente antes de adoptar el modelo.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje el grafo de ataques propuesto y cada iteración de defensa junto al alcance de la evidencia consultiva conservada.

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

- [Requisito previo versionado: phi-001-how-to-argue-well](../../philosophy/en/phi-001-how-to-argue-well.md)
- [Requisito previo versionado: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/en/phi-008-separate-a-test-oracle-from-a-specification.md)
- [Artefacto local conservado](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Lectura primaria](https://cse-robotics.engr.tamu.edu/dshell/cs631/papers/dung95acceptability.pdf)
- [Expediente del caso construido](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
