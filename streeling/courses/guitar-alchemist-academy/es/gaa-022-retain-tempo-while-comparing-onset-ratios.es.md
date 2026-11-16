---
module_id: "gaa-022-retain-tempo-while-comparing-onset-ratios"
department: "guitar-alchemist-academy"
course: "Conservar el tempo al comparar proporciones entre ataques"
level: "advanced"
prerequisites: ["gaa-010-define-a-practice-pass-before-counting-success", "mcl-017-integrate-a-tempo-ramp-in-beat-coordinates"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Conservar el tempo al comparar proporciones entre ataques

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Un intento conserva las proporciones de un ritmo aunque dura más. Dividir los intervalos entre ataques por su suma elimina la escala temporal global; conserve por separado esa suma. Calcule las diferencias absolutas de los intervalos normalizados y su suma. Es una discrepancia de forma deliberadamente invariante a la escala, no una alineación completa con un reloj de pulsos ni una regla de aprobación. Ignora la posición absoluta del primer ataque y no evalúa articulación ni escucha. Una forma perfecta puede coexistir con un tempo inadecuado para otra tarea declarada.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "target_ioi": [
      1,
      2,
      1
    ],
    "attempt_ioi": [
      2,
      4,
      2
    ]
  },
  "formula": "normalize each positive IOI vector by its own sum; errors=abs(target_normalized-attempt_normalized); shape_L1=sum(errors); duration_ratio=sum(attempt)/sum(target)",
  "expected": {
    "target_normalized": [
      0.25,
      0.5,
      0.25
    ],
    "attempt_normalized": [
      0.25,
      0.5,
      0.25
    ],
    "errors": [
      0,
      0,
      0
    ],
    "shape_L1": 0,
    "duration_ratio": 2
  },
  "negative_control": {
    "values": {
      "target_ioi": [
        1,
        2,
        1
      ],
      "attempt_ioi": [
        2,
        3,
        3
      ]
    },
    "expected": {
      "target_normalized": [
        0.25,
        0.5,
        0.25
      ],
      "attempt_normalized": [
        0.25,
        0.375,
        0.375
      ],
      "errors": [
        0,
        0.125,
        0.125
      ],
      "shape_L1": 0.25,
      "duration_ratio": 2
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** Los intervalos positivos no son marcas temporales absolutas; normalice cada vector por separado.

</details>

### Ejercicio 2

Normalice los vectores principales de intervalos y calcule su error de forma.

<details><summary>Respuesta 2</summary>

> **Respuesta:** Ambos vectores principales normalizados son `[0.25,0.5,0.25]`, con error de forma `0`.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** La razón de duración `2` sigue siendo necesaria; la normalización sola oculta la ejecución más lenta.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** El error de forma del control es `0.25` mientras la razón de duración sigue siendo `2`.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** Declare la tolerancia de tempo y recopile ataques observados antes de puntuar a un guitarrista.

</details>

## Tarea con fuentes y referencia manual directa

Calcule una puntuación de forma rítmica con su razón de duración y conserve el expediente de eventos como contexto histórico.

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

- [Requisito previo versionado: gaa-010-define-a-practice-pass-before-counting-success](../../guitar-alchemist-academy/en/gaa-010-define-a-practice-pass-before-counting-success.md)
- [Requisito previo versionado: mcl-017-integrate-a-tempo-ramp-in-beat-coordinates](../../musicology/en/mcl-017-integrate-a-tempo-ramp-in-beat-coordinates.md)
- [Artefacto local conservado](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)
- [Lectura primaria](https://docs.python.org/3/library/math.html)
- [Expediente del caso construido](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
