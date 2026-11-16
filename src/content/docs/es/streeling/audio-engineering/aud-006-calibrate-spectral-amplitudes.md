---
title: Calibrar una amplitud espectral antes de comparar renderizados
description: Calibrar una amplitud espectral antes de comparar renderizados — Ingeniería de audio
sidebar:
  label: AUD-006 · Calibrar una amplitud espectral antes de comparar renderizados
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/es/aud-006-calibrate-spectral-amplitudes.es.md
---

:::note[Streeling University]
**AUD-006** · Calibrar una amplitud espectral antes de comparar renderizados · intermedio · 35 minutos

Generado por el departamento *Ingeniería de audio* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/es/aud-006-calibrate-spectral-amplitudes.es.md) · [Mi diario](../../journal/)

Requisitos previos: [AUD-003](../../audio-engineering/aud-003-transient-preservation-gate/), [AUD-005](../../audio-engineering/aud-005-pcm-guards-and-format-boundaries/)
:::

> **Alcance del borrador.** Nuevo análisis numérico de archivos WAV de guitarra conservados y señales de calibración construidas. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML público del curso. El análisis no ejecutó ningún binario de IX ni generó nuevo audio de guitarra.

## La pregunta del proyecto

Un analista de audio de GA duplica una ventana de análisis y observa un pico espectral más fuerte. ¿Ha aumentado el volumen de la guitarra o ha cambiado la medición? Antes de incorporar un valor espectral a un ciclo de mejora, asígnele una referencia y pruébelo con una señal de amplitud conocida. Esta lección desarrolla esa calibración; [AUD-003](../../audio-engineering/aud-003-transient-preservation-gate/) aborda la ubicación de transitorios y la reducción de ruido.

