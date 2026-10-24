---
title: Conservar el nivel al normalizar la forma de onda
description: Conservar el nivel al normalizar la forma de onda — Teoría de la información
sidebar:
  label: INF-009 · Conservar el nivel al normalizar la forma de onda
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/es/inf-009-keep-level-when-normalizing-waveform-shape.es.md
---

:::note[Streeling University]
**INF-009** · Conservar el nivel al normalizar la forma de onda · intermedio · 45 minutos

Generado por el departamento *Teoría de la información* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/es/inf-009-keep-level-when-normalizing-waveform-shape.es.md) · [Mi diario](../../journal/)

Requisitos previos: [INF-005](../../information-theory/inf-005-quantization-and-indistinguishable-renders/), [INF-008](../../information-theory/inf-008-keep-phase-when-waveform-identity-matters/)
:::

> **Alcance del borrador.** Vectores reales didácticos y lectura del código en una revisión fijada. Siguen pendientes las revisiones humanas técnicas, musicales, lingüísticas por personas que dominen el idioma y pedagógicas con estudiantes, así como la verificación del HTML del curso desplegado. No se produjo ningún renderizado de audio nuevo, resultado perceptivo ni validación estadística.

## La pregunta del proyecto

Un agente entrega una forma normalizada y una puntuación de correlación perfecta. ¿Puede otro agente recuperar el nivel de la señal? [INF-005](../../information-theory/inf-005-quantization-and-indistinguishable-renders/) estudia la pérdida por cuantificación; [INF-008](../../information-theory/inf-008-keep-phase-when-waveform-identity-matters/) conserva la fase. Aquí los cambios de escala positivos y los desplazamientos desaparecen con la normalización centrada.

## 1. Definir el descriptor con precisión

Los [vectores fijados](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/normalized-shape.json) utilizan la desviación típica poblacional, dividiendo la varianza por el número de tramas N en vez de N-1:

```text
x = [-.25, 0, .25, .5]
y = .5*x + .25 = [.125, .25, .375, .5]
mu_x = 1/8; sigma_x = sqrt(5)/8
mu_y = 5/16; sigma_y = sqrt(5)/16
z[n] = (sample[n] - mu)/sigma
z_x = z_y = [-3, -1, 1, 3]/sqrt(5)
```

