---
module_id: pm-007-measure-playback-latency-at-the-user-boundary
department: product-management
course: "Medir la latencia de reproducción desde el punto de vista del usuario"
level: intermediate
prerequisites: ["pm-005-interpret-brutal-coexistence-experiments", "net-008-map-clock-domains-before-ordering-events"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Medir la latencia de reproducción desde el punto de vista del usuario

> **Alcance del borrador.** Registros didácticos de extremos de medición, resúmenes exactos y lectura de código y especificaciones fijados a una revisión. Quedan pendientes las revisiones humanas técnica, musical, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se probaron un navegador, una guitarra, un oyente ni un banco real de pruebas de latencia.

## La pregunta del proyecto

Un agente acelera un cálculo de reproducción. ¿Ha oído antes la respuesta el guitarrista? [PM-005](pm-005-interpret-brutal-coexistence-experiments.md) muestra por qué la velocidad propia del productor no basta. Aquí usamos un componente concreto seleccionado de progresión de GA y separamos solicitudes de programación de ejecución de eventos y observación de salida. [NET-008](../../network-science/en/net-008-map-clock-domains-before-ordering-events.md) aporta las comprobaciones de dominios de reloj.

## 1. Un retraso solicitado al temporizador no es un tiempo medido de devolución de llamada

En el commit de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`, el [componente de progresión](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Apps/ga-dashboard/src/app/shared/progression.component.ts#L84-L116) usa [setTimeout](https://html.spec.whatwg.org/multipage/timers-and-user-prompts.html#timers) con duraciones acumuladas de acordes. La especificación de temporizadores HTML no garantiza programación exacta de las devoluciones de llamada.

Para una secuencia didáctica, las posiciones solicitadas de las devoluciones son 0, 1000 y 2000 ms; las anotaciones ficticias de ejecución son 12, 1080 y 2015 ms. Son registros inventados, no trazas extraídas.

### Ejercicio 1 — Separar plazos de eventos

Calcula el retraso de cada devolución de llamada y los dos intervalos entre ellas. ¿Establece pedir una separación de 1000 ms que las llamadas ejecutadas o acordes audibles tengan esa separación?

> **Respuesta:** Los retrasos son 12, 80 y 15 ms. Los intervalos de llamadas ejecutadas son 1068 y 935 ms, pese a intervalos solicitados de 1000 ms. Una solicitud no establece separación de ejecución ni salida de audio. Estas diferencias didácticas no diagnostican la máquina actual.

## 2. Un rasgueo programado es otro límite

El [código de solicitud de audio](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Apps/ga-dashboard/src/app/shared/progression.component.ts#L140-L190) lee un tiempo de contexto de audio cuando se ejecuta la devolución de llamada. Solicita cada cuerda sonora en ese anclaje más su índice físico de cuerda por 0.03 segundos, usando índices desde cero. Se omiten cuerdas silenciadas, pero no se compactan los índices restantes.

Para la lista didáctica de trastes siguiente, los índices de las cuerdas que suenan son 1, 3 y 4:

```text
frets = [-1, 0, -1, 2, 3, -1]
```

### Ejercicio 2 — Conservar la secuencia solicitada

Calcula desplazamientos solicitados y separaciones de las cuerdas sonoras. ¿Conservaría las solicitudes del código asignar rangos consecutivos solo a cuerdas sonoras? ¿Son alguno de los dos conjuntos de números inicios físicos observados?

> **Respuesta:** Los desplazamientos son 0.03, 0.09 y 0.12 segundos, con separaciones 0.06 y 0.03 segundos. Compactar a rangos solicitaría en cambio 0, 0.03 y 0.06 segundos, cambiando la programación. Ningún conjunto es un inicio físico observado. El código seleccionado usa un oscilador triangular y una envolvente, no una medición de guitarra real.

## 3. Medir el intervalo que nombra la promesa del producto

La [tabla didáctica de trazas](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/playback-endpoints.json) define cuatro etapas secuenciales sobre un único reloj común estipulado en milisegundos: acción a gestor, cálculo del gestor a llamada de programación, llamada a límite solicitado de salida y límite solicitado a una anotación didáctica de inicio de salida. No hay solapamiento entre esos intervalos en este modelo didáctico.

| Configuración | Despacho del gestor, ms | Cálculo, ms | Espera programada, ms | Salida más allá del límite solicitado, ms |
| --- | --- | --- | --- | --- |
| A | 4 | 4 | 72 | 10, 15, 20, 25 |
| B | 4 | 6 | 40 | 10, 15, 20, 25 |

Los valores resultantes de acción a salida son 90, 95, 100 y 105 ms para A; 60, 65, 70 y 75 ms para B. Las anotaciones de salida y los orígenes compartidos son premisas didácticas, no capturas acústicas reales ni observaciones simultáneas de dos configuraciones.

### Ejercicio 3 — Clasificar con la métrica correcta

Calcula las medianas de duración de cálculo y de acción a salida para ambas configuraciones y cada diferencia emparejada. ¿Qué configuración es más rápida en cada límite? ¿Establece esto una mejora causal en GA?

> **Respuesta:** La mediana de cálculo es 4 ms para A y 6 ms para B. La mediana de acción a salida es 97.5 ms para A y 67.5 ms para B; las cuatro diferencias emparejadas de extremo a extremo son 30 ms. A calcula más rápido, mientras B tiene menor duración didáctica en el punto de salida del usuario. Ilustra dependencia de los extremos elegidos, no una mejora medida ni causal de GA. La espera programada deliberada forma parte de este intervalo definido y debe seguir visible.

## 4. Una regla de latencia es solo una condición de aprobación

Para este ejemplo inventado, declara que cada valor registrado de acción a salida debe ser como máximo 80 ms. A no tiene ningún ensayo aprobado; B tiene cuatro. Ambos rangos abarcan 15 ms, así que B no ha reducido ese descriptor concreto de dispersión. Cuatro ensayos didácticos no establecen un percentil de cola en producción ni aceptabilidad perceptiva.

### Ejercicio 4 — Tomar la decisión acotada

Aplica la regla de 80 ms, compara los rangos e indica qué sigue faltando antes de recomendar a guitarristas una nueva configuración predeterminada de reproducción.

> **Respuesta:** A pasa 0 de 4; B pasa 4 de 4. Ambos rangos son 15 ms. Solo B satisface la regla declarada de solo latencia en estos registros inventados. Una decisión real sobre configuración predeterminada sigue necesitando adquisición real emparejada, registros de fallos y salidas ausentes, estado efectivo de navegador y dispositivo, comprobaciones de calidad sonora y rasgueo previsto, cobertura repetida de cargas y evaluación adecuada de músicos u oyentes. Estos números no aprueban ningún lanzamiento real.

## 5. Separar estimaciones de API de un resultado capturado del usuario

El [borrador de trabajo fechado de Web Audio 1.1](https://www.w3.org/TR/2026/WD-webaudio-1.1-20260922/) define estimaciones de latencia de procesamiento y salida con límites concretos. Por sí solas no miden un intervalo de acción a inicio acústico. El componente examinado de GA solicita inicios de osciladores y fija el paso resaltado; no contiene adquisición de inicio de salida. Un acorde resaltado o una solicitud correcta de inicio no son un comprobante de inicio audible.

### Ejercicio 5 — Preparar una comparación que pueda fallar

Escribe un plan acotado de adquisición real para un cambio propuesto de reproducción. Identifica eventos de inicio y fin, correspondencia de relojes, código y modo efectivo, salida ausente, límites temporales y musicales y un resultado que rechazaría el cambio. Compara una alternativa de medición más sencilla con un nuevo DSL de telemetría.

> **Respuesta:** Fija revisión del código, navegador y dispositivo, ciclo de vida del contexto, ruta efectiva de salida, patrón y carga. Define una acción de entrada y un inicio de salida detectado independientemente con temporización común calibrada o una correspondencia explícita probada; conserva umbrales de detección, incertidumbre, registros brutos y salidas ausentes. Repite comparaciones emparejadas con orden contrabalanceado y una regla declarada antes de adquirir datos, y comprueba temporización del rasgueo previsto y calidad sonora. Rechaza un cambio que falle los límites declarados de latencia y calidad o cuya comparación tenga pruebas temporales inválidas. Un experimento de bucle de retorno con reloj común puede ser más sencillo que un DSL nuevo. Aún necesita calibración y validación reales; aquí no se implementó ningún instrumento ni contrato de telemetría.

## Tarea del estudiante con acceso a las fuentes

Produce un registro breve de decisión con errores e intervalos de devoluciones de llamada, solicitudes de rasgueo por índice físico, ambas clasificaciones de métricas, las cuatro diferencias emparejadas y el resultado de la regla de latencia. Añade un plan real de adquisición y un caso explícito de rechazo. Registra ayuda e incógnitas. La [rúbrica de revisión](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/reviewer-rubric.json) prepara criterios, pero no registra ningún resultado de estudiante.

El [comprobante de fuentes](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/primary-readback.json) vincula los archivos examinados. Son observaciones acotadas del código de un demostrador y modelos didácticos de extremos de medición, no reproducción real verificada, una nueva configuración predeterminada de producción, beneficio para oyentes ni HTML desplegado del curso.
