---
title: ¿Cuándo está justificada una decisión consultiva?
description: "Filosofía: pruebas y autoridad en las decisiones consultivas — Filosofía"
sidebar:
  label: PHI-002 · ¿Cuándo está justificada una decisión consultiva?
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/es/phi-002-when-is-an-advisory-decision-justified.es.md
---

:::note[Streeling University]
**PHI-002** · Filosofía: pruebas y autoridad en las decisiones consultivas · intermedio · 35 minutos

Generado por el departamento *Filosofía* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/es/phi-002-when-is-an-advisory-decision-justified.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHI-001](../../philosophy/phi-001-how-to-argue-well/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de traducciones todavía no redactadas, de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) documenta los borradores traducidos actuales, la importación y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Filosofía** | Nivel: intermedio | Etapa: Albedo | Duración: 35 minutos | Borrador en español pendiente de revisión del contenido, prueba con un estudiante y revisión lingüística humana

## Objetivos

Después de esta lección podrás distinguir la conformidad con un esquema de un consejo justificado, identificar divergencias de vocabulario del contrato, indicar quién conserva la autoridad de fusión y diseñar una comprobación de pruebas refutable.

## Pregunta del proyecto y alcance de las pruebas

**¿Cuándo puede Demerzel recomendar que una pull request de Guitar Alchemist (GA) está lista para que un humano la fusione?** El [documento de decisiones consultivas](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/docs/architecture/demerzel-advisory-decisions.md) de Demerzel indica que las recomendaciones deben citar identificadores concretos de eventos de Streeling o hechos de Seldon, exponer motivos y dejar acciones de alto riesgo como la fusión en manos humanas. Su [esquema `advisory-decision`](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/schemas/advisory-decision.schema.json) define un resultado de regla estructurado y de simulación. El [documento de paquetes de reglas AIW](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/docs/governance/aiw-rule-packs.md) describe expresamente el motor de evaluación como consultivo, no como un entorno de ejecución de producción ni un sustituto del juicio humano. Los tres enlaces fijan el commit de Demerzel `9ba9a29f6424ac8c1a6654c9b979b282a8cf216f`.

Es una pregunta filosófica con una respuesta operativa. Una decisión puede tener una *forma* válida mientras sus motivos carecen de pruebas pertinentes. Un consejo no concede autoridad para actuar. [PHI-001](../../philosophy/phi-001-how-to-argue-well/) introdujo premisas, conclusiones y solidez; aquí examinamos los pasos entre una declaración serializada, las pruebas que la respaldan y una persona autorizada para decidir. Probamos un ejemplo **sintético**, no un motor de políticas activo ni una PR de GA.

## 1. Un registro puede ser conforme sin respaldar su afirmación

El esquema exige un objeto `rule_result` de primer nivel. Dentro, son obligatorios `rule_id`, `subject`, `decision`, `reason_codes`, `evidence_refs`, `next_actions` y `confidence`. `subject` puede ser `pull_request` y `decision` puede ser `recommend`. Sin embargo, la propiedad `evidence_refs` es solo un array de cadenas: el esquema no exige un número mínimo de elementos, un identificador de Streeling o Seldon ni una regla que vincule una referencia con la PR indicada. Exigir un campo no exige que contenga pruebas útiles.

Considera esta **fixture didáctica sintética**. `PR-EXAMPLE` es un marcador, no una pull request observada; el identificador de regla y la acción se inventan únicamente para explorar el esquema.

```json
{
  "rule_result": {
    "rule_id": "SYNTHETIC-PR-READINESS",
    "subject": "pull_request",
    "decision": "recommend",
    "reason_codes": [],
    "evidence_refs": [],
    "next_actions": ["ask a human to inspect PR-EXAMPLE"],
    "confidence": "high"
  }
}
```

Este objeto supera el JSON Schema fijado: existen las claves obligatorias, cada valor tiene un tipo permitido y `recommend` y `high` pertenecen a sus respectivas enumeraciones. Es un resultado limitado y reproducible sobre la *estructura*. Ninguna fuente respalda que PR-EXAMPLE haya superado CI, revisión o controles de políticas. Una lista vacía no satisface el principio de pruebas declarado en el documento consultivo. El esquema tampoco valida que una cadena no vacía nombre un evento auténtico. Llamar «alta confianza» a la fixture añade una etiqueta, no una prueba.

### Ejercicio 1 — Separar las tres pruebas

¿La fixture sintética (a) cumple el esquema, (b) satisface el principio de pruebas específicas del documento consultivo y (c) autoriza una fusión GA? Cita los campos o frases que determinan cada respuesta.

> **Respuesta:** (a) Sí. Tiene todas las claves obligatorias de `rule_result` con valores permitidos `pull_request`, `recommend` y `high`; el esquema permite arrays vacíos. (b) No. `evidence_refs: []` no contiene ningún identificador concreto de evento Streeling o hecho Seldon. (c) No. El documento reserva la fusión a la aprobación humana y el documento de paquetes de reglas describe este motor como consultivo y de simulación. Un objeto válido no es una conclusión respaldada de preparación ni autoridad para fusionar.

