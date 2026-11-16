---
module_id: dv-015-map-missing-stitches-without-inventing-holes
department: data-visualization
course: "Mapear puntadas sin observar sin inventar agujeros"
level: intermediate
prerequisites: ["dv-010-show-pitch-errors-and-missing-estimates"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Mapear puntadas sin observar sin inventar agujeros

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Un mapa de inspección de bordado deja una celda vacía donde no existe observación. Quien prepara la escena interpreta el vacío como agujero y elimina geometría. Distinguimos ausencia observada y ubicación sin observar, conservando identidad espacial y denominador. Transferimos la distinción del prerrequisito desde una señal temporal a una superficie artesanal propuesta sin presentar una imagen como inspección física.

## Leer el límite conservado

El conjunto conservado asigna identidad y coordenadas de cuadrícula a cada cruce. Esos campos aportan una dirección espacial explícita. Sus booleanos describen el orden del tejido, no presencia de puntadas; nuestra tabla separada no debe sustituir su significado.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

Use una tabla por filas con tres estados. Verdadero significa puntada observada, falso ausencia observada y nulo ubicación sin observar. Marque los lugares sin observar y añada una leyenda textual; el fondo no debe implicar vacío físico. Muestre ausencia observada y cobertura. La máscara de observación forma parte de los datos, no es una decoración descartable. Un grupo de sitios ausentes tampoco demuestra un desgarro continuo entre ellos: no se ha modelado ni muestreado el material intermedio.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"grid_width":3,"grid_height":2,"observed_stitch":[true,false,null,true,false,true]}
observed=count(v is not null); present=count(v is true); absent=count(v is false); missing=total-observed; observed_absence_fraction=absent/observed
```

## Ejercicios corregidos

### Ejercicio 1

Cuente sitios presentes, ausentes y sin observar.

<details><summary>Respuesta 1</summary>

Hay `3` presentes, `2` ausencias observadas y `1` sitio sin observar. El total observado es `5` y la cuadrícula contiene `6` sitios.

</details>

### Ejercicio 2

Calcule la fracción de ausencias observadas. ¿Qué población describe?

<details><summary>Respuesta 2</summary>

Es `0.4` sobre `5` sitios observados. Describe ese subconjunto, sin justificar una estimación para todas las ubicaciones de un tejido real.

</details>

### Ejercicio 3

Aplique el control que sustituye el nulo por falso.

<details><summary>Respuesta 3</summary>

Las observaciones pasan a `6`, las ausencias a `3`, los nulos a `0` y la fracción a `0.5`. La sustitución inventa una observación.

</details>

### Ejercicio 4

¿Cómo debe la leyenda distinguir las dos clases de vacío?

<details><summary>Respuesta 4</summary>

Use estados textuales y marcas distintas para ausencia observada y ubicación sin observar. Un fondo transparente no distingue una medición ausente de un agujero real.

</details>

### Ejercicio 5

¿Puede la cuadrícula certificar un desgarro físico continuo?

<details><summary>Respuesta 5</summary>

No. Los estados separados no definen material intermedio ni conectividad. Se necesita geometría o inspección adicional antes de eliminar una superficie continua.

</details>

## Tarea con consulta de fuentes

Dibuje la cuadrícula, rotule la máscara y reproduzca los denominadores manualmente. Señale los campos de dirección del conjunto y explique por qué su booleano de orden no indica presencia. Una vista que convierta el sitio sin observar en ausencia confirmada refuta conservar ese límite.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: dv-010-show-pitch-errors-and-missing-estimates](../../data-visualization/en/dv-010-show-pitch-errors-and-missing-estimates.md)
- [Artefacto conservado del proyecto](../../../../code/streeling/evidence/weave-scene-2026-10-22/crossings.json)
- [Fuente primaria](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html)
- [Expediente fijo de ejemplos](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
