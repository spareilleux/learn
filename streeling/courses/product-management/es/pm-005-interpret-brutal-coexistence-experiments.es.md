---
module_id: pm-005-interpret-brutal-coexistence-experiments
department: product-management
course: "Interpretar los experimentos de coexistencia BRUTAL antes de elegir una configuración predeterminada"
level: intermediate
prerequisites: ["pm-004-craft-extension-release-decision", "vc-009-budget-brutal-scene-expansion"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Interpretar los experimentos de coexistencia BRUTAL antes de elegir una configuración predeterminada

> **Alcance del borrador.** Análisis de registros públicos de experimentos históricos y propuesta de una comparación futura. Quedan pendientes la revisión técnica humana, la revisión por una persona que domine el idioma, las pruebas con estudiantes y la verificación del HTML público del curso. No se ejecutó ningún nuevo experimento gráfico, de GPU, DLSS ni transmisión para esta lección.

## La pregunta del proyecto

¿Debe una herramienta auxiliar del Observatory funcionar sin límite de fotogramas porque informa de una tasa muy alta? La [evaluación BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) registra tanto un fallo grave de coexistencia como un seguimiento no concluyente. Una decisión de producto necesita ambos, junto con el comportamiento de la tarea adyacente. Esta lección usa esa evidencia para diseñar una próxima comparación defendible; [PM-004](pm-004-craft-extension-release-decision.md) aborda de forma más amplia los criterios de publicación de extensiones.

Todos los documentos se leen en el commit público de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`. Eso fija los bytes de los documentos. Los encabezados de las ejecuciones históricas identifican por separado revisiones anteriores e informan de cambios sin confirmar. La instantánea documental no identifica un binario exacto y reproducible para esas ejecuciones anteriores. El [conjunto de referencia de comparación histórica](../../../../code/streeling/evidence/brutal-composition-2026-10-22/historical-comparison.json) conserva esa distinción.

## 1. Medir la tarea que debe seguir funcionando

El [informe M2 sin límite](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m2-20261019-235218.md) informa de HallSlice a 10059 fps mientras que la vista RTX adyacente cayó de una mediana previa de 60 fps a una mediana de 2 fps durante la ejecución. También registra el fallo de una comprobación de las teclas de cámara. El mismo documento registra una presentación y una limpieza correctas, por lo que «la ventana funcionó» y «toda la evaluación se superó» son afirmaciones diferentes.

La variación de la mediana de la vista es `(2-60)/60`, aproximadamente -96.67 por ciento. Esa aritmética describe la comparación registrada entre antes y durante la ejecución. No aísla el mecanismo de planificación subyacente, no demuestra que toda ejecución sin límite cause esa caída ni mide la máquina actual. Una tasa alta en el productor no establece un rendimiento útil para la persona que observa la tarea adyacente.

### Ejercicio 1: expresar el impacto en el producto

Calcule la variación relativa de la mediana de la vista adyacente. ¿Por qué la tasa de fotogramas propia de HallSlice y una salida limpia no permiten aprobar la coexistencia?

> **Respuesta:** `(2-60)/60` es aproximadamente -0.9667, una disminución del 96.67 por ciento en la mediana informada de la vista. La tasa y el ciclo de vida de HallSlice describen su propio comportamiento. No satisfacen el requisito independiente de que la vista adyacente siga siendo utilizable; el informe también incluye una comprobación fallida de las teclas de cámara. Conserve el resultado completo registrado sin convertir esta única comparación en una regla causal universal.

## 2. Conservar los controles que cuestionan la primera interpretación

El [informe de controles M3](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) alterna controles sin HallSlice y ejecuciones sin límite. Su regla de aprobación declarada exige que el mínimo de la vista sea de al menos 58 fps.

| Condición | Mínimos de la vista, fps | Medianas de la vista, fps | Caídas registradas |
|---|---|---|---|
| Tres controles | 57, 60, 49 | 60, 60, 57 | 2 |
| Tres ejecuciones sin límite | 60, 60, 38 | 60, 60, 51 | 1 |

Dos controles sufrieron descensos sin que HallSlice estuviera presente. El README público califica el seguimiento de no concluyente: no se reprodujo el colapso grave inicial y la vista adyacente variaba por sí sola. Estas pequeñas muestras secuenciales tienen distintas duraciones de observación y una escena en movimiento. Contar menos caídas en el grupo sin límite no demuestra que renderizar sin límite proteja la vista.

### Ejercicio 2: actualizar la afirmación

Según la regla declarada de un mínimo de 58 fps, cuente las caídas en ambas condiciones. ¿Qué cuestiona esto y por qué tampoco estaría respaldada la afirmación «funcionar sin límite mejora la coexistencia»?

> **Respuesta:** Los mínimos de control 57 y 49 incumplen la regla, lo que da dos caídas; el mínimo sin límite 38 también la incumple, lo que da una. La variación sin HallSlice cuestiona que se atribuya cada descenso menor a ese proceso. Las pequeñas ventanas secuenciales no mantienen constantes la fase de la escena ni las demás cargas, por lo que tampoco está respaldada la afirmación causal inversa. Mantenga visibles la observación M2 original y el seguimiento no concluyente.

## 3. Comprobar tanto la definición de la métrica como la regla de decisión

El README público indica que M2 medía el trabajo desde el comienzo de un fotograma hasta su presentación. M3 medía desde una presentación hasta la siguiente. Por tanto, sus valores p50 tienen distintos extremos temporales: comparar 0.073 ms en el informe M2 sin límite con 0.064 ms en el barrido M3 no establece una mejora de velocidad con una medida común.

El [barrido M3](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000131.md) utilizó una regla más estricta de mínimo de la vista de 60 fps. Con límites de 120 y 480 informó de un mínimo de 59 y marcó caídas. Reclasificar esos valores con una regla hipotética de 58 fps los marcaría como aprobados, pero no cambiaría las observaciones ni la regla original registrada. Mantenga las etiquetas originales y las alternativas en columnas separadas. Establezca la regla de un nuevo ensayo antes de conocer sus resultados.

### Ejercicio 3: auditar una mejora aparente

Un agente combina los dos valores p50 para afirmar que es «más rápido» y cambia a aprobadas las etiquetas del barrido de 59 fps. Identifique los dos problemas independientes y la evidencia necesaria para comparar de forma justa.

> **Respuesta:** Los valores p50 resumen intervalos con extremos temporales diferentes, y el cambio de etiqueta aplica otro umbral después de observar los datos. Use una definición temporal común y conserve cada regla original. Se puede mostrar explícitamente una clasificación alternativa de 58 fps, pero una nueva comparación aceptada necesita una regla declarada de antemano y mediciones del mismo protocolo.

## 4. Separar una capacidad solicitada de su funcionamiento observado

Los [comentarios del código público de Colossus](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L29-L41) documentan `--dlss` y `--rr`, los componentes externos de NVIDIA y el comportamiento alternativo cuando no están disponibles. También describen la entrega de una escena Lego validada a la aplicación gráfica. Son observaciones del código fuente. Las nuevas pruebas en CPU de [VC-009](../../visual-computing/en/vc-009-budget-brutal-scene-expansion.md) ejercitaron la ruta de descripción pura, sin ejercitar esas funciones gráficas.

Un registro de benchmark debe distinguir el modo solicitado, la capacidad disponible, el modo realmente activado y la salida o las mediciones temporales observadas. Si una función recurre a un modo alternativo, etiquete esa ejecución en consecuencia. Una opción solicitada o una escena aceptada no pueden demostrar la calidad de imagen de DLSS, la velocidad del trazado de rayos ni la coexistencia en otro equipo anfitrión.

### Ejercicio 4: clasificar la evidencia de capacidad

Un agente adjunta un comando que contiene `--dlss` y una descripción CPU correcta, y después marca como superado el criterio de rendimiento DLSS del motor de renderizado. ¿Qué falta?

> **Respuesta:** El registro necesita una ejecución gráfica real que muestre la disponibilidad de la capacidad, su activación correcta o el uso explícito de un modo alternativo, el modo de renderizado efectivo y las mediciones declaradas de calidad y rendimiento con hardware y controlador identificados. Ni el texto de la opción ni la validación de la escena en CPU aportan esas observaciones. No se produjo ningún resultado gráfico de ese tipo para esta lección.

## 5. Diseñar una comparación que pueda cambiar la configuración predeterminada

Para una futura prueba de coexistencia, fije la identidad del código fuente y del binario y cualquier diff sin confirmar, la escena, la fase de cámara, la semilla, el hardware y el controlador, el modo de presentación, el límite, los extremos temporales medidos y la duración del muestreo. Repita controles y tratamientos en fases de escena equivalentes; contrabalancee su orden. Observe tanto la tarea adyacente como la nueva herramienta, conserve todas las ejecuciones y declare el margen de recursos y las condiciones de interrupción. Son requisitos propuestos, no una prueba ejecutada aquí.

La pregunta de producto es si la configuración predeterminada elegida cumple el requisito de coexistencia declarado con la carga probada. Si los controles son demasiado variables para distinguir un efecto, informe de la incertidumbre y mejore la comparación. La evidencia histórica respalda mantener abierto el riesgo de coexistencia; no certifica una configuración sin límite ni establece un límite seguro universal.

### Ejercicio 5: elegir el siguiente experimento

Redacte una próxima comparación acotada entre el funcionamiento con y sin límite junto al Observatory. Nombre un resultado que impediría aprobar una configuración sin límite y explique qué seguiría sin establecer ese resultado.

> **Respuesta:** Compare controles, ejecuciones con límite y ejecuciones sin límite repetidos y con un orden equilibrado, en fases fijas de escena y cámara, con las mismas ventanas de medición temporal y observación. Fije los modos efectivos, el estado del binario y del código fuente, el equipo anfitrión y el controlador, y una regla para la vista adyacente declarada de antemano. Un incumplimiento reproducible sin límite bajo ese protocolo impide aprobarlo para la carga probada; un resultado no concluyente también deja la aprobación sin respaldo. Una aprobación seguiría condicionada a ese equipo, esa carga y ese protocolo, sin demostrar una coexistencia GPU universal.

## Límites de la evidencia

La [lectura de verificación del código fuente](../../../../code/streeling/evidence/brutal-composition-2026-10-22/primary-readback.json) vincula documentos públicos y código. El conjunto de referencia histórico reconstruye fielmente filas seleccionadas de los registros, con nuevos cálculos y un protocolo futuro. No contiene nuevos resultados GPU, diagnósticos de la máquina actual, revisión humana ni resultados de estudiantes. Un despliegue posterior deberá verificar por separado el HTML público del curso.
