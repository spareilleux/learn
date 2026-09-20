---
title: Programación agéntica con Claude Code y Codex — Misión
description: Aprende cómo funcionan los agentes de programación, a partir de lo que ya sabe un desarrollador C# o Java — el bucle de herramientas, los permisos, las instrucciones de proyecto, los hooks, las skills, los subagentes y MCP — en el repositorio de este sitio y en GuitarAlchemist/ga, con Claude Code y la CLI de Codex.
sidebar:
  label: Misión
  order: 0
---

:::note[Versiones estudiadas, y lo que la CI puede y no puede probar]
[Claude Code](https://code.claude.com/docs/en/overview) **2.1.270**, actualizado a 2.1.271 mientras escribía, y la [CLI de Codex](https://learn.chatgpt.com/docs/codex/cli) **0.154.0**, en Windows 11, en septiembre de 2026. El código de este curso está en [`code/agentic-coding`](https://github.com/spareilleux/learn/tree/main/code/agentic-coding): un hook, un servidor MCP en C# y los archivos de configuración de ambos agentes. [`.github/workflows/agentic-coding-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/agentic-coding-examples.yml) lo prueba todo en Linux, Windows y macOS, **sin agente y sin clave de API**: el hook lee llamadas a herramientas en JSON, el servidor lo maneja un cliente MCP, los archivos de configuración se analizan.

Lo que responde un agente no se puede probar así: depende del modelo, del día y de la suscripción. Cada sesión de agente citada en estas lecciones es una captura, marcada con su fecha y hora en UTC, y nunca se presenta como reproducible.
:::

## Por qué aprendo esto

La mayor parte de este sitio se escribió con un agente de programación. Describo una tarea, el agente lee archivos, ejecuta comandos, edita, ejecuta las pruebas y vuelve con un diff y un resumen. Cuando funciona, es más rápido que hacerlo yo mismo; cuando no, el error puede ser sutil: una prueba que no ejecutó, una regla que olvidó, una rama que hizo push.

Quiero entender lo que pasa entre mi petición y el diff: qué archivos lee el agente, qué tiene permitido ejecutar, qué recuerda y cómo poner barreras de protección que no dependan de la buena voluntad del agente. Después, usarlo en [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), una solución .NET de 111 proyectos, y más adelante en Gaia e IX.

## Para quién es este curso

Escribes C# o Java profesionalmente. Conoces tu IDE, Git, una herramienta de compilación y un framework de pruebas. Puede que hayas usado el autocompletado de código (IntelliSense, las sugerencias en línea de GitHub Copilot), pero **nunca has dejado que un agente ejecute comandos en tu repositorio**. No necesitas saber nada de modelos de lenguaje.

## Los agentes de programación en una tabla

| | Autocompletado del IDE | Claude Code | CLI de Codex |
|---|---|---|---|
| Se ejecuta | dentro del editor, en cada pulsación | en una terminal, como sesión | en una terminal, como sesión |
| Actúa sobre | la línea que estás escribiendo | todo el repositorio: lee, edita, ejecuta comandos | lo mismo |
| Pregunta antes de actuar | nunca actúa | modos y reglas de permisos | modos de sandbox y políticas de aprobación |
| Instrucciones de proyecto | ninguna | `CLAUDE.md` | `AGENTS.md` |
| Barreras de protección deterministas | ninguna | hooks | hooks, sandbox |
| Herramientas adicionales | extensiones del editor | servidores MCP, skills, subagentes | servidores MCP, skills, subagentes |
| No interactivo | no | `claude -p` | `codex exec` |

Fuentes: [cómo funciona Claude Code](https://code.claude.com/docs/en/how-claude-code-works), [CLI de Codex](https://learn.chatgpt.com/docs/codex/cli), [aprobaciones y seguridad de Codex](https://learn.chatgpt.com/docs/agent-approvals-security).

## Los repositorios

- **Este sitio**, [spareilleux/learn](https://github.com/spareilleux/learn): un sitio Astro con cursos en tres idiomas, una CI que ejecuta el código de cada curso y un [`AGENTS.md`](https://github.com/spareilleux/learn/blob/main/AGENTS.md) que ha crecido con cada error que un agente cometió aquí. Varias sesiones de agente trabajan en él al mismo tiempo.
- **[GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga)**, fijado en el commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) (2026-09-14): una aplicación de teoría musical en C# y F#, con un `CLAUDE.md`, un `AGENTS.md`, skills y subagentes de proyecto, y [`GaMcpServer`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer), un servidor MCP que expone su teoría musical a los agentes. Este curso lee ga; nunca escribe en él.

## Al final de este curso, sabré

- explicar el bucle entre el modelo y las herramientas, y lo que un agente puede hacer sin preguntar;
- instalar Claude Code y la CLI de Codex en Windows, Linux y macOS, y ejecutarlos de forma interactiva y desde un script;
- escribir instrucciones de proyecto que lean ambos agentes, y saber lo que no pueden imponer;
- bloquear un comando peligroso con un hook, empaquetar un procedimiento como skill y delegar en un subagente;
- escribir un servidor MCP en C#, probarlo sin agente y conectarlo a ambos agentes;
- usar estas herramientas en una solución .NET real, y revisar lo que hizo el agente.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [Agentes, herramientas y permisos](01-agents-and-permissions/) | las refactorizaciones del IDE, lanzar una compilación desde la terminal |
| 2 | [Contexto de proyecto: `CLAUDE.md`, `AGENTS.md`, memoria y compactación](02-project-context/) | `README.md`, `.editorconfig`, una página de wiki que nadie lee |
| 3 | [Hooks, skills y subagentes](03-hooks-skills-subagents/) | los hooks de Git, los analizadores, los scripts de `tools/` |
| 4 | [MCP: un servidor C# para ambos agentes](04-mcp/) | un servicio JSON-RPC o gRPC, la inyección de dependencias |
| 5 | [Skills de Matt Pocock: métodos de ingeniería ejecutables](05-matt-pocock-skills/) | runbooks, TDD, división en issues |
| 6 | [Sandcastle: una ejecución aislada de un agente](06-sandcastle/) | contenedores, ramas, aislamiento de procesos |
| 7 | [Compound Engineering: cerrar el ciclo de aprendizaje](07-compound-engineering/) | pipelines de entrega, postmortems, documentación reutilizable |
| 8 | Trabajar en GuitarAlchemist/ga: planificar, compilar, probar, revisar (próximamente) | la revisión de una pull request |
| 9 | Agentes en la CI, y varios agentes en un mismo repositorio | GitHub Actions, la protección de ramas |
| 10 | Gaia e IX: agentes que ejecutan otros agentes | orquestación, colas |
| — | [Diario](journal/) | |

## Recursos

- [Documentación de Claude Code](https://code.claude.com/docs/en/overview), también disponible en Markdown ([índice](https://code.claude.com/docs/llms.txt))
- [Documentación de Codex](https://learn.chatgpt.com/docs/codex/cli), y el [código fuente de Codex](https://github.com/openai/codex)
- [Model Context Protocol](https://modelcontextprotocol.io/), su [especificación](https://modelcontextprotocol.io/specification/2026-07-28/architecture) y el [SDK de C#](https://github.com/modelcontextprotocol/csharp-sdk)
- [Agent Skills](https://agentskills.io/), el formato abierto de los archivos `SKILL.md` que leen ambos agentes
