---
module_id: "cs-024-check-semantic-parser-printer-round-trips"
department: "computer-science"
course: "Comprobar el significado tras un recorrido entre analizador e impresor"
title: "Comprobar el significado tras un recorrido entre analizador e impresor"
level: "intermediate"
prerequisites: ["cs-019-preserve-lexical-bindings-when-composing-fragments", "sem-002-chord-symbols-and-canonicalization"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Comprobar el significado tras un recorrido entre analizador e impresor

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un agente que explica GA puede reformular una expresión para hacerla legible antes de entregarla a quien escribe un pipeline IX. Una presentación cuidada puede cambiar la agrupación. A la inversa, un impresor puede conservar todas las operaciones y cambiar los espacios. Decida qué representación debe sobrevivir a la entrega antes de comparar cadenas o presentar una simplificación DSL.

El lenguaje del caso contiene enteros, sumas, multiplicaciones y paréntesis. Analice la fuente como árbol ordenado, imprima una propuesta y vuelva a analizarla con la misma gramática. Compare los árboles recursivamente. La documentación AST de Python ofrece un ejemplo concreto de garantía de árbol equivalente sin garantía de texto idéntico. Adoptamos esa distinción; esta pequeña gramática no es Python ni un nuevo analizador de GA.

El caso fijo mantiene la multiplicación en el hijo derecho de la suma. Conserva el resultado aunque las cadenas difieran. La igualdad numérica por sí sola sería más débil: dos árboles distintos podrían producir casualmente el mismo número. El control sitúa la suma debajo de la multiplicación y cambia estructura y resultado. Conserve el primer nodo distinto como diagnóstico útil.

Antes de proponer un formateador o una reescritura mediante agente, decida si comentarios, grafía y disposición forman parte del requisito. Un árbol que los omite no puede reconstruirlos. El requisito sobre enlaces léxicos aborda un fallo distinto relacionado con nombres; nuestra gramática sin nombres aísla la precedencia. Una gramática ampliada necesitaría ambas comprobaciones. La tarea es comparar árboles en papel con un criterio de refutación, sin autorizar la sustitución del analizador de producción.

El requisito de semiótica ya sigue el análisis y la representación canónica de GA, con alias convergentes. La canonicalización es trabajo previo. La comprobación adicional vuelve a analizar la expresión impresa y compara el árbol ordenado completo; la agrupación modificada refuta una ley falsa de recorrido.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: cs-019-preserve-lexical-bindings-when-composing-fragments](../../computer-science/en/cs-019-preserve-lexical-bindings-when-composing-fragments.md)

[Requisito previo: sem-002-chord-symbols-and-canonicalization](../../semiotics/en/sem-002-chord-symbols-and-canonicalization.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://docs.python.org/3/library/ast.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "source": "1 + 2 * 3",
    "printed": "1+(2*3)"
  },
  "formula": "Parse nonnegative decimal integers, +, *, and parentheses; multiplication binds tighter than addition, both left-associative. AST uses [lit,n], [add,left,right], [mul,left,right]. Compare parsed ASTs and evaluate recursively.",
  "expected": {
    "source_ast": [
      "add",
      [
        "lit",
        1
      ],
      [
        "mul",
        [
          "lit",
          2
        ],
        [
          "lit",
          3
        ]
      ]
    ],
    "printed_ast": [
      "add",
      [
        "lit",
        1
      ],
      [
        "mul",
        [
          "lit",
          2
        ],
        [
          "lit",
          3
        ]
      ]
    ],
    "same_ast": true,
    "same_text": false,
    "values": [
      7,
      7
    ]
  },
  "negative_control": {
    "values": {
      "source": "1 + 2 * 3",
      "printed": "(1+2)*3"
    },
    "expected": {
      "source_ast": [
        "add",
        [
          "lit",
          1
        ],
        [
          "mul",
          [
            "lit",
            2
          ],
          [
            "lit",
            3
          ]
        ]
      ],
      "printed_ast": [
        "mul",
        [
          "add",
          [
            "lit",
            1
          ],
          [
            "lit",
            2
          ]
        ],
        [
          "lit",
          3
        ]
      ],
      "same_ast": false,
      "same_text": false,
      "values": [
        7,
        9
      ]
    },
    "why": "Moving parentheses changes the grouping, not merely whitespace."
  },
  "input_types": {
    "source": "expression string in the declared grammar",
    "printed": "expression string in the declared grammar"
  },
  "assumptions": [
    "No names, floating-point rounding, effects or compiler optimizations.",
    "Tree equality compares tags and ordered children, ignoring no semantic node."
  ],
  "limits": "A few exact trees do not certify an entire GA or IX grammar or establish source-comment preservation."
}
```

### Ejercicio 1

¿Cuál es el árbol fuente?

<details><summary>Respuesta 1</summary>

La raíz es `add`, con hijo izquierdo `lit(1)` y derecho `mul(lit(2),lit(3))`. La multiplicación tiene prioridad; la fuente vale `7`.

</details>

### Ejercicio 2

¿Respeta el impresor fijo el contrato?

<details><summary>Respuesta 2</summary>

Sí: los árboles coinciden y ambos valores son `7`, mientras que la igualdad textual es `false`. Este contrato semántico permite cambios de espacios.

</details>

### Ejercicio 3

Evalúe la agrupación modificada.

<details><summary>Respuesta 3</summary>

El control tiene raíz `mul` y valor `9`. El árbol distinto refuta la garantía del recorrido, aunque su presentación resulte atractiva.

</details>

### Ejercicio 4

¿Probaría un valor igual la igualdad de árboles?

<details><summary>Respuesta 4</summary>

No. Operaciones distintas pueden coincidir en algunas entradas. Conserve etiquetas y orden de los hijos; indique por separado si comentarios y disposición requieren una representación sin pérdidas.

</details>

### Ejercicio 5

¿Qué evidencia justificaría una reescritura mediante agente?

<details><summary>Respuesta 5</summary>

Una gramática versionada, árboles manuales, la agrupación rechazada y cobertura de la sintaxis pertinente. El caso solo cubre las expresiones declaradas y no ejecuta un analizador de producción.

</details>

## Tarea con consulta de fuentes

Anote una reescritura propuesta por un agente en una explicación entregada de GA a IX.

**Referencia manual directa:** Dibuje ambos árboles ordenados a mano y localice su primer nodo diferente.

**Criterio de refutación:** Una propuesta que afirma conservar el árbol cambia una etiqueta o la agrupación de hijos.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: ¿Cuál es el árbol fuente? — Decisión sin resolver.
- Ejercicio 2: ¿Respeta el impresor fijo el contrato? — Decisión sin resolver.
- Ejercicio 3: Evalúe la agrupación modificada. — Decisión sin resolver.
- Ejercicio 4: ¿Probaría un valor igual la igualdad de árboles? — Decisión sin resolver.
- Ejercicio 5: ¿Qué evidencia justificaría una reescritura mediante agente? — Decisión sin resolver.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
