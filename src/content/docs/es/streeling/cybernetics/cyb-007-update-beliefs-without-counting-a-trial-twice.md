---
title: Actualizar creencias sin contar un ensayo dos veces
description: Actualizar creencias sin contar un ensayo dos veces — Cibernética
sidebar:
  label: CYB-007 · Actualizar creencias sin contar un ensayo dos veces
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/es/cyb-007-update-beliefs-without-counting-a-trial-twice.es.md
---

:::note[Streeling University]
**CYB-007** · Actualizar creencias sin contar un ensayo dos veces · intermedio · 40 minutos

Generado por el departamento *Cibernética* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/es/cyb-007-update-beliefs-without-counting-a-trial-twice.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CYB-004](../../cybernetics/cyb-004-observe-before-correcting-a-feedback-loop/), [FUT-005](../../futurology/fut-005-value-a-renderer-pilot-before-running-it/)
:::

> **Alcance del borrador.** Trazas de creencias y acciones creadas para el curso, probabilidades condicionales exactas y lectura de código fijado a una revisión. Quedan pendientes las revisiones humanas técnica, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se implementaron ni ejecutaron un controlador real, una prueba de renderizador ni un canal de pruebas calibrado.

## La pregunta del proyecto

Dos agentes resumen la misma prueba de rendimiento. ¿Ha recibido un controlador dos observaciones independientes? La [guía de ingeniería de agentes de GA](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/docs/methodology/agentic-engineering.md) recomienda trabajo acotado y revisión eficiente. Eso motiva conservar las pruebas a través de los traspasos; sus recomendaciones no proporcionan un modelo de independencia probabilística.

Usa la condición F/U estable de [FUT-005](../../futurology/fut-005-value-a-renderer-pilot-before-running-it/), creada para el curso, la distribución previa `1/2` y las verosimilitudes positivas `4/5` en F y `1/5` en U. La regla de acción elige S solo por encima de la probabilidad posterior `3/5`; de lo contrario, K. Distinguiremos un ensayo nuevo de una nueva envoltura de un ensayo antiguo.

## 1. Actualizar con una razón de verosimilitudes

