---
title: Distinguir los batimientos de un cambio de amortiguamiento
description: Distinguir los batimientos de un cambio de amortiguamiento — Acústica de la guitarra y síntesis sonora
sidebar:
  label: GAS-008 · Distinguir los batimientos de un cambio de amortiguamiento
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/es/gas-008-separate-beating-from-a-change-in-damping.es.md
---

:::note[Streeling University]
**GAS-008** · Distinguir los batimientos de un cambio de amortiguamiento · intermedio · 45 minutos

Generado por el departamento *Acústica de la guitarra y síntesis sonora* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/es/gas-008-separate-beating-from-a-change-in-damping.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAS-004](../../guitar-acoustics/gas-004-run-open-e-decay-candidate/), [GAS-007](../../guitar-acoustics/gas-007-distinguish-body-poles-from-string-partials/)
:::

> **Alcance del borrador.** Cálculos didácticos y lectura del código en una revisión fijada. Siguen pendientes las revisiones humanas técnicas, musicales, lingüísticas por personas que dominen el idioma y pedagógicas con estudiantes, así como la verificación del HTML del curso desplegado. No se capturó ninguna grabación nueva, renderizado del motor ni flujo de trabajo de [ComfyUI](https://docs.comfy.org/).

## La pregunta del proyecto

El candidato de decaimiento de guitarra de [GAS-004](../../guitar-acoustics/gas-004-run-open-e-decay-candidate/) no cumplió el criterio de mejora conservado. Un tramo ascendente de la envolvente de una forma de onda podría tentar a un agente a diagnosticar amortiguamiento negativo. Esta lección construye un contraejemplo; no diagnostica aquel renderizado anterior. [GAS-007](../../guitar-acoustics/gas-007-distinguish-body-poles-from-string-partials/) distingue los parciales de cuerda de las secciones del cuerpo del instrumento. Aquí separamos la interferencia del amortiguamiento de las componentes.

## 1. Dos componentes decrecientes pueden producir una suma con batimientos

El [cálculo fijado](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/beating-envelope.json) define el tiempo en segundos:

```text
x(t) = .25*exp(-t)*(cos(2*pi*100*t) + cos(2*pi*102*t))
     = .5*exp(-t)*cos(2*pi*101*t)*cos(2*pi*t)
E(t) = .5*exp(-t)*abs(cos(2*pi*t))
```

La identidad del producto de cosenos da una envolvente algebraica de modulación E. No es una envolvente medida ni una estimación mediante la transformada de Hilbert. La amplitud de cada componente es .25 por exp(-t), con una tasa de amortiguamiento de 1 por segundo. La [relación de batimientos](https://openstax.org/books/university-physics-volume-1/pages/17-6-beats) da una frecuencia de batimiento de 2 Hz: la modulación en valor absoluto se repite cada .5 segundos. La frecuencia media portadora es 101 Hz. No se modela ningún umbral de escucha ni cuerpo real de guitarra.

### Ejercicio 1 — Nombrar las magnitudes

Deduza el producto y explique por qué la frecuencia de batimiento es 2 Hz aunque el coseno de modulación con signo tenga frecuencia 1 Hz.

> **Respuesta:** Las frecuencias media y de semidiferencia son 101 y 1 Hz. El factor de modulación no amortiguado en valor absoluto se repite dos veces por segundo; E también contiene la exponencial decreciente y no es periódica. Ambas tasas de amortiguamiento de las componentes siguen siendo 1 por segundo; ni la frecuencia portadora ni la de batimiento es un coeficiente de amortiguamiento.

## 2. Una pendiente en un intervalo corto puede tener el signo incorrecto

Entre t = .2 y t = .4, el cociente calculado de la envolvente es aproximadamente 2.143464939. Un ajuste ingenuo entre los extremos da:

```text
alpha_apparent = -ln(E(.4)/E(.2))/.2
               = -3.812118251 per second
```

La modulación se recupera de la interferencia destructiva. Esto no aporta energía a ninguna componente ni cambia su amortiguamiento positivo.

### Ejercicio 2 — Rechazar un diagnóstico falso

¿La tasa aparente negativa demuestra que el resonador es inestable? Indique qué supuesto de un ajuste exponencial único entre extremos falla.

> **Respuesta:** No. La envolvente total de modulación no es una sola exponencial en este intervalo: su factor coseno también cambia. El cociente y la tasa negativa ajustada son correctos para los extremos elegidos, pero atribuirlos solo al amortiguamiento de las componentes carece de fundamento. Las componentes didácticas siguen teniendo una tasa positiva de amortiguamiento de 1 por segundo.

## 3. Comparar en la misma fase del batimiento

En t = 0 y t = .5, el factor coseno en valor absoluto es el mismo. El cociente de amplitudes es exp(-.5), aproximadamente .606530660; el cociente de envolventes al cuadrado es exp(-1), aproximadamente .367879441. La tasa de amortiguamiento de amplitud inferida es 1 por segundo.

No se afirma que estos dos instantes sean máximos locales de la envolvente. Multiplicar por una exponencial decreciente desplaza los máximos de la envolvente combinada respecto de los extremos de la modulación no amortiguada.

### Ejercicio 3 — Separar amplitud y amplitud al cuadrado

Recupere la tasa de amortiguamiento a partir del cociente de amplitudes a igual fase durante .5 segundos. ¿Qué cambia si se utiliza en su lugar el cociente de envolventes al cuadrado?

> **Respuesta:** El negativo del logaritmo de exp(-.5), dividido entre .5, es 1 por segundo. Aplicar esa misma fórmula de amplitud a exp(-1) da 2 por segundo. Elevar al cuadrado duplica la tasa logarítmica de decaimiento; no duplica el amortiguamiento de amplitud de las componentes. Una interpretación energética exigiría un modelo físico apropiado, no solo elevar una envolvente al cuadrado.

## 4. Los ceros no son observaciones logarítmicas

En t = .25 y .75, E es analíticamente cero. El registro distingue los ceros exactos de modulación del residuo de evaluación en coma flotante. El logaritmo no está definido allí. Un suelo numérico introduciría una decisión de análisis, no revelaría un amortiguamiento medido infinito. La forma de onda bruta también se anula cuando se anula el coseno portador; no todos sus ceros identifican ceros de envolvente.

### Ejercicio 4 — Decidir qué conservar

Un agente sustituye todos los ceros por una constante pequeña e informa de una pendiente finita de decaimiento. ¿Qué debe declarar su informe?

> **Respuesta:** Debe conservar el estado de cero, el valor del suelo, las muestras afectadas y la regla de ajuste. La pendiente resultante depende de esa regla y no es una tasa observada de amortiguamiento de las componentes. Los cruces por cero de la portadora y los ceros de modulación deben mantenerse separados. Rechace un logaritmo de extremo en un cero exacto de la envolvente en vez de tratar silenciosamente el redondeo como señal.

## 5. Volver al motor con una comparación refutable

El [motor de GA](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs) en la revisión fijada suma voces, procesa secciones compartidas del cuerpo del instrumento y reverberación, y después limita la salida. Sus frecuencias del cuerpo y su etapa no lineal de salida no son esta pareja didáctica de tonos. Las [observaciones del código](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/source-observations.json) separan esta lectura del código de la ejecución nativa/Wasm anterior conservada. El antiguo criterio de decaimiento incumplido sigue sin cumplirse.

### Ejercicio 5 — Preparar un próximo experimento real

Con ayuda del código, proponga evidencia que permita distinguir la interferencia de un cambio de amortiguamiento. ¿Qué invalidaría la conclusión?

> **Respuesta:** Conserve la revisión del código, la frecuencia de muestreo, la excitación, el límite de señal seleccionado, las ventanas, la fase, los filtros, el estado de recorte y la incertidumbre. Compare las componentes aisladas o un ajuste multicomponente validado con la señal combinada antes de atribuir una pendiente de envolvente al amortiguamiento. Una mezcla cambiante, una salida recortada, componentes no resueltas o un ajuste deficiente del modelo invalidan esa atribución. Compare primero el análisis directo con el procedimiento de decaimiento existente; un DSL o agente nuevo no mejora por sí solo la evidencia. Aquí no se ejecutó ningún experimento de ese tipo.

## Trabajo que debe entregar el estudiante

Complete la [tarea con ayuda de las fuentes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/learner-task.md) y conserve los cálculos, las ubicaciones en el código y la ayuda recibida. La [rúbrica preparada](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/reviewer-rubric.json) no es un resultado real de un estudiante. Continúe con [AUD-009](../../audio-engineering/aud-009-declare-alignment-before-a-null-test/) para separar las transformaciones de comparación de la identidad de la señal original.
