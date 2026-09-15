---
title: "2. Contexto de proyecto: CLAUDE.md, AGENTS.md, memoria y compactación"
description: Lo que un agente sabe de tu repositorio antes de su primera llamada a herramienta — CLAUDE.md para Claude Code, AGENTS.md para Codex, y cómo un mismo repositorio sirve a ambos — y después la memoria automática, la compactación, y por qué un archivo de instrucciones guía al modelo pero no impone nada. Con la historia real del AGENTS.md de este sitio y el script de sincronización de GuitarAlchemist/ga.
sidebar:
  order: 2
---

Cada sesión empieza con una ventana de contexto vacía: el modelo no recuerda nada de ayer. Lo que sabe de tu proyecto antes de su primera llamada a herramienta viene de archivos que el programa agente carga para él. En una solución .NET ya tienes archivos así para las herramientas: `.editorconfig` para el formateador, `Directory.Build.props` para MSBuild. La diferencia es que esos se analizan y se aplican; un archivo de instrucciones para un agente es **texto que se le da a un modelo**.

## Dos nombres de archivo, una convención

- [Claude Code](https://code.claude.com/docs/en/memory) lee `CLAUDE.md`, del directorio de trabajo y de cada directorio por encima, más `CLAUDE.local.md` para notas personales que no versionas, y `~/.claude/CLAUDE.md` para todos tus proyectos. Los archivos de los subdirectorios se cargan más tarde, cuando Claude lee archivos allí.
- [Codex](https://learn.chatgpt.com/docs/agent-configuration/agents-md) lee `AGENTS.md`: primero `~/.codex/AGENTS.md`, después un archivo por directorio desde la raíz del proyecto (normalmente la raíz de Git) hasta el directorio de trabajo, con `AGENTS.override.md` teniendo prioridad en su directorio. Los concatena, la raíz primero, y «deja de añadir archivos cuando el tamaño combinado alcanza el límite definido por `project_doc_max_bytes` (32 KiB por defecto)».

Ambos concatenan en lugar de sustituir: el archivo más cercano a donde empezaste va al final, y se espera que el modelo le dé prioridad. Nada garantiza que lo haga.

La documentación es explícita sobre la discrepancia: «Claude Code lee `CLAUDE.md`, no `AGENTS.md`». Para un repositorio que se usa con ambos agentes, sugiere un `CLAUDE.md` que importe `AGENTS.md`:

```markdown
@AGENTS.md
```

Las importaciones `@path` se expanden al iniciar la sesión, relativas al archivo que importa, hasta cuatro saltos de profundidad. Un enlace simbólico también funciona en Linux y macOS; «en Windows, crear un enlace simbólico requiere privilegios de administrador o el modo de desarrollador, así que usa en su lugar la importación `@AGENTS.md`».

### Un experimento: ¿lee Claude Code AGENTS.md?

Dos directorios vacíos, cada uno con el mismo `AGENTS.md`:

```markdown
# Project rules

- The release codename of this project is HEDGEHOG-42.
```

El segundo tiene además un `CLAUDE.md` que solo contiene `@AGENTS.md`. La misma pregunta en ambos, con todas las herramientas eliminadas (`--tools ""`) para que el modelo no pueda ir a leer el archivo por su cuenta, el 2026-09-14 a las 22:37 UTC, Claude Code 2.1.271:

```bash
claude -p "What is the release codename of this project? Answer with the codename only, or UNKNOWN if your instructions don't say." --tools "" --output-format json
```

| Directorio | `result` | `num_turns` |
|---|---|---|
| solo `AGENTS.md` | `UNKNOWN` | 1 |
| `AGENTS.md` y `CLAUDE.md` = `@AGENTS.md` | `HEDGEHOG-42` | 1 |

Un turno cada uno: ninguna llamada a herramienta, la respuesta vino de lo que se cargó antes del primer turno. Con herramientas, el primer modelo podría haber encontrado `AGENTS.md` listando el directorio; eso es un archivo que leyó, no una instrucción que se le dio, y solo ocurriría si al modelo se le ocurriera buscar. La parte Codex del experimento, el mismo `AGENTS.md` sin `CLAUDE.md`, está *por verificar*: la cuenta alcanzó su límite de uso (ver la [lección 1](../01-agents-and-permissions/)).

## Un caso real: el AGENTS.md de este sitio

Este repositorio tiene un `AGENTS.md` de 38 líneas (4696 bytes, muy por debajo de los 32 KiB de Codex) y un `CLAUDE.md` de 11 bytes: `@AGENTS.md`. Su historia es la historia de los errores que los agentes cometieron aquí. `git log --format="%h %ad %s" --date=short -- AGENTS.md`:

```text
1b108b9 2026-09-14 Render Mermaid diagrams, first one in LadybugDB lesson 8 (en, fr, es)
d32b186 2026-09-13 Java lessons 5-8 and a Spanish locale for the whole site
9849105 2026-09-13 Rust course: lessons 13-15, OS tabs, reference links, French mirror
1faa32e 2026-09-13 Add an Artifacts page listing shared Claude artifacts
6145ed7 2026-09-13 Split Software Engineering into sub-areas
95a42da 2026-09-13 Group courses under a Software Engineering area
a79c0bc 2026-09-13 Add Rust for C#/Java developers course, lessons 1-4
f43ba7e 2026-09-13 Import Streeling University modules from Demerzel
eda2608 2026-09-13 Initial learn site: Starlight, bilingual en/fr, WSL containers course
```

Lee las reglas como informes de errores:

- [Línea 8](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L8), de `f43ba7e`: las páginas de Streeling son generadas, «nunca las edites a mano; cambia en su lugar el script». Un agente al que se le pide corregir una errata corrige el archivo que tiene delante; la siguiente sincronización lo desharía en silencio.
- [Línea 13](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L13), de `1faa32e`: nada de `{`, `}` o `<` sueltos en la prosa `.mdx`. MDX los analiza como JSX y la compilación falla.
- [Línea 15](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L15), de `1faa32e`: «Este repositorio lo comparten varias sesiones: añade al índice solo rutas explícitas, justo antes de hacer commit». Varias sesiones de agente trabajan aquí en paralelo; un `git add -A` en una de ellas hace commit de la lección a medio escribir de otra sesión.
- La [línea 5](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L5) cambió tres veces en dos días (`95a42da`, `6145ed7`, `d32b186`), cada vez que cambiaba la estructura del sitio. Un archivo de instrucciones describe una base de código; cuando la base de código se mueve, el archivo tiene que moverse con ella, o induce a error.

De ahí se siguen dos prácticas. Escribe reglas que digan **por qué** en pocas palabras, para que el modelo pueda aplicarlas a un caso que no previste. Y mantén el archivo corto: «apunta a menos de 200 líneas por archivo CLAUDE.md. Los archivos más largos consumen más contexto y reducen la adherencia» ([memoria](https://code.claude.com/docs/en/memory)). Las líneas 17 a 38, sobre el servidor de desarrollo de Astro y los enlaces a la documentación, llegaron con el commit inicial y nunca han cambiado.

## Otra estrategia: GuitarAlchemist/ga copia

[GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) hace la elección opuesta: `CLAUDE.md` es la fuente, 192 líneas y 15 773 bytes, y `AGENTS.md` es una copia generada. [`Scripts/sync-agents-md.ps1`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Scripts/sync-agents-md.ps1#L38-L41) sustituye el título y la nota que dice qué archivo editar:

```powershell
$agentsContent = $claudeContent `
    -replace '^# CLAUDE\.md', '# AGENTS.md' `
    -replace 'Edit `CLAUDE\.md`; never edit `AGENTS\.md` directly\.', 'Source of truth is `CLAUDE.md`. This file is auto-generated — do not edit directly.'
```

El [hook pre-commit](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.githooks/pre-commit.ps1#L196-L229) de Git lo ejecuta antes de cada commit, vuelve a añadir `AGENTS.md` al índice si cambió, y se salta la sincronización durante un merge, un rebase o un cherry-pick, para no sobrescribir una resolución de conflictos. El script tiene además un parámetro `-CheckOnly` para la CI.

| | Este sitio: importación `@AGENTS.md` | ga: copia generada |
|---|---|---|
| Fuente de verdad | `AGENTS.md` | `CLAUDE.md` |
| Bytes duplicados | ninguno | el archivo entero |
| Puede desincronizarse | no | sí, si el hook de Git no está instalado (`pwsh Scripts/install-git-hooks.ps1`) |
| Importaciones `@path` | solo en `CLAUDE.md`, que Codex no lee | solo llegarían a Claude: la documentación de Codex no describe importaciones (*por verificar*) |
| Un agente edita el archivo equivocado | una regla añadida a `CLAUDE.md` solo llega a Claude | una regla añadida a `AGENTS.md` se sobrescribe en el siguiente commit |

Leer el `CLAUDE.md` de ga muestra dos cosas más. Nombra la versión de la extensión de Claude Code que usó su autor, [`anthropic.claude-code-2.1.126`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md?plain=1#L68), 145 versiones de parche antes de la de esta lección: los hechos en los archivos de instrucciones envejecen. Y su sección [*Session-learned rules*](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md?plain=1#L134-L152) la completa un comando personalizado `/correct` cuando el usuario corrige al agente, cada regla con un **Why** y un **How to apply**, y las correcciones delimitadas como bloques `untrusted-correction`: el archivo es a la vez instrucciones y registro.

## Memoria automática

Claude Code tiene un segundo mecanismo, la [memoria automática](https://code.claude.com/docs/en/memory#auto-memory) (auto memory): notas que escribe **Claude** cuando lo corriges o cuando aprende algo que el código no dice, en `~/.claude/projects/<project>/memory/`, un directorio por repositorio Git, compartido por sus worktrees, nunca compartido entre máquinas. «Las primeras 200 líneas de `MEMORY.md`, o los primeros 25KB, lo que ocurra primero, se cargan al inicio de cada conversación»; `MEMORY.md` es un índice que apunta a archivos temáticos que Claude lee cuando hace falta. `/memory` abre estos archivos; son Markdown plano que puedes editar o borrar.

| | `CLAUDE.md` / `AGENTS.md` | Memoria automática |
|---|---|---|
| Escrito por | ti, revisado en pull requests | el agente |
| Compartido | con todos los que clonan el repositorio | no, local a tu máquina |
| Útil para | reglas que todo el equipo debe seguir | tus preferencias, lo que corregiste |

Codex tiene un equivalente, [Memories](https://learn.chatgpt.com/docs/customization/memories), experimental y desactivado por defecto en su referencia de configuración, con el mismo consejo: «Mantén las pautas obligatorias del equipo en `AGENTS.md` o en documentación versionada. Trata las memorias como una capa de recuerdo útil, no como la única fuente de reglas que deben aplicarse siempre».

## Compactación

Una sesión larga llena la ventana de contexto. Ambos agentes entonces **compactan**: sustituyen la conversación por un resumen escrito por el modelo, automáticamente cerca del límite o cuando escribes `/compact` ([Claude Code](https://code.claude.com/docs/en/context-window#what-survives-compaction), [Codex](https://learn.chatgpt.com/docs/developer-commands)). `/compact focus on the failing test` le dice a Claude lo que el resumen debe conservar.

Lo que sobrevive en Claude Code, según su documentación:

| Contenido | Tras la compactación |
|---|---|
| `CLAUDE.md` de la raíz del proyecto, reglas sin ámbito, memoria automática | reinyectados desde el disco |
| Archivos `CLAUDE.md` anidados y reglas con ámbito de ruta | recargados cuando Claude lee un archivo que coincide |
| Archivos que Claude leyó o editó | hasta cinco releídos, los modificados más recientemente primero |
| Skills invocadas | reinyectadas, hasta 5000 tokens cada una y 25 000 en total |
| Instrucciones que escribiste en la conversación | solo lo que conservó el resumen |

La última fila es la práctica: **una regla que diste en el chat puede desaparecer en la compactación; una regla en `CLAUDE.md` vuelve.**

Esta lección se escribió en una sesión que compactó, a las 22:32 UTC del 2026-09-14, con Claude Code 2.1.270 (la actualización a 2.1.271 se aplica en el siguiente arranque). La transcripción de la sesión, un archivo JSONL bajo `~/.claude/projects/`, muestra que el resumen tenía secciones nombradas como dice la documentación: las peticiones, los conceptos técnicos clave, los archivos y el código, los errores y sus correcciones, las tareas pendientes, el trabajo en curso. También muestra algo que la tabla anterior no deja prever. Las instrucciones inyectadas justo después de la compactación eran **el `AGENTS.md` del inicio de la sesión, a las 20:56 UTC, sin la regla de Mermaid incluida en el commit de las 22:01**, mientras que el archivo en disco sí la tenía. El archivo actual llegó, pero 34 minutos después, a las 23:06 UTC, con el siguiente mensaje que recibió la sesión, como un recordatorio de que «instruction files were re-read after the conversation was compacted; these differ from their earlier copies». Entretanto, a las instrucciones en el contexto del agente les faltaba la regla. Por qué la relectura llegó tarde, y si la importación `@AGENTS.md` influye, está *por verificar*; el [diario](../journal/) guarda los detalles. La lección no depende de la causa: tras una sesión larga, no des por hecho que el agente ha visto un cambio en sus archivos de instrucciones. Inicia una sesión nueva.

`/context` muestra lo que llena la ventana en este momento, incluidos los archivos de memoria cargados; `/clear` vuelve a empezar entre tareas no relacionadas, lo que a menudo es mejor que compactar.

## Guiar no es imponer

Todos los mecanismos de esta lección son texto en la ventana de contexto. La documentación de Claude Code lo dice claramente: «Claude los trata como contexto, no como configuración impuesta. Para bloquear una acción independientemente de lo que decida Claude, usa en su lugar un hook PreToolUse», y `CLAUDE.md` «se entrega como un mensaje de usuario después del prompt de sistema», «sin garantía de cumplimiento estricto».

La línea 15 del `AGENTS.md` de este sitio pide a los agentes que añadan al índice rutas explícitas. Es una buena instrucción, y los agentes de aquí la siguen la mayoría de las veces. Pero la máquina en la que se escribe este sitio también tiene un hook que rechaza los comandos `git push` peligrosos antes de que se ejecuten, decida lo que decida el modelo. Las instrucciones reducen la frecuencia con la que el agente intenta algo; los hooks, los permisos y la CI deciden lo que pasa cuando lo intenta. La [lección 3](../03-hooks-skills-subagents/) escribe uno.

Una regla práctica para cada instrucción que estés a punto de añadir:

| Si incumplir la regla… | Ponla en |
|---|---|
| empeora el resultado pero es inofensivo | `CLAUDE.md` / `AGENTS.md` |
| no debe ocurrir nunca | una regla de permisos, un hook o el sandbox, y la razón en `AGENTS.md` |
| puede detectarse a posteriori | la CI, y el comando para ejecutarla en local en `AGENTS.md` |

## Puntos clave

- Claude Code lee `CLAUDE.md`; Codex lee `AGENTS.md`. Un `CLAUDE.md` que contiene `@AGENTS.md` sirve a ambos desde un solo archivo; una copia generada también funciona, si algo la mantiene sincronizada.
- Los archivos de instrucciones se concatenan desde la raíz hacia abajo, se cargan antes del primer turno, y Codex se detiene en 32 KiB por defecto.
- Trata tu archivo de instrucciones como código: corto, revisado, con la razón de cada regla, y actualizado cuando cambia el proyecto.
- La memoria automática es local y la escribe el agente; las reglas del equipo van en el repositorio.
- La compactación conserva los archivos de instrucciones y resume la conversación: pon las instrucciones duraderas en archivos, e inicia una sesión nueva después de cambiarlas.
- Las instrucciones guían; los permisos, los hooks, los sandboxes y la CI imponen.

## Ejercicios

1. El repositorio de un colega solo tiene un `CLAUDE.md` de 300 líneas, y ahora quiere probar Codex sin renombrar nada. ¿Cuál es el cambio más pequeño, y qué dos problemas quedan?

<details>
<summary>Solución</summary>

En `~/.codex/config.toml`, añade `project_doc_fallback_filenames = ["CLAUDE.md"]`: Codex comprueba entonces `AGENTS.override.md`, `AGENTS.md` y después `CLAUDE.md` en cada directorio, como mucho un archivo por directorio ([AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)). Quedan dos problemas. Si el `CLAUDE.md` usa importaciones `@path`, la documentación de Codex no dice nada sobre expandirlas: espera que Codex vea el texto literal `@docs/testing.md` (*por verificar*). Y el ajuste está en la configuración de cada usuario, así que cada colega tiene que repetirlo (si el `.codex/config.toml` de un proyecto lo acepta está *por verificar*). Un `AGENTS.md` versionado, con `CLAUDE.md` reducido a `@AGENTS.md`, evita ambos, y 300 líneas son de todos modos señal de que el archivo debería dividirse.

</details>

2. Clasifica estas instrucciones del `AGENTS.md` de este sitio en «archivo de instrucciones», «imponer» o «detectar en la CI», y di con qué: (a) «usa enlaces relativos en Markdown, nunca enlaces absolutos desde la raíz `/…`»; (b) «añade al índice solo rutas explícitas»; (c) «nunca edites `streeling/` a mano»; (d) «Enlaza la primera mención en cada lección de una herramienta … a su documentación oficial».

<details>
<summary>Solución</summary>

(a) Detectar: un comprobador de enlaces sobre el sitio compilado, o un `grep` de `](/` en `src/content/docs` en la CI. (b) Imponer, en parte: un hook PreToolUse puede rechazar `git add -A`, `git add .` y `git commit -a`, pero no puede saber qué rutas pertenecen a otra sesión; la instrucción se queda. (c) Detectar: la CI ejecuta `npm run sync:streeling` y falla si `git diff` no está vacío; un hook que rechace `Edit` sobre `src/content/docs/**/streeling/**` también funcionaría, con una regla deny `Edit(./src/content/docs/**/streeling/**)` como opción más sencilla. (d) Archivo de instrucciones: «la primera mención de una herramienta» es un juicio que un script no puede hacer de forma fiable; una comprobación en la CI puede al menos verificar que los enlaces resuelven.

</details>

3. En una sesión larga, le dijiste al agente «a partir de ahora, ejecuta `dotnet test --filter Category!=Slow` en lugar de `dotnet test`». Dos horas después vuelve a ejecutar toda la suite. Da dos explicaciones y una solución para cada una.

<details>
<summary>Solución</summary>

La sesión compactó y el resumen no conservó tu frase: las instrucciones dadas solo en la conversación se resumen con todo lo demás. Solución: ponla en `CLAUDE.md` o `AGENTS.md`, que vuelven tras la compactación, o en un archivo de `.claude/rules/`. O el modelo la vio y no la siguió, por ejemplo porque el archivo de instrucciones dice «ejecuta `dotnet test` antes de hacer commit» y ambas se contradicen: corrige el archivo para que haya una sola regla. Si ejecutar las pruebas lentas es realmente perjudicial, ninguna de las dos soluciones es una garantía: un hook PreToolUse que rechace `dotnet test` sin `--filter` sí lo es.

</details>

## Fuentes

- Claude Code: [memoria](https://code.claude.com/docs/en/memory), [ventana de contexto](https://code.claude.com/docs/en/context-window), [cómo funciona Claude Code](https://code.claude.com/docs/en/how-claude-code-works)
- Codex: [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [configuración avanzada](https://learn.chatgpt.com/docs/config-file/config-advanced), [memorias](https://learn.chatgpt.com/docs/customization/memories), [comandos de barra](https://learn.chatgpt.com/docs/developer-commands)
- [agents.md](https://agents.md/), el sitio de la convención `AGENTS.md`
