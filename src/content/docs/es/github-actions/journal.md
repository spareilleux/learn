---
title: Diario
description: Notas de progreso fechadas — ejecuciones, errores y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Código de ejemplo: la misma función de slug en .NET (xUnit v3) y Java (JUnit 6)
- [x] Lección 1: primer workflow, leer ejecuciones con `gh`
- [x] Lección 2: build con matrix en tres sistemas operativos, setup-dotnet, setup-java, caché de Maven
- [x] Lección 3: disparadores, filtros, inputs, concurrencia
- [x] Lección 4: expresiones, contextos, salidas, condiciones
- [x] Lección 5: cachés y artefactos (caché de NuGet con `packages.lock.json`, `actions/cache`, artefactos entre jobs)
- [ ] Lección 6: workflows reutilizables y actions compuestas
- [ ] Lección 7: seguridad — permisos, secretos, fijación de versiones, OIDC
- [ ] Lección 8: desplegar en GitHub Pages
- [ ] Lección 9: depurar ejecuciones
- [ ] Lección 10: escribir tu propia action

## 2026-09-14 — Primero en local: dos trampas de xUnit v3

Antes de escribir ningún workflow, `dotnet test` en el proyecto de ejemplo (SDK 10.0.112 en local, `xunit.v3` 4.0.1) falló dos veces:

1. `Testing with VSTest target is no longer supported by Microsoft.Testing.Platform on .NET 10 SDK and later.` Corrección: `"test": { "runner": "Microsoft.Testing.Platform" }` en `global.json`.
2. `CS0246: The type or namespace name 'Theory' could not be found`. Con `ImplicitUsings` activado, esta versión del paquete no añadía `using Xunit`. Corrección: el `using` en el archivo de pruebas.

El lado Java (`mvn -B verify`, JUnit 6.1.3, Maven 3.9.16) pasó a la primera.

## 2026-09-14 — Primer push: cuatro workflows, uno inválido

El push de los cuatro workflows de las lecciones (commit `61e7e42`) los inició todos. `GHA 01`, `GHA 02` (6 jobs) y `GHA 04` pasaron. `GHA 03` apareció con el nombre de su archivo, falló en 0 s, sin ningún job: `You have an error in your yaml syntax on line 41`, una línea `run: echo "cron: …"` (un valor sin comillas que contiene `: `). El push siguiente, sin relación con ese archivo, lo hizo fallar de nuevo, a pesar de su filtro `paths`.

Un segundo commit la misma tarde repitió el error en `gha-04-exercises.yml` (`run: echo "next: $BUILD_LABEL"`); esta vez `python -c "import yaml; yaml.safe_load(...)"` lo detectó antes del push. Lección: validar el YAML en local, siempre.

## 2026-09-14 — Colisión de dos despliegues de este sitio

Los pushes `61e7e42` y `cb69dca`, con 14 s de diferencia, iniciaron cada uno `Deploy to GitHub Pages`. El segundo job de despliegue falló:

```text
##[error]HttpError: Deployment request failed for cb69dca950b667b876d8d32cfe778a24b6320c59 due to in progress deployment. Please cancel 61e7e4235b7bc138f2f35cd7f61195bdaed4b019 first or wait for it to complete.
```

El sitio se quedó en la versión anterior hasta el push siguiente. Corrección en `deploy.yml` (commit `5c9896f`): `concurrency: { group: pages, cancel-in-progress: false }`. Varias sesiones hacen push a este repositorio, así que las colisiones iban a volver a ocurrir.

## 2026-09-14 — Mediciones

- Caché de Maven, primera ejecución → segunda ejecución de `gha-02`: Ubuntu 16 s → 10 s, Windows 43 s → 28 s, macOS 20 s → 9 s. Jobs de .NET sin cambios (21/60/20 s → 22/57/22 s): todavía no hay caché de NuGet.
- `global.json` `10.0.100` + `latestFeature` → `setup-dotnet` instaló el SDK 10.0.401.
- Temurin 25.0.4 venía preinstalado en `ubuntu-latest` (`Resolved Java 25.0.4+1 from tool-cache`).
- `macos-latest` es arm64 (clave de caché `setup-java-macOS-arm64-maven-…`).
- Shell por defecto de `run:`: `/usr/bin/bash -e {0}` (Ubuntu), `/bin/bash -e {0}` (macOS), `pwsh -command ". '{0}'"` (Windows). `shell: bash` explícito en Windows: `bash.EXE --noprofile --norc -e -o pipefail {0}`, bash 5.3.15.
- Permisos por defecto de `GITHUB_TOKEN` en este repositorio: `Contents: read`, `Metadata: read`, `Packages: read`. El token tenía 377 caracteres.
- Concurrencia con `cancel-in-progress: true`: la ejecución del push fue cancelada por una ejecución manual 41 s después, cancelada a su vez 10 s más tarde por otra antes de que arrancara su job.

## 2026-09-14 — Lección 5: una caché que no ahorra nada, un conflicto de artefactos que no ocurre

- `setup-dotnet` `cache: true` sin ningún `packages.lock.json`: `Dependencies lock file is not found in /home/runner/work/learn/learn`. Se añadió `RestorePackagesWithLockFile` en `Directory.Build.props`, se hizo commit de los dos archivos de bloqueo, `dotnet restore --locked-mode` en la CI.
- Caché de NuGet, sin caché → acierto: step de restauración 3 s → 1 s (Ubuntu, macOS), 5 s → 4 s (Windows), para una caché de 54 MB por sistema operativo. La descarga de la caché cuesta más o menos lo que ahorra en un proyecto con tres paquetes de prueba. Se mantiene por la lección y por los archivos de bloqueo.
- Salida `cache-hit` de `actions/cache`: vacía sin acierto, `false` con una coincidencia de `restore-keys`, `true` con un acierto exacto.
- Dos jobs de matrix que suben un artefacto llamado `os`: el README anuncia errores de conflicto; en tres ejecuciones de tres, las dos subidas tuvieron éxito y la ejecución tenía dos artefactos llamados `os`. `download-artifact` y `gh run download --name os` devolvieron ambos el de Ubuntu, sin aviso.
- Caducidad de los artefactos: 7 días con `retention-days: 7`, si no, 90 días (`gh api repos/spareilleux/learn/actions/permissions/artifact-and-log-retention` → `{"days":90,"maximum_allowed_days":90}`).

## Preguntas abiertas

- ¿El disparador `schedule` de `gha-03` (lunes 06:17 UTC) se ejecuta a su hora? *Por verificar el 2026-09-21.*
- ¿Qué artefacto elige `download-artifact` cuando dos comparten nombre, y es estable? *Por verificar.*
- ¿Qué muestra exactamente la página de un pull request para un check obligatorio omitido por `paths`? *Por verificar.*
