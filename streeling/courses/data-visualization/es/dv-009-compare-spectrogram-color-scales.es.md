---
module_id: dv-009-compare-spectrogram-color-scales
department: data-visualization
course: "Comparar espectrogramas sin ocultar un cambio de ganancia"
level: intermediate
prerequisites: ["dv-007-optick-partition-small-multiples", "aud-006-calibrate-spectral-amplitudes", "cs-013-preserve-spectral-axes-and-units"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Comparar espectrogramas sin ocultar un cambio de ganancia

> **Alcance del borrador.** Análisis medido de visualización sobre WAV conservados con un control de ganancia construido. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes, la escucha y la verificación del HTML público del curso. No se realizó ningún nuevo renderizado de guitarra ni se ejecutó ningún binario de IX.

## La pregunta del proyecto

Un agente de mejora de GA coloca dos espectrogramas uno al lado del otro y dice que tienen la misma intensidad. Si cada imagen se normalizó por su propio pico, ¿qué comprobó realmente esa comparación? Una visualización puede preservar un patrón y a la vez borrar una diferencia de ganancia. Esta lección hace visible ese fallo con entradas conocidas y amplía el principio de escala compartida de [DV-007](dv-007-optick-partition-small-multiples.md).

Abra la [figura de seis paneles](../../../../code/streeling/evidence/spectral-views-2026-10-22/spectrogram-reference-comparison.png) y su [registro numérico](../../../../code/streeling/evidence/spectral-views-2026-10-22/display-comparison.json). El [modelo de normalización de Matplotlib](https://matplotlib.org/stable/users/explain/colors/colormapnorms.html) asigna límites numéricos a colores. Compartir un mapa de colores y límites numéricos es solo parte de la comparabilidad: los valores suministrados también deben compartir la referencia prevista.

## 1. Identificar los tratamientos antes de comparar colores

Las columnas llevan las etiquetas `B`, `C` y `0.5B`. Las dos primeras son la referencia conservada y el candidato real de decaimiento del experimento nativo de guitarra anterior. La tercera es una copia construida de la referencia decodificada multiplicada por 0.5. Es un control de visualización, no otro renderizado físico de guitarra ni el candidato real. Las muestras son enteros PCM16 decodificados y divididos por 32768; [AUD-006](../../audio-engineering/en/aud-006-calibrate-spectral-amplitudes.md) explica el estimador de amplitud aplicado antes del trazado.

La figura muestra frecuencias hasta 2000 Hz. Las coordenadas horizontales usan el tiempo de inicio de trama y celdas de visualización del ancho de un salto; cada trama analizada sigue abarcando 2048 muestras. [CS-013](../../computer-science/en/cs-013-preserve-spectral-axes-and-units.md) explica ese contrato de coordenadas. Las letras y las etiquetas de fórmulas se comparten entre idiomas; este texto aporta su interpretación.

### Ejercicio 1: identificar el control

¿Qué par aísla un cambio exacto de ganancia y qué par compara los tratamientos de decaimiento anteriores? ¿Por qué llamar a las tres columnas renderizados separados del motor debilitaría el registro del experimento?

> **Respuesta:** `B` frente a `0.5B` aísla el multiplicador de ganancia construido de 0.5. `B` frente a `C` compara la referencia y el candidato de decaimiento anteriores. El arreglo con la mitad de ganancia se creó a partir de muestras decodificadas de la referencia sin otra ejecución del motor. Llamarlo un renderizado separado identificaría mal la intervención y exageraría las pruebas de ejecución.

## 2. Dar a la barra de colores una referencia, además de un rango

La fila superior utiliza `20*log10(max(A/1,1e-4))`, con una amplitud de pico de referencia fija de 1. Todos los paneles utilizan límites de color de -80 a 0 dB. La fila inferior primero divide cada matriz completa por su propio máximo y después utiliza `20*log10(max(A/max(A),1e-4))` con los mismos límites numéricos de color. Su referencia es el pico propio de cada panel. Los máximos se calculan sobre la matriz completa antes de recortar el rango visible de frecuencias.

Son dos preguntas distintas. La fila superior conserva diferencias de amplitud respecto a la referencia común declarada donde el recorte no las oculta. La fila inferior muestra un patrón relativo al pico de cada matriz. Por tanto, el mismo color en filas distintas no tiene por qué significar la misma amplitud. Ninguna fila es una puntuación de sonoridad, realismo o preferencia, y el estimador de amplitud no es una medida universal de los parciales individuales de guitarra.

### Ejercicio 2: interpretar un color igual

Dos celdas de la fila inferior tienen el mismo color y valor numérico. ¿Qué igualdad puede establecer eso bajo la normalización indicada? ¿Establece la igualdad de las amplitudes originales o justifica comparar directamente ese color con la fila superior?

> **Respuesta:** Puede establecer un nivel mostrado igual respecto al máximo propio de cada panel, sujeto al recorte por el suelo. No establece amplitudes originales iguales. La fila superior usa la referencia común de 1, mientras que la inferior usa los máximos de los paneles, de modo que la igualdad de color entre filas no implica igualdad de amplitud respecto a una referencia compartida.

## 3. Utilizar un control que deba desaparecer con la normalización

Antes de aplicar el suelo, reducir la amplitud a la mitad cambia su valor logarítmico en `20*log10(0.5)`, aproximadamente -6.02059991 dB. En el control calculado hay 6359 celdas en las que ambos valores con referencia fija están en el suelo de -80 dB o por encima. Sus diferencias medidas coinciden con ese desplazamiento con una tolerancia de `1e-10` dB. Las celdas ocultas por el suelo no pueden demostrar que la diferencia se mantiene intacta.

Para la fila relativa, `max(0.5*A) = 0.5*max(A)` en esta matriz no nula. Dividir por el máximo del panel cancela la ganancia. La diferencia máxima calculada entre las vistas relativas de la referencia y del control con la mitad de ganancia es de 0 dB. Por tanto, la normalización supera una prueba de invariancia del patrón y falla como prueba de que la ganancia de entrada no cambió. El suelo se aplica después del cociente; aplicarlo antes modifica este argumento.

### Ejercicio 3: predecir y verificar la diferencia

Calcule el desplazamiento esperado con referencia fija para el multiplicador 0.5 y explique por qué coinciden las imágenes relativas. ¿Qué celdas deben excluirse de una afirmación de que todas las diferencias mostradas con referencia fija equivalen a ese desplazamiento?

> **Respuesta:** El desplazamiento es `20*log10(0.5)`, aproximadamente -6.02059991 dB. En la vista relativa tanto el numerador como el máximo se reducen a la mitad, de modo que su cociente se mantiene antes del suelo compartido. Excluya las celdas recortadas por el suelo en cualquiera de los paneles con referencia fija; su diferencia mostrada no tiene por qué conservar el desplazamiento original. Este resultado corresponde al control construido, no al candidato real de decaimiento.

## 4. Explicitar el orden del recorte y la normalización

Si una visualización recalcula su máximo después de cada recorte de frecuencias, hacer zoom puede cambiar el color de datos que no han cambiado. Si conserva el máximo de la matriz completa como hace esta figura, el recorte cambia la visibilidad y mantiene fija esa referencia. Ambas opciones pueden tener utilidad, pero el lector debe saber cuál se utilizó. De lo contrario, un agente puede tratar una manipulación de la vista como un cambio en un renderizado de guitarra.

### Ejercicio 4: auditar una visualización cambiante

Una persona que revisa la figura hace zoom a un rango de frecuencias más estrecho y ve más brillantes las celdas conservadas, aunque los valores fuente no han cambiado. ¿Qué comportamiento de normalización podría explicarlo? Indique la política de esta figura y lo que debe vincular un registro de comparación.

> **Respuesta:** Recalcular el máximo del panel a partir de la región visible más pequeña puede cambiar la referencia y aclarar valores sin cambios. Esta figura usa el máximo de cada matriz completa antes del recorte de frecuencias. Vincule los valores fuente y sus hashes, estimador de la magnitud, dominio de referencia, recorte, suelo y límites de color para que otra persona pueda distinguir un cambio de datos de un cambio de visualización.

## 5. Volver a la medida de aceptación declarada

El [resultado anterior del criterio de decaimiento](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/results.json) del candidato real sigue siendo un fallo: mejora de unos 0.11416615 dB, mejora requerida de 1 dB. Ese número es una mejora del error en la medida de decaimiento anterior; el desplazamiento del control de aproximadamente -6.02059991 dB es una magnitud diferente de una intervención diferente. No los combine en una nueva puntuación de aceptación.

### Ejercicio 5: redactar una decisión defendible

Un agente afirma: «Las imágenes inferiores coinciden, así que el candidato es equivalente, la ganancia no cambió y el criterio de decaimiento se supera». Sustituya esa afirmación por una decisión respaldada por este experimento y especifique las siguientes pruebas necesarias para una afirmación musical más amplia.

> **Respuesta:** La referencia y el control construido con la mitad de ganancia tienen vistas relativas a su panel iguales bajo la transformada y la normalización declaradas, aunque sus amplitudes con referencia fija difieren. Esto no establece equivalencia del candidato real, ganancia de entrada sin cambios ni superación del criterio de decaimiento. Conserve el fallo del criterio. Una afirmación musical más amplia necesita una característica o pregunta de escucha declarada por separado, entradas controladas y una comparación ejecutada adecuada a esa pregunta.

## Límites de las pruebas

El [registro del análisis](../../../../code/streeling/evidence/spectral-views-2026-10-22/execution.json) recoge las versiones instaladas, el hash de la figura y las comprobaciones de cálculo. El [protocolo](../../../../code/streeling/evidence/spectral-views-2026-10-22/experiment-plan.md) distingue predicciones, audio conservado y controles construidos. Esto es un artefacto de visualización científica con pruebas numéricas, no una extensión de editor desplegada, un resultado de escucha humana ni un beneficio de aprendizaje medido.
