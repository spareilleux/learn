---
module_id: cs-005-agent-handoff-evidence-contract
department: computer-science
course: Transferir el trabajo de un agente mediante un contrato de pruebas
level: intermediate
prerequisites: ["cs-002-governing-agentic-loops"]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: computer-science-2026-10-11-005
version: "0.1.0"
---

# Transferir el trabajo de un agente mediante un contrato de pruebas

> **Alcance del borrador y las traducciones.** El texto técnico siguiente es un borrador fechado. Las menciones históricas de traducciones, integración en Learn o comprobaciones de publicación pendientes corresponden a aquella etapa; este [registro de traducción](../../../../code/streeling/evidence/locale-completion-2026-10-22/README.md) documenta los borradores actuales y las comprobaciones realizadas. Los ensayos de ejecución no realizados siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Informática** | Nivel intermedio | 30 minutos | Borrador en español; pendientes la revisión del contenido, una prueba con un estudiante y la revisión lingüística humana

## Objetivos

Aprenderás a inspeccionar una nota de handoff de GA, identificar qué demuestra realmente, probar un escenario fijo para el agente receptor y escribir una siguiente acción comprobable de forma independiente. El problema del proyecto es concreto: un agente termina un cambio de GA y otro debe decidir si continuar, inspeccionar o detenerse sin heredar una afirmación de éxito sin respaldo.

## 1. Inspeccionar el puente antes de confiar en la nota

