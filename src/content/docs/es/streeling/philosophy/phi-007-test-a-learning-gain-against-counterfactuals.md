---
title: Contrastar una ganancia de aprendizaje con contrafactuales
description: Contrastar una ganancia de aprendizaje con contrafactuales — Filosofía
sidebar:
  label: PHI-007 · Contrastar una ganancia de aprendizaje con contrafactuales
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/es/phi-007-test-a-learning-gain-against-counterfactuals.es.md
---

:::note[Streeling University]
**PHI-007** · Contrastar una ganancia de aprendizaje con contrafactuales · intermedio · 45 minutos

Generado por el departamento *Filosofía* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/es/phi-007-test-a-learning-gain-against-counterfactuals.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHI-001](../../philosophy/phi-001-how-to-argue-well/), [COG-007](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/)
:::

> **Alcance del borrador.** Resultados binarios didácticos, contramodelos lógicos, enumeración finita exacta y lectura de fuentes primarias y código. Quedan pendientes las revisiones humanas técnica, lingüística, musical y de estudiantes, así como la verificación del HTML del curso desplegado. No se observaron participantes, una intervención, asignación aleatoria ni un efecto causal de aprendizaje.

## La pregunta del proyecto

Un agente mejora un flujo de práctica e informa de una puntuación posterior mayor. ¿Qué premisa conecta ese cambio con el beneficio del flujo? [COG-007](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/) conserva ayuda y datos ausentes unidos a un criterio de resultado. Esta lección plantea otra pregunta incluso cuando están disponibles todos los resultados: ¿qué habrían puntuado las mismas unidades en ese mismo momento posterior de evaluación sin la intervención?

