---
title: Distinguir los batimientos de dos tonos del decaimiento
description: Distinguir los batimientos de dos tonos del decaimiento — Física
sidebar:
  label: PHY-007 · Distinguir los batimientos de dos tonos del decaimiento
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/es/phy-007-separate-beating-from-decay.es.md
---

:::note[Streeling University]
**PHY-007** · Distinguir los batimientos de dos tonos del decaimiento · intermedio · 35 minutos

Generado por el departamento *Física* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/es/phy-007-separate-beating-from-decay.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-001](../../physics/phy-001-science-of-guitar-sound/)
:::

> **Alcance del borrador.** Señales construidas de amplitud constante, controles numéricos y medios originales. Siguen pendientes la revisión técnica humana, la revisión lingüística, los intentos de alumnos y la verificación del HTML desplegado. Esto no es una nueva renderización del motor de GA, un diagnóstico de una guitarra física ni una prueba de escucha.

## La pregunta del proyecto

Un agente de análisis de guitarra observa una caída de nivel en una ventana corta y anuncia un amortiguamiento más rápido. ¿Podría otro mecanismo producir la misma observación? La [ecuación de batimientos de OpenStax](https://openstax.org/books/university-physics-volume-1/pages/17-6-beats) se deriva de sumar dos cosenos. Usamos esa identidad matemática con señales construidas de manera independiente y ejercicios originales. No se reproduce ningún diagrama, actividad ni grabación de terceros.

Utilice las frecuencias 327.031956626 Hz y 329.627556913 Hz, construidas en [WML-004](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/). Cada componente tiene amplitud de pico fija `a=0.125`, fase inicial de coseno 0 y frecuencia de muestreo de 44100 Hz. Ningún componente pierde amplitud en el modelo matemático sin fundidos. Su suma variable ofrece un contraejemplo a la inferencia propuesta.

## 1. Deducir la suma antes de nombrar su envolvente

Escriba `x_a(t)=a*cos(2*pi*f_a*t)` y `x_b(t)=a*cos(2*pi*f_b*t)`. Su suma equivale a `2*a*cos(pi*(f_b-f_a)*t)*cos(2*pi*((f_a+f_b)/2)*t)`. La diferencia es 2.595600287 Hz y la media es 328.329756769 Hz. Una comparación numérica de las dos expresiones durante cuatro segundos se mantuvo dentro de la tolerancia absoluta declarada `1e-10`.

El modulador con signo tiene frecuencia `abs(f_b-f_a)/2`, aproximadamente 1.297800144 Hz. La envolvente **sin signo** es `2*a*abs(cos(pi*(f_b-f_a)*t))`. Sus picos se repiten a la frecuencia de diferencia, aproximadamente 2.595600287 Hz. Olvidar el valor absoluto produce un error de interpretación de un factor de dos.

### Ejercicio práctico 1: nombrar la recurrencia medida

Para estas frecuencias, calcule el período de recurrencia de la envolvente sin signo y compare la frecuencia del modulador con signo con la frecuencia de recurrencia de los picos sin signo.

> **Respuesta:** `T=1/abs(f_b-f_a)` es aproximadamente 0.385267333 segundos. La frecuencia del modulador con signo es aproximadamente 1.297800144 Hz; los picos sin signo se repiten a aproximadamente 2.595600287 Hz. Los cambios de signo invierten la fase de la portadora sin que el módulo de la amplitud sea negativo.

## 2. Una envolvente descendente puede recuperarse sin aportar energía

La envolvente sin signo comienza en 0.25, alcanza su primer cero cerca de 0.192633666 segundos y vuelve a su pico cerca de 0.385267333 segundos. La amplitud de cada componente sigue siendo 0.125. La cancelación y el refuerzo cambian la suma sin introducir amortiguamiento exponencial de los componentes.

![Cosenos construidos sin fundidos y envolvente sin signo de su suma](https://raw.githubusercontent.com/spareilleux/learn/0e1080569fb174d7867eebc9248f4fc9193aa5a8/code/streeling/evidence/intonation-listening-2026-10-22/two-tone-envelope.png)

El gráfico superior muestra los primeros 0.025 segundos del modelo sin fundidos. El inferior muestra su envolvente sin signo; las líneas de puntos marcan períodos de recurrencia sucesivos. Esta figura no representa la forma de onda del WAV exportado con fundidos en los extremos. Un cero de la envolvente matemática tampoco garantiza un RMS nulo en una ventana de duración finita.

### Ejercicio práctico 2: rechazar una conclusión de amortiguamiento sin respaldo

Un agente ajusta una recta de decaimiento solo desde el pico inicial hasta el primer mínimo de la envolvente. ¿Por qué ese intervalo no establece un amortiguamiento de los componentes en este ejemplo?

> **Respuesta:** Los dos componentes tienen amplitud constante, pero su suma se cancela cerca del primer mínimo y después se recupera. El intervalo elegido omite esa recuperación. Por tanto, el modelo ofrece un contraejemplo a identificar toda envolvente descendente con una pérdida de energía de los componentes; no diagnostica la causa de una grabación concreta de guitarra física.

## 3. Especificar la ventana y el control

El [registro de medición](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/beats.json) utiliza ventanas RMS nominales de 20 ms centradas en `T`, `1.5*T` y `2*T`. Para cada ventana, los índices de inicio y de fin exclusivo son los techos de los tiempos correspondientes multiplicados por 44100. Esta convención explícita de intervalo semiabierto evita cambiar silenciosamente las muestras incluidas.

Respecto a la primera ventana, la ventana de interferencia destructiva cae 26.357732143 dB; la ventana recuperada difiere en +0.000373071 dB. Antes de medir, el plan exigía una caída de al menos 10 dB y una recuperación a menos de 1 dB del nivel inicial. Ambos controles se cumplen. Sustituir la segunda frecuencia por la primera y conservar las mismas ventanas da un cambio de solo +0.000087429 dB donde antes estaba la caída. El muestreo finito de la portadora explica que el cociente de este control en una ventana corta no sea exactamente cero dB.

### Ejercicio práctico 3: interpretar la comparación

La ventana de interferencia destructiva está a -26.357732143 dB respecto a la primera y la ventana posterior a +0.000373071 dB. ¿Qué criterios declarados de antemano se cumplen? ¿Qué aporta el control de frecuencias iguales?

> **Respuesta:** La caída supera 10 dB y la ventana recuperada queda a menos de 1 dB de la primera, de modo que se cumplen ambos criterios. El control de frecuencias iguales no presenta esa gran caída en las mismas ventanas, lo que respalda la interferencia entre frecuencias como mecanismo de esta comparación construida. No establece el mecanismo de una grabación física sin medir.

## 4. Distinguir las señales matemáticas de los archivos de escucha

El conjunto incluye una [ilustración original de la mezcla de cuatro segundos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/two-tone-illustration.wav). Conserva las amplitudes de los componentes y aplica fundidos de 441 muestras, o 10 ms, en cada extremo. Cada fundido incluye sus extremos. Las ventanas medidas quedan fuera de esos fundidos. El WAV es PCM16 mono, mientras que las ecuaciones representadas y las ventanas RMS registradas utilizan señales en coma flotante sin fundidos.

Los archivos separados [tono A](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/tone-a.wav) y [tono B](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/tone-b.wav) duran un segundo cada uno. Su RMS en coma flotante después de los fundidos se iguala a 0.05 antes de la cuantización. Estos archivos de tonos aislados están preparados para una tarea propuesta de discriminación secuencial; la mezcla simultánea ilustra la interferencia. Ninguno de los archivos se reprodujo ni se escuchó en este análisis.

El [registro de archivos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/audio-assets.json) especifica el redondeo al par más cercano de `sample*32768`, la decodificación PCM16 con signo mediante división por 32768, los hashes y los errores de reconstrucción. El error absoluto máximo de cuantización es como mucho `0.5/32768`. Igualar numéricamente el RMS no establece una sonoridad percibida igual ni un nivel real de reproducción.

### Ejercicio práctico 4: elegir el archivo adecuado

¿Qué archivo ilustra los batimientos simultáneos y qué pareja sirve para preguntar secuencialmente cuál es el tono más agudo? ¿Demuestra la igualación RMS declarada una sonoridad percibida igual?

> **Respuesta:** La mezcla de cuatro segundos ilustra los batimientos simultáneos. Los tonos separados de un segundo sirven para la pregunta secuencial. Son estímulos y tareas diferentes. La igualación RMS en coma flotante y la verificación PCM establecen la preparación numérica; la igualdad de sonoridad percibida y la calibración de la reproducción siguen sin medirse.

## 5. Conservar el resultado fallido del motor

El anterior [conjunto de evidencias de ejecución del motor de guitarra](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/README.md) midió una mejora de 0.114166150 dB para un candidato frente a un umbral requerido de 1 dB en el decaimiento. Ese candidato falló. Un nuevo contraejemplo construido no puede cambiar las muestras anteriores, la regla ni el veredicto.

Para una futura grabación física o del motor, declare el componente o banda objetivo, la ventana de análisis y los controles antes de comparar el decaimiento. Compruebe si la recuperación de nivel, los parciales que interactúan o una ventana de medición diferente cuestionan el mecanismo propuesto. Son posibles controles de seguimiento, no una afirmación de que la interferencia causó el fallo anterior. [COG-004](../../cognitive-science/cog-004-score-a-pitch-discrimination-task/) examina por separado lo que podría establecer una puntuación de escucha.

### Ejercicio práctico 5: acotar la revisión del agente

Un agente ve la nueva simulación y cambia el candidato anterior de fallido a aprobado. ¿Qué debe decir su informe corregido?

> **Respuesta:** El candidato anterior sigue fallido: 0.114166150 dB es inferior al umbral requerido de 1 dB. El nuevo modelo de amplitud constante demuestra que una envolvente descendente en una ventana corta puede deberse a interferencias. Motiva un seguimiento controlado de las grabaciones reales; no revierte el veredicto anterior ni establece una causa física o una ventaja perceptiva.
