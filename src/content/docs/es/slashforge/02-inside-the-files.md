---
title: 2. Dentro de los archivos — comandos, skills, guías
description: Cómo un archivo bajo commands/ se convierte en /slashforge:code, para qué sirve el frontmatter cuando lo leen dos programas distintos, qué rechaza el instalador y por qué lo rechaza antes de escribir nada, cómo {{INSTALL_PATH}} hace absoluta una instalación global y relativa una instalación de proyecto, y cómo cuatro comandos cortos delegan en guías largas.
sidebar:
  order: 2
---

Código: [`code/slashforge/check.sh`](https://github.com/spareilleux/learn/blob/main/code/slashforge/check.sh) y [`scripts/installer-functions.mjs`](https://github.com/spareilleux/learn/blob/main/code/slashforge/scripts/installer-functions.mjs), que llama a las propias funciones del instalador. Las salidas están en [`expected/`](https://github.com/spareilleux/learn/tree/main/code/slashforge/expected).

El instalador [exporta](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L660-L676) las funciones de las que está hecho, y cargarlo no lo ejecuta — su punto de entrada está protegido por [`require.main === module`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L652-L658), el equivalente en Node de un `Main` que solo se ejecuta cuando el ensamblado es el ensamblado de entrada. Así que, en lugar de describir lo que hace, esta lección lo llama.

## Una ruta se convierte en un nombre

```
# A file path under commands/ becomes the name you type
slashforge/setup.md            /slashforge:setup
slashforge/code.md             /slashforge:code
slashforge/investigate.md      /slashforge:investigate
slashforge/review-pr.md        /slashforge:review-pr
slashforge/brainstorm.md       /slashforge:brainstorm
slashforge/plan.md             /slashforge:plan
slashforge/debug.md            /slashforge:debug
slashforge/tdd.md              /slashforge:tdd
slashforge/verify.md           /slashforge:verify
slashforge/review-feedback.md  /slashforge:review-feedback
slashforge/request-review.md   /slashforge:request-review
slashforge/worktree.md         /slashforge:worktree
slashforge/parallel.md         /slashforge:parallel
```

La función [`commandName`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L186) del instalador aplica la regla que Claude Code documenta sobre [cómo obtiene una skill su nombre de comando](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name): para un archivo en un subdirectorio de `commands/`, *"subdirectory path relative to `commands/` with each `/` replaced by `:`, then the file name without extension"*. Es enrutamiento por carpeta, como un área de ASP.NET o un paquete Java convierten un directorio en prefijo. Nada del interior del archivo interviene. El prefijo es además toda la estrategia contra colisiones: un comando `/code` tuyo y `/slashforge:code` pueden convivir.

## El frontmatter tiene dos lectores

Cada archivo empieza con un bloque de frontmatter entre líneas `---`. Este es el de [`code.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/code.md):

```markdown
---
name: /slashforge:code
description: End-to-end development workflow — gather requirements, plan, confirm, branch, implement, verify, review, push, PR. Pass `-quick` for lean mode on small changes (skips brainstorming, minimal plan, inline self-review instead of the agent review). Uses SlashForge's own skills at each phase — no plugins required.
---
```

Dos programas leen este bloque, por razones distintas. El instalador lo lee para [rechazar una plantilla rota](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137), y exige `name` y `description`. Claude Code lo lee para configurar el comando — y para un archivo en `commands/`, su documentación dice que el archivo [*"supports the same frontmatter except `name` and `paths`"*](https://code.claude.com/docs/en/skills#where-skills-live). El único campo en el que insiste el instalador es uno que Claude Code no usa para este tipo de archivo. `name: /slashforge:code` es una etiqueta para humanos y para la comprobación del instalador; el nombre del comando viene de la ruta, como arriba. Renombra el archivo y el comando cambia de nombre; edita la línea `name` y no pasa nada.

Los dos lectores tampoco analizan igual. Claude Code lee YAML. El instalador lee [línea a línea](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137): toda línea no vacía entre los delimitadores debe tener la forma `key: value`, con una clave hecha de letras, dígitos, `_` y `-`. Llamando a `parseFrontmatter` con algunas muestras:

```
# What the frontmatter check refuses
no opening fence: demo.md: missing opening '---' frontmatter fence
no closing fence: demo.md: missing closing '---' frontmatter fence
no description: demo.md: frontmatter missing required field 'description'
a key with a space: demo.md: invalid frontmatter at line 3: "long description: d"
a closing fence with a trailing space: demo.md: missing closing '---' frontmatter fence
a folded YAML description: demo.md: invalid frontmatter at line 4: "  two lines"
valid: ok {"name":"/demo","description":"d"}
```

La descripción plegada es YAML válido, y Claude Code la leería como una sola línea de texto. El instalador la rechaza. Ninguno se equivoca en su propio trabajo — el instalador solo tiene que aceptar las veintinueve plantillas que distribuye, y todas usan valores de una línea —, pero una comprobación más estricta que el runtime que protege merece conocerse antes de añadir una plantilla propia y preguntarte por qué un archivo que Claude Code acepta no se instala.

## Rechazado antes de escribir nada

`check.sh` copia el paquete, borra la línea `description:` de una skill y ejecuta el instalador de esa copia en otro directorio personal vacío:

```
Template validation failed:
  ✗ slashforge/verify.md: frontmatter missing required field 'description'
Error: Refusing to install with invalid templates.
exit 1
```

y después lista los archivos de ese directorio personal: ninguno. La [función `install`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L477-L483) valida las cuatro listas antes de crear una sola carpeta, y un [comentario](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L142-L143) da la razón: *"a half-installed kit is worse than none"*. Es el patrón de un lote validado entero antes de `SaveChanges`, en lugar de guardado fila a fila hasta que una falla.

## `{{INSTALL_PATH}}`: absoluta en un modo, relativa en el otro

Un comando tiene que decirle al modelo dónde están las guías. Las plantillas escriben `{{INSTALL_PATH}}`, y el instalador [lo sustituye](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L175-L180) — junto con `{{KIT_VERSION}}` y `{{KIT_PACKAGE}}` — al escribir el archivo. Con qué lo sustituye depende del modo:

```
# The two install modes
global   guides   /home/ada/.claude/setup/slashforge
global   commands /home/ada/.claude/commands
global   {{INSTALL_PATH}} = /home/ada/.claude/setup/slashforge
project  guides   /src/app/.claude/setup/slashforge
project  commands /src/app/.claude/commands
project  {{INSTALL_PATH}} = .claude/setup/slashforge
```

En una instalación global la ruta es absoluta, y siempre escrita con `/`, Windows incluido. En una instalación de proyecto es relativa al repositorio. Una línea de `code.md`, tal como se distribuye y después de cada instalación:

```
# template
- **The argument contains `-quick`** → **LEAN MODE.** Read `{{INSTALL_PATH}}/forge-workflow-quick.md` in full, in addition to the workflow files below, and apply its overrides on top of everything in this file. Tell the user: *"Lean mode — skipping brainstorming, minimal plan, inline self-review."*
# global
- **The argument contains `-quick`** → **LEAN MODE.** Read `~/.claude/setup/slashforge/forge-workflow-quick.md` in full, in addition to the workflow files below, and apply its overrides on top of everything in this file. Tell the user: *"Lean mode — skipping brainstorming, minimal plan, inline self-review."*
# project
- **The argument contains `-quick`** → **LEAN MODE.** Read `.claude/setup/slashforge/forge-workflow-quick.md` in full, in addition to the workflow files below, and apply its overrides on top of everything in this file. Tell the user: *"Lean mode — skipping brainstorming, minimal plan, inline self-review."*
# placeholders left in the installed files
global  0
project 0
```

(`check.sh` escribe el directorio personal desechable como `~`; el archivo instalado contiene la ruta absoluta completa.) Esa ruta relativa es lo que hace commiteable una instalación de proyecto: una ruta absoluta contendría el nombre de quien ejecutó el instalador. También significa que el modelo tiene que resolver la ruta desde la raíz del repositorio. Si sigue encontrando las guías cuando Claude Code se inicia en una subcarpeta está *por verificar*: eso depende del modelo y de su directorio de trabajo, no del instalador.

Comparar las dos instalaciones archivo por archivo muestra exactamente dónde difieren los modos, con el número de líneas cambiadas:

```
  2  ./commands/slashforge/brainstorm.md
  3  ./commands/slashforge/code.md
  2  ./commands/slashforge/investigate.md
  2  ./commands/slashforge/plan.md
  2  ./commands/slashforge/review-pr.md
 18  ./commands/slashforge/setup.md
  3  ./setup/slashforge/forge-workflow-investigation.md
  2  ./setup/slashforge/forge-workflow-review-pr.md
  2  ./setup/slashforge/meta.json
```

Ocho archivos nombran una ruta, y `meta.json` registra el modo y la hora. Los otros veintitrés son idénticos. Hasta la 4.4.1 las guías se copiaban en lugar de renderizarse, así que una guía no podía nombrar otro archivo por su ruta; el [changelog](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/CHANGELOG.md) registra ese arreglo, y las dos guías de arriba son las que lo necesitaban.

Esta tabla es también la prueba de lo que la [lección 1](../01-what-the-installer-writes/#lo-que-el-dry-run-no-anuncia) leyó en el changelog: el dry run sigue diciendo `copy   forge-workflow-review-pr.md`, y un archivo copiado no podría diferir entre los dos modos.

## Comandos cortos, guías largas

Los cuatro puntos de entrada son pequeños. La mayor parte de lo que hacen está en las guías que mandan leer al modelo:

```
 110  slashforge/setup.md
  70  slashforge/code.md
 165  forge-workflow.md
  46  forge-workflow-agents.md
  94  forge-workflow-quick.md
  51  slashforge/investigate.md
 154  forge-workflow-investigation.md
  67  slashforge/review-pr.md
 302  forge-workflow-review-pr.md
```

`code.md` contiene la selección de modo y la pregunta de entrada, y después dice:

```markdown
## Workflow files

Read the following in full — together they are your complete workflow guide:

- {{INSTALL_PATH}}/forge-workflow.md
- {{INSTALL_PATH}}/forge-workflow-agents.md

You MUST follow every phase in order. Do not skip phases. Do not combine phases.
```

El changelog llama a esta forma *a dispatcher plus a workflow file*. `review-pr.md` tenía 301 líneas hasta que la 4.4.1 movió sus fases a `forge-workflow-review-pr.md`, e `investigate.md` 143 líneas hasta que la 4.4.2 hizo lo mismo, *"so I3 existed twice, in two levels of detail, and the two could drift"*. Es la misma refactorización que sacar la lógica de un controlador a un servicio: el punto de entrada sigue siendo lo bastante pequeño para leerlo de un vistazo, y cada regla se escribe una sola vez.

Hay un coste que la tabla no muestra. Un archivo de comando se carga cuando lo escribes; una guía se carga cuando el modelo decide leerla, como llamada a herramienta, y cuenta en la conversación como cualquier archivo que lea. `/slashforge:code` pide 211 líneas de guías antes de su primera pregunta.

## Skills que son archivos de comando

Las nueve skills son archivos del mismo tipo, en la misma carpeta. [`verify.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/verify.md) empieza así:

```markdown
---
name: /slashforge:verify
description: Evidence before claims. Use before stating that anything is done, fixed, passing, or ready — and before committing, opening a PR, or handing off. Requires running the verification command and reading its output first.
---

<!--
Adapted from the `verification-before-completion` skill in superpowers.
Copyright (c) 2025 Jesse Vincent. Licensed under the MIT License.
```

Están adaptadas de [superpowers](https://github.com/obra/superpowers), y cada una lleva el aviso MIT en un comentario HTML, porque los archivos se instalan lejos del repositorio que contiene la licencia. Claude Code tiene dos formatos para esto: una [skill](https://code.claude.com/docs/en/skills) propiamente dicha es una carpeta con un `SKILL.md` y sitio para archivos de apoyo, y un archivo en `commands/` es *"the older format"* que *"still works"*. SlashForge usa el antiguo para los trece archivos, que es lo que permite que una sola carpeta les dé un solo prefijo. El workflow no espera a que el modelo elija una skill: las guías nombran la que hay que usar en cada fase — `slashforge:plan` en la fase 2, `slashforge:verify` en la fase 6, y así sucesivamente.

## Puntos clave

- La ruta de un archivo bajo `commands/` es su nombre; el campo `name` de un archivo de comando lo ignora Claude Code y lo exige el instalador de SlashForge.
- La comprobación de frontmatter del instalador es un analizador de líneas, más estricto que el YAML que lee Claude Code: un `description: >` plegado se rechaza.
- Cada plantilla se valida antes de escribir el primer archivo, así que un paquete roto no instala nada.
- `{{INSTALL_PATH}}` es absoluta en una instalación global y relativa en una instalación de proyecto; ocho archivos la usan, y por eso son los únicos que difieren entre los dos modos.
- Los cuatro comandos son dispatchers de 51 a 110 líneas; el workflow en sí está en guías de hasta 302 líneas que el modelo lee cuando las necesita.

## Ejercicios

1. Renombras el `commands/slashforge/verify.md` instalado a `check.md` y dejas su frontmatter como está. ¿Qué escribes ahora para ejecutarlo, y qué pasa la próxima vez que ejecutes el instalador?
2. El instalador comprueba cuatro listas antes de escribir. Supón que validara cada archivo justo antes de escribirlo. ¿Qué dejaría en el directorio personal el experimento de la `description` vacía de arriba?
3. En `l02_global_vs_project`, `setup.md` difiere en 18 líneas y `code.md` en 3. Sin abrir los archivos, ¿qué te dice eso de los dos comandos?

<details>
<summary>Solución</summary>

1. `/slashforge:check`: el nombre viene de la ruta del archivo, y Claude Code ignora `name` en un archivo de comando, así que la antigua línea `name: /slashforge:verify` no cambia nada. La siguiente instalación vuelve a escribir `verify.md`, porque el instalador trabaja con su propia lista, no con lo que hay en disco — y entonces tienes dos comandos con el mismo contenido, `/slashforge:check` y `/slashforge:verify`. Las guías siguen mandando al modelo a `slashforge:verify`, así que tu copia renombrada es la que nada usa.
2. Los archivos escritos antes de `verify.md` en el orden del instalador: las dieciséis guías, los dos assets y los comandos y skills que lo preceden en `[...COMMAND_FILES, ...SKILL_FILES]` — `setup`, `code`, `investigate`, `review-pr`, `brainstorm`, `plan`, `debug`, `tdd` —, sin `meta.json`, que se escribe el último: 26 archivos. Un kit al que le falta la skill de su fase 6, y que [`status`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L439-L457) describiría como *"unknown (legacy install — no meta.json)"*, ya que la carpeta de guías existe pero `meta.json` no.
3. Que `setup.md` nombra las guías por su ruta muchas más veces: es el comando que manda al modelo a la mayoría de ellas — reglas, skills, agentes, comandos, hooks, memoria —, una línea cada una, mientras que `code.md` nombra tres. Los recuentos de líneas son un mapa de qué comando depende de qué guías, dibujado por un `diff`.

</details>