La [guía del NIST de diseño completamente aleatorizado](https://www.itl.nist.gov/div898/handbook/pri/section3/pri331.htm) trata la asignación aleatoria de niveles de factores a unidades experimentales. Se leyó el contenido real de su página web. Las tablas binarias de resultados potenciales siguientes son una construcción didáctica propia, no observaciones del NIST, un estudio publicado ni un tamaño de muestra recomendado.

## 1. Nombrar la comparación no observada

Usa una población separada de ocho estudiantes ficticios, no las preguntas repetidas de COG-007. Sus resultados previos son `[0,0,1,0,1,0,1,1]`; sus resultados posteriores con la intervención son `[1,1,1,0,1,0,1,1]`. Cada resultado binario corresponde al mismo tipo declarado de evaluación. La media didáctica previa es `4/8`, la posterior `6/8` y su diferencia `1/4`.

Sea `Y1` el resultado posterior de cada unidad con la intervención y `Y0` su resultado posterior sin ella. El efecto medio de la población finita es la media de `Y1-Y0` entre esas ocho unidades. La prueba previa se observa en otro momento. Igualar el `Y0` posterior a la prueba previa requiere una hipótesis sustantiva sobre qué cambiaría en caso contrario.

### Ejercicio 1: identificar la premisa ausente

Calcula la diferencia antes y después. ¿Qué resultado posterior falta cuando todos reciben la intervención y por qué sustituir la prueba previa no es un paso aritmético neutral?

> **Respuesta:** La diferencia es `6/8-4/8=1/4`. No se observa el `Y0` posterior sin intervención de cada unidad. Igualarlo a la prueba previa anterior supone que no habría ningún cambio relevante sin la intervención; los datos antes y después por sí solos no establecen esa premisa.

## 2. Construir mundos que coincidan en lo observado

Conserva las mismas pruebas previas y resultados posteriores tratados en tres mundos didácticos. En el mundo de beneficio, el vector posterior sin intervención es igual a la prueba previa, así que el efecto medio es `1/4`. En el mundo sin efecto, el vector sin intervención es igual a `Y1`, así que el efecto es 0. En el mundo de daño, todos los resultados posteriores sin intervención son 1, así que el efecto es `6/8-8/8=-1/4`.

Todos los mundos coinciden en cada observación aportada de antes y después. Difieren en el contrafactual ausente y, por tanto, en el signo del beneficio. Es un testigo lógico de falta de identificación bajo estas premisas sin restricciones. No afirma que todos los mundos sean igual de plausibles ni que el flujo real ayude o perjudique a nadie.

### Ejercicio 2: cuestionar la conclusión causal

Indica los tres efectos medios. ¿Por qué coincidir en la mejora observada no los distingue y qué tipo de premisa o prueba adicional haría falta?

> **Respuesta:** Los efectos son `1/4`, 0 y `-1/4`. Sus pruebas previas y posteriores tratadas son idénticas; solo difieren los resultados posteriores sin intervención no observados. Hace falta una hipótesis justificada sobre esa comparación o un diseño de comparación adecuado. El cambio positivo didáctico no selecciona un mundo.

## 3. Acotar lo que permiten solo los datos binarios

Hay 256 vectores binarios `Y0` posibles para ocho unidades etiquetadas. Con `Y1` fijado en seis éxitos, el menor efecto medio posible es `6/8-1=-1/4`; el mayor es `6/8-0=3/4`. Ambas cotas pueden alcanzarse mediante un vector `Y0` completo, así que el intervalo es ajustado para este problema finito sin más restricciones.

El [registro contrafactual](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/counterfactual-gains.json) enumera todos los vectores y nueve niveles de efecto alcanzables. Los recuentos de vectores no son una distribución de probabilidad sobre mundos reales. El intervalo no es de confianza y estas ocho unidades ficticias no estiman una población futura de estudiantes.

### Ejercicio 3: derivar una cota honesta

Deriva las cotas sin restricciones e indica el vector contrafactual que alcanza cada una. ¿Da enumerar 256 posibilidades una probabilidad a cada una o hace irrelevante la prueba previa para todos los diseños posibles de estudio?

> **Respuesta:** `Y0` todo unos da la cota inferior `-1/4`; `Y0` todo ceros da la superior `3/4`. Enumerar no asigna probabilidades. Las pruebas previas pueden informar un diseño o modelo justificado, pero no restringen el contrafactual posterior en esta construcción sin restricciones si no se añade una hipótesis.

## 4. Separar el promedio de un diseño de una asignación concreta

Considera ahora un diseño futuro hipotético que asigna cuatro de estos ocho estudiantes a intervención y cuatro a comparación, uniformemente entre 70 repartos. Es un esquema hipotético de observación distinto del ejemplo en que todos reciben tratamiento. Fija los resultados potenciales de cada mundo y supone una intervención bien definida, observación coherente con la asignación y ausencia de interferencia entre estudiantes.

Entre todos los repartos, la media del contraste entre media tratada y media de control equivale al efecto medio de la población finita del mundo: `1/4`, 0 o `-1/4`. Un reparto concreto puede diferir. En el mundo de beneficio, asignar los estudiantes 1, 2, 4 y 6 a intervención da media tratada `1/2`; los resultados sin intervención de las unidades restantes son todos 1, dando media de comparación 1 y contraste `-1/2`.

### Ejercicio 4: probar una garantía de aleatorización

Indica el número de repartos equilibrados y el contraste medio entre repartos en el mundo de beneficio. Reconstruye el contraste negativo declarado. ¿Garantiza el diseño que cada contraste realizado tenga el signo del efecto verdadero?

> **Respuesta:** Hay 70 repartos y su contraste medio es `1/4`. Los estudiantes 1, 2, 4 y 6 tienen resultados tratados 1, 1, 0, 0, así que su media es `1/2`; los controles 3, 5, 7 y 8 tienen cada uno resultado sin intervención 1, dando contraste `-1/2`. La ausencia de sesgo entre las asignaciones estipuladas no garantiza el signo ni la precisión de un resultado. Aquí no se ejecutó ninguna asignación real.

## 5. Concretar la unidad y la intervención antes de atribuir progreso

Si se asigna la intervención a estudiantes, las respuestas repetidas de un estudiante no son estudiantes adicionales asignados independientemente. Compartir pistas entre grupos, visibilidad desigual de respuestas o cambiar el criterio diferido también pueden cambiar la comparación realizada. Un diseño futuro necesita versiones explícitas de intervención y comparación, unidad y procedimiento de asignación, tiempos, reglas de pistas y ayuda, política de datos ausentes y definición del resultado antes de interpretar un contraste.

Las [etiquetas de seguimiento de planes de práctica](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/PracticeRoutineTypes.fs#L81-L101) y el [registro de evaluación RAG](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Rag/RagEvaluationModels.cs#L3-L31) de GA no proporcionan estas asignaciones hipotéticas de estudiantes ni sus observaciones. Esto acota esas definiciones inspeccionadas; no afirma que todos los subsistemas del proyecto carezcan de pruebas más ricas.

### Ejercicio 5: corregir el informe de beneficio de un agente

Un agente convierte once filas de respuestas de un estudiante en «once participantes aleatorizados» y trata una mejor prueba posterior como beneficio demostrado. Sustituye la afirmación y especifica las siguientes pruebas necesarias.

> **Respuesta:** Las filas de respuestas son intentos vinculados a sus identidades reales de estudiante y pregunta, no participantes aleatorizados independientemente. Un cambio antes y después describe su criterio registrado y no identifica beneficio sin una comparación contrafactual justificada. Una afirmación futura necesita un procedimiento de comparación y asignación implementado y versionado, resultados reales medidos en momentos apropiados, registros de ayuda y datos ausentes y comprobaciones de sus hipótesis. Ni este paquete fijado ni un campo de plan de práctica aportan esas pruebas.

La [tarea preparada y su rúbrica](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/learner-task.md) piden a los estudiantes que deriven los contramodelos. Su preparación no constituye una revisión humana ni un experimento causal.
