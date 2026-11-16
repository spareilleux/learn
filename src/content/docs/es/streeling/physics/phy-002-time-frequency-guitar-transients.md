---
title: Elegir una representación tiempo-frecuencia para un transitorio de guitarra
description: Elegir una representación tiempo-frecuencia para un transitorio de guitarra — Física
sidebar:
  label: PHY-002 · Elegir una representación tiempo-frecuencia para un transitorio de guitarra
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/es/phy-002-time-frequency-guitar-transients.es.md
---

:::note[Streeling University]
**PHY-002** · Elegir una representación tiempo-frecuencia para un transitorio de guitarra · intermedio · 35 minutos

Generado por el departamento *Física* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/es/phy-002-time-frequency-guitar-transients.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-001](../../physics/phy-001-science-of-guitar-sound/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-audio-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Física** | Intermedio | 35 minutos | Borrador traducido por IA; revisión humana del contenido y pruebas con estudiantes pendientes

## Objetivos

Responderás una pregunta precisa de análisis de señales: **¿puede una FFT analizar una nota de guitarra cuyo espectro cambia con el tiempo, y cuándo debería un analista de GA usar una STFT o un seguimiento por ondículas?** Distinguirás la validez del cálculo de una transformada de la afirmación que permite sostener su representación, calcularás un compromiso de ventanas e interpretarás las mediciones fijadas de mi al aire dentro de sus intervalos temporales seleccionados. [PHY-001](../../physics/phy-001-science-of-guitar-sound/) presenta los armónicos; [GAS-001](../../guitar-acoustics/gas-001-open-string-audio-evidence/) trata las preguntas sobre el motor de guitarra y la escucha del fixture. Esta lección se centra en el método tiempo-frecuencia.

## 1. Una FFT global es válida, pero su espectro no sitúa los eventos

Usa el [fixture GAS-001 y su procedencia](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/README.md), fijados al commit de Demerzel [`5c49674`](https://github.com/GuitarAlchemist/Demerzel/tree/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001). Ambos WAV son archivos mono de cuatro segundos a 44,100 Hz. El primer inicio de nota de la grabación está aproximadamente a **1.1 segundos** del archivo, y se produce otro ataque cerca de **2.75 segundos**. La nota renderizada por GA empieza en el tiempo cero del archivo. Los eventos tienen distribuciones distintas, aunque ambos archivos estén etiquetados como mi2 al aire.

Una transformada discreta de Fourier puede calcularse sobre **cualquier señal muestreada de duración finita**, incluida una no estacionaria. No exige que la guitarra mantenga un espectro constante. El problema está en la interpretación: un espectro de magnitud de los cuatro segundos reúne el tramo inicial de poco nivel, los ataques y los decaimientos. Un bin intenso de 165 Hz no diría qué ataque aportó esa energía. La transformada compleja completa conserva la fase y puede invertirse; es la **representación única y global de magnitud** la que carece de un eje temporal para responder a la pregunta sobre los eventos. Un fragmento de cuatro segundos da un espaciado nominal entre bins de frecuencia de `1/4 = 0.25 Hz` antes de añadir ceros, pero un espaciado fino no recupera los marcadores temporales que faltan.

### Ejercicio práctico 1

Un analista afirma: «El mi2 grabado cambia con el tiempo, así que aplicar una FFT es matemáticamente inválido». Corrige la afirmación y nombra la limitación real de un único espectro de magnitud del archivo completo en este caso.

> **Respuesta:** La FFT es válida sobre la grabación muestreada. Su espectro de magnitud del archivo completo combina el tramo inicial de poco nivel, la primera nota y el ataque posterior sin indicar cuándo apareció cada componente. No puede responder si un parcial pertenece al primer ataque o al posterior. Usa una ventana temporal seleccionada o una transformada con resolución temporal para esa pregunta.

## 2. Elegir la ventana según la pregunta

El [script de medición](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measure-pair.py) fijado elige un inicio aproximado para cada archivo y calcula una **FFT de un segundo con ventana de Hann, desde 0.2 hasta 1.2 segundos después de ese inicio**. Por tanto, la FFT de la grabación analiza aproximadamente los tiempos **1.3–2.3 segundos** del archivo, mientras que el render usa **0.2–1.2 segundos**. El segundo ataque grabado, cerca de 2.75 segundos, queda fuera del intervalo espectral elegido. A 44,100 Hz, la ventana de un segundo contiene 44,100 muestras y los bins de su FFT sin añadir ceros están separados **1 Hz**. Una ventana de Hann reduce la fuga espectral en los bordes, pero ensancha los picos; el espaciado de bins por sí solo no garantiza que se resuelvan dos tonos cercanos.

La nueva ejecución de `measure-pair.py` reprodujo las [mediciones](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measurements.json) guardadas: el pico local del primer parcial fue de **83 Hz** en la grabación y de **82 Hz** en el render. Son bins seleccionados dentro de la búsqueda del script de ±8 Hz alrededor del objetivo mi2 de 82.4069 Hz. Los números describen esta ventana y esta regla de selección de picos. No establecen que las dos fuentes tengan una diferencia de altura de un hercio. Cambiar el marcador de inicio o la ventana puede cambiar el espectro local de una nota no estacionaria.

### Ejercicio práctico 2

¿Qué intervalo del archivo grabado usa la FFT de un segundo guardada, y por qué el intervalo 0.2–1.2 segundos del archivo respondería a otra pregunta? Calcula el espaciado nominal de sus bins sin añadir ceros.

> **Respuesta:** Usa aproximadamente 1.3–2.3 segundos del archivo: el inicio 1.1 más 0.2–1.2 segundos. El intervalo 0.2–1.2 del archivo incluye sobre todo el tramo anterior a la nota y solo el comienzo de esta. Una FFT de un segundo y 44,100 muestras tiene bins separados `44,100 / 44,100 = 1 Hz`. Ese espaciado de la cuadrícula no certifica por sí solo una capacidad de resolución de un hercio.

## 3. La STFT intercambia detalle espectral por localización temporal de eventos

Una transformada de Fourier de tiempo corto (STFT) repite una FFT con ventana en instantes sucesivos. La [documentación de `ShortTimeFFT` de SciPy](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.ShortTimeFFT.html) describe la ventana y el salto: la ventana establece el tramo de muestras que contribuye a cada espectro; el salto establece cada cuánto se producen los espectros. La salida tiene ejes de tiempo y frecuencia. Un salto menor produce más columnas solapadas, **no** una ventana de análisis más estrecha ni una resolución frecuencial adicional independiente.

Considera una ventana de Hann de 50 ms **propuesta** para inspeccionar los ataques de los archivos GAS-001. A 44,100 Hz son 2,205 muestras, con una cuadrícula de bins sin añadir ceros de `1/0.05 = 20 Hz`. Localiza los cambios en el tiempo con mucha más precisión que la FFT de un segundo guardada, pero ofrece una cuadrícula de frecuencia mucho más gruesa y picos espectrales más anchos. Una ventana móvil de un segundo conserva la cuadrícula más fina, pero extiende un ataque breve por aproximadamente un segundo de contexto. Es un compromiso tiempo-frecuencia, no una clasificación de las herramientas. El fixture real **no** guardó una STFT; los ajustes de 50 ms y la comparación son un ejercicio de diseño, no una salida medida.

Como comprobación posterior útil, inspecciona los dos inicios en la forma de onda, calcula una STFT con ventana y salto declarados y compara sus marcadores temporales con la FFT de un segundo seleccionada. Conserva los mismos hashes de WAV y la misma convención de inicio. Si el segundo ataque aparece en la representación con ventanas, pero no en el intervalo reservado a la primera nota, las representaciones responden a preguntas distintas, tal como se pretendía.

### Ejercicio práctico 3

¿Cuántas muestras y qué espaciado nominal de bins tiene una ventana STFT de 50 ms, sin añadir ceros, a 44,100 Hz? ¿Cambiar solo el salto de 25 ms a 5 ms facilitaría resolver dos parciales cercanos en cada columna?

> **Respuesta:** `0.05 × 44,100 = 2,205` muestras y `1/0.05 = 20 Hz` de espaciado nominal de bins. Un salto de 5 ms crea más columnas temporales solapadas; no cambia las muestras de los 50 ms de cada columna ni su discriminación frecuencial intrínseca. Usa una ventana más larga para mejorar la separación de frecuencias cercanas, aceptando una localización temporal menos precisa.

## 4. Un seguimiento por ondículas adapta su duración a la frecuencia

El script del fixture también calcula **seguimientos mediante ondículas complejas de tipo Morlet** en frecuencias centrales seleccionadas cerca de **82.41, 164.81 y 329.63 Hz**. Elige una anchura mediante `sigma = 6/(2π × center_hz)`, por lo que un seguimiento de menor frecuencia abarca más tiempo que uno de mayor frecuencia. De ahí procede su escala temporal dependiente de la frecuencia. La [guía de ondículas continuas de PyWavelets](https://pywavelets.readthedocs.io/en/latest/ref/cwt.html) explica la relación general entre escala y frecuencia; GAS-001 usa su propio núcleo explícito de convolución, no `pywt.cwt`.

El artefacto guardado indica un cambio de nivel del segundo parcial desde **0.2–0.4** hasta **1.0–1.2 segundos después del inicio seleccionado** de **−4.5 dB** en la grabación y de **−12.9 dB** en el render. Con este núcleo y estos intervalos, el seguimiento del segundo parcial del render presenta un cambio tardío menos temprano **8.4 dB más negativo**. Una FFT local de un segundo puede indicar un nivel del segundo parcial promediado sobre su intervalo, pero por sí sola no puede indicar este cambio entre dos subintervalos. Las cifras de ondículas son relaciones dentro de cada archivo; no comparan sonoridad absoluta ni calidad de sonido.

Las ondículas no evitan el compromiso tiempo-frecuencia. Una ondícula más amplia de baja frecuencia puede difuminar un inicio rápido; una de mayor frecuencia con un soporte temporal más corto tiene un ancho de banda frecuencial absoluto mayor. Importan la elección de frecuencias centrales, la anchura, los límites y el inicio aproximado. Este seguimiento de tres frecuencias tampoco puede describir todas las componentes espectrales. Para otra pregunta puede ser preferible una STFT dirigida o un ajuste distinto de ondículas.

### Ejercicio práctico 4

Calcula la diferencia entre los dos cambios guardados tardíos menos tempranos del segundo parcial. ¿Qué permite establecer esa diferencia y qué no permite establecer?

> **Respuesta:** `−12.9 − (−4.5) = −8.4 dB`: el segundo parcial seguido del render cayó 8.4 dB más con el método guardado. Esto establece una diferencia en estas envolventes de ondículas e intervalos elegidos dentro de cada archivo. No establece un error de altura, una diferencia de volumen global, un parámetro causal del motor ni realismo percibido.

## 5. Asociar un método a una afirmación refutable

Para este fixture, usa la FFT local para la pregunta «¿Qué picos son intensos durante el intervalo seleccionado de la primera nota?». Usa la STFT cuando la pregunta sea «¿Cuándo cambia la energía espectral a lo largo de los dos ataques?». Usa los seguimientos por ondículas guardados cuando la pregunta sea «¿Cómo cambian las envolventes de estos tres parciales elegidos después del inicio alineado?». Conserva la ventana, el salto o la anchura de la ondícula, el marcador de inicio, la frecuencia de muestreo y los hashes de los archivos con cada resultado. Cambia una sola decisión de análisis cada vez y muestra si la conclusión se mantiene.

Un ejercicio refutable para una ejecución posterior es el siguiente: con el inicio grabado situado cerca de 1.1 segundos, una representación con resolución temporal debería distinguir el ataque posterior, cerca de 2.75 segundos, del intervalo de la primera nota. Si una medida presentada como exclusiva de la primera nota incluye el ataque posterior, inspecciona sus límites temporales y rechaza esa afirmación. Es una comprobación del alcance del análisis, no un veredicto de escucha ni sobre el motor.

### Ejercicio práctico 5

Un compañero muestra los picos guardados de 83 Hz y 82 Hz y afirma: «La grabación y el render difieren exactamente 1 Hz a lo largo de ambos clips completos de cuatro segundos». ¿Cuál es la afirmación más sólida que respaldan los datos y qué comprobación con resolución temporal pondría a prueba la afirmación más amplia?

> **Respuesta:** Bajo la búsqueda de picos guardada, de un segundo, alineada al inicio y con ventana de Hann, los bins seleccionados fueron 83 Hz y 82 Hz. El análisis no estimó la altura a lo largo de ambos clips completos. Calcula estimaciones locales repetidas con una resolución declarada adecuada para comprobar una diferencia de 1 Hz, etiqueta cada intervalo temporal e inspecciona la primera nota por separado del ataque posterior grabado. Una estimación con resolución suficiente que mostrara otra diferencia refutaría la afirmación «a lo largo de ambos clips completos»; una diferencia sin resolver en una ventana gruesa la dejaría sin verificar.

## Fuentes y límites

Los WAV, el script y el JSON están fijados al commit de Demerzel `5c4967454ddc740ed937c87719ca4d71a3522e4b`; el código Rust del render de GA está fijado por separado al commit de GA [`dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs). Volví a ejecutar el script de medición Python versionado sobre los WAV versionados y coincidieron sus valores guardados y los hashes de los archivos. Los marcadores de inicio son aproximados, la etiqueta de la fuente grabada procede de los metadatos del conjunto de datos, y el render es una compilación nativa en lugar de una captura del navegador. No se midió ninguna salida STFT para esta lección. La documentación de SciPy y PyWavelets respalda las descripciones de los métodos, mientras que las comparaciones numéricas proceden únicamente del fixture fijado. Siguen pendientes la revisión humana del contenido, las pruebas con estudiantes, la revisión lingüística y la publicación.
