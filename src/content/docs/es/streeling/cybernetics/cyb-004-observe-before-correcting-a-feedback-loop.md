---
title: Observar antes de corregir un bucle de realimentación
description: Observar antes de corregir un bucle de realimentación — Cibernética
sidebar:
  label: CYB-004 · Observar antes de corregir un bucle de realimentación
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/es/cyb-004-observe-before-correcting-a-feedback-loop.es.md
---

:::note[Streeling University]
**CYB-004** · Observar antes de corregir un bucle de realimentación · intermedio · 40 minutos

Generado por el departamento *Cibernética* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/es/cyb-004-observe-before-correcting-a-feedback-loop.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CYB-002](../../cybernetics/cyb-002-active-dampening-cross-repo-oscillation/)
:::

> **Borrador fuente producido por IA.** Siguen pendientes las revisiones por un especialista del tema, una persona con dominio del idioma y un alumno, así como la publicación pública del curso en HTML.

## 1. Definir qué controla el bucle

Un reintento puede producir otro registro sin mejorar el sistema. Antes de automatizar una corrección, identifique el proceso controlado (la planta), la intervención permitida (el actuador), la observación (el sensor) y la regla que convierte la evidencia en una decisión. Repetir sin observar el estado pertinente no demuestra una mejora en bucle cerrado.

[CYB-002](../../cybernetics/cyb-002-active-dampening-cross-repo-oscillation/) presenta el estado objetivo, el estado medido y la realimentación. Aquí contrastamos ese vocabulario con trazas conservadas del proyecto. Sus campos ilustrativos de gobernanza no se convierten en nuevos requisitos del protocolo. Una reducción del error en un solo punto no establece convergencia ni justifica una política universal de corrección.

Use la [guía de evidencias](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/feedback-projections-2026-10-22/README.md) y la [tarea del alumno](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/feedback-projections-2026-10-22/learner-task.md). Su entrega será una nota de corrección fundamentada. Esta lección analiza artefactos conservados; no presenta una nueva ejecución nativa ni una prueba con alumnos.

### Ejercicio 1 — Nombrar los componentes del bucle

Defina planta, actuador, sensor y decisión para el [experimento de guitarra](../../guitar-acoustics/gas-004-run-open-e-decay-candidate/).

> **Respuesta:** La planta es el experimento fijo del motor de guitarra. El actuador es el parámetro de decaimiento base, cambiado de **0.9978** a **0.9976**. El sensor mide la caída del nivel PCM16 en ventanas relativas al inicio del sonido y el error absoluto respecto a la referencia. La decisión compara la mejora con el umbral declarado. El código de salida del proceso informa sobre la ejecución, una propiedad distinta.

## 2. Separar una ejecución correcta del objetivo

