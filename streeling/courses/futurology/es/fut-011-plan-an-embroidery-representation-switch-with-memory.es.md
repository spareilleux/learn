---
module_id: fut-011-plan-an-embroidery-representation-switch-with-memory
department: futurology
course: "Planear un cambio de representación de bordado con memoria"
level: intermediate
prerequisites: ["fut-005-value-a-renderer-pilot-before-running-it","cyb-005-stop-render-policy-flapping"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Planear un cambio de representación de bordado con memoria

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

El curso anterior CYB005 ya enseña histéresis, persistencia, tiempo de permanencia y comparación con una regla sin memoria. Repetir la idea en un visor de bordado solo sirve de referencia. Añadimos otra pregunta: si la huella proyectada de una puntada se expresa como intervalo, ¿qué transiciones están forzadas y qué estados de la regla de anchura exacta siguen siendo posibles? La operación nueva propaga conjuntos de estados admisibles en vez de ocultar la incertidumbre en el punto medio.

## Leer el límite conservado

El argumento de resolución del pipeline no proporciona estos intervalos ni cambios de representación. Godot4.5 documenta histéresis mediante márgenes de distancia. Nuestros intervalos son conjuntos admisibles de píxeles elaborados para una vista propuesta, no límites medidos, distribuciones ni intervalos de confianza calibrados. El curso compañero VC014 calcula una huella puntual con una cámara declarada; es lectura opcional y no un prerrequisito anterior.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

Separe tres interpretaciones. Primero reproduzca las anchuras puntuales suministradas, incluidas en sus intervalos pero no necesariamente situadas en sus puntos medios mediante la regla anterior de histéresis de anchura exacta. Después defina una política conservadora: desde textura, entre en malla solo si todo el intervalo cerrado alcanza o supera la entrada; desde malla, salga solo si el extremo superior queda estrictamente por debajo de la salida; en otro caso conserve el estado. Esta elección de política no revela el estado real de la regla de anchura exacta desconocida.

Por último, parta del estado inicial declarado y propague todos los estados alcanzables. Desde textura, malla es posible si el extremo superior alcanza la entrada y textura sigue siendo posible si el inferior queda por debajo. Desde malla, textura es posible si el extremo inferior queda por debajo de la salida y malla sigue siendo posible si el superior la alcanza. Una los resultados de todos los estados anteriores. Un intervalo que atraviesa un umbral puede crear dos posibilidades; intervalos posteriores dentro de la banda pueden conservar ambas. No propague solo el estado conservador ni sustituya silenciosamente un intervalo por su punto medio. Extremos cerrados y salida estricta determinan las igualdades. Los conjuntos admisibles son independientes por muestra, sin restricción oculta de velocidad de variación.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"widths_px":[2.5,1.9,2.1,1.8,1.1,1.4,2.5],"enter_mesh_px":2.4,"exit_mesh_px":1.2,"initial_mesh":false,"width_intervals_px":[[2.3,2.5],[1.8,2],[2,2.2],[1.7,1.9],[1.1,1.3],[1.3,1.5],[2.4,2.6]]}
Start state=initial_mesh; if state is false and width>=enter_mesh set true; else if state is true and width<exit_mesh set false; emit state; count transitions including from initial state; for closed interval[lo,hi], robust false->true only if lo>=enter, true->false only if hi<exit, otherwise retain; separately propagate reachable states from initial state: from false include true if hi>=enter and false if lo<enter; from true include false if lo<exit and true if hi>=exit; union across preceding reachable states; sort false before true; ambiguous sample numbers are1-based
```

El control conserva los mismos intervalos y anchuras puntuales suministradas, fijando ambos umbrales en `2 px`.

## Ejercicios corregidos

### Ejercicio 1

Reproduzca las anchuras puntuales suministradas con umbrales separados y coincidentes. ¿Qué parte ya enseña CYB005?

<details><summary>Respuesta 1</summary>

Las secuencias de anchuras puntuales suministradas son `[true,true,true,true,false,false,true]` con `3` cambios y `[true,false,true,false,false,false,true]` con `5` cambios. Histéresis, estado retenido y comparación sin memoria proceden de CYB005; esta reproducción es una referencia, no el resultado nuevo.

</details>

### Ejercicio 2

Aplique la política conservadora a los intervalos con umbrales separados. Cuente cambios desde el estado inicial declarado.

<details><summary>Respuesta 2</summary>

La secuencia conservadora es `[false,false,false,false,false,false,true]`, con `1` cambio. El primer intervalo atraviesa la entrada y no la fuerza; en la muestra7 el extremo inferior alcanza la entrada y sí la fuerza. El extremo superior debe quedar estrictamente bajo la salida para forzar el abandono.

</details>

### Ejercicio 3

Propague todos los estados compatibles con los umbrales separados y los intervalos. ¿Una observación dentro de la banda elimina la ambigüedad anterior?

<details><summary>Respuesta 3</summary>

Los estados posibles son `[false,true]` en las muestras `1,2,3,4,5,6` y después `[true]` en la muestra7. La ambigüedad del primer intervalo persiste dentro de la banda. Se propagan ambos estados anteriores en vez de decidir por el punto medio o solo por el estado conservador.

</details>

### Ejercicio 4

Aplique el control de umbrales coincidentes a ambas interpretaciones por intervalos. Explique la igualdad en la muestra2.

<details><summary>Respuesta 4</summary>

La secuencia conservadora del control es `[true,true,true,false,false,false,true]`, con `3` cambios. Los conjuntos alcanzables son `[[true],[false,true],[true],[false],[false],[false],[true]]`; solo la muestra2 es ambigua. Ese intervalo alcanza `2 px`, igual a la salida: salir exige un valor estrictamente inferior; la igualdad conserva malla.

</details>

### Ejercicio 5

¿La coincidencia de las trayectorias puntuales, menos cambios conservadores o menos estados alcanzables autorizan la política?

<details><summary>Respuesta 5</summary>

No. Son conjuntos admisibles elaborados, no incertidumbre medida ni confianza calibrada. La regla conservadora es otra política, no el estado conocido de la regla de anchura exacta. Reconocimiento, transiciones visibles, coste, validez de intervalos y correspondencia con el anfitrión siguen sin probarse. Godot4.5 documenta márgenes de distancia; nuestros intervalos de píxeles no los configuran.

</details>

## Tarea con consulta de fuentes

Antes de abrir respuestas, dibuje los siete intervalos cerrados y dos tablas distintas: política conservadora de estado único y todos los estados alcanzables de la regla de anchura exacta. Conserve ambas ramas dentro de la banda, compare el control y nombre una medición futura que refutaría la cobertura supuesta. Cite CYB005 y el compañero opcional VC014; no se configura un motor ni se afirma un ensayo de reconocimiento.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: fut-005-value-a-renderer-pilot-before-running-it](../../futurology/en/fut-005-value-a-renderer-pilot-before-running-it.md)
- [Prerrequisito: cyb-005-stop-render-policy-flapping](../../cybernetics/en/cyb-005-stop-render-policy-flapping.md)
- [Compañero opcional: vc-014-predict-an-embroidered-stitch-pixel-footprint](../../visual-computing/en/vc-014-predict-an-embroidered-stitch-pixel-footprint.md)
- [Artefacto conservado del proyecto](../../../../code/blender/scripts/glb_pipeline.py)
- [Fuente primaria](https://docs.godotengine.org/en/4.5/tutorials/3d/visibility_ranges.html)
- [Expediente fijo de ejemplos](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
