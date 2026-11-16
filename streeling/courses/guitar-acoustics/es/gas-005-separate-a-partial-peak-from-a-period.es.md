---
module_id: gas-005-separate-a-partial-peak-from-a-period
department: guitar-acoustics
course: "Distinguir el pico de un parcial de un período"
level: intermediate
prerequisites: ["gas-001-open-string-audio-evidence", "aud-006-calibrate-spectral-amplitudes"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguir el pico de un parcial de un período

> **Alcance del borrador.** Nuevo análisis numérico de señales construidas y de un búfer nativo de guitarra conservado, junto con una inspección del código del motor en una revisión fijada. Siguen pendientes las revisiones humanas técnica, musical o perceptiva y lingüística, las pruebas con estudiantes y la verificación del HTML publicado. No se volvió a ejecutar el motor, WASM, el navegador, el detector IX ni la reproducción de audio.

## La pregunta del proyecto

Un agente de audio encuentra el pico espectral más alto y lo llama «la nota de guitarra». Ese atajo confunde la frecuencia de una componente, una estimación de repetición y un juicio perceptivo. Antes de usar un valor de altura para orientar el trabajo de guitarra en WASM, indique qué magnitud devuelve realmente el método.

El [motor GA en la revisión fijada](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L281-L326) almacena una frecuencia solicitada y limitada, y construye los estados de retardo entero y fraccionario. Los filtros, la dispersión y los resonadores de la caja también afectan a la salida. La entrada almacenada no es una medición de la altura generada. Esta lección aporta dos controles matemáticos y un reanálisis acotado de muestras generadas anteriormente.

## 1. Distinguir una frecuencia solicitada de una estimación

Para la solicitud nominal de 82.4069 Hz a 44100 Hz, el cálculo en números reales da una longitud de retardo entera de 535 más un resto fraccionario. La razón basada solo en el entero `44100/535` es aproximadamente 82.429906542 Hz. Describe esa razón simplificada, no la salida medida del motor. El código real utiliza interpolación fraccionaria y filtros de realimentación en lugar de un simple retardo entero.

La [vinculación a la entrada conservada](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/input-bindings.json) coincide con una ejecución anterior de referencia: 176400 muestras float32 little-endian, cuatro segundos a 44100 Hz. Se proporciona una [copia del búfer nativo idéntica byte a byte](https://raw.githubusercontent.com/spareilleux/learn/c953607dc38126877032dd5919e57d894971b257/code/streeling/evidence/pitch-estimates-2026-10-22/baseline-native.f32le) para verificarla. Este reanálisis usa esos valores de coma flotante, no el WAV cuantizado ni un nuevo renderizado. El [decodificador de búfer de NumPy](https://numpy.org/doc/stable/reference/generated/numpy.frombuffer.html) interpreta el orden de bytes declarado `<f4` antes del cálculo numérico.

### Ejercicio 1: delimitar el cálculo del retardo

¿Qué longitud entera y qué frecuencia basada solo en el retardo entero se deducen de la solicitud nominal indicada? ¿Pueden la solicitud almacenada o esa razón certificar la altura medida de la salida?

> **Respuesta:** La longitud es 535 y `44100/535` es aproximadamente 82.429906542 Hz. Ninguna certifica la altura medida. La solicitud almacenada es una entrada, mientras que la razón simplificada omite el comportamiento del retardo fraccionario y de los filtros. Estimar la forma de onda conservada es otra operación, con sus propias hipótesis y resolución.

## 2. Construir una señal cuya componente fundamental está ausente

El complejo matemático original A suma cosenos de fase cero a 1000, 1200 y 1400 Hz con amplitudes de pico de 0.3, 0.2 y 0.1. A 48000 Hz durante un segundo, estas frecuencias coinciden con casillas de transformada coherentes. La componente más fuerte es de 1000 Hz, pero la forma de onda continua completa se repite cada `1/200` segundos: las componentes son los armónicos quinto, sexto y séptimo de 200 Hz. No se ha suministrado ninguna componente coseno a 200 Hz.

Los [controles sintéticos fijos](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/synthetic-periods.json) utilizan la [transformada de NumPy para una entrada real](https://numpy.org/doc/stable/reference/generated/numpy.fft.rfft.html) y proyecciones directas separadas. Recuperan las amplitudes suministradas y la ausencia de amplitud en la fundamental con un error máximo de `1e-10`. Son matrices matemáticas sin fundidos, no estímulos reproducidos ni observaciones de un oyente.

### Ejercicio 2: rechazar el atajo del pico más alto

Para A, indique la componente más fuerte, la frecuencia fundamental de repetición, el período en segundos y el período en muestras. ¿La ausencia de una componente de 200 Hz impide que la forma de onda completa se repita a esa frecuencia?

> **Respuesta:** La componente más fuerte es de 1000 Hz; la frecuencia fundamental de repetición es de 200 Hz, con un período de `1/200` segundos y 240 muestras a 48000 Hz. Las tres componentes completan 5, 6 y 7 ciclos en ese intervalo. No hace falta una componente espectral no nula a 200 Hz para que se repita la forma de onda completa. Este cálculo por sí solo no determina la altura que comunica un oyente.

## 3. Mantener visibles los múltiplos del período y el significado de la puntuación

Reste la media de la ventana completa. Para cada desplazamiento positivo, divida el producto escalar de las partes solapadas por la raíz cuadrada del producto de sus energías. Así se obtiene una puntuación de recurrencia normalizada. En la búsqueda declarada de 144 a 576 muestras, A presenta puntuaciones iguales a uno con una tolerancia de `1e-12` en los desplazamientos de 240 y 480. El segundo es otra recurrencia del mismo patrón, no una prueba independiente de que se haya suministrado una componente de 100 Hz.

Nuestro control construido elige el más corto de esos candidatos de período perfecto empatados. Esa regla explícita devuelve 200 Hz; elegir 480 devolvería 100 Hz. Los límites de desplazamiento y la regla de selección afectan a lo que comunica un estimador. Una puntuación cercana a uno mide esa coincidencia entre formas de onda; no es una confianza calibrada de que la octava elegida sea correcta ni de que una persona la oiga.

### Ejercicio 3: mostrar la otra octava posible

Convierta los desplazamientos de 240 y 480 en frecuencias a 48000 Hz. ¿Cuál elige la regla declarada del período empatado más corto y qué no demuestra la otra puntuación perfecta?

> **Respuesta:** Dan 200 y 100 Hz. La regla elige 240 muestras y, por tanto, 200 Hz. La recurrencia en 480 es un múltiplo del período; no demuestra que se haya suministrado una componente de 100 Hz, ni confirma de forma independiente la octava elegida, ni establece una probabilidad perceptiva. Conserve ambos candidatos y la regla.

## 4. Aplicar un método declarado a las muestras de guitarra conservadas

Las nuevas ventanas semiabiertas seleccionadas son 0.2–0.4, 0.4–0.6, 0.6–0.8 y 1.0–1.2 segundos. Cada una contiene 8820 muestras. Su [registro de análisis](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/native-pitch-windows.json) conserva las curvas completas por desplazamiento y los máximos locales. El método espectral usa una ventana de Hann simétrica y la casilla de mayor magnitud entre 50 y 500 Hz, sin interpolación; importa la separación de 5 Hz entre casillas. El método por desplazamiento usa las muestras centradas sin Hann, desplazamientos enteros de 89 a 882, máximos locales interiores y un umbral de comunicación de 0.9.

| Inicio de ventana, segundos | Casilla espectral más fuerte, Hz | Desplazamiento elegido, muestras | Frecuencia del desplazamiento, Hz | Cents respecto a la solicitud nominal |
| --- | --- | --- | --- | --- |
| 0.2 | 80 | 538 | 81.970260223 | -9.197475196 |
| 0.4 | 80 | 539 | 81.818181818 | -12.412395431 |
| 0.6 | 80 | 539 | 81.818181818 | -12.412395431 |
| 1.0 | 80 | 539 | 81.818181818 | -12.412395431 |

Las cuatro mejores puntuaciones de recurrencia superan 0.999, pero todas incumplen el control didáctico de proximidad declarado de antemano: un error absoluto de como máximo 5 cents respecto a la solicitud nominal de 82.4069 Hz. Es un diagnóstico de aula frente a esa referencia de entrada, no una medición física calibrada de la altura ni una norma de producto. Las casillas espectrales de 80 Hz tampoco establecen una frecuencia de salida exactamente igual a 80 Hz.

### Ejercicio 4: conservar un control fallido

Para un desplazamiento de 538, calcule la frecuencia e interprete la desviación comunicada de aproximadamente -9.197475196 cents según el control de 5 cents. ¿Su puntuación superior a 0.999 hace que el control se cumpla?

> **Respuesta:** `44100/538` da aproximadamente 81.970260223 Hz. El valor absoluto de su desviación respecto a la referencia nominal supera 5 cents, por lo que el resultado de este método incumple el control declarado. Una puntuación de recurrencia alta no anula el criterio ni certifica la afinación. No se realizó una medición física independiente y calibrada de la frecuencia, un juicio humano ni un nuevo renderizado del motor.

## 5. Elegir el siguiente experimento sin ocultar la limitación

Antes de llamar «desafinado» al motor conservado, pruebe el estimador con otras frecuencias conocidas, fases, filtros, duraciones y octavas posibles, e indique su resolución. Podría compararse un método de desplazamiento fraccionario, pero es un candidato que requiere calibración, no una sustitución automáticamente correcta. La altura comunicada por un músico necesita una tarea separada, como explica [COG-005](../../cognitive-science/en/cog-005-separate-pitch-estimates-from-listener-reports.md).

El candidato histórico de decaimiento de [GAS-004](gas-004-run-open-e-decay-candidate.md) mejoró el error seleccionado en aproximadamente 0.114166150 dB frente a un requisito de 1 dB y no superó ese criterio. Un nuevo análisis de altura no revierte ese resultado ni identifica su causa. [DV-010](../../data-visualization/en/dv-010-show-pitch-errors-and-missing-estimates.md) mantiene separadas las estimaciones disponibles, los valores ausentes y los errores de octava en una visualización.

### Ejercicio 5: redactar el resultado del ciclo de mejora

Resuma el resultado de las ventanas conservadas y un siguiente control, sin afirmar que hubo un nuevo renderizado, una percepción de un oyente o una reparación del criterio de decaimiento.

> **Respuesta:** Cuatro ventanas nativas conservadas produjeron estimaciones por desplazamiento entero cercanas a 81.97 o 81.82 Hz, con puntuaciones de recurrencia altas, pero ningún cumplimiento del control declarado de 5 cents respecto a la referencia nominal. Calibre el estimador y su resolución de octava y desplazamiento con señales controladas antes de atribuir la discrepancia al motor. No se repitió ningún renderizado ni ensayo de escucha, y el fallo anterior de decaimiento sigue sin cambios.
