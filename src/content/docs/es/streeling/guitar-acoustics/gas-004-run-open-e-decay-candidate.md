---
title: Ejecutar y rechazar un ajuste de decaimiento del mi al aire
description: Ejecutar y rechazar un ajuste de decaimiento del mi al aire — Acústica de la guitarra y síntesis sonora
sidebar:
  label: GAS-004 · Ejecutar y rechazar un ajuste de decaimiento del mi al aire
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/es/gas-004-run-open-e-decay-candidate.es.md
---

:::note[Streeling University]
**GAS-004** · Ejecutar y rechazar un ajuste de decaimiento del mi al aire · intermedio · 45 minutos

Generado por el departamento *Acústica de la guitarra y síntesis sonora* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/es/gas-004-run-open-e-decay-candidate.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAS-003](../../guitar-acoustics/gas-003-decay-calibration-open-e/)
:::

> **Borrador redactado por IA.** Siguen pendientes las revisiones humanas de un especialista en la materia, una persona con dominio del idioma y un estudiante. La publicación HTML del curso sigue pendiente.

## La pregunta de ingeniería

[GAS-003](../../guitar-acoustics/gas-003-decay-calibration-open-e/) propuso cambiar el decaimiento base de GA de **0.9978** a **0.9976** y exigir una reducción de al menos **1 dB** del error absoluto respecto al decaimiento de un mi al aire grabado. Esta continuación presenta el experimento ejecutado. El ajuste mejora ligeramente la medida elegida y no supera ese criterio previamente establecido. El entregable es un registro de rechazo fundamentado, con suficiente procedencia para que otra persona pueda reproducir la decisión.

Consulte el [laboratorio compartido](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/README.md) y la [guía de evidencias](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/README.md) junto con esta lección. El laboratorio compila sin modificaciones el [código del motor GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs), fijado en `dc2e74cbd992a298f67efb928b5b3754615e1924`. El [conjunto de referencia histórico](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001/README.md) está fijado en `5c4967454ddc740ed937c87719ca4d71a3522e4b`.

## Fijar la comparación antes de medir

Cada variante comienza con un motor nuevo a **44100 Hz**, el perfil de guitarra predeterminado **0**, una frecuencia E2 solicitada de **82.4069 Hz**, una velocidad de **0.1** y una duración de **4 segundos**, que produce **176400 muestras**. La inicialización nueva evita transferir a la otra variante los estados de retardo, filtro o reverberación de una nota anterior. Los ajustes de brillo, decaimiento del ataque, dispersión y reverberación permanecen fijos.

La inicialización ya selecciona el perfil **0**. La referencia conserva su decaimiento base de **0.9978**. En el candidato, a la inicialización le sigue `engine_set_decay` con **0.9976**, después `engine_note_on` y, por último, la generación de audio. Seleccionar un perfil después del setter sobrescribiría el decaimiento solicitado. Lea el [adaptador nativo](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/native.rs) y el [programa de ejecución](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs), en vez de deducir el orden de llamadas del nombre del candidato.

### Ejercicio 1 — Proteger la intervención

¿Por qué debe seleccionarse el perfil antes de ajustar el decaimiento y por qué necesita cada variante un motor nuevo?

> **Respuesta:** La selección del perfil escribe el decaimiento junto con otros controles, de modo que una selección posterior podría borrar la intervención. Un motor nuevo proporciona el mismo estado inicial a ambas variantes; reutilizarlo confundiría el cambio de parámetro con los estados acumulados de voces, filtros y reverberación.

## Reproducir el alcance de los artefactos

