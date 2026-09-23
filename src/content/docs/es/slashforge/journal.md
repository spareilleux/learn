---
title: Diario
description: Notas de progreso fechadas del curso de SlashForge — la versión estudiada, lo que escribe el instalador y dónde su dry run, su README y sus comentarios no coinciden con él, dónde su comprobación de frontmatter no coincide con Claude Code, y los puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] SlashForge 4.4.3 fijado en `code/slashforge/package.json`; `check.sh` ejecuta el instalador en un directorio personal desechable y en un repositorio desechable
- [x] CI: `check.sh` en Linux, Windows y macOS, sin Claude Code y sin clave de API
- [x] Lección 1: lo que escribe el instalador
- [x] Lección 2: dentro de los archivos — comandos, skills, guías
- [ ] Lección 3: `/slashforge:setup` frente a `/init`, en un repositorio público
- [ ] Lección 4: `/slashforge:code`, diez fases y cuatro puertas
- [ ] Lección 5: `-quick`, `/slashforge:investigate` y `/slashforge:review-pr`
- [ ] Lección 6: hacerlo tuyo

## QA

Cada fila de abajo está reproducida por `check.sh` o leída en el instalador en el tag `v4.4.3`. Ninguna se ha reportado aguas arriba: el repositorio no tenía ninguna issue abierta ni cerrada el 2026-09-22, y sus pruebas no cubren el dry run.

Todavía no hay tabla de experimentos: nada de lo que hay aquí se midió frente a una hipótesis escrita de antemano. Las lecciones 3 a 5, que ejecutan los comandos a través del modelo, son donde eso cambiará.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| `--dry-run` lista lo que escribe la instalación | Lista 21 archivos; la instalación escribe 32. Faltan las nueve skills, `forge-open.sh` y `forge-report-shell.html` | [`bin/install.js#L499-L528`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L499-L528) construye su propia lista a partir de dos de los cuatro arrays | `l01_dry_run_vs_install`: 11 escritos y no anunciados; 0 anunciados y no escritos | Reproducido, no reportado [2026-09-22](#2026-09-22--leer-y-ejecutar-el-instalador) |
| El dry run etiqueta cada archivo con lo que la instalación le hace | Dice `copy` para todas las guías. Las guías se renderizan desde la 4.4.1 | mismas líneas | `l02_global_vs_project`: dos guías difieren entre la instalación global y la de proyecto, cosa que una copia no podría hacer | Reproducido, no reportado [2026-09-22](#2026-09-22--leer-y-ejecutar-el-instalador) |
| El apartado *What gets installed* del README describe la 4.4.3 | Describe tres comandos en `commands/forge/`; la 4.4.3 escribe cuatro comandos y nueve skills en `commands/slashforge/` | [`README.md#L103-L112`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/README.md#L103-L112) | `l01_files` | Reproducido, no reportado [2026-09-22](#2026-09-22--leer-y-ejecutar-el-instalador) |
| Los comentarios del instalador describen su código | Tres son más antiguos que él: *"the three entry points"* encima de una lista de cuatro; `'forge/setup.md' -> '/slashforge:setup'` encima de `commandName`; *"a namespace subdirectory (forge/)"* donde escribe `slashforge/` | [`#L45-L50`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L45-L50), [`#L182-L183`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L183), [`#L259-L260`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L259-L260) | `l02_installer_functions`: `commandName('slashforge/setup.md')` da `/slashforge:setup` | Leído; solo comentarios, ningún comportamiento afectado |
| `--yes`, que la ayuda asocia a *"the update prompt"*, no responde a otras preguntas | Con un stdin que no es una terminal está activado, y `uninstall` lo borra todo sin preguntar | [`#L628-L633`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L628-L633) | `l01_uninstall`: 15 borrados, exit 0, ninguna pregunta | Reproducido; documentado en parte |
| Una plantilla que Claude Code acepta, el instalador la acepta | El instalador lee el frontmatter línea a línea: una `description: >` plegada de YAML se rechaza, y un `---` de cierre seguido de un espacio no se encuentra, aunque al delimitador de apertura sí se le quitan los espacios | [`#L113-L137`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137) | `l02_installer_functions`: 6 rechazos de 7 muestras | Reproducido; solo afecta a las plantillas que añadas tú |
| El campo `name` que exige el instalador da nombre al comando | Claude Code ignora `name` en un archivo bajo `commands/`; es la ruta la que da nombre al comando | [Claude Code, skills](https://code.claude.com/docs/en/skills#where-skills-live) | — | Documentado por ambos lados; una trampa al renombrar (lección 2, ejercicio 1) |

## 2026-09-22 — Leer y ejecutar el instalador

SlashForge 4.4.3 (tag `v4.4.3`, commit `bd75a4f`), Node.js 24.21.0, Windows 11. El instalador en `main` era el mismo archivo ese día.

El curso no deja que el instalador se acerque al verdadero `~/.claude`. `check.sh` apunta `HOME`, y `USERPROFILE` en Windows, a `out/home`, pone `SLASHFORGE_NO_UPDATE_CHECK=1` para que la comprobación de versión no llegue a npm, y ejecuta cada comando con stdin desde `/dev/null`, como hace la CI. Esa última elección revela un comportamiento propio: sin terminal, el instalador responde que sí a todo, desinstalación incluida.

El dry run fue la primera sorpresa. Conté sus líneas a mano y me salieron 23, lo cual era falso: ahora el recuento lo hace `scripts/dry-run-vs-install.mjs`, y dice 21 frente a 32. La causa está en el código y no en una actualización olvidada: la vista previa es un segundo camino dentro del instalador, y el real ganó assets en la 4.1.0 y skills en la 4.2.0 sin ella. Primero escribí que las nueve skills *no se instalaban*; sí se instalan, solo que no se anuncian — la segunda lista del script, *en el dry run pero no escritos*, está vacía.

La lección 2 llama a las funciones exportadas del instalador en lugar de describirlas, lo que es posible porque cargar `install.js` no lo ejecuta. De esa lección salieron dos mediciones: qué archivos difieren entre una instalación global y una de proyecto (nueve: ocho nombran una ruta, y `meta.json`), y los recuentos de líneas que muestran que los cuatro comandos son dispatchers de guías más largas.

La comprobación de plantilla rota copia el paquete, borra una línea `description:` y ejecuta la copia en su propio directorio personal: exit 1, y ningún archivo escrito.

## Por verificar

- Si el modelo encuentra `.claude/setup/slashforge/…` cuando Claude Code se inicia en una subcarpeta de un repositorio con una instalación de proyecto (lección 2).
- El coste en tokens de cada comando, que el README estima, en un repositorio público (lecciones 3 a 5).
- Si una skill escrita como archivo en `commands/` la elige alguna vez el modelo por sí mismo, o solo cuando una guía la nombra.

## Preguntas abiertas

- ¿Aceptaría upstream un dry run construido a partir del propio `installFiles`, como el `-WhatIf` de PowerShell pasa por el mismo `ShouldProcess` que la acción? No propuesto: nada sale de este repositorio sin la aprobación del autor.
