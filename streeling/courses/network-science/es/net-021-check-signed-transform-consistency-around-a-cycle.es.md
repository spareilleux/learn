---
module_id: "net-021-check-signed-transform-consistency-around-a-cycle"
department: "network-science"
course: "Comprobar la coherencia de transformaciones con signo en un ciclo"
title: "Comprobar la coherencia de transformaciones con signo en un ciclo"
level: "intermediate"
prerequisites: ["net-009-detect-global-cycles-in-a-panel-stack", "net-011-separate-reachability-from-semantic-compatibility"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Comprobar la coherencia de transformaciones con signo en un ciclo

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Los paneles artesanales o las convenciones de coordenadas pueden imponer relaciones de orientación por pares. Una conserva un signo y otra lo invierte. Un diagrama puede contener un ciclo sin contradicción: la coherencia depende de las transformaciones compuestas. Esto difiere de un ciclo de precedencia, donde el orden circular impide una planificación válida.

Asigne un signo a cada vértice y exija que el producto de los signos extremos coincida con el de la arista. Fije la raíz para eliminar la ambigüedad de inversión global. Propague por un camino de expansión y compruebe todas las aristas restantes. Multiplicar relaciones alrededor del ciclo cancela los signos de vértices; por tanto, el producto de las aristas debe ser positivo. Para el triángulo declarado también es condición suficiente.

El triángulo fijo contiene inversiones compatibles. Cambiar una arista en el control hace imposible el producto cíclico. Invertir todos los signos de vértices no lo repara porque sus productos no cambian. Este modelo no representa transformaciones geométricas generales: las rotaciones espaciales pueden no conmutar y necesitan matrices o cuaterniones. Un futuro DSL debería conservar el significado y la revisión de las relaciones.

## Fuentes y alcance del proyecto

[Prerrequisito: net-009-detect-global-cycles-in-a-panel-stack](../../network-science/en/net-009-detect-global-cycles-in-a-panel-stack.md)

[Prerrequisito: net-011-separate-reachability-from-semantic-compatibility](../../network-science/en/net-011-separate-reachability-from-semantic-compatibility.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://arxiv.org/abs/1701.07963)

## Modelo fijo y control negativo

```json
{
  "values": {
    "nodes": [
      "A",
      "B",
      "C"
    ],
    "edges": [
      [
        "A",
        "B",
        1
      ],
      [
        "B",
        "C",
        -1
      ],
      [
        "A",
        "C",
        -1
      ]
    ],
    "root_sign": 1
  },
  "formula": "Require label[u]*label[v]=edge_sign with root label fixed. Enumerate remaining signs in order [1,-1]; report first satisfying assignment or null. For this triangle cycle_product is product of its three edge signs.",
  "expected": {
    "cycle_product": 1,
    "consistent": true,
    "labels": [
      1,
      1,
      -1
    ]
  },
  "negative_control": {
    "values": {
      "nodes": [
        "A",
        "B",
        "C"
      ],
      "edges": [
        [
          "A",
          "B",
          1
        ],
        [
          "B",
          "C",
          -1
        ],
        [
          "A",
          "C",
          1
        ]
      ],
      "root_sign": 1
    },
    "expected": {
      "cycle_product": -1,
      "consistent": false,
      "labels": null
    },
    "why": "One changed edge makes closed-loop sign transport contradictory."
  },
  "input_types": {
    "nodes": "ordered three distinct node strings",
    "edges": "triangle undirected pairs with sign integer +1 or -1",
    "root_sign": "fixed first-node sign +1 or -1"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "Only commuting scalar sign relations are modeled; no 3D transform, social trust, knot type or physical panel is validated."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Fijar la raíz, propagar relaciones y multiplicar signos del ciclo.

**Criterio de refutación:** El diagnóstico acepta un producto negativo o rechaza todo ciclo sin componer relaciones.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Propague los signos fijos.

> **Respuesta:** Con raíz `A=1`, los signos `[1,1,-1]` satisfacen las aristas; el producto cíclico es `1`.

### Ejercicio 2

¿Por qué falla el control?

> **Respuesta:** Su producto cíclico es `-1`. Multiplicar las ecuaciones exigiría `1=-1`; no existe asignación.

### Ejercicio 3

¿Invertir todos los signos repararía el control?

> **Respuesta:** No. La inversión global conserva los productos extremos. Hay que examinar la relación conflictiva, no ocultarla cambiando la raíz.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: Con raíz `A=1`, los signos `[1,1,-1]` satisfacen las aristas; el producto cíclico es `1`.
- Ejercicio 2: Su producto cíclico es `-1`. Multiplicar las ecuaciones exigiría `1=-1`; no existe asignación.
- Ejercicio 3: No. La inversión global conserva los productos extremos. Hay que examinar la relación conflictiva, no ocultarla cambiando la raíz.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