El [puente Antigravity de GA en el commit `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Scripts/antigravity-bridge.ps1) tiene un modo `-Handoff`. Escribe un archivo Markdown en `state/handoffs/` con `from`, `at`, `branch`, `head`, `working_tree_dirty_lines` y el mensaje de texto libre del llamante. El script pide a Git la rama actual, el último commit **abreviado** y su asunto, y el número de líneas del estado corto. No ejecuta pruebas ni comprueba que las afirmaciones del mensaje sean ciertas. No captura una revisión completa, la lista de archivos cambiados, un hash de artefacto ni los permisos del siguiente agente. Las [instrucciones del workspace de GA en el mismo commit](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/CLAUDE.md) piden actor, rama, objetivo, alcance de escritura, pruebas, evidencias y siguiente petición en un handoff. Son campos que deben verificar el productor y el receptor, no garantías que aporte el puente.

El archivo resulta útil porque sobrevive a un cambio de contexto. Es una **afirmación con referencias**, no una observación en directo. El receptor debe vincularla a un checkout y una revisión concretos y después seguir sus pruebas. Un `head` abreviado y un recuento de líneas modificadas son pistas; no identifican el contenido exacto sin confirmar. Una nota en un directorio de handoff ignorado por Git puede seguir existiendo después de que su rama original haya avanzado.

### Ejercicio práctico 1

A partir del código fuente fijado del puente, enumera tres campos generados desde Git y tres elementos que un receptor aún debe obtener de forma independiente antes de tratar «pruebas superadas» como resultado verificado.

> **Respuesta:** El script genera `branch`, `head` abreviado y `working_tree_dirty_lines`. El receptor aún necesita el SHA completo del commit y el checkout actual, el comando exacto de pruebas con un resultado vinculado a esa revisión y el diff o artefacto real con su ubicación e identidad. El mensaje libre puede nombrarlos, pero el script no los verifica.

## 2. Hacer el contrato lo bastante pequeño para comprobarlo

Un handoff útil identifica **actor**, **objetivo**, **rama y revisión completa**, **alcance de escritura**, **pruebas de test**, **artefacto de salida** y **siguiente acción**. El actor indica al receptor quién hizo la afirmación; no otorga autoridad. La revisión indica qué fuente confirmada describe la afirmación. Si hay cambios sin confirmar, registra también sus rutas y un diff o parche guardado. El alcance de escritura nombra los archivos que puede modificar el siguiente agente y cualquier límite de autor único. Una afirmación de pruebas identifica el comando, dónde se ejecutó, el resultado y la revisión o el estado del worktree probado. «No ejecutado» es un estado válido; «superado» sin un resultado inspeccionable no lo es.

El artefacto es lo que hay que inspeccionar: ruta, commit, PR, recibo o registro de pruebas, con una identidad como un hash cuando un archivo puede reemplazarse. La siguiente acción es una instrucción acotada como «inspeccionar el diff y volver a ejecutar esta prueba identificada, después solicitar revisión»; no debería autorizar silenciosamente fusión ni publicación. En un handoff entre repositorios vecinos, identifica el repositorio además de la ruta. `state/handoffs/` de GA es un espacio local de coordinación; un agente en Demerzel no puede deducir que tenga permiso para leer o escribir allí.

Utiliza esta **fixture didáctica fija**, no como una afirmación sobre una sesión actual de GA:

```text
H1: note in ga/state/handoffs/example.md
from: agent
branch: codex/example-voicing
head: a1b2c3d fix: adjust voicing selection
working_tree_dirty_lines: 2
body: "Done. Tests passed. Continue the PR."

H2: receiver's independent probe of the same checkout
branch: codex/example-voicing
full HEAD: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
git status --short: M Common/VoicingRule.cs; ?? state/results/voicing.json
test log: absent
claimed output receipt: absent
wrapper: running
```

El HEAD abreviado `a1b2c3d` de H1 no coincide con el prefijo del HEAD completo `bbbb...` de H2, por lo que son revisiones confirmadas distintas. La fixture no indica cuándo se escribió H1 respecto a H2 ni si alguna revisión es antecesora de la otra. No inventes ese historial. El handoff necesita una comprobación de revisión y artefacto antes de continuar el trabajo.

### Ejercicio práctico 2

¿Qué puede concluir el receptor del recuento de líneas modificadas `2` de H1 y del estado corto de H2? Compara los dos valores HEAD: ¿puede H1 describir la revisión confirmada actual de H2 y qué sigue siendo desconocido?

> **Respuesta:** La nota informó de dos líneas de estado cuando se creó, mientras que la comprobación muestra ahora una ruta modificada y otra sin seguimiento. Los recuentos y nombres de ruta por sí solos no muestran los bytes ni si sobrevivieron los mismos dos cambios. `a1b2c3d` de H1 no es el prefijo del HEAD `bbbb...` de H2, así que H1 y H2 identifican revisiones confirmadas diferentes. Su ascendencia y cronología siguen siendo desconocidas. Inspecciona el diff actual y el artefacto sin seguimiento antes de decidir qué cubren todavía las afirmaciones de H1.

### Ejercicio práctico 3

H1 dice «pruebas superadas». El receptor no encuentra ningún registro de pruebas. Escribe el estado veraz más firme y las pruebas mínimas necesarias para reforzarlo.

> **Respuesta:** Estado: **se afirma que las pruebas pasaron, sin verificar**. Pide el comando exacto, el resultado de ejecución y el checkout o revisión junto con la identidad del estado modificado utilizado, o vuelve a ejecutar la prueba en el checkout inspeccionado y guarda la salida. Una nueva ejecución superada en H2 verificaría H2, no demostraría retroactivamente la afirmación anterior de H1.

## 3. Separar presencia, progreso y finalización

La [observación wmux de CS-004](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/computer-science/cs-004/wmux-dogfood-observation.md) es un ejemplo real acotado. Un proveedor se ejecutó y terminó con código 0, pero se denegaron las lecturas del repositorio vecino y la escritura del recibo. El wrapper que comprueba el marcador no encontró ni el marcador requerido ni el artefacto. Por tanto, el coordinador registró que **no se había completado ninguna revisión**. Un wrapper `running` muestra el estado de un proceso en un instante. Un prompt entregado muestra el envío. Incluso el código de salida 0 solo indica que un proceso terminó satisfactoriamente según ese proceso. Nada de ello demuestra que exista el artefacto solicitado ni que satisfaga la tarea.

El [registro del reintento acotado](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/computer-science/cs-004/review-followup-20261004.md) describe una observación más sólida: las lecturas y escritura declaradas aparecieron en el panel, existía un archivo de recibo con el marcador exacto y el wrapper lo verificó. Eso respalda una revisión consultiva acotada en ese momento. Sigue sin convertir la revisión en un curso publicado ni demostrar que todas las futuras ejecuciones de agentes puedan leer repositorios vecinos.

### Ejercicio práctico 4

Para el primer intento de CS-004, clasifica «prompt entregado», «wrapper en ejecución», «salida del proveedor 0» y «revisión completada». ¿Qué hechos observados determinan la última afirmación?

> **Respuesta:** Los tres primeros son, respectivamente, envío, estado transitorio del proceso y terminación del proveedor. «Revisión completada» es falso en ese intento: se denegaron dos lecturas requeridas y la escritura del recibo, y el wrapper no encontró marcador de finalización ni artefacto. El receptor debería registrar el límite de capacidad fallido y una comprobación previa acotada de permisos como siguiente acción.

## 4. Escribir un handoff utilizable por el receptor

Supón que un agente GA ha editado una regla de voicing, pero no ha ejecutado pruebas. El receptor puede usar la siguiente estructura. Sustituye los marcadores solo por valores observados:

```text
actor: <agent identity and surface>
goal: <one user-visible behavior to verify>
repository / checkout: <repo and absolute worktree path>
branch / full HEAD: <branch and 40-character SHA>
uncommitted state: <status paths plus diff or patch identity>
write scope / owner: <exact paths the next actor may edit; current writer>
tests: NOT RUN; <specific command proposed for this checkout>
artifact: <diff, receipt, or output path and hash, or MISSING>
next action: <one bounded inspection or test, then report result>
```

Si una ruta de fuente es inaccesible, indica **sin evaluar**. Si falta un recibo, indica **ausente**. No reconstruyas pruebas ausentes a partir del historial del chat. El receptor debería confirmar el checkout, resolver el commit, inspeccionar el diff y el artefacto y ejecutar o examinar la prueba identificada antes de continuar. Es un contrato de pruebas porque cada campo tiene una comprobación o un estado desconocido explícito.

### Ejercicio práctico 5

Reescribe el cuerpo de H1 como un handoff que el receptor H2 pueda utilizar sin afirmar éxitos no observados. Incluye los siete elementos del contrato y una siguiente acción dentro del alcance de las pruebas de H2.

> **Respuesta:** «Actor: agente (interfaz desconocida). Objetivo: evaluar el cambio de selección de voicing. Repositorio/checkout: GA, ruta del checkout H2 por registrar. Rama/HEAD completo: `codex/example-voicing` en `bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb` según H2; H1 identifica otra revisión confirmada, con ascendencia y cronología desconocidas. Alcance de escritura/responsable: no especificado; retener las ediciones hasta confirmar el responsable y las rutas permitidas. Estado sin confirmar: `Common/VoicingRule.cs` modificado y `state/results/voicing.json` sin seguimiento; inspeccionar su contenido. Pruebas: H1 afirma que pasaron, pero no hay registro, por lo que no está verificado. Artefacto: falta el recibo declarado; el JSON actual sin seguimiento requiere inspección e identidad. Siguiente acción: resolver el commit de H1 respecto a H2, inspeccionar diff y JSON, obtener o volver a ejecutar la prueba exacta en H2 e informar de las pruebas antes de continuar la PR». La interfaz desconocida del actor, el alcance y el recibo ausente siguen siendo explícitos.

## Fuentes y límites

El puente y las instrucciones GA anteriores están fijados al commit GA `dc2e74cbd992a298f67efb928b5b3754615e1924`; las observaciones CS-004 están fijadas al [commit Demerzel `6bc584d`](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/fixtures/computer-science/cs-004/wmux-dogfood-observation.md). H1 y H2 son explícitamente sintéticos y no establecen ningún estado actual de proceso o repositorio. El recibo local completo del reintento CS-004 está fuera de este repositorio de cursos, así que esta lección se basa en su resumen comprobado, no en una nueva lectura independiente de ese recibo. No se afirma ninguna nueva ejecución de agente, revisión del contenido, prueba con estudiantes, revisión de localización ni publicación. [CS-002](cs-002-governing-agentic-loops.md) trata los límites de bucles; esta lección trata la transferencia de pruebas entre actores.
