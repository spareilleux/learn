---
module_id: "phi-016-compose-unknown-evidence-with-strong-kleene-rules"
department: "philosophy"
course: "Componer evidencia desconocida con reglas fuertes de Kleene"
level: "advanced"
prerequisites: ["phi-001-how-to-argue-well", "sem-003-status-signs-and-evidence"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Componer evidencia desconocida con reglas fuertes de Kleene

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Un resumen de evidencia [Demerzel](https://github.com/GuitarAlchemist/Demerzel) contiene una proposición sin resolver. Convertir lo desconocido en falso hace que su negación invente evidencia positiva; convertirlo en verdadero también inventa evidencia. Declare una interpretación fuerte de Kleene con falso, desconocido y verdadero en ese orden. La conjunción toma el mínimo, la disyunción el máximo y la negación conserva lo desconocido. Es una interpretación propuesta para razonar, no un control desplegado. Lo desconocido indica estado no disponible, no evidencia contradictoria ni probabilidad intermedia.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "p": "U",
    "q": "F",
    "order": [
      "F",
      "U",
      "T"
    ]
  },
  "formula": "AND=min and OR=max under F<U<T; NOT swaps F and T and preserves U; excluded_middle=OR(p,NOT(p))",
  "expected": {
    "and": "F",
    "or": "U",
    "not_p": "U",
    "excluded_middle": "U"
  },
  "negative_control": {
    "values": {
      "p": "U",
      "q": "T",
      "order": [
        "F",
        "U",
        "T"
      ]
    },
    "expected": {
      "and": "U",
      "or": "T",
      "not_p": "U",
      "excluded_middle": "U"
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** `U` significa estado sin resolver, no falso ni puntuación de confianza.

</details>

### Ejercicio 2

Evalúe la conjunción, la disyunción y la negación principales.

<details><summary>Respuesta 2</summary>

> **Respuesta:** La conjunción es `F`, la disyunción `U` y la negación `U`.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** El tercero excluido es `U`; importar la tabla clásica cambiaría la interpretación declarada.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** La conjunción del control es `U` y la disyunción `T`; la negación sigue en `U`.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** Una política real necesita su regla de acción y evidencia vinculada; esta tabla no autoriza nada.

</details>

## Tarea con fuentes y referencia manual directa

Prepare un registro de valores de verdad junto a la repetición del esquema Demerzel sin convertirla en ejecución de políticas.

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
- [Requisito previo versionado: sem-003-status-signs-and-evidence](../../semiotics/en/sem-003-status-signs-and-evidence.md)
- [Artefacto local conservado](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Lectura primaria](https://plato.stanford.edu/entries/logic-manyvalued/)
- [Expediente del caso construido](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
