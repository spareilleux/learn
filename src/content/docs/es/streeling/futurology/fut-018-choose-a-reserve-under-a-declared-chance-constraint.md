---
title: Elegir una reserva con una restricción probabilística declarada
description: Elegir una reserva con una restricción probabilística declarada — Futurología
sidebar:
  label: FUT-018 · Elegir una reserva con una restricción probabilística declarada
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/futurology/es/fut-018-choose-a-reserve-under-a-declared-chance-constraint.es.md
---

:::note[Streeling University]
**FUT-018** · Elegir una reserva con una restricción probabilística declarada · avanzado · 50 minutos

Generado por el departamento *Futurología* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/futurology/es/fut-018-choose-a-reserve-under-a-declared-chance-constraint.es.md) · [Mi diario](../../journal/)

Requisitos previos: [FUT-012](../../futurology/fut-012-budget-the-worst-tail-mass-of-a-renderer-scenario/)
:::

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Una cola propuesta de capturas artesanales necesita una reserva ante demanda incierta. En lugar de minimizar la media o la pérdida media de la peor cola, limite la probabilidad de superar la capacidad disponible. Enumere las reservas candidatas y sume la masa de los escenarios estrictamente superiores a esa capacidad. La igualdad queda atendida. La menor reserva admisible depende de la distribución suministrada; sus probabilidades son premisas didácticas, no fiabilidad medida ni garantía de ausencia de sobrecarga.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "demands": [
      8,
      10,
      14
    ],
    "probabilities": [
      0.5,
      0.3,
      0.2
    ],
    "base_capacity": 10,
    "reserves": [
      0,
      2,
      4
    ],
    "maximum_exceedance": 0.1
  },
  "formula": "p_exceed(r)=sum(probability[i] for demand[i]>base_capacity+r); passing=[r where p_exceed(r)<=maximum_exceedance]; choose minimum passing r or null",
  "expected": {
    "exceedance": [
      0.2,
      0.2,
      0
    ],
    "passing_reserves": [
      4
    ],
    "chosen_reserve": 4
  },
  "negative_control": {
    "values": {
      "demands": [
        8,
        10,
        14
      ],
      "probabilities": [
        0.5,
        0.3,
        0.2
      ],
      "base_capacity": 10,
      "reserves": [
        0,
        2,
        4
      ],
      "maximum_exceedance": 0.2
    },
    "expected": {
      "exceedance": [
        0.2,
        0.2,
        0
      ],
      "passing_reserves": [
        0,
        2,
        4
      ],
      "chosen_reserve": 0
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** Use superación estricta y probabilidades de escenario normalizadas.

</details>

### Ejercicio 2

Calcule las probabilidades de superación e identifique la reserva admisible.

<details><summary>Respuesta 2</summary>

> **Respuesta:** Las probabilidades de superación son `[0.2,0.2,0]`; solo la reserva `4` cumple el límite principal.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** La restricción no acota la gravedad de una sobrecarga cuando ocurre.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** Con límite `0.2`, todos los candidatos cumplen y la menor reserva es `0`.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** Calibre las masas de los escenarios y los costes de reserva antes de decidir capacidad de producción.

</details>

## Tarea con fuentes y referencia manual directa

Enumere reservas para una carga de capturas Atlas y conserve las superaciones estrictas de cada una.

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

- [Requisito previo versionado: fut-012-budget-the-worst-tail-mass-of-a-renderer-scenario](../../futurology/fut-012-budget-the-worst-tail-mass-of-a-renderer-scenario/)
- [Artefacto local conservado](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://docs.python.org/3/library/math.html)
- [Expediente del caso construido](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
