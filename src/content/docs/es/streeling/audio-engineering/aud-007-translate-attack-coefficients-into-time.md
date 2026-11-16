---
title: Traducir los coeficientes de ataque a duraciones
description: Traducir los coeficientes de ataque a duraciones — Ingeniería de audio
sidebar:
  label: AUD-007 · Traducir los coeficientes de ataque a duraciones
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/es/aud-007-translate-attack-coefficients-into-time.es.md
---

:::note[Streeling University]
**AUD-007** · Traducir los coeficientes de ataque a duraciones · intermedio · 40 minutos

Generado por el departamento *Ingeniería de audio* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/es/aud-007-translate-attack-coefficients-into-time.es.md) · [Mi diario](../../journal/)

Requisitos previos: [AUD-005](../../audio-engineering/aud-005-pcm-guards-and-format-boundaries/), [GAS-002](../../guitar-acoustics/gas-002-brightness-control-and-evaluation-gate/)
:::

> **Alcance del borrador.** Código público fijado a una revisión y cálculos aislados de envolvente en aritmética real. Quedan pendientes las revisiones humanas técnica, lingüística, musical y de estudiantes, así como la verificación del HTML del curso desplegado. No se realizaron un nuevo renderizado nativo/WASM, una captura de navegador ni un procesamiento con [ComfyUI](https://docs.comfy.org/).

## La pregunta del proyecto

Se copia un coeficiente de una configuración de audio a otra. ¿Dura el ataque el mismo número de milisegundos? La respuesta depende de qué multiplica el código y qué reloj lo hace avanzar. Inspeccionamos el commit de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`; no se sustituyen silenciosamente perfiles de casos de prueba anteriores por esta revisión.

## 1. Rastrear el coeficiente efectivo

El [constructor y la selección de perfil](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L184-L260) inicializan primero el decaimiento del ataque en 0.988 y después llaman al perfil 0, que escribe 0.986. La [ruta de renderizado por voz](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L426-L478) calcula `r=clamp(base_attack_decay-0.004*f_norm,0.97,0.993)`. La normalización de frecuencia sube de 0 a 82 Hz a 1 a 330 Hz.

Para el punto de referencia didáctico de 82 Hz, velocidad de pulsación 1 y perfil 0, el nivel inicial de ataque es 0.06 y r es 0.986. El punto de referencia es exactamente 82 Hz; no es el valor E2 más preciso de 82.4069 Hz usado en casos de prueba de audio anteriores. La [tabla de envolvente fijada](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pluck-coordinates-2026-10-22/attack-clock.json) conserva ambas frecuencias por separado.

### Ejercicio 1: seleccionar el valor inicial real

Un agente lee el 0.988 del constructor y lo llama multiplicador efectivo de ataque a 82 Hz del perfil 0. ¿Qué lo sobrescribe? Da los valores de base y efectivo correctos para este punto de referencia. ¿Cuánto vale r a 330 Hz?

> **Respuesta:** La selección de perfil sobrescribe el campo del constructor con 0.986. En el punto de referencia de 82 Hz, la normalización de frecuencia es 0, así que los multiplicadores de base y efectivo son ambos 0.986. A 330 Hz, la normalización es 1 y el multiplicador efectivo es 0.982 tras restar 0.004. Ningún resultado es un decaimiento de audio observado.

## 2. Convertir actualizaciones en segundos

Mientras la voz esté activa y el nivel de ataque supere su umbral, el código lo multiplica una vez por muestra de salida. En el modelo aislado de aritmética real, `A[n]=A0*r^n`, donde n cuenta las multiplicaciones completadas y `A[0]` es el estado inicial. Para r positivo menor que 1, la constante de tiempo exacta de la extensión continua es `tau=-1/(Fs*ln(r))` segundos. Esto se deriva de la [demostración de la constante de tiempo de un polo](https://www.dsprelated.com/freebooks/filters/Time_Constant_One_Pole.html).

Para r 0.986, tau es aproximadamente 1.6083309868956657 ms a 44100 muestras por segundo y 1.4776540942103929 ms a 48000. Una constante de tiempo significa un factor de amplitud `1/e`; no es el tiempo hasta el silencio, un tiempo de decaimiento de 60 dB ni la duración del sonido completo de la guitarra. La señal de ruido, la realimentación de la cuerda, el cuerpo y la reverberación tienen otros estados.

### Ejercicio 2: comparar relojes

Mantén r en 0.986 y cambia la frecuencia de muestreo de 44100 a 48000. ¿Qué constante de tiempo es más corta y por qué? ¿Predice este cálculo la duración de toda la nota renderizada?

> **Respuesta:** El caso de 48000 es más corto: aproximadamente 1.4776540942103929 ms frente a 1.6083309868956657 ms. Se realizan más multiplicaciones por segundo con el mismo multiplicador por muestra. El cálculo describe solo el estado aislado de ataque, así que no predice la duración de la nota completa, la respuesta del cuerpo ni la reverberación.

## 3. Respetar el umbral de parada del código

La [rama de ataque](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L467-L478) se ejecuta solo mientras el estado actual supere `1e-3`. Para A0 0.06 y r 0.986, el primer entero n con `A0*r^n<=1e-3` es 291. Después de 290 actualizaciones es aproximadamente 0.0010056725203252386; después de 291 es aproximadamente 0.0009915931050406854. Las contribuciones de esta traza aislada usan estados anteriores a la actualización con índices de 0 a 290 y después se detiene la rama.

Esas 291 actualizaciones de muestra ocupan aproximadamente 6.598639455782313 ms a 44100 y 6.0625 ms a 48000. El código conserva el estado tras el cruce; no sigue multiplicándolo hacia cero en esta rama. Su condición de desactivación de voz también requiere un nivel de ataque inferior a `5e-5`, que este valor conservado no satisface. Es una cuestión del ciclo de vida derivada del código para la ruta seleccionada, conservada en el [registro de observaciones](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pluck-coordinates-2026-10-22/source-observations.json). No se afirma una reproducción en ejecución, un efecto sobre la CPU ni una corrección de producción.

### Ejercicio 3: contar la última actualización

¿Cuántas contribuciones de ataque preceden a la parada por umbral en la traza aislada? ¿Es cero el estado conservado? ¿Puede su valor conservado satisfacer la parte del nivel de ataque de la comprobación de desactivación de voz inspeccionada?

> **Respuesta:** Hay 291 contribuciones que usan índices de 0 a 290, cada una seguida de una actualización. El estado conservado es aproximadamente 0.0009915931050406854, no cero. Está por encima de `5e-5`, así que no satisface esa parte de la condición de desactivación. Este razonamiento de código y modelo no es un fallo reproducido en ejecución ni una prueba sobre todas las rutas del ciclo de vida.

## 4. Traducir deliberadamente una duración objetivo

Para conservar esta constante de tiempo aislada, establece `r_new=r_old^(Fs_old/Fs_new)`. Traducir r efectivo 0.986 de 44100 a 48000 da aproximadamente 0.9871301472688642. Eso cambia deliberadamente el multiplicador para conservar los milisegundos. No conserva automáticamente el mismo número entero de actualizaciones hasta el umbral, porque el cruce final se redondea a actualizaciones de muestra.

La traducción afecta al coeficiente efectivo. En otras frecuencias, el código resta su término dependiente de la frecuencia y vuelve a limitar; copiar este número a un método de ajuste de base no constituye automáticamente una compensación general. La selección de perfil también puede sobrescribir un ajuste. Un cambio de todo el motor necesitaría una política definida, pruebas en varias frecuencias y velocidades de pulsación y comprobaciones de todos los demás estados dependientes de las muestras.

### Ejercicio 4: traducir el coeficiente

¿Qué multiplicador efectivo conserva a 48000 la constante de tiempo de r 0.986 a la frecuencia de muestreo 44100? ¿Establece ese cálculo por sí solo un motor completamente invariante a la frecuencia de muestreo o un parche de producción?

> **Respuesta:** Aproximadamente 0.9871301472688642. Conserva la constante de tiempo aislada de la extensión continua bajo la fórmula indicada. La cuantización del umbral, el ajuste de frecuencia, el orden de perfiles y los demás estados de procesamiento digital de señales siguen necesitando sus propias políticas y pruebas; no se estableció invariancia de todo el motor ni un parche de producción.

## 5. Seguir el reloj del anfitrión hasta la prueba

El [puente de Web Audio](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/src/audio/audioEngine.js#L14-L35) pasa `audioContext.sampleRate` en su mensaje de inicialización. El [worklet](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/src/audio/guitar-worklet.js#L11-L30) reenvía la frecuencia numérica proporcionada a la inicialización del motor, con la frecuencia del anfitrión como alternativa. La [especificación de Web Audio](https://www.w3.org/TR/webaudio/#dom-baseaudiocontext-samplerate) define la propiedad de frecuencia de muestreo del contexto. Estas lecturas del código no observan la frecuencia actual ni una captura de un navegador en funcionamiento.

Un ensayo futuro debería registrar la frecuencia real del contexto, el estado de inicialización, el perfil seleccionado, el orden de los ajustes, los parámetros de nota, el formato bruto de muestras y la identidad de la salida. Compara las trazas de estado de ataque por separado de la forma de onda completa; la señal estocástica no es una envolvente exponencial positiva. Si se remuestrea un candidato de ComfyUI fuera de línea, conserva esa conversión y compara las ventanas de tiempo físico previstas. Su existencia no cambia la semántica de los coeficientes del motor.

### Ejercicio 5: redactar la siguiente comprobación

Un informe dice «mismo ajuste de decaimiento, mismo tiempo de ataque», pero omite la frecuencia de muestreo y el orden de perfiles. Indica las pruebas ausentes y un control negativo útil. ¿Se ha realizado aquí una comparación de navegador a dos frecuencias?

> **Respuesta:** Registra la frecuencia real de muestreo del anfitrión, la inicialización correcta, el perfil y el orden de los ajustes, el coeficiente efectivo dependiente de la frecuencia, nota y velocidad de pulsación, formato de muestras e identidad de la salida. Un cálculo de envolvente de r fijo a dos frecuencias es un control negativo porque debe cambiar los milisegundos; una traducción que conserve duración debería mantener la constante de tiempo aislada indicada. Aquí no se realizó una captura de navegador a dos frecuencias ni una comparación perceptiva.
