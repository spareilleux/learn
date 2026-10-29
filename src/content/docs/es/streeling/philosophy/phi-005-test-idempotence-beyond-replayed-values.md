---
title: Probar la idempotencia más allá de los valores devueltos al repetir
description: Probar la idempotencia más allá de los valores devueltos al repetir — Filosofía
sidebar:
  label: PHI-005 · Probar la idempotencia más allá de los valores devueltos al repetir
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/es/phi-005-test-idempotence-beyond-replayed-values.es.md
---

:::note[Streeling University]
**PHI-005** · Probar la idempotencia más allá de los valores devueltos al repetir · intermedio · 35 minutos

Generado por el departamento *Filosofía* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/es/phi-005-test-idempotence-beyond-replayed-values.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHI-002](../../philosophy/phi-002-when-is-an-advisory-decision-justified/), [NET-007](../../network-science/net-007-separate-dag-readiness-from-admission/)
:::

> **Alcance del borrador.** Respuestas reales acotadas de herramientas de IX, código público de caché y ejecución fijado a una revisión y contraejemplos de transiciones de estado creados para el curso. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML del curso desplegado. No se probaron un almacén duradero de deduplicación, recuperación tras fallos, un ejecutor de efectos concurrentes ni una modificación externa real.

## La pregunta del proyecto