Los [resultados de guitarra fijados](https://github.com/spareilleux/learn/blob/7eaa68f8d4d32e8d1b495a93775d18135e709811/code/streeling/evidence/guitar-runtime-2026-10-22/results.json) proceden del código del motor `dc2e74cbd992a298f67efb928b5b3754615e1924`. Ambas variantes aplican el mismo cuantificador y procedimiento de medición a sus entradas reales. Por tanto, sus errores permiten esta comparación aritmética; la cuantificación no invalida todas las diferencias medidas.

El [análisis de decisiones](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/feedback-projections-2026-10-22/feedback-decisions.json) registra un error inicial de **2.837303388606845 dB**, un error del candidato de **2.723137239012459 dB** y una mejora de **0.11416614959438576 dB**. El requisito declarado es de al menos **1 dB**. El código de salida **0** y el valor false de `candidate_passes_decline_gate` pueden coexistir: el experimento terminó y el candidato no cumplió su objetivo.

### Ejercicio 2 — Calcular el error admisible

¿Qué error del candidato cumpliría el criterio indicado? ¿Lo cumple el candidato observado?

> **Respuesta:** Reste la mejora exigida del error inicial: el cálculo almacenado da un error máximo del candidato de **1.8373033886068448 dB**. El error real supera ese límite. Rechace este candidato según este criterio. Una intervención no proporciona una tasa de convergencia, un gradiente ni la certeza de que otro cambio del decaimiento ayude.

## 3. Clasificar la evidencia antes de corregir

En el caso de la escena, [Godot](https://docs.godotengine.org/en/4.6/classes/class_resource.html) debe cargar la escena guardada y producir observaciones con nombre. El [informe del lanzamiento fallido](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/launcher-failed-run-report.json) registra `godot_execution` con `spawnSync godot ETIMEDOUT`. Se agotó el límite de arranque de **60 segundos** del controlador. La admisión semántica anterior pasó, pero ningún informe nativo establece la geometría ni la identidad de los cruces.

Distinga tres situaciones. **Observación ausente:** el informe nativo esperado nunca llega. **Medición mal formada:** llega un informe con valores inutilizables, procedencia incorrecta o una definición de sensor incompatible. **Incumplimiento del objetivo:** una observación válida infringe su criterio indicado. Agotar el tiempo no es un defecto geométrico medido; un valor de apariencia numérica con unidades desconocidas no constituye un incumplimiento fiable del objetivo.

Los [resultados finales de la escena](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/results.json) incluyen **190** comprobaciones nativas superadas y **3** defectos introducidos como controles. En el control de asociación incorrecta pasan las comprobaciones de geometría y hebra superior, mientras falla `ray_crossing_identity`. Es una observación útil: una geometría correcta no basta para establecer que el impacto identifica el cruce previsto.

### Ejercicio 3 — Elegir la clase de fallo

Clasifique el tiempo agotado y el resultado de asociación incorrecta. ¿Dónde situaría un informe con unidades incompatibles?

> **Respuesta:** El tiempo agotado deja ausente la observación nativa. La asociación incorrecta es un incumplimiento observado del criterio de identidad, aunque pasen las comprobaciones geométricas. Las unidades incompatibles vuelven inutilizable la medición propuesta hasta reparar su interpretación. Diagnostique el sensor ausente o defectuoso antes de cambiar la geometría.

## 4. Preguntar qué distingue el sensor

Un sensor suele proyectar un estado más rico en una representación más pequeña. El codificador conservado usa [Math.round](https://tc39.es/ecma262/multipage/numbers-and-dates.html#sec-math.round): `Math.round(sample * 32767)`, almacenado como PCM16 con signo. Unas salidas proyectadas iguales no revelan todas las diferencias entre sus entradas.

La [lectura de cuantificación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/feedback-projections-2026-10-22/quantization.json) encuentra **2918** muestras flotantes distintas entre el resultado nativo inicial y [Wasm](https://nodejs.org/en/learn/getting-started/nodejs-with-webassembly), pero **0** muestras PCM16 distintas. En la muestra **646**, el valor nativo **0.000552888261154294** y el de Wasm **0.0005528881447389722** se convierten ambos en **18**. Este contraejemplo concreto limita lo que observa la igualdad PCM; no es un teorema general sobre dinámicas ocultas.

### Ejercicio 4 — Elegir una observación discriminante

¿Qué observación conservada refuta la igualdad bruta: los datos PCM16 iguales o las muestras flotantes decodificadas distintas?

> **Respuesta:** Las muestras flotantes distintas refutan la igualdad bruta. La igualdad PCM16 establece igualdad solo en esa proyección. Ninguno de los resultados establece equivalencia auditiva. Elija un sensor con resolución suficiente para la pregunta y conserve la observación más rica cuando esté disponible.

## 5. Aplicar una corrección comprobada y detenerse

La [caracterización mediante el ejecutable directo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/direct-executable-characterization.json) ejecutó el mismo programa instalado sobre el mismo proyecto copiado y el mismo script, con éxito en **0.5707436999946367 segundos**. Un intento anterior de cambiar el directorio padre en PATH seguía seleccionando el enlace porque el ejecutable real tenía otro nombre; no aisló un cambio de selección del ejecutable. El controlador final resuelve ese enlace antes del lanzamiento.

### Ejercicio 5 — Redactar una nota de corrección acotada

Proponga una corrección del lanzamiento, su comprobación, condición de parada, criterio de refutación y límite de coste.

> **Respuesta:** Resuelva el enlace del ejecutable y registre la ruta seleccionada conservando las mismas entradas copiadas. Exija un informe nativo válido con las comprobaciones indicadas. Deténgase tras esta comparación acotada; conserve los registros de fallo si el arranque agota el tiempo o falla una comprobación. Un lanzamiento directo resuelto que siga sin producir el informe refuta que esta corrección sea suficiente localmente. Limite el intento al tiempo ya establecido y revise el resultado antes de otra intervención.

Este resultado local secuencial respalda esa hipótesis correctiva. No establece fiabilidad universal del arranque, una mejora causal del rendimiento ni estabilidad de un ensamblado C#. La aceptación humana sigue en `null`; la asistencia sobre las fuentes está pendiente. El trabajo posterior necesita una nueva pregunta acotada, sin promesas de mejora infinita ni convergencia exponencial.
