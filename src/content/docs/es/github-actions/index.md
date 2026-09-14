---
title: GitHub Actions — Misión
description: Aprender GitHub Actions a partir de ejecuciones reales — compilar, probar y desplegar proyectos .NET y Java, con cada log de las lecciones capturado en el repositorio de este sitio.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada workflow de este curso está en el repositorio de este sitio ([`.github/workflows/gha-*.yml`](https://github.com/spareilleux/learn/tree/main/.github/workflows)) y se ejecuta de verdad en GitHub. Los logs, errores y tiempos citados en las lecciones provienen de esas ejecuciones, en septiembre de 2026 (runner `2.337.0`, imagen `ubuntu-24.04`). El código de ejemplo está en [`code/github-actions`](https://github.com/spareilleux/learn/tree/main/code/github-actions).
:::

## Por qué estoy aprendiendo esto

Este sitio se compila, se prueba y se despliega con [GitHub Actions](https://docs.github.com/actions): un despliegue de Pages en cada push, y una CI que compila los ejemplos Rust, Java y C# de los cursos en Linux, Windows y macOS. Escribí esos workflows copiando y ajustando. Quiero entender qué hace cada línea, por qué falla una ejecución y cómo hacerla rápida y segura.

## A quién va dirigido este curso

Sabes compilar y probar un proyecto .NET o Java desde la línea de comandos (`dotnet test`, `mvn verify`), y conoces Git. Puede que hayas usado otro sistema de CI — [Azure Pipelines](https://learn.microsoft.com/azure/devops/pipelines/), [Jenkins](https://www.jenkins.io/), [GitLab CI](https://docs.gitlab.com/ci/) — pero no es necesario.

## Al final de este curso, sabré

- leer cualquier archivo de workflow y decir cuándo se ejecuta, dónde y en qué orden;
- compilar y probar .NET y Java en tres sistemas operativos con una matrix y caches;
- elegir los disparadores y filtros adecuados, y evitar ejecuciones que se acumulan o que nunca arrancan;
- pasar datos entre steps y entre jobs, y controlar lo que ocurre después de un fallo;
- reutilizar workflows y actions en lugar de copiarlos;
- asegurar un workflow: permisos del token, secretos, actions fijadas, OIDC;
- desplegar un sitio estático en GitHub Pages;
- diagnosticar una ejecución fallida a partir de sus logs.

## Plan

| # | Lección | Si conoces Azure Pipelines |
|---|---|---|
| 1 | [Primer workflow](01-first-workflow/) | pipeline, stage, job, step, agente |
| 2 | [Compilar y probar .NET y Java](02-build-and-test/) | `strategy: matrix`, `UseDotNet@2`, `Cache@2` |
| 3 | [Disparadores, filtros y concurrencia](03-triggers/) | `trigger`, `pr`, `schedules`, parámetros |
| 4 | [Expresiones, contextos y salidas](04-expressions-and-outputs/) | `$[ ]`, variables, variables de salida, `condition` |
| 5 | [Cachés y artefactos](05-caches-and-artifacts/) | `Cache@2`, `PublishPipelineArtifact@1` |
| 6 | [Workflows reutilizables y acciones compuestas](06-reuse/) | plantillas de step, de job y de stage |
| 7 | [Seguridad: permisos, secretos, fijación de versiones, OIDC](07-security/) | conexiones de servicio, federación de identidades de carga de trabajo |
| 8 | [Desplegar en GitHub Pages](08-pages/) | entornos, aprobaciones |
| 9 | [Depurar ejecuciones](09-debugging/) | `system.debug`, logs de diagnóstico, volver a ejecutar los jobs fallidos |
| 10 | Escribir tu propia action *(próximamente)* | tareas personalizadas |
| — | [Diario](journal/) | |

## Recursos

- [Documentación de GitHub Actions](https://docs.github.com/actions)
- [Referencia de la sintaxis de los workflows](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax)
- [Eventos que desencadenan workflows](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [Manual de GitHub CLI: `gh run`](https://cli.github.com/manual/gh_run)
- [Imágenes de los runners](https://github.com/actions/runner-images): lo que está instalado en `ubuntu-latest`, `windows-latest`, `macos-latest`
