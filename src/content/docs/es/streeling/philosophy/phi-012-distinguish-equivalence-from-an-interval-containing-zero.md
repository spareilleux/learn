---
title: Distinguir la equivalencia de un intervalo que contiene cero
description: Distinguir la equivalencia de un intervalo que contiene cero — Filosofía
sidebar:
  label: PHI-012 · Distinguir la equivalencia de un intervalo que contiene cero
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/es/phi-012-distinguish-equivalence-from-an-interval-containing-zero.es.md
---

:::note[Streeling University]
**PHI-012** · Distinguir la equivalencia de un intervalo que contiene cero · avanzado · 45 minutos

Generado por el departamento *Filosofía* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/es/phi-012-distinguish-equivalence-from-an-interval-containing-zero.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHI-006](../../philosophy/phi-006-preserve-the-quantifier-in-a-fold-verdict/), [PHI-011](../../philosophy/phi-011-cross-mesh-and-lighting-before-attributing-a-render-change/)
:::

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Un intervalo de diferencias residuales de una limpieza propuesta contiene cero y el informe declara equivalencia. Contener cero solo hace compatible la igualdad con el intervalo. La equivalencia bajo un margen práctico exige que todo el conjunto admisible quede dentro de ese margen. Esta lección convierte la distinción de cuantificadores en una operación de revisión precisa.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Los intervalos son conjuntos admisibles inventados, no intervalos de confianza calibrados ni resultados de pruebas. Acotar todos los valores exige más que encontrar uno aceptable. Elija el margen antes de inspeccionar el candidato y conserve su significado: una tolerancia de pantalla no establece equivalencia perceptiva. El script expone ajustes de captura, sin evidencia de intervalos ni criterio de equivalencia. La referencia lógica distingue satisfacibilidad de validez y ayuda a comprobar el cuantificador utilizado.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "difference_interval": [
      -0.1,
      0.15
    ],
    "equivalence_margin": 0.2
  },
  "formula": "contains_zero=(lo<=0<=hi); equivalent=(lo>=-margin and hi<=margin); compatible_with_equivalence=(hi>=-margin and lo<=margin); width=hi-lo",
  "expected": {
    "contains_zero": true,
    "equivalent": true,
    "compatible_with_equivalence": true,
    "width": 0.25
  },
  "negative_control": {
    "values": {
      "difference_interval": [
        -0.5,
        0.5
      ],
      "equivalence_margin": 0.2
    },
    "expected": {
      "contains_zero": true,
      "equivalent": false,
      "compatible_with_equivalence": true,
      "width": 1
    }
  }
}
```

### Ejercicio 1

¿El intervalo principal contiene cero?

<details><summary>Respuesta 1</summary>

Sí: `contains_zero=true`. Esto establece compatibilidad con la igualdad, sin demostrar igualdad exacta.

</details>

### Ejercicio 2

¿Cumple el límite de equivalencia declarado?

<details><summary>Respuesta 2</summary>

Sí: `equivalent=true`; su anchura es `0.25`. Ambos extremos quedan dentro del margen prescrito.

</details>

### Ejercicio 3

Aplique el control más amplio.

<details><summary>Respuesta 3</summary>

Conserva `contains_zero=true`, pero `equivalent=false`, con anchura `1`. La compatibilidad con equivalencia sigue en `true`.

</details>

### Ejercicio 4

¿Un intervalo inconcluyente demuestra una diferencia perjudicial?

<details><summary>Respuesta 4</summary>

No. El conjunto amplio permite valores aceptables e inaceptables. Conserve esa ambigüedad sin afirmar equivalencia ni perjuicio.

</details>

### Ejercicio 5

¿Qué requeriría una afirmación real de equivalencia?

<details><summary>Respuesta 5</summary>

Defina previamente tarea y margen, justifique cómo obtuvo el intervalo y conserve las observaciones pertinentes. Este cálculo de conjuntos no es una prueba estadística de equivalencia.

</details>

## Tarea con consulta de fuentes

Dibuje ambos intervalos sobre la misma banda de tolerancia. Inspeccione los argumentos de captura e indique el contrato de medición que falta. Reescriba una afirmación basada en contener cero con el cuantificador correcto.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

El control amplio, que permite diferencias fuera del margen, refuta que cualquier intervalo que contenga cero demuestre equivalencia práctica.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: phi-006-preserve-the-quantifier-in-a-fold-verdict](../../philosophy/phi-006-preserve-the-quantifier-in-a-fold-verdict/)

- [Prerrequisito ya confirmado: phi-011-cross-mesh-and-lighting-before-attributing-a-render-change](../../philosophy/phi-011-cross-mesh-and-lighting-before-attributing-a-render-change/)

- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/glb_pipeline.py)

- [Lectura primaria](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/)

- [Paquete inventado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
