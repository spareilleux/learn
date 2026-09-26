---
title: Diario de actualizaciones
description: Publicaciones, pruebas de entrega y solicitudes pendientes.
---

## Regla de entrega

Solicitado, delegado, realizado localmente, fusionado, desplegado y verificado públicamente son estados distintos. Un agente activo o una PR abierta no constituye una entrega. Cada entrada verificada necesita una revisión, pruebas de validación y un destino público. Este diario es una instantánea fechada, no una conexión en directo a GitHub o wmux.

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

## Por verificar

- Comprobar las URL públicas de esta actualización y el catálogo tras el despliegue; conservar su recibo en el registro de integración.
- Publicar e inspeccionar las dos imágenes ComfyUI solicitadas; un prompt o una tarea en cola no es una imagen.
- Examinar el historial TARS en revisiones concretas antes de explicar la evolución de v1.
- Añadir un calendario solo después de establecer responsables, dependencias y estimaciones. Ninguna fecha de finalización ficticia.

## Preguntas abiertas

- ¿Pueden los recibos de candidatos y operaciones de Gaia imponer estas distinciones sin crear otra máquina de estados competidora?
- ¿Qué lagunas Streeling conviene cubrir en origen antes de la sincronización canónica de Learn?
