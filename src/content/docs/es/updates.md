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

## 2026-09-27 — Streeling MAT-005 sincronizado, pendiente de verificación

La [PR de Demerzel #1138](https://github.com/GuitarAlchemist/Demerzel/pull/1138) se fusionó como `8bd026f`, después de la fijación de MAT-004. Esta actualización la sincroniza en Learn:
- el [módulo MAT-005](../streeling/mathematics/mat-005-symmetric-eigenproblems/) en los tres idiomas;
- el índice de matemáticas;
- la [entrada del diario de Streeling](../streeling/journal/).

MAT-005 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## 2026-09-27 — Streeling MAT-002, MAT-004 y MAT-005 publicados

Codex fusionó las tres sincronizaciones canónicas, y cada despliegue de Pages fue correcto:
- [MAT-002](../streeling/mathematics/mat-002-counterexamples-and-exhaustive-checks/), Demerzel `a3a07df`: [PR #35](https://github.com/spareilleux/learn/pull/35), fusionada como `1b4ec84`, [despliegue](https://github.com/spareilleux/learn/actions/runs/36371547922);
- [MAT-004](../streeling/mathematics/mat-004-vectors-matrices-norms/), Demerzel `d451c90`: [PR #36](https://github.com/spareilleux/learn/pull/36), fusionada como `b0f4380`, [despliegue](https://github.com/spareilleux/learn/actions/runs/36372857458);
- [MAT-005](../streeling/mathematics/mat-005-symmetric-eigenproblems/), Demerzel `8bd026f`: [PR #37](https://github.com/spareilleux/learn/pull/37), fusionada como `36d4d17`, [despliegue](https://github.com/spareilleux/learn/actions/runs/36373405733).

Los tres módulos, el índice de matemáticas, el [diario de Streeling](../streeling/journal/) y sus entradas en este diario se leyeron sin autenticación en los tres idiomas. En esa lectura, después de #37, las páginas servidas enlazaban su fuente en `8bd026f`; esta actualización las fija de nuevo en `0b13b9d`.

Estos tres módulos pasan así de pendientes de verificación a verificados; sus entradas de arriba quedan tal como se escribieron. En la misma lectura, el catálogo de matemáticas tenía cinco módulos, de MAT-001 a MAT-005; esta actualización añade MAT-006, el sexto. Publicado no es estudiado: ninguno se ha ejecutado ni estudiado aquí, y sus experimentos siguen propuestos.

## 2026-09-27 — Streeling MAT-006 sincronizado, pendiente de verificación

La [PR de Demerzel #1139](https://github.com/GuitarAlchemist/Demerzel/pull/1139) se fusionó como `0b13b9d`, después de la fijación de MAT-005. Esta actualización la sincroniza en Learn:
- el [módulo MAT-006](../streeling/mathematics/mat-006-svd-low-rank-approximation/) en los tres idiomas;
- el índice de matemáticas;
- la [entrada del diario de Streeling](../streeling/journal/).

MAT-006 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## 2026-09-27 — Streeling MAT-006 publicado

Codex fusionó la [PR de Learn #38](https://github.com/spareilleux/learn/pull/38) como `0853739`, tras dos correcciones de este diario pedidas en la revisión, y su [despliegue de Pages](https://github.com/spareilleux/learn/actions/runs/36375002691) fue correcto. El [módulo MAT-006](../streeling/mathematics/mat-006-svd-low-rank-approximation/), el índice de matemáticas, el [diario de Streeling](../streeling/journal/) y este diario se leyeron sin autenticación en los tres idiomas: 12 páginas, que respondieron todas 200 y mencionan MAT-006.

MAT-006 pasa así de pendiente de verificación a verificado; su entrada de arriba queda tal como se escribió. En esa lectura, las páginas de MAT-006 enlazaban su fuente en `0b13b9d`; esta actualización las fija de nuevo en `8c14336`. Como en los módulos anteriores, publicado no es estudiado: MAT-006 no se ha ejecutado ni estudiado aquí, y su experimento sigue propuesto.

## 2026-09-27 — Streeling MAT-007 sincronizado, pendiente de verificación

La [PR de Demerzel #1140](https://github.com/GuitarAlchemist/Demerzel/pull/1140) se fusionó como `8c14336`, después de la fijación de MAT-006. Esta actualización la sincroniza en Learn:
- el [módulo MAT-007](../streeling/mathematics/mat-007-least-squares-regularisation/) en los tres idiomas;
- el índice de matemáticas;
- la [entrada del diario de Streeling](../streeling/journal/).

MAT-007 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## 2026-10-02 — Streeling MAT-007 publicado

La [PR de Learn #39](https://github.com/spareilleux/learn/pull/39) se fusionó como `0436325`, y su [despliegue de Pages](https://github.com/spareilleux/learn/actions/runs/36377803965) fue correcto. El 2026-10-02, con `main` en `c547150` y su [despliegue](https://github.com/spareilleux/learn/actions/runs/37065792242) correcto, el [módulo MAT-007](../streeling/mathematics/mat-007-least-squares-regularisation/), el índice de matemáticas, el [diario de Streeling](../streeling/journal/) y este diario se leyeron sin autenticación en los tres idiomas: 12 páginas, que respondieron todas 200 y mencionan MAT-007.

MAT-007 pasa así de pendiente de verificación a verificado; su entrada de arriba queda tal como se escribió. En esa lectura, las páginas de MAT-007 enlazaban su fuente en `8c14336`; esta actualización las fija de nuevo en `e203e5a`. Como en los módulos anteriores, publicado no es estudiado: MAT-007 no se ha ejecutado ni estudiado aquí, y su experimento sigue propuesto.

## 2026-10-02 — Streeling MAT-008 a MAT-025 y cinco módulos de música sincronizados, pendientes de verificación

El `master` de Demerzel llegó a [`e203e5a`](https://github.com/GuitarAlchemist/Demerzel/commit/e203e5a25e10b85b8d22ece9a700e12447f4a236), después de la fijación de MAT-007. Esta actualización lo sincroniza en Learn:
- 23 módulos nuevos en los tres idiomas: [MAT-008 a MAT-025](../streeling/mathematics/) y, en [música](../streeling/music/), MUS-007, MUS-008, MUS-009, MUS-018 y MUS-020;
- páginas en francés y en español para quince módulos que aquí solo tenían inglés, y las correcciones y los acentos españoles restaurados fusionados en Demerzel desde `8c14336`;
- los índices de los departamentos;
- la [entrada del diario de Streeling](../streeling/journal/).

Estos módulos y traducciones siguen **pendientes de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## 2026-10-02 — Streeling MAT-008 a MAT-025, cinco módulos de música y quince traducciones publicados

La [PR de Learn #114](https://github.com/spareilleux/learn/pull/114) se fusionó como `48d4e74`, después de corregir dos formulaciones del diario pedidas en una revisión independiente, y su [despliegue de Pages](https://github.com/spareilleux/learn/actions/runs/37070579523) fue correcto. Después, las páginas se leyeron sin autenticación en los tres idiomas, 99 páginas de módulos en total, que respondieron todas 200, nombran su módulo y enlazan su fuente en `e203e5a`:
- los 23 módulos nuevos, [MAT-008 a MAT-025](../streeling/mathematics/) y, en [música](../streeling/music/), MUS-007, MUS-008, MUS-009, MUS-018 y MUS-020, en inglés, francés y español;
- las páginas en francés y en español de los quince módulos traducidos ahora.

Los índices de matemáticas y de música, el [diario de Streeling](../streeling/journal/) y este diario también respondieron 200. Estos módulos y traducciones pasan así de pendientes de verificación a verificados; su entrada de arriba queda tal como se escribió. Esta actualización fija de nuevo sus enlaces a la fuente en `d459d8e`. Publicado no es estudiado: ninguno se ha ejecutado ni estudiado aquí, y sus experimentos siguen propuestos.

## 2026-10-02 — Lecciones 9 a 14 de teoría musical publicadas

Cada lección se fusionó después de que su CI pasara y de que una revisión independiente de su último commit no dejara nada abierto:
- [Lección 9](../music-theory-ga/09-voice-leading-and-common-tones/): [PR #90](https://github.com/spareilleux/learn/pull/90), fusionada como `c547150`;
- [Lección 10](../music-theory-ga/10-substitutions-and-modal-mixture/): [PR #99](https://github.com/spareilleux/learn/pull/99), fusionada como `9722af8`;
- [Lección 11](../music-theory-ga/11-modes-in-depth/): [PR #100](https://github.com/spareilleux/learn/pull/100), fusionada como `c0abd0e`;
- [Lección 12](../music-theory-ga/12-symmetry-and-limited-transposition/): [PR #104](https://github.com/spareilleux/learn/pull/104), fusionada como `641df75`;
- [Lección 13](../music-theory-ga/13-extended-and-altered-chords/): [PR #108](https://github.com/spareilleux/learn/pull/108), fusionada como `e2ce788`;
- [Lección 14](../music-theory-ga/14-guitar-voicings/): [PR #111](https://github.com/spareilleux/learn/pull/111), fusionada como `1364ba4`.

El [despliegue de Pages](https://github.com/spareilleux/learn/actions/runs/37070289373) de `1364ba4` fue correcto, igual que el siguiente, el de #114. Las seis lecciones respondieron 200 sin autenticación en los tres idiomas, 18 páginas en total.

## 2026-10-02 — Corrección de Streeling PHY-001 sincronizada, pendiente de verificación

La [PR de Demerzel #1179](https://github.com/GuitarAlchemist/Demerzel/pull/1179) se fusionó como `d459d8e`, después de la fijación de `e203e5a`. Esta actualización la sincroniza en Learn:
- el ejercicio corregido del [módulo PHY-001](../streeling/physics/phy-001-science-of-guitar-sound/), en los tres idiomas: los 2/3 de una quinta justa se miden desde el traste 7 hasta la selleta, no desde la cejuela;
- la [entrada del diario de Streeling](../streeling/journal/).

La corrección de PHY-001 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## 2026-10-03 — Corrección de Streeling PHY-001 publicada

La [PR de Learn #117](https://github.com/spareilleux/learn/pull/117) se fusionó como `8183127`, y su [despliegue de Pages](https://github.com/spareilleux/learn/actions/runs/37072084405) fue correcto. Después, el [módulo PHY-001](../streeling/physics/phy-001-science-of-guitar-sound/) y el [diario de Streeling](../streeling/journal/) se leyeron sin autenticación en los tres idiomas: seis páginas, que respondieron todas 200. Las páginas del módulo nombran PHY-001 y enlazan su fuente en `d459d8e`; las del diario incluyen su entrada del 2026-10-02.

La corrección de PHY-001 pasa así de pendiente de verificación a verificada; su entrada de arriba queda tal como se escribió. Esta actualización fija de nuevo los enlaces a la fuente del módulo en `450fc67`. Publicado no es estudiado: PHY-001 no se ha ejecutado ni estudiado aquí.

## 2026-10-03 — Lección 15 de teoría musical publicada

La [lección 15](../music-theory-ga/15-the-fretboard/) se fusionó después de que su CI pasara: [PR #119](https://github.com/spareilleux/learn/pull/119), fusionada como `89dc3e6`. Su [despliegue de Pages](https://github.com/spareilleux/learn/actions/runs/37083729662) fue correcto. La lección y el [diario del curso](../music-theory-ga/journal/) respondieron 200 sin autenticación en los tres idiomas, seis páginas en total.

## 2026-10-03 — Streeling MUS-012 sincronizado, pendiente de verificación

La [PR de Demerzel #1180](https://github.com/GuitarAlchemist/Demerzel/pull/1180) se fusionó como `450fc67`, después de la fijación de `d459d8e`. Esta actualización la sincroniza en Learn:
- el nuevo [módulo MUS-012](../streeling/music/mus-012-chord-formulas-essential-tones-doubling/), Fórmulas de acordes, notas esenciales y duplicaciones, en los tres idiomas;
- su línea en el [índice de música](../streeling/music/) y en el [diario de Streeling](../streeling/journal/), con una entrada fechada en este último.

MUS-012 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## 2026-10-03 — Streeling MUS-012 publicado

La [PR de Learn #124](https://github.com/spareilleux/learn/pull/124) se fusionó como `062e3cb`, después de dos correcciones del diario de Streeling pedidas en una revisión independiente, y su [despliegue de Pages](https://github.com/spareilleux/learn/actions/runs/37143956527) fue correcto. Después, las páginas se leyeron sin autenticación en los tres idiomas: doce páginas, que respondieron todas 200. Las páginas del [módulo MUS-012](../streeling/music/mus-012-chord-formulas-essential-tones-doubling/) nombran MUS-012 y enlazan su fuente en `450fc67`; el [índice de música](../streeling/music/) lo incluye, y el [diario de Streeling](../streeling/journal/) y este diario incluyen sus entradas del 2026-10-03.

MUS-012 pasa así de pendiente de verificación a verificado; su entrada de arriba queda tal como se escribió. Esta actualización fija de nuevo sus enlaces a la fuente en `928fbb2`. Publicado no es estudiado: MUS-012 no se ha ejecutado ni estudiado aquí, y su experimento sigue propuesto.

## 2026-10-03 — Streeling MUS-013 sincronizado, pendiente de verificación

La [PR de Demerzel #1181](https://github.com/GuitarAlchemist/Demerzel/pull/1181) se fusionó como `928fbb2`, después de la fijación de `450fc67`. Esta actualización la sincroniza en Learn:
- el nuevo [módulo MUS-013](../streeling/music/mus-013-root-bass-pitch-class-set/), Fundamental, bajo y conjunto de clases de altura, en los tres idiomas;
- su línea en el [índice de música](../streeling/music/) y en el [diario de Streeling](../streeling/journal/), con una entrada fechada en este último.

MUS-013 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## 2026-10-03 — Streeling MUS-013 publicado

La [PR de Learn #128](https://github.com/spareilleux/learn/pull/128) se fusionó como `0c918c8`, y su [despliegue de Pages](https://github.com/spareilleux/learn/actions/runs/37144727921) fue correcto. Después, las páginas se leyeron sin autenticación en los tres idiomas: doce páginas, que respondieron todas 200. Las páginas del [módulo MUS-013](../streeling/music/mus-013-root-bass-pitch-class-set/) nombran MUS-013 y enlazan su fuente en `928fbb2`; el [índice de música](../streeling/music/) lo incluye, y el [diario de Streeling](../streeling/journal/) y este diario incluyen sus entradas del 2026-10-03.

MUS-013 pasa así de pendiente de verificación a verificado; su entrada de arriba queda tal como se escribió. Esta actualización fija de nuevo sus enlaces a la fuente en `d8c8da5`. Publicado no es estudiado: MUS-013 no se ha ejecutado ni estudiado aquí, y su experimento sigue propuesto.

## 2026-10-03 — Streeling MUS-010 sincronizado, pendiente de verificación

La [PR de Demerzel #1183](https://github.com/GuitarAlchemist/Demerzel/pull/1183) se fusionó como `d8c8da5`, después de la fijación de `928fbb2`. Esta actualización la sincroniza en Learn:
- el nuevo [módulo MUS-010](../streeling/music/mus-010-scales-pattern-set-interval-vector/), Fórmulas de escalas, conjuntos y vector interválico diatónico, en los tres idiomas;
- su línea en el [índice de música](../streeling/music/) y en el [diario de Streeling](../streeling/journal/), con una entrada fechada en este último.

MUS-010 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## 2026-10-03 — Streeling MUS-010 publicado

La [PR de Learn #132](https://github.com/spareilleux/learn/pull/132) se fusionó como `9e03205`, y su [despliegue de Pages](https://github.com/spareilleux/learn/actions/runs/37152236058) fue correcto. Después, las páginas se leyeron sin autenticación en los tres idiomas: doce páginas, que respondieron todas 200. Las páginas del [módulo MUS-010](../streeling/music/mus-010-scales-pattern-set-interval-vector/) nombran MUS-010 y enlazan su fuente en `d8c8da5`; el [índice de música](../streeling/music/) lo incluye, y el [diario de Streeling](../streeling/journal/) y este diario incluyen sus entradas del 2026-10-03.

MUS-010 pasa así de pendiente de verificación a verificado; su entrada de arriba queda tal como se escribió. Esta actualización fija de nuevo sus enlaces a la fuente en `499fc64`. Publicado no es estudiado: MUS-010 no se ha ejecutado ni estudiado aquí, y su experimento sigue propuesto.

## 2026-10-03 — Streeling MUS-011 sincronizado, pendiente de verificación

La [PR de Demerzel #1184](https://github.com/GuitarAlchemist/Demerzel/pull/1184) se fusionó como `499fc64`, después de la fijación de `d8c8da5`. Esta actualización la sincroniza en Learn:
- el nuevo [módulo MUS-011](../streeling/music/mus-011-modes-modal-families/), Modos y familias modales, en los tres idiomas;
- su línea en el [índice de música](../streeling/music/) y en el [diario de Streeling](../streeling/journal/), con una entrada fechada en este último.

MUS-011 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## 2026-10-03 — Streeling MUS-011 publicado

La [PR de Learn #138](https://github.com/spareilleux/learn/pull/138) se fusionó como `aaf6d3e`, y su [despliegue de Pages](https://github.com/spareilleux/learn/actions/runs/37177089952) fue correcto. Después, las páginas se leyeron sin autenticación en los tres idiomas: doce páginas, que respondieron todas 200. Las páginas del [módulo MUS-011](../streeling/music/mus-011-modes-modal-families/) nombran MUS-011 y enlazan su fuente en `499fc64`; el [índice de música](../streeling/music/) lo incluye, y el [diario de Streeling](../streeling/journal/) y este diario incluyen sus entradas del 2026-10-03.

MUS-011 pasa así de pendiente de verificación a verificado; su entrada de arriba queda tal como se escribió. Esta actualización fija de nuevo sus enlaces a la fuente en `518158b`. Publicado no es estudiado: MUS-011 no se ha ejecutado ni estudiado aquí, y su experimento sigue propuesto.

## 2026-10-04 — Streeling MUS-014 sincronizado, pendiente de verificación

La [PR de Demerzel #1185](https://github.com/GuitarAlchemist/Demerzel/pull/1185) se fusionó como `518158b`, después de la fijación de `499fc64`. Esta actualización la sincroniza en Learn:
- el nuevo [módulo MUS-014](../streeling/music/mus-014-inversions-bass-line/), Inversiones y línea de bajo, en los tres idiomas;
- su línea en el [índice de música](../streeling/music/) y en el [diario de Streeling](../streeling/journal/), con una entrada fechada en este último.

MUS-014 sigue **pendiente de verificación** hasta que este cambio se fusione, su despliegue sea correcto y las páginas se lean sin autenticación.

## Por verificar

- Comprobar las URL públicas de esta actualización y el catálogo tras el despliegue; conservar su recibo en el registro de integración.
- Examinar el historial TARS en revisiones concretas antes de explicar la evolución de v1.
- Añadir un calendario solo después de establecer responsables, dependencias y estimaciones. Ninguna fecha de finalización ficticia.

## Preguntas abiertas

- ¿Pueden los recibos de candidatos y operaciones de Gaia imponer estas distinciones sin crear otra máquina de estados competidora?
- ¿Qué lagunas Streeling conviene cubrir en origen antes de la sincronización canónica de Learn?
