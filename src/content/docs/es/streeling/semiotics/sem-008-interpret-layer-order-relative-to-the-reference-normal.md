---
title: Interpretar el orden de capas respecto a la normal de referencia
description: Interpretar el orden de capas respecto a la normal de referencia — Semiótica
sidebar:
  label: SEM-008 · Interpretar el orden de capas respecto a la normal de referencia
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/es/sem-008-interpret-layer-order-relative-to-the-reference-normal.es.md
---

:::note[Streeling University]
**SEM-008** · Interpretar el orden de capas respecto a la normal de referencia · intermedio · 40 minutos

Generado por el departamento *Semiótica* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/es/sem-008-interpret-layer-order-relative-to-the-reference-normal.es.md) · [Mi diario](../../journal/)

Requisitos previos: [SEM-004](../../semiotics/sem-004-face-identity-under-reindexing/), [SEM-006](../../semiotics/sem-006-preserve-orientation-across-scene-frames/)
:::

> **Alcance del borrador.** Tablas didácticas de signos y lectura de código FOLD/IX fijado a una revisión. No se ejecutaron un adaptador nuevo, una transformación de escena ni una prueba nativa. Quedan pendientes las revisiones humanas técnica, artesanal, lingüística y de estudiantes; la verificación del HTML desplegado del curso es separada.

## La pregunta del proyecto

¿Puede un agente traducir «encima» a un signo de orden de capas sin conservar la normal de referencia? [SEM-004](../../semiotics/sem-004-face-identity-under-reindexing/) conserva identidad de caras al cambiar índices; [SEM-006](../../semiotics/sem-006-preserve-orientation-across-scene-frames/) sigue orientación entre marcos. Esta lección deriva otra regla: el significado del signo depende de qué cara aporta la normal de referencia.

