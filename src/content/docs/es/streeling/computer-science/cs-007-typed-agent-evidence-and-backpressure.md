---
title: Tipar las pruebas de los agentes antes de componer los veredictos
description: Tipar las pruebas de los agentes antes de componer los veredictos — Ciencias de la computación
sidebar:
  label: CS-007 · Tipar las pruebas de los agentes antes de componer los veredictos
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-007-typed-agent-evidence-and-backpressure.es.md
---

:::note[Streeling University]
**CS-007** · Tipar las pruebas de los agentes antes de componer los veredictos · intermedio · 40 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-007-typed-agent-evidence-and-backpressure.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-005](../../computer-science/cs-005-agent-handoff-evidence-contract/) *(en inglés)*, [CS-006](../../computer-science/cs-006-ixql-pipeline-composition/) *(en inglés)*
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Informática** | Nivel intermedio | 40 minutos | Borrador en español; pendientes la revisión del contenido, una prueba con un estudiante y la revisión por una persona que domine el español

## Objetivos y pregunta del proyecto

Aprenderás a distinguir un registro válido según un esquema de una prueba que respalda su conclusión, a transmitir un fallo entre agentes sin convertirlo en éxito y a evaluar una regla propuesta para retrasar el trabajo posterior cuando falten las pruebas necesarias. **Pregunta del proyecto:** antes de que un agente de QA de Demerzel redacte o transmita un veredicto, ¿qué deben entregar sus nodos anteriores para que el siguiente agente distinga una comprobación real de un elemento provisional? Esta lección utiliza un pipeline de Phase 0 fijado a una revisión concreta. Su envoltorio tipado y su regla de contrapresión semántica son *propuestas didácticas*, no funciones verificadas en el ejecutor IXQL.

## 1. Examinar la declaración y el contrato

