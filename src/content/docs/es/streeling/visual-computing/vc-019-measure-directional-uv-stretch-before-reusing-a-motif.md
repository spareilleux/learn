---
title: Medir el estiramiento UV direccional antes de reutilizar un motivo
description: Medir el estiramiento UV direccional antes de reutilizar un motivo — Computación visual
sidebar:
  label: VC-019 · Medir el estiramiento UV direccional antes de reutilizar un motivo
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/es/vc-019-measure-directional-uv-stretch-before-reusing-a-motif.es.md
---

:::note[Streeling University]
**VC-019** · Medir el estiramiento UV direccional antes de reutilizar un motivo · avanzado · 45 minutos

Generado por el departamento *Computación visual* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/es/vc-019-measure-directional-uv-stretch-before-reusing-a-motif.es.md) · [Mi diario](../../journal/)

Requisitos previos: [VC-016](../../visual-computing/vc-016-track-uv-gutters-through-mip-levels/)
:::

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Un motivo bordado circular puede alargarse aunque dos parches UV tengan el mismo factor de área. El margen del atlas mide separación entre islas; no describe la distorsión direccional interna. Esta lección compara los estiramientos independientes de un parche afín declarado antes de una reutilización propuesta de Blender a Godot.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

El mapa diagonal lleva los ejes a direcciones ortogonales de la superficie. Cada magnitud diagonal es un estiramiento; su producto es el factor de área. Un círculo sigue ambos estiramientos y se convierte en elipse si difieren. [PBRT](https://pbr-book.org/4ed/Shapes/Triangle_Meshes) explica derivadas UV afines en triángulos. Atlas crea objetos de malla, sin aportar resultados sobre la calidad de UV exportadas. La tabla simplificada es inventada y no representa mediciones de un recurso generado.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "dx_du": 4,
    "dy_dv": 1,
    "uv_radius": 0.1
  },
  "formula": "J=diag(dx_du,dy_dv); stretches=[abs(dx_du),abs(dy_dv)]; area_scale=abs(dx_du*dy_dv); anisotropy=max(stretches)/min(stretches); ellipse_axes=uv_radius*stretches",
  "expected": {
    "stretches": [
      4,
      1
    ],
    "area_scale": 4,
    "anisotropy": 4,
    "ellipse_axes": [
      0.4,
      0.1
    ]
  },
  "negative_control": {
    "values": {
      "dx_du": 2,
      "dy_dv": 2,
      "uv_radius": 0.1
    },
    "expected": {
      "stretches": [
        2,
        2
      ],
      "area_scale": 4,
      "anisotropy": 1,
      "ellipse_axes": [
        0.2,
        0.2
      ]
    }
  }
}
```

### Ejercicio 1

Obtenga los estiramientos y el factor de área principales.

<details><summary>Respuesta 1</summary>

Los estiramientos son `[4,1]` y el factor de área es `4`. El producto por sí solo pierde la diferencia entre direcciones.

</details>

### Ejercicio 2

Transforme el círculo UV.

<details><summary>Respuesta 2</summary>

Sus semiejes pasan a `[0.4,0.1]` unidades de escena, con anisotropía `4`. Son radios, no diámetros completos.

</details>

### Ejercicio 3

Aplique el control de igual área.

<details><summary>Respuesta 3</summary>

Los estiramientos pasan a `[2,2]`, el factor de área sigue en `4`, los semiejes son `[0.2,0.2]` y la anisotropía es `1`.

</details>

### Ejercicio 4

¿Un margen suficiente del atlas corrige la distorsión?

<details><summary>Respuesta 4</summary>

No. El margen evita otro tipo de contaminación entre islas. No modifica la derivada afín dentro del parche.

</details>

### Ejercicio 5

¿Cuándo deja de servir el atajo diagonal?

<details><summary>Respuesta 5</summary>

El cizallamiento o las derivadas no ortogonales requieren valores singulares del mapa local completo. Los parches curvos necesitan derivadas dependientes de la posición; este caso no los evalúa.

</details>

## Tarea con consulta de fuentes

Dibuje los círculos transformados con la misma escala, inspeccione la creación de mallas Atlas e identifique la evidencia UV que falta. Formule primero una recomendación basada en área y confróntela con el control antes de automatizar.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

Los mapas tienen el mismo factor de área y distinta anisotropía; esto refuta que igual área garantice conservar la forma del motivo.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: vc-016-track-uv-gutters-through-mip-levels](../../visual-computing/vc-016-track-uv-gutters-through-mip-levels/)

- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)

- [Lectura primaria](https://pbr-book.org/4ed/Shapes/Triangle_Meshes)

- [Paquete inventado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