La [especificación FOLD de la revisión fijada](https://github.com/edemaine/fold/blob/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md#L346-L377), etiquetada como borrador preliminar de versión 1.2, define `[f,g,s]` respecto a la normal de la segunda cara. Para `s=+1`, la cara `f` está en el lado al que apunta la normal de la cara `g`. Para `s=-1`, está en el lado opuesto. No es un indicador de altura absoluta del mundo.

## 1. Convertir a una dirección global declarada

Para un ejemplo didáctico de capas planas, sea `d` +1 cuando `f` está encima de `g` respecto a un eje global hacia arriba elegido y -1 en caso contrario. Sean `sigma_f` y `sigma_g` los signos de las normales de caras respecto a ese mismo eje. Ambos deben ser conocidos y no nulos en este ejemplo simplificado. El signo relativo es `s=d*sigma_g`, así que `d=s*sigma_g`.

### Ejercicio 1: identificar la cara de referencia

Para `[2,5,+1]`, determina el orden global cuando la normal de la cara 5 apunta arriba y cuando apunta abajo. ¿Qué cara aporta la normal?

> **Respuesta:** La cara 5 aporta la normal de referencia. Con `sigma_g=+1`, el orden global es `d=+1`; con `sigma_g=-1`, es `d=-1`. La misma relación positiva puede significar órdenes globales opuestos. Las posiciones de argumentos y la dirección de referencia son información necesaria.

## 2. Intercambiar argumentos no siempre niega el signo

Escribe la relación intercambiada como `[g,f,t]`. Su orden global es `-d`, medido ahora frente a la normal de la otra cara. Por tanto, `t=-d*sigma_f=-s*sigma_f*sigma_g`. Direcciones de normales iguales requieren signo opuesto; normales opuestas requieren el mismo signo. Concuerda con la regla de intercambio de ternas de la especificación.

### Ejercicio 2: intercambiar una relación concreta

Usa `[2,5,+1]`, `sigma_g=-1` y `sigma_f=+1`. Halla `d` y el signo intercambiado. Indica después qué ocurre si ambas normales tienen en cambio signos iguales.

> **Respuesta:** El orden global es `d=-1`; el signo intercambiado es `t=+1`, dando `[5,2,+1]`. Las normales opuestas explican que no cambie el signo. Con signos de normales iguales, el signo intercambiado sería en cambio `t=-1`. Negar a ciegas en cada intercambio de argumentos es incorrecto.

## 3. Voltear el objeto completo

Al voltear todo el objeto respecto al mismo eje global hacia arriba, se invierten el orden global y ambos signos de normales. En consecuencia, `s'=(-d)*(-sigma_g)=s`: el signo relativo almacenado no cambia. Esta operación difiere de sustituir la etiqueta de un argumento o cambiar la definición de «arriba».

Los [controles de IX de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/controls.rs#L82-L107) implementan un movimiento plano por separado del volteo. El volteo niega las coordenadas plegadas del eje y mientras conserva las ternas brutas de orden de caras; sus comentarios explican la inversión conjunta de orientación y arriba. Es evidencia del código, no una ejecución nueva ni una correspondencia universal con el eje vertical de una escena anfitriona.

### Ejercicio 3: rechazar una inversión general de signos

Empieza con `d=+1`, `sigma_g=+1` y `s=+1`. Voltea el modelo completo. Si un adaptador también niega el signo almacenado, ¿qué orden global implicaría?

> **Respuesta:** Los nuevos valores correctos son `d'=-1`, `sigma_g'=-1` y `s'=+1` sin cambios. Almacenar incorrectamente `s'=-1` implicaría `d'=s'*sigma_g'=+1`, contradiciendo el volteo previsto. La geometría y sus normales de referencia deben interpretarse juntas.

## 4. Distinguir cambios de bits iguales de acciones iguales

Para un cruce de tejido, un indicador basado en roles `warp_over` pregunta si la hebra actualmente llamada urdimbre está más alta en la dirección de escena elegida. Recolorear no cambia ni rol ni orden. Renombrar urdimbre y trama complementa el indicador mientras deja la antigua hebra física de urdimbre a la misma altura. Voltear todo el objeto manteniendo nombres de roles también complementa el indicador, pero invierte la relación global de altura de esa antigua hebra.

El [registro didáctico de relaciones](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-material-2026-10-22/layer-relations.json) conserva 8 combinaciones de signos y fichas separadas de cruces para `w2-f0` y `w3-f0`. Son ejemplos semánticos finitos, no ediciones reales de la escena guardada. Un indicador de rol y una terna FOLD relativa a la normal responden a preguntas distintas.

### Ejercicio 4: distinguir tres ediciones

Un cruce tiene inicialmente urdimbre encima de trama. Compara recolorear, intercambiar nombres de roles y voltear el objeto completo. ¿Puede un booleano complementado identificar qué operación ocurrió?

> **Respuesta:** Recolorear deja sin cambios indicador y orden físico. Intercambiar nombres de roles complementa el indicador, pero conserva la altura de la antigua urdimbre física. Voltear todo el objeto manteniendo nombres complementa el indicador e invierte esa relación de altura. Un booleano complementado por sí solo no identifica la operación; conserva identidades de hebras, asignación de roles, marco y procedencia de transformación.

## 5. Conservar orden desconocido y alcance del código

En la especificación fijada, `s=0` significa orden desconocido; una pareja omitida también es desconocida. Ninguno significa altura igual ni ausencia confirmada de intersección. El [módulo de capas de IX de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/layers.rs#L1-L16) comprueba relaciones de capas suministradas; no calcula un orden completo. Por tanto, una comprobación aceptada no puede completar toda relación ausente.

### Ejercicio 5: preparar un traspaso con acceso a las fuentes

Lee la especificación y los controles y módulo de IX. Un agente emite «la cara 2 está encima de la cara 5» a partir de una relación omitida y después propone un DSL nuevo. ¿Cuál es la corrección útil más pequeña y qué pruebas siguen faltando?

> **Respuesta:** Mantén desconocido el orden. Para una relación conocida, conserva revisión del código, identidad de caras, roles ordenados de argumentos, definición del signo, información pertinente de normales y marco y cualquier transformación. Un registro tipado con un validador basado en tablas puede bastar; un DSL nuevo necesita una ventaja demostrada. Las comprobaciones seleccionadas no infieren orden ausente ni establecen realizabilidad física. Aquí no se entregaron un adaptador ni una nueva verificación nativa.
