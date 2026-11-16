---
title: Conservar los recuentos de un mapa de calor normalizado
description: Conservar los recuentos de un mapa de calor normalizado — Visualización de datos
sidebar:
  label: DV-011 · Conservar los recuentos de un mapa de calor normalizado
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-011-retain-raw-counts-behind-normalized-heatmaps.es.md
---

:::note[Streeling University]
**DV-011** · Conservar los recuentos de un mapa de calor normalizado · intermedio · 40 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-011-retain-raw-counts-behind-normalized-heatmaps.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/), [DV-008](../../data-visualization/dv-008-streeling-evidence-stage-map/)
:::

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Un panel Learn normaliza cada fila de un mapa de calor de estados de evidencia. Dos filas parecen igual de satisfactorias, pero una abarca un grupo mínimo y otra uno mayor. ¿Qué puede reconstruirse a partir de los colores? La reproducción antigua del esquema consultivo es un registro real de una comprobación limitada, no una observación de las celdas inventadas aquí. El panel permite estudiar una transformación visual que pierde información.

[Requisito previo: dv-002-denominators-and-test-populations](../../data-visualization/dv-002-denominators-and-test-populations/); [Requisito previo: dv-008-streeling-evidence-stage-map](../../data-visualization/dv-008-streeling-evidence-stage-map/)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

Divida cada celda por el total de su fila solo si es positivo. Conserve la matriz original, las etiquetas, la población y la regla de normalización junto a la visualización. Multiplicar toda una fila positiva por cualquier factor conserva los valores normalizados: el color no identifica el recuento original. Guardar el total permite reconstruir antes del redondeo; los porcentajes redondeados pueden admitir varios enteros. Una fila vacía carece de proporción empírica y debe quedar ausente, no mostrarse como fracaso medido. Esto amplía los promedios ponderados del requisito previo con una transformación no inyectiva y una condición explícita de reconstrucción.

## Caso fijo y supuestos

```text
columns=["pass","fail"]
A=[1,1]; B=[20,20]; Empty=[0,0]
row_normalized_A=[0.5,0.5]; row_normalized_B=[0.5,0.5]
raw_column_totals=[21,21]; raw_total=42
control_C=[2,8]; normalized_C=[0.2,0.8]
Empty_normalized=null
```

## Ejercicios resueltos

### Ejercicio 1

Normalice las dos filas equilibradas no vacías.

> **Respuesta:** Ambas quedan `[0.5,0.5]`, aunque sus totales son `2` y `40`. Colores iguales no demuestran igual volumen de evidencia.

### Ejercicio 2

¿Permiten las filas normalizadas recuperar los totales originales?

> **Respuesta:** No. `[1,1]` y `[20,20]` son preimágenes distintas. Conserve recuentos o totales exactos junto con proporciones sin redondear.

### Ejercicio 3

Agregue las filas equilibradas originales.

> **Respuesta:** Los totales son `[21,21]` sobre `42` registros. La proporción global de éxito es `0.5`, con su denominador conservado.

### Ejercicio 4

Normalice el control desequilibrado y la fila vacía.

> **Respuesta:** El control da `[0.2,0.8]`; la fila vacía queda `null`. Rellenarla con `[0,0]` disfrazaría una proporción indefinida de valores medidos.

### Ejercicio 5

¿Una celda normalizada acredita una revisión autorizada?

> **Respuesta:** No. El recuento sigue necesitando el registro subyacente y su vínculo con la fuente exacta. Normalizar cambia la presentación, no la autoridad ni la validez del comprobante.

## Tarea con consulta de fuentes

Lea el registro y localice el caso aceptado con evidencias vacías. Diseñe manualmente una tabla de recuentos para un mapa Learn propuesto; marque las celdas como hipotéticas. Pida ayuda para el texto y rechácelo si deduce muestras iguales o aprobación humana de colores normalizados iguales.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Fuente primaria](https://github.com/spareilleux/learn/blob/8f13637ae4596b614c2ba493b596b6a08e1cf43a/scripts/streeling-lib.mjs)
- [Expediente de evidencias fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
