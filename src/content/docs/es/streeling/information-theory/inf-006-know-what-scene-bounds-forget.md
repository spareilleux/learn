---
title: Comprender qué olvidan los límites de una escena
description: Comprender qué olvidan los límites de una escena — Teoría de la información
sidebar:
  label: INF-006 · Comprender qué olvidan los límites de una escena
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/es/inf-006-know-what-scene-bounds-forget.es.md
---

:::note[Streeling University]
**INF-006** · Comprender qué olvidan los límites de una escena · intermedio · 40 minutos

Generado por el departamento *Teoría de la información* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/es/inf-006-know-what-scene-bounds-forget.es.md) · [Mi diario](../../journal/)

Requisitos previos: [INF-004](../../information-theory/inf-004-information-loss-in-agent-handoffs/), [VC-009](../../visual-computing/vc-009-budget-brutal-scene-expansion/)
:::

> **Alcance del borrador.** Nuevas llamadas de validación y cálculo de límites en CPU sobre borradores BRUTAL creados para el ejercicio, junto con cálculos exactos de geometría ideal y una distribución previa finita. Siguen pendientes las revisiones humanas técnica, lingüística y pedagógica, así como la verificación del HTML del curso desplegado. No se ejecutó ningún renderizador, motor de colisiones, adaptador Blender/Godot ni GPU.

## La pregunta del proyecto

Un agente recibe dos cajas de escena y una caja envolvente alineada con los ejes, y después afirma que la escena no ha cambiado. El resumen puede bastar para encuadrar una vista previa, pero no determina toda la geometría interior. Esta lección concreta la información perdida antes de decidir qué deben intercambiar los agentes.

