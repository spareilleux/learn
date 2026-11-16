---
title: Comprobar el par al desplazar un pivote de escena
description: Comprobar el par al desplazar un pivote de escena — Física
sidebar:
  label: PHY-013 · Comprobar el par al desplazar un pivote de escena
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/es/phy-013-check-torque-when-moving-a-scene-pivot.es.md
---

:::note[Streeling University]
**PHY-013** · Comprobar el par al desplazar un pivote de escena · intermedio · 40 minutos

Generado por el departamento *Física* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/es/phy-013-check-torque-when-moving-a-scene-pivot.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/)
:::

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Un futuro visor de piezas IX desplaza el origen de un objeto manteniendo fijo el panel visible. ¿Se conserva el momento de la carga? Un cambio de coordenadas puede preservar la geometría y cambiar el punto respecto al cual se calcula el par. El marco BRUTAL fijado utiliza metros; no aporta masa, fuerzas aplicadas ni una bisagra física. Esos datos son supuestos explícitos de este ejemplo.

[Requisito previo: phy-005-sheet-thickness-and-scene-units](../../physics/phy-005-sheet-thickness-and-scene-units/)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

La definición de OpenStax utiliza el producto vectorial del desplazamiento desde el origen elegido hasta el punto de aplicación con la fuerza. En este caso plano construido, calcule la componente con signo perpendicular a la página. Desplace el origen de referencia sin mover la fuerza. Esto difiere de trasladar toda la configuración física: ambos puntos se mueven juntos y su diferencia permanece igual. Por ello, el nombre de un pivote no basta para un traspaso mecánico. Registre su posición y aclare si es un origen de modelado o un apoyo real. El registro de orientación motiva marcos explícitos, pero no contiene ningún experimento de fuerzas.

## Caso fijo y supuestos

```text
P=(0.30,0,0) m; O=(0,0,0) m; O2=(0.10,0,0) m
F=(0,-20,0) N
r=P-O; tau=r cross F
tau_z=-6 N*m; tau2_z=-4 N*m
P3=(0.40,0,0) m; O3=(0.10,0,0) m; tau3_z=-6 N*m
```

## Ejercicios resueltos

### Ejercicio 1

Calcule el momento original y su signo.

> **Respuesta:** El brazo es `0.30 m`; el momento vale `-6 N*m`. El signo depende de los ejes declarados y del orden del producto vectorial.

### Ejercicio 2

Mantenga fijo el panel y use el segundo origen. ¿Qué cambia?

> **Respuesta:** El brazo pasa a `0.20 m` y el momento a `-4 N*m`. La fuerza no cambia; cambia su punto de referencia.

### Ejercicio 3

Traslade ambos puntos según el control. ¿Cambia el par?

> **Respuesta:** No: `0.40-0.10=0.30 m`, por lo que resulta `-6 N*m`. Una traslación común conserva el brazo relativo.

### Ejercicio 4

Sitúe el origen en el punto de aplicación. ¿Desaparece la fuerza?

> **Respuesta:** El brazo y el momento son `0`, pero sigue actuando una fuerza de `20 N` hacia abajo. Un momento nulo respecto a ese punto no implica carga nula.

### Ejercicio 5

¿Puede este cálculo certificar una bisagra?

> **Respuesta:** No. Da un momento respecto a puntos declarados. Faltan reacciones de apoyo, resistencia del material y movimiento; no se midió ninguna capacidad de carga.

## Tarea con consulta de fuentes

Con el registro y la definición fijada del marco BRUTAL, prepare un traspaso que distinga un panel fijo de un conjunto trasladado. Recalcule con el origen en el punto de aplicación. Los momentos distintos anteriores refutan que todos los orígenes den el mismo momento.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/orientation-controls.json)
- [Fuente primaria](https://openstax.org/books/university-physics-volume-1/pages/10-6-torque)
- [Expediente de evidencias fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