En el [commit de Demerzel `c3bf622`](https://github.com/GuitarAlchemist/Demerzel/tree/c3bf6224386374fc0f74cfb36643e543b4bdcce2), [`pipelines/qa-architect-cycle.ixql`](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/pipelines/qa-architect-cycle.ixql#L1-L15) se describe como un **esqueleto de Phase 0**. Sus comentarios excluyen expresamente el analizador real del alcance del impacto, el tribunal de revisores, los comentarios de PR o las incidencias de seguimiento y la señal algedónica derivada. Lee una ruta de activación con un destino alternativo, proporciona un alcance del impacto vacío y utiliza una cadena de un solo revisor cuya nota aclara que no hay agregación de tribunal ([líneas 23–55](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/pipelines/qa-architect-cycle.ixql#L23-L55)). El veredicto ensamblado indica `risk_tier: "P3"`, `verdict: "informational"` y contiene `evidence: [{kind: "manual_note", name: "phase0.skeleton", outcome: "n/a", ...}]` ([líneas 66–90](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/pipelines/qa-architect-cycle.ixql#L66-L90)). Son declaraciones del código fuente. La lección no dispone de ningún recibo que demuestre que el pipeline se ejecutó o escribió un archivo.

El [JSON Schema del veredicto QA incluido en el repositorio](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json#L14-L30) exige `target`, `risk_tier`, `verdict`, `blast_radius`, `evidence`, `reviewer_chain` y otros campos. Su regla condicional exige `P3` para un veredicto `informational` ([líneas 147–162](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json#L147-L162)); `reviewer_chain` necesita al menos una entrada ([líneas 96–102](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json#L96-L102)). Un elemento de prueba puede ser una `manual_note` con resultado `n/a` ([líneas 260–297](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json#L260-L297)). Por tanto, el esquema permite la *estructura* del esqueleto; no afirma que la nota pruebe una comprobación real de regresión ni que la entrada única del revisor represente un tribunal finalizado. `schema_version: 1` es un solo campo, no el esquema completo.

### Ejercicio práctico 1

El código fuente declara `informational/P3`, un revisor de arquitectura con `score: null` y una `manual_note/n/a`. ¿Cuáles de estas afirmaciones puede respaldar una comprobación de esquema: (a) el veredicto tiene una combinación de categorías permitida, (b) una prueba de regresión pasó, (c) se ejecutó un tribunal con varios revisores? Explica tu respuesta.

> **Respuesta:** Solo (a) se desprende de la regla condicional citada, siempre que el objeto completo supere la validación. El esquema permite `manual_note/n/a` y una cadena de un solo revisor, por lo que la estructura no demuestra ni una prueba superada ni un tribunal. El pipeline identifica expresamente tanto el resultado del alcance del impacto como la cadena de revisores como elementos provisionales de Phase 0. Incluso (a) es una expectativa deducida del código fuente hasta que un validador compruebe un objeto realmente emitido.

## 2. Poner un tipo en cada frontera entre agentes

Para debatir el diseño, asigna a un nodo un tipo de resultado como `Result<Output, Error>` y haz que su salida incluya pruebas. La siguiente notación **propuesta** no es sintaxis IXQL ni una afirmación sobre su ejecución:

```text
TriggerRead = Ok { target, source_path, source_revision }
            | Err { code, source_path, observed_at }
BlastCheck  = Ok { target_revision, result, evidence_receipt }
            | Err { code, target_revision, attempted_check }
VerdictDraft = { target, category, evidence_items, reviewer_receipts, provenance }
```

El productor responde de lo que afirma haber intentado. El receptor comprueba que la revisión de destino del resultado coincide con la que pretende juzgar. Un recibo debería identificar la comprobación, la revisión de entrada, el resultado y la ubicación de un artefacto que se pueda inspeccionar. Un valor de esquema como `kind: "test_run"` es una etiqueta; el JSON Schema no autentica un registro de pruebas. Si un nodo no tiene resultado, utiliza `Err` o `Unknown` con un motivo en lugar de inventar `Ok {result: []}`. Un resultado vacío y satisfactorio significa «la comprobación se ejecutó y no encontró elementos»; una comprobación no disponible significa «no lo sabemos».

`VerdictDraft` es un tipo didáctico interno, no el formato de intercambio del veredicto QA. Omite campos obligatorios del esquema y utiliza nombres de campo diferentes. Un compositor propuesto debe convertirlo y completarlo en un `QaVerdict` con todos los campos de intercambio obligatorios antes de aplicar el JSON Schema fijado; copiar el borrador directamente en un validador fallaría.

El pipeline fijado contiene `trigger_context <- ix.io.read(...) → default({...})`. La gramática y este código fuente no especifican si `default` se aplica solo a un archivo ausente, a JSON mal formado o a cualquier fallo de lectura. Un **contrato propuesto** más seguro distinguiría `Missing` de `Malformed` y `PermissionDenied`: solo un barrido sintético autorizado expresamente podría convertir `Missing` en una alternativa documentada; los demás casos detendrían el proceso o solicitarían una reparación. Es una decisión de diseño que hay que probar, no una descripción del comportamiento observado de IXQL. La alternativa también necesita una marca de procedencia para que un nodo posterior nunca confunda su destino sintético con un activador real de PR.

### Ejercicio práctico 2

Un nodo de activación propuesto devuelve `Err {code: "PermissionDenied", source_path: "state/qa-architect/trigger.json"}`. Un compañero lo sustituye por el destino alternativo y lo etiqueta como «leído del archivo de activación». ¿Qué dos errores ha cometido y qué salida debería recibir el siguiente nodo según el contrato propuesto?

> **Respuesta:** Ha convertido un fallo de permisos en un éxito y ha atribuido un destino sintético a un archivo que no se leyó. Según el contrato propuesto, el siguiente nodo recibe `Err(PermissionDenied)` con la ruta intentada y sin un destino de activación fiable; el cálculo QA se detiene o solicita corregir los permisos. La línea IXQL del repositorio por sí sola no demuestra que su `default` real se comporte así.

## 3. Propagar el fallo antes de un efecto irreversible

El código fuente de Phase 0 declara `ix.io.write(verdict_path, verdict) → tars.validate(check: "verdict.schema_version == 1", ...)` ([líneas 93–102](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/pipelines/qa-architect-cycle.ixql#L93-L102)). En el orden escrito, la escritura precede a una comprobación de un solo campo. El mensaje de rechazo dice que se niega a persistir una incompatibilidad de esquema, pero la comprobación mostrada no puede demostrar la validez completa según el JSON Schema y el código fuente no aporta ningún recibo de reversión. No podemos deducir que se persistiera realmente un archivo inválido, porque esta lección no ejecutó el pipeline. Sí *podemos* afirmar que la declaración por sí sola no basta para demostrar un control anterior a la escritura.

Una composición propuesta convertiría primero `VerdictDraft` en un `QaVerdict` completo con la estructura del esquema, validaría ese objeto de intercambio contra el esquema fijado, verificaría el recibo de prueba requerido para la afirmación prevista, autorizaría la escritura y, por último, examinaría su resultado. Cada paso devuelve `Ok` o `Err`. La política de pruebas es independiente de la validación JSON Schema: un elemento informativo provisional de Phase 0 puede ser válido y útil, pero debe seguir identificado como tal. En este diseño propuesto, un fallo de conversión, validación o revisión de pruebas no permite ninguna escritura autorizada. Un fallo de escritura produce un recibo de error, no un veredicto aceptado. Hay que implementar y probar el diseño antes de afirmar que el pipeline lo impone.

### Ejercicio práctico 3

Toma un **veredicto sintético en formato de intercambio** idéntico al de Phase 0 excepto por `schema_version: 2`. Si el `tars.validate` del código fuente rechaza esa versión, ¿puede su rechazo demostrar que no hubo ninguna escritura? Indica el resultado esperado del diseño propuesto que valida antes de escribir.

> **Respuesta:** No. El código fuente sitúa `ix.io.write` antes de la comprobación de `schema_version` y no se ha observado ninguna reversión, por lo que un rechazo posterior no demuestra por sí solo la ausencia de escritura. En el diseño propuesto, tras la conversión al objeto de intercambio completo, la validación completa del esquema rechaza `schema_version: 2` porque el esquema exige la constante entera `1`; el resultado es `Err(SchemaMismatch)` y no se invoca la etapa de escritura. Una prueba necesitaría una traza de llamadas y una comprobación del estado de los archivos para verificar ese comportamiento en una implementación.

### Ejercicio práctico 4

Una llamada real a un revisor agota el tiempo de espera, pero un compositor inserta la entrada de Phase 0 de `reviewer_chain` y anuncia «tribunal finalizado». El JSON sigue teniendo un revisor, por lo que satisface `minItems: 1`. ¿Cuál debería ser el resultado tipado y qué comprobación distingue esto de un esqueleto informativo válido?

> **Respuesta:** La etapa de revisión debería devolver `Err(Timeout)` o un resultado explícitamente sin resolver con el rol intentado y la revisión de destino. El compositor no debe convertir el elemento provisional en un tribunal finalizado. Una comprobación de pruebas específica para esa afirmación exige recibos de los roles de revisión requeridos y sus resultados; el `minItems: 1` del esquema solo comprueba la estructura del array. Un esqueleto informativo de Phase 0 puede seguir claramente identificado como tal, mientras que afirmar que el tribunal ha finalizado requiere pruebas de ejecución independientes.

## 4. La contrapresión semántica es una hipótesis

La **contrapresión** suele ralentizar a un productor cuando un consumidor posterior carece de capacidad. Una versión *semántica* propuesta ralentizaría a un productor de veredictos cuando el consumidor no puede interpretar o verificar sus pruebas. La idea es refutable: exigir una identidad de fuente tipada, un recibo de comprobación finalizada y un recibo de revisor antes de colocar un elemento en una cola «listo para una decisión operativa». En caso contrario, mantenerlo en una cola sin resolver con un motivo. Esta regla de tres partes es una **política didáctica sintética**, no una regla de Demerzel ni una función IXQL. No sustituye ninguna política vigente de autoridad, revisión o fusión. La fixture siguiente trata decisiones vinculadas a un commit; un barrido programado con `sha: null` necesitaría otra identidad de destino estable, como una revisión de instantánea con nombre, en lugar de un SHA de commit inventado.

Considera una fixture fija con dos plazas disponibles en la etapa posterior y tres conjuntos candidatos. `A` tiene `sha: null`, `manual_note/n/a` y la entrada de arquitectura del esqueleto. `B` tiene un SHA de destino fijado, un recibo verificable de `test_run/pass` y un recibo de revisor para ese mismo SHA. `C` tiene un SHA fijado y un recibo de prueba, pero su llamada al revisor agotó el tiempo de espera. Según la regla propuesta de tres partes, solo `B` entra en la cola de elementos listos. `A` y `C` siguen sin resolver y queda una plaza libre. La plaza sin usar es deliberada: la capacidad por sí sola no constituye una prueba. `B` está listo únicamente para la *decisión operativa específica definida por la política*; la fixture no autoriza ninguna fusión ni afirma que haya pasado una prueba real de GA.

La hipótesis predice menos clasificaciones de «listo» sin respaldo y quizá más tiempo de espera. Pruébala con handoffs históricos etiquetados o en una simulación controlada: cuenta las decisiones falsamente listas, la antigüedad de los elementos sin resolver y las correcciones manuales con y sin la regla. Un buen resultado reduciría las decisiones falsamente listas sin un bloqueo indefinido inaceptable. Un criterio de refutación sería que la clasificación falsamente lista no cambiara o empeorara, o que el trabajo sin resolver nunca dispusiera de una vía de reparación. Esta lección no ha recogido esas mediciones.

### Ejercicio práctico 5

Aplica la regla propuesta a `A`, `B` y `C`. ¿Cuántas de las dos plazas se ocupan, cuántos conjuntos esperan y qué evento adicional podría hacer que `C` fuera admisible? ¿Demuestra el ejercicio que Demerzel aplica actualmente contrapresión semántica?

> **Respuesta:** `B` ocupa una plaza; dos conjuntos (`A` y `C`) esperan; queda una plaza sin usar. Un reintento satisfactorio del revisor con un recibo vinculado al SHA de destino fijado de `C` podría completar sus tres requisitos. La fixture solo comprueba la aritmética y la clasificación de la regla propuesta. No aporta pruebas de que Demerzel implemente actualmente contrapresión semántica o se beneficie de ella.

## Fuentes, límites y próxima comprobación

Las pruebas del proyecto son el [archivo IXQL de Phase 0 fijado](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/pipelines/qa-architect-cycle.ixql), el [esquema de veredicto incluido en el repositorio](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json) y el [validador estructural mínimo](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/scripts/ixql-validate.js#L1-L4). Los metadatos del esquema designan a GA como fuente canónica en un SHA diferente ([líneas 6–12](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json#L6-L12)). El comentario IXQL nombra `docs/contracts/qa-verdict.schema.json`, mientras que el archivo incluido en este checkout está en `schemas/contracts/qa-verdict.schema.json`; esa diferencia de rutas es un problema de documentación del código fuente, no una prueba de que una ejecución fallara. El validador estructural no es un analizador completo ni un ejecutor. Para esta lección no se ejecutó ninguna emisión de veredicto, comprobación de esquema sobre los bytes emitidos, traza de escritura, llamada a un revisor ni medición de contrapresión. La siguiente comprobación es una prueba de implementación aislada con un borrador inválido y una llamada de revisor denegada, registrando la traza de llamadas de escritura y el estado de los artefactos. En el ciclo inglés original seguían pendientes la revisión humana del contenido, la prueba con un estudiante, la traducción y la publicación. Este borrador en español sigue pendiente de revisión del contenido, prueba con un estudiante, revisión por una persona que domine el español y revisión previa a la publicación.
