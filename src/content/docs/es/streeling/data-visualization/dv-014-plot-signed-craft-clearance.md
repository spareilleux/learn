---
title: Representar la separación con signo de una pieza artesanal
description: Representar la separación con signo de una pieza artesanal — Visualización de datos
sidebar:
  label: DV-014 · Representar la separación con signo de una pieza artesanal
  order: 14
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-014-plot-signed-craft-clearance.es.md
---

:::note[Streeling University]
**DV-014** · Representar la separación con signo de una pieza artesanal · intermedio · 45 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-014-plot-signed-craft-clearance.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-006](../../data-visualization/dv-006-position-length-area-comparisons/)
:::

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Un panel informa la magnitud media de separación y presenta un hilo solapado como si estuviera separado. El signo perdido cambia la decisión de escena. Diseñamos una vista divergente con una línea de contacto visible y conservamos las filas elaboradas. Ampliamos la escala común tratando el cero como frontera de interpretación física y no solo como origen del eje.

## Leer el límite conservado

El conjunto de cruces conservado guarda posiciones en milímetros y una bandera de orden vinculada a roles. No contiene separaciones medidas. Los nuevos valores son didácticos; el conjunto motiva conservar unidades e identidad del cruce en una anotación propuesta para la escena.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

Defina una dirección antes de dibujar. En nuestra sección declarada, los negativos indican solapamiento, cero contacto y los positivos separación. Sitúe cada cruce identificado en un eje común con signo y rotule el contacto. La magnitud describe distancia al contacto pero no el lado. Tampoco una media certifica todos los cruces: una separación grande puede ocultar un valor negativo. Conserve mínimo y recuentos por categoría junto al resumen. Esta tabla determinista no tiene incertidumbre medida; añadir barras de error requeriría otro modelo.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"clearance_mm":[-0.4,0,0.2,0.8]}
minimum=min(clearance); overlap_count=count(c<0); contact_count=count(c==0); mean_absolute=sum(abs(c))/len(c)
```

## Ejercicios corregidos

### Ejercicio 1

Clasifique todas las filas principales respecto al contacto.

<details><summary>Respuesta 1</summary>

Hay `1` fila solapada, `1` en contacto y `2` separadas. Las categorías se derivan de la convención de signo, no de preferencias de color.

</details>

### Ejercicio 2

Calcule el mínimo y la media de separaciones absolutas.

<details><summary>Respuesta 2</summary>

El mínimo es `-0.4 mm` y la media absoluta `0.35 mm`. La segunda cifra por sí sola no identifica un solapamiento.

</details>

### Ejercicio 3

Aplique el control con signo cambiado. ¿Qué estadística oculta la mejora?

<details><summary>Respuesta 3</summary>

El mínimo pasa a `0 mm`, los solapamientos a `0` y la media absoluta sigue en `0.35 mm`. La agregación absoluta oculta el cambio de lado.

</details>

### Ejercicio 4

Especifique una vista que conserve la pregunta sin depender del color.

<details><summary>Respuesta 4</summary>

Use filas identificadas en posiciones con signo, línea de contacto rotulada, valores exactos y estados textuales. El color puede reforzar categorías, pero no ser la única información del signo.

</details>

### Ejercicio 5

¿Un mínimo no negativo demuestra que el tejido móvil no colisiona?

<details><summary>Respuesta 5</summary>

No. Las filas describen una sección fija declarada. Geometría completa, movimiento, tolerancias y cruces no observados necesitan sus propias pruebas.

</details>

## Tarea con consulta de fuentes

Dibuje manualmente los puntos con signo y anote la identidad de escena de cada fila. Compárelos con un resumen de magnitudes y conserve el control. Un solapamiento invisible en una vista supuestamente segura refuta que esa vista apoye la tarea declarada.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: dv-006-position-length-area-comparisons](../../data-visualization/dv-006-position-length-area-comparisons/)
- [Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/crossings.json)
- [Fuente primaria](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Expediente fijo de ejemplos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