La [implementación del espectrograma de IX en la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L32-L54) toma las magnitudes de las transformadas con ventana. Con su opción logarítmica aplica `20*log10(max(magnitude,1e-10))`. La [implementación de la ventana](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/window.rs#L10-L15) utiliza una Hann simétrica. Ninguno de los pasos divide por la suma de la ventana. La inspección del código fuente establece esa fórmula; no establece ningún resultado de un servicio IX en ejecución.

Lea las [mediciones de calibración](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/spectral-views-2026-10-22/calibration.json) y el [registro del análisis](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/spectral-views-2026-10-22/execution.json). El análisis temporal utilizó la [FFT de NumPy para entradas reales](https://numpy.org/doc/stable/reference/generated/numpy.fft.rfft.html) con una transformada directa sin escalado y su [ventana Hann simétrica](https://numpy.org/doc/stable/reference/generated/numpy.hanning.html). Las versiones de los paquetes instalados figuran en el registro; la documentación actual puede describir una versión más reciente.

## 1. Mantener fija la entrada física al cambiar el análisis

El coseno construido tiene una amplitud de pico de 0.25 y una frecuencia de 689.0625 Hz, con una frecuencia de muestreo de 44100 Hz. Se sitúa en el índice frecuencial 32 para una ventana de longitud 2048 y en el índice 64 para una longitud de 4096. Por tanto, ambos casos analizan un número entero de ciclos. La Hann simétrica es `w[n] = 0.5 - 0.5*cos(2*pi*n/(N-1))`; su suma es aproximadamente 1023.5 y 2047.5 en estos casos.

| Longitud de ventana | Índice del tono | Magnitud bruta | Estimación de amplitud de pico |
|---|---|---|---|
| 2048 | 32 | 127.9375151793639 | 0.25000002966167834 |
| 4096 | 64 | 255.93750379229243 | 0.25000000370431497 |

La diferencia entre las magnitudes brutas expresadas en dB es de unos 6.02272037 dB. Esa diferencia se debe al cambio en la ganancia del análisis. No demuestra un cambio de ganancia en la entrada construida. El pequeño error residual tras la normalización procede de este cálculo con una ventana simétrica finita; no lo redondee para afirmar una igualdad exacta.

### Ejercicio 1: diagnosticar la mejora aparente

Un agente describe la segunda fila como una guitarra aproximadamente 6 dB más fuerte. ¿Qué permaneció fijo, qué cambió y qué resultado cuestiona esa interpretación?

> **Respuesta:** La amplitud de pico de 0.25, la frecuencia de 689.0625 Hz y la frecuencia de muestreo de 44100 Hz permanecieron fijas. La longitud de ventana cambió de 2048 a 4096, lo que modificó la ganancia asociada a la suma de sus coeficientes. Ambas estimaciones normalizadas recuperan aproximadamente 0.25, mientras que las magnitudes brutas casi se duplican. La diferencia de unos 6 dB describe este cambio en la medición, no un nuevo renderizado de guitarra ni una entrada más fuerte.

## 2. Indicar qué amplitud estima la fórmula

Para un coseno real aislado cuya frecuencia coincide con un índice interior de la transformada, utilice `A[k] = 2*abs(X[k])/sum(w)`. El coseno real tiene contribuciones de frecuencia positiva y negativa; conservar un solo lado exige el factor 2 para esta estimación de amplitud. Las pruebas recuperan la amplitud de pico declarada con una tolerancia absoluta de `1e-6`. También se comprobaron valores complejos seleccionados de la transformada mediante suma directa con una tolerancia absoluta de `1e-10`, en lugar de comprobar solo una etiqueta redondeada del gráfico.

Para una referencia de amplitud de 1, la estimación logarítmica es `20*log10(A/1)`. Una amplitud de pico de 0.25 equivale a unos -12.0412 dB respecto a esa referencia de pico unitaria. Esta fórmula describe la amplitud de pico bajo un estimador declarado de transformada y ventana. No estima el valor eficaz, la sonoridad, la potencia de banda ancha integrada ni la densidad espectral de potencia. Los parciales de guitarra próximos entre sí y las componentes entre índices frecuenciales necesitan análisis adicional antes de que un valor de un solo índice pueda representar la amplitud de un parcial individual.

### Ejercicio 2: recuperar la amplitud

Con la primera fila, calcule `2*127.9375151793639/1023.5`. ¿Qué valor y qué referencia logarítmica deben acompañar a la respuesta? ¿Puede etiquetarse como densidad espectral de potencia?

> **Respuesta:** La estimación es aproximadamente 0.25000003, a menos de `1e-6` de la amplitud de pico construida de 0.25. Respecto a la amplitud de pico unitaria, su valor es aproximadamente -12.0412 dB. El estimador de amplitud declarado para índices interiores no aporta ninguna normalización de potencia por hercio, de modo que la etiqueta de densidad espectral de potencia carecería de fundamento.

## 3. No duplicar los extremos

Para una longitud de transformada par, la componente continua y la frecuencia de Nyquist no se emparejan con índices distintos de frecuencia negativa conservados. Utilice `A[k] = abs(X[k])/sum(w)` en esos extremos. Los controles separados usan una constante de 0.25 y la secuencia alternante `0.25*(-1)^n`. Ambos recuperan 0.25 sin duplicar. Aplicar la regla de los índices interiores a cualquiera de los extremos daría aproximadamente 0.5, un resultado rechazado deliberadamente.

### Ejercicio 3: detectar el error en los extremos

Con longitud 2048, el control de continua tiene una magnitud bruta de 255.875 y una suma de ventana de 1023.5. Calcule la amplitud correcta y la duplicada por error. ¿Se aplicaría la misma regla de los extremos en Nyquist?

> **Respuesta:** `255.875/1023.5 = 0.25`; duplicar por error da 0.5. Nyquist también utiliza la regla de los extremos sin duplicación para esta transformada real de longitud par. Un factor 2 indiscriminado haría fallar ambos controles de calibración.

## 4. Registrar el decodificador además de la transformada

El [WAV de referencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/baseline.wav) y el [WAV candidato](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/candidate.wav) conservados son PCM16 mono, con 176400 muestras a 44100 Hz. El nuevo análisis decodifica cada entero con signo usando un denominador de 32768. El exportador anterior utilizó un multiplicador de 32767 al crear esos WAV. Son pasos diferentes con convenciones declaradas por separado; este análisis no recupera los búferes nativos de coma flotante anteriores a la cuantificación.

Los hashes de los WAV, la convención del decodificador, las celdas seleccionadas de las matrices y las coordenadas de las tramas completas figuran en el [registro de coordenadas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/spectral-views-2026-10-22/coordinates.json). Mantenga fijas esas entradas al comparar una referencia con un candidato. Cambiar el decodificador o la normalización en una sola rama confundiría la comparación.

### Ejercicio 4: distinguir las magnitudes

Un analista divide muestras PCM16 por 32768 y después etiqueta el arreglo como «las muestras flotantes nativas originales exactas porque el exportador utilizó 32767». ¿Qué debería indicar el registro en su lugar?

> **Respuesta:** Contiene muestras PCM16 cuantificadas y decodificadas con el denominador declarado de 32768. El multiplicador de exportación de 32767 describe un paso de cuantificación anterior y no revierte la pérdida de información ni identifica los flotantes originales. Conserve el hash del WAV y ambas convenciones; no afirme que este arreglo decodificado es igual al búfer nativo.

## 5. Utilizar la calibración para proteger la decisión

El [experimento de decaimiento](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/results.json) anterior mejoró su error declarado en unos 0.11416615 dB, frente a una mejora requerida de 1 dB. No superó ese criterio. Un gráfico calibrado no sustituye la medida declarada ni aporta una preferencia de escucha. [DV-009](../../data-visualization/dv-009-compare-spectrogram-color-scales/) utiliza las mismas muestras conservadas para mostrar cómo una visualización puede ocultar una diferencia real de ganancia construida.

### Ejercicio 5: decidir qué permiten aceptar las pruebas

Un agente dice que el candidato parece mejor tras cambiar la normalización de la ventana, por lo que su criterio de decaimiento fallido puede marcarse como superado. ¿Qué debe conservar, rechazar y probar a continuación el ciclo de mejora?

> **Respuesta:** Conserve el análisis calibrado con sus hashes de WAV, decodificador, ventana y referencia. Rechace modificar el veredicto registrado: aproximadamente 0.11416615 dB está por debajo del requisito de 1 dB. Si importa otra propiedad musical, declare una medida y una regla de aceptación separadas antes de una nueva comparación y después póngalas a prueba. Ni esta calibración ni una imagen aportan aprobación humana mediante escucha.

## Límites de las pruebas

El [protocolo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/spectral-views-2026-10-22/experiment-plan.md) registra predicciones y condiciones de refutación; la [verificación de las fuentes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/spectral-views-2026-10-22/primary-readback.json) distingue las comprobaciones de bytes satisfactorias de una solicitud directa de documentación que falló. Son cálculos numéricos y observaciones del código fuente. No se afirma ningún nuevo resultado de ejecución de IX, ejecución de audio en el navegador, adaptador de ComfyUI, resultado de participantes ni lanzamiento a producción.
