---
title: Una condición de publicación basada en pruebas para los cursos de Streeling
description: Una condición de publicación basada en pruebas para los cursos de Streeling — Gestión de productos y proyectos
sidebar:
  label: PM-002 · Una condición de publicación basada en pruebas para los cursos de Streeling
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/es/pm-002-release-evidence-gate.es.md
---

:::note[Streeling University]
**PM-002** · Una condición de publicación basada en pruebas para los cursos de Streeling · principiante · 30 minutos

Generado por el departamento *Gestión de productos y proyectos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/es/pm-002-release-evidence-gate.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PM-001](../../product-management/pm-001-shipping-vs-talking/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Ámbito de las fuentes actuales.** El inventario, la cola de revisión y los ejemplos de importación siguientes son observaciones históricas de las fuentes de Demerzel y su anterior vía de importación a Learn. La autoría actual EN/FR/ES corresponde a Learn `streeling/courses/`, cuyas páginas se generan mediante `npm run sync:streeling`. PT/IT/DE y los ciclos de investigación siguen en Demerzel. Los indicadores y recuentos históricos de producción no acreditan la revisión, el flujo ni la publicación de los blobs de Learn modificados.

> **Departamento de Gestión de Productos y Proyectos** | Nivel: principiante | Duración estimada: 30 minutos | Estado: borrador fuente en español; revisión y publicación pendientes

## Objetivos

Después de esta lección, podrás:

- Clasificar un módulo de Streeling como redactado, registrado, revisado, compilado localmente o accesible públicamente mediante el artefacto que demuestra cada estado.
- Nombrar las pruebas que faltan antes de afirmar que se ha publicado.
- Redactar una nota de publicación que ofrezca al lector una ruta reproducible hasta la fuente y la página desplegada.

## La pregunta del proyecto

Un agente escribe una lección útil de Streeling en Demerzel. Otro crea un registro de producción JSON. Learn genera una página en una compilación local. ¿Puede el equipo anunciar el curso como revisado y publicado? **No.** Esas acciones responden a preguntas diferentes. Un archivo fuente demuestra que se redactó un texto; un registro válido según un esquema demuestra que los campos y tipos requeridos se ajustan al esquema; una página local demuestra que una ejecución del generador y la compilación produjo una salida. Ninguna registra un intento de un estudiante ni demuestra que un lector anónimo pueda obtener la lección desplegada.

Esta lección utiliza el **piloto DV-001** fechado como caso fijo. Los comprobantes están fijados al commit piloto de Demerzel `6bc584d7ca1cd9eb1b1481e1100eeeb74e983863`, salvo el generador de Learn, leído en el commit de Learn `fe8e38444d882c28691dce9f12c21ac2ad404ec0`. Describen trabajo observado el 11 de octubre de 2026, no el sitio público actual. [PM-001](../../product-management/pm-001-shipping-vs-talking/) pregunta si una afirmación de producto es concreta y refutable. Aquí, el elemento que la refuta es un comprobante de publicación ausente o fallido.

### Ejercicio práctico 1: clasificar la fuente

DV-001 tiene una lección Markdown en inglés y cinco ejercicios resueltos. El [registro de producción](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/course-productions/cp-data-visualization-2026-10-04-001.json) indica `review.completed: false` y `publish.completed: false`. ¿Qué puede afirmar con respaldo una nota de publicación?

> **Respuesta:** «Existe en Demerzel un borrador fuente de DV-001 en inglés con cinco ejercicios resueltos». No puede decir «revisado» ni «publicado». Examinar la fuente es necesario para juzgar su contenido; los dos indicadores de fase en falso excluyen expresamente esas afirmaciones posteriores.

## 1. Una afirmación, un responsable de la prueba

Utiliza una ficha de control con la **afirmación**, el **artefacto**, la **revisión o fecha**, el **resultado** y el **siguiente responsable**. Las cinco filas siguientes son decisiones distintas, no sinónimos de «terminado».

| Afirmación | Prueba mínima para este piloto | Lo que no acredita la prueba |
|---|---|---|
| Fuente redactada | Ruta de la lección en Demerzel, ID del módulo, revisión de la fuente, ejercicio resuelto | Exactitud o utilidad para el estudiante |
| Registro de producción conforme | Archivo JSON validado según el [esquema `course-production`](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/schemas/course-production.schema.json) de Demerzel, con ID de fuente/investigación e indicadores de fase veraces | Que ocurrieran los hechos descritos en el registro |
| Revisado | Dictamen humano registrado sobre la materia, dictámenes de personas que dominen los idiomas requeridos y un intento de un estudiante con las correcciones resueltas | Una página desplegada y accesible |
| Integración de Learn | Salida de sincronización vinculada a un commit de la fuente de Demerzel, `streeling.lock.json` y compilación satisfactoria del sitio con rutas generadas comprobadas | Despliegue o acceso anónimo |
| Comprobación pública | Tras el despliegue, GET anónimo a las rutas previstas de lecciones e índices EN/FR/ES, con contenido y procedencia correctos | Que el contenido haya sido aprobado si faltan comprobantes de revisión |

El [dossier de revisión de DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-review-brief.md) registra una comprobación independiente de la materia mediante IA y una comparación multilingüe mediante IA, pero deja abiertas la revisión humana de la materia, la lingüística y la del estudiante. El indicador `review.completed: false` del registro de producción respeta ese límite. Una comprobación mediante IA puede reducir la cola sin convertirse silenciosamente en un resultado de revisión humana. La [regla del currículo](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/docs/specs/streeling-project-curriculum-2026-10-04.md) también distingue los recuentos de módulos listos, revisados y publicados.

### Ejercicio práctico 2: leer un registro válido

Supón que un validador JSON acepta el registro de producción de DV-001. Un compañero dice: «El curso pasó producción, así que la revisión está completa». ¿Qué campos y qué comprobante ausente refutan esa conclusión?

> **Respuesta:** La aceptación del esquema cubre la estructura del registro. El registro indica `status: review_pending`, `review.completed: false` y `publish.completed: false`. El dossier de revisión no tiene ningún dictamen completado de revisión humana de la materia, lingüística ni de un estudiante. La validación no puede convertir esos valores falsos en trabajo terminado.

## 2. Hacer observable la revisión

Una revisión requiere una persona y un resultado, no un título de una lista de comprobación. Para la exactitud de la materia, pide a un revisor que reproduzca las afirmaciones fechadas y todas las respuestas de los ejercicios a partir de los archivos fuente indicados. Para la localización, pide a alguien que domine el idioma que compruebe el sentido técnico y la naturalidad del texto en cada lengua requerida. Para la condición del estudiante, entrégale una tarea sin respuestas, recoge su respuesta, evalúala después y registra las dudas y las modificaciones. El [dossier de revisión de DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-review-brief.md) describe estas pruebas; el dossier en sí no es una prueba completada. Su comprobante de revisión de la materia mediante IA solo aprueba la comprobación factual acotada en inglés.

### Ejercicio práctico 3: distinguir a los revisores

DV-001 tiene seis borradores lingüísticos y una comparación semántica mediante IA. Un compañero propone marcar la casilla «revisado». Indica los comprobantes mínimos que faltan.

> **Respuesta:** Registra una revisión humana de las afirmaciones y respuestas inglesas, una revisión y un dictamen por alguien que domine cada idioma requerido y un intento observado de un estudiante con la tarea sin respuestas y con sus correcciones resueltas. Los borradores y comprobaciones de IA existentes no proporcionan esos resultados; deja `review.completed` en falso hasta que existan.

## 3. La salida local de Learn es una comprobación previa

En el commit fijado de Learn `fe8e384`, [`scripts/sync-streeling.mjs`](https://github.com/spareilleux/learn/blob/fe8e38444d882c28691dce9f12c21ac2ad404ec0/scripts/sync-streeling.mjs) lee los archivos de cursos de Demerzel y escribe las páginas EN/FR/ES generadas y `streeling.lock.json`; conserva los diarios. El [comprobante de comprobación previa de DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-learn-preflight-2026-10-11.md) informa de una sincronización y compilación Astro satisfactorias en un worktree aislado de Learn, con HTML de DV-001 generado en los tres idiomas. También informa de entradas de diario ausentes y revisión pendiente. El archivo de bloqueo fija la entrada de Demerzel para esa ejecución, no un despliegue público. Una modificación posterior de la fuente necesita un nuevo comprobante de sincronización y compilación.

### Ejercicio práctico 4: evaluar la compilación

Un panel de publicación muestra: «Compilación Astro: superada; existen archivos DV-001 EN/FR/ES bajo `dist/`». ¿Está respaldado afirmar «DV-001 está en línea»? Nombra la siguiente comprobación verificable.

> **Respuesta:** No. Son salidas locales de comprobación previa. Tras sincronizar y desplegar la fuente aprobada, solicita sin credenciales cada URL prevista de lección e índice, comprueba el contenido recibido y la procedencia de la fuente y registra el resultado y la hora. Una compilación local satisfactoria no basta para demostrar accesibilidad pública.

## 4. Cerrar el circuito público sin exagerar la afirmación

El [estado público de referencia del 11 de octubre](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/public-baseline-2026-10-11.md) registró respuestas 404 para las rutas de lección DV-001 EN, FR y ES mientras la comprobación previa local producía sus archivos HTML. Las dos observaciones son compatibles: la comprobación previa examinaba la salida local; el estado de referencia examinaba el sitio entonces público. También informa de que el índice público advertía que el autor del sitio no había revisado ni probado sus módulos generados mediante IA. La presencia pública seguiría sin ser un dictamen de revisión.

Una condición práctica de publicación incluye una regla de parada: si falta cualquier comprobante requerido, escribe la afirmación más firme y acotada que permitan las pruebas y asigna la condición pendiente a un responsable. Tras el despliegue, repite la comprobación anónima contra el nuevo commit fuente público; un resultado del 11 de octubre no puede certificar un despliegue posterior. Conserva las fechas de revisión y comprobación pública junto al dictamen para que un futuro editor sepa qué versión se comprobó.

### Ejercicio práctico 5: redactar la nota de publicación

Escribe dos frases sobre el piloto DV-001 usando solo estos comprobantes: seis borradores lingüísticos fuente; comprobaciones acotadas mediante IA; ninguna revisión humana ni de estudiante completada; compilación local EN/FR/ES satisfactoria; rutas públicas EN/FR/ES con respuestas 404 el 11 de octubre.

> **Respuesta:** «DV-001 tiene seis borradores lingüísticos y comprobaciones acotadas mediante IA; una sincronización y compilación locales de Learn generaron sus páginas EN/FR/ES a partir de una fuente fijada de Demerzel. Las revisiones humana de la materia, lingüística y del estudiante siguen abiertas, y las solicitudes anónimas a esas tres rutas públicas devolvieron 404 el 11 de octubre de 2026, por lo que estos comprobantes no acreditan un curso revisado o publicado».

## Ideas clave

- Una afirmación de publicación necesita un comprobante para su límite concreto; conformidad JSON, revisión, compilación y acceso público son límites diferentes.
- Indica la revisión de la fuente y la fecha de observación. Una comprobación previa fechada no es una promesa sobre el sitio actual.
- Si falta una condición, comunica el estado veraz más acotado y la siguiente comprobación, sin declarar un dictamen completado.

## Pruebas del proyecto y límites

- Commit piloto de Demerzel `6bc584d7ca1cd9eb1b1481e1100eeeb74e983863`: [registro de producción de DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/course-productions/cp-data-visualization-2026-10-04-001.json), [dossier de revisión](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-review-brief.md), [comprobación de la materia](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-subject-review-2026-10-11.md), [comprobación previa local de Learn](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-learn-preflight-2026-10-11.md) y [estado público de referencia](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/public-baseline-2026-10-11.md). Son comprobantes fechados del piloto, no comprobantes de revisión de PM-002.
- Commit de Learn `fe8e38444d882c28691dce9f12c21ac2ad404ec0`: [script de sincronización](https://github.com/spareilleux/learn/blob/fe8e38444d882c28691dce9f12c21ac2ad404ec0/scripts/sync-streeling.mjs). La comprobación previa de DV-001 también utilizó una corrección local del generador; su compilación satisfactoria no certifica este borrador de PM-002.
- Las cinco respuestas de esta lección se basan en los comprobantes fijados. En el ciclo anterior del original inglés, no se había realizado ninguna revisión de la materia, lingüística ni de estudiante, sync/build de Learn, despliegue ni comprobación pública anónima para PM-002. Este borrador en español sigue pendiente de aprobación por una persona que domine el español; traducirlo no acredita ninguno de esos resultados.
