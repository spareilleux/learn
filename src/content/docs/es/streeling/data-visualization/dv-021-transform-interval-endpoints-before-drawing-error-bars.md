---
title: Transformar los extremos antes de dibujar barras de intervalo
description: Transformar los extremos antes de dibujar barras de intervalo — Visualización de datos
sidebar:
  label: DV-021 · Transformar los extremos antes de dibujar barras de intervalo
  order: 21
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-021-transform-interval-endpoints-before-drawing-error-bars.es.md
---

:::note[Streeling University]
**DV-021** · Transformar los extremos antes de dibujar barras de intervalo · avanzado · 45 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-021-transform-interval-endpoints-before-drawing-error-bars.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-016](../../data-visualization/dv-016-compare-paired-silhouette-residuals/)
:::

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Un panel de comparación de esculturas comprime su eje de residuos no negativos mediante raíz cuadrada. Un asistente transforma el valor central y copia después la antigua longitud simétrica a ambos lados. Esa operación puede situar los extremos en valores que la evidencia inventada nunca aportó. La cuestión es preservar un rango factible al cambiar coordenadas, sin presentar ese rango matemático como intervalo de confianza calibrado.

Transporte centro y extremos mediante el mismo mapa creciente. Solo después reste el centro mostrado para obtener las extensiones inferior y superior. Una estimación central dada no tiene por qué ser el punto medio en ninguno de los sistemas. El caso principal tiene distancias brutas desiguales pero distancias gráficas iguales; el control invierte esa relación. Estos patrones opuestos impiden sustituir el cálculo por una regla de simetría visual.

Un futuro diagnóstico Learn o [Godot](https://docs.godotengine.org/en/4.5/) necesita intervalo bruto, identificador de transformación, unidad y extremos mostrados. Los números originales siguen disponibles para cálculos y tolerancias prácticas. Transformar el eje cambia las posiciones dibujadas; no cambia la definición del residuo, crea precisión ni justifica una margen de equivalencia. El revisor asistido debe reconstruir cada extremo desde los datos conservados antes de discutir si el panel ayuda a comparar bordados o piezas metálicas.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "centre": 4,
    "lower": 1,
    "upper": 9,
    "transform": "sqrt"
  },
  "formula": "display_centre=sqrt(centre); display_lower=sqrt(lower); display_upper=sqrt(upper); lower_extent=display_centre-display_lower; upper_extent=display_upper-display_centre",
  "expected": {
    "display_centre": 2,
    "display_lower": 1,
    "display_upper": 3,
    "lower_extent": 1,
    "upper_extent": 1
  },
  "negative_control": {
    "values": {
      "centre": 4,
      "lower": 0,
      "upper": 8,
      "transform": "sqrt"
    },
    "expected": {
      "display_centre": 2,
      "display_lower": 0,
      "display_upper": 2.8284271247461903,
      "lower_extent": 2,
      "upper_extent": 0.8284271247461903
    }
  }
}
```

### Ejercicio 1

Transforme el centro dado.

<details><summary>Respuesta 1</summary>

El centro mostrado es `2`. Esto transforma solo la referencia, sin determinar los extremos.

</details>

### Ejercicio 2

Transforme ambos extremos principales.

<details><summary>Respuesta 2</summary>

Pasan a `[1,3]`. El mapa creciente en este dominio conserva su orden.

</details>

### Ejercicio 3

Derive las extensiones mostradas.

<details><summary>Respuesta 3</summary>

Ambas valen `1`, pese a distancias brutas desiguales. Reste después de transformar, sin transformar una longitud de error bruta.

</details>

### Ejercicio 4

Aplique el control simétrico bruto.

<details><summary>Respuesta 4</summary>

La extensión inferior es `2` y la superior `0.8284271247461903`. La simetría bruta no sobrevive al mapa no lineal.

</details>

### Ejercicio 5

¿El intervalo transformado establece confianza estadística?

<details><summary>Respuesta 5</summary>

No. Son límites factibles estipulados. Interpretarlos como confianza exige un procedimiento de muestreo justificado que el eje no aporta.

</details>

## Tarea con fuentes y referencia manual directa

Esboce una comparación con eje bruto y eje de raíz cuadrada. Marque los mismos extremos a mano y pida explicar cada extensión gráfica sin sustituir el intervalo original.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

Los extremos transformados independientemente refutan una regla que fuerce extensiones iguales en el control.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: dv-016-compare-paired-silhouette-residuals](../../data-visualization/dv-016-compare-paired-silhouette-residuals/)
- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://docs.python.org/3/library/math.html)
- [Paquete inventado](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
