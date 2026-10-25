---
title: Elegir un conjunto mínimo de vistas para rasgos declarados
description: Elegir un conjunto mínimo de vistas para rasgos declarados — Visualización de datos
sidebar:
  label: DV-019 · Elegir un conjunto mínimo de vistas para rasgos declarados
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-019-choose-a-minimal-view-set-for-declared-features.es.md
---

:::note[Streeling University]
**DV-019** · Elegir un conjunto mínimo de vistas para rasgos declarados · avanzado · 45 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-019-choose-a-minimal-view-set-for-declared-features.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHI-010](../../philosophy/phi-010-state-what-a-craft-view-cannot-distinguish/), [DV-016](../../data-visualization/dv-016-compare-paired-silhouette-residuals/)
:::

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Una rotación puede producir muchas capturas y dejar sin examinar un detalle artesanal oculto. El prerrequisito demuestra pérdida de información en una vista; esta lección selecciona una colección mínima a partir de una tabla explícita de visibilidad. La minimalidad depende de los rasgos y costes declarados, sin fijar un número universal de cámaras.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Trate cada cámara como un conjunto de identificadores visibles y combine vistas mediante unión. Examine subconjuntos pequeños antes que grandes y conserve todos los mínimos empatados. Sumar recuentos de rasgos puede repetir identidades y no demuestra cobertura. El script de limpieza expone un número de fotogramas, sin aportar esta matriz binaria. Godot delimita la observación según la cámara, sin establecer estas visibilidades. Una futura prueba deberá validar cada entrada antes de seleccionar vistas.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "required": [
      "A",
      "B",
      "C",
      "D"
    ],
    "views": {
      "front": [
        "A",
        "B"
      ],
      "side": [
        "B",
        "C"
      ],
      "top": [
        "C",
        "D"
      ],
      "back": [
        "A",
        "D"
      ]
    }
  },
  "formula": "For each subset of sorted view names union feature sets; retain subsets covering required; minimize cardinality; return all tied minima in lexicographic order; if impossible return minimum_count=null and covers=[]; uncovered=required-union(all views)",
  "expected": {
    "minimum_count": 2,
    "covers": [
      [
        "back",
        "side"
      ],
      [
        "front",
        "top"
      ]
    ],
    "uncovered": []
  },
  "negative_control": {
    "values": {
      "required": [
        "A",
        "B",
        "C",
        "D"
      ],
      "views": {
        "front": [
          "A",
          "B"
        ],
        "side": [
          "B",
          "C"
        ],
        "top": [
          "C"
        ],
        "back": [
          "A"
        ]
      }
    },
    "expected": {
      "minimum_count": null,
      "covers": [],
      "uncovered": [
        "D"
      ]
    }
  }
}
```

### Ejercicio 1

¿Puede una vista cubrir todos los rasgos requeridos?

<details><summary>Respuesta 1</summary>

No. Cada vista suministrada cubre solo un subconjunto propio. Contar sus marcas no añade identidades ausentes.

</details>

### Ejercicio 2

Obtenga todas las coberturas mínimas.

<details><summary>Respuesta 2</summary>

El mínimo es `2`: `[back,side]` y `[front,top]`. Ambas cubren el conjunto requerido.

</details>

### Ejercicio 3

¿Elegir una pareja empatada demuestra optimalidad única?

<details><summary>Respuesta 3</summary>

No. Conserve ambas parejas bajo la regla de costes iguales. Una preferencia requiere otro criterio declarado.

</details>

### Ejercicio 4

Aplique el control de rasgo ausente.

<details><summary>Respuesta 4</summary>

El rasgo `[D]` queda sin cubrir; el mínimo es `null` y las coberturas son `[]`. Añadir más vistas de la lista no lo revela.

</details>

### Ejercicio 5

¿Qué añadiría una prueba física o renderizada?

<details><summary>Respuesta 5</summary>

Validaría visibilidad para la geometría, cámara y tarea de reconocimiento concretas. Una tabla inventada no demuestra que un estudiante reconozca el rasgo.

</details>

## Tarea con consulta de fuentes

Dibuje la matriz de rasgos y vistas, enumere subconjuntos a mano y conserve los empates. Inspeccione el argumento de fotogramas del pipeline e identifique las medidas ausentes. Declare el rechazo por rasgo inobservable antes de automatizar la selección.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

La afirmación de que aumentar el número de capturas listadas garantiza cobertura falla cuando un rasgo requerido no aparece en ninguna vista.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: phi-010-state-what-a-craft-view-cannot-distinguish](../../philosophy/phi-010-state-what-a-craft-view-cannot-distinguish/)

- [Prerrequisito ya confirmado: dv-016-compare-paired-silhouette-residuals](../../data-visualization/dv-016-compare-paired-silhouette-residuals/)

- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/glb_pipeline.py)

- [Lectura primaria](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html)

- [Paquete inventado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