## 2. Las pruebas necesitan identidad, pertinencia y fecha

Supón que un registro futuro incluye `"ci-run-123"` en `evidence_refs`. ¿Puede un revisor recuperar esa ejecución, vincularla a la revisión exacta de la PR y comprobar su resultado final? Una marca verde en un commit anterior puede ser auténtica y, aun así, irrelevante para el head actual.

Para recomendar una fusión, el documento consultivo exige haber superado todos los controles de gobernanza, incluidos CI, revisión y políticas. El esquema citado no contiene campos dedicados al número de PR, SHA de head, estado de CI, aprobación de revisión ni resultado de políticas. Un productor podría incluir cadenas explicativas en `reason_codes` o `evidence_refs`, pero esta estructura por sí sola no demuestra que se comprobaran los controles requeridos. Un humano necesitaría registros fechados y coincidentes con el destino y una correspondencia documentada entre cada control y sus pruebas. La decisión podría entonces estar bien respaldada; seguiría siendo una recomendación.

«Todas las comprobaciones pasaron» es una afirmación empírica sobre una revisión y un momento. «Lista para fusionar» también aplica una norma de política. «Fusiónala» pide actuar a alguien autorizado. Si falta una comprobación, registra una condición sin resolver o solicita revisión. El [catálogo de paquetes de reglas](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/docs/governance/aiw-rule-packs.md) nombra Merge Readiness, pero no muestra que se evaluara ninguna PR concreta.

### Ejercicio 2 — Auditar una cita propuesta

Un aviso **sintético** apunta a `ci-run-123` y dice «GA PR-EXAMPLE está lista». Enumera tres hechos que el revisor debe comprobar antes de tratar esa referencia como prueba de la parte CI de la afirmación. ¿Una ejecución CI superada demuestra por sí sola toda la afirmación de preparación?

> **Respuesta:** Recuperar `ci-run-123` y verificar que existe; confirmar que su repositorio, PR/SHA de head y fecha coinciden con la revisión juzgada; confirmar que terminó con las comprobaciones obligatorias superadas. CI superada por sí sola no demuestra los controles de revisión y políticas, que el documento consultivo también incluye en la preparación para fusionar. La fixture no proporciona ningún resultado CI real.

## 3. Un contrato documentado puede divergir entre artefactos

Los artefactos fijados usan vocabularios diferentes. El documento consultivo enumera `route`, `hold`, `request_review`, `escalate`, `recommend_merge` y `no_action` como tipos de decisión. La enumeración `decision` del esquema es `allow`, `block`, `warn`, `escalate` y `recommend`. Por tanto, el valor literal `recommend_merge` del documento falla la validación del esquema, mientras que `recommend`, válido según el esquema, no especifica por sí solo una recomendación de fusión. No trates silenciosamente ambos términos como idénticos.

El documento pide una puntuación numérica de confianza de 0 a 1 y habla de un campo `reasons`. En cambio, el esquema exige una cadena categórica `confidence` (`low`, `medium` o `high`) y `reason_codes`. Un valor numérico `0.9` o una clave `reasons` aislada no son el objeto descrito por el esquema. El ejemplo del documento de paquetes de reglas usa el vocabulario del esquema. Estas observaciones demuestran una *divergencia documentada del contrato en esta revisión*. No demuestran qué artefacto sigue un servicio activo, si existe una migración en otro lugar ni que alguna decisión de producción estuviera mal formada.

La regla en prosa, el esquema legible por máquina y la decisión particular son objetos distintos. Donde discrepen, conserva esa pregunta para los responsables del contrato; una traducción inventada impide una revisión reproducible.

### Ejercicio 3 — Identificar la divergencia exacta

¿Cuáles de estos campos o valores literales pertenecen al esquema fijado: `decision: "recommend_merge"`, `decision: "recommend"`, `confidence: 0.9`, `confidence: "high"`, `reasons` y `reason_codes`? ¿Qué conclusión puedes sacar de la discrepancia?

> **Respuesta:** El esquema acepta `decision: "recommend"`, `confidence: "high"` y el campo obligatorio `reason_codes`. Rechaza el valor literal de enumeración `recommend_merge` y la confianza numérica, y `reasons` por sí solo no puede sustituir al obligatorio `reason_codes`. Los documentos discrepan en vocabulario en la revisión fijada. Esto demuestra un problema de interpretación del contrato, no un comportamiento observado del motor activo ni permiso para equiparar sus términos.

## 4. El consejo y la autoridad son independientes

