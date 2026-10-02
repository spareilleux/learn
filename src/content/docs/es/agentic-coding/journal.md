---
title: Diario
description: Notas de progreso fechadas del curso de programación agéntica — las versiones de Claude Code, Codex y el SDK de MCP, las capturas y lo que costaron, las sorpresas de ambos agentes y del servidor MCP de GuitarAlchemist/ga, y los puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Claude Code y la CLI de Codex instalados en Windows; versiones anotadas abajo
- [x] CI: el hook, el servidor MCP (cliente del SDK y sesiones raw en las dos eras del protocolo) y los archivos de configuración, en Linux, Windows y macOS, sin agente ni clave de API
- [x] Lección 1: agentes, herramientas y permisos
- [x] Lección 2: contexto de proyecto, `CLAUDE.md`, `AGENTS.md`, memoria y compactación
- [x] Lección 3: hooks, skills y subagentes
- [x] Lección 4: MCP, un servidor C# para ambos agentes
- [x] Lección 5: skills de Matt Pocock y workflow de tracer bullets
- [x] Lección 6: laboratorio acotado de aislamiento Sandcastle
- [x] Lección 7: ciclo de Compound Engineering y aprendizaje duradero
- [ ] Sesiones de Codex: todas las capturas que necesitan el modelo (límite de uso hasta el 2026-09-19)
- [ ] Lección 8: trabajar en GuitarAlchemist/ga
- [x] Un formato de observación para ejecuciones de modelos, skills y subagentes, y su primera observación (2026-09-26)
- [x] Tres observaciones retrospectivas registradas: los tiempos agotados de los hooks (2026-09-26), una recuperación tras una caída de wmux y la fusión anticipada de GA #740 (2026-09-27)

## QA

El software que enseña este curso es Claude Code, la CLI de Codex y, por la lección sobre MCP, el servidor MCP de GuitarAlchemist/ga — los tres dieron hallazgos. Cuatro son documentación que no coincide con el comportamiento, lo que aquí importa más que en otros sitios: un tutorial sobre agentes es sobre todo un tutorial sobre cuánto fiarse de lo que una herramienta dice de sí misma. Nada se ha reportado aguas arriba.

