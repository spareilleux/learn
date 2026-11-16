---
title: Componer veredictos de revisión vinculados al código fuente exacto
description: Componer veredictos de revisión vinculados al código fuente exacto — Ciencias de la computación
sidebar:
  label: CS-008 · Componer veredictos de revisión vinculados al código fuente exacto
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-008-compose-exact-source-review-verdicts.es.md
---

:::note[Streeling University]
**CS-008** · Componer veredictos de revisión vinculados al código fuente exacto · intermedio · 45 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-008-compose-exact-source-review-verdicts.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-005](../../computer-science/cs-005-agent-handoff-evidence-contract/), [CS-007](../../computer-science/cs-007-typed-agent-evidence-and-backpressure/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Informática** | Nivel intermedio | 45 minutos | Borrador en español; pendientes la revisión del contenido, una prueba con un estudiante y la revisión por una persona que domine el español

## Objetivos y pregunta del proyecto

Aprenderás a deducir un estado de revisión a partir de una revisión de las fuentes y un veredicto humano de alcance limitado, a identificar qué cambios invalidan qué veredictos y a distinguir una insignia generada de una autorización para publicar. **Pregunta del proyecto:** ¿cómo puede Streeling mostrar pruebas de revisión útiles para cientos de cursos sin que un veredicto obsoleto o automatizado se haga pasar por una aprobación humana? El ejercicio utiliza un borrador real de contrato y un generador real de Learn probado localmente. En las revisiones citadas, ambos eran experimentos en borrador; ninguno demuestra una revisión humana finalizada ni un despliegue público.

La necesidad es concreta. El [encargo de revisión de AUD-001](https://github.com/GuitarAlchemist/Demerzel/blob/2e1766e524e4e7900b380823006a8192cf6aa493/state/streeling/reviews/aud-001-review-brief.md) fija un curso de audio en inglés y cinco blobs Git traducidos. Pide a un especialista que compruebe las afirmaciones de DSP y las respuestas, a lectores que dominen cada idioma que comprueben las traducciones y a un estudiante que intente una tarea sin respuestas proporcionadas. Una comprobación estática previa es útil, pero no realiza ninguno de esos trabajos humanos. El usuario ha indicado que designará un revisor; esta lección no tiene ningún resultado de revisión que comunicar.

**Alcance de la implementación histórica.** El helper de Learn en `02fc08c` es un experimento en borrador archivado y no existe en el árbol actual de fuentes de Learn. Las PR citadas de Demerzel #1211/#1207 y Learn #170 se cerraron sin fusionar el 2026-10-21; su código y sus pruebas inmutables siguen siendo pruebas para este caso de estudio, no capacidades actuales del generador ni aprobaciones humanas. La autoría actual EN/FR/ES reside en Learn `streeling/courses/`; las páginas se generan a partir de esas fuentes. Usa `git rev-parse <learn-commit>:streeling/courses/<department>/<locale>/<filename>` para obtener un blob actual de Learn. Los comandos históricos de Demerzel que aparecen abajo conservan sus rutas originales `state/streeling`. Harían falta un validador de recibos mantenido y sus propias pruebas de aceptación antes de adoptar el helper histórico en esta arquitectura.

## 1. Dar a cada afirmación sus propias pruebas

El [esquema de recibo propuesto de Demerzel en `5d7c1d1`](https://github.com/GuitarAlchemist/Demerzel/blob/5d7c1d1bd9972fe9d6d2e7a90ab3cdddabb8ed44/schemas/streeling-review-receipt.schema.json) registra un `module_id`, `locale`, `kind`, `source_blob`, `reviewed_commit`, `reviewer`, `reviewed_at`, `verdict` y `evidence`. Los tipos permitidos son `subject`, `language` y `learner`; los veredictos permitidos son `approved`, `changes_requested` y `not_assessed`. Un recibo de contenido vincula el archivo inglés. Un recibo lingüístico vincula tanto su archivo traducido como `source_english_blob`, el texto inglés frente al que se comprobó la traducción. Un recibo es una afirmación de alcance limitado, no un certificado para todo el curso. La [guía de recibos](https://github.com/GuitarAlchemist/Demerzel/blob/5d7c1d1bd9972fe9d6d2e7a90ab3cdddabb8ed44/state/streeling/review-receipts/README.md) dice expresamente que el directorio todavía no contiene ningún recibo de aprobación.

Git identifica el *contenido* de un archivo mediante el hash de su blob. Para un commit fijado `C`, `git rev-parse C:state/streeling/courses/audio-engineering/en/aud-001-eq-compression-order.md` obtiene el blob inglés en ese commit. `reviewed_commit` es un puntero de auditoría; `source_blob` indica qué bytes juzgó el revisor. La coincidencia de un hash no autentica al revisor, no demuestra que se inspeccionara el enlace de prueba ni convierte una comprobación previa de IA en una revisión humana. Esas son comprobaciones de gobernanza independientes.

Considera la siguiente tabla **sintética**; `E1`, `E2`, `F1` y `F2` representan hashes distintos de blobs Git de 40 caracteres, no valores reales de AUD-001.

| Artefacto | Blob inglés | Blob francés | Recibo |
|---|---|---|---|
| Revisión A de las fuentes | `E1` | `F1` | ninguno |
| Revisión del contenido inglés | `E1` | — | `approved` |
| Revisión lingüística francesa | `E1` | `F1` | `approved` |
| Tarea del estudiante en francés | — | `F1` | `not_assessed` |

La página francesa en la revisión A tiene un recibo de aprobación del contenido inglés coincidente y un recibo de aprobación lingüística francesa coincidente. Su resultado del estudiante está **sin evaluar**. Sigue siendo una fixture didáctica: el esquema real exige valores hexadecimales SHA-1 reales y metadatos de revisión. Una estructura JSON válida por sí sola no demostraría que una persona real aprobó esas afirmaciones.

### Ejercicio práctico 1

¿Se pueden reducir los dos registros `approved` de la tabla a un único indicador `course_approved: true`? Indica un fallo concreto que ocultaría ese indicador.

> **Respuesta:** No. El registro de contenido cubre el contenido inglés; el registro lingüístico cubre la versión francesa frente a ese contenido inglés. Un único indicador ocultaría que la tarea del estudiante sigue `not_assessed` y podría seguir siendo verdadero después de cambiar solo el texto francés. Tampoco puede autenticar a un revisor. Mantén las afirmaciones separadas y vincula cada una a los bytes de sus fuentes.

## 2. Componer predicados y conservar el veredicto

El [helper de revisión de Learn en `02fc08c`](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/streeling-review-status.mjs) lee los identificadores de blob de los cursos mediante `git ls-tree` en el commit de las fuentes importadas. Su coincidencia central es sencilla: el `source_blob` del recibo debe ser igual al blob del archivo correspondiente y, en un recibo lingüístico, `source_english_blob` también debe ser igual al blob inglés actual. Para un recibo coincidente, comprueba además que `reviewed_commit` contiene los blobs declarados en sus rutas indicadas. Devuelve el *recibo coincidente*, no un booleano. Por tanto, un recibo `changes_requested` puede mostrarse sin contar como aprobación. Un recibo antiguo que ya no coincide produce una indicación de pendiente para esa afirmación. Las [pruebas de sincronización de Learn en el mismo commit](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/tests/sync-streeling.test.mjs) cubren la ausencia de recibo, la coincidencia exacta, el inglés obsoleto, la traducción obsoleta, la locale incorrecta, los cambios solicitados, el recibo mal formado y el commit contradictorio.

Para el debate, escribe la composición como predicados. Esta notación describe el helper en borrador; no es sintaxis IXQL:

```text
match_subject  = receipt.kind == subject
                 && receipt.locale == en
                 && receipt.source_blob == current_english_blob
match_language = receipt.kind == language
                 && receipt.locale == page_locale
                 && receipt.source_blob == current_translation_blob
                 && receipt.source_english_blob == current_english_blob
approved_claim = matching_receipt != null
                 && matching_receipt.verdict == approved
```

Esto hace visibles las dependencias. Un veredicto lingüístico depende de dos fuentes, mientras que un veredicto de contenido inglés depende de una. El helper también valida la estructura de los campos, el nombre del archivo, la marca temporal UTC, los valores permitidos y los blobs pertinentes del commit revisado antes de generar las páginas. Un recibo coincidente mal formado o contradictorio hace fallar la importación en lugar de ignorarse en silencio. Esta comprobación del commit surgió al utilizar esta misma lección para evaluar el proceso: el primer borrador solo comprobaba la sintaxis del commit, lo que permitía que su puntero de auditoría contradijera el blob declarado. La validación sigue sin poder autenticar a una persona; un revisor del repositorio debe examinar la identidad declarada y las pruebas. El borrador del contrato de recibos está sujeto a un control de revisión humana independiente porque afecta a `schemas/`.

### Ejercicio práctico 2

En la revisión A, ¿cuáles de las tres afirmaciones de la tabla cuentan como aprobadas? Si el recibo del estudiante francés cambia de `not_assessed` a `changes_requested` sin una nueva prueba del estudiante, ¿aumenta el número de aprobaciones?

> **Respuesta:** Las afirmaciones de contenido inglés y lengua francesa coinciden con sus blobs y tienen `approved`; la del estudiante coincide, pero es `not_assessed`. Cambiar su veredicto a `changes_requested` no aumenta el número de aprobaciones. Informaría de un hallazgo pendiente del estudiante, no de una tarea superada. En una revisión real, cambiar el registro también requiere una decisión auténtica del revisor y pruebas.

## 3. Las revisiones invalidan solo las afirmaciones que afectan

Supón que la revisión B cambia el curso inglés a `E2` y deja el archivo francés en `F1`. El antiguo recibo de contenido nombra `E1`, por lo que ya no coincide. El recibo lingüístico francés sigue nombrando `F1`, pero su `source_english_blob` es `E1`, así que tampoco coincide. El recibo del estudiante, que se refiere a la página francesa sin cambios `F1`, sigue coincidiendo y sigue indicando `not_assessed`. Si solo el francés cambia a `F2` y el inglés sigue en `E1`, el recibo de contenido inglés sigue siendo aplicable; los recibos franceses de lengua y estudiante vinculados a `F1` dejan de coincidir. Es un cálculo de dependencias, no una decisión de que el texto nuevo sea malo. Un revisor puede inspeccionar el nuevo diff y emitir un nuevo veredicto.

Ejecuta el cálculo con bytes reales al revisar un curso:

```text
git rev-parse <source-commit>:state/streeling/courses/<department>/en/<module-id>.md
git rev-parse <source-commit>:state/streeling/courses/<department>/fr/<module-id>.fr.md
```

Usa un *SHA de commit* y la ruta real del curso, y compara las salidas con el recibo. El encargo fijado de AUD-001 proporciona rutas e identificadores de blobs reales para un piloto de alcance limitado. No uses las cadenas `E1` y `F1` como argumentos de comando; son marcadores ficticios. Una edición de las fuentes posterior a una revisión puede conservar el significado, pero un agente no puede trasladar silenciosamente la aprobación al blob nuevo. El revisor humano decide si el diff justifica una nueva revisión completa o una extensión más limitada.

### Ejercicio práctico 3

Desde la revisión A, calcula los tres estados mostrados después de (a) cambiar solo el inglés a `E2` y (b) cambiar solo el francés a `F2`. Explica por qué `reviewed_commit` por sí solo no basta para ninguno de los cálculos.

> **Respuesta:** (a) Contenido pendiente, lengua francesa pendiente, estudiante francés `not_assessed`; el recibo del estudiante del `F1` sin cambios sigue coincidiendo. (b) Contenido inglés aprobado, lengua francesa pendiente, estudiante francés pendiente. Un commit identifica un árbol, no los bytes de archivo que cubría un veredicto concreto. Los identificadores de blob pertinentes y, para una traducción, la dependencia del inglés determinan la aplicabilidad. El helper de Learn compara esos blobs; no trata cualquier commit más reciente como automáticamente aprobado.

## 4. Mantener la publicación como efecto independiente

El [borrador de implementación de sincronización de Learn](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/sync-streeling.mjs) muestra estados separados de contenido, lengua y estudiante en las páginas generadas y solo cuenta recibos `approved` coincidentes en los resúmenes. Una compilación local del commit anterior generó 1,603 páginas y mostró revisión pendiente para AUD-001 en inglés, francés y español; las pruebas específicas de sincronización del commit posterior pasaron tras añadir la protección del commit revisado. Estas comprobaciones no demuestran que un humano revisara AUD-001, que se comprobara cada curso traducido ni que el sitio público sirva esa compilación.

Trata la publicación como una transición independiente con sus propias comprobaciones: pruebas humanas aprobadas para las afirmaciones previstas, fuentes revisadas y fusionadas, un sitio generado a partir del commit de fuentes elegido, despliegue y, después, lectura anónima de la página prevista y de la revisión de fuentes. Si falta una de esas comprobaciones, mantén falso el indicador `review.completed` o `publish.completed` del curso, según corresponda. Una insignia derivada de un recibo es una vista de las pruebas, no autoridad para fusionar ni desplegar. Esta separación es útil para un flujo de trabajo agéntico porque asigna a cada agente una función pequeña y auditable: examinar una fuente, registrar un veredicto, calcular su aplicabilidad, mostrar un estado y verificar la salida pública. También ofrece un motivo para retener una etapa posterior de publicación cuando una afirmación previa siga sin resolver. Esa última política es una propuesta de diseño hasta que la imponga un pipeline probado.

### Ejercicio práctico 4

Una página francesa generada indica «traducción aprobada» a partir de un recibo coincidente, pero la revisión del contenido inglés está pendiente. ¿Puede un agente marcar todo el curso como revisado y publicado? ¿Qué pruebas faltan?

> **Respuesta:** No. El recibo lingüístico solo cubre la versión francesa frente a su fuente inglesa; no aprueba el contenido inglés de audio o informática. Falta el veredicto de contenido coincidente. La publicación también necesita una integración revisada de las fuentes, un despliegue y una lectura anónima de la revisión elegida. El estado de traducción mostrado es correcto para su afirmación limitada, pero no puede autorizar la transición más amplia.

### Ejercicio práctico 5

Un archivo llamado `aud-001.en.subject.json` tiene un `source_blob` actual y `verdict: "approved"`, pero un campo adicional desconocido lo hace inválido según el borrador de esquema. Un compañero propone ignorar ese archivo y mostrar todas las insignias existentes. ¿Qué debería hacer la sincronización en borrador y qué prueba detectaría una salida parcial accidental?

> **Respuesta:** Rechazar la importación antes de escribir las páginas generadas. El helper de Learn rechaza campos desconocidos y su prueba de sincronización coloca un recibo inválido en una fixture, espera un error y comprueba que el archivo de bloqueo anterior no ha cambiado. Ignorar pruebas mal formadas podría hacer que una salida obsoleta pareciera actual; generar algunas páginas antes del fallo podría dejar una mezcla de revisiones. Una prueba superada demuestra este comportamiento solo para la implementación en borrador probada, no para un sitio público desplegado.

## Fuentes, límites y próxima comprobación

Las fuentes del proyecto son el [encargo de revisión acotado de AUD-001](https://github.com/GuitarAlchemist/Demerzel/blob/2e1766e524e4e7900b380823006a8192cf6aa493/state/streeling/reviews/aud-001-review-brief.md), el [borrador de esquema de Demerzel](https://github.com/GuitarAlchemist/Demerzel/blob/5d7c1d1bd9972fe9d6d2e7a90ab3cdddabb8ed44/schemas/streeling-review-receipt.schema.json), el [borrador del helper de Learn](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/streeling-review-status.mjs) y la [prueba de fixture de Learn](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/tests/sync-streeling.test.mjs). La instantánea cita las PR Demerzel #1211, Learn #170 y Demerzel #1207 como trabajo histórico en borrador; las tres se cerraron después sin fusionar. Estas referencias identifican la procedencia, no una implementación ni una aprobación actuales. La estructura del esquema de revisión no puede autenticar a un humano; las pruebas locales no pueden demostrar el despliegue del sitio. En el ciclo inglés original no se registró ningún veredicto humano, intento de estudiante, traducción de este curso ni lectura pública. Este borrador en español está pendiente de revisión por una persona que domine el español; no añade ningún veredicto humano, resultado de estudiante ni comprobación de despliegue. La siguiente comprobación útil consiste en que el especialista designado para AUD-001 complete un veredicto sobre las fuentes exactas con hallazgos citados, seguido de un intento de estudiante y una lectura anónima de la página tras una publicación autorizada.
