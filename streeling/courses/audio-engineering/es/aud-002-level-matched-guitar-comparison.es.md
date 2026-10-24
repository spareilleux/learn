---
module_id: aud-002-level-matched-guitar-comparison
department: audio-engineering
course: "Comparar un render de guitarra GA con el nivel de reproducción igualado"
level: intermediate
prerequisites: [gas-001-open-string-audio-evidence]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: audio-engineering-2026-10-11-002
version: "0.1.0"
---

# Comparar un render de guitarra GA con el nivel de reproducción igualado

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](../../../../code/streeling/evidence/guitar-audio-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Ingeniería de Audio** | Nivel: intermedio | Duración estimada: 30 minutos | Estado: borrador en español; revisión del contenido, revisión lingüística por una persona con dominio del español, pruebas con estudiantes y publicación pendientes

## Objetivos

Al terminar esta lección, podrás:

- Conservar la identidad y la procedencia de los WAV grabado y sintetizado antes de crear copias de escucha.
- Alinear los primeros eventos de nota y calcular un ajuste aproximado de ganancia a partir de la misma ventana RMS posterior al inicio.
- Explicar por qué igualar el nivel inicial no iguala dos envolventes ni dos timbres.
- Definir una comparación de audio refutable y un plan de escucha a ciegas de alcance acotado.

## La pregunta del proyecto

El motor nativo de guitarra de GA, escrito en Rust, sintetizó un mi grave al aire, E2. Otro E2 al aire, grabado, sirve de referencia didáctica. Si los oyentes escuchan el archivo GA mucho más fuerte, ¿pueden juzgar su timbre de forma justa frente a la grabación? No: el nivel de reproducción y la alineación temporal forman parte de la preparación de la comparación. [GAS-001](../../guitar-acoustics/en/gas-001-open-string-audio-evidence.md) presenta el recorrido general de las pruebas desde la grabación hasta el experimento con el motor. AUD-002 se centra en la **verificación de ingeniería de audio previa a un juicio A/B**: fijar las fuentes, alinear los primeros eventos, igualar el nivel en una ventana declarada y conservar las diferencias que esa igualación no controla. No enseña la teoría de FFT, STFT o wavelets que sustenta las mediciones de la fixture.

Este caso se fija en la revisión de código de Demerzel `5c4967454ddc740ed937c87719ca4d71a3522e4b`. El [registro de la fixture GAS-001](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/README.md) identifica los archivos fuente, la licencia, los ajustes de renderizado, los hashes, el script de medición y las limitaciones. Ambos WAV duran cuatro segundos, son mono y tienen una frecuencia de muestreo de 44 100 Hz. El archivo grabado se atribuye a collegefishiesd bajo CC BY-SA 4.0 y el conjunto de datos lo etiqueta como `low_E`, cuerda al aire, E2. El WAV GA es un render nativo del código Rust fijado, **no** una captura de la salida del AudioWorklet del navegador. Por tanto, un veredicto de escucha sobre este par no validaría la reproducción en el navegador.

### Ejercicio práctico 1: fijar las entradas

El README de la fixture indica para `deb-low-e-open.wav` el SHA-256 `03a1965f…7f38b248` y para `ga-engine-e2-open-4s.wav` el SHA-256 `a78a7024…7866c3f98`. Una persona exporta un MP3 más fuerte y sustituye el WAV GA en el directorio de la fixture. ¿Se pueden seguir usando las mediciones y la procedencia existentes sin cambios?

> **Respuesta:** No. Conserva los WAV originales y sus hashes completos como entradas inmutables. Guarda cualquier copia de escucha con ganancia, recorte o codificación modificados en otra ruta, junto con su transformación y hash. Sustituir el archivo rompe el vínculo entre la medición registrada, los ajustes de renderizado y los bytes; además, el MP3 con pérdida cambia la señal. El README de la fixture proporciona los hashes completos y la atribución.

## 1. Alinear el evento, no la cabecera del archivo

El [script de medición](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measure-pair.py) usa primeros inicios aproximados de **1,1 segundos** para la grabación y **0,0 segundos** para el render GA. El archivo grabado tiene un tramo inicial silencioso y otro ataque cerca de **2,75 segundos**. Elige fragmentos de igual duración que empiecen en sus respectivos primeros inicios. Un fragmento propuesto de 1,5 segundos de la primera nota abarca los tiempos de archivo **1,1–2,6 segundos** de la grabación y **0,0–1,5 segundos** del render; termina antes del segundo ataque grabado. Aplica los mismos fundidos en los límites de las copias de escucha y anótalos en el registro de sesión. Los marcadores de inicio son estimaciones: inspecciona la forma de onda y repite las mediciones clave tras desplazar ligeramente el marcador antes de considerar estable una diferencia dudosa.

Para los valores existentes de la fixture, la ventana RMS inicial es **0,2–0,4 segundos después de cada primer inicio**. Eso corresponde a los tiempos de archivo **1,3–1,5 segundos** de la grabación y **0,2–0,4 segundos** del render. La comprobación posterior es **1,0–1,2 segundos después del inicio**, o tiempos de archivo **2,1–2,3 segundos** de la grabación y **1,0–1,2 segundos** del render. Estas ventanas preceden al segundo ataque de la grabación. Son ventanas de medición, no una prueba de que ambas interpretaciones tengan un punteo con idéntica posición temporal.

### Ejercicio práctico 2: elegir las ventanas correctas

Un analista compara ambos archivos desde el tiempo absoluto de archivo 0,2 hasta 0,4 segundos y llama «silenciosa» a la referencia. Indica las ventanas iniciales y posteriores corregidas, en tiempo de archivo, para cada WAV.

> **Respuesta:** Respecto a los primeros inicios aproximados, la ventana inicial es 1,3–1,5 segundos en la grabación y 0,2–0,4 segundos en el render; la posterior es 2,1–2,3 segundos en la grabación y 1,0–1,2 segundos en el render. El segmento de archivo 0,2–0,4 segundos de la referencia forma parte de su tramo inicial, así que no es la ventana de comparación correcta.

## 2. Igualar una ventana de nivel sin borrar el resultado

El [JSON de mediciones fijado](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measurements.json) indica un RMS inicial de **−34,6 dBFS** para la grabación y **−16,6 dBFS** para el render GA. El render está **18,0 dB por encima** en esta *ventana alineada concreta*. Para igualar aproximadamente esa ventana, atenúa una **copia de escucha** del render GA en 18,0 dB, un multiplicador de amplitud de `10^(-18/20) ≈ 0.126`. Conserva los WAV fuente sin cambios. La fixture registra picos absolutos del archivo completo de 0,1297 para la grabación y 0,4602 para el render; tras esa atenuación uniforme, el pico de la copia del render sería de unos `0.4602 × 0.126 ≈ 0.058`, antes de cualquier otro procesado. Es una predicción basada solo en la ganancia, no una medición de un archivo nuevo.

No te limites a subir la grabación 18 dB: su pico registrado de 0,1297 para el archivo completo pasaría a aproximadamente **1,03** en amplitud normalizada, con riesgo de saturación al exportar en punto fijo. Atenuar la rama más fuerte es la opción sencilla y segura para este par. Registra la ganancia, las unidades, el tratamiento de canales y frecuencia de muestreo, el recorte, los fundidos y el hash de salida. Si un medidor indica otro nivel después de exportar, detente e investiga antes de escuchar.

Esta igualación del RMS inicial es un **control operativo**, no una igualdad de sonoridad percibida. Un oyente aún puede percibir diferencias de ataque, equilibrio espectral, coloración de sala o micrófono y decaimiento. Una única ganancia escalar no puede corregirlas. Para un fragmento más largo u otra tarea, elige y justifica un método de sonoridad más adecuado; no cambies de método sin indicarlo a mitad de la comparación de un candidato.

### Ejercicio práctico 3: calcular la ganancia de reproducción

Con los valores RMS iniciales fijados de −34,6 y −16,6 dBFS, calcula la ganancia en dB para la copia de escucha GA y su multiplicador lineal aproximado de amplitud. ¿Demuestra esa ganancia que el motor GA ya es tan realista como la grabación?

> **Respuesta:** Se aplica `−34.6 − (−16.6) = −18.0 dB` a la copia GA, es decir, se multiplican las amplitudes de sus muestras por `10^(−18/20) ≈ 0.126`. Esto iguala aproximadamente una ventana RMS medida. No iguala el timbre, el ataque, el decaimiento, la cadena de grabación ni el realismo percibido.

## 3. Comprobar la diferencia restante y escuchar a ciegas

El mismo JSON de mediciones indica un RMS posterior de **−38,5 dBFS** para la grabación y **−17,7 dBFS** para el render bruto. Aplicar la misma ganancia de −18,0 dB predice **−35,7 dBFS** en la ventana posterior del render, todavía **2,8 dB por encima** del RMS posterior de la grabación. De forma equivalente, el archivo grabado baja **3,9 dB** entre las ventanas inicial y posterior, mientras que el render baja **1,1 dB**. Una ganancia uniforme conserva la evolución interna de cada archivo. Esto no demuestra qué nota suena más natural; identifica una diferencia de envolvente con el inicio aproximado y las ventanas elegidas de la fixture.

Para una comprobación de escucha, prepara copias sin pérdida de la primera nota a partir de los WAV fijados. Aplica la ganancia documentada y el mismo recorte y fundido; verifica los niveles iniciales resultantes y la ausencia de saturación. Aleatoriza la identidad y el orden A/B, oculta los nombres de archivo y las formas de onda, mantén fijos la cadena de reproducción y el volumen y registra la respuesta de cada oyente antes de revelar las identidades. Plantea una pregunta concreta, por ejemplo qué versión se parece más a un único E2 tocado al aire, y pide un motivo en texto libre. Registra el número de oyentes y ensayos, su experiencia, las condiciones y los desacuerdos. La fixture no contiene un resultado de escucha a ciegas de este tipo. Incluso una preferencia por la grabación mezclaría diferencias de interpretación, instrumento, micrófono, sala, procesado y síntesis; no aislaría un parámetro del motor GA.

### Ejercicio práctico 4: probar lo que la igualación no corrigió

Tras aplicar −18,0 dB a la copia GA, ¿qué RMS posterior se predice? ¿A qué distancia queda de la ventana posterior de la grabación y qué afirmación de comparación falla?

> **Respuesta:** El valor posterior del render pasa a aproximadamente `−17.7 − 18.0 = −35.7 dBFS`, que es `−35.7 − (−38.5) = 2.8 dB` mayor que la ventana posterior grabada. La afirmación «igualar el RMS inicial también iguala la envolvente posterior» falla para estas mediciones redondeadas de la fixture. No es un veredicto de escucha.

## 4. Hacer refutable el siguiente cambio

La diferencia inicial-posterior de 2,8 dB de la base de comparación ofrece un punto de partida medible, no un objetivo automático de optimización. Un cambio propuesto del motor debe declarar los parámetros modificados, la revisión de código de GA, los ajustes de renderizado, el nuevo hash WAV y una política de ventanas e inicios definida de antemano. Una regla **ilustrativa y no aprobada** podría exigir que un candidato nuevo reduzca la diferencia absoluta inicial-posterior por debajo de **1,8 dB** (al menos 1,0 dB menos que esta base), conserve un pico E2 con el mismo método, evite la saturación y supere una comprobación de preferencia a ciegas registrada por separado. El umbral de 1,8 dB es una elección didáctica, no un estándar de aceptación de GA ni un umbral perceptivo. Un candidato que incumpla cualquier condición predeclarada falla esa verificación propuesta; superarla con este único E2 tampoco demostraría realismo general de guitarra.

### Ejercicio práctico 5: definir un criterio de refutación

Un agente afirma que un nuevo ajuste de brillo de GA mejora la guitarra sintetizada porque un valor espectral se ha acercado a la referencia. Propón una siguiente comparación refutable con esta fixture e indica qué resultado rechazaría la afirmación.

> **Respuesta:** Fija los hashes de la referencia y del render de partida, genera un candidato documentado desde una revisión GA fijada, aplica el mismo método de inicio, fragmento e igualación de nivel inicial a la base y al candidato y compara después la diferencia declarada en la ventana posterior, las comprobaciones de pico y altura y las respuestas de los oyentes a ciegas. Con la condición **ilustrativa** anterior, un candidato con una diferencia de 1,8 dB o más, saturación, una comprobación E2 fallida o sin una preferencia de oyentes respaldada no supera la verificación. Aquí no se afirma haber ejecutado ningún candidato ni obtenido resultados de escucha; mover una sola característica espectral no demuestra una mejora.

## Ideas clave

- Calcula los hashes de los WAV grabado y sintetizado originales y consérvalos; transforma copias nuevas para escuchar.
- Alinea el primer inicio antes de elegir las mismas ventanas relativas.
- Una ganancia fija puede igualar una ventana RMS y dejar una diferencia medida de 2,8 dB en la ventana posterior.
- Las etiquetas a ciegas reducen el sesgo de expectativas, pero no eliminan diferencias de fuente, interpretación, micrófono o sala.
- Decide los criterios de medición y escucha antes de probar un candidato y comunica tanto los éxitos como los fallos.

## Pruebas del proyecto y límites

- Revisión Demerzel fijada `5c4967454ddc740ed937c87719ca4d71a3522e4b`: [procedencia y licencia de la fixture](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/README.md), [WAV grabado](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/deb-low-e-open.wav), [WAV de render nativo GA](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/ga-engine-e2-open-4s.wav), [código de medición](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measure-pair.py) y [resultados de medición](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measurements.json). Los hashes de ambos WAV se comprobaron frente al README y al JSON. Son entradas didácticas fijas, no capturas WASM del navegador.
- Todos los cálculos de ganancia, pico y ventana posterior de esta lección se derivan de los valores redondeados de la fixture. No se produjo ningún WAV con ganancia aplicada ni ninguna sesión de escucha a ciegas para AUD-002. Los inicios son aproximados y el RMS inicial es solo una de las posibles reglas de igualación de nivel.
- Estos enlaces WAV relativos a la fuente se resuelven en Demerzel; una publicación en Learn debe incluir el audio o proporcionar enlaces públicos estables a los recursos.
- El borrador inglés fuente no ha completado la revisión del contenido, la revisión lingüística, las pruebas con estudiantes, la sincronización o compilación de Learn ni la lectura pública anónima. Este texto en español también sigue siendo un borrador; quedan pendientes la revisión del contenido, la revisión lingüística por una persona con dominio del español, las pruebas con estudiantes y la publicación.
