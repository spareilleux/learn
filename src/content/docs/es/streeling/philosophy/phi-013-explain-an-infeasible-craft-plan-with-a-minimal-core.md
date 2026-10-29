---
title: Explicar un plan artesanal inviable mediante un núcleo mínimo
description: Explicar un plan artesanal inviable mediante un núcleo mínimo — Filosofía
sidebar:
  label: PHI-013 · Explicar un plan artesanal inviable mediante un núcleo mínimo
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/es/phi-013-explain-an-infeasible-craft-plan-with-a-minimal-core.es.md
---

:::note[Streeling University]
**PHI-013** · Explicar un plan artesanal inviable mediante un núcleo mínimo · avanzado · 45 minutos

Generado por el departamento *Filosofía* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/es/phi-013-explain-an-infeasible-craft-plan-with-a-minimal-core.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-009](../../computer-science/cs-009-composing-origami-panel-constraints/), [PHI-008](../../philosophy/phi-008-separate-a-test-oracle-from-a-specification/)
:::

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Un plan artesanal incumple varios controles y un agente propone eliminar un requisito conveniente. Una explicación útil identifica un subconjunto ya contradictorio y demuestra por qué importa cada miembro. El prerrequisito de origami muestra fallos de composición; esta lección añade una explicación mínima con testigos de eliminación en un dominio de diseño finito.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Mantenga fijos el dominio y las desigualdades nombradas al estudiar subconjuntos. Un núcleo insatisfacible explica una contradicción; la minimalidad por inclusión exige además que cada subconjunto propio sea satisfacible. La guía [Z3](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/) describe núcleos nombrados sin garantizar minimalidad. Nuestro caso finito la demuestra a mano, sin ejecutar un solucionador. Las dimensiones Atlas motivan una futura transferencia, sin aportar estos valores inventados. Hallar una contradicción mínima no decide qué requisito relajar ni quién puede autorizarlo.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "domain": [
      0,
      10
    ],
    "lower_x": 8,
    "upper_x": 6,
    "lower_y": 1,
    "sum_limit": 10
  },
  "formula": "Integer x,y in inclusive domain; A:x>=lower_x; B:x<=upper_x; C:y>=lower_y; D:x+y<=sum_limit; enumerate full solutions; enumerate nonempty constraint subsets; a minimal core has no solution and every proper subset has one",
  "expected": {
    "full_solution_count": 0,
    "minimal_cores": [
      [
        "A",
        "B"
      ]
    ],
    "core_deletion_witnesses": {
      "remove_A": [
        0,
        0
      ],
      "remove_B": [
        8,
        0
      ]
    }
  },
  "negative_control": {
    "values": {
      "domain": [
        0,
        10
      ],
      "lower_x": 8,
      "upper_x": 9,
      "lower_y": 1,
      "sum_limit": 10
    },
    "expected": {
      "full_solution_count": 3,
      "minimal_cores": [],
      "core_deletion_witnesses": {}
    }
  }
}
```

### Ejercicio 1

Encuentre la contradicción principal.

<details><summary>Respuesta 1</summary>

Las restricciones `[A,B]` exigen límites incompatibles sobre la misma dimensión; el número de soluciones completas es `0`.

</details>

### Ejercicio 2

Demuestre que el núcleo es mínimo.

<details><summary>Respuesta 2</summary>

Sin A se admite `[0,0]`; sin B se admite `[8,0]`. Estos testigos satisfacen el miembro restante del núcleo y el dominio, no necesariamente todos los demás requisitos del plan.

</details>

### Ejercicio 3

¿Eliminar la restricción de suma corrige el plan original?

<details><summary>Respuesta 3</summary>

No. Permanecen los límites incompatibles. Una reparación debe abordar algún miembro del núcleo o cambiar la semántica del dominio declarado.

</details>

### Ejercicio 4

Aplique el límite superior relajado.

<details><summary>Respuesta 4</summary>

Hay `3` soluciones completas y ningún núcleo mínimo: `[]`. Los puntos son `[8,1]`, `[8,2]` y `[9,1]`.

</details>

### Ejercicio 5

¿Un núcleo mínimo autoriza modificar el diseño?

<details><summary>Respuesta 5</summary>

No. Explica la inviabilidad. Coste, seguridad, intención artesanal y autoridad determinan reparaciones admisibles; una explicación pequeña no es una relajación preferida.

</details>

## Tarea con consulta de fuentes

Enumere los candidatos enteros y tache las infracciones a mano. Encuentre el núcleo, guarde testigos de eliminación e inspeccione el límite de dimensiones Atlas. Distinga contradicción, minimalidad y autoridad para reparar.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

Una asignación que satisfaga el núcleo o un subconjunto propio aún incompatible refuta una minimalidad declarada; conserve cualquiera de esos testigos.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: cs-009-composing-origami-panel-constraints](../../computer-science/cs-009-composing-origami-panel-constraints/)

- [Prerrequisito ya confirmado: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/phi-008-separate-a-test-oracle-from-a-specification/)

- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)

- [Lectura primaria](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/)

- [Paquete inventado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
