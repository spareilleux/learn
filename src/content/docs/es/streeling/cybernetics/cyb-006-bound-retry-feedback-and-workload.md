---
title: Acotar la realimentación de los reintentos antes de añadir workers
description: Acotar la realimentación de los reintentos antes de añadir workers — Cibernética
sidebar:
  label: CYB-006 · Acotar la realimentación de los reintentos antes de añadir workers
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/es/cyb-006-bound-retry-feedback-and-workload.es.md
---

:::note[Streeling University]
**CYB-006** · Acotar la realimentación de los reintentos antes de añadir workers · intermedio · 35 minutos

Generado por el departamento *Cibernética* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/es/cyb-006-bound-retry-feedback-and-workload.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CYB-004](../../cybernetics/cyb-004-observe-before-correcting-a-feedback-loop/), [NET-007](../../network-science/net-007-separate-dag-readiness-from-admission/)
:::

> **Alcance del borrador.** Código público de IX fijado a una revisión, pruebas acotadas de respuestas de herramientas y modelos de probabilidad, carga de trabajo y finalización tardía creados para el curso. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML del curso desplegado. No se ejecutaron un controlador real de reintentos, pruebas de rendimiento de colas, cancelaciones ni escrituras externas.

## La pregunta del proyecto

Un agente no ve un resultado terminal y lanza otro intento. Eso puede ayudar ante un fallo transitorio, pero también puede añadir trabajo mientras el primer intento sigue activo. El [artículo de AWS Builders' Library sobre tiempos de espera y reintentos](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/) explica este riesgo de realimentación. Esta lección construye modelos pequeños explícitos para poder cuestionar una propuesta de controlador de IX antes de instalarla.

El [ejecutor público de IX](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-agent/src/tools.rs#L408-L450), en el commit `456df065ee837e33b5bbe22a4df0616a4fcb76e5`, despacha un paso y sale ante un error. El modelo de resultados inspeccionado no tiene un ciclo de vida de intentos de reejecución. Esta observación acotada del código no demuestra que ningún otro componente de IX pueda reintentar. [NET-007](../../network-science/net-007-separate-dag-readiness-from-admission/) separa los nodos listos del grafo de la capacidad; los reintentos también consumen esa capacidad.

## 1. Contar los intentos por separado de las solicitudes lógicas

El [modelo de reintentos creado para el curso](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/retry-load-model.json) supone intentos independientes, probabilidad de fallo 1/2 y un máximo de 3 intentos por solicitud lógica. Enumera ocho cadenas de resultados de longitud 3, muestreadas de antemano y equiprobables. Los resultados posteriores al primer éxito son recursos de conteo que no se usan, no intentos adicionales ejecutados.

Siempre se realiza un intento. Se realiza un segundo con probabilidad 1/2; un tercero con probabilidad 1/4. Por tanto, el trabajo esperado es `1+1/2+1/4 = 7/4` intentos. Solo tres fallos consecutivos agotan el límite, lo que da probabilidad de fallo terminal 1/8 y probabilidad de éxito 7/8. Son valores del modelo, no fiabilidad medida de la herramienta ni confianza en un artefacto real.

### Ejercicio 1: calcular la amplificación de los reintentos

Según las hipótesis declaradas, calcula los intentos esperados y la probabilidad de éxito. En la cadena premuestreada SFF, ¿cuántos intentos se ejecutan realmente? ¿Ejecuta el modelo los tres resultados para cada solicitud?

> **Respuesta:** Los intentos esperados son 7/4 y la probabilidad de éxito es 7/8. SFF solo ejecuta su primer intento porque tiene éxito. Los resultados premuestreados posteriores se ignoran; la enumeración representa probabilidades y no fuerza tres ejecuciones después del éxito.

## 2. Comparar la carga ofrecida con la capacidad de intentos

Supón que una ilustración mediante un modelo fluido de tasas medias recibe 6 solicitudes lógicas por segundo y puede procesar 10 intentos por segundo. Con el mismo modelo independiente, la demanda esperada es `6*7/4 = 10.5` intentos por segundo. Supera la capacidad en 0.5 unidades de trabajo de intento por segundo, o 15 en 30 segundos. Ese último valor es el exceso medio de trabajo ofrecido, no una muestra con exactamente 15 trabajos en cola.

El umbral de llegada lógica es `10/(7/4) = 40/7` solicitudes por segundo. Permanecer estrictamente por debajo deja capacidad libre en tasa media en esta ilustración simplificada. La igualdad no deja margen y no constituye una prueba general de estabilidad de colas estocásticas. Los costes reales, los fallos correlacionados, los búferes finitos y la planificación necesitan mediciones reales.

### Ejercicio 2: localizar el cuello de botella

Calcula la tasa de intentos ofrecida y el umbral de llegada lógica. ¿Puede el hecho de que 6 sea menor que 10 establecer capacidad libre? ¿Qué representa aquí el número 15?

> **Respuesta:** La demanda ofrecida es 10.5 intentos por segundo y el umbral es 40/7 solicitudes lógicas por segundo. Comparar directamente 6 solicitudes lógicas con 10 intentos mezcla unidades e ignora los reintentos. El 15 representa el exceso medio de demanda de trabajo de intento durante 30 segundos con las hipótesis fluidas, no una longitud de cola observada.

## 3. Separar la suavización de la reducción del trabajo esperado

La espera entre reintentos cambia cuándo se ofrece un intento; la variación aleatoria de esos tiempos dispersa los reintentos sincronizados. En este modelo fijo de resultados independientes, cambiar solo los tiempos de reintento no altera las probabilidades 1/2 o 1/4 de que se necesiten intentos posteriores. Por tanto, no cambia los intentos esperados, 7/4. En un sistema real dependiente de la carga, retrasar un intento podría cambiar su probabilidad de fallo; ese es otro modelo que necesita pruebas.

En cambio, el control de fallo persistente asigna a cada intento probabilidad de fallo 1. Tres intentos consumen entonces 3 unidades y no producen ningún éxito. Reintentar a ciegas un error permanente de validación no puede justificarse con el cálculo anterior de fallos transitorios. Una propuesta útil de controlador necesita clasificar los fallos, acotar la política de intentos y compararla con la referencia más sencilla de un único intento.

### Ejercicio 3: cuestionar una mejora anunciada

Una propuesta añade retrasos aleatorios de reintento y afirma reducir los intentos esperados desde 7/4 sin cambiar el modelo de fallos independientes. ¿Se deriva eso de estas hipótesis? ¿Qué ocurre en el control de fallo persistente?

> **Respuesta:** No. Cambiar solo los tiempos deja intactas las probabilidades fijas de los intentos y el trabajo esperado. Una reducción necesitaría un modelo de resultados o una política diferentes y respaldados por pruebas. En el control de fallo persistente, el límite permite 3 intentos fallidos y el éxito sigue en 0.

## 4. Agotar un tiempo de espera no demuestra que el trabajo se haya detenido

La [traza de finalización tardía creada para el curso](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/delayed-completion-model.json) inicia intentos para una solicitud lógica en los pasos de tiempo 0, 1 y 2. Cada uno dura 3 pasos, así que terminan en 3, 4 y 5. Inmediatamente después del tercer inicio hay 3 intentos activos. El tiempo de espera de observación de un paso era menor que la duración del trabajo; el primer intento seguía activo por construcción.

Una regla de admisión de dos plazas impide el tercer inicio. Deja inicios en 0 y 1, finalizaciones en 3 y 4 y un pico de 2 intentos activos. Aceptar el primer resultado en 3 no cancela el segundo intento en este modelo. La admisión por capacidad, la confirmación de cancelación y la deduplicación de efectos previstos son mecanismos separados. No se detuvo ni reinició ninguna tarea remota real para este ejercicio.

### Ejercicio 4: seguir el intento tardío

Indica los tiempos de finalización y el pico de intentos activos de la traza sin límite y la de dos plazas. Después de aceptar el primer resultado en el paso 3, ¿puede el controlador suponer que el segundo intento se ha detenido?

> **Respuesta:** La primera traza termina en 3, 4 y 5 con pico 3. La traza de dos plazas termina en 3 y 4 con pico 2. No puede suponer que el segundo intento se haya detenido: este modelo no proporciona confirmación de cancelación y ese intento sigue activo hasta 4.

## 5. Hacer refutable la propuesta de controlador

Las [pruebas reales de IX](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/execution-tool-probes.json) incluyen un error de una herramienta deliberadamente desconocida. No proporcionan un paquete completo de resultados parciales. La ausencia de ese paquete no demuestra que no hubiera trabajo previo. Un controlador externo que relance un pipeline entero cada vez que falta un agregado podría repetir efectos ya completados.

Un controlador propuesto debería identificar por separado la solicitud lógica y cada intento, observar inicios y estados terminales, acotar la admisión y el trabajo de reintentos y declarar cómo maneja los resultados desconocidos. Compáralo con una referencia de un único intento mediante resultados aceptados, intentos totales, trabajo activo y efectos sin resolver. Rechaza una ganancia aparente que solo aumente los intentos lanzados mientras los resultados aceptados no cambian. Son criterios de evaluación candidatos, no una nueva política instalada en IX. [PHI-005](../../philosophy/phi-005-test-idempotence-beyond-replayed-values/) examina las pruebas necesarias para llamar idempotentes a los efectos repetidos.

### Ejercicio 5: elegir una observación discriminante

Un controlador afirma haberse recuperado porque lanzó 3 intentos en vez de 1. Los resultados lógicos aceptados siguen en 1 y un intento anterior tiene estado desconocido. ¿Demuestra eso una mejora? Indica dos observaciones necesarias antes de ampliar la política.

> **Respuesta:** No. Los intentos lanzados miden esfuerzo, no una mejora de los resultados aceptados. Observa el inicio y el estado terminal o la cancelación confirmada de cada intento, y concilia el efecto externo previsto mediante su identidad lógica. Compara también el trabajo total de intentos y los resultados aceptados con la referencia; un resultado anterior desconocido no puede sustituirse por una detención supuesta.

## Tarea del estudiante con acceso a las fuentes

Usa la [tarea preparada](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/learner-task.md) para reconstruir la enumeración de probabilidades, la carga con unidades coherentes y la traza tardía. Explica un criterio de rechazo de una propuesta de reintentos. Los resultados reales de estudiantes, revisión humana y controlador en ejecución siguen pendientes.
