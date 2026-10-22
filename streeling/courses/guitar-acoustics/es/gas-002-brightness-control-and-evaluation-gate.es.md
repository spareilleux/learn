---
module_id: gas-002-brightness-control-and-evaluation-gate
department: guitar-acoustics
course: "Acústica de la guitarra: probar un control de brillo en GA WASM"
level: intermediate
alchemical_stage: albedo
prerequisites: [gas-001-open-string-audio-evidence]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: guitar-acoustics-2026-10-11-002
version: "0.1.0"
---

# Probar un control de brillo en el motor de guitarra de GA

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](../../../../code/streeling/evidence/guitar-audio-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de acústica y síntesis de guitarra** | Nivel: intermedio | Etapa: Albedo | Duración: 35 minutos | Borrador traducido por IA; revisión pendiente

## Objetivos

Al terminar esta lección, podrás localizar el control de brillo del motor de guitarra de GA, calcular su valor efectivo para dos notas y diseñar una prueba de un solo parámetro con condiciones explícitas de aceptación y fallo. Distinguirás un cambio de coeficiente de un cambio espectral medido, un fixture nativo del motor de una salida del AudioWorklet del navegador, y un crítico sin conexión existente de un candidato ComfyUI propuesto.

## Pregunta del proyecto y fuentes

[GAS-001](gas-001-open-string-audio-evidence.es.md) estableció un par didáctico de alcance limitado: un mi2 al aire grabado y un mi2 renderizado por GA. El [fixture GAS-001 fijado](https://github.com/GuitarAlchemist/Demerzel/tree/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001) tiene un [registro de mediciones](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001/measurements.json) y [notas de procedencia](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001/README.md). El WAV de GA es un **render nativo** del código Rust fijado, con el perfil 0 predeterminado y `engine_note_on(82.4069, 0.1)`, a 44,100 Hz. No es una grabación del AudioWorklet del navegador. El archivo externo es una grabación atribuida por separado, etiquetada como mi2 al aire por su conjunto de datos; sus condiciones de grabación no se observaron de forma independiente.

El registro de mediciones indica que el segundo parcial respecto al primero está a **+7.0 dB** en la grabación y a **−16.9 dB** en el render de GA, dentro de una ventana espectral de un segundo relativa al inicio de la nota. La diferencia es de 23.9 dB en esa *relación entre parciales dentro de cada archivo*. No es una diferencia de sonoridad global de 23.9 dB, y el instrumento grabado, el micrófono, la sala y la fuerza de ejecución no están controlados frente a la fuente sintética. **¿Reduciría un cambio del control de brillo del motor esta diferencia medida concreta sin perjudicar la altura, el nivel, el decaimiento u otras notas?** La respuesta exige un nuevo render controlado. Esta lección deriva una prueba del código fijado; el candidato no se ha ejecutado.

### Ejercicio 1 — Interpretar bien la diferencia

Resta la relación segundo/primer parcial del render de GA de la del archivo grabado. Indica el signo y qué mide el resultado. ¿Puede llamarse una preferencia de los oyentes?

> **Respuesta:** `+7.0 − (−16.9) = +23.9 dB`: el segundo parcial grabado está 23.9 dB más alto *respecto a su propio primer parcial* que el segundo parcial del render respecto al primer parcial de ese render. Es una comparación espectral en una ventana seleccionada, no una diferencia de sonoridad entre archivos completos ni una preferencia medida de los oyentes.

## 1. Seguir el parámetro antes de cambiarlo

El [motor Rust de GA en `dc2e74cbd992a298f67efb928b5b3754615e1924`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs) inicializa un motor y llama a `set_guitar_profile(0)`. Ese perfil establece el valor base `brightness = 0.80`, junto con valores de decaimiento, dispersión, decaimiento del ataque y reverberación. La función exportada `engine_set_brightness` limita el valor base recibido a `[0, 1]`. Un experimento propuesto puede comparar el `0.80` de ese perfil con `0.90`, aplicando el setter **después** de seleccionar el perfil. Seleccionar un perfil más tarde vuelve a escribir un brillo de perfil y puede sustituir el valor de prueba. Conviene incluir este orden de llamadas en el registro de ejecución.

El [puente de audio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/src/audio/audioEngine.js) del navegador envía `set_brightness` con el número que proporciona quien lo llama. El [AudioWorklet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/src/audio/guitar-worklet.js) solo reenvía ese mensaje al setter de Rust cuando `ready` es verdadero. Su manejador asíncrono `init` establece `ready` solo después de crear el motor WASM y envía un estado de inicialización. La función `initAudioEngine` del puente devuelve un nodo después de enviar `init`; ese retorno por sí solo no demuestra que el worklet haya llegado a `ready`. Para una prueba en el navegador, observa su estado de inicialización completada, selecciona el perfil, establece el brillo y después dispara la nota. De lo contrario, un mensaje de brillo prematuro puede ignorarse o una selección posterior de perfil puede sustituirlo. El WAV de GAS-001 no pasó por esta ruta de mensajes del navegador.

Este parámetro es un valor base, no el coeficiente final de todas las notas. Una prueba útil registra el orden de selección del perfil, llamada al setter y evento de nota, además de la revisión exacta del código. Registrar solo «brillo 0.90» sería ambiguo si otra llamada hubiera restablecido el valor.

### Ejercicio 2 — Proteger el ajuste previsto

En una prueba propuesta para el navegador, una persona llama a `setEngineBrightness(node, 0.90)` inmediatamente después de que `initAudioEngine` retorne y luego selecciona el perfil de guitarra 0. Da dos razones por las que el `0.90` previsto podría no controlar la nota. ¿Qué orden debe registrar el experimento?

> **Respuesta:** Es posible que el worklet aún no esté `ready`, por lo que no reenviará el mensaje de brillo; después, seleccionar el perfil 0 vuelve a fijar el brillo base en `0.80`. Registra, en ese orden, la inicialización correcta del worklet, la selección del perfil 0, la llamada al setter de brillo con `0.90` y el evento de nota posterior. El setter limita los valores a `[0, 1]`; ninguna de estas líneas de código demuestra que se haya ejecutado esta prueba.

## 2. Calcular lo que realmente usa el bucle DSP

En `excite`, el motor limita la velocidad a `[0, 1]` y establece `pluck_mix = clamp(0.15 + 0.35 × velocity, 0.05, 0.7)`. Durante el render calcula `f_norm = clamp((frequency − 82) / (330 − 82), 0, 1)` y luego usa

`effective_brightness = clamp(base_brightness + 0.45 × f_norm + 0.30 × pluck_mix, 0, 1)`.

Ese coeficiente mezcla una ruta de realimentación más brillante con un estado de filtro paso bajo. No ajusta directamente la amplitud del segundo parcial. El motor también moldea la excitación, el ruido de ataque, la dispersión, el decaimiento, la resonancia de la caja y la reverberación. Por tanto, aumentar el coeficiente es una **hipótesis** plausible de cambio espectral en mi2, no una corrección calculada de 23.9 dB. La medición debe decidir si cambia esa relación concreta, y otras comprobaciones deben determinar si el sonido sigue siendo utilizable.

Para el mi2 nominal del fixture a `82.4069 Hz` y con velocidad `0.1`, `pluck_mix = 0.185` y `f_norm = 0.4069 / 248 ≈ 0.001641`. El coeficiente efectivo del perfil predeterminado es `0.80 + 0.45(0.001641) + 0.30(0.185) ≈ 0.85624`; la base propuesta de `0.90` da `≈ 0.95624`. Es aritmética derivada de una ruta del código, no una nueva medición de audio. A `330 Hz`, con la misma velocidad, `f_norm = 1` y ambas sumas superan 1, por lo que ambos coeficientes efectivos se limitan a `1`. Un cambio que afecte a este coeficiente en mi2 puede no afectarle en esa nota más aguda. Aun así, podría influir en otras rutas o condiciones; solo un render puede establecer el resultado sonoro.

### Ejercicio 3 — Calcular el límite

Para una velocidad de `0.1`, calcula `pluck_mix` y el brillo efectivo a `82.4069 Hz` con valores base de `0.80` y `0.90`. ¿Cuáles son los dos valores efectivos a `330 Hz` y qué implica esto para extrapolar una prueba de mi2?

> **Respuesta:** `pluck_mix = 0.15 + 0.35(0.1) = 0.185`; `f_norm ≈ 0.001641`. El brillo efectivo de mi2 es aproximadamente `0.85624` con base `0.80` y `0.95624` con base `0.90`. A 330 Hz, `f_norm = 1`, lo que da las sumas `1.3055` y `1.4055`; ambas se limitan a `1`. El coeficiente de brillo del código no demuestra que un cambio espectral en mi2 se generalice a 330 Hz ni que cualquiera de los dos renders suene mejor.

## 3. Definir un criterio de aceptación antes de escuchar un candidato

Usa el fixture nativo de mi2 existente como referencia inicial, no como medición del navegador. Una futura prueba nativa de un solo control inicializaría el mismo motor fijado a 44,100 Hz, mantendría el perfil 0, mi2 a `82.4069 Hz`, velocidad `0.1`, duración del render, ventanas de análisis y demás ajustes, y solo cambiaría el brillo base de `0.80` a `0.90` después de seleccionar el perfil. Usa un motor nuevo por brazo para que el estado de inicialización y la semilla de ruido fija del código sean comparables. Conserva los WAV de referencia y candidato con sus hashes y el registro de parámetros y orden de aplicación. Si la pregunta trata de la reproducción en el navegador, repite la prueba por separado mediante AudioWorklet y captura su salida; un resultado nativo no puede certificar la ruta del navegador.

Un **criterio didáctico propuesto** consiste en reducir al menos 3.0 dB el error absoluto de la relación del segundo parcial respecto a la referencia grabada de +7.0 dB, partiendo de la diferencia inicial de 23.9 dB. Por tanto, el error del candidato debe ser como máximo de **20.9 dB** con el mismo método de medición relativo al inicio. Es un umbral declarado de antemano, no un estándar de GA establecido empíricamente. Evita el recorte exigiendo un pico medido inferior a 0.95 en amplitud normalizada; conserva la comprobación de la fundamental mi2, la comparación de decaimiento y los renders de otras notas y velocidades. Revisa el comportamiento tardío de los parciales del candidato, porque una buena relación FFT local podría ocultar un ataque o decaimiento poco natural. Si falla una salvaguarda, no aceptes el cambio de control solo porque el segundo parcial se haya movido en la dirección deseada.

El criterio no resuelve el realismo percibido. Después de las mediciones, compara copias de escucha con niveles igualados e inicios alineados mediante un protocolo ciego, y conserva los juicios individuales. Una referencia mi2 fija de un instrumento grabado es una sonda útil, no un objetivo universal para todas las guitarras. Un candidato que supere este criterio didáctico numérico aún puede fallar en la escucha o en la comprobación de varias notas.

### Ejercicio 4 — Calcular el umbral propuesto

¿Qué error absoluto máximo cumpliría la regla propuesta de mejora de 3.0 dB a partir de la diferencia inicial de 23.9 dB? Si un futuro candidato cumpliera ese único umbral espectral pero presentara recorte, ¿lo aceptaría la propuesta? ¿Se ha medido aquí un candidato así?

> **Respuesta:** `23.9 − 3.0 = 20.9 dB` de error absoluto máximo respecto a la relación grabada de +7.0 dB, usando el mismo método. No: el recorte incumple una salvaguarda independiente, así que el cambio de una sola relación entre parciales no basta. No se ha renderizado ni medido ningún candidato de brillo para esta lección.

## 4. Mantener un candidato sin conexión en un brazo distinto

El [bucle sin conexión](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/full-auto.ps1) fijado de GA graba una iteración, aplica opcionalmente coloración DDSP cuando `GA_USE_DDSP=1` y llama a críticos locales y espectrales. Son pasos existentes que se han inspeccionado; no constituyen una transferencia a ComfyUI. Un mi2 **propuesto**, generado o procesado por ComfyUI, corresponde a otro brazo candidato sin conexión, junto a la referencia grabada original y el render base de GA sin cambios. Para una comparación reproducible necesitaría el hash del WAV fuente, el JSON del workflow, el modelo y su versión, la semilla, los ajustes, el hash de salida, el formato y los derechos de uso. Verifica que aún representa un evento mi2 aislado antes de medirlo frente a la misma referencia.

La salida de ComfyUI no es un cambio del renderizador Rust/WASM ni sustituye a un render controlado del motor. Podría sugerir un timbre objetivo o plantear una pregunta sobre la excitación, pero el parámetro del motor debe evaluarse sobre una salida real de ese motor. El crítico espectral existente sugiere posibles ajustes a partir de características resumidas; su puntuación no valida el realismo de la guitarra ni identifica un único control causal. La aceptación sigue dependiendo del procedimiento de medición fijado, las salvaguardas, más de una nota y las pruebas de escucha.

### Ejercicio 5 — Clasificar el tercer brazo

Un agente propone un WAV brillante de ComfyUI sin workflow, versión del modelo, semilla ni hash fuente. ¿Puede contar como prueba de que el brillo base `0.90` mejoró el motor WASM de GA? Nombra la procedencia que falta y la comparación necesaria del motor.

> **Respuesta:** No. El WAV es un candidato sin conexión que carece de trazabilidad, no una salida del motor. Conserva los hashes de fuente y salida, el workflow, el modelo y su versión, la semilla, los ajustes, el formato y los derechos; verifica que sea un mi2 aislado. Después renderiza el motor GA fijado cambiando solo el brillo, compáralo con su propio render base mediante el mismo método y las mismas salvaguardas, y recoge por separado juicios de escucha con niveles igualados. Aquí no se realizó ninguna ejecución de ComfyUI ni una comparación de ese tipo.

## Límites y próxima comprobación

La diferencia de 23.9 dB es una medición guardada de un mi2 al aire grabado y otro renderizado de forma nativa, bajo las ventanas declaradas relativas al inicio. Los valores de brillo efectivo son cálculos derivados del código fijado, no cambios registrados de energía armónica. Siguen sin ejecutarse el candidato propuesto `0.90`, el umbral de aceptación, la secuencia de mensajes del navegador, el barrido de varias notas, el brazo ComfyUI y la prueba de escucha. Antes de cambiar GA, captura un candidato controlado y verifica el orden de sus parámetros, la identidad del WAV, la altura, las relaciones entre parciales, el ataque y decaimiento, los picos, el comportamiento del navegador cuando corresponda y los juicios de músicos. Siguen pendientes la revisión humana del contenido, las pruebas con estudiantes, la revisión lingüística, la sincronización y compilación de Learn, la lectura anónima de comprobación y la publicación.
