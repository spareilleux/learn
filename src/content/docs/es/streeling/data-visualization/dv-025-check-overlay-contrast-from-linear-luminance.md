---
title: Comprobar el contraste de una anotación con luminancia lineal
description: Comprobar el contraste de una anotación con luminancia lineal — Visualización de datos
sidebar:
  label: DV-025 · Comprobar el contraste de una anotación con luminancia lineal
  order: 25
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-025-check-overlay-contrast-from-linear-luminance.es.md
---

:::note[Streeling University]
**DV-025** · Comprobar el contraste de una anotación con luminancia lineal · avanzado · 50 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-025-check-overlay-contrast-from-linear-luminance.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-006](../../data-visualization/dv-006-position-length-area-comparisons/), [VC-001](../../visual-computing/vc-001-accessible-fretboard-paths/)
:::

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Una anotación de bordado propuesta en [Godot](https://docs.godotengine.org/en/stable/classes/class_transform3d.html) parece clara en una captura, pero esa impresión no proporciona un cálculo de contraste. A partir de luminancias relativas ya lineales, aplique la razón [WCAG](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) y el umbral declarado para texto. El valor más claro va en el numerador independientemente de su etiqueta de primer plano o fondo. Los canales RGB codificados no son esas luminancias. El cálculo solo comprueba el par opaco indicado; no certifica una escena renderizada ni toda su accesibilidad.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "foreground_luminance": 0.2,
    "background_luminance": 1,
    "threshold": 4.5
  },
  "formula": "ratio=(max(foreground_luminance,background_luminance)+0.05)/(min(foreground_luminance,background_luminance)+0.05); passes=ratio>=threshold",
  "expected": {
    "ratio": 4.2,
    "passes": false
  },
  "negative_control": {
    "values": {
      "foreground_luminance": 0.1,
      "background_luminance": 1,
      "threshold": 4.5
    },
    "expected": {
      "ratio": 7,
      "passes": true
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** Las entradas son luminancias relativas lineales y un umbral explícito, no bytes RGB.

</details>

### Ejercicio 2

Calcule la razón de contraste y la decisión con el umbral declarado.

<details><summary>Respuesta 2</summary>

> **Respuesta:** La razón es `4.2`, inferior a `4.5`; el par indicado no cumple este criterio.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** Una impresión visual o una prueba de teclado no sustituye el cálculo de luminancias.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** El primer plano modificado produce una razón de `7` y supera el mismo umbral.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** La composición renderizada, las variaciones del fondo y otros criterios requieren observaciones independientes.

</details>

## Tarea con fuentes y referencia manual directa

Prepare una nota de colores opacos para una anotación Atlas con las luminancias lineales indicadas.

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

- [Requisito previo versionado: dv-006-position-length-area-comparisons](../../data-visualization/dv-006-position-length-area-comparisons/)
- [Requisito previo versionado: vc-001-accessible-fretboard-paths](../../visual-computing/vc-001-accessible-fretboard-paths/)
- [Artefacto local conservado](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
- [Expediente del caso construido](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
