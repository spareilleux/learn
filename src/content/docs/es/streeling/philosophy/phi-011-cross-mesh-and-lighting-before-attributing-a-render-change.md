---
title: Cruzar malla e iluminación antes de atribuir un cambio de renderizado
description: Cruzar malla e iluminación antes de atribuir un cambio de renderizado — Filosofía
sidebar:
  label: PHI-011 · Cruzar malla e iluminación antes de atribuir un cambio de renderizado
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/es/phi-011-cross-mesh-and-lighting-before-attributing-a-render-change.es.md
---

:::note[Streeling University]
**PHI-011** · Cruzar malla e iluminación antes de atribuir un cambio de renderizado · intermedio · 45 minutos

Generado por el departamento *Filosofía* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/es/phi-011-cross-mesh-and-lighting-before-attributing-a-render-change.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHI-007](../../philosophy/phi-007-test-a-learning-gain-against-counterfactuals/)
:::

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Un equipo sustituye la malla de una escultura y cambia la iluminación en la misma comparación. La captura nueva tiene peor residuo y se culpa a la malla. Separamos los cambios mediante una tabla completa elaborada. Ampliamos los contrafactuales a un diseño de factores cruzados y usamos un control con interacción para mostrar cuándo falla un único efecto de malla.

## Leer el límite conservado

El pipeline expone ajustes de captura junto con ajustes geométricos. Los argumentos no aportan una comparación causal controlada. La guía factorial NIST explica el cruce de niveles y las interacciones; nuestra tabla es una construcción inventada, no una experiencia de esa fuente.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

Compare malla antigua y nueva bajo la misma iluminación antes de promediar. Después compare esas diferencias entre iluminaciones. Si difieren, el efecto depende de la iluminación en esta tabla. Una diagonal cambia ambos factores y no aísla ninguno. El cruce completo explicita comparaciones ausentes, pero no establece automáticamente causalidad real. Un futuro ensayo aún necesita cámaras, ajustes, entradas y orden de ejecución controlados, con repetición u otro método justificado de incertidumbre cuando corresponda. El cálculo actual es determinista y no contiene ruido muestreado de renderizado.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"old_flat":6,"old_lit":10,"new_flat":4,"new_lit":8}
mesh_flat=new_flat-old_flat; mesh_lit=new_lit-old_lit; average_mesh=(mesh_flat+mesh_lit)/2; interaction=mesh_lit-mesh_flat; diagonal=new_lit-old_flat
```

## Ejercicios corregidos

### Ejercicio 1

Compare ambas mallas bajo cada iluminación coincidente.

<details><summary>Respuesta 1</summary>

Ambas diferencias de malla son `-2` unidades de residuo. En esta tabla elaborada, la malla nueva mejora el criterio en cada iluminación.

</details>

### Ejercicio 2

¿Qué informa la comparación diagonal y por qué no permite atribuirlo?

<details><summary>Respuesta 2</summary>

El cambio diagonal es `2` unidades. Mezcla cambio de malla e iluminación; no permite atribuir el aumento solo a la malla.

</details>

### Ejercicio 3

Calcule diferencia media de malla e interacción.

<details><summary>Respuesta 3</summary>

La diferencia media es `-2` unidades y la interacción `0`. La igualdad entre estas iluminaciones es una propiedad de la tabla, no una ley universal.

</details>

### Ejercicio 4

Aplique el control de interacción. ¿Qué afirmación sencilla falla?

<details><summary>Respuesta 4</summary>

Las diferencias son `-2` y `2`, su media `0`, la interacción `4` y la diagonal `6`. Falla la mejora independiente de iluminación.

</details>

### Ejercicio 5

¿Demuestra la tabla que una limpieza real causó un mejor renderizado?

<details><summary>Respuesta 5</summary>

No. Los valores son inventados. Enseñan qué comparaciones debe conservar un diseño real; faltan observaciones ejecutadas y sus condiciones controladas.

</details>

## Tarea con consulta de fuentes

Dibuje la tabla cruzada y calcule manualmente los contrastes dentro de cada iluminación. Anote los ajustes del pipeline que habría que fijar en un ensayo futuro. Una iluminación coincidente donde la nueva malla empeore, como en el control, refuta un beneficio incondicional.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: phi-007-test-a-learning-gain-against-counterfactuals](../../philosophy/phi-007-test-a-learning-gain-against-counterfactuals/)
- [Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/glb_pipeline.py)
- [Fuente primaria](https://www.itl.nist.gov/div898/handbook/pri/section3/pri3331.htm)
- [Expediente fijo de ejemplos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
