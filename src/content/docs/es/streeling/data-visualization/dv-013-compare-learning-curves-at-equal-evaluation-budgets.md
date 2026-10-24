---
title: Comparar curvas de aprendizaje con presupuestos de evaluación iguales
description: Comparar curvas de aprendizaje con presupuestos de evaluación iguales — Visualización de datos
sidebar:
  label: DV-013 · Comparar curvas de aprendizaje con presupuestos de evaluación iguales
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-013-compare-learning-curves-at-equal-evaluation-budgets.es.md
---

:::note[Streeling University]
**DV-013** · Comparar curvas de aprendizaje con presupuestos de evaluación iguales · intermedio · 40 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-013-compare-learning-curves-at-equal-evaluation-budgets.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/), [PHI-007](../../philosophy/phi-007-test-a-learning-gain-against-counterfactuals/)
:::

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Un gráfico de evaluación GA asistida por IX compara el último punto de cada curva. Un candidato se evaluó durante más tiempo. ¿Su mayor puntuación final demuestra un método mejor? El requisito previo separaba mejora y beneficio causal. Aquí el problema gráfico es más concreto: presupuestos de evaluación desiguales y parada selectiva. Las curvas son listas construidas, no observaciones de estudiantes ni ejecuciones de entrenamiento.

[Requisito previo: dv-002-denominators-and-test-populations](../../data-visualization/dv-002-denominators-and-test-populations/); [Requisito previo: phi-007-test-a-learning-gain-against-counterfactuals](../../philosophy/phi-007-test-a-learning-gain-against-counterfactuals/)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

Defina el eje horizontal como ítems evaluados acumulados bajo un evaluador y una política fijos. Compare puntos observados con presupuestos iguales; no invente extremos ausentes ni interpole sin declararlo. Una puntuación puede mejorar con el presupuesto mientras otro método la supera en todos los presupuestos compartidos. La comparación sigue siendo descriptiva; costes de evaluación y entrenamiento pueden diferir. Conserve intentos y ausencias: eliminar fallos puede cambiar presupuesto y progreso aparente. El tipo de evaluación GA existente motiva resultados identificados, pero no aporta esta trayectoria hipotética ni su explicación causal.

## Caso fijo y supuestos

```text
budget_items=[10,20,30]
A_score=[0.60,0.70,0.75]
B_score=[0.65,0.72,null]
shared_budget_differences_B_minus_A=[0.05,0.02]
last_observed_A=0.75; last_observed_B=0.72
shared_mean_A=(0.60+0.70)/2=0.65
shared_mean_B=(0.65+0.72)/2=0.685
control_B_score=[0.60,0.70,null]; control_shared_differences=[0,0]
```

## Ejercicios resueltos

### Ejercicio 1

Compare los últimos resultados observados. ¿Qué diferencia aparece?

> **Respuesta:** A termina en `0.75` y B en `0.72`, pero sus presupuestos son `30` y `20` ítems. Los extremos no comparan igual trabajo.

### Ejercicio 2

Compare solo los presupuestos compartidos.

> **Respuesta:** B supera a A por `0.05` y `0.02`. El resultado descriptivo invierte la impresión de los extremos sin aportar una afirmación causal.

### Ejercicio 3

Calcule las medias en la cuadrícula común. ¿Son áreas bajo curvas continuas?

> **Respuesta:** Las medias son `0.65` y `0.685`, con diferencia `0.035`. Son medias de puntos equiponderados, no integrales ni estimaciones poblacionales.

### Ejercicio 4

¿Puede dibujarse como cero el extremo ausente de B?

> **Respuesta:** No: es `null`. El control de puntuaciones iguales da `[0,0]` en presupuestos compartidos; la ausencia por sí sola no implica inferioridad.

### Ejercicio 5

¿Demuestra este gráfico que un agente enseña mejor?

> **Respuesta:** No. Describe puntos construidos. El beneficio real exige resultados observados, ayudas registradas, comparación justificada y evaluador fijo; nada de ello se observó aquí.

## Tarea con consulta de fuentes

Lea el expediente contrafactual y localice el tipo de evaluación GA en la fuente fijada. Prepare manualmente un texto a presupuesto igual conservando los puntos ausentes. Pida comparar los resultados finales y corrija la conclusión con las diferencias de presupuesto compartido. Un extremo inventado o una superioridad con presupuestos distintos refuta el texto.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/counterfactual-gains.json)
- [Fuente primaria](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Rag/RagEvaluationModels.cs)
- [Expediente de evidencias fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