El laboratorio utiliza [Rust](https://doc.rust-lang.org/rustc/command-line-arguments.html), el [destino WebAssembly](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html) y [Node.js](https://nodejs.org/en/learn/getting-started/nodejs-with-webassembly). El registro indica Windows x64, Rust **1.94.0** y Node **v24.12.0**. Es una compilación didáctica con optimización del compilador, distinta del perfil de entrega del proyecto original. La ejecución en Linux/WSL y macOS queda por verificar.

Desde la raíz del repositorio, el laboratorio ejecutó este comando tras sustituir ambos marcadores por rutas reales:

```text
node code/streeling/guitar-runtime/run.mjs <new-output-directory> <recorded-wav-path>
```

Utilice un directorio de salida nuevo. El comando se escribe igual en todos los sistemas operativos compatibles; el programa elige el sufijo del ejecutable. Comprueba el hash de la referencia y utiliza las herramientas instaladas sin descargar dependencias. Siga las instrucciones de adquisición del laboratorio antes de ejecutarlo.

La grabación se atribuye a **collegefishiesd** y tiene licencia [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). La entrada exacta se conservó únicamente en una caché externa del experimento; no se distribuye en este laboratorio didáctico. El [registro de entradas públicas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/public-input-readback.json) documenta la adquisición y la atribución. Los nuevos archivos nativos, [audio de referencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/baseline.wav) y [audio candidato](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/candidate.wav), se conservan como WAV PCM16. La grabación de entrada utiliza WAV IEEE float32; decodificarla como PCM16 invalidaría la comparación.

### Ejercicio 2 — Comprobar la reproducibilidad

¿Qué pruebas demostrarían que la nueva referencia reproduce el experimento histórico, más allá de obtener un decaimiento redondeado similar?

> **Respuesta:** El WAV de referencia tiene exactamente el hash del archivo histórico, y volver a ejecutar el script de medición primario sin modificar produce un JSON de referencia completamente idéntico a las mediciones archivadas. La coincidencia de un decaimiento redondeado podría ocultar otra forma de onda o un método de medición modificado.

## Medir el mismo evento

El método resta el nivel RMS de la ventana temprana al de la tardía, usando **0.2–0.4 segundos** y **1.0–1.2 segundos** después del inicio. La grabación empieza a sonar aproximadamente a los **1.1 segundos** del archivo; tiene un ataque adicional cerca de los **2.75 segundos**. Por tanto, las ventanas seleccionadas están aproximadamente a los **1.3–1.5 segundos** y **2.1–2.3 segundos** del archivo. Ambas preceden ese ataque adicional. El audio generado comienza en cero.

Esta es una medida local de la envolvente, no una constante de decaimiento de todo el archivo. La referencia procede de otra guitarra, otro micrófono, otra sala y otra pulsación. El cambio de nivel dentro del archivo elimina una diferencia simple de ganancia, pero no convierte la grabación en un objetivo físico universal.

### Ejercicio 3 — Detectar una ventana contaminada

¿Una ventana de la grabación que comenzara a los **2.8 segundos** respondería a la misma pregunta sobre el decaimiento de la primera nota?

> **Respuesta:** No. Comienza después del ataque adicional cercano a los **2.75 segundos** e introduce otra excitación. Mantenga las ventanas relativas al inicio y documente su carácter aproximado; de lo contrario, el experimento cambiaría de pregunta conservando la misma etiqueta.

## Leer los registros sin redondear

La [repetición primaria](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/primary-measurement-replay.json) registra un decaimiento de referencia de **−3.9221151304441193 dB**, el uso del script primario sin modificar y la coincidencia completa del JSON de referencia. El [resumen de referencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/baseline-primary-measurements.json) y el [resumen del candidato](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/candidate-primary-measurements.json) conservan sus demás mediciones. Los siguientes valores, con toda la precisión registrada, proceden de los [resultados de ejecución](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/results.json); el registro de repetición documenta diferencias insignificantes entre implementaciones por el orden de las operaciones aritméticas.

| Variante nativa PCM16 | Decaimiento, dB | Error absoluto respecto a la grabación, dB |
|---|---:|---:|
| Referencia | −1.0848117418372532 | 2.837303388606845 |
| Candidato | −1.198977891431639 | 2.723137239012459 |

La mejora registrada es de **0.11416614959438576 dB**. Para facilitar la lectura del cálculo, **2.837303 − 2.723137 ≈ 0.114166 dB**. El requisito previo de **1 dB** permitiría un error candidato aproximado de **1.837303 dB**, aplicado a la referencia sin redondear. El error candidato real es aproximadamente **2.723137 dB**, por lo que no lo cumple. No reduzca el umbral después de ver el resultado.

### Ejercicio 4 — Tomar la decisión

¿Una mejora positiva de **0.114166 dB** supera un requisito de al menos **1 dB**? ¿Qué debe indicar el registro del experimento?

> **Respuesta:** No lo supera. Registre que el decaimiento base **0.9976** redujo ligeramente este error de E2 en las condiciones fijadas, pero no alcanzó el criterio de mejora previamente establecido. Rechace este ajuste según este criterio. El resultado no demuestra que suene peor ni que el algoritmo no pueda mejorar.

## Conservar las preguntas abiertas

Una ejecución correcta se distingue de la aceptación del candidato. El programa puede terminar correctamente mientras `candidate_passes_decline_gate` es falso. Las aserciones sobre el rango de muestras, el silencio y la partición en bloques cubren propiedades concretas de ejecución. No demuestran que se cumplan todas las protecciones de GAS-003. Los resúmenes primarios contienen observaciones de altura y parciales, pero sus datos redondeados no prueban la conservación del ataque ni de todas las propiedades espectrales.

### Ejercicio 5 — Preparar el siguiente traspaso

¿Qué debe seguir pendiente antes de tomar una decisión sobre el producto, incluso si un futuro candidato supera el criterio numérico?

> **Respuesta:** Mantenga trabajos separados para la sensibilidad a la detección del inicio, la conservación del ataque, los controles de altura y seguimiento de parciales, otras notas y velocidades, y la escucha a ciegas con niveles igualados. La generación nativa y la ejecución de WebAssembly sin conexión no certifican la captura de AudioWorklet en el navegador, la planificación temporal ni el comportamiento de memoria prolongado. Las revisiones humanas de un especialista en la materia, una persona con dominio del idioma y un estudiante, así como la publicación HTML del curso, también siguen pendientes.

Conserve los artefactos del candidato rechazado. Sustituyen una hipótesis sin probar por un resultado acotado y ofrecen al siguiente experimento una referencia reproducible, sin convertir una medida de calibración en un veredicto de escucha.
