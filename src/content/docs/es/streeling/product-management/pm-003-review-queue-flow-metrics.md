---
title: Medir la cola de revisión de Streeling sin contar los borradores como flujo completado
description: Medir la cola de revisión de Streeling sin contar los borradores como flujo completado — Gestión de productos y proyectos
sidebar:
  label: PM-003 · Medir la cola de revisión de Streeling sin contar los borradores como flujo completado
  order: 3
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/es/pm-003-review-queue-flow-metrics.es.md
---

:::note[Streeling University]
**PM-003** · Medir la cola de revisión de Streeling sin contar los borradores como flujo completado · principiante · 30 minutos

Generado por el departamento *Gestión de productos y proyectos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/es/pm-003-review-queue-flow-metrics.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PM-002](../../product-management/pm-002-release-evidence-gate/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Ámbito de las fuentes actuales.** El inventario, la cola de revisión y los ejemplos de importación siguientes son observaciones históricas de las fuentes de Demerzel y su anterior vía de importación a Learn. La autoría actual EN/FR/ES corresponde a Learn `streeling/courses/`, cuyas páginas se generan mediante `npm run sync:streeling`. PT/IT/DE y los ciclos de investigación siguen en Demerzel. Los indicadores y recuentos históricos de producción no acreditan la revisión, el flujo ni la publicación de los blobs de Learn modificados.

> **Departamento de Gestión de Productos y Proyectos** | Nivel: principiante | Duración estimada: 30 minutos | Estado: borrador en español; condiciones de materia, estudiante, idioma y publicación abiertas

## Objetivos

Después de esta lección, podrás:

- Nombrar la unidad, el límite y la ventana temporal del trabajo de revisión en curso (WIP) y del flujo de revisiones completadas.
- Utilizar el inventario fuente de Streeling como una instantánea fechada sin llamar tasa de flujo a su recuento de borradores.
- Calcular el balance de una cola mediante un pequeño registro de eventos e identificar las mediciones que los artefactos actuales no permiten obtener.

## La pregunta del proyecto

El equipo quiere saber si la cola de revisión humana de Streeling crece más rápido de lo que los revisores pueden terminar los cursos. Un panel muestra **81 módulos fuente en inglés**. ¿Cuántas revisiones se completaron la semana pasada? Esa cifra **no permite saberlo**. Un recuento fuente es un stock de archivos en una revisión. El flujo de revisiones completadas cuenta los módulos que cruzaron un límite de finalización acordado durante un intervalo concreto. [PM-002](../../product-management/pm-002-release-evidence-gate/) explica las condiciones separadas de publicación; esta lección mide los movimientos entre ellas.

Utiliza el [script de progreso de Demerzel](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/scripts/streeling_course_progress.py) y el [inventario fechado del currículo](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/docs/specs/streeling-project-curriculum-2026-10-04.md) como caso del proyecto. En una instantánea limpia del árbol fuente del commit de Demerzel `0220ca84a25f59973bd6b9236cc00b7f68631a50` el 11 de octubre de 2026, `python scripts/streeling_course_progress.py` informó de **81** módulos EN redactados en **21** directorios de cursos, **16** módulos con todos los archivos de idiomas activos y **0** módulos con una revisión aprobada en el registro de producción. El script también encontró **23** registros de definición de departamentos. Estos recuentos corresponden a esa revisión y a ese alcance basado en directorios; ejecutarlo en una copia posterior puede cambiarlos.

El currículo registra **78** módulos fuente EN en 21 directorios en un estado anterior del piloto del 11 de octubre. La diferencia, `81 - 78 = 3`, es un **cambio neto del inventario fuente entre esas observaciones**. No son tres revisiones completadas. Incluso un denominador sin cambios no revelaría si entre las instantáneas se añadieron, eliminaron, renombraron o revisaron archivos.

### Ejercicio práctico 1: etiquetar las unidades

Una tarjeta de estado dice «78 → 81 módulos el 11 de octubre, por lo que el flujo completado fue de 3 cursos». Corrige la tarjeta con la unidad exacta y el límite que falta.

> **Respuesta:** «El inventario fuente en inglés aumentó en tres archivos de módulos netos entre las dos observaciones fechadas». No puede afirmar un flujo de revisiones completadas: ninguna cifra cuenta un evento de aprobación dentro de una ventana definida. El primer 78 es una observación fechada del currículo; 81 es la instantánea fijada del script en `0220ca8`.

## 1. Definir la cola antes de contarla

En este ejercicio, cuenta **una sola vez cada ID de módulo**, aunque su curso tenga seis traducciones o varias tareas de revisión. La entrada ocurre cuando un coordinador registra el módulo como listo para revisión y asigna su trabajo de revisión. La salida ocurre cuando se resuelven las observaciones requeridas de materia, idioma y estudiante y se registra una revisión de producción aprobada, o cuando el coordinador lo retira expresamente. Un borrador devuelto permanece en WIP hasta una de esas salidas; de lo contrario, un ciclo de correcciones podría hacer que la cola pareciese menor sin reducir el trabajo pendiente. Registra el ID del módulo, la hora de entrada, la hora de salida, el motivo de salida y la revisión de la fuente en un registro de eventos.

El [script de progreso actual](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/scripts/streeling_course_progress.py) examina archivos fuente y JSON de producción. Su recuento `authored_en` incluye módulos Markdown en inglés. Su señal `pipeline_review_approved` requiere `review.completed: true` **y** `verdict: approved` en un registro de producción correspondiente. No reconstruye cuándo una revisión entró o salió de una cola. En la instantánea fijada `0220ca8`, los 12 registros de producción contienen un estado `review_pending`, el de [DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/state/streeling/course-productions/cp-data-visualization-2026-10-04-001.json), y once estados `in_progress`. Ese único registro `review_pending` es un **indicador indirecto del estado**, no un censo medido de la cola: no existe un evento de entrada obligatorio, una marca temporal de asignación ni una garantía de que todos los borradores listos para revisión ya tengan registros.

El [dossier de revisión de DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/state/streeling/reviews/dv-001-review-brief.md) demuestra la distinción. Indica que las condiciones de revisión humana de la materia, lingüística y del estudiante siguen abiertas. Sus comprobaciones acotadas mediante IA y los seis borradores lingüísticos hacen visible el trabajo de revisión, pero no lo completan. Un módulo con trabajo abierto puede ser contenido fuente valioso y a la vez aportar cero revisiones aprobadas completadas.

### Ejercicio práctico 2: interpretar la instantánea con rigor

En `0220ca8`, el script informa de 81 módulos EN redactados, 16 completos en idiomas activos y 0 revisiones de producción aprobadas; la exploración de estados encuentra un módulo `review_pending`. ¿Cuál de estos valores es WIP verificado y cuál es flujo semanal completado?

> **Respuesta:** Ninguno es un censo verificado del WIP de la cola de revisión ni un flujo semanal completado. El módulo `review_pending` es un indicador indirecto del estado de un registro en una revisión. Los valores 81 y 16 cuentan estados de archivos fuente y 0 cuenta módulos aprobados en esa instantánea. Sin horas de eventos ni una regla coherente de entrada a la cola, no se deduce ninguna tasa semanal de llegadas o finalizaciones.

## 2. Contar el movimiento con una ventana explícita

El siguiente registro es un **conjunto de datos didáctico sintético**, no una historia observada de Streeling. Su ventana es `[2026-10-05 00:00 UTC, 2026-10-12 00:00 UTC)`: inicio incluido, final excluido, exactamente siete días. Al inicio, los módulos A y B están en WIP de revisión. Un módulo permanece en WIP durante las correcciones solicitadas. El registro utiliza cinco ID de módulos distintos; un módulo puede aparecer en más de un evento.

| Hora (UTC) | Módulo | Evento | Efecto en el WIP de revisión |
|---|---|---|---:|
| 6 oct., 09:00 | C | Listo para revisión; entra en la cola | +1 |
| 7 oct., 16:00 | A | Revisiones requeridas aprobadas; sale | -1 |
| 8 oct., 11:00 | D | Borrador inglés redactado; sin entrada en revisión | 0 |
| 9 oct., 14:00 | B | Devuelto para corregir; sigue asignado | 0 |
| 10 oct., 12:00 | E | Listo para revisión; entra en la cola | +1 |
| 11 oct., 18:00 | C | Retirado expresamente; sale | -1 |

El WIP inicial es 2. Dos entradas, una salida aprobada y una retirada dan un WIP final de `2 + 2 - 1 - 1 = 2`: B y E. **El flujo de revisiones completadas es de un módulo por ventana de siete días**, A. La retirada de C es una salida para el balance de la cola, pero no una revisión completada. El nuevo borrador de D es un evento de autoría, no una llegada a revisión. No mezcles los recuentos de este conjunto de datos con la instantánea real de 81 módulos.

### Ejercicio práctico 3: conciliar la cola

Utilizando solo el registro sintético, calcula el WIP final de revisión y enumera sus ID. ¿Mover B a «necesita cambios» fuera del tablero de revisión cambiaría el trabajo pendiente?

> **Respuesta:** El WIP final es `2 opening + 2 entries - 1 approval - 1 withdrawal = 2`, compuesto por B y E. Cambiar la etiqueta de B no lo terminaría. Según la regla de cola de esta lección, permanece en WIP mientras se solicitan correcciones; cualquier regla de tablero distinta debe declararse antes de comparar recuentos.

### Ejercicio práctico 4: calcular el flujo completado

Para la ventana de siete días del conjunto de datos, informa por separado de las revisiones aprobadas completadas, las retiradas y los borradores redactados. ¿Qué ocurre si un panel trata cada salida como una «revisión entregada»?

> **Respuesta:** Se registran una revisión aprobada completada (A), una retirada (C) y un borrador redactado sin entrada en revisión (D). Llamar a ambas salidas «revisiones entregadas» daría dos y exageraría en una unidad el flujo de revisiones aprobadas. El registro no recoge ninguna publicación pública en Learn.

## 3. Mostrar las horas ausentes y los cambios de alcance

El tiempo de entrega necesita las marcas temporales de entrada de un módulo en la cola y de salida aprobada. La entrada de A fue anterior a la ventana del conjunto de datos, pero no se especifica su hora exacta, por lo que no puede calcularse su tiempo de revisión. En el instante de cierre, E lleva **36 horas** en esta cola definida, del 10 de octubre a las 12:00 UTC al 12 de octubre a las 00:00 UTC. La antigüedad de B es desconocida porque no se proporciona su hora de entrada. No promedies una antigüedad conocida con una desconocida ni asignes silenciosamente a B el inicio de la ventana.

Para el trabajo real de Streeling, guarda un registro inmutable de eventos antes de graficar la tasa de llegadas, el flujo de revisiones completadas, la antigüedad o el tiempo de entrega. Fija una revisión de la fuente, usa la misma unidad de ID de módulo y regla de entrada/salida durante toda comparación e informa del intervalo UTC. Mantén separadas las etapas de materia, idioma, estudiante, compilación de Learn y comprobación pública si sus colas tienen responsables distintos. Un `timestamp` de un registro JSON de producción indica cuándo se escribió por última vez ese registro; por sí solo no identifica la hora de una transición. El [estado público de referencia fechado](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/state/streeling/reviews/public-baseline-2026-10-11.md) trata el acceso anónimo a Learn, no el flujo de revisión.

### Ejercicio práctico 5: escribir un pie de panel útil

Escribe dos frases con la instantánea fijada del proyecto `0220ca8` y el conjunto de datos sintético sin presentar este último como un resultado observado del equipo. Incluye una acción siguiente de medición.

> **Respuesta:** «En Demerzel `0220ca8`, la exploración de fuentes encontró 81 módulos en inglés y cero módulos con una revisión de producción aprobada; un registro tenía el estado `review_pending`, pero esto no es un censo temporal de la cola. En un registro sintético independiente de siete días, el WIP de revisión cierra en dos y el flujo de revisiones aprobadas es de uno; para medir el flujo real de Streeling, registra eventos de entrada a revisión, salida aprobada y retirada por módulo, con marcas temporales UTC y reglas estables».

## Ideas clave

- El inventario fuente y la cobertura de localización son stocks. Una tasa de revisiones completadas requiere eventos de transición fechados y una ventana declarada.
- El balance de la cola cuenta llegadas y todas las salidas; el flujo de revisiones completadas cuenta solo las salidas aprobadas según la regla de esta lección.
- Un campo de estado y la marca de última escritura son señales útiles para clasificar trabajo, pero no permiten reconstruir el WIP histórico, el tiempo de entrega ni el flujo completado.

## Pruebas del proyecto y límites

- Commit de Demerzel `0220ca84a25f59973bd6b9236cc00b7f68631a50`: [script de progreso](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/scripts/streeling_course_progress.py), [inventario fechado del currículo](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/docs/specs/streeling-project-curriculum-2026-10-04.md), [registro de producción de DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/state/streeling/course-productions/cp-data-visualization-2026-10-04-001.json) y [dossier de revisión abierto](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/state/streeling/reviews/dv-001-review-brief.md). La salida del script en el árbol limpio y la exploración de registros de producción descritas se observaron para ese commit; un árbol de trabajo posterior puede diferir.
- El registro A–E de seis eventos es inventado para practicar aritmética. No aporta pruebas sobre los revisores reales de Streeling, su tiempo de ciclo ni la publicación.
- PM-003 es aquí un borrador en español. En el ciclo anterior del original inglés, no se habían completado una revisión humana de la materia, un intento de un estudiante, revisiones lingüísticas por personas que dominen los idiomas, sync/build de Learn ni comprobación pública anónima. Este borrador sigue pendiente de aprobación por una persona que domine el español; traducirlo no acredita ninguno de esos resultados.