El [modelo Scene de BRUTAL en la revisión inspeccionada](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs#L236-L257) transforma las ocho esquinas de cada caja local y obtiene sus mínimos y máximos por componentes. Sus cajas se apoyan en el suelo: X/Z abarcan la mitad de la dimensión a cada lado, e Y va desde cero hasta la altura. [VC-009](../../visual-computing/vc-009-budget-brutal-scene-expansion/) explica el presupuesto independiente de cajas. Aquí, igualar el presupuesto y los límites ocultará deliberadamente una diferencia geométrica.

## 1. Encontrar todos los extremos transformados

Para la guiñada del hijo de 45 grados bajo una escala del padre de `(2,1,1)` creada para el ejercicio, una caja unitaria apoyada en el suelo tiene mínimo agregado `(-sqrt2,0,-1/sqrt2)` y máximo `(sqrt2,1,1/sqrt2)`. Los [casos nativos realmente ejecutados](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/native-cases.json) conservan los límites en float32. Un cálculo exacto independiente y una fórmula basada en los valores absolutos de las componentes de la base coinciden dentro de la tolerancia declarada `1e-5`.

Transformar únicamente los extremos locales opuestos `(-0.5,0,-0.5)` y `(0.5,1,0.5)` daría, en cambio, Z igual a cero en aritmética exacta y omitiría los extremos de las otras esquinas. Una aplicación afín no tiene por qué conservar qué esquina maximiza una coordenada. La [comparación de límites](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/bounds-comparison.json) conserva este atajo fallido. Estas afirmaciones se refieren a cajas sometidas a transformaciones afines, no a una perspectiva general ni a una deformación no lineal.

### Ejercicio práctico 1: rechazar el atajo de dos esquinas

¿Qué intervalo Z debe tener la caja transformada completa y qué intervalo informa el atajo de extremos opuestos? ¿Por qué este último no es un límite conservador?

> **Respuesta:** El intervalo Z exacto completo va desde `-1/sqrt2` hasta `1/sqrt2`; el atajo solo da cero. Excluye esquinas realmente transformadas y, por tanto, no puede envolver esta caja de forma segura. Transformar las ocho esquinas, o usar una fórmula equivalente válida para cajas afines, resuelve este caso; comprobar dos extremos no basta.

## 2. Construir dos escenas con un resumen compartido

Usa orientación identidad y metros para este ejemplo didáctico de dos escenas:

| Escena | Dimensiones de las cajas | Traslaciones X | Traslación Y/Z |
| --- | --- | --- | --- |
| A | `(1,2,2)` para cada caja | -0.5 y 0.5 | 0 para ambos ejes |
| B | `(0.2,2,2)` para cada caja | -0.9 y 0.9 | 0 para ambos ejes |

El validador público real acepta ambos borradores didácticos, y las propiedades nativas de Scene devuelven un número de cajas de 2 y los mismos límites: mínimo `(-1,0,-1)`, máximo `(1,2,1)`. La escena A llena esa caja con dos mitades que se tocan. La escena B deja un hueco interior entre unas losas laterales delgadas. El [registro del contraejemplo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/summary-counterexample.json) separa las observaciones nativas de la geometría decimal ideal exacta. No se afirma que las dimensiones representadas en float32 tengan volúmenes racionales exactos.

### Ejercicio práctico 2: recuperar lo que omite el resumen

Calcula el volumen ideal de la unión de cada escena y el volumen de la caja envolvente compartida. ¿La igualdad del número de cajas y los límites demuestra igualdad de geometría o una colisión de hashes de escena?

> **Respuesta:** La escena A tiene volumen `2*1*2*2=8`; B tiene `2*0.2*2*2=1.6`, o `8/5`. El volumen de la caja envolvente compartida es `2*2*2=8`. Por tanto, el mismo resumen de número y límites no determina el interior. No se afirmó ni se midió igualdad o colisión de hashes de las escenas completas.

## 3. Un límite puede descartar un candidato sin demostrar contacto

Usa cajas cerradas para estas pruebas didácticas de pertenencia. El centro `(0,1,0)` pertenece a la unión A en el límite compartido de las mitades y está fuera de B, aunque ambas cajas envolventes agregadas lo incluyen. El control exterior `(1.2,1,0)` está fuera de ambas. Son comprobaciones de pertenencia de puntos a estas uniones de cajas creadas para el ejercicio, no una prueba de colisiones de producción ejecutada.

Cuando dos límites agregados son disjuntos en el mismo sistema de referencia y unidades declarados, la geometría que contienen no puede solaparse. La implicación inversa no se cumple: unos límites solapados pueden contener geometría separada. Las convenciones sobre los límites también importan para el contacto exacto. Un candidato de la fase amplia justifica una comprobación más precisa; no es una colisión confirmada ni una garantía de holgura de fabricación.

### Ejercicio práctico 3: interpretar un resultado positivo de fase amplia

Un agente usa únicamente el límite agregado de B para afirmar que hay material en el centro. Da el contraejemplo y una conclusión útil que el mismo límite todavía permite sostener.

> **Respuesta:** Las losas laterales de B dejan vacío el centro `(0,1,0)`, aunque su límite agregado incluye ese punto. El límite permite descartar `(1.2,1,0)` como exterior a toda la geometría contenida. Una prueba positiva solo sobre el límite agregado no puede demostrar ocupación de material, contacto superficial ni holgura física.

## 4. Cuantificar la pérdida bajo una distribución previa declarada

Para un ejemplo de teoría de la información deliberadamente pequeño, supongamos que A y B son las únicas alternativas, cada una con probabilidad 0.5. La entropía inicial de la elección de escena es 1 bit. El mensaje contiene solo el número 2 y los límites compartidos. Ambas alternativas producen ese mensaje, así que la entropía condicional de la elección de escena sigue siendo 1 bit y la información mutua sobre la elección es 0 bits.

Añade el resultado declarado de pertenencia del centro. Es verdadero para A y falso para B, por lo que bajo esta distribución previa de dos alternativas identifica la escena: la entropía condicional pasa a 0 y la información mutua pasa a 1 bit. Esto no significa que un bit identifique cualquier escena ni que los límites carezcan de valor para otra tarea. Las alternativas y la distribución previa definen el cálculo.

### Ejercicio práctico 4: formular con precisión la afirmación informativa

Calcula la entropía inicial, la entropía condicional tras el resumen compartido y la información mutua. ¿Cómo cambian estos valores tras la prueba del centro y qué supuesto impide generalizar el resultado a todas las escenas?

> **Respuesta:** Inicialmente hay 1 bit; después del resumen compartido hay 1 bit de entropía condicional y 0 bits de información mutua. Añadir el resultado del centro da 0 bits condicionales y 1 bit de información mutua. Esos valores dependen de exactamente dos alternativas equiprobables con las respuestas deterministas indicadas. No son una entropía general de escenas, una relación de compresión medida ni una codificación universal de un bit.

## 5. Elegir un mensaje para la decisión real

Para encuadrar una cámara, el límite común puede bastar. Para la ocupación de material, el destinatario necesita la geometría adecuada o el resultado justificado de una consulta. Para el sombreado o la interpretación de lados, [PHY-008](../../physics/phy-008-keep-surface-normals-perpendicular/) y [SEM-006](../../semiotics/sem-006-preserve-orientation-across-scene-frames/) identifican otras distinciones que faltan. Un resumen debe declarar qué pregunta puede responder y conservar el contexto de origen, sistema de referencia y unidades.

La principal objeción a enviar siempre la geometría completa es su coste de transferencia e inspección. Una alternativa más sencilla es un resumen acotado a la tarea junto con una forma de solicitar más pruebas. Nuestra prueba del centro basta para la elección didáctica; no es un protocolo general de consultas implementado. [INF-004](../../information-theory/inf-004-information-loss-in-agent-handoffs/) explica por qué una transferencia económica debe seguir conservando las distinciones que necesita su destinatario.

### Ejercicio práctico 5: diseñar una transferencia suficiente

El destinatario necesita primero encuadrar una cámara y luego pregunta si hay material en el centro. ¿Qué debe conservar o añadir el agente en cada paso? Formula un criterio que permita rechazar el resumen propuesto para una nueva tarea.

> **Respuesta:** Conserva el límite con su sistema de referencia, unidades y contexto de origen para el encuadre. Añade el resultado de pertenencia del centro con alcance explícito y su fundamento geométrico para la pregunta posterior, o proporciona la geometría pertinente para una prueba precisa real. Rechaza el resumen como suficiente cuando dos escenas admisibles producen el mismo mensaje pero requieren respuestas diferentes a la tarea del destinatario. Aquí no se implementó ningún nuevo adaptador, servicio de consultas de producción ni resultado del anfitrión.