Las posibilidades relativas son `p/(1-p)`. Su valor previo es 1. Un resultado positivo tiene razón de verosimilitudes `(4/5)/(1/5)=4`; uno negativo tiene razón `1/4`. Multiplicar las posibilidades relativas previas por la razón adecuada da las posteriores. La conversión inversa usa `p=odds/(1+odds)`, de acuerdo con la [fórmula de Bayes del NIST](https://www.itl.nist.gov/div898/handbook/apr/section2/apr1a.htm).

Tras un resultado positivo, las posibilidades relativas son 4 y la probabilidad posterior `4/5`. Tras un nuevo resultado negativo, las posibilidades relativas vuelven a 1 y la probabilidad posterior a `1/2`. Esta multiplicación supone que los resultados de los nuevos ensayos son independientes condicionados al mismo estado latente. La independencia es una propiedad del modelo de observación declarado, no del hecho de que hayan llegado dos mensajes.

### Ejercicio 1: seguir observaciones nuevas

Partiendo de la distribución previa `1/2`, calcula las posibilidades relativas y probabilidades posteriores después de un resultado positivo y después de uno negativo independiente. ¿Qué acciones se siguen bajo el umbral declarado?

> **Respuesta:** Las posibilidades relativas pasan a 4 y la probabilidad posterior a `4/5`, seleccionando S. El negativo independiente multiplica las posibilidades relativas por `1/4`, devolviéndolas a 1 y la probabilidad posterior a `1/2`, seleccionando K. Los resultados requieren las hipótesis declaradas de independencia condicional y estado estable.

## 2. Reconocer una copia de un único evento

Si el segundo mensaje es una copia determinista del resultado positivo del primer ensayo, es positivo con probabilidad 1 dado ese evento observado bajo cualquiera de los estados latentes. Por tanto, su razón adicional de verosimilitudes condicionales es 1. No multiplica de nuevo las posibilidades relativas por 4.

En cambio, dos ensayos positivos nuevos e independientes estipulados dan posibilidades relativas 16 y probabilidad posterior `16/17`. La distinción se refiere a la observación subyacente, no a cuánta seguridad expresa el resumen. Un nuevo identificador de envoltura, una marca de tiempo o una redacción distinta no crean un nuevo ensayo experimental.

### Ejercicio 2: comparar copia y repetición

Tras un ensayo positivo, compara un informe positivo copiado con un ensayo positivo realmente nuevo e independiente. ¿Qué probabilidades posteriores resultan? ¿Resuelve la cuestión asignar un nuevo identificador de mensaje al informe copiado?

> **Respuesta:** La copia deja la probabilidad posterior en `4/5`; el nuevo positivo independiente da `16/17`. Un nuevo identificador de mensaje identifica la envoltura, no una observación nueva condicionalmente independiente. Conserva la identidad del ensayo subyacente y las hipótesis sobre cómo se produjeron los ensayos nuevos.

## 3. Observar el cambio de acción al duplicar pruebas

El [registro didáctico](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pilot-value-2026-10-22/belief-updates.json) contiene tres mensajes:

| Envoltura | Ensayo subyacente | Resultado | Probabilidad posterior que conserva la identidad | Probabilidad posterior por recuento ingenuo de mensajes |
| --- | --- | --- | --- | --- |
| wrap-A | trial-A | positivo | `4/5` | `4/5` |
| wrap-A-again | trial-A | positivo copiado | `4/5` | `16/17` |
| wrap-B | trial-B | negativo independiente | `1/2` | `4/5` |

La traza correcta después del nuevo negativo elige K; la ingenua elige S porque contó trial-A dos veces. Es un contraejemplo en un modelo didáctico de observador, no un fallo reproducido en un controlador del proyecto en funcionamiento.

### Ejercicio 3: localizar la actualización espuria

¿Qué mensaje no debe añadir otro factor de 4? Después de wrap-B, indica ambas probabilidades posteriores y acciones. ¿Por qué el recuento de mensajes produce una decisión distinta?

> **Respuesta:** wrap-A-again repite trial-A y no añade ningún factor independiente. Después de wrap-B, la probabilidad posterior que conserva la identidad es `1/2`, eligiendo K, mientras que la ingenua es `4/5`, eligiendo S. Su factor extra de verosimilitud positiva procedía de una copia en lugar de un ensayo nuevo.

## 4. Distinguir identidad, independencia y comparabilidad

Ensayos genuinos distintos pueden producir bytes de resumen idénticos. Deduplicar solo por el hash del resumen podría borrar erróneamente información nueva. A la inversa, dos resúmenes diferentes pueden describir el mismo ensayo bruto. Un traspaso útil conserva procedencia del ensayo, tiempo de recogida, entorno, protocolo y entradas compartidas, además de la identidad del artefacto.

Incluso los ensayos distintos pueden no ser condicionalmente independientes ni comparables. Pueden compartir una perturbación, solaparse en el tiempo, reutilizar un resultado en caché u observar un estado que cambió. El [informe histórico BRUTAL M2](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m2-20261019-235218.md) y el [seguimiento M3](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) tienen ejecuciones registradas distintas y controles variables, con sus propios contextos de revisión y cambios sin confirmar. No fueron generados por este modelo binario de verosimilitud.

### Ejercicio 4: auditar dos identidades

Dos informes tienen hashes distintos, pero ambos citan el mismo ensayo. Otros dos tienen bytes de resumen iguales, pero proceden de ensayos nuevos distintos. ¿Debe la igualdad de hashes por sí sola determinar las actualizaciones de creencias? ¿Demuestra una identidad de ensayo distinta la independencia condicional?

> **Respuesta:** No. Hashes distintos pueden envolver un evento, mientras resúmenes iguales pueden surgir de eventos distintos. Conserva la procedencia del ensayo subyacente y el modelo de dependencia y comparabilidad. Una identidad distinta permite investigar un ensayo nuevo, pero no demuestra por sí misma independencia condicional ni un estado latente estable.

## 5. Valorar otra actualización antes de solicitarla

Tras el primer resultado positivo, un segundo ensayo nuevo tiene probabilidad positiva `17/25` y negativa `8/25`. El segundo positivo da probabilidad posterior `16/17` y pérdida óptima `10/17`; el negativo devuelve la probabilidad posterior a `1/2` y pérdida 4. Promediar da pérdida esperada `42/25=1.68`, frente a la pérdida actual 2. Su valor condicional bruto es `8/25=0.32` puntos.

Tras un primer resultado negativo, cualquier segundo resultado sigue seleccionando K, así que el valor bruto de decisión del segundo ensayo es 0 en esa rama. Promediado antes del primer resultado, el valor marginal del segundo ensayo es `4/25=0.16`. Con coste 0.6, un segundo ensayo no merece la pena en ninguna rama de este modelo didáctico. Es un cálculo acotado de parada; no instala una regla de parada en producción ni resuelve obligaciones de validación obligatoria.

### Ejercicio 5: decidir si solicitar otro ensayo

Tras un primer resultado positivo, compara el valor bruto 0.32 del segundo ensayo con coste 0.6. ¿Cuál es su valor neto? ¿Qué pasa tras un primer resultado negativo y puede este modelo cancelar validación técnica obligatoria?

> **Respuesta:** Tras un positivo, el valor neto es `0.32-0.6=-0.28` puntos; tras un negativo es `0-0.6=-0.6`. No solicites el segundo ensayo opcional bajo estas premisas. La validación requerida es una obligación separada de admisibilidad, y la verosimilitud, la persistencia del estado y el modelo de costes aún necesitan justificación real antes de controlar un proceso en funcionamiento.