No hay tabla de experimentos: este diario recoge sorpresas y hallazgos de esperado-contra-obtenido, pero ninguna entrada planteó una hipótesis antes de una medición, y redactar una a partir del resultado es justo lo que esa sección existe para impedir.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| `claude -p` arranca en modo `default`, como dice la tabla de la documentación | Sigue el `defaultMode` de los ajustes del usuario. Esta máquina pone `"defaultMode": "auto"`, así que un `claude -p` al que se le pide crear un archivo lo creó sin preguntar | `~/.claude/settings.json` | Un archivo escrito sin pedir aprobación | Reproducido; la documentación y el comportamiento se contradicen [2026-09-14](#2026-09-14--sorpresas-en-claude-code) |
| `--allowedTools` restringe las herramientas disponibles | Las preaprueba. La que restringe es `--tools` | CLI de Claude Code | Dos opciones, una de las cuales hace en un script lo contrario de lo que su nombre sugiere | Reproducido, fácil de confundir [2026-09-14](#2026-09-14--sorpresas-en-claude-code) |
| `${CLAUDE_PROJECT_DIR}` en los args de `.mcp.json` también se resuelve para Claude Code | Está puesta para el servidor, no para Claude Code, así que el servidor no arranca | `.mcp.json` | `CONNECTION_CLOSED`; `${CLAUDE_PROJECT_DIR:-.}` funciona | Documentado; el modo de fallo no [2026-09-14](#2026-09-14--sorpresas-en-claude-code) |
| `AGENTS.md` se relee del disco justo después de una compactación, como dice la documentación | La copia inyectada tras la compactación era la del principio de la sesión | Claude Code 2.1.270 | Sesión iniciada a las 20:56 UTC, regla registrada a las 22:01, compactación a las 22:32, y la copia correcta llegó a las 23:06:49 — 34 minutos de retraso | Reproducido una vez, causa desconocida, no reportado [2026-09-14](#2026-09-14--sorpresas-en-claude-code) |
| Un prompt que empieza por `/` llega al modelo tal como se escribió | Git Bash lo reescribe: `claude -p "/journal-status …"` llegó como `C:/Program Files/Git/journal-status …` | Git Bash en Windows | `MSYS_NO_PATHCONV=1` lo arregla. El modelo luego sorteó el prompt deformado en lugar de avisarlo | Reproducido; es cosa del shell, no de Claude Code [2026-09-14](#2026-09-14--sorpresas-en-claude-code) |
| Un subagente que lee una ruta absoluta de Windows tiene permiso en modo `default` | El `Read` de `/C:/Users/…` de un subagente Haiku se rechazó como «a suspicious Windows path pattern that requires manual approval», dos veces, antes de que reintentara con rutas relativas | Claude Code, modo `default` | Dos rechazos y luego un rodeo que el subagente encontró solo | Reproducido [2026-09-14](#2026-09-14--sorpresas-en-claude-code) |
| Un agente sabe decir de dónde salió una de sus propias reglas | El padre le dijo al usuario que «Key takeaways» no venía de ninguna parte, cuando estaba en la definición del propio subagente — que el padre nunca lee | subagentes de Claude Code | Una atribución equivocada y segura de sí | Reproducido; un límite que vale la pena enseñar [2026-09-14](#2026-09-14--sorpresas-en-claude-code) |
| Las respuestas JSON-RPC vuelven en el orden en que se pidieron | Cinco líneas enviadas de golpe volvieron desordenadas: el id 4 antes que el id 3 | sesión MCP en crudo del curso | Arreglado esperando cada respuesta en vez de encadenarlas | Reproducido; el protocolo lo permite, el primer código del curso no [2026-09-14](#2026-09-14--el-servidor-mcp-y-sus-pruebas) |
| `codex exec` sigue aceptando `--full-auto`, como muestran casi todos los tutoriales | La 0.154.0 lo rechaza (`unexpected argument '--full-auto'`); la política de aprobación `untrusted` está retirada y `--approve-for-me` es nueva | CLI de Codex 0.154.0 | Una opción retirada, una política retirada, una opción nueva | Reproducido; `codex mcp-server` también desapareció, y su página de documentación es ya un aviso de retirada [2026-09-14](#2026-09-14--sorpresas-en-codex) |
| `codex mcp list` dice si un servidor funciona | Imprime «enabled» sin comprobar la conexión, a diferencia de `claude mcp list`, que arranca los servidores que puede | CLI de Codex 0.154.0 | Un estado que no puede fallar | Reproducido [2026-09-14](#2026-09-14--sorpresas-en-codex) |
| `GetScaleNotes` escribe las notas según la tonalidad pedida | Solo escribe con sostenidos, sea cual sea la tonalidad | `GaMcpServer/Tools/ScaleTool.cs` 50-80 | «F major» da la♯ donde lo correcto es la♭ … si♭ | Corregido upstream por [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionada el 2026-09-23, con pruebas [2026-09-14](#2026-09-14--guitaralchemistga-en-el-commit-a826864), [2026-09-24](#2026-09-24--correcciones-upstream) |
| La herramienta acepta las escrituras con bemoles que su propia documentación usa de ejemplo | Las rechaza: `Unknown root note 'Bb'` | `GaMcpServer/Tools/ScaleTool.cs` | El ejemplo de la documentación es la entrada que falla | Corregido upstream por [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionada el 2026-09-23, con pruebas [2026-09-14](#2026-09-14--guitaralchemistga-en-el-commit-a826864), [2026-09-24](#2026-09-24--correcciones-upstream) |
| Un modo que no es mayor ni menor devuelve ese modo | Todo lo que no empieza por «minor» se trata como mayor: `D dorian` devuelve re mayor | `GaMcpServer/Tools/ScaleTool.cs` | Capturado en vivo durante la lección | Corregido upstream por [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionada el 2026-09-23, con pruebas [2026-09-14](#2026-09-14--guitaralchemistga-en-el-commit-a826864), [2026-09-24](#2026-09-24--correcciones-upstream) |
| Dos herramientas del mismo servidor escriben una nota igual | `get_key_notes("Key of F")` escribe si♭ mientras que `GetScaleNotes` solo escribe con sostenidos | servidor MCP de GA | Dos respuestas a una pregunta, desde un solo servidor | Corregido upstream por [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionada el 2026-09-23, con pruebas [2026-09-14](#2026-09-14--guitaralchemistga-en-el-commit-a826864), [2026-09-24](#2026-09-24--correcciones-upstream) |
| Un error MCP se devuelve como error | Se devuelve como texto corriente | `GaMcpServer/Tools/ScaleTool.cs` | Ni `isError`, ni excepción: un cliente no puede distinguir el éxito del fallo | Reproducido, no reportado [2026-09-14](#2026-09-14--guitaralchemistga-en-el-commit-a826864) |
| El `.mcp.json` en la raíz de un repositorio se puede compartir | El de GA contiene rutas absolutas propias de una máquina | raíz del repositorio de GA | Rutas que solo funcionan en una máquina | Reproducido, no reportado [2026-09-14](#2026-09-14--guitaralchemistga-en-el-commit-a826864) |

## 2026-09-14 — Versiones e instalación

- **Claude Code**: instalador nativo, `~/.local/bin/claude`. La sesión empezó en **2.1.270**; `claude doctor` indicó después «Last update attempt: success → 2.1.271 (2026-09-14)», y las sesiones nuevas desde las 22:14 UTC aproximadamente ejecutaron **2.1.271**. La sesión en curso se queda en su versión hasta que se reinicia, así que las capturas de antes y de después de esa hora difieren en versión. Cada captura de las lecciones indica la suya.
- **CLI de Codex**: **0.154.0**, instalada con `npm install -g @openai/codex` (Node.js 24.12.0). No se probó el instalador PowerShell de la documentación.
- **.NET**: `code/agentic-coding/global.json` fija el SDK 10.0.100 con `rollForward: latestFeature`; en local eso selecciona 10.0.112, mientras que la raíz del repositorio, sin `global.json`, obtiene una preview de 11.0. La CI usa `actions/setup-dotnet` con el mismo `global.json`.
- **ModelContextProtocol** 2.2.0 y Microsoft.Extensions.Hosting 10.0.12 para el servidor; GuitarAlchemist/ga usa ModelContextProtocol 1.3.0.
- **La documentación se ha movido**: `docs.anthropic.com/en/docs/claude-code/…` redirige (301) a `code.claude.com/docs/en/…`; la documentación de Codex está en `learn.chatgpt.com/docs/…`. Ambos sitios sirven cada página en Markdown con el sufijo `.md`, que es como se comprobaron las afirmaciones de las lecciones, página a página.
- Ninguna `ANTHROPIC_API_KEY` en la máquina ni en la CI: todas las capturas usaron la suscripción.

## 2026-09-14 — Las capturas y su coste

Cada salida de agente en las lecciones es una captura, con su hora UTC. Lo que indicó `claude -p`:

| Captura | Lección | Turnos | Coste indicado |
|---|---|---|---|
| Elementos sin marcar en los diarios, 22:10 | 1 | 3 | 0,34 $ |
| Servidor MCP, `D dorian`, `Gb major`, `ladybugdb`, 22:11 | 4 | 5 | 0,36 $ |
| `${CLAUDE_PROJECT_DIR}` en `.mcp.json`, primer intento, 22:15 | 4 | 4 | 0,39 $ |
| Hook que bloquea `git push --prune`, 22:18 | 3 | 2 | |
| Escritura rechazada en modo `default`, 22:22 | 1 | 2 | |
| Skill, 22:24 y 22:25 | 3 | 6 y 2 | |
| Experimento `CLAUDE.md` / `AGENTS.md`, 22:37 | 2 | 1 cada uno | |
| Subagente `lesson-checker`, 22:48 | 3 | 4 | 0,49 $, de los cuales 0,04 $ para el subagente Haiku |
| Tres variantes de `.mcp.json`, 22:54 | 4 | 4 | 0,34 $ |

El «coste» es lo que indica la salida JSON; con una suscripción, cuenta contra los límites de uso en lugar de facturarse.

`codex exec` con la misma pregunta que la primera captura se detuvo con el error citado en la [lección 1](../01-agents-and-permissions/): el límite de uso, hasta «Sep 19th, 2026 9:42 AM». Los comandos de Codex que no llaman a un modelo funcionaron: `codex --help`, `codex exec --help`, `codex mcp add`, `codex mcp list`, `codex mcp get`, con un `CODEX_HOME` temporal.

## 2026-09-14 — Sorpresas en Claude Code

- **`claude -p` sigue el `defaultMode` de la configuración de usuario.** El `~/.claude/settings.json` de esta máquina fija `"defaultMode": "auto"`, así que un `claude -p` al que se pidió crear un archivo lo creó sin confirmación. La tabla de la documentación dice que `claude -p` empieza en `default`, pero la configuración va primero en el orden que indica. La lección 1 pasa `--permission-mode default` para la captura de un rechazo.
- **`--allowedTools` no restringe la lista de herramientas**, preaprueba; `--tools` restringe. Fácil de confundir en los scripts.
- **Git Bash reescribe un prompt que empieza por `/`.** `claude -p "/journal-status …"` llegó como `C:/Program Files/Git/journal-status …`. `MSYS_NO_PATHCONV=1` lo arregla. El modelo rodeó entonces el comando ausente leyendo él mismo `SKILL.md`.
- **Un `Read` de un subagente Haiku con la ruta `/C:/Users/…`** se rechazó como «a suspicious Windows path pattern that requires manual approval», en modo `default`, dos veces, antes de que lo reintentara con rutas relativas. Los rechazos aparecen en los `permission_denials` del agente padre.
- **El agente padre atribuyó mal una regla**: le dijo al usuario que «Key takeaways» no venía de ninguna parte, cuando estaba en la propia definición del subagente, que el padre nunca lee.
- **Los hooks de una carpeta no confiable se ejecutan en modo `-p`**, mientras que sus reglas allow se ignoran con un aviso. Documentado en [confianza del espacio de trabajo](https://code.claude.com/docs/en/hooks#workspace-trust), y merece una línea en cualquier script de «clonar y ejecutar».
- **`${CLAUDE_PROJECT_DIR}` en los args de `.mcp.json` falla sin valor por defecto** (`CONNECTION_CLOSED`), documentado: la variable se define para el servidor, no para Claude Code. `${CLAUDE_PROJECT_DIR:-.}` funciona. `claude mcp list` muestra esa entrada como `${CLAUDE_PROJECT_DIR}/server/LearnMcp.dll`, sin el `:-.`: una rareza de visualización, el servidor se conectó.
- **El AGENTS.md inyectado tras la compactación era el del inicio de la sesión.** La sesión de este curso empezó a las 20:56 UTC; la regla de Mermaid se incluyó en un commit de `AGENTS.md` a las 22:01; la sesión compactó a las 22:32. La transcripción de la sesión muestra los archivos de instrucciones inyectados tras la compactación sin la regla de Mermaid, aunque el archivo en disco la tenía y la documentación dice que el `CLAUDE.md` de la raíz del proyecto se «reinyecta desde el disco». La copia actual llegó a las 23:06:49 UTC, adjunta al siguiente mensaje entrante, como «Instruction files were re-read after the conversation was compacted; these differ from their earlier copies»: durante 34 minutos, mientras se escribían las lecciones 1 a 4, a las instrucciones en contexto les faltaba la regla (las lecciones usaron Mermaid de todos modos, a partir del resumen de la conversación). Aquí `CLAUDE.md` es solo `@AGENTS.md`: quizá la importación influya. Observado una vez, en 2.1.270, causa desconocida.
- **El propio hook de git de la máquina bloqueó mis comandos dos veces**: expresiones regulares como `push .*--delete` coincidían con texto dentro de here-documents y de datos de prueba JSON. Escribir los archivos con una herramienta de edición en lugar de un here-document de shell lo evitó. El mismo hook deja pasar `git push --prune`. Esa es la motivación del hook de la lección 3, que analiza el comando.
- **La búsqueda de herramientas está activada**: las herramientas MCP no están en el contexto del modelo al arrancar; la primera llamada de cada captura MCP es `ToolSearch`.

## 2026-09-14 — Sorpresas en Codex

- `codex mcp-server` ha desaparecido; la página de documentación que lo describía es ahora un aviso de retirada que apunta al app server experimental.
- `codex exec` 0.154.0 rechaza `--full-auto` (`unexpected argument '--full-auto'`), la política de aprobación `untrusted` está retirada, y `--approve-for-me` es nuevo. Muchos tutoriales siguen usando las opciones antiguas.
- En Windows, los comandos de los hooks se ejecutan con `%COMSPEC%` o `cmd.exe /C` ([código fuente](https://github.com/openai/codex/blob/60e35765c3e43e152bf5b382a38a0628efd70842/codex-rs/hooks/src/engine/command_runner.rs#L435-L441)): la forma documentada `$(git rev-parse --show-toplevel)` necesita un `command_windows` que la sustituya.
- Esta máquina tiene hooks tanto en `~/.codex/hooks.json` como en `~/.codex/config.toml`; cada `codex exec` avisa «prefer a single representation for this layer».
- `codex mcp add` con un `CODEX_HOME` bajo la carpeta temporal avisa de que se niega a crear alias de PATH allí, y continúa.
- `codex mcp list` muestra «enabled», sin comprobar la conexión; `claude mcp list` comprueba los servidores que puede iniciar.

## 2026-09-14 — El servidor MCP y sus pruebas

- La primera prueba raw envió cinco líneas JSON de golpe por la tubería: las respuestas volvieron fuera de orden (id 4 antes que id 3). El modo raw espera ahora cada respuesta antes de enviar la petición siguiente.
- `server/discover` sin `_meta` responde `-32602`, «requires per-request metadata declaring a supported protocol version».
- El SDK devuelve un `string[]` como texto JSON con `"` escapado como `\u0022`, y también los caracteres no ASCII escapados: `course_outline` devuelve en cambio una sola cadena, para que una raya en un título siga siendo legible.
- La consola de Windows mostraba esa raya como `-` hasta que el cliente de comprobación fijó `Console.OutputEncoding` en UTF-8; los archivos esperados son idénticos en los tres sistemas operativos.
- Un `Console.WriteLine` dentro de una herramienta rompe las sesiones raw pero **no** la salida del cliente del SDK, que se saltó la línea no JSON: el cliente del SDK es una prueba tolerante.
- Primer `dotnet run guard-git-push.cs`: unos 13 s de compilación; ejecuciones siguientes, 0,24 s desde la caché de compilación. Los registros del hook usan un timeout de 120 s.
- La ejecución de CI [34904115148](https://github.com/spareilleux/learn/actions/runs/34904115148) pasó al primer push en Linux, Windows y macOS.

## 2026-09-14 — GuitarAlchemist/ga, en el commit `a826864`

Hallazgos para el autor de ga; este curso no escribe en ga, y no se ha informado de nada upstream.

- **`GaMcpServer/Tools/ScaleTool.cs`, `GetScaleNotes`** ([líneas 50-80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/ScaleTool.cs#L50-L80)):
  - escribe solo con sostenidos: `F major` da `A#` en lugar de `Bb`;
  - la descripción del parámetro da `'Bb major'` como ejemplo, y la herramienta rechaza `Bb` («Unknown root note 'Bb'. Use sharps…»);
  - los errores se devuelven como resultados de texto corrientes, no con `isError: true` ni con una excepción;
  - todo modo que no empiece por «minor» se trata como mayor: `D dorian` devuelve D mayor;
  - `get_key_notes("Key of F")` escribe `Bb`, así que dos herramientas del mismo servidor no coinciden.
  Observado mediante una compilación local de ga el 2026-09-14 hacia las 22:57 UTC; el código fuente en `a826864` tiene la misma lógica.
- **El `.mcp.json` de la raíz de ga** contiene rutas absolutas, específicas de una máquina: solo funciona en la máquina de su autor. Rutas relativas, o `${VAR:-default}`, lo harían compartible.
- **ModelContextProtocol 1.3.0** en `GaMcpServer.csproj`, subido desde 1.1.0 porque el paquete complementario de gobernanza depende de `>= 1.3.0`; la versión estable actual es la 2.2.0, que habla la revisión 2026-07-28.
- **`Scripts/sync-agents-md.ps1`**: su ayuda dice que un aviso «do not edit» se «añade al principio», mientras que el código sustituye la línea de la nota; inofensivo, pero el comentario está desactualizado. `CLAUDE.md` nombra además la versión `2.1.126` de la extensión de Claude Code, 145 versiones de parche por detrás.

## 2026-09-20 — Tutoriales de workflow agéntico

- Versiones fijadas: skills de Matt Pocock `c55ee460`, Sandcastle `e99f832f` (paquete 0.12.0) y Compound Engineering `6be0932b` (plugin 3.27.0).
- Lecciones 5–7 añadidas en inglés, francés y español a partir de fuentes upstream primarias.
- No se usó ningún plugin, credencial ni proveedor de pago. Las ejecuciones Sandcastle y con modelo siguen siendo experimentos manuales.
- Se documentó el conflicto upstream entre la antigua configuración Sandcastle en `config.json` y las plantillas TypeScript actuales, sin decidirlo en silencio.

## 2026-09-24 — Correcciones upstream

- Las cuatro filas de `ScaleTool` están corregidas upstream por [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionada el 2026-09-23. `GetScaleNotes` escribe una letra por grado: `F major` da `F G A Bb C D E`, y `Bb major`, el ejemplo de su propia documentación, se acepta y da `Bb C D Eb F G A`. `D dorian` da `D E F G A B C`. Cada caso es una prueba del `ScaleToolTests.cs` de GA, que leí en la rama main de GA sin ejecutarlo.
- Las dos herramientas coinciden ahora. Una sesión que corregía otros hallazgos de los cursos llamó a `KeyTool.GetKeyNotes` y `ScaleTool.GetScaleNotes` para las 30 tonalidades de `Key.Items`, y escribieron las mismas notas en cada una.

## 2026-09-26 — Un formato de observación para modelos, skills y subagentes

Las notas sobre ejecuciones de agentes derivan hacia la anécdota: «Opus lo hizo más rápido», «el subagente se perdió». Una anécdota mezcla tres cosas: lo que razonó el modelo, lo que el arnés le dejó hacer y quién era dueño del trabajo. El formato de abajo las separa, para que dos observaciones puedan compararse, o declararse no comparables.

**La ficha.** Una fila por ejecución. Un campo que no se tiene se escribe *desconocido*, nunca se adivina.

| Campo | Qué va en él |
|---|---|
| Fecha, identificador de ejecución | Fecha y hora locales con su desfase; el identificador de correlación o de sesión |
| Repositorio | El SHA exacto en que cada repositorio se leyó o se cambió |
| Arnés | CLI o aplicación y su versión (`claude --version`), y el sistema operativo |
| Modelo, pedido y observado | Lo que se pidió, y lo que muestra un recibo. Un nombre de modelo mostrado por una interfaz o por el propio agente es *autodeclarado*, no un recibo |
| Skill o subagente | Nombre y versión, o un resumen criptográfico del archivo; el rol: padre, subagente o agente par |
| Tarea y contexto | La tarea en una frase; qué contexto se dio (archivos, instrucciones, memoria) |
| Permisos | El modo de permisos, y qué se permitió o se denegó |
| Hipótesis | Escrita antes de la ejecución, o marcada como *observación retrospectiva* |
| Evidencia | El comando, artefacto, registro o código de salida que un lector puede volver a abrir |
| Resultado y estado | Uno de: enviado, visible, aceptado, completado, verificado de forma independiente |
| Categoría de fallo | Razonamiento del modelo; lanzador, herramienta, autenticación, permiso o entorno; orquestación o propiedad |
| Tokens y coste | La cifra y su procedencia: factura del proveedor, estimación del arnés o *desconocido* |
| Confianza y límites | Tamaño de muestra, y lo que la ejecución no puede mostrar |
| Reproducibilidad | Lo que necesita una segunda ejecución: mismas entradas, semilla, versiones |
| Seguimiento | La próxima comprobación, con su responsable |

**Los estados no son intercambiables.**
- *Enviado*: la petición salió.
- *Visible*: el destinatario la muestra.
- *Aceptado*: el destinatario asumió la responsabilidad.
- *Completado*: dice que terminó.
- *Verificado de forma independiente*: otra persona volvió a comprobar la evidencia.

Un wrapper que sigue corriendo, una CPU ocupada o un mensaje de «terminado» no prueba ninguno de los dos últimos.

**Las categorías de fallo tampoco.**
- Un tiempo agotado por un host lento es un fallo de entorno, no del modelo.
- Una afirmación falsa hecha con todas las herramientas funcionando es un fallo de razonamiento.
- Dos agentes que escriben el mismo archivo es un fallo de propiedad, sea cual sea el modelo.

**Nada de clasificaciones a partir de anécdotas.** Tareas, presupuestos y contextos distintos no se clasifican entre sí. Una comparación justa de modelos necesita:
- tareas emparejadas con entradas fijas;
- ejecuciones o semillas repetidas donde los resultados varían;
- criterios fijados y cegados antes de las ejecuciones;
- una comprobación independiente de cada resultado;
- el coste informado junto a la calidad.

Esa comparación está *propuesta, no realizada*.

**Primera observación: esta delegación, 2026-09-26.** Un coordinador (Codex) entregó a una sesión de Claude Code cuatro instrucciones de curso y un diagnóstico, correlación `test-quality-courses-20260926` y sus vecinas. Solo se registra la evidencia de la que dispone esta sesión.

| Campo | Observación |
|---|---|
| Arnés | Claude Code 2.1.282 (`claude --version`, 13:39 EDT). La comprobación previa del coordinador también vio 2.1.282 instalada, mientras el registro de npm ofrecía 2.1.283. No se hizo ninguna actualización ni ningún reinicio |
| Modelo | Solo autodeclarado: la interfaz de la sesión mostraba «Opus 5.5 (1M context)», razonamiento medio, y su prompt de sistema nombra el mismo modelo. No se comprobó ningún recibo del proveedor |
| Roles | Codex como coordinador; esta sesión como único escritor en el worktree de learn; un subagente de solo lectura sobre un clon fijado de AutoHarness; un agente par (Augment) para una auditoría estática de solo lectura de Abide, escrita en la carpeta de traspaso compartida |
| Bus compartido | El coordinador informó que las llamadas status e inbox del bus de mensajes compartido devolvían «Transport closed». Nada muestra que el bus aceptara una reclamación; la coordinación pasó por archivos en una carpeta compartida |
| Hipótesis | Escritas antes de medir solo para el laboratorio test-quality ([lección 6 de repository-dogfooding](../../repository-dogfooding-lab/06-mutation-property-testing/)); todo lo demás aquí es *observación retrospectiva* |
| Resultados, por estado | Laboratorio medido y diario escrito: completado, no verificado de forma independiente. La nota de supervisión del coordinador dice que volvió a analizar los informes de mutación y encontró las mismas cifras; es una nueva comprobación de la evidencia registrada, no una nueva ejecución. Diagnóstico de los hooks: completado; el coordinador calificó su causa raíz de hipótesis |
| Fallos vistos, por categoría | Razonamiento, detectado antes de medir: un generador de entradas malformadas que podía construir una entrada válida. Uso de herramientas, detectado por una comprobación de hash: una edición por script convirtió en silencio un archivo prerregistrado a CRLF, y se revirtió. Lanzador y entorno: un here-document del shell no se pudo analizar, y no se escribió nada; en el host, arrancar un `bash` vacío tardaba unos 2,8 s durante el diagnóstico de los hooks. Orquestación: nada observado; se mantuvo un único escritor por repositorio |
| Tokens y coste | *Desconocido*. No se leyó ninguna factura ni recibo de uso. No se llamó a ninguna API de pago |
| Límites | Una sesión, un día, un coordinador; no es muestra de nada |

## 2026-09-26 — Tres hooks que agotaron su tiempo, y un host lento

*Observación retrospectiva: no se escribió ninguna hipótesis antes de estas mediciones.* La evidencia es local: un arnés y sus registros, guardados en la carpeta de traspaso del coordinador, no en este repositorio.

**El síntoma.** En cada prompt, tres hooks `UserPromptSubmit` agotaban su tiempo y su salida se descartaba. Los tres pertenecen a un mismo plugin de terceros, [claude-octopus](https://github.com/nyldn/claude-octopus) 9.56.1, instalado en el commit [`cb2677b`](https://github.com/nyldn/claude-octopus/tree/cb2677b2bd442bcc501489cc6110ab54fb14e701). Su [`hooks.json`](https://github.com/nyldn/claude-octopus/blob/cb2677b2bd442bcc501489cc6110ab54fb14e701/hooks/hooks.json#L300-L325) da 5 s a dos de ellos y 8 s al tercero. Los scripts se leyeron antes de ejecutar nada:
- son inyectores de contexto consultivos, no controles de seguridad;
- cada uno empieza leyendo stdin con `timeout 3 cat` ([`done-criteria.sh`, línea 26](https://github.com/nyldn/claude-octopus/blob/cb2677b2bd442bcc501489cc6110ab54fb14e701/hooks/done-criteria.sh#L26));
- el de GitHub solo actúa dentro del propio repositorio del plugin.

**La medición.** Un arnés ejecutó cada hook fuera de Claude Code:
- `env -i`, un `HOME` temporal vacío, un prompt sintético, los umbrales originales;
- una ejecución de cada uno, el 2026-09-26 hacia las 13:00 EDT, en Git Bash sobre Windows 11;
- ninguna llamada de red y ningún proveedor lanzado, y el `HOME` temporal seguía vacío después.

| Comando | Salida | Tiempo real |
|---|---|---|
| `bash -c true` | 0 | 2829 ms |
| `bash -lc true` | 0 | 25 457 ms |
| `timeout 3 cat </dev/null` | 0 | 7031 ms |
| `python3 -c pass` | 0 | 10 357 ms |
| `python -c pass` | 0 | 1539 ms |
| `done-criteria.sh` (5 s) | 124, tiempo agotado | 9546 ms, 0 bytes de salida |
| `user-prompt-submit.sh` (5 s) | 124, tiempo agotado | 11 690 ms, 0 bytes de salida |
| `github-work-queue-watch.sh` (8 s) | 124, tiempo agotado | 15 298 ms, 0 bytes de salida |

**Lo que esto muestra.**
- El síntoma se reproduce fuera de Claude Code.
- No es la lógica de los hooks lo que gasta el presupuesto. El camino más barato por `done-criteria.sh` es un `bash` nuevo y luego `timeout 3 cat` sobre una entrada que ya llegó a su final. Esos dos pasos solos cuestan 2,8 s + 7,0 s, más que los 5 s completos.
- En ese host, en ese momento, *lanzar cualquier proceso* tardaba segundos.

**Lo que no muestra.** La causa es *muy probablemente* una latencia de creación de procesos en todo el host, y no está aislada. Los candidatos son:
- la carga: había unos 40 procesos `bash`, 65 `node` y 13 `claude` en marcha;
- el análisis antivirus de cada lanzamiento;
- un perfil de inicio de sesión costoso, si los hooks se lanzan a través de uno. No he comprobado qué modo de shell usa Claude Code.

Los límites: mediciones únicas, ninguna comparación en un momento tranquilo, y los tres hooks lanzados uno tras otro cuando Claude Code los lanza juntos. La diferencia entre `python3` y `python` descansa en una medición de cada uno, con una carga variable. En los términos del [formato de observación de arriba](#2026-09-26--un-formato-de-observación-para-modelos-skills-y-subagentes), es un fallo de **entorno**, no del modelo.

**No se cambió nada.** El plugin tiene interruptores (`OCTO_DONE_CRITERIA=off`, `OCTOPUS_GITHUB_WORK_QUEUE=off`); activarlos es un cambio de configuración que necesita la aprobación del usuario. Subir los tiempos límite ocultaría la latencia y añadiría segundos a cada prompt.

Una idea de parche upstream sigue siendo un borrador, sin probar y sin enviar:
- leer stdin con un comando interno de bash;
- hacer una sola llamada a `jq` en lugar de varias a `python3`;
- salir antes de lanzar `git` fuera del repositorio del plugin.

## 2026-09-27 — Tras una caída de wmux: reanudado no es entregado

*Observación retrospectiva.* La evidencia es la nota de recuperación del coordinador, guardada localmente, y lo que esta sesión vio de sí misma. Se omiten los identificadores de sesiones y de superficies.

- **Qué pasó.** El multiplexor de terminal que aloja los paneles de los agentes (wmux) se cayó. Con la autorización del usuario, el coordinador:
  - relanzó la versión 1.1.1, que se cerró durante su propia actualización sin crear ningún agente;
  - vio después la 2.13.1, que el usuario instaló, responder y restaurar sus espacios de trabajo;
  - reanudó seis carriles (IX, Learn, TARS, Demerzel, Gaia, Music) por sus conversaciones históricas exactas.
  No hubo reinicio, borrado de datos, elusión de permisos, edición de repositorios, reinicio de servidores ni llamada de pago.
- **«Reanudado» es un estado de la interfaz, no una entrega.** La nota de recuperación registra, para cada carril, lo que se observó: un resumen reanudado, un diff anterior, un prompt. Su propia regla es que *«agent labels/running alone are not delivery evidence»* (una etiqueta de agente o un agente en marcha no prueban una entrega). En los estados del [formato de observación](#2026-09-26--un-formato-de-observación-para-modelos-skills-y-subagentes), un panel reanudado está *visible*. Pasa a *aceptado* cuando el carril acusa recibo de una tarea, y a *completado* solo con un recibo.
- **Lo que abarató la recuperación.** Cada carril había escrito su estado en archivos antes de la caída, no solo en su conversación. Esos archivos nombraban el checkout exacto, la cabeza y las rutas sin commit, y daban la acción siguiente.
  - Esta sesión de Learn se reanudó desde uno de esos archivos. Después esperó la autoridad de publicación, como decía el archivo, en lugar de actuar según su resumen.
  - El carril IX encontró de la misma manera una modificación de workflow sin commit, cuyo commit y push había cortado la caída. Preguntó al usuario antes de publicarla.
  - Un resumen de conversación no basta para esto. Dice lo que se pretendía, no qué comando se ejecutó de verdad.
- **Los identificadores cambiaron.** Los identificadores de espacios de trabajo y de superficies eran nuevos tras el reinicio, así que cualquier monitor tenía que releer la correspondencia antes de enviar teclas a un panel. Es un fallo de orquestación en potencia, y aquí se evitó.

## 2026-09-27 — GA #740 fusionada antes de su revisión independiente

*Observación retrospectiva*, registrada con el formato de observación. Los hechos públicos se leyeron con `gh`. El resto viene de recibos locales —los del carril IX, del coordinador y de la revisión posterior a la fusión— que este curso ha leído sin reejecutarlos.

| Campo | Observación |
|---|---|
| Repositorio | [GuitarAlchemist/ga#740](https://github.com/GuitarAlchemist/ga/pull/740), *editor de pipelines: tema del sistema, comprobación de tipos de argumentos, pipeline de ejemplo de GA*. Fusionada el 2026-09-27T02:50:43Z como [`d67d04b`](https://github.com/GuitarAlchemist/ga/commit/d67d04bdb04742ba338518e28197e6035cb80e90). La cabeza fusionada, [`984192e`](https://github.com/GuitarAlchemist/ga/commit/984192e970746dbed9e56255616360f56d9eed62), se fijó con `--match-head-commit` |
| Roles | La sesión del agente IX era la autora, y fusionó con las credenciales del propietario del repositorio. Codex debía ser el integrador, tras una revisión independiente de esa cabeza exacta |
| Qué salió mal | El turno del usuario «pousse tout ce qui est green» («publica todo lo que esté en verde») llegó primero a la sesión autora, que lo leyó como autoridad para fusionar las PR en verde. Comprobó los comentarios del bot de Codex (ningún P0/P1 abierto en esa cabeza) y una CI en verde, y fusionó. La instrucción de que Codex revisara la cabeza antes de cualquier fusión llegó después de la fusión |
| Categoría de fallo | **Orquestación o propiedad**: dos instrucciones con autoridad distinta llegaron a un mismo agente en el orden equivocado. Ninguna herramienta falló y ningún paso de razonamiento era erróneo con lo que el agente había visto, pero la barrera no se aplicó |
| Evidencia en el momento de la fusión | Pública: todos los checks de GitHub de la PR pasan. Informado por Codex tras la fusión: sincronización del tema generado comprobada, y tres suites de pruebas dirigidas, 35 de 35 superadas. No es una cobertura completa de HTTP, navegador, build o backend |
| Revisión posterior a la fusión | De solo lectura, por una sesión distinta, con el recibo guardado localmente; este curso no la reejecutó. Confirmó, cada vez con un caso de fallo reproducido: las rutas de propuestas que añade la PR admiten más que su límite cuando los cuerpos llegan tarde (29 pendientes para 20, mientras que los envíos en serie lo respetan); clics simultáneos superan el límite de gasto del asesor (8 llamadas admitidas donde solo cabía una, API simulada, sin gasto; las llamadas en serie lo respetan); un cuerpo mal formado recibe un «invalid JSON body» engañoso; una línea corrupta del registro lanza una excepción fuera de cualquier `try`. Según el código fuente: una propuesta sin revisión base se trata como actual. La descripción de la PR no menciona ni la API de pago del asesor ni las rutas de propuestas en las que pueden escribir los agentes. Las barreras manuales Accept y Run se mantienen, y la revisión no indica ningún revert |
| Estado | La fusión está *completada*, y la revisión también. Una corrección de los cinco hallazgos sobre el código está *enviada* a Codex: una rama local, sin commit, con primero una prueba que falla para cada uno (5 fallos antes de la corrección, y 42 de 42 superadas después, en 4 archivos). Codex reejecutó esos 4 archivos: 42 de 42. La corrección no está integrada, y quedan su revisión completa, una comprobación en un navegador y un build completo. Así que todavía no hay ningún defecto cerrado en `main` |
| Respuesta | Ningún revert. La integración sigue en manos de Codex. Los residuos que la propia corrección nombra siguen abiertos: dos servidores de desarrollo que comparten un registro aún pueden competir, la comprobación de gasto usa una estimación y no una cota superior garantizada, y los cuerpos de petición por encima del límite de tamaño se siguen guardando en memoria, como antes de la PR |
| Seguimiento | La decisión de Codex sobre la corrección, luego su PR y su CI, y después el estado de esta entrada |

## Por verificar

- Aplicar el formato de observación a una segunda delegación independiente, y que alguien distinto de su autor compruebe una ficha contra su evidencia.
- Los comandos de instalación de la lección 1 en Linux, WSL y macOS, para ambos agentes, y el instalador PowerShell de Codex.
- Una sesión de Codex que responda a la primera pregunta de la lección 1, y el mismo experimento `AGENTS.md` que en la lección 2.
- Hooks de Codex: si el ejemplo `config.toml` de la lección 3 funciona en Windows con `command_windows`, y si su ruta relativa funciona cuando Codex arranca en un subdirectorio; el flujo de confianza en `/hooks`.
- Skills de Codex: si `$ARGUMENTS`, `argument-hint` y `allowed-tools` significan algo para Codex, y la invocación de `$journal-status`.
- Agente personalizado de Codex `lesson_checker`: la carga, y `sandbox_mode = "read-only"` en la práctica.
- MCP en Codex: una sesión que llame a `scale_notes` y `course_outline`; el directorio de trabajo contra el que se resuelven los `args` relativos sin `cwd`; `default_tools_approval_mode = "approve"`.
- Si `project_doc_fallback_filenames` se acepta en el `.codex/config.toml` de un proyecto.
- Si Codex expande las importaciones `@path` en `AGENTS.md` (su documentación no las menciona).
- Si Claude Code y Codex toleran una línea no JSON en la stdout de un servidor, como hace el cliente del SDK.
- Por qué el `AGENTS.md` releído llegó a la sesión solo con el siguiente mensaje entrante tras la compactación: repetir con un `CLAUDE.md` simple, sin importación, en 2.1.271.
- `codex exec -o`: si el archivo lo escribe la CLI fuera del sandbox en modo `read-only`.
- Una captura de instalación desechable para cada workflow, sin instalar suites solapadas en el mismo fixture.
- Una ejecución Sandcastle con Docker, rama explícita, una iteración, sin merge y evidencia de pruebas controlada por el host.
- Los tiempos agotados de los hooks: tres ejecuciones de cada hook en un momento tranquilo y tres bajo carga, los tres hooks lanzados juntos como los lanza Claude Code, y si Claude Code lanza los hooks a través de un shell de inicio de sesión.
- GA #740: si la corrección de los cinco hallazgos de la revisión sobre el código llega a `main` con sus pruebas de regresión, y una comprobación del editor en un navegador, que ni la revisión ni la corrección hicieron.
