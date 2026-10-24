---
title: Comparar adopción por etapas y migración irreversible
description: Comparar adopción por etapas y migración irreversible — Futurología
sidebar:
  label: FUT-009 · Comparar adopción por etapas y migración irreversible
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/futurology/es/fut-009-compare-staged-adoption-with-an-irreversible-migration.es.md
---

:::note[Streeling University]
**FUT-009** · Comparar adopción por etapas y migración irreversible · intermedio · 40 minutos

Generado por el departamento *Futurología* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/futurology/es/fut-009-compare-staged-adoption-with-an-irreversible-migration.es.md) · [Mi diario](../../journal/)

Requisitos previos: [FUT-004](../../futurology/fut-004-scenario-test-an-observatory-renderer/), [FUT-005](../../futurology/fut-005-value-a-renderer-pilot-before-running-it/)
:::

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Una futura migración del renderizador elimina inmediatamente la ruta antigua. Una alternativa por etapas la conserva hasta superar un control de aceptación. ¿Qué plan limita la pérdida si el candidato no sirve? El registro BRUTAL antiguo contiene un fallo de coexistencia y un seguimiento inconcluso; no aporta probabilidades de éxito. Esta lección compara pérdidas condicionales por escenario y explicita la reversión sin inventar un piloto real.

[Requisito previo: fut-004-scenario-test-an-observatory-renderer](../../futurology/fut-004-scenario-test-an-observatory-renderer/); [Requisito previo: fut-005-value-a-renderer-pilot-before-running-it](../../futurology/fut-005-value-a-renderer-pilot-before-running-it/)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

Use dos estados construidos, adecuado e inadecuado, y puntos de pérdida comparables. La migración directa cuesta menos si resulta adecuada, pero pierde más en el otro estado. Adoptar por etapas cuesta más cuando todo va bien porque mantiene dos rutas y comprueba un control. Si resulta inadecuada, conserva una salida. Compare pérdidas máximas y arrepentimiento por escenario antes de invocar probabilidades. A diferencia del valor esperado de información del requisito previo, aquí no estimamos verosimilitudes ni promediamos estados. Un control defectuoso puede admitir al candidato inadecuado y eliminar la protección. Revertir exige un artefacto conservado y compatibilidad real, no una palabra tranquilizadora.

## Caso fijo y supuestos

```text
states=["suitable","unsuitable"]; unit="authored loss points"
direct=[6,26]; staged_with_correct_gate=[10,8]
state_best=[6,8]
direct_regret=[0,18]; staged_regret=[4,0]
direct_worst=26; staged_worst=10
direct_max_regret=18; staged_max_regret=4
control_staged_false_acceptance=[10,30]; control_worst=30
```

## Ejercicios resueltos

### Ejercicio 1

¿Qué plan tiene menor pérdida en cada estado?

> **Respuesta:** El directo gana si es adecuado con `6` frente a `10`; las etapas ganan si es inadecuado con `8` frente a `26`. Ningún plan domina ambos estados.

### Ejercicio 2

Compare las pérdidas máximas.

> **Respuesta:** Son `26` para directo y `10` para etapas. Preferir menor pérdida máxima favorece las etapas en esta tabla, sin establecer probabilidades reales.

### Ejercicio 3

Deduzca ambos vectores de arrepentimiento.

> **Respuesta:** Reste la mejor pérdida de cada estado: directo da `[0,18]`, etapas `[4,0]`. Los arrepentimientos máximos son `18` y `4`.

### Ejercicio 4

Aplique el control de aceptación defectuoso. ¿Siguen siendo las etapas automáticamente más seguras?

> **Respuesta:** No. La pérdida máxima llega a `30`, por encima de `26` del directo. El control correcto es una premisa decisiva, no una garantía de adoptar por etapas.

### Ejercicio 5

¿Autoriza la migración el informe antiguo inconcluso?

> **Respuesta:** No. Conserva evidencia de coexistencia sin resolver. El plan real necesita aceptación vinculada a la fuente, artefactos de reversión y autorización aplicable; la tabla no aporta esas observaciones.

## Tarea con consulta de fuentes

Lea el fallo antiguo y el seguimiento inconcluso. Prepare manualmente pérdidas directas y por etapas, con requisitos de artefactos conservados y controles marcados como propuestas. Pida explicar la ventaja de las etapas y pruebe la falsa aceptación. Ese control refuta toda afirmación de seguridad incondicional.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/historical-comparison.json)
- [Fuente primaria](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md)
- [Expediente de evidencias fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