La [definición de Pearson del NIST](https://www.itl.nist.gov/div898/software/dataplot/refman2/auxillar/correlat.htm) utiliza vectores centrados. Los factores comunes de normalización se cancelan en su cociente. Aquí la correlación es 1, aunque el RMS de la diferencia bruta es aproximadamente .233853587. La correlación no es la probabilidad de que dos señales sean iguales.

### Ejercicio 1 — Identificar qué olvida el descriptor

Verifique las medias, las desviaciones típicas poblacionales y la igualdad de los vectores normalizados. ¿Una correlación de 1 implica igualdad bruta?

> **Respuesta:** Las medias son .125 y .3125. El centrado da vectores proporcionales por un factor de .5, por lo que sus desviaciones típicas son sqrt(5)/8 y sqrt(5)/16. La división produce el mismo vector normalizado. La diferencia bruta es [.375, .25, .125, 0], con RMS no nulo de aproximadamente .233853587. Por tanto, una correlación positiva perfecta no implica igualdad bruta, nivel sin cambios ni un veredicto de escucha.

## 2. Conservar los metadatos de la inversa

Para cualquier vector no constante y a positivo, centrar y normalizar a*x+b da el mismo z que x. Un descriptor limitado a la forma no puede distinguir toda esa familia. Conservar cada muestra normalizada, la media, la desviación típica y el número de tramas permite la inversa en aritmética real:

```text
sample[n] = mu + sigma*z[n]
```

Esto no demuestra que el redondeo, la serialización de flotantes, la compresión con pérdidas o un descriptor reducido conserven los bytes originales.

### Ejercicio 2 — Reparar la transferencia

¿Qué valores adicionales distinguen x de y? ¿Basta conservar solo el vector normalizado compartido y N?

> **Respuesta:** Conserve la media y la desviación típica poblacional correspondientes junto con N, cada muestra z y su orden. Los dos pares distintos de media y desviación típica reconstruyen vectores brutos diferentes. Los z y N compartidos por sí solos no pueden restaurar la escala positiva y el desplazamiento perdidos. Un vector reducido de características o un almacenamiento redondeado necesitarían su propio análisis del error de reconstrucción y del formato de bytes.

## 3. La correlación en valor absoluto también puede borrar la polaridad

Sea el vector invertido -x. Su vector normalizado es -z_x, por lo que la correlación de Pearson con signo respecto de x es -1. Aplicar el valor absoluto da 1, igual que para y. Matemáticamente, x + (-x) es el vector cero. No se observó reproducción, enrutamiento ni cancelación audible.

### Ejercicio 3 — Elegir una puntuación para la afirmación

¿Por qué la correlación en valor absoluto no es una prueba fiable de que la polaridad de la forma de onda permanezca intacta? ¿Qué debe conservarse?

> **Respuesta:** Lleva a 1 tanto las formas centradas perfectamente alineadas como las perfectamente invertidas. Conserve la correlación con signo, la política de polaridad, las muestras originales o una representación reversible y el residuo bruto. El control matemático de cancelación revela la información descartada por la puntuación absoluta. No establece equivalencia perceptiva, interferencia medida en una sala ni una probabilidad de acierto.

## 4. Las señales constantes son un caso distinto

Para [.25, .25, .25, .25], la desviación típica poblacional es cero. El vector normalizado y la correlación de Pearson con él están indefinidos, mientras que el RMS bruto es .25. Una copia idéntica aún puede satisfacer la igualdad bruta. Un estado constante separado, la media y el número de tramas pueden describir este vector sin dividir entre cero.

### Ejercicio 4 — Evitar una puntuación inventada

Un agente escribe una correlación de 1 siempre que ambas entradas son constantes. ¿Es ese el resultado definido por Pearson?

> **Respuesta:** No. El denominador se anula, por lo que Pearson está indefinido. Devuelva ese estado y compare las constantes directamente si la tarea es comprobar la igualdad. Conserve la media y N para la reconstrucción; el RMS bruto sigue siendo válido. Una aplicación puede definir otra regla para el caso constante, pero debe nombrarla en vez de presentarla como correlación de Pearson.

## 5. Anteponer los metadatos a la abstracción

El [programa de ejecución de Learn](https://github.com/spareilleux/learn/blob/49ad4cf7db680f031b3a3fb5b6ee118464ad099f/code/streeling/guitar-runtime/run.mjs) en la revisión fijada mantiene separadas las comparaciones de flotantes brutos y PCM16. Su cálculo RMS incluye un suelo numérico antes de los logaritmos. No implementa este nuevo descriptor de forma normalizada ni el de Pearson. El [registro de fuentes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/source-observations.json) distingue la inspección del código, los cálculos didácticos y la evidencia histórica de ejecuciones.

### Ejercicio 5 — Especificar una transferencia útil entre agentes

Diseñe un registro mínimo de comparación utilizando ubicaciones del código. ¿Cómo decidiría si ayuda un DSL más abstracto?

> **Respuesta:** Conserve las revisiones del código, el límite de señal, el reloj de muestreo, el orden de canales, el formato, N, la regla de normalización, la media, la desviación típica poblacional, el estado constante, la política con signo o absoluta y el nivel y el residuo brutos. Estos vectores simplificados no tienen reloj medido ni formato de audio; no invente ninguno. Localice la serialización de flotantes, la conversión PCM16 y las ventanas RMS del programa de ejecución. Compare registros explícitos con cálculos directos de muestras, incluidos controles de inversión y constantes, antes de añadir un DSL. Mida omisiones, errores y coste en tareas reales; ni una sintaxis nueva ni una puntuación perfecta de forma demuestran una mejora. Aquí no existe ningún estudio de usuarios de ese tipo ni una implementación nueva.

## Trabajo que debe entregar el estudiante

Utilice la [tarea con ayuda de las fuentes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/learner-task.md) y la [rúbrica preparada](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/reviewer-rubric.json). Conserve las respuestas reales y la ayuda recibida; la aceptación del estudiante sigue siendo null. [AUD-009](../../audio-engineering/aud-009-declare-alignment-before-a-null-test/) explicita la ganancia y la temporización eliminadas en vez de ocultarlas en una puntuación.
