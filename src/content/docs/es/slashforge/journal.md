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
- [x] Lecciones 1 y 2 repetidas desde un export limpio del código del curso: 19 de 19 salidas coinciden
- [x] Un laboratorio desechable para las lecciones 3 a 5: `code/slashforge/lab/prepare.sh` y `lab/run.sh`, con un tope en cada ejecución
- [ ] Lección 3: `/slashforge:setup` frente a `/init` — **bloqueada, sin probar**: el Claude Code del laboratorio no tiene sesión iniciada
- [ ] Lección 4: `/slashforge:code`, diez fases y cuatro puertas — **bloqueada, sin probar**, por la misma razón
- [ ] Lección 5: `-quick`, `/slashforge:investigate` y `/slashforge:review-pr` — **bloqueada, sin probar**, por la misma razón
- [ ] Lección 6: hacerlo tuyo

## QA

Cada fila de abajo está reproducida por `check.sh` o leída en el instalador en el tag `v4.4.3`. Ninguna se ha reportado aguas arriba: el repositorio no tenía ninguna issue abierta ni cerrada el 2026-09-22, y sus pruebas no cubren el dry run.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| `--dry-run` lista lo que escribe la instalación | Lista 21 archivos; la instalación escribe 32. Faltan las nueve skills, `forge-open.sh` y `forge-report-shell.html` | [`bin/install.js#L499-L528`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L499-L528) construye su propia lista a partir de dos de los cuatro arrays | `l01_dry_run_vs_install`: 11 escritos y no anunciados; 0 anunciados y no escritos | Reproducido, no reportado [2026-09-22](#2026-09-22--leer-y-ejecutar-el-instalador) |
| El dry run etiqueta cada archivo con lo que la instalación le hace | Dice `copy` para todas las guías. Las guías se renderizan desde la 4.4.1 | mismas líneas | `l02_global_vs_project`: dos guías difieren entre la instalación global y la de proyecto, cosa que una copia no podría hacer | Reproducido, no reportado [2026-09-22](#2026-09-22--leer-y-ejecutar-el-instalador) |
| El apartado *What gets installed* del README describe la 4.4.3 | Describe tres comandos en `commands/forge/`; la 4.4.3 escribe cuatro comandos y nueve skills en `commands/slashforge/` | [`README.md#L103-L112`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/README.md#L103-L112) | `l01_files` | Reproducido, no reportado [2026-09-22](#2026-09-22--leer-y-ejecutar-el-instalador) |
| Los comentarios del instalador describen su código | Tres son más antiguos que él: *"the three entry points"* encima de una lista de cuatro; `'forge/setup.md' -> '/slashforge:setup'` encima de `commandName`; *"a namespace subdirectory (forge/)"* donde escribe `slashforge/` | [`#L45-L50`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L45-L50), [`#L182-L183`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L183), [`#L259-L260`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L259-L260) | `l02_installer_functions`: `commandName('slashforge/setup.md')` da `/slashforge:setup` | Leído; solo comentarios, ningún comportamiento afectado |
| `--yes`, que la ayuda asocia a *"the update prompt"*, no responde a otras preguntas | Con un stdin que no es una terminal está activado, y `uninstall` lo borra todo sin preguntar | [`#L628-L633`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L628-L633) | `l01_uninstall`: 15 borrados, exit 0, ninguna pregunta | Reproducido; documentado en parte |
| Una plantilla que Claude Code acepta, el instalador la acepta | El instalador lee el frontmatter línea a línea: una `description: >` plegada de YAML se rechaza, y un `---` de cierre seguido de un espacio no se encuentra, aunque al delimitador de apertura sí se le quitan los espacios | [`#L113-L137`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137) | `l02_installer_functions`: 6 rechazos de 7 muestras | Reproducido; solo afecta a las plantillas que añadas tú |
| El campo `name` que exige el instalador da nombre al comando | Claude Code ignora `name` en un archivo bajo `commands/`; es la ruta la que da nombre al comando | [Claude Code, skills](https://code.claude.com/docs/en/skills#where-skills-live) | — | Documentado por ambos lados; una trampa al renombrar (lección 2, ejercicio 1) |

## Experimentos

Las lecciones 3 a 5 ejecutan los comandos a través del modelo, así que cada ejecución tiene una hipótesis escrita antes y un tope (`lab/run.sh` no tiene presupuesto por defecto). Solo se ejecutó la primera. Se detuvo antes de llamar al modelo, y las demás filas son hipótesis que esperan un inicio de sesión, no resultados.

| Pregunta | Hipótesis (escrita antes de la ejecución) | Resultado | Veredicto | Entrada, código |
|---|---|---|---|---|
| e0 — ¿Puede el laboratorio ejecutar un comando sin tocar el verdadero `~/.claude`? | Un Claude Code cuyo directorio de configuración está vacío no tiene sesión iniciada, y se detiene antes de cualquier llamada al modelo, sin gastar nada | `Not logged in · Please run /login`, exit 1, 1 turno, 114 ms, 0 tokens de entrada y de salida, 0 USD, 0 archivos cambiados. Tope: 0.25 USD, 3 turnos | Confirmada: el laboratorio está aislado, y no puede ir más lejos sin un inicio de sesión | [2026-09-22](#2026-09-22--el-laboratorio-de-las-lecciones-3-a-5-y-dónde-se-detiene), `lab/run.sh` |
| L3 — ¿Qué escribe `/slashforge:setup` en un repositorio sin `.claude/`, comparado con `/init`? | Escribe `CLAUDE.md` y `.claude/rules/`, y se detiene en la oferta de Graphify (un sí/no) antes de aprovisionar nada | Sin medir | Bloqueada: sin sesión | ídem |
| L4 — ¿Hasta dónde llega `/slashforge:code -quick` en modo headless con un cambio pequeño? | Se detiene en la puerta de la fase 3 (confirmar el plan) sin editar el repositorio, por debajo de 70,000 tokens, el extremo alto del rango del README para `-quick` | Sin medir | Bloqueada: sin sesión | ídem |
| L5a — ¿Se queda `/slashforge:investigate` en solo lectura? | No edita ningún archivo versionado y escribe un informe HTML bajo `docs/slashforge/` | Sin medir | Bloqueada: sin sesión | ídem |
| L5b — ¿Qué hace `/slashforge:review-pr` sin sesión en GitHub? | Se detiene en su comprobación previa del paso 0 y pide `gh auth login`, como dice su archivo, sin ejecutar ningún otro comando | Sin medir | Bloqueada: sin sesión | ídem |

## 2026-09-22 — Leer y ejecutar el instalador

SlashForge 4.4.3 (tag `v4.4.3`, commit `bd75a4f`), Node.js 24.12.0 en local y 24.21.0 en CI, Windows 11. El instalador en `main` era el mismo archivo ese día.

El curso no deja que el instalador se acerque al verdadero `~/.claude`. `check.sh` apunta `HOME`, y `USERPROFILE` en Windows, a `out/home`, pone `SLASHFORGE_NO_UPDATE_CHECK=1` para que la comprobación de versión no llegue a npm, y ejecuta cada comando con stdin desde `/dev/null`, como hace la CI. Esa última elección revela un comportamiento propio: sin terminal, el instalador responde que sí a todo, desinstalación incluida.

El dry run fue la primera sorpresa. Conté sus líneas a mano y me salieron 23, lo cual era falso: ahora el recuento lo hace `scripts/dry-run-vs-install.mjs`, y dice 21 frente a 32. La causa está en el código y no en una actualización olvidada: la vista previa es un segundo camino dentro del instalador, y el real ganó assets en la 4.1.0 y skills en la 4.2.0 sin ella. Primero escribí que las nueve skills *no se instalaban*; sí se instalan, solo que no se anuncian — la segunda lista del script, *en el dry run pero no escritos*, está vacía.

La lección 2 llama a las funciones exportadas del instalador en lugar de describirlas, lo que es posible porque cargar `install.js` no lo ejecuta. De esa lección salieron dos mediciones: qué archivos difieren entre una instalación global y una de proyecto (nueve: ocho nombran una ruta, y `meta.json`), y los recuentos de líneas que muestran que los cuatro comandos son dispatchers de guías más largas.

La comprobación de plantilla rota copia el paquete, borra una línea `description:` y ejecuta la copia en su propio directorio personal: exit 1, y ningún archivo escrito.

## 2026-09-22 — El laboratorio de las lecciones 3 a 5, y dónde se detiene

Versiones: Claude Code 2.1.280, Node.js 24.12.0 en local, SlashForge 4.4.3, Windows 11 con Git Bash.

**Lecciones 1 y 2, repetidas.** Exporté `code/slashforge` desde el commit publicado (`cfa14ef`) a una carpeta nueva, ejecuté `npm ci` y `bash check.sh`: 19 de 19 salidas coinciden, en 135 s incluida la instalación. La CI pasó en Linux, Windows y macOS para el mismo commit. Después, el verdadero `~/.claude` no tenía carpeta `commands/` ni `setup/`: nada de SlashForge.

**El laboratorio.** `lab/prepare.sh <dir>` crea un directorio personal, un directorio de configuración de Claude Code (`CLAUDE_CONFIG_DIR`), un directorio para la CLI de GitHub (`GH_CONFIG_DIR`) y una configuración de git, todo dentro de `<dir>`. Clona el propio SlashForge en `v4.4.3` (público, MIT, sin dependencias) en una rama `lab`, quita el remote y añade un hook pre-push que rechaza. Luego instala el kit de forma global en el directorio personal del laboratorio. Comprobé esa protección con un push a un repositorio bare local: `lab: push refused`, exit 1.

`lab/run.sh <dir> <name> <max-usd> <max-turns> <prompt>` ejecuta `claude -p` en el repositorio del laboratorio con `--max-budget-usd`, `--max-turns` y un timeout de 900 s. Acepta ediciones, solo permite git de solo lectura, `ls` y las pruebas, y rechaza `git push`, `gh`, `curl`, la web y los servidores MCP. Registra el código de salida, el tiempo real, los turnos, los tokens, el coste que calcula Claude Code, los permisos denegados y cuántas rutas cambiaron. Una ejecución headless termina en la primera pregunta que hace el workflow, así que una puerta de SlashForge termina la ejecución. Nunca se responde.

**El experimento más pequeño, e0**: `/slashforge:investigate` sobre el hallazgo del dry run de la lección 1, con un tope de 0.25 USD y 3 turnos. Claude Code respondió `Not logged in · Please run /login` en 114 ms, con 0 tokens y 0 USD, y el repositorio del laboratorio no cambió. Su resultado JSON informa `"subtype": "success"` con `"is_error": true` y `"terminal_reason": "api_error"`, así que un script tiene que leer `is_error` y no `subtype`.

**Dónde se detiene.** Iniciar sesión en el laboratorio necesita a una persona. El inicio de sesión es un flujo en el navegador para la cuenta del autor, y copiar las credenciales reales al laboratorio sería leer `~/.claude`, justo lo que este laboratorio existe para no hacer. Así que las lecciones 3 a 5 se detienen aquí, en el paso cero. Las puertas a las que habrían llegado los comandos se listan abajo, sacadas de sus archivos, no de una ejecución:

| Comando | Dónde espera a una persona |
|---|---|
| `/slashforge:setup` | la oferta de Graphify (sí/no), las preguntas de aclaración, y antes de sobrescribir un archivo que generó en una versión anterior |
| `/slashforge:code` y `-quick` | fase 3 confirmar el plan, fase 4 decisión de rama, fase 8 push y PR, fase 10 limpieza; `-quick` conserva las cuatro |
| `/slashforge:investigate` | solo cuando se llama sin un síntoma |
| `/slashforge:review-pr` | paso 0 (`gh` debe tener sesión iniciada, o se detiene), R1 elegir la PR, R5 antes de publicar nada |

Dos de ellas necesitan una autoridad que este laboratorio no tiene y que no se le debe dar: la fase 8 hace push y abre una pull request, y `review-pr` publica en GitHub.

**Las propias pruebas de SlashForge, en el laboratorio.** `node --test` sobre el clon salió con 0 pero tardó 523 s. No capturé el número de pruebas superadas, porque mi filtro esperaba líneas TAP y el reporter por defecto imprime otra cosa. Sospeché de la prueba de `forge-open.sh`, que ejecuta `start` bajo Git Bash. Ejecutada sola, pasa en 20 s, y primero concluí que no era la causa. Esa conclusión era errónea: aquí una prueba en verde no demuestra nada. [`test/install.test.js:527`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/test/install.test.js#L527) llama al helper con `/tmp/definitely-does-not-exist-slashforge.html`, y en Windows [`forge-open.sh`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-open.sh#L37-L40) ejecuta `start`, se traga el error y devuelve 0. Así que la prueba queda en verde haga lo que haga `start`: es un falso positivo. Una captura de pantalla del autor muestra que muestra un cuadro de diálogo de error de Windows en el escritorio. Los 20 s tampoco descartan el helper como causa de los 523 s. No volví a ejecutar la prueba, porque abre una ventana. La causa de los 523 s queda por verificar.

## Por verificar

- Por qué el `node --test` de SlashForge tarda 523 s en Windows con Git Bash, incluida la parte de la prueba de `forge-open.sh`. No volver a ejecutar esa prueba en una sesión de escritorio: abre un cuadro de diálogo de error (ver la entrada del laboratorio).
- Si `--max-budget-usd` detiene una ejecución con un inicio de sesión por suscripción, como lo hace con una clave de API (de la lección 3 en adelante).
- Si el modelo encuentra `.claude/setup/slashforge/…` cuando Claude Code se inicia en una subcarpeta de un repositorio con una instalación de proyecto (lección 2).
- El coste en tokens de cada comando, que el README estima, en un repositorio público (lecciones 3 a 5).
- Si una skill escrita como archivo en `commands/` la elige alguna vez el modelo por sí mismo, o solo cuando una guía la nombra.

## Preguntas abiertas

- Cómo iniciar sesión en el laboratorio: `claude auth login` con `CLAUDE_CONFIG_DIR` apuntando al laboratorio, o un token de `claude setup-token` en `CLAUDE_CODE_OAUTH_TOKEN`. En ambos casos es decisión del autor, igual que el presupuesto para L3 a L5.
- ¿Aceptaría upstream un dry run construido a partir del propio `installFiles`, como el `-WhatIf` de PowerShell pasa por el mismo `ShouldProcess` que la acción? No propuesto: nada sale de este repositorio sin la aprobación del autor.
