---
title: Alinear dos periodos de motivos en una costura textil
description: Alinear dos periodos de motivos en una costura textil — Semiótica
sidebar:
  label: SEM-013 · Alinear dos periodos de motivos en una costura textil
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/es/sem-013-align-two-motif-periods-at-a-textile-seam.es.md
---

:::note[Streeling University]
**SEM-013** · Alinear dos periodos de motivos en una costura textil · intermedio · 45 minutos

Generado por el departamento *Semiótica* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/es/sem-013-align-two-motif-periods-at-a-textile-seam.es.md) · [Mi diario](../../journal/)

Requisitos previos: [SEM-008](../../semiotics/sem-008-interpret-layer-order-relative-to-the-reference-normal/)
:::

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Un panel tejido repite el orden de sus cruces mientras una marca bordada sigue otro ciclo. Una unión que alinea solo la marca puede romper el tejido. Componemos dos contratos periódicos en una misma cuadrícula entera. Añadimos una condición de fase para varios motivos más allá de interpretar qué hilo está encima en un cruce aislado.

## Leer el límite conservado

El conjunto conservado declara una variante de paridad global y coordenadas de cuadrícula. Motiva una dirección periódica de los cruces, pero no aporta un ciclo de marcas bordadas. El segundo periodo es una adición didáctica explícita, no una propiedad oculta del conjunto histórico.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

Una copia trasladada conserva la fase de un motivo si el desplazamiento es divisible por su periodo. Para conservar ambos deben anularse ambos restos. Su mínimo común múltiplo proporciona la primera repetición positiva bajo estos supuestos. Distinga periodo y fase: periodos iguales pueden tener orígenes distintos. Aquí ambos parten de fase cero y solo hay traslación. Voltear el tejido, intercambiar urdimbre y trama o reflejar el patrón exigiría otra interpretación. Un borde visualmente parecido no sustituye la igualdad de direcciones cuando la identidad importa para consultar la escena.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"periods_cells":[2,3],"shift_cells":6}
phase_remainders=[shift % p for p in periods]; compatible=all(remainder==0); joint_period=lcm(periods)
```

## Ejercicios corregidos

### Ejercicio 1

Compruebe los restos de ambos motivos para el desplazamiento principal.

<details><summary>Respuesta 1</summary>

Los restos de fase son `[0,0]`, así que se conservan ambas fases declaradas. Es una igualdad de direcciones, no una inspección visual.

</details>

### Ejercicio 2

Obtenga el menor desplazamiento positivo que conserva ambos motivos.

<details><summary>Respuesta 2</summary>

El periodo conjunto es `6` celdas. Cualquier múltiplo común sirve; el menor positivo da la primera repetición con fases iniciales nulas.

</details>

### Ejercicio 3

Aplique el control de desplazamiento más corto.

<details><summary>Respuesta 3</summary>

Los restos son `[1,0]`: coincide el ciclo de marcas pero falla el otro. La compatibilidad es falsa aunque un motivo sí coincida.

</details>

### Ejercicio 4

¿Declarar solo los periodos identifica completamente una costura?

<details><summary>Respuesta 4</summary>

No. También hacen falta orígenes o desfases, direcciones de cuadrícula y transformación de unión. Este cálculo supone fases iniciales nulas.

</details>

### Ejercicio 5

¿La condición modular certifica un tejido o textura sin costura visible?

<details><summary>Respuesta 5</summary>

No. Solo comprueba fases discretas declaradas. Geometría, grosor, muestreo, continuidad material y fabricación son requisitos separados.

</details>

## Tarea con consulta de fuentes

Dibuje ambos ciclos en una tira numerada y compruebe los desplazamientos manualmente. Identifique las direcciones del conjunto y marque como elaborado el ciclo bordado añadido. Una unión que alinea un solo ciclo refuta una regla incondicional basada en un único motivo.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: sem-008-interpret-layer-order-relative-to-the-reference-normal](../../semiotics/sem-008-interpret-layer-order-relative-to-the-reference-normal/)
- [Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/crossings.json)
- [Fuente primaria](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Expediente fijo de ejemplos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
