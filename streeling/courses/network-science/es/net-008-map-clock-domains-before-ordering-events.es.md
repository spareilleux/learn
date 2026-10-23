---
module_id: net-008-map-clock-domains-before-ordering-events
department: network-science
course: "Relacionar dominios de reloj antes de ordenar eventos"
level: intermediate
prerequisites: ["net-004-semantic-backpressure-and-evidence-dependencies", "mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Relacionar dominios de reloj antes de ordenar eventos

> **Alcance del borrador.** Coordenadas didácticas de relojes, cálculos de modelo afín y lectura de fuentes primarias y código. Quedan pendientes las revisiones humanas técnica, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se midieron sincronización de relojes, pruebas de navegador, latencia de mensajes de agentes ni temporización de hardware.

## La pregunta del proyecto

Un agente de audio informa de un tiempo programado en segundos; un agente de interfaz informa del tiempo de una devolución de llamada en milisegundos. ¿Puede otro agente restar los números o inferir qué acción ocurrió antes? [MCL-007](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md) convierte coordenadas musicales en segundos. Esta lección distingue esa conversión de una relación entre dos relojes. [NET-004](net-004-semantic-backpressure-and-evidence-dependencies.md) exige pruebas vinculadas a su acción; una marca de tiempo también necesita identidad y alcance de su reloj.

El [borrador de trabajo fechado de Web Audio 1.1](https://www.w3.org/TR/2026/WD-webaudio-1.1-20260922/) describe una cronología de audio y una estimación de correspondencia mediante `getOutputTimestamp()`. [High Resolution Time](https://www.w3.org/TR/2026/WD-hr-time-3-20260901/) define marcas de tiempo de rendimiento en milisegundos con un origen temporal. Ambos documentos citados son borradores de trabajo. Leerlos no establece qué funciones implementa un navegador concreto.

## 1. Las unidades por sí solas no alinean orígenes

Sea c una coordenada didáctica de contexto de audio en segundos y p una coordenada de reloj de rendimiento en milisegundos. Estipula el modelo:

```text
p = a + b*c
a = 10000 ms
b = 1000.1 ms per context second
```

Un objetivo en c = 10 se corresponde con p = 20001 ms. Una llamada de programación en p = 19980 ms precede al objetivo convertido en 21 ms. Multiplicar segundos por 1000 sin tener en cuenta origen y ritmo no produce esta comparación.

### Ejercicio 1 — Comparar coordenadas compatibles

Calcula la anticipación entre llamada y objetivo. ¿Por qué carece de sentido restar directamente 19980 de 10 y por qué convertir unidades sigue siendo insuficiente?

> **Respuesta:** El objetivo convertido es 20001 ms y la anticipación es 21 ms. Los números brutos usan unidades y orígenes distintos. Convertir unidades no aporta el desplazamiento de 10000 ms ni la relación supuesta de ritmos. El resultado es condicional al modelo, no un margen medido de programación.

## 2. Dos anclajes ajustan un ritmo; no lo validan

Usa anclajes didácticos (c = 0, p = 10000) y (c = 60, p = 70006). Su pendiente es 60006/60 = 1000.1 ms por segundo de contexto. Respecto a 1000 ms por segundo, la diferencia es 100 partes por millón. Es un ritmo aparente en datos inventados, no deriva observada de un dispositivo.

Un anclaje puede fijar un desplazamiento solo después de suponer un ritmo. Dos anclajes exactos determinan una recta afín, pero no establecen que los relojes sigan siendo afines, no identifican ruido de muestra ni justifican extrapolación indefinida.

### Ejercicio 2 — Identificar la hipótesis ausente

Deriva pendiente, ordenada en el origen y diferencia de ritmo. ¿Qué no podría identificarse solo con el primer anclaje?

> **Respuesta:** La pendiente es 1000.1, la ordenada en el origen 10000 ms y la diferencia relativa de ritmo 100 partes por millón. Con un solo anclaje, muchas pendientes con ordenadas correspondientes pasan por el punto. Hace falta una hipótesis de ritmo o más observaciones emparejadas; una recta ajustada no demuestra por sí sola estabilidad de reloj.

## 3. Distinguir interpolación de extrapolación

El [caso de prueba de relojes](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/clock-map.json) predice p = 40003 ms en c = 30 y p = 130012 ms en c = 120. Mantener la misma ordenada en el origen usando pendiente nominal 1000 predice 130000 ms en c = 120, una discrepancia de 12 ms bajo el modelo didáctico. El punto en 30 está entre anclajes; el de 120 está más allá.

### Ejercicio 3 — Acotar la afirmación de marca temporal

Calcula ambas predicciones y la discrepancia en 120. ¿Convierte el ajuste de dos anclajes la predicción posterior en un evento observado o valida su incertidumbre?

> **Respuesta:** Las predicciones son 40003 y 130012 ms; el valor a ritmo nominal en 120 es 130000 ms, con diferencia de 12 ms. Ninguna predicción es un evento observado. Extrapolar requiere una hipótesis de modelo continuada y su propia evaluación de error, especialmente tras suspensión, reinicio o cambios de dispositivo.

## 4. Propagar cotas antes de aceptar un punto reservado

Supón que la coordenada de rendimiento de cada anclaje tiene error de como máximo 0.5 ms, las coordenadas de contexto son exactas y se aplica una relación afín única. En c = 90, los pesos de interpolación extendidos más allá de los anclajes son -0.5 y 1.5. El valor central predicho es 100009 ms, con cota determinista de error de 1 ms. Es una cota bajo hipótesis declaradas, no un intervalo de confianza.

Aporta ahora un valor didáctico reservado de 100011 ms con error máximo 0.5 ms. El intervalo de predicción es 100008 a 100010 ms; el del punto reservado es 100010.5 a 100011.5 ms. No se intersectan.

### Ejercicio 4 — Permitir que falle el modelo

Calcula la cota usando los pesos absolutos y compara el residuo de 2 ms con el margen combinado de error. ¿Qué se ha refutado y qué causa sigue siendo desconocida?

> **Respuesta:** La cota es 0.5 por (0.5 + 1.5) = 1 ms. Incluir el error reservado permite residuo máximo 1.5 ms, menor que los 2 ms didácticos. La relación afín, las hipótesis de coordenadas y las cotas de error combinadas son incompatibles con este registro reservado. No aísla deriva, error de marca temporal, cambio de origen ni otra causa. No reajustes silenciosamente para volver a etiquetar el modelo original como verificado.

## 5. Conservar pruebas de reloj a través del traspaso

El [componente de panel de la revisión fijada](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Apps/ga-dashboard/src/app/shared/progression.component.ts#L84-L167) programa una devolución de llamada del navegador y después lee `AudioContext.currentTime` para solicitar inicios de osciladores. El archivo examinado no contiene marcas de salida emparejadas ni una correspondencia medida de relojes. Es un demostrador seleccionado, no una prueba sobre todas las interfaces de reproducción de GA.

La marca temporal emparejada del borrador de Web Audio es una estimación cercana a una posición del flujo de salida; no es una observación por micrófono ni un protocolo general de sincronización entre anfitriones. También advierte contra tratar la diferencia entre `currentTime` y la coordenada devuelta del flujo de salida como una estimación fiable de latencia de salida. Conserva identidad de dispositivo, contexto y ciclo de vida al interpretar esas pruebas.

### Ejercicio 5 — Proponer un comprobante acotado

¿Qué debe acompañar a una comparación de marcas temporales entre agentes? Da una alternativa más sencilla a introducir un DSL de relojes, una condición de rechazo y una medición aún necesaria para latencia física de audio.

> **Respuesta:** Conserva identificadores de reloj, unidades, orígenes, anclajes emparejados, hipótesis de modelo y error, intervalo de validez, cambios de ciclo de vida, identidad del código y extremos de comparación. Un único reloj monótono común de adquisición puede ser más sencillo que un protocolo nuevo. Rechaza o aplaza comparaciones cuando las correspondencias fallen las cotas reservadas o cambios de identidad las invaliden. Una afirmación de latencia física de audio necesita una observación de salida definida y calibrada independientemente. Es una propuesta de registro orientativo; no se implementaron un esquema de comprobante, un servicio de sincronización ni un DSL de relojes.

## Tarea del estudiante con acceso a las fuentes

Prepara una revisión de traspaso con la anticipación de 21 ms, el ajuste y ritmo de dos anclajes, ambas predicciones posteriores, la cota ponderada de error y el rechazo del punto reservado. Indica un caso de reinicio de identidad del reloj y una alternativa de adquisición con reloj común. Registra ayuda e hipótesis sin resolver. La [rúbrica de revisión](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/reviewer-rubric.json) está preparada, sin ninguna decisión real de estudiante.

El [registro de lectura primaria](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/primary-reading.json) distingue especificaciones de observaciones. No se establecieron sincronización productiva de agentes, adaptador desplegado, beneficio para oyentes ni estabilidad de relojes.
