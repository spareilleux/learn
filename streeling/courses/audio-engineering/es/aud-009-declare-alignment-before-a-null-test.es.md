---
module_id: aud-009-declare-alignment-before-a-null-test
department: audio-engineering
course: "Declarar la alineación antes de una prueba de cancelación"
level: intermediate
prerequisites: ["aud-005-pcm-guards-and-format-boundaries", "aud-008-measure-a-filter-with-paired-input-and-output"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Declarar la alineación antes de una prueba de cancelación

> **Alcance del borrador.** Muestras didácticas en número finito y lectura del código en una revisión fijada. Siguen pendientes las revisiones humanas técnicas, musicales, lingüísticas por personas que dominen el idioma y pedagógicas con estudiantes, así como la verificación del HTML del curso desplegado. No se realizó ningún renderizado nuevo del motor, captura en el navegador ni prueba de escucha.

## La pregunta del proyecto

Dos búferes se cancelan después de que un agente desplace y cambie la escala de uno. ¿Eran idénticos los búferes originales? [AUD-005](aud-005-pcm-guards-and-format-boundaries.md) distingue las salvaguardas y los formatos PCM; [AUD-008](aud-008-measure-a-filter-with-paired-input-and-output.md) conserva emparejadas la entrada y la salida. Aquí la comparación debe conservar sus transformaciones como resultados.

## 1. Declarar el reloj, la dirección del retardo y el soporte completo

Las [muestras fijadas](../../../../code/streeling/evidence/audio-comparison-2026-10-23/null-comparison.json) son valores reales elaborados para el curso:

```text
x = [0, .25, -.25, .5, -.5, .25, 0, -.25]
y = [0, 0] + .5*x
Fs = 8000 Hz
y[n+2] = .5*x[n] for n = 0..7
```

La referencia tiene 8 tramas; la señal retardada tiene 10. El objetivo de referencia declarado comprende las 8 tramas completas, emparejadas con las tramas de y de 2 a 9. El retardo es 2/8000 segundos = .25 ms. Este reloj didáctico no es una frecuencia medida del navegador ni una latencia del hardware.

### Ejercicio 1 — Hacer reproducible el emparejamiento

Indique el objetivo, la correspondencia entre tramas y la dirección del retardo. ¿Son .25 ms una mejora observada de la latencia?

> **Respuesta:** Empareje la trama n de x con la trama n+2 de y para cada trama de referencia de 0 a 7. El y didáctico tiene un retardo de 2 tramas. Esto cubre por completo el objetivo de referencia declarado y trata las dos tramas iniciales por separado. El valor de .25 ms se deriva del reloj estipulado; no es una latencia medida ni una mejora.

## 2. Informar de los residuos antes y después del ajuste

Para cualquier vector de residuo r declarado, RMS es la raíz cuadrada de la media de sus cuadrados. El RMS de referencia es aproximadamente .306186218. Comparar x con las primeras 8 tramas de y en el origen inicial da un RMS del residuo de aproximadamente .275992527. Alinear el retardo declarado y mantener la ganancia unitaria da aproximadamente .153093109.

La primera comparación es un diagnóstico explícitamente recortado en el origen inicial, no una cobertura completa de la señal retardada. No debe convertirse silenciosamente en el objetivo final alineado.

### Ejercicio 2 — Explicar el cambio de pregunta

¿Por qué puede ser menor el residuo tras alinear el retardo aunque no haya cambiado ninguna muestra original?

> **Respuesta:** Cambió el emparejamiento de tramas. Tras la alineación, la señal es la mitad de la referencia, por lo que la diferencia tiene la mitad del RMS de referencia. Esto elimina el desplazamiento estipulado de la pregunta de comparación, no del historial de la señal original. Conserve ambos residuos, sus soportes y el retardo en vez de afirmar que la alineación conservó la temporización original.

## 3. Una cancelación tras el ajuste no demuestra igualdad original

Sobre el objetivo alineado completo, ajuste un escalar real con la referencia como predictor:

```text
g_hat = sum(x[n]*y[n+2])/sum(x[n]*x[n]) = .5
residual[n] = y[n+2] - g_hat*x[n] = 0
20*log10(g_hat) = -6.020599913 dB
```

El modelo declarado de retardo y ganancia se ajusta exactamente en aritmética real. Ha eliminado dos diferencias que pueden importar al usuario: temporización y nivel. Esto no dice nada sobre la identidad de bytes de coma flotante nativos/Wasm, la identidad PCM16 ni la preferencia de escucha.

### Ejercicio 3 — Redactar un veredicto fiel

¿Puede presentarse el residuo nulo tras el ajuste como «audio sin cambios»? Incluya el retardo y la ganancia en un veredicto alternativo.

> **Respuesta:** Informe de la coincidencia exacta de las muestras didácticas después de la alineación declarada de 2 tramas y la ganancia ajustada de .5, aproximadamente -6.020599913 dB. Las señales originales difieren en soporte, temporización y nivel. Un residuo nulo tras el ajuste solo establece la comparación transformada indicada sobre su objetivo completo. No demuestra audio original sin cambios, identidad de bits ni reducción medida de latencia.

## 4. El silencio y las colas truncadas necesitan estados separados

Para dos vectores silenciosos de 8 tramas, el residuo bruto es cero, pero el denominador del ajuste de ganancia es cero: la ganancia está indefinida. La igualdad bruta de los silencios sigue siendo una afirmación válida.

Para un control de cola, parta de la señal alineada .5*x y sume .125 a su última trama. Con la ganancia prescrita de .5, las primeras 6 tramas tienen residuo cero, pero solo se ha comprobado 6/8 = .75 del objetivo declarado. El RMS del residuo completo es aproximadamente .044194174. Es una comprobación con ganancia prescrita; no vuelva a ajustar silenciosamente la ganancia sobre la cola modificada.

### Ejercicio 4 — Rechazar dos validaciones inválidas

¿Debe una ganancia ajustada indefinida hacer falsa la igualdad bruta de dos silencios? ¿Puede el residuo nulo de las primeras 6 tramas certificar el objetivo completo de 8 tramas?

> **Respuesta:** No en ambos casos. El ajuste de ganancia sobre silencio está indefinido, mientras que la comparación bruta directa sigue teniendo sentido. En el caso de la cola, la diferencia omitida hace que el residuo completo sea distinto de cero. Conserve el número de tramas comprobadas, el número de tramas objetivo, los datos ausentes y la política de transformación. Este objetivo exige las 8 tramas completas; el ejemplo no establece un umbral universal de cobertura mínima para otras tareas.

## 5. Leer el programa de ejecución existente antes de proponer un pipeline

El [programa de ejecución de Learn](https://github.com/spareilleux/learn/blob/49ad4cf7db680f031b3a3fb5b6ee118464ad099f/code/streeling/guitar-runtime/run.mjs) en la revisión fijada trata por separado los bytes brutos de coma flotante, PCM16 y las ventanas RMS semiabiertas con límites redondeados. Utiliza desplazamientos de inicio conocidos para su comparación de decaimiento; no implementa este nuevo procedimiento de ajuste de retardo y ganancia. Su [procedencia](https://github.com/spareilleux/learn/blob/49ad4cf7db680f031b3a3fb5b6ee118464ad099f/code/streeling/guitar-runtime/source.json) fija un motor más antiguo que el código de GA recién inspeccionado. El criterio conservado de decaimiento incumplido no ha cambiado.

### Ejercicio 5 — Definir una comparación con ayuda de las fuentes

¿Qué necesitaría un registro real de comparación nativa/Wasm antes de que estas ideas se conviertan en un DSL agéntico?

> **Respuesta:** Conserve las revisiones del motor y del programa de ejecución, el formato de muestras, la distribución de canales, los relojes, la excitación, las extensiones completas de los búferes, el soporte objetivo, la dirección del retardo, la ganancia ajustada o prescrita, las métricas brutas, las métricas ajustadas, las tramas ausentes y el coste de cálculo. Inspeccione dónde el programa actual serializa los flotantes y convierte a PCM16. Compare primero un pequeño registro explícito y una resta directa. La identidad de bytes, la coincidencia tras la transformación, la latencia y la escucha requieren evidencia separada. Aquí no se demostró ningún pipeline de producción, nueva ejecución del motor ni beneficio para el usuario.

## Trabajo que debe entregar el estudiante

Conserve el trabajo real y la ayuda recibida en la [tarea con ayuda de las fuentes](../../../../code/streeling/evidence/audio-comparison-2026-10-23/learner-task.md). La [rúbrica preparada](../../../../code/streeling/evidence/audio-comparison-2026-10-23/reviewer-rubric.json) no contiene ningún veredicto de estudiante. [INF-009](../../information-theory/en/inf-009-keep-level-when-normalizing-waveform-shape.md) muestra otra forma en que una comparación puede borrar las diferencias de nivel.
