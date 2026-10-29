---
title: Poner a prueba la contrapresión semántica con dependencias de pruebas
description: Poner a prueba la contrapresión semántica con dependencias de pruebas — Ciencia de redes
sidebar:
  label: NET-004 · Poner a prueba la contrapresión semántica con dependencias de pruebas
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/es/net-004-semantic-backpressure-and-evidence-dependencies.es.md
---

:::note[Streeling University]
**NET-004** · Poner a prueba la contrapresión semántica con dependencias de pruebas · intermedio · 40 minutos

Generado por el departamento *Ciencia de redes* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/es/net-004-semantic-backpressure-and-evidence-dependencies.es.md) · [Mi diario](../../journal/)

Requisitos previos: [NET-003](../../network-science/net-003-worker-lane-coverage-and-fragility/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Ciencia de Redes** | Intermedio | 40 minutos | Borrador en español de una lección basada en una hipótesis; revisión y publicación pendientes

## Objetivos y pregunta del proyecto

Después de esta lección, podrás distinguir un corte por capacidad o modo de un prerrequisito de prueba incumplido, dibujar las dependencias de comprobantes de una acción propuesta, evaluar una pequeña regla de composición sin confundir un comprobante ausente con una denegación de autoridad e indicar cuándo debe rechazarse la nueva regla. **Pregunta del proyecto:** ¿podrían las dependencias de pruebas por acción permitir que avance el trabajo independiente e impedir que un borrador de Streeling se dé por revisado o publicado antes de disponer de sus comprobantes requeridos? Es una hipótesis de diseño, no un controlador desplegado en Demerzel, Gaia o Learn.

## 1. Partir del control existente

[NET-003](../../network-science/net-003-worker-lane-coverage-and-fragility/) modela el grafo de Demerzel entre workers y clases de trabajo. Su [política de lanes](https://github.com/GuitarAlchemist/Demerzel/blob/ecdc6c27559bb1a11343cfad33687465893e9891/state/driver/aiw-worker-lanes.json) y su [selector consultivo](https://github.com/GuitarAlchemist/Demerzel/blob/ecdc6c27559bb1a11343cfad33687465893e9891/scripts/aiw_lane_selector.py) fijados cortan caminos asignados cuando un modo de fanout bloquea su clase de trabajo. Una clase bloqueada recibe `SYSTEM.BACKPRESSURE_HIGH`. El selector también comprueba los roles prohibidos y asignados, pero no examina las pruebas de revisión de la materia de un curso, un SHA de la fuente de Learn ni un resultado de un estudiante. Su código de salida 0 significa que se ha evaluado; la decisión está en los datos JSON. Son observaciones del código en `ecdc6c27559bb1a11343cfad33687465893e9891`, no un informe del estado actual de los workers.

Llama **semántica** a la contrapresión solo si depende de una propiedad declarada del *resultado solicitado* y de sus pruebas. Por ejemplo, una regla de modo puede aplazar todas las funcionalidades nuevas durante DRAINING. Una regla propuesta de publicación de cursos aplazaría, en cambio, `publish(NET-003)` cuando faltara una revisión humana requerida para la misma revisión de la fuente, permitiendo continuar un análisis independiente de una fixture de audio. Ninguna regla crea un revisor humano ni concede autoridad para fusionar cambios. Un simple indicador de revisión podría bastar; la formulación por dependencias solo justifica su complejidad si mejora las decisiones en una comparación medida.

### Ejercicio práctico 1: identificar el origen de la contrapresión

En DRAINING, el selector fijado de Demerzel bloquea el rol principal `builder_fixer` de `claude` porque `net_new_feature` está bloqueado por el modo, pero recomienda su rol secundario `test_author` porque `fix` sigue permitido. Por separado, un curso tiene `review.completed=false`. ¿Qué condición es un corte de modo, cuál podría convertirse en un prerrequisito de prueba incumplido y autoriza alguna de ellas a publicar el curso?

> **Respuesta:** Las dos decisiones de lane son decisiones de modo y rol del selector. La revisión ausente del curso podría dejar incumplido un prerrequisito de publicación *propuesto* si el contrato de publicación exige esa revisión. Ninguna concede autoridad de publicación. Recomendar el rol de autor de pruebas no satisface una revisión de la materia ausente ni convierte un borrador en un curso aprobado.

## 2. Dibujar dependencias entre acciones y comprobantes

Representa una acción candidata `a` y las pruebas que requiere mediante un grafo dirigido de dependencias con un nodo explícito `all(a)`. Cada arista `receipt r -> all(a)` aporta un prerrequisito; `all(a) -> a` habilita la acción solo cuando todos los comprobantes requeridos están presentes, son válidos para el alcance declarado y están vinculados a la misma revisión de la fuente. Esta flecha es un prerrequisito, no una orden de crear un comprobante. Para `publish(NET-003)`, considera tres prerrequisitos candidatos: una revisión del curso guardada en un commit `S`, una compilación de Learn hecha a partir de `S` y un dictamen humano sobre la materia referido a `S`. Un intento de un estudiante puede proceder de un piloto accesible antes de publicar; de lo contrario, es un resultado de aprendizaje posterior a la publicación, no un prerrequisito para hacer accesible el curso. Este es un **contrato didáctico** para evaluar, no la política de despliegue implementada en el sitio actual. La autorización y la revisión lingüística por personas que dominen los idiomas serían condiciones adicionales e independientes para una publicación real.

Define `ready(a,S)` como la conjunción de los predicados de comprobantes declarados para la acción. Un dictamen humano ausente es `unknown` o `not supplied`, no `false expertise`; una revisión diferente invalida la vinculación, aunque a un revisor le gustara una versión anterior. No conviertas un recuento como «dos de tres comprobantes» en un permiso parcial. Mantén visible la entrada incumplida. El grafo también debería contener una acción independiente, como `analyze(AUD-003 fixture)`, con sus propias entradas; una revisión ausente de NET-003 no debería bloquear automáticamente esa acción.

### Ejercicio práctico 2: evaluar una dependencia Y

Supón que existen la fuente del curso y una compilación de Learn correspondiente a `S`, pero falta el dictamen sobre la materia. El análisis de la fixture de audio tiene su comprobante de entrada requerido. ¿Qué prerrequisito queda incumplido y qué sigue siendo ejecutable?

> **Respuesta:** La entrada del dictamen sobre la materia en `all(publish)` está incumplida, por lo que el nodo `all` no puede habilitar `publish(NET-003,S)` según el contrato didáctico enunciado. Es un prerrequisito Y, no un corte de una sola arista: las entradas de fuente y compilación siguen presentes. `analyze(AUD-003 fixture)` sigue siendo ejecutable mediante sus entradas independientes y el borrador puede seguir revisándose. El resultado es «prerrequisitos de publicación incompletos», no «todo el sistema de agentes está detenido».

## 3. Componer una regla sin inventar un motor de ejecución

Lo siguiente es un **boceto de notación**, no un DSL ni una API implementados:

```text
publish(course, S) <- all(
  committed(course, S),
  build_from(S),
  human_subject_review(course, S)
)
```

`all` es una conjunción pura de comprobaciones tipadas de comprobantes. Cada comprobación devuelve un dictamen acotado y la identidad de la prueba examinada. Una búsqueda fallida debe incluir un motivo como `missing`, `stale_revision` o `invalid_scope`; reducirlos a un solo bit falso ocultaría la acción correctiva. Una comprobación posterior de autorización no es otro comprobante factual que un agente pueda fabricar. Este boceto compone predicados al nivel de una acción y sus obligaciones de prueba, en lugar de pedir a los agentes que intercambien llamadas de API de bajo nivel. No especifica un analizador, un ejecutor de efectos, un protocolo de bloqueo ni una autoridad de gobernanza.

### Ejercicio práctico 3: detectar una discrepancia de revisión

Un dictamen humano nombra el SHA de la fuente `S0`, mientras que la compilación y la publicación propuesta nombran `S1`. Están presentes los tres *tipos* de comprobantes. ¿Qué devuelve el boceto y por qué sería erróneo comprobar solo su número?

> **Respuesta:** `human_subject_review(course,S1)` está incumplido porque el dictamen está vinculado a `S0`, así que `publish(course,S1)` se aplaza según el boceto. Tres archivos no son tres pruebas válidas para una misma revisión. El operador necesita una nueva revisión de `S1` o una decisión documentada del revisor que cubra expresamente su diff; la notación por sí misma no puede decidir una equivalencia de fondo.

## 4. Intentar refutar el mecanismo adicional

El contraargumento más sólido es que los indicadores existentes `review.completed` y `publish.completed`, una protección del SHA de la fuente y comprobaciones CI ordinarias podrían expresar este caso de forma más sencilla. Un grafo y un DSL podrían duplicar políticas, producir dependencias obsoletas o circulares, bloquear trabajo útil por un falso positivo, añadir demora a la revisión y crear un atractivo indicador «verde» sin autoridad. Un comprobante puede estar presente sintácticamente y ser erróneo en su contenido. Por eso, una regla de prerrequisitos semánticos puede ser peor que una lista manual clara.

Compara la propuesta con esa referencia más sencilla mediante un conjunto finito de cambios reales de cursos con datos sensibles omitidos y comprobantes alterados deliberadamente. Antes de probar, define los resultados: la admisión errónea de una publicación sin revisar o con fuente obsoleta debe permanecer en cero; cuenta los bloqueos innecesarios de trabajo independiente; mide el tiempo de decisión; y registra si los revisores pueden explicar cada decisión. Rechaza la propuesta si no aporta una mejora observable de precisión o de flujo frente a los indicadores simples, si oculta una decisión humana requerida o si sus obligaciones de prueba no pueden mantenerse al ritmo real de cambios de la fuente. Una revisión crítica independiente debe examinar la regla antes de que se vuelva normativa.

### Ejercicio práctico 4: encontrar un falso positivo

Una condición global bloquea todas las tareas de Demerzel mientras NET-003 carece de un dictamen humano sobre la materia. El equipo también necesita volver a ejecutar una fixture de señal de IX independiente cuyos datos de entrada y autoridad ya están disponibles. ¿Qué métrica pondría de manifiesto el error y cuál es la corrección más sencilla?

> **Respuesta:** Cuenta este caso como un bloqueo innecesario de trabajo independiente. Limita la condición de revisión a `publish(NET-003,S)` y sus acciones dependientes, dejando intacta la ruta de la fixture de IX. Una lista de comprobación por acción podría hacer la misma corrección sin un nuevo DSL; el grafo de dependencias solo se justifica si maneja mejor casos adicionales.

## 5. Aplicar la hipótesis a un registro de proyecto fijado

En el commit de la fuente de Demerzel [`29e83e0`](https://github.com/GuitarAlchemist/Demerzel/blob/29e83e08120cba99452020c54c31680c28b32c3e/state/streeling/course-productions/cp-network-science-2026-10-11-003.json), el registro de producción de NET-003 tiene `review.completed=false` y `publish.completed=false`. El curso inglés dispone de un [comprobante de reproducción local del selector](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/reviews/net-003-selector-replay-2026-10-12.json), pero ese comprobante solo demuestra el experimento acotado del selector consultivo. No es un dictamen humano sobre la materia, un resultado de aprendizaje ni un comprobante de despliegue de Learn. La [protección de sincronización de Learn](https://github.com/spareilleux/learn/blob/3f4de745f56e81f237159997473253546d7f6d64/scripts/sync-streeling.mjs), independiente, rechaza una copia de la fuente de Demerzel con cambios locales cuando se pretende declarar su HEAD como procedencia; no aprueba el contenido del curso. El registro y la protección son artefactos concretos del proyecto, mientras que la regla propuesta dependiente de pruebas sigue sin implementarse.

### Ejercicio práctico 5: redactar una decisión limitada por las pruebas

Usando solo esos artefactos fijados, escribe el estado de `publish(NET-003,S)` y una acción siguiente. Nombra una observación que refutaría la afirmación de que una futura regla de contrapresión semántica mejoró este flujo de trabajo.

> **Respuesta:** La publicación no es admisible según el contrato didáctico: el registro deja explícitamente revisión y publicación en falso, y la reproducción del selector no es un dictamen sobre la materia. Continúa preparando la fuente y la revisión; obtén un dictamen humano sobre la materia vinculado a la revisión aceptada antes de reconsiderar la publicación. Un intento de un estudiante puede recogerse mediante un piloto accesible antes de publicar o evaluarse como resultado de aprendizaje posterior. Si una regla probada admite publicar sin sus prerrequisitos declarados, incumple la protección de cero admisiones erróneas. Si toma exactamente las mismas decisiones que los indicadores existentes y añade demora y mantenimiento, también queda refutado su supuesto beneficio. El registro fijado no demuestra que esté desplegada ninguna regla de este tipo.

## Pruebas y límites

- El selector y la política fijados de Demerzel solo establecen comportamientos de modo y rol. La reproducción de NET-003 es un experimento en seco sobre el código fuente; no observa lanes activas.
- El registro de producción fijado de NET-003 establece los indicadores de fase del borrador en una revisión. Una modificación posterior puede cambiarlos, así que vuelve a leer la fuente exacta y los comprobantes de revisión antes de actuar.
- `semantic backpressure`, el grafo de dependencias, la notación y la comparación de rendimiento son conceptos propuestos. Necesitan una comparación real con una referencia, límites de autoridad explícitos, pruebas con estudiantes, traducción, vista previa en Learn y comprobación pública antes de cualquier aprobación operativa o educativa. En el ciclo anterior del original inglés, la traducción seguía pendiente; este borrador en español requiere aprobación de una persona que domine el español. Una revisión crítica independiente mediante IA identificó y motivó correcciones en los supuestos del grafo y del piloto; no sustituye una revisión humana de la materia.
