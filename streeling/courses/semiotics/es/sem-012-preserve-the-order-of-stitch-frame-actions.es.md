---
module_id: sem-012-preserve-the-order-of-stitch-frame-actions
department: semiotics
course: "Conservar el orden de acciones de un marco de bordado"
level: intermediate
prerequisites: ["sem-006-preserve-orientation-across-scene-frames"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar el orden de acciones de un marco de bordado

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Una instrucción pide desplazar y girar un motivo de bordado. Otro autor invierte los verbos porque ambas listas contienen las mismas acciones. El anclaje termina en otro sitio. El orden forma parte del significado: composiciones con los mismos ingredientes pueden producir ubicaciones distintas. Ampliamos el razonamiento de orientación desde nombrar una dirección hasta interpretar una secuencia ordenada de acciones.

## Leer el límite conservado

La utilidad de objetos Atlas admite padre y posición, por lo que un motivo podría situarse en otro marco. No define nuestras instrucciones. La documentación de Godot motiva declarar operaciones locales o relativas al padre en vez de deducir el marco solo por los verbos.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

Use un marco plano fijo y un cuarto de vuelta exacto. La composición de la fórmula aplica primero la acción situada más a la derecha. Trasladar antes de girar rota tanto el desplazamiento como el punto. Girar antes de trasladar añade un desplazamiento alineado con el marco fijo. Es una diferencia semántica, no de precisión numérica. El control de traslación nula muestra por qué una coincidencia no demuestra independencia del orden. Un DSL propuesto debe conservar orden y marco en su interpretación antes de mejorar sintaxis u optimizar acciones.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"point_mm":[1,0],"translation_mm":[1,0],"rotation_deg":90}
R(x,y)=(-y,x); T(p)=p+t; rotate_after_translate=R(T(p)); translate_after_rotate=T(R(p))
```

## Ejercicios corregidos

### Ejercicio 1

Traslade primero y después gire el punto principal.

<details><summary>Respuesta 1</summary>

El resultado es `(0,2) mm`. La traslación queda incluida en el vector girado alrededor del origen fijo.

</details>

### Ejercicio 2

Gire primero y después traslade. ¿Queda igual el anclaje?

<details><summary>Respuesta 2</summary>

El resultado es `(1,1) mm`, distinto del primer orden. Los mismos nombres de acciones no especifican la misma ubicación sin su orden.

</details>

### Ejercicio 3

Aplique la traslación nula a ambas composiciones.

<details><summary>Respuesta 3</summary>

Ambas producen `(0,1) mm`. La coincidencia especial no justifica conmutar la traslación no nula del caso principal.

</details>

### Ejercicio 4

¿Qué información debe sobrevivir al traducir una descripción de escena?

<details><summary>Respuesta 4</summary>

Conserve orden, unidades del punto y desplazamiento, origen de giro, marco del desplazamiento y convención de composición. Los verbos solos dejan el significado incompleto.

</details>

### Ejercicio 5

¿Puede un compilador reordenar estas acciones porque coincidió una vista previa?

<details><summary>Respuesta 5</summary>

No con las entradas principales declaradas. Una optimización válida necesita una condición que demuestre igualdad de resultados interpretados, no una coincidencia con desplazamiento nulo.

</details>

## Tarea con consulta de fuentes

Dibuje ambas trayectorias desde el mismo punto y escriba manualmente las coordenadas intermedias. Identifique el límite de ubicación en Atlas sin editarlo. Los anclajes distintos refutan una regla incondicional de reordenación; proponga equivalencia semántica antes de implementar un compilador.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: sem-006-preserve-orientation-across-scene-frames](../../semiotics/en/sem-006-preserve-orientation-across-scene-frames.md)
- [Artefacto conservado del proyecto](../../../../code/blender/scripts/atlas/kit.py)
- [Fuente primaria](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Expediente fijo de ejemplos](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
