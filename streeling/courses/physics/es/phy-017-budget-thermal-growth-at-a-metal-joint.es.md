---
module_id: phy-017-budget-thermal-growth-at-a-metal-joint
department: physics
course: "Prever la dilatación térmica en una junta metálica"
level: intermediate
prerequisites: ["phy-015-bound-clearance-after-thickening-a-panel"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Prever la dilatación térmica en una junta metálica

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Una tira de metal cincelado de una escultura propuesta deja una holgura visible ante un tope fijo. Un agente puede conservarla en la malla y olvidar la temperatura de referencia. Esta lección añade una referencia térmica al prerrequisito de separación estática. Calculamos la dilatación libre con un coeficiente explícitamente inventado y distinguimos una holgura prevista negativa de un fallo medido en una junta real.

## Leer el límite conservado

Atlas establece propiedades metálicas y de rugosidad en una utilidad de materiales. Estos parámetros visuales no identifican la aleación ni su coeficiente de dilatación. La propiedad física ausente debe seguir siendo una entrada didáctica, sin deducirse de un renderizado brillante.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

OpenStax presenta una aproximación lineal de la dilatación. Aquí la longitud corresponde a la temperatura de referencia, el cambio térmico es una diferencia en kelvins y el coeficiente tiene unidades de kelvin inverso. La tira puede crecer libremente hacia un tope inmóvil; quedan excluidas las fuerzas de restricción. Reste la dilatación de la holgura inicial, no una temperatura absoluta. Un material visual puede representar metal sin aportar una ley mecánica. El control cambia únicamente la diferencia térmica y muestra por qué una malla invariable no garantiza una separación invariable bajo otra interpretación física.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"length_mm":200,"alpha_per_K":2e-05,"delta_K":50,"gap_mm":0.3}
growth_mm=alpha_per_K*length_mm*delta_K; remaining_gap_mm=gap_mm-growth_mm
```

## Ejercicios corregidos

### Ejercicio 1

Calcule la dilatación libre. ¿Qué unidades se cancelan?

<details><summary>Respuesta 1</summary>

La dilatación es `0.2 mm`. Los kelvins inversos cancelan los kelvins y queda la unidad de longitud. El coeficiente es una entrada, no una estimación obtenida de la apariencia.

</details>

### Ejercicio 2

¿Qué holgura queda y qué conclusión limitada se obtiene?

<details><summary>Respuesta 2</summary>

La holgura restante es `0.1 mm`. El modelo de crecimiento libre predice separación para estas entradas; no se observó una tira ni un contacto reales.

</details>

### Ejercicio 3

Aplique el control de mayor cambio térmico. ¿Qué significa la holgura negativa?

<details><summary>Respuesta 3</summary>

La dilatación es `0.4 mm` y la holgura restante `-0.1 mm`. La geometría libre invade el tope; el modelo no calcula la tensión producida por la restricción.

</details>

### Ejercicio 4

¿Puede un parámetro metálico del shader sustituir al coeficiente de dilatación?

<details><summary>Respuesta 4</summary>

No. Los parámetros visuales controlan la apariencia. No identifican la aleación, la dependencia térmica, la restricción ni el coeficiente físico necesario.

</details>

### Ejercicio 5

¿Qué refutaría aplicar este modelo a una pieza artesanal concreta?

<details><summary>Respuesta 5</summary>

Una expansión medida fuera del margen declarado, un tope móvil, fuertes gradientes o un crecimiento restringido invalidarían alguna premisa. Conserve la discrepancia en vez de certificar la pieza.

</details>

## Tarea con consulta de fuentes

Prepare una ficha de la junta con temperatura de referencia, longitud, holgura, procedencia del coeficiente y dirección de crecimiento. Use un dibujo manual de antes y después como referencia. Señale los parámetros visuales de Atlas y el campo físico ausente sin editar el código.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: phy-015-bound-clearance-after-thickening-a-panel](../../physics/en/phy-015-bound-clearance-after-thickening-a-panel.md)
- [Artefacto conservado del proyecto](../../../../code/blender/scripts/atlas/kit.py)
- [Fuente primaria](https://openstax.org/books/university-physics-volume-2/pages/1-3-thermal-expansion)
- [Expediente fijo de ejemplos](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
