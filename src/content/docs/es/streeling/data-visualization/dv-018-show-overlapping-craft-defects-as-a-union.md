---
title: Mostrar los defectos artesanales superpuestos mediante su unión
description: Mostrar los defectos artesanales superpuestos mediante su unión — Visualización de datos
sidebar:
  label: DV-018 · Mostrar los defectos artesanales superpuestos mediante su unión
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-018-show-overlapping-craft-defects-as-a-union.es.md
---

:::note[Streeling University]
**DV-018** · Mostrar los defectos artesanales superpuestos mediante su unión · avanzado · 45 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-018-show-overlapping-craft-defects-as-a-union.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-015](../../data-visualization/dv-015-map-missing-stitches-without-inventing-holes/)
:::

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Un informe de textura marca un fallo de costura y otro de color en regiones superpuestas. Sumar sus áreas cuenta dos veces la región común y puede exagerar la superficie afectada. El prerrequisito distingue ausencia de observación no disponible. Aquí se conocen las áreas; el problema nuevo es el solapamiento entre categorías.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Divida el lienzo en categorías exclusivas antes de apilar marcas: solo la primera máscara, solo la segunda, ambas y ninguna. Sus áreas cubren el lienzo una sola vez. El [W3C](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/) describe combinaciones sensibles al solapamiento; estas máscaras binarias son un modelo de conjuntos inventado, no valores alfa ni defectos renderizados. El helper ComfyUI devuelve bytes sin demostrar qué regiones contienen defectos. Un ejemplo disjunto correcto no valida el resumen de defectos superpuestos.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "canvas_area": 100,
    "mask_a_area": 30,
    "mask_b_area": 25,
    "intersection_area": 10
  },
  "formula": "a_only=A-I; b_only=B-I; both=I; union=A+B-I; neither=canvas-union; naive_sum=A+B",
  "expected": {
    "a_only": 20,
    "b_only": 15,
    "both": 10,
    "union": 45,
    "neither": 55,
    "naive_sum": 55
  },
  "negative_control": {
    "values": {
      "canvas_area": 100,
      "mask_a_area": 30,
      "mask_b_area": 25,
      "intersection_area": 0
    },
    "expected": {
      "a_only": 30,
      "b_only": 25,
      "both": 0,
      "union": 55,
      "neither": 45,
      "naive_sum": 55
    }
  }
}
```

### Ejercicio 1

Obtenga las áreas afectadas exclusivas.

<details><summary>Respuesta 1</summary>

Solo la primera ocupa `20`, solo la segunda `15` y ambas `10` unidades de área. Separe el significado de cada categoría del color elegido.

</details>

### Ejercicio 2

Calcule las áreas afectada única y no afectada.

<details><summary>Respuesta 2</summary>

Son `45` y `55`. La partición exclusiva suma `100`.

</details>

### Ejercicio 3

Cuantifique el error de la suma ingenua.

<details><summary>Respuesta 3</summary>

La suma es `55` y supera la unión en `10`, exactamente la intersección contada de nuevo.

</details>

### Ejercicio 4

Aplique el control disjunto.

<details><summary>Respuesta 4</summary>

La unión pasa a `55` y la zona no afectada a `45`. La suma ingenua coincide porque la intersección es `0`.

</details>

### Ejercicio 5

¿Las dos áreas de entrada determinan por sí solas la unión?

<details><summary>Respuesta 5</summary>

No. La intersección es información adicional. Si se desconoce, indique cotas en lugar de inventar una única área afectada.

</details>

## Tarea con consulta de fuentes

Dibuje manualmente el solapamiento y su tabla de áreas exclusivas. Inspeccione el límite de recuperación de imágenes y proponga una visualización con categoría compartida y un estado para intersección desconocida.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

El caso superpuesto refuta la regla de sumar siempre áreas de categorías, aunque funcione para el control disjunto.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: dv-015-map-missing-stitches-without-inventing-holes](../../data-visualization/dv-015-map-missing-stitches-without-inventing-holes/)

- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/comfyui/ga-lab/runner/comfy.py)

- [Lectura primaria](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/)

- [Paquete inventado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
