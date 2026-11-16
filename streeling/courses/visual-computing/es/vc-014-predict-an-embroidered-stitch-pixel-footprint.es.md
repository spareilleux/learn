---
module_id: vc-014-predict-an-embroidered-stitch-pixel-footprint
department: visual-computing
course: "Prever la anchura en píxeles de una puntada bordada"
level: intermediate
prerequisites: ["vc-005-craft-details-through-blender-to-godot"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Prever la anchura en píxeles de una puntada bordada

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Un hilo sobrevive a la limpieza de Blender y desaparece en una vista general propuesta para Godot. Conservar geometría y verla en pantalla son cuestiones distintas. Calculamos la anchura proyectada de una puntada antes de elegir geometría o textura. La predicción depende de la cámara; no afirma que una persona reconozca la puntada ni mide un motor de renderizado o un reescalador.

## Leer el límite conservado

El script de limpieza expone un argumento de resolución para sus capturas. No establece un viewport de Godot ni su campo de visión. El modelo siguiente se construye por separado; la referencia de Godot explica proyecciones y selección del eje del campo de visión.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

Combine altura del viewport y campo de visión vertical para expresar la focal en píxeles. Divida anchura física por distancia a la cámara y multiplique por esa focal. Ambas longitudes deben usar la misma unidad. La proyección supone un elemento paralelo al plano de imagen; una puntada inclinada tendría otra anchura. El umbral es una decisión de diseño pendiente de observación. No representa agudeza humana, contraste, sombreado ni estabilidad temporal. Una cámara ortográfica necesita otro modelo porque su tamaño proyectado no disminuye así con la distancia.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"width_m":0.002,"distance_m":1,"viewport_height_px":1000,"vertical_fov_deg":90,"required_px":2}
focal_px=viewport_height_px/(2*tan(vertical_fov_deg*pi/360)); width_px=focal_px*width_m/distance_m; meets_declared_threshold=width_px>=required_px
```

## Ejercicios corregidos

### Ejercicio 1

Calcule la focal en píxeles del caso principal.

<details><summary>Respuesta 1</summary>

La focal es `500 px`. Combinar campo vertical con anchura del viewport respondería a otra pregunta de proyección, generalmente incorrecta.

</details>

### Ejercicio 2

Obtenga la anchura proyectada y compárela con el umbral declarado.

<details><summary>Respuesta 2</summary>

La anchura es `1 px`, inferior al umbral de `2 px`. Solo falla el requisito geométrico elaborado; no se demuestra invisibilidad real.

</details>

### Ejercicio 3

Aplique el control de cámara más cercana sin cambiar la malla.

<details><summary>Respuesta 3</summary>

La anchura pasa a `2 px` y alcanza el umbral declarado. Una misma geometría admite huellas distintas según la distancia de observación.

</details>

### Ejercicio 4

¿Se transfiere esta fórmula sin cambios a una vista ortográfica?

<details><summary>Respuesta 4</summary>

No. La división por distancia corresponde a la perspectiva. El modelo ortográfico necesita el tamaño de vista y su correspondencia con el viewport.

</details>

### Ejercicio 5

¿Alcanzar el umbral demuestra un resultado de DLSS o reconocimiento?

<details><summary>Respuesta 5</summary>

No. No se probó ningún reescalador ni observador. Contraste, muestreo, movimiento y reconocimiento siguen siendo cuestiones separadas para una observación futura.

</details>

## Tarea con consulta de fuentes

Prepare una ficha con anchura física, convención de ejes, distancia, viewport y anchura prevista. Calcule manualmente antes de consultar el expediente. Refute la visibilidad incondicional cambiando solo la distancia; proponga capturas con cámaras coincidentes como prueba futura, no ejecutada.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: vc-005-craft-details-through-blender-to-godot](../../visual-computing/en/vc-005-craft-details-through-blender-to-godot.md)
- [Artefacto conservado del proyecto](../../../../code/blender/scripts/glb_pipeline.py)
- [Fuente primaria](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html)
- [Expediente fijo de ejemplos](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
