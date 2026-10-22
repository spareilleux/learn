---
title: Evaluar una prueba piloto según su horizonte de decisión
description: Evaluar una prueba piloto según su horizonte de decisión — Gestión de productos y proyectos
sidebar:
  label: PM-006 · Evaluar una prueba piloto según su horizonte de decisión
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/es/pm-006-test-a-pilot-against-its-decision-horizon.es.md
---

:::note[Streeling University]
**PM-006** · Evaluar una prueba piloto según su horizonte de decisión · intermedio · 40 minutos

Generado por el departamento *Gestión de productos y proyectos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/es/pm-006-test-a-pilot-against-its-decision-horizon.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PM-005](../../product-management/pm-005-interpret-brutal-coexistence-experiments/), [FUT-005](../../futurology/fut-005-value-a-renderer-pilot-before-running-it/)
:::

> **Alcance del borrador.** Modelo de pérdidas, costes y horizonte creado para el curso, aritmética exacta y lectura de fuentes fijadas a una revisión. Quedan pendientes las revisiones humanas técnica, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se midieron una migración, una prueba de renderizador, un ahorro de tiempo de ingeniería ni un despliegue en producción.

## La pregunta del proyecto

Un equipo propone una prueba piloto porque su resultado podría ayudar a muchas decisiones futuras. ¿Cuántas decisiones pueden reutilizar realmente esa información y tiene coste cambiar? [FUT-005](../../futurology/fut-005-value-a-renderer-pilot-before-running-it/) valoró un canal de información sin coste de migración. Aquí añadimos un cargo único y volvemos a optimizar las acciones, en lugar de añadir un coste a una recomendación antigua.

El [README de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) registra una observación original grave de coexistencia y un seguimiento no concluyente. [PM-005](../../product-management/pm-005-interpret-brutal-coexistence-experiments/) explica por qué importan sus condiciones. No miden el horizonte, los cargos ni el siguiente modelo de probabilidad.

## 1. Declarar qué persiste a lo largo del horizonte

Usa la misma distribución previa F/U didáctica `1/2`, las pérdidas de acción K 4 en ambas condiciones y S 0 en F o 10 en U, y las verosimilitudes de la prueba piloto `4/5` y `1/5`. Una prueba cuesta 0.6 puntos. Su resultado se reutiliza en N decisiones por lo demás idénticas bajo la misma condición latente estable y modelo de consecuencias. Son hipótesis fuertes, no un recuento de tareas futuras arbitrarias.

Carga 2 puntos adicionales una sola vez si se elige S para el horizonte; no cargues migración si se elige K. Todas las cantidades usan la misma escala cardinal didáctica. Antes de una prueba piloto, K cuesta `4*N`; S tiene coste esperado `5*N+2`, así que K sigue siendo la elección previa para N positivo. No hay conversión medida de minutos, dinero o tiempos de fotograma a estos puntos.

### Ejercicio 1: incluir el cargo único

Para N igual a 2, calcula las pérdidas esperadas totales previas de K y S, incluida la migración. ¿Por qué es incorrecto multiplicar el cargo de migración por N en este modelo?

> **Respuesta:** K cuesta `4*2=8`; S cuesta `5*2+2=12`. El modelo carga migración una vez al seleccionar S, no una vez por decisión. Un cargo por uso sería otro modelo que necesitaría otro cálculo.

## 2. Recalcular las acciones dependientes del resultado

Tras una señal positiva, la probabilidad posterior de F es `4/5`. Compara el coste K `4*N` con el coste S `2*N+2`. Tras una señal negativa, compara K `4*N` con S `8*N+2`. Los empates mantienen K.

Con N igual a 1, la rama positiva empata en 4, así que se conserva K y no se paga migración. Con N igual a 2, la rama positiva selecciona S por 6 en lugar de K por 8; la negativa mantiene K por 8 en lugar de S por 18. Añadir migración cambia por tanto lo que puede justificar la prueba piloto, especialmente en horizontes cortos.

### Ejercicio 2: probar el horizonte corto

¿Qué acciones siguen una señal positiva con N igual a 1 y 2? ¿Qué cargo de migración se paga realmente en cada rama seleccionada? ¿Se transfiere sin cambios la recomendación sin migración de FUT-005?

> **Respuesta:** Con N igual a 1, ambas alternativas cuestan 4 y la política de empate mantiene K, sin pagar migración. Con N igual a 2, S cuesta 6 frente a K por 8 y paga el cargo único 2. La política anterior sin migración debe recalcularse bajo las nuevas consecuencias.

## 3. Promediar la política de la prueba piloto y hallar el punto de equilibrio

Ambos resultados de señal tienen probabilidad `1/2` cada uno. Para N entero positivo, la pérdida esperada optimizada antes del coste de la prueba piloto es `3*N+1`; tras el cargo 0.6 es `3*N+1.6`. Con N igual a 1, la rama empatada tiene la misma pérdida óptima aunque la acción elegida K no pague migración. Conserva esa distinción al informar de los componentes del coste.

