---
module_id: "sem-021-retain-alternative-lineages-and-their-multiplicity"
department: "semiotics"
course: "Conservar linajes alternativos y su multiplicidad"
level: "advanced"
prerequisites: ["sem-003-status-signs-and-evidence"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Conservar linajes alternativos y su multiplicidad

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Un nodo propuesto de evidencia artesanal fusiona derivaciones en un conjunto de nombres de fuentes. Ese conjunto pierde la conjunción y las formas repetidas de producir una salida. Represente cada derivación como producto de tokens y sume alternativas sin descartar productos repetidos por idempotencia. Agrupe monomios iguales con coeficientes naturales. El polinomio describe el uso de fuentes, no su fiabilidad. W3C PROV aporta contexto general, no esta álgebra; el artículo primario de semianillos aporta la interpretación simbólica. Repetir una derivación no crea testigos independientes.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "derivations": [
      [
        "a",
        "b"
      ],
      [
        "a",
        "b"
      ],
      [
        "c"
      ]
    ],
    "valuation": {
      "a": 1,
      "b": 1,
      "c": 0
    }
  },
  "formula": "sort tokens inside products; collect equal monomials with integer multiplicity; evaluate sum over products of supplied token values; do not erase repeated derivations",
  "expected": {
    "coefficients": {
      "a*b": 2,
      "c": 1
    },
    "evaluated_multiplicity": 2
  },
  "negative_control": {
    "values": {
      "derivations": [
        [
          "a",
          "b"
        ],
        [
          "c"
        ]
      ],
      "valuation": {
        "a": 1,
        "b": 1,
        "c": 0
      }
    },
    "expected": {
      "coefficients": {
        "a*b": 1,
        "c": 1
      },
      "evaluated_multiplicity": 1
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** Los tokens indican ocurrencias de fuente en un álgebra declarada, no probabilidades fiables.

</details>

### Ejercicio 2

Agrupe el polinomio principal y evalúe su multiplicidad.

<details><summary>Respuesta 2</summary>

> **Respuesta:** El polinomio agrupado es `2*a*b+c` y su multiplicidad evaluada es `2`.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** Un conjunto `[a,b,c]` pierde la distinción entre uso conjunto y alternativo y las derivaciones repetidas.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** El polinomio del control es `a*b+c` y vale `1`; la pertenencia de nombres de fuente no cambia.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** El álgebra no proporciona corroboración independiente ni implementación desplegada de linaje.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje caminos de derivación de un traspaso de evidencia y conserve repeticiones antes de agrupar monomios.

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

- [Requisito previo versionado: sem-003-status-signs-and-evidence](../../semiotics/en/sem-003-status-signs-and-evidence.md)
- [Artefacto local conservado](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Lectura primaria](https://www.cs.ucdavis.edu/~green/papers/pods07.pdf)
- [W3C PROV](https://www.w3.org/TR/prov-dm/)
- [Expediente del caso construido](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