Un agente repite un pipeline y ve el mismo resultado. ¿Qué justifica esa observación? La [definición de idempotencia de RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html#section-9.2.2) trata del efecto previsto de repetir una solicitud, sin exigir respuestas idénticas byte a byte. Su semántica de métodos HTTP no se aplica automáticamente a herramientas arbitrarias de agentes. Usamos esa distinción para examinar afirmaciones sobre repeticiones en IX y pequeños contraejemplos matemáticos.

El [ejecutor público de IX](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-agent/src/tools.rs#L408-L450), fijado en `456df065ee837e33b5bbe22a4df0616a4fcb76e5`, puede devolver valores en caché cuando se proporciona un nombre de activo. Almacenar un cálculo en caché y deduplicar un efecto externo previsto son contratos distintos. [PHI-002](../../philosophy/phi-002-when-is-an-advisory-decision-justified/) distinguía pruebas y autoridad; esta lección pone a prueba una afirmación concreta mediante contraejemplos y límites de observación.

## 1. Enunciar la propiedad que se prueba

El [modelo de estado creado para el curso](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/effect-identity-model.json) compara dos operaciones sobre un estado entero. Set7 sustituye el estado por 7; el incremento suma 1. Para los estados iniciales -2, 0 y 5, aplicar Set7 dos veces da el mismo estado final que aplicarlo una vez. Incrementar dos veces da una unidad más que incrementar una vez.

Ambas operaciones pueden devolver la etiqueta de respuesta «ok» después de cada llamada. Por tanto, secuencias de respuestas iguales no distinguen la transición de estado prevista idempotente de la no idempotente. El invariante debe identificar el estado o efecto comparado. Los registros de auditoría pueden seguir anotando cada solicitud sin cambiar la idempotencia de la operación prevista; no amplíes silenciosamente la propiedad a todos los efectos accesorios.

### Ejercicio 1: construir un contraejemplo

Partiendo de 0, indica el estado tras una y dos llamadas a Set7, y después tras uno y dos incrementos. Ambas devuelven «ok» cada vez. ¿Establece la igualdad de respuestas el mismo efecto previsto?

> **Respuesta:** Set7 da 7 y 7; el incremento da 1 y 2. En ambos casos se producen respuestas «ok» idénticas, así que la igualdad de respuestas por sí sola no establece la idempotencia del cambio de estado previsto.

## 2. Leer las pruebas reales de repetición dentro de su alcance

Dos [llamadas reales al pipeline de IX](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/execution-tool-probes.json) ejecutan los mismos tres pequeños pasos estadísticos. Sus mapas de resultados numéricos coinciden, con medias 2, 5 y 15. Ambas indican una lista vacía de aciertos de caché y claves de caché nulas. El esquema expuesto de la herramienta no ofrecía un campo de nombre de activo, así que este ejercicio no lo eludió para solicitar caché. Los resultados iguales aquí no son prueba de un acierto de caché.

El orden de ejecución indicado de los pasos hermanos cambia entre llamadas. Por tanto, los paquetes completos de respuesta no son iguales aunque sí lo sean los mapas numéricos. Las duraciones indicadas son 0 ms; el ejecutor inspeccionado registra milisegundos transcurridos, de modo que un campo cero no prueba coste computacional cero. La revisión del servicio es desconocida y ninguna llamada modifica un recurso de negocio externo.

### Ejercicio 2: acotar la conclusión sobre la repetición

¿Qué establecen las medias iguales 2, 5 y 15 para estas entradas? ¿Puede la persona revisora afirmar un acierto de caché medido, paquetes completos idénticos, coste cero o efectos externos deduplicados?

> **Respuesta:** Las salidas numéricas observadas coinciden para estas pequeñas entradas repetidas. Las listas de aciertos vacías y las claves nulas no proporcionan un acierto de caché medido; el orden de ejecución distinto refuta la igualdad de paquetes completos. Cero milisegundos informados no prueban coste cero y no se probó ninguna deduplicación de efectos externos.

## 3. Identificar la solicitud lógica, no solo sus argumentos

El [artículo de AWS Builders' Library sobre API idempotentes](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/) explica por qué argumentos iguales pueden representar un reintento o una operación prevista distinta. El modelo secuencial creado para el curso explicita esa distinción. Dos solicitudes de incremento con la misma clave lógica job-A aplican el incremento previsto una vez bajo una regla ideal de deduplicación atómica y dan un estado final 1. Asignar una clave nueva a cada intento lo aplica dos veces y da 2. Dos trabajos lógicos realmente distintos también pueden dar intencionadamente 2 con los mismos argumentos.

Esta regla matemática supone registro y aplicación del efecto atómicos. No los implementa. Los intentos concurrentes, los fallos entre la modificación y el registro del token, la retención de claves y los cambios de intención necesitan un contrato real y pruebas de fallos antes de justificar una afirmación sobre un servicio duradero.

### Ejercicio 3: distinguir los reintentos del trabajo nuevo

Partiendo de 0, compara las claves job-A/job-A con job-A-attempt-1/job-A-attempt-2 bajo la regla ideal. ¿Por qué no deben fusionarse automáticamente dos trabajos distintos con argumentos iguales?

> **Respuesta:** La clave lógica repetida aplica un incremento y termina en 1; las claves nuevas de intento aplican dos y terminan en 2. Dos trabajos lógicos distintos pueden buscar dos efectos pese a tener argumentos iguales. La igualdad de argumentos por sí sola no identifica la intención lógica de quien llama.

## 4. Examinar qué vincula realmente la clave de caché

En el ejecutor de la revisión fijada, la clave de caché se deriva del nombre del activo, el nombre de la herramienta y los argumentos resueltos serializados. La expresión no incluye directamente el identificador del paso, la revisión de la implementación de la herramienta ni la revisión del estado externo. Es una observación acotada del código, no una afirmación de que todas las cachés de IX tengan la misma política ni de que todos esos campos sean siempre necesarios.

Para un cálculo puro con un contrato de entrada versionado adecuado, reutilizar valores puede ser apropiado. Para una operación cuyo significado depende de estado externo mutable o de una implementación modificada, esas premisas necesitan más examen. Una clave coincidente no demuestra que la clave cubra todas las entradas semánticas ni que un efecto externo anterior se haya confirmado de forma duradera una sola vez. Aquí no se realizó una ejecución con acierto de caché ni una prueba deliberada de colisión.

### Ejercicio 4: cuestionar una afirmación insuficiente de identidad

La implementación de una herramienta cambia mientras el nombre del activo, el nombre de la herramienta y los argumentos resueltos siguen iguales. ¿Vincula directamente la expresión de clave inspeccionada la nueva revisión de implementación? ¿Bastaría un valor devuelto desde caché para establecer una deduplicación correcta de efectos externos?

> **Respuesta:** No. Esa expresión no incluye directamente la revisión de implementación. Un valor en caché por sí solo tampoco establece una deduplicación duradera de un efecto externo. La persona revisora necesita una política justificada de entradas semánticas y versiones, y pruebas sobre el contrato del efecto; esta inspección del código no aporta esas pruebas.

## 5. Conservar la incertidumbre después de un error

La prueba deliberada de herramienta ausente indica un fallo en el paso b sin un paquete final de resultados parciales. En el ejecutor de la revisión fijada, puede despacharse un paso anterior antes de que un error posterior haga salir del bucle. Para el servicio real de revisión desconocida, el error devuelto por sí solo no proporciona una traza completa de intentos. La ausencia de un agregado devuelto no debe convertirse en prueba de que no hubo trabajo previo.

Para probar una afirmación sobre efectos repetidos, declara de antemano el efecto previsto, la identidad lógica, los reintentos admisibles y el estado observable. Compara solicitudes únicas y repetidas, incluyendo un caso de respuesta perdida y la recuperación tras un intento interrumpido. Concilia el efecto mismo, no solo las etiquetas de éxito. Son pruebas propuestas, no resultados obtenidos ni un mecanismo de deduplicación instalado. [CYB-006](../../cybernetics/cyb-006-bound-retry-feedback-and-workload/) muestra por qué reintentar un resultado desconocido también puede amplificar el trabajo activo.

### Ejercicio 5: identificar la prueba que falta

Un pipeline devuelve un error en b. Una persona revisora concluye que el paso anterior a no produjo efecto y autoriza un reintento incondicional de todo el pipeline. ¿Qué carece de respaldo? Propón una observación más discriminante sin inventar una recuperación satisfactoria.

> **Respuesta:** El error por sí solo no demuestra que a nunca se ejecutara o no produjera efecto. Examina las observaciones por intento y concilia el efecto previsto bajo la misma identidad de solicitud lógica, o apóyate en un contrato de idempotencia validado por separado que cubra ese efecto. Esta prueba no demostró ninguna recuperación satisfactoria ni que fuera seguro un reintento incondicional.

## Tarea del estudiante con acceso a las fuentes

Completa la [tarea preparada](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/learner-task.md) distinguiendo igualdad de valores devueltos, igualdad de efectos, identidad y observaciones ausentes. Usa los contraejemplos fijados para rechazar una afirmación demasiado amplia sobre la repetición. Las decisiones humanas y de los estudiantes siguen pendientes.
