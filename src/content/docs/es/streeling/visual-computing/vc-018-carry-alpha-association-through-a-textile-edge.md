---
title: Conservar la asociación alfa en el borde de un textil
description: Conservar la asociación alfa en el borde de un textil — Computación visual
sidebar:
  label: VC-018 · Conservar la asociación alfa en el borde de un textil
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/es/vc-018-carry-alpha-association-through-a-textile-edge.es.md
---

:::note[Streeling University]
**VC-018** · Conservar la asociación alfa en el borde de un textil · avanzado · 45 minutos

Generado por el departamento *Computación visual* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/es/vc-018-carry-alpha-association-through-a-textile-edge.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-009](../../physics/phy-009-distinguish-linear-color-from-display-encoding/), [VC-010](../../visual-computing/vc-010-preserve-packed-texture-channel-contracts/)
:::

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Un recorte bordado transparente puede adquirir un halo oscuro si el consumidor multiplica el color por alfa dos veces. El orden de canales y la codificación de color no indican si RGB ya está asociado a alfa. Esta lección añade esa convención a una propuesta de transferencia de texturas de ComfyUI a una escena.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Parta del color sin asociar, forme una vez su contribución y use la ecuación source-over premultiplicada. La contribución del fondo disminuye según la fracción descubierta. El [W3C](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/) define estas representaciones; el helper ComfyUI inspeccionado recupera bytes sin declarar la asociación alfa de sus píxeles. Una descarga correcta no resuelve esa cuestión. Un píxel opaco discrimina mal los caminos porque la asociación correcta y la doble multiplicación coinciden.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "source_straight": [
      1,
      0,
      0
    ],
    "source_alpha": 0.25,
    "backdrop_straight": [
      0,
      0,
      1
    ],
    "backdrop_alpha": 1
  },
  "formula": "premul=source_alpha*source_straight; out=premul+(1-source_alpha)*backdrop_alpha*backdrop_straight; out_alpha=source_alpha+(1-source_alpha)*backdrop_alpha; double_multiplied=source_alpha*premul+(1-source_alpha)*backdrop_alpha*backdrop_straight",
  "expected": {
    "source_premultiplied": [
      0.25,
      0,
      0
    ],
    "out_premultiplied": [
      0.25,
      0,
      0.75
    ],
    "out_alpha": 1,
    "double_multiplied": [
      0.0625,
      0,
      0.75
    ]
  },
  "negative_control": {
    "values": {
      "source_straight": [
        1,
        0,
        0
      ],
      "source_alpha": 1,
      "backdrop_straight": [
        0,
        0,
        1
      ],
      "backdrop_alpha": 1
    },
    "expected": {
      "source_premultiplied": [
        1,
        0,
        0
      ],
      "out_premultiplied": [
        1,
        0,
        0
      ],
      "out_alpha": 1,
      "double_multiplied": [
        1,
        0,
        0
      ]
    }
  }
}
```

### Ejercicio 1

Asocie una vez el color de origen.

<details><summary>Respuesta 1</summary>

La contribución es `[0.25,0,0]`. Conserve la etiqueta de representación junto al vector.

</details>

### Ejercicio 2

Calcule el resultado source-over.

<details><summary>Respuesta 2</summary>

El resultado es `[0.25,0,0.75]` con alfa `1`. En este fondo opaco, la salida asociada también coincide con la salida sin asociar.

</details>

### Ejercicio 3

Calcule la segunda multiplicación errónea.

<details><summary>Respuesta 3</summary>

Da `[0.0625,0,0.75]` y vuelve a reducir la contribución de origen. Es un error de representación, no evidencia de un tinte o material defectuoso.

</details>

### Ejercicio 4

Aplique el control opaco.

<details><summary>Respuesta 4</summary>

Ambos caminos dan `[1,0,0]` con alfa `1`. Ese acuerdo no valida los bordes translúcidos.

</details>

### Ejercicio 5

¿Qué debe indicar una transferencia de textura?

<details><summary>Respuesta 5</summary>

Declare dominio de color, funciones de canales, asociación alfa y orden de composición. Recuperar los bytes no aporta por sí solo esa semántica.

</details>

## Tarea con consulta de fuentes

Prepare a mano una tabla de contribuciones antes de inspeccionar el helper de descarga. Proponga un diagnóstico de borde con casos translúcidos y opacos y registre los metadatos de asociación necesarios para un futuro importador.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

La afirmación de que el acuerdo opaco demuestra un manejo correcto de alfa queda refutada por los resultados translúcidos diferentes con la misma aritmética.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: phy-009-distinguish-linear-color-from-display-encoding](../../physics/phy-009-distinguish-linear-color-from-display-encoding/)

- [Prerrequisito ya confirmado: vc-010-preserve-packed-texture-channel-contracts](../../visual-computing/vc-010-preserve-packed-texture-channel-contracts/)

- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/comfyui/ga-lab/runner/comfy.py)

- [Lectura primaria](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/)

- [Paquete inventado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
