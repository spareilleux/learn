---
title: Acotar el barrido de una bisagra de pliegue
description: Acotar el barrido de una bisagra de pliegue — Física
sidebar:
  label: PHY-016 · Acotar el barrido de una bisagra de pliegue
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/es/phy-016-bound-a-fold-hinge-sweep.es.md
---

:::note[Streeling University]
**PHY-016** · Acotar el barrido de una bisagra de pliegue · intermedio · 45 minutos

Generado por el departamento *Física* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/es/phy-016-bound-a-fold-hinge-sweep.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-013](../../physics/phy-013-check-torque-when-moving-a-scene-pivot/)
:::

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Un panel plegado puede terminar separado de su vecino y atravesarlo durante el movimiento. En una escultura de origami propuesta para Godot, la imagen final responde a una pregunta más limitada que la trayectoria. Esta lección sigue un punto marcado alrededor de una bisagra ideal y distingue la distancia a la bisagra del desplazamiento respecto al inicio. Ninguna de esas cantidades es una deformación del material.

## Leer el límite conservado

La utilidad Atlas conservada declara el sistema de modelado y la relación entre objetos padre e hijo. Una jerarquía de bisagra es una cuestión concreta de integración futura, pero las líneas inspeccionadas no contienen una bisagra de origami ni un ensayo de colisiones.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

Sitúe la bisagra en el origen y el punto marcado sobre X positivo. La rotación conserva el radio mientras modifica las coordenadas finales. La cuerda entre el inicio y el final es menor que el arco salvo en el límite de ángulo nulo. Nuestro margen solo compara radios; no sitúa un obstáculo finito. Un margen radial positivo no demuestra un recorrido libre. La referencia de Godot distingue rotación local y rotación respecto al padre; este cálculo declara su plano independientemente de cualquier recurso importado.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"radius_mm":100,"angle_deg":60,"obstacle_radius_mm":90}
x=r*cos(theta*pi/180); y=r*sin(theta*pi/180); swept_displacement=2*r*sin(abs(theta)*pi/360); radial_margin=r-obstacle_radius
```

## Ejercicios corregidos

### Ejercicio 1

Calcule el extremo del punto marcado. ¿Qué coordenada ha permanecido fija?

<details><summary>Respuesta 1</summary>

El extremo es `(50,86.60254037844386) mm`. Ninguna coordenada queda fija; la bisagra y el radio sí. Declare cualquier redondeo sin modificar la construcción.

</details>

### Ejercicio 2

Calcule el desplazamiento recto desde el inicio y compárelo con el radio.

<details><summary>Respuesta 2</summary>

La cuerda mide `100 mm`, igual al radio de este caso. La igualdad depende del ángulo elegido; no define una rotación.

</details>

### Ejercicio 3

¿Qué demuestra el margen radial sobre un obstáculo cercano?

<details><summary>Respuesta 3</summary>

Vale `10 mm` según la comparación radial. Sin extensión angular ni volumen ocupado, no demuestra que el panel evite el obstáculo.

</details>

### Ejercicio 4

Aplique el control de ángulo nulo. ¿Conservar el radio implica siempre conservar el extremo?

<details><summary>Respuesta 4</summary>

El extremo del control es `(100,0) mm` y su desplazamiento es `0 mm`. El caso principal cambia el extremo aunque conserva ese mismo radio.

</details>

### Ejercicio 5

¿Qué información adicional necesita una entrega de escena para comprobar el recorrido?

<details><summary>Respuesta 5</summary>

Incluya el sistema de bisagra, los volúmenes del panel y del obstáculo, todo el intervalo angular y la convención de contacto. Un punto y una captura final no bastan.

</details>

## Tarea con consulta de fuentes

Dibuje el inicio, el final y el arco antes de abrir las respuestas. Anote una bisagra padre-hijo propuesta en la utilidad Atlas sin editarla. Un obstáculo que corte una posición intermedia con ambos extremos libres refuta el criterio basado solo en los extremos.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: phy-013-check-torque-when-moving-a-scene-pivot](../../physics/phy-013-check-torque-when-moving-a-scene-pivot/)
- [Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Fuente primaria](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Expediente fijo de ejemplos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
