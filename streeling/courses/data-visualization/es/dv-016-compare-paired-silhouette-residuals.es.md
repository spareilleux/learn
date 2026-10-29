---
module_id: dv-016-compare-paired-silhouette-residuals
department: data-visualization
course: "Comparar residuos de silueta emparejados"
level: intermediate
prerequisites: ["dv-006-position-length-area-comparisons"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Comparar residuos de silueta emparejados

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Una limpieza reduce el peor residuo de silueta de una escultura y empeora otras vistas. Informar solo la mejora media oculta las vistas afectadas; ordenar las columnas por separado destruye su emparejamiento. Preparamos una comparación antes-después por identidad de cámara. Preguntamos qué vistas cambian, no solo si dos conjuntos tienen medias distintas.

## Leer el límite conservado

El pipeline solicita varios fotogramas de giro y una resolución de captura. Estos argumentos motivan revisar cada vista, pero no contienen residuos de nuestra escultura. Los siguientes valores son píxeles inventados bajo una convención propuesta de comparación.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

Un residuo necesita límite de referencia, definición en imagen y cámara emparejada. Cada escalar es aquí el error declarado para una cámara. Una los valores anteriores y posteriores en una escala común conservando su etiqueta. Un cambio negativo mejora este criterio porque se prefieren residuos menores. La media negativa no implica mejora en todas las vistas. El control reasigna valores sin cambiar su conjunto. Persisten los resúmenes pero cambian las diferencias emparejadas: la identidad de vista es información, no decoración.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"view_ids":["front","side","back"],"before_px":[2,8,2],"after_px":[4,3,4]}
delta_i=after_i-before_i; mean_delta=sum(delta)/len(delta); worst_before=max(before); worst_after=max(after)
```

## Ejercicios corregidos

### Ejercicio 1

Calcule los cambios en el orden dado de cámaras.

<details><summary>Respuesta 1</summary>

Son `[2,-5,2] px`. Frente y dorso empeoran; el lateral mejora. Conserve el orden de cámaras junto al vector.

</details>

### Ejercicio 2

Obtenga el cambio medio y los peores residuos.

<details><summary>Respuesta 2</summary>

El cambio medio es `-1/3 px`; el peor residuo baja de `8 px` a `4 px`. Estos resúmenes coexisten con vistas que empeoran.

</details>

### Ejercicio 3

Aplique el control de valores posteriores reasignados.

<details><summary>Respuesta 3</summary>

Los cambios son `[1,-4,2] px`, mientras la media sigue en `-1/3 px` y los peores residuos en `8 px` y `4 px`. Cambia el emparejamiento sin cambiar los agregados.

</details>

### Ejercicio 4

¿Por qué resulta engañoso ordenar cada columna por separado?

<details><summary>Respuesta 4</summary>

Empareja posiciones estadísticas en vez de cámaras coincidentes. Un segmento podría unir vistas distintas y dejaría de describir el efecto de limpieza de esa vista.

</details>

### Ejercicio 5

¿Un máximo menor demuestra mayor fidelidad artística?

<details><summary>Respuesta 5</summary>

No. El residuo elegido mide una tarea geométrica. Rasgos significativos, materiales, iluminación y juicio artístico requieren criterios adicionales y observaciones reales.

</details>

## Tarea con consulta de fuentes

Dibuje segmentos emparejados con etiquetas y anote cada empeoramiento antes de abrir respuestas. Localice los argumentos de captura y el contrato ausente de imagen de referencia. Un cambio positivo emparejado refuta una supuesta mejora de todas las vistas.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: dv-006-position-length-area-comparisons](../../data-visualization/en/dv-006-position-length-area-comparisons.md)
- [Artefacto conservado del proyecto](../../../../code/blender/scripts/glb_pipeline.py)
- [Fuente primaria](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html)
- [Expediente fijo de ejemplos](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
