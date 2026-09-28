---
title: Diario de actualizaciones
description: Publicaciones, pruebas de entrega y solicitudes pendientes.
---

## Regla de entrega

Solicitado, delegado, realizado localmente, fusionado, desplegado y verificado públicamente son estados distintos. Un agente activo o una PR abierta no constituye una entrega. Cada entrada verificada necesita una revisión, pruebas de validación y un destino público. Este diario es una instantánea fechada, no una conexión en directo a GitHub o wmux.

## Tablero de entregas — 2026-09-27

| Publicación verificada | Publicación o verificación pendiente | Solicitado, no entregado |
| --- | --- | --- |
| [Lección 9 de LadybugDB, laboratorio de grafos](../ladybugdb/09-graph-lab/): PR #25 fusionada como `438b320`, despliegue Pages correcto, lección y entrada del diario EN/FR/ES leídas de forma anónima | [Streeling MAT-003](../streeling/mathematics/): fuente fusionada en Demerzel (`89a1bdb`); PR #26 del generador fusionada como `67ffd4e` y PR #24 del laboratorio de Learn como `00ae641`; sincronización canónica pendiente de revisión | Módulos de matemáticas de Streeling más allá de MAT-001 y MAT-003: ninguno existe aún en la fuente canónica; MAT-002 y MAT-004 están en cola |

Este tablero añade lo resuelto o abierto el 2026-09-27; el del 2026-09-26, más abajo, no cambia.

## Tablero de entregas — 2026-09-26

| Publicación verificada | Publicación o verificación pendiente | Solicitado, no entregado |
| --- | --- | --- |
| Retest de SlashForge 4.5.0 y lección de contribución: PR #21, despliegue Pages correcto | Ocean está compartido públicamente; su entrada en el catálogo se añade con esta actualización | Imagen de portada ComfyUI |
| Laboratorio de calidad de pruebas y formato de observación agéntica: misma publicación | Narración de estudio: muestras locales, sin aprobación de escucha ni integración | Ilustración ComfyUI de Ix |
| | Receta de contenedor presente, ejecución sin probar | Diario de «prior art» TARS v1 → v2 |
| | | Nuevos cursos Streeling y enlaces a los cómics de Jean-Pierre Petit |
| | | Vista Gantt con estimaciones fundamentadas y dependencias |
| | | Propuesta de contratos de entrega Gaia; función no implementada |

Las columnas resumen solo estas solicitudes recientes. No son una auditoría completa de todos los repositorios ni de toda la conversación. Las fechas y los responsables no establecidos mediante pruebas quedan sin especificar.

## 2026-09-26 — Contribuciones SlashForge publicadas