| N | Mantener sin prueba piloto | Total esperado con prueba piloto | Ganancia neta |
| --- | --- | --- | --- |
| 1 | 4 | 4.6 | -0.6 |
| 2 | 8 | 7.6 | 0.4 |
| 5 | 20 | 16.6 | 3.4 |
| 10 | 40 | 31.6 | 8.4 |

La ganancia modelada es `N-1.6`, positiva cuando `N>1.6`. El primer horizonte entero con ganancia positiva es 2. Es un cálculo condicional del punto de equilibrio, no un ahorro observado ni una justificación para contar cargas de trabajo sin relación como usos idénticos.

### Ejercicio 3: hallar el horizonte útil

Calcula la ganancia neta con N igual a 1 y 2 e identifica el primer horizonte entero con ganancia positiva. Con N igual a 5, ¿qué pérdida total se predice con la prueba piloto?

> **Respuesta:** Las ganancias son -0.6 y 0.4 puntos; el primer horizonte entero con ganancia positiva es 2. Con N igual a 5, la pérdida total esperada es `3*5+1.6=16.6`. Todos los resultados dependen de las hipótesis didácticas de estado estable, señal reutilizable y pérdidas comparables.

## 4. Conservar los mismos costes en un techo de información

La información perfecta elegiría S en F con coste total 2 y K en U con coste `4*N`. Su pérdida esperada es `2*N+1` para N entero positivo. Frente a K previo por `4*N`, el techo bruto de información perfecta es `2*N-1`.

Con N igual a 1, el techo es 1 punto, menor que el techo de 2 puntos de FUT-005 sin migración. La prueba piloto imperfecta tiene valor bruto de decisión cero en este horizonte antes de su cargo de adquisición porque ninguna señal cambia la acción elegida. Un techo no promete que una prueba ruidosa disponible lo alcance. La [clase del MIT sobre valor de la información](https://ocw.mit.edu/courses/15-053-optimization-methods-in-management-science-spring-2013/b68f3b255275ffa42099958e373248b1_MIT15_053S13_lec19.pdf#page=7) define el valor de información frente al mismo problema de decisión original; cambiar costes cambia ese problema.

### Ejercicio 4: comparar problemas equivalentes

Para N igual a 2, calcula la pérdida esperada y el techo con información perfecta e incluyendo migración. ¿Puede reutilizarse simplemente el techo sin migración? ¿Significa un techo de 3 puntos que la prueba piloto imperfecta vale 3 puntos?

> **Respuesta:** La pérdida esperada con información perfecta es `2*2+1=5`, frente a la referencia 8, dando techo 3. Reutilizar un techo que omite migración compara problemas distintos. El valor bruto de la prueba piloto imperfecta aquí es solo `8-7=1` punto antes de su cargo de adquisición 0.6, así que no alcanza el techo de información perfecta.

## 5. Hacer de la reutilización de información una hipótesis refutable

El [informe histórico M2](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m2-20261019-235218.md) y el [informe M3](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) nombran revisiones distintas con cambios sin confirmar y controles variables. Ilustran por qué debe comprobarse la comparabilidad antes de multiplicar un resultado a lo largo de un horizonte. No establecen la misma condición oculta para cada escena, controlador o tarea futura.

Un registro propuesto de prueba piloto debería indicar alcance de la decisión, hipótesis de reutilización, acciones permitidas, cargos únicos frente a cargos por uso, unidades de coste, modo efectivo y desencadenante de caducidad de las pruebas. Una nueva escena o anfitrión puede invalidar la reutilización sin demostrar que el candidato sea malo. La alternativa más sencilla es mantener la configuración actual mientras se recoge la mínima evidencia comparable necesaria para la decisión real. Un nuevo DSL es opcional; un registro tipado claro puede expresar estas distinciones.

### Ejercicio 5: cuestionar una reutilización exagerada

Un agente aplica la ganancia de 8.4 puntos para N igual a 10 a diez escenas sin relación en anfitriones distintos. ¿Qué hipótesis falló? Indica un desencadenante de caducidad y las pruebas necesarias antes de afirmar ahorros reales.

> **Respuesta:** Diez tareas no son automáticamente diez decisiones idénticas bajo una condición latente estable y una señal calibrada. Un cambio de escena, carga de trabajo, anfitrión, controlador, modo efectivo o protocolo de medición debería desencadenar una reevaluación de la reutilización. Los ahorros reales necesitan resultados comparables, costes reales de adquisición y migración, una escala justificada de consecuencias y los controles requeridos de calidad y coexistencia; aquí no se midió tal ahorro.

El [registro de horizonte fijado](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pilot-value-2026-10-22/decision-horizons.json) conserva las políticas exactas de las ramas, incluido el empate con N igual a 1 y su cargo de migración pagado de cero.
