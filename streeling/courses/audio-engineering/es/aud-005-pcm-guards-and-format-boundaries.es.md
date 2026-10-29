---
module_id: aud-005-pcm-guards-and-format-boundaries
department: audio-engineering
course: "Controles PCM y límites de formato en el laboratorio de guitarra"
level: intermediate
prerequisites: ["aud-002-level-matched-guitar-comparison"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Controles PCM y límites de formato en el laboratorio de guitarra

Un archivo de audio que se abre correctamente puede ocultar una cadena de medición defectuosa. Una conversión puede borrar pequeñas diferencias, un decodificador de entrada puede suponer una codificación equivocada y un proceso terminado correctamente puede informar del fracaso de un candidato. Este curso utiliza el experimento real de guitarra de GA para convertir esos riesgos en controles verificables antes de someter otro ajuste de decaimiento a una comparación auditiva.

Al terminar, podrás seguir las muestras originales hasta el WAV, explicar cada control, distinguir un fallo de formato de entrada de un defecto del motor y redactar una conclusión con límites explícitos. El entregable es una breve nota de revisión que cite las pruebas proporcionadas, incluya una decisión sobre el candidato y enumere las validaciones pendientes.

## Delimitar el experimento

El [README del laboratorio](../../../../code/streeling/guitar-runtime/README.md) describe la compilación didáctica. [Rust](https://doc.rust-lang.org/rustc/command-line-arguments.html) compila el motor fijado, sin cambios, para ejecución nativa y para el [destino WebAssembly](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html); [Node.js](https://nodejs.org/en/learn/getting-started/nodejs-with-webassembly) ejecuta este último. Revisa el [manifiesto de fuentes](../../../../code/streeling/guitar-runtime/source.json) y la [comprobación de entradas públicas](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/public-input-readback.json) antes de considerar que un nombre de archivo demuestra su procedencia. El código del motor y la licencia están fijados; las opciones de compilación didácticas no reproducen el perfil de publicación original.

El experimento inicia un perfil nuevo en E2, con frecuencia solicitada de 82.4069 Hz y velocidad de 0.1. El decaimiento de referencia es 0.9978; el del candidato es 0.9976. Ambos generan audio mono durante 4 segundos a 44100 Hz. Esos ajustes delimitan esta observación, sin ofrecer garantías para cualquier nota, velocidad, perfil, compilador o entorno de audio. Se probó Windows x64. Linux/WSL y macOS quedan por verificar.

## Comprobar las muestras antes de reducir su precisión

Sigue [el programa de ejecución](../../../../code/streeling/guitar-runtime/run.mjs) desde la generación, pasando por `pcmGuard`, hasta `pcm16Wav`. Cada búfer principal debe contener 176400 muestras originales. Una muestra ocupa 4 bytes de coma flotante en orden little-endian, de modo que el tamaño esperado es de 705600 bytes. El control compara primero el número exacto de bytes, después exige `Number.isFinite(sample)` y luego comprueba `Math.abs(sample) <= 1`. Ese orden detecta un búfer truncado como fallo estructural antes del bucle y expone los datos numéricos inválidos antes de convertirlos a enteros.

El codificador utiliza `Math.round(sample * 32767)`. Los datos enteros mono ocupan 352800 bytes, y la cabecera de 44 bytes eleva el WAV generado a 352844 bytes. El decodificador lee esas muestras enteras con `payload.readInt16LE(i * 2) / 32767`. Registra esta convención: la conversión y la decodificación forman parte del método de medición. Los hashes de muestras originales y los del WAV responden a preguntas distintas.

El código fuente termina la generación con una limitación estricta. Es una prueba útil sobre la implementación, pero esa limitación por sí sola no demuestra que entradas `NaN` arbitrarias produzcan una salida finita. Aquí la observación procede de comprobar cada muestra generada en el experimento definido. Ampliar la cobertura de entradas requiere otra prueba explícita, en lugar de extrapolar un comentario sobre la salida normalizada.

Los [resultados](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/results.json) indican picos absolutos de las muestras originales de 0.4601604640483856 para la referencia y 0.46006888151168823 para el candidato en ambos entornos de ejecución. Ambos están por debajo del margen de 0.95 propuesto en GAS-003. Eso respalda el control de pico para esta generación; no demuestra que el sonido sea realista, agradable o esté libre de todo defecto audible.

## Demostrar que el control rechaza entradas

Aceptar búferes normales solo demuestra que el control los tolera. El programa también proporciona entradas deliberadamente inválidas y exige su rechazo mediante aserciones. Una muestra `NaN` alcanza el control de valores finitos. Una muestra de 1.01 alcanza el control del rango normalizado. Un búfer truncado de 3 bytes falla en el recuento esperado. Estos controles negativos hacen observable la vía de fallo prevista; no enumeran todas las posibles corrupciones.

Las pruebas de silencio con instancias nuevas contienen 4096 muestras y tienen un pico de 0 en ejecución nativa y WASM. Esto aporta pruebas sobre esas instancias sin un evento de nota. No certifica un entorno de audio completo, la planificación del navegador, la vida de la memoria, la cancelación ni el silencio tras cualquier actividad previa. Incluye el estado inicial de la prueba en la nota de revisión.

## Dejar que la entrada ponga a prueba el decodificador

La grabación de referencia reveló un error concreto de preparación: el decodificador inicial solo aceptaba WAV PCM16 entero y rechazaba el WAV IEEE float32 suministrado, cuya etiqueta de formato es 3. La corrección añadió una rama de formato explícita y conservó los controles de canal, frecuencia de muestreo, bloques y valores finitos. El código del motor no cambió. Clasificarlo como un fallo de síntesis habría dirigido la investigación a la capa equivocada.

La grabación permanece en una caché externa y no se copia al repositorio. El crédito corresponde a **collegefishiesd**, con la revisión del conjunto de datos y la atribución en el manifiesto; su licencia es [CC BY-SA4.0](https://creativecommons.org/licenses/by-sa/4.0/). La [atribución fijada](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001/README.md) explica el recurso de prueba. Su SHA256 es `03a1965f275f0858be70476dab2bf55d2cbf2272ef7a50c61453d45e7f38b248`. Conserva esa identidad al reparar el decodificador; sustituir silenciosamente la grabación cambia el experimento.

## Distinguir un artefacto válido de un candidato aceptado

Las muestras originales nativas y WASM difieren, aunque los bytes WAV PCM16 coinciden dentro de cada variante. La cuantificación puede transformar distintos flotantes en el mismo entero. Por tanto, los hashes WAV coincidentes no prueban la igualdad de las muestras originales ni su equivalencia perceptiva. El WAV de referencia generado también coincide con el hash del antiguo recurso público, lo que establece la continuidad de ese artefacto concreto.

Lee la [repetición de las mediciones primarias](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/primary-measurement-replay.json), las [mediciones de referencia](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/baseline-primary-measurements.json) y las [mediciones del candidato](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/candidate-primary-measurements.json). El método primario sin cambios se volvió a ejecutar sobre los WAV nativos generados. La mejora del error de decaimiento del candidato es de 0.11416614959438576 dB frente a un mínimo requerido de 1 dB, por lo que `candidate_passes_decline_gate` es `false`. El código de salida 0 significa que la ejecución y las aserciones terminaron; no significa aceptación del producto. La revisión humana y la publicación siguen pendientes, sin resultados de escucha ni captura del navegador.

Para una reproducción futura con las herramientas documentadas ya instaladas, ejecuta desde la raíz del repositorio:

```text
node code/streeling/guitar-runtime/run.mjs <new-output-directory> <recorded-wav-path>
```

Sustituye ambos marcadores. El comando se escribe igual en los sistemas compatibles, pero solo se ha probado la plataforma registrada. Lee las pruebas antes de decidir repetir la ejecución.

## Ejercicios

### Ejercicio A — Auditar el contrato del búfer

Explica los tamaños de las muestras originales y del WAV generado e identifica dónde se rechaza un búfer corto.

> **Respuesta:** La generación contiene 176400 muestras y produce 705600 bytes originales. La conversión entera produce 352800 bytes de datos; la cabecera de 44 bytes da un WAV de 352844 bytes. `pcmGuard` rechaza un recuento inesperado antes de leer las muestras.

### Ejercicio B — Explicar un rechazo

Asigna los controles `NaN`, 1.01 y 3 bytes a las comprobaciones previstas. ¿Por qué conservarlos todos?

> **Respuesta:** Ejercitan los valores finitos, el rango normalizado y el recuento exacto, respectivamente. Cada uno protege una suposición distinta antes de codificar; el éxito del control de rango por sí solo dejaría las otras vías sin probar.

### Ejercicio C — Redactar el diagnóstico de formato

La entrada falla con el decodificador inicial. Describe la corrección sin afirmar que se reparó el motor.

> **Respuesta:** La entrada grabada es un WAV IEEE float32 con etiqueta de formato 3. Añade la decodificación explícita del formato suministrado y conserva la validación y el hash de entrada. La salida generada es PCM16 entero; los dos contenedores requieren interpretar las muestras de forma distinta.

### Ejercicio D — Interpretar bytes WAV idénticos

¿Permiten los hashes WAV nativos/WASM coincidentes cerrar un informe de diferencias entre muestras originales?

> **Respuesta:** Establecen la igualdad después de esta conversión. La cuantificación pierde información, así que la diferencia original sigue siendo real. Ni la igualdad de bytes ni la pequeña diferencia original aportan un veredicto auditivo.

### Ejercicio E — Redactar la decisión

Formula el veredicto del candidato con el estado del proceso, el resultado de pico y el criterio de decaimiento.

> **Respuesta:** La ejecución terminó y los controles de muestras probados se superaron, pero el candidato falló el criterio declarado de mejora del decaimiento. Mantén el candidato sin aceptar. Solicita las revisiones humanas y perceptivas pendientes antes de publicar; la prueba de silencio no certifica un entorno de audio completo.
