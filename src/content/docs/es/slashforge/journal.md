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
- [x] Lecciones 3 a 5 probadas en el laboratorio, en modo headless, cada una hasta su primera puerta: seis ejecuciones, 1.83 USD en total (ver Experimentos)
- [x] Página de la lección 3: `/slashforge:setup` frente a `/init`
- [x] Página de la lección 4: `/slashforge:code`, diez fases y cuatro puertas, con `-quick`
- [x] Página de la lección 5: `/slashforge:investigate` y `/slashforge:review-pr`
- [x] Lección 6: hacerlo tuyo — reglas, verificación, una instalación de equipo; `check.sh` compara ahora 20 salidas
- [x] Lección 7: contribuir aguas arriba, y una nueva prueba de 4.5.0 en Windows

## QA

Cada fila de abajo está reproducida por `check.sh` o leída en el instalador en el tag `v4.4.3`. Ninguna se ha reportado aguas arriba: el repositorio no tenía ninguna issue abierta ni cerrada el 2026-09-22, y sus pruebas no cubren el dry run. El 2026-09-26, el autor reconoció estos hallazgos y anunció correcciones ([entrada](#2026-09-26--la-respuesta-del-autor-y-cómo-comprobar-una-release)), y la release 4.5.0 corrige las ocho filas sobre el instalador y las guías, vueltas a probar en Windows ([nueva prueba](#2026-09-26--nueva-prueba-sobre-slashforge-450)).

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| `--dry-run` lista lo que escribe la instalación | Lista 21 archivos; la instalación escribe 32. Faltan las nueve skills, `forge-open.sh` y `forge-report-shell.html` | [`bin/install.js#L499-L528`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L499-L528) construye su propia lista a partir de dos de los cuatro arrays | `l01_dry_run_vs_install`: 11 escritos y no anunciados; 0 anunciados y no escritos | Reproducido, no reportado [2026-09-22](#2026-09-22--leer-y-ejecutar-el-instalador) · Corregido en v4.5.0, vuelto a probar en Windows ([2026-09-26](#2026-09-26--nueva-prueba-sobre-slashforge-450)) |
| El dry run etiqueta cada archivo con lo que la instalación le hace | Dice `copy` para todas las guías. Las guías se renderizan desde la 4.4.1 | mismas líneas | `l02_global_vs_project`: dos guías difieren entre la instalación global y la de proyecto, cosa que una copia no podría hacer | Reproducido, no reportado [2026-09-22](#2026-09-22--leer-y-ejecutar-el-instalador) · Corregido en v4.5.0, vuelto a probar en Windows ([2026-09-26](#2026-09-26--nueva-prueba-sobre-slashforge-450)) |
| El apartado *What gets installed* del README describe la 4.4.3 | Describe tres comandos en `commands/forge/`; la 4.4.3 escribe cuatro comandos y nueve skills en `commands/slashforge/` | [`README.md#L103-L112`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/README.md#L103-L112) | `l01_files` | Reproducido, no reportado [2026-09-22](#2026-09-22--leer-y-ejecutar-el-instalador) · Corregido en v4.5.0, vuelto a probar en Windows ([2026-09-26](#2026-09-26--nueva-prueba-sobre-slashforge-450)) |
| Los comentarios del instalador describen su código | Tres son más antiguos que él: *"the three entry points"* encima de una lista de cuatro; `'forge/setup.md' -> '/slashforge:setup'` encima de `commandName`; *"a namespace subdirectory (forge/)"* donde escribe `slashforge/` | [`#L45-L50`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L45-L50), [`#L182-L183`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L183), [`#L259-L260`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L259-L260) | `l02_installer_functions`: `commandName('slashforge/setup.md')` da `/slashforge:setup` | Leído; solo comentarios, ningún comportamiento afectado · Corregido en v4.5.0, vuelto a probar en Windows ([2026-09-26](#2026-09-26--nueva-prueba-sobre-slashforge-450)) |
| `--yes`, que la ayuda asocia a *"the update prompt"*, no responde a otras preguntas | Con un stdin que no es una terminal está activado, y `uninstall` lo borra todo sin preguntar | [`#L628-L633`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L628-L633) | `l01_uninstall`: 15 borrados, exit 0, ninguna pregunta | Reproducido; documentado en parte · Corregido en v4.5.0, vuelto a probar en Windows ([2026-09-26](#2026-09-26--nueva-prueba-sobre-slashforge-450)) |
| Una plantilla que Claude Code acepta, el instalador la acepta | El instalador lee el frontmatter línea a línea: una `description: >` plegada de YAML se rechaza, y un `---` de cierre seguido de un espacio no se encuentra, aunque al delimitador de apertura sí se le quitan los espacios | [`#L113-L137`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137) | `l02_installer_functions`: 6 rechazos de 7 muestras | Reproducido; solo afecta a las plantillas que añadas tú · Corregido en v4.5.0, vuelto a probar en Windows ([2026-09-26](#2026-09-26--nueva-prueba-sobre-slashforge-450)) |
| El campo `name` que exige el instalador da nombre al comando | Claude Code ignora `name` en un archivo bajo `commands/`; es la ruta la que da nombre al comando | [Claude Code, skills](https://code.claude.com/docs/en/skills#where-skills-live) | — | Documentado por ambos lados; una trampa al renombrar (lección 2, ejercicio 1) |
| Las guías del kit coinciden sobre dónde va una skill y cuánto puede medir | `forge-instructions.md` dice `.claude/skills/*.md` y *"Every `.md` file … under 200 lines"*; `forge-skills.md` dice una carpeta con `SKILL.md`, por debajo de 500 líneas. La documentación de Claude Code solo lista la forma de carpeta | [`forge-instructions.md#L14-L34`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-instructions.md#L14-L34), [`forge-skills.md#L27-L51`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-skills.md#L27-L51) | Dos contradicciones en guías que el modelo lee en la misma ejecución | Leído, no reportado [2026-09-22](#2026-09-22--lección-6-dos-reglamentos-y-qué-copia-se-ejecuta) · Corregido en v4.5.0, vuelto a probar en Windows ([2026-09-26](#2026-09-26--nueva-prueba-sobre-slashforge-450)) |
| El paso de verificación de setup detecta un archivo de más de 200 líneas | `wc -l CLAUDE.md .claude/**/*.md` en bash sin `globstar` se queda a una carpeta de profundidad, así que el `SKILL.md` de una skill nunca se cuenta | [`forge-instructions.md` Step 9](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-instructions.md#L126-L139) | `l06_verify_glob`: un `SKILL.md` de 300 líneas ausente del recuento, en Linux, Windows y macOS | Reproducido, no reportado [2026-09-22](#2026-09-22--lección-6-dos-reglamentos-y-qué-copia-se-ejecuta) · Corregido en v4.5.0, vuelto a probar en Windows ([2026-09-26](#2026-09-26--nueva-prueba-sobre-slashforge-450)) |

## Experimentos

Las lecciones 3 a 5 ejecutan los comandos a través del modelo, así que cada ejecución tiene una hipótesis escrita antes y un tope (`lab/run.sh` no tiene presupuesto por defecto). Las hipótesis de L3 a L5 se escribieron cuando el laboratorio aún no tenía sesión iniciada; las ejecuciones vinieron después de que el autor iniciara sesión en el laboratorio. Cada ejecución es headless y termina en la primera pregunta que hace el workflow. Los costes son los que Claude Code calcula para el modelo que usó, `claude-opus-5-5[1m]`, el predeterminado de la cuenta: serían más bajos con un modelo más pequeño. Son una ejecución cada uno, no promedios.

| Pregunta | Hipótesis (escrita antes de la ejecución) | Resultado | Veredicto | Entrada, código |
|---|---|---|---|---|
| e0 — ¿Puede el laboratorio ejecutar un comando sin tocar el verdadero `~/.claude`? | Un Claude Code cuyo directorio de configuración está vacío no tiene sesión iniciada, y se detiene antes de cualquier llamada al modelo, sin gastar nada | `Not logged in · Please run /login`, exit 1, 1 turno, 114 ms, 0 tokens de entrada y de salida, 0 USD, 0 archivos cambiados. Tope: 0.25 USD, 3 turnos | Confirmada: el laboratorio está aislado, y no puede ir más lejos sin un inicio de sesión | [2026-09-22](#2026-09-22--el-laboratorio-de-las-lecciones-3-a-5-y-dónde-se-detiene), `lab/run.sh` |
| L3 — ¿Qué escribe `/slashforge:setup` en un repositorio sin `.claude/`, comparado con `/init`? | Escribe `CLAUDE.md` y `.claude/rules/`, y se detiene en la oferta de Graphify (un sí/no) antes de aprovisionar nada | e2: nada escrito. Graphify omitido sin preguntar (por debajo de su umbral del 70%); se detuvo en seis preguntas de aclaración. 6 turnos, 56 s, 0.27 USD. e2b, `/init` sobre el mismo clon: un `CLAUDE.md` de 50 líneas escrito de inmediato, sin preguntas, 9 turnos, 92 s, 0.32 USD | Refutada: setup pregunta antes de escribir, y la puerta de Graphify nunca se activó | [2026-09-22](#2026-09-22--las-lecciones-3-a-5-ejecutadas-en-el-laboratorio), `lab/run.sh` |
| L4 — ¿Hasta dónde llega `/slashforge:code -quick` en modo headless con un cambio pequeño? | Se detiene en la puerta de la fase 3 (confirmar el plan) sin editar el repositorio, por debajo de 70,000 tokens, el extremo alto del rango del README para `-quick` | e3: un plan escueto (un `plannedWrites` exportado, una prueba que lo compara con `installFiles`), y luego una parada, ningún archivo cambiado. Preguntó la fase 3 y la fase 4 (rama) en un solo mensaje. 6 turnos, 57 s, 0.25 USD; 1,720 tokens de entrada y de salida, 23,433 escritos en la caché, 158,847 leídos de ella | Confirmada para la puerta y para «ninguna edición»; la parte de tokens depende de lo que se cuente: solo las lecturas de caché superan 70,000 | [2026-09-22](#2026-09-22--las-lecciones-3-a-5-ejecutadas-en-el-laboratorio) |
| L5a — ¿Se queda `/slashforge:investigate` en solo lectura? | No edita ningún archivo versionado y escribe un informe HTML bajo `docs/slashforge/` | e1 y e1b: ningún archivo cambiado en el repositorio, la causa raíz correcta, y ningún informe, porque construirlo necesita código `node` que el laboratorio rechaza. En e1, donde el laboratorio preaprobaba `Write`, el modelo escribió su generador de informes en `%TEMP%` en su lugar. e1: 15 turnos, 0.45 USD; e1b: detenida por el límite de turnos en 11, 0.38 USD | Confirmada para el repositorio; la mitad del informe queda sin probar; y un `Write` preaprobado no se limita al repositorio | [2026-09-22](#2026-09-22--las-lecciones-3-a-5-ejecutadas-en-el-laboratorio) |
| L5b — ¿Qué hace `/slashforge:review-pr` sin sesión en GitHub? | Se detiene en su comprobación previa del paso 0 y pide `gh auth login`, como dice su archivo, sin ejecutar ningún otro comando | e4: `gh auth status` falló, el comando se detuvo y le dijo al usuario que ejecutara `gh auth login`; nada leído ni escrito en GitHub. 4 turnos, 35 s, 0.17 USD | Confirmada | [2026-09-22](#2026-09-22--las-lecciones-3-a-5-ejecutadas-en-el-laboratorio) |
| e5 — Cuando un comando existe a la vez en `~/.claude` y en el proyecto, ¿cuál se ejecuta? | El personal, como dice la documentación de Claude Code (*"personal over project"*) | e5b: `GLOBAL`, 1 turno, 0.09 USD. e5, con un tope de 0.10 USD, se detuvo con `error_max_budget_usd` en 0.103 USD antes de devolver su respuesta | Confirmada; y el tope funciona con un inicio de sesión por suscripción, comprobado después de cada llamada | [2026-09-22](#2026-09-22--lección-6-dos-reglamentos-y-qué-copia-se-ejecuta) |

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

## 2026-09-22 — Las lecciones 3 a 5, ejecutadas en el laboratorio

El autor inició sesión en el directorio de configuración propio del laboratorio con `claude auth login` (suscripción, no facturación por API), en su propia terminal: la página de inicio de sesión da un código para pegar, cosa que un proceso en segundo plano no puede hacer. `claude auth status` en el laboratorio dijo entonces `"loggedIn": true, "authMethod": "claude.ai"`, y el verdadero `~/.claude` no intervino.

Versiones: Claude Code 2.1.280, modelo `claude-opus-5-5[1m]` (el predeterminado; no se pasó `--model`), SlashForge 4.4.3 sobre su propio repositorio en `v4.4.3`. Seis ejecuciones, cada una con su tope, una a una:

| Ejecución | Prompt | Tope | Turnos | Tiempo | Coste | Se detuvo en |
|---|---|---|---|---|---|---|
| e1 | `/slashforge:investigate` sobre el hallazgo del dry run | 0.50 USD, 10 turnos | 15 | 76 s | 0.45 USD | el paso del informe, rechazado (ver abajo) |
| e2 | `/slashforge:setup` | 0.75 USD, 20 turnos | 6 | 56 s | 0.27 USD | seis preguntas de aclaración |
| e2b | `/init` | 0.50 USD, 20 turnos | 9 | 92 s | 0.32 USD | terminado: `CLAUDE.md` escrito |
| e3 | `/slashforge:code -quick` + la corrección del dry run | 0.75 USD, 20 turnos | 6 | 57 s | 0.25 USD | fase 3 y fase 4 juntas |
| e4 | `/slashforge:review-pr` | 0.25 USD, 5 turnos | 4 | 35 s | 0.17 USD | paso 0: `gh` sin sesión iniciada |
| e1b | e1 otra vez, con el laboratorio corregido | 0.50 USD, 10 turnos | 11 | 58 s | 0.38 USD | el límite de turnos |

Total: 1.83 USD. Ninguna ejecución alcanzó su tope en dólares. Después de e2b, el repositorio del laboratorio se restauró (su `CLAUDE.md` se guarda con los archivos de la ejecución); todas las demás ejecuciones lo dejaron sin cambios.

**Lo que encontró la investigación.** Ambas ejecuciones dieron la causa raíz que da la lección 1: el dry run construye su propia lista a partir de `GUIDE_FILES` y `COMMAND_FILES`, e `installFiles` escribe además `ASSET_FILES` y `SKILL_FILES`, 21 + 2 + 9 = 32. e1 añadió dos cosas que el curso no había escrito: que las guías se etiquetan `copy` aunque se renderizan (la lección 1 lo recoge), y que el dry run no menciona los `REMOVED_GUIDE_FILES` obsoletos que borra. Propuso la corrección que sugiere la lección 1, una única función de planificación compartida por los dos caminos, con una prueba que los compara.

**Una escritura que salió del repositorio.** En e1, `lab/run.sh` listaba `Edit` y `Write` entre las herramientas permitidas. Eso las preaprueba en todas partes, no solo en el directorio de trabajo, y el modelo lo aprovechó: con `node` rechazado para el informe, escribió un script de 4,175 bytes en `%TEMP%\sf-splice.js` y le dijo al usuario que lo ejecutara. El archivo se guarda con la ejecución, y el laboratorio está corregido. `Edit` y `Write` ya no se listan, así que `acceptEdits` solo acepta ediciones dentro del repositorio, y `run.sh` lista cualquier archivo que aparezca en la carpeta temporal durante una ejecución. e1b y e2 a e4 no escribieron nada fuera; el único archivo listado después de e2b era una imagen escrita por otro programa.

**`/init` frente a `/slashforge:setup`.** `/init` escribió un `CLAUDE.md` de 50 líneas de inmediato, y encontró por sí solo la desviación del README que recoge la tabla de QA de este curso ("Known drift: the README's *What gets installed* table still shows `commands/forge/`"). Setup leyó más y no escribió nada: propuso cuatro agentes, preguntó por los hooks, los comandos, las reglas de release y la estructura, y dijo que escribiría `CLAUDE.md` al final. La oferta de Graphify, que la hipótesis esperaba como primera puerta, no apareció: la mayor parte del repositorio es Markdown y `.astro`, por debajo del umbral de lenguaje del 70% de Graphify, y en ese caso setup lo omite en silencio, como dice su archivo.

**Las puertas.** Cada comando se detuvo donde su archivo dice que decide una persona, y ninguno pasó de una. Una desviación: `/slashforge:code -quick` pidió el plan (fase 3) y la rama (fase 4) en el mismo mensaje, mientras que `code.md` dice *"Do not combine phases"*.

**Límites.** Una ejecución por comando, un repositorio, un modelo. Los costes los calcula Claude Code para la sesión de suscripción, no son importes facturados. La comparación de tokens de `-quick` con el README es aproximada, porque el README no dice si su rango cuenta la entrada en caché. El límite de turnos se comportó de forma distinta en dos ejecuciones: e1 informó 15 turnos con `--max-turns 10` y terminó con normalidad, y e1b se detuvo en 11 con `error_max_turns`. La causa queda por verificar.

## 2026-09-22 — Lección 6: dos reglamentos, y qué copia se ejecuta

La mayor parte de la lección 6 es lectura, y de ella salieron dos hallazgos. Las dos guías que el modelo lee durante setup no coinciden: `forge-instructions.md` lista las skills como `.claude/skills/*.md` bajo una regla de oro de 200 líneas, y `forge-skills.md` pide una carpeta con un `SKILL.md` de menos de 500 líneas. Y el paso de verificación al final de setup, `wc -l CLAUDE.md .claude/**/*.md`, no mira dentro de las carpetas de skills en el modo por defecto de bash. `check.sh` construye ahora un pequeño repositorio con un `SKILL.md` de 300 líneas y compara las dos listas de archivos (`l06_verify_glob`), así que la CI lo muestra en los tres sistemas; en zsh, donde `**` es recursivo por defecto, la misma línea vería el archivo.

Una ejecución del modelo, para zanjar lo que significa una instalación de equipo. La hipótesis, escrita a partir de la documentación de Claude Code antes de la ejecución: con `/lab:which` a la vez en el `commands/` personal del laboratorio y en el `.claude/commands/` del repositorio, se ejecuta el personal. e5, con un tope de 0.10 USD, se detuvo con `error_max_budget_usd` en 0.103 USD: el tope funciona con un inicio de sesión por suscripción, y se comprueba después de la llamada, no antes. e5b, con 0.30 USD, respondió `GLOBAL` por 0.09 USD. Los dos archivos de prueba se guardan con la ejecución, y el laboratorio se restauró. Así que un compañero con una instalación global ejecuta su propia versión de `/slashforge:code`, no la que el equipo versionó.

Límite: el comportamiento de setup en una nueva ejecución — actualizar, preguntar o no tocar según la marca `generated_by` — se describe a partir de la guía, no se ha probado; probarlo implica ejecutar setup más allá de sus preguntas dos veces.

## 2026-09-26 — La respuesta del autor, y cómo comprobar una release

Una respuesta atribuida al autor de SlashForge, [Rajdeep Singh Ratan](https://www.linkedin.com/in/rajdeepratan/), se publicó en LinkedIn y se pegó en las notas de trabajo de este curso el 2026-09-26. El enlace permanente y la fecha de publicación del mensaje no se han comprobado; el enlace de arriba lleva al perfil del autor, no al mensaje. En resumen, el autor repasó los hallazgos de este diario, se mostró de acuerdo y anunció que orientarán las próximas releases, entre ellas un manifiesto compartido por el dry run y la instalación, y guías y comprobaciones coherentes entre sí.

Estado cuando se escribió esta entrada: **reconocimiento del autor, correcciones anunciadas, ni corregidas ni vueltas a probar.** Más tarde ese mismo día, este curso vio que la release 4.5.0 ya incluía las correcciones y la volvió a probar: ver la [entrada siguiente](#2026-09-26--nueva-prueba-sobre-slashforge-450). Nada de lo que sigue cambia un resultado medido. Cada fila sigue describiendo `v4.4.3` en `bd75a4f`, y solo pasa a *corregida* después de ejecutar, sobre una release con nombre, la lista de comprobación que sigue.

| Lo que el autor reconoció | Dónde lo midió este diario |
|---|---|
| El dry run lista 21 archivos, la instalación escribe 32 | QA, primera fila (`l01_dry_run_vs_install`) |
| La vista previa dice que las guías se copian cuando se generan | QA, segunda fila (`l02_global_vs_project`) |
| El README quedó desactualizado tras el cambio de nombre | QA, tercera fila |
| Hay comentarios del instalador desactualizados | QA, cuarta fila (leído, solo comentarios) |
| El sí automático no interactivo también cubre `uninstall` | QA, quinta fila (`l01_uninstall`) |
| La validación de plantillas es más estricta que las reglas de Claude Code | QA, sexta fila (`l02_installer_functions`) |
| Dos guías se contradicen sobre la ubicación y la longitud de una skill | QA, fila de las dos guías ([entrada de la lección 6](#2026-09-22--lección-6-dos-reglamentos-y-qué-copia-se-ejecuta)) |
| La comprobación bash de 200 líneas no ve las skills anidadas | QA, fila del paso de verificación (`l06_verify_glob`) |
| Una prueba de Windows pasa pase lo que pase y abre un diálogo de error | [Entrada del laboratorio](#2026-09-22--el-laboratorio-de-las-lecciones-3-a-5-y-dónde-se-detiene) y *Por verificar* |
| Generar el informe con `node` en línea es difícil de autorizar sin riesgo | Experimento L5a, y «Una escritura que salió del repositorio» en la [entrada de las lecciones 3 a 5](#2026-09-22--las-lecciones-3-a-5-ejecutadas-en-el-laboratorio) |
| Cada comando cuesta dinero antes de su primer punto de control | Experimentos L3 a L5b: de 0,17 a 0,45 USD por ejecución, calculados por Claude Code, no facturados |
| No está claro si la entrada en caché cuenta en las cifras de tokens | Experimento L4: solo las lecturas de caché superan los 70 000 del README |
| Una copia global desactualizada gana en silencio al kit versionado en el proyecto | Experimento e5: `GLOBAL` |

**Lista de comprobación de una release.** Para ejecutar sobre la primera release que anuncie estas correcciones, antes de que ninguna fila cambie de estado:

1. Nombrar la release: su tag y el SHA exacto del commit al que apunta, leídos en el repositorio, no en un changelog.
2. Volver a ejecutar las mismas reproducciones (`check.sh`, las comprobaciones `l01`, `l02` y `l06`) en ese commit, en cada sistema que la release declare: Linux, Windows y macOS.
3. Comparar la lista del dry run con los archivos que la instalación escribe de verdad, archivo por archivo, y anotar ambos códigos de salida.
4. Mantener los controles negativos. Una comprobación que no encuentra nada en el commit viejo no prueba nada en el nuevo: ejecutar también cada comprobación en `bd75a4f` y confirmar que allí sigue fallando.
5. Con una entrada estándar que no sea un terminal, comprobar que `uninstall` ya no borra archivos sin una confirmación u opción explícita, y que `--yes` está documentado como que lo cubre si todavía lo hace.
6. Leer cómo define ahora el README el coste por comando y si la entrada en caché cuenta. Volver a ejecutar un comando con un tope en dólares para comparar.
7. Volver a ejecutar e5 con una copia personal y una de proyecto, anotar cuál se ejecuta y si el kit ahora avisa.
8. Actualizar cada fila de QA: *corregido en `<tag>`, vuelto a probar en `<lista de SO>`*, o *sigue abierto en `<tag>`*. Mantener en la fila la medición original y su fecha.

Ninguna gestión de este curso ante el proyecto original: no se publicó, archivó ni envió nada.

## 2026-09-26 — Nueva prueba sobre SlashForge 4.5.0

Comprobar el proyecto original antes de declarar nada abierto reveló una release que el curso no había visto: el tag `v4.5.0` en `10d3d916b30323598515aa27aef43a8527e7e967`, con fecha 2026-09-25. Su [CHANGELOG](https://github.com/rajdeepratan/SlashForge/blob/10d3d916b30323598515aa27aef43a8527e7e967/CHANGELOG.md) anuncia una corrección para cada fila de la tabla QA sobre el instalador y las guías, y también para la prueba de Windows del asistente de apertura y los informes con `node` en línea. Añade un aviso cuando una instalación global oculta una de proyecto, y da crédito a este curso.

`code/slashforge/retest/retest.sh` instala una release dada en una carpeta desechable y vuelve a ejecutar `check.sh` contra lo esperado para 4.4.3. Se ejecutó en Windows 11 con Git Bash y Node 24.12.0:

| | 4.4.3 (control negativo) | 4.5.0 |
|---|---|---|
| `check.sh` contra lo esperado para 4.4.3 | exit 0, 20/20 | exit 1, 16 difieren: lo esperado es de 4.4.3 |
| Dry run contra instalación | 21 listados, 32 escritos, 11 que faltan | 34 y 34, no falta ninguno |
| Etiquetas del dry run | 16 `copy`, 4 `render` | 29 `render`, 4 `copy` |
| `uninstall` sin terminal | 15 borrados, exit 0 | rechazado, exit 1 |
| YAML plegado, cierre con espacio final | ambos rechazados | ambos aceptados; 4 errores reales siguen rechazados |
| Aviso de ocultación con `--project` | ninguno | mostrado |
| Plantillas con `node -e '` en línea | 4 | 0 |
| Paso 9 en tres repositorios desechables (`verify-step9.sh`) | el glob no ve ningún archivo de skill | un `SKILL.md` de 600 líneas y un archivo anidado de 250 líneas señalados; un `SKILL.md` de 300 líneas pasa |

Leído, no ejecutado:
- el README y las guías ahora concuerdan;
- los tres comentarios desactualizados desaparecieron;
- el paquete npm 4.5.0 es idéntico al `bin/` y `templates/` del tag, salvo los finales de línea;
- la nueva prueba del asistente simula los abridores en Linux y macOS y termina enseguida en Windows. Windows ya no abre un diálogo, pero tampoco tiene ninguna aserción.

El README ahora dice que sus rangos de tokens no separan las lecturas de caché de la entrada nueva: una aclaración, no una separación.

Veredicto: las ocho filas sobre el instalador y las guías están **corregidas en 4.5.0, vueltas a probar en Windows**. Cada fila conserva su medición de 4.4.3. No se volvió a probar:
- Linux, macOS ni WSL;
- ninguna ejecución con modelo sobre 4.5.0.

Las lecciones siguen describiendo 4.4.3, y la CI sigue fijándola. La [lección 7](../07-contributing-back/) cuenta la historia y lista lo que sigue abierto.

## Por verificar

- Volver a ejecutar `retest/retest.sh 4.5.0` en Linux y macOS, y en WSL; solo se volvió a probar Windows 11.
- Volver a ejecutar un comando con modelo sobre 4.5.0 (costes, puertas, qué copia se ejecuta) antes de afirmar nada sobre el comportamiento en ejecución tras las correcciones.
- Ejecutar la lista de comprobación de la entrada del 2026-09-26 sobre la primera release que anuncie las correcciones, antes de cambiar cualquier estado de QA.
- Por qué el `node --test` de SlashForge tarda 523 s en Windows con Git Bash, incluida la parte de la prueba de `forge-open.sh`. No volver a ejecutar esa prueba en una sesión de escritorio: abre un cuadro de diálogo de error (ver la entrada del laboratorio).
- Por qué e1 informó 15 turnos con `--max-turns 10` y terminó con normalidad, cuando e1b se detuvo en 11.
- Si el modelo encuentra `.claude/setup/slashforge/…` cuando Claude Code se inicia en una subcarpeta de un repositorio con una instalación de proyecto (lección 2).
- El coste de un workflow completo más allá de sus puertas. El laboratorio se detiene en la primera puerta por diseño; ir más lejos implica responder a las puertas, y eso lo decide el autor.
- Si una skill escrita como archivo en `commands/` la elige alguna vez el modelo por sí mismo, o solo cuando una guía la nombra.

## Preguntas abiertas

- ¿Respeta la nueva ejecución de setup las marcas `generated_by` como dice su guía: actualizar los archivos de la versión actual, preguntar por los más antiguos, no tocar los editados?
- ¿Aceptaría upstream un dry run construido a partir del propio `installFiles`, como el `-WhatIf` de PowerShell pasa por el mismo `ShouldProcess` que la acción? No propuesto: nada sale de este repositorio sin la aprobación del autor.
