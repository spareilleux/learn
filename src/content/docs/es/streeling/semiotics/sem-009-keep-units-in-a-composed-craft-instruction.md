---
title: Conservar las unidades en una instrucción artesanal compuesta
description: Conservar las unidades en una instrucción artesanal compuesta — Semiótica
sidebar:
  label: SEM-009 · Conservar las unidades en una instrucción artesanal compuesta
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/es/sem-009-keep-units-in-a-composed-craft-instruction.es.md
---

:::note[Streeling University]
**SEM-009** · Conservar las unidades en una instrucción artesanal compuesta · intermedio · 40 minutos

Generado por el departamento *Semiótica* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/es/sem-009-keep-units-in-a-composed-craft-instruction.es.md) · [Mi diario](../../journal/)

Requisitos previos: [SEM-007](../../semiotics/sem-007-preserve-the-meaning-of-a-bend-angle/), [PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/)
:::

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Una instrucción artesanal suma un desplazamiento de lámina en milímetros a una posición BRUTAL en metros. La sintaxis acepta números, pero ¿se refieren las instrucciones compuestas a la misma longitud? El requisito previo distinguía significados angulares. Aquí construimos un balance dimensional: cada operando conserva magnitud, unidad y marco antes de sumar. Es una nota consultiva, no un analizador ni un DSL nuevo.

[Requisito previo: sem-007-preserve-the-meaning-of-a-bend-angle](../../semiotics/sem-007-preserve-the-meaning-of-a-bend-angle/); [Requisito previo: phy-005-sheet-thickness-and-scene-units](../../physics/phy-005-sheet-thickness-and-scene-units/)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

Sumar exige magnitudes representadas en unidades compatibles y en el mismo marco. Convierta el desplazamiento físico antes de sumar su representación numérica. Un factor adimensional multiplica una longitud; el producto de dos longitudes tiene unidades de área y no puede seguir siendo un desplazamiento sin explicación. Marcos distintos también exigen una correspondencia aunque ambos usen metros. La fuente define ejes y orden de matrices, pero no infiere la escala externa de la lámina. Manténgala como premisa y compruebe mediante una conversión de ida y vuelta. Un desplazamiento nulo es un control débil: oculta una conversión omitida.

## Caso fijo y supuestos

```text
base=0.20 m; offset=30 mm; mm_to_m=0.001 m/mm
offset_m=30*0.001=0.03 m
composed=0.20+0.03=0.23 m
wrong=0.20+30=30.20
roundtrip=0.23*1000=230 mm
scale=2; scaled_offset=2*0.03=0.06 m
control_offset=0 mm; control_composed=0.20 m
```

## Ejercicios resueltos

### Ejercicio 1

Componga correctamente ambas longitudes.

> **Respuesta:** Convierta `30 mm` a `0.03 m` y sume para obtener `0.23 m`. La suma numérica directa no realiza esa conversión.

### Ejercicio 2

¿Por qué falla la suma directa como instrucción física?

> **Respuesta:** El número `30.20` mezcla representaciones. Etiquetarlo en metros implicaría un desplazamiento `1000` veces mayor; la etiqueta no corrige la operación.

### Ejercicio 3

Compruebe el resultado por la ruta en milímetros.

> **Respuesta:** La base es `200 mm`, por tanto `200+30=230 mm`, de acuerdo con `0.23 m`. Ambas rutas comparten unidades y marco declarados.

### Ejercicio 4

Escale el desplazamiento y examine el control nulo.

> **Respuesta:** El desplazamiento escalado es `0.06 m`. Con desplazamiento nulo ambas sumas pueden dar `0.20`; ese único control no detectaría el error de unidad.

### Ejercicio 5

¿Bastan etiquetas de unidad iguales entre marcos distintos?

> **Respuesta:** No. Un desplazamiento también necesita marco y dirección declarados. La convención en metros no establece una correspondencia lámina-escena ni un adaptador ejecutado.

## Tarea con consulta de fuentes

Lea el marco fijado y el registro de composición. Anote una instrucción propuesta con magnitud, unidad y marco en cada límite. Compare la composición asistida con la conversión manual en milímetros. Una discrepancia no nula refuta que la sintaxis numérica conserve el significado.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json)
- [Fuente primaria](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs)
- [Expediente de evidencias fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