Usa un segundo **escenario sintético**: PR-EXAMPLE cambia un componente de GA; el revisor tiene una ejecución CI de un SHA de head anterior, no tiene aprobación de revisión para el head actual y no ha encontrado un resultado de políticas. No estaría justificado presentar esa PR como lista. El documento consultivo incluye expresamente la espera por fallos de CI o pruebas ausentes y una solicitud de revisión. El esquema puede representar una advertencia o escalado, mientras que `next_actions` puede describir los pasos humanos necesarios. Elegir el código exacto de regla dependería de un paquete de reglas definido que esta lección no ha ejecutado. Se trata de registrar la carencia en vez de deducir éxito del silencio.

La autoridad añade otra frontera. Las acciones no permitidas del MVP en el documento consultivo incluyen fusión automática, push directo de código, cambios de protección de ramas y concesión de permisos a workers. El documento de paquetes de reglas también dice que el motor de evaluación no modifica directamente el estado de GitHub ni elude los controles de revisión o fusión. La descripción del esquema llama a la decisión de simulación y consultiva. Por tanto, incluso una recomendación de preparación plenamente respaldada sería un motivo para que un humano autorizado inspeccione y decida, no una instrucción que conceda derechos de fusión al motor.

La revisión de pruebas aborda las afirmaciones erróneas de preparación; un responsable explícito de la decisión evita que un aviso se convierta en una fusión no autorizada. El texto del producto debería conservar esa distinción: «recomendado para revisión humana» no significa «aprobado para fusionar».

### Ejercicio 4 — Elegir un consejo defendible

Para el escenario sintético PR-EXAMPLE, escribe una frase consultiva defendible y nombra dos registros ausentes. ¿Puede un agente consultivo fusionar automáticamente cuando lleguen esos registros?

> **Respuesta:** «Retener la recomendación de preparación mientras se comprueban el resultado CI del head actual, la aprobación de revisión y el resultado de políticas». Dos registros ausentes son una ejecución CI obligatoria completada y vinculada al SHA de head actual y una aprobación de revisión para esa revisión; también debe establecerse el resultado de políticas. No. El documento consultivo prohíbe la fusión automática en el MVP y mantiene la decisión final de fusión en manos humanas.

## 5. Hacer refutable la afirmación

La afirmación limitada que se prueba aquí es: **en la revisión fijada, la validación del esquema por sí sola no impone el requisito de pruebas específicas del documento consultivo.** La fixture válida con pruebas vacías es un contraejemplo directo. La afirmación sería falsa si el esquema fijado rechazara esa fixture por exigir una referencia no vacía y específica de la fuente. No lo hace. Revisiones futuras podrían reforzar el esquema y un evaluador en ejecución podría imponer restricciones adicionales a la validación del esquema. Ninguna posibilidad cambia el resultado sobre este artefacto fijado.

Un estudio de campo podría probar la calidad *real* de las recomendaciones. Define un intervalo de fechas y enumera las decisiones de preparación de PR de GA. Conserva cada decisión, SHA de head de destino y hora de evaluación, identificadores citados y pruebas correspondientes de CI, revisión y políticas. Cuenta referencias sin resolver o que no coincidan con el destino; registra por separado la ambigüedad. Una recomendación sin respaldo refutaría la afirmación de que *todas* las recomendaciones de ese intervalo estaban respaldadas. Aquí no se analizaron decisiones operativas.

### Ejercicio 5 — Enunciar una prueba y sus límites

Escribe un criterio de refutación para la afirmación limitada de la lección sobre el esquema y una observación que refutaría la afirmación hipotética más fuerte «todas las recomendaciones de preparación para fusionar GA en un intervalo declarado tienen pruebas de apoyo coincidentes con su destino». ¿Esta lección demuestra esa afirmación más fuerte?

> **Respuesta:** La afirmación limitada sería falsa si el esquema fijado rechazara la fixture sintética completa únicamente porque `evidence_refs` estuviera vacío o careciera de un identificador de fuente concreto; en cambio, la valida. Una recomendación real en el intervalo declarado con una cita sin resolver o un resultado CI para otro SHA de head refutaría la afirmación universal más fuerte. Esta lección no tiene un corpus de decisiones operativas y no demuestra nada sobre la frecuencia de esos casos.

## Límites y base de investigación

Esta lección compara tres artefactos fijados de Demerzel y valida un objeto JSON sintético contra su esquema. No demuestra qué documento es la autoridad para una implementación, que se ejecutara el motor de políticas, que se evaluaran PR de GA ni que un humano aceptara una recomendación. El documento y el esquema pueden reflejar etapas de diseño diferentes; su discrepancia es visible, pero aquí no se establece su causa. Una futura revisión del curso debería comprobar el contrato vigente entonces, rastrear referencias reales de pruebas y preguntar a sus responsables cómo se corresponde el vocabulario antes de formular afirmaciones operativas. Siguen pendientes la revisión humana del contenido, pruebas con estudiantes, revisión lingüística humana de este borrador en español, sincronización Learn y lectura pública.