La [PR Learn #21](https://github.com/spareilleux/learn/pull/21) se fusionó como `26a2f79f7901d8e4cd937ad291b0c4764f6d837e`. Su [compilación y despliegue Pages](https://github.com/spareilleux/learn/actions/runs/36265141942) finalizaron correctamente. La publicación incluye el [diario SlashForge](../slashforge/journal/), la [lección de contribución](../slashforge/07-contributing-back/), la ilustración de taller ComfyUI y la [lección de pruebas por mutación y propiedades](../repository-dogfooding-lab/06-mutation-property-testing/), en los tres idiomas.

El retest conserva las mediciones de 4.4.3 y separa los resultados Windows de 4.5.0. La CI SlashForge pasó en Linux, Windows y macOS; esto no convierte el retest live Windows en tres retests live. La narración sigue siendo una muestra local y la receta de contenedor no se ha ejecutado.

## 2026-09-26 — Artifact Ocean compartido comprobado

El [Artifact GA Ocean](https://claude.ai/artifact/P5JPUkCRR1cYc4herNiR9F) se abrió con un enlace de inicio de sesión opcional, sin exigir autenticación, y mostró los cuatro presets y la atribución de Saint-Malo. Ahora está referenciado en el [catálogo de Artifacts](../artifacts/). Esto confirma el acceso a la página compartida, no el rendimiento WebGPU en todos los dispositivos.

## 2026-09-27 — Lección 9 de LadybugDB y Streeling MAT-003 publicadas

La [PR de Learn #25](https://github.com/spareilleux/learn/pull/25) se fusionó como `438b320`, y su [despliegue Pages](https://github.com/spareilleux/learn/actions/runs/36341917142) fue correcto. La [lección 9 de LadybugDB](../ladybugdb/09-graph-lab/) y su [entrada del diario](../ladybugdb/journal/) se leyeron de forma anónima en los tres idiomas. Los dos scripts del laboratorio pasaron la CI del curso en Linux, Windows y macOS; las mediciones en sí se tomaron en Windows.

[Streeling MAT-003](../streeling/mathematics/mat-003-floating-point-conditioning/) llegó mediante tres fusiones:
- el laboratorio de Learn ([PR #24](https://github.com/spareilleux/learn/pull/24), `00ae641`);
- las etiquetas «en inglés» del generador ([PR #26](https://github.com/spareilleux/learn/pull/26), `67ffd4e`);
- la sincronización canónica en el commit de Demerzel `89a1bdb` ([PR #27](https://github.com/spareilleux/learn/pull/27), `ce6021f`), cuyo [despliegue Pages](https://github.com/spareilleux/learn/actions/runs/36343842316) fue correcto.

El módulo, el índice de matemáticas, la [entrada del diario de Streeling](../streeling/journal/) y el tablero del 2026-09-27 de arriba se leyeron de forma anónima en los tres idiomas. Ese tablero es una instantánea tomada antes de estas fusiones, y se deja tal como se escribió.

Estos dos elementos pasan así de pendientes a verificados. El catálogo de matemáticas sigue teniendo dos módulos, MAT-001 y MAT-003.

## 2026-09-27 — Ilustraciones de la portada y de IX publicadas

La [PR de Learn #23](https://github.com/spareilleux/learn/pull/23) se fusionó como `3c8c1de`, y su [despliegue Pages](https://github.com/spareilleux/learn/actions/runs/36299159809) fue correcto. La [portada](../) y la [introducción del curso IX](../machine-learning-ix/) muestran ahora las dos imágenes generadas localmente con ComfyUI y modelos en caché. En los tres idiomas, cada una se presenta como arte conceptual, no un diagrama. Las seis páginas respondieron 200 sin autenticación, y las dos imágenes eran idénticas, byte a byte, a una compilación local.

Son las dos imágenes ComfyUI que el tablero del 2026-09-26 incluye entre las solicitudes. Ese tablero se deja tal como se escribió.

## 2026-09-27 — Lección 16 de redes de Petri y curso AutoHarness publicados

La [PR de Learn #28](https://github.com/spareilleux/learn/pull/28) se fusionó como `e5a4ddd`, y la [PR #29](https://github.com/spareilleux/learn/pull/29) como `c406126`, cuyo [despliegue Pages](https://github.com/spareilleux/learn/actions/runs/36368118824) fue correcto. La [lección 16 de redes de Petri](../petri-nets/16-interoperability-lab/), su [diario](../petri-nets/journal/), el [curso AutoHarness](../autoharness/) y su [diario](../autoharness/journal/) se leyeron sin autenticación en los tres idiomas.

- **Las dos PR se repararon tras la revisión.** La revisión de Codex pedía cambios en cada una:
  - la comparación de ida y vuelta de la lección 16 y su guarda sobre el tipo de arco se corrigieron con pruebas que fallaban primero, y sus enlaces de QA apuntan ahora a un commit fijo;
  - las fixtures de AutoHarness se ejecutan ahora en CI en Linux, Windows y macOS.
- **Las cabezas reparadas se fusionaron a petición del usuario,** sin una segunda revisión independiente.
- **Lo que sigue sin medirse.** Los analizadores externos de la lección 16 (TINA, pm4py, Graphviz) son recetas que no se ejecutaron. AutoHarness se evaluó sin instalarlo, y su veredicto es «no adoptar» en `ca39a72`.

## 2026-09-27 — Streeling MAT-002 sincronizado, pendiente de verificación

La [PR de Demerzel #1136](https://github.com/GuitarAlchemist/Demerzel/pull/1136) se revisó de forma independiente en `5e6b733` y se fusionó como `a3a07df`. Esta actualización la sincroniza en Learn:
- el [módulo MAT-002](../streeling/mathematics/mat-002-counterexamples-and-exhaustive-checks/) en los tres idiomas;
- el índice de matemáticas;
- la [entrada del diario de Streeling](../streeling/journal/).

MAT-002 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación. MAT-004 se fusionó en Demerzel después de esta fijación (`d451c90`, [PR #1137](https://github.com/GuitarAlchemist/Demerzel/pull/1137)); no está sincronizado aquí.

## 2026-09-27 — Streeling MAT-004 sincronizado, pendiente de verificación

La [PR de Demerzel #1137](https://github.com/GuitarAlchemist/Demerzel/pull/1137) se fusionó como `d451c90`, después de la fijación de MAT-002. Esta actualización la sincroniza en Learn:
- el [módulo MAT-004](../streeling/mathematics/mat-004-vectors-matrices-norms/) en los tres idiomas;
- el índice de matemáticas;
- la [entrada del diario de Streeling](../streeling/journal/).

MAT-004 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## Por verificar

- Comprobar las URL públicas de esta actualización y el catálogo tras el despliegue; conservar su recibo en el registro de integración.
- Examinar el historial TARS en revisiones concretas antes de explicar la evolución de v1.
- Añadir un calendario solo después de establecer responsables, dependencias y estimaciones. Ninguna fecha de finalización ficticia.

## Preguntas abiertas

- ¿Pueden los recibos de candidatos y operaciones de Gaia imponer estas distinciones sin crear otra máquina de estados competidora?
- ¿Qué lagunas Streeling conviene cubrir en origen antes de la sincronización canónica de Learn?
