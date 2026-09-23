---
title: SlashForge, comandos de workflow para Claude Code — Misión
description: Leer, instalar y desmontar SlashForge, un paquete npm que da a Claude Code un workflow de desarrollo de diez fases con puertas, escrito enteramente en Markdown — lo que escribe su instalador, cómo un archivo se convierte en un slash command, y dónde el kit y Claude Code no coinciden sobre el mismo archivo.
sidebar:
  label: Misión
  order: 0
---

:::note[Versión estudiada, y lo que la CI puede y no puede probar]
[SlashForge](https://github.com/rajdeepratan/SlashForge) **4.4.3**, tag [`v4.4.3`](https://github.com/rajdeepratan/SlashForge/tree/bd75a4f770bb2e323551c05fab0d3f326c72ae98) (el instalador es idéntico en `main` el 2026-09-22), con [Node.js](https://nodejs.org/) 24 y [Claude Code](https://code.claude.com/docs/en/overview), en Windows 11, en septiembre de 2026. El código de este curso está en [`code/slashforge`](https://github.com/spareilleux/learn/tree/main/code/slashforge), y [`.github/workflows/slashforge-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/slashforge-examples.yml) lo ejecuta en Linux, Windows y macOS.

Lo que prueba la CI es **el instalador**: lo ejecuta en un directorio personal desechable y compara todo lo que imprime y escribe. Lo que hacen los comandos una vez que Claude Code los ejecuta depende del modelo y cuesta tokens — decenas de miles por ejecución, según la propia estimación de SlashForge —, así que esas lecciones son capturas, fechadas, y nunca se presentan como reproducibles.
:::

## Por qué aprendo esto

El [curso de programación agéntica](../agentic-coding/) enseñó las piezas que te da Claude Code: instrucciones de proyecto, comandos, skills, subagentes, hooks. No mostró cómo es un workflow completo construido con esas piezas. SlashForge es uno: cuatro comandos y nueve skills que llevan una petición por la recogida de requisitos, el plan, la confirmación, la rama, la implementación, la verificación, la revisión, la pull request, el feedback y la limpieza, y se detienen en cuatro *puertas* (gates) donde nada continúa hasta que respondes.

Es un buen espécimen por dos razones. Es lo bastante pequeño para leerlo — un instalador de 676 líneas y veintinueve plantillas Markdown — y es honesto sobre su coste: su README dice que es *"deliberately heavy"* y da presupuestos de tokens para cada comando. Y todo su comportamiento vive en texto plano que puedes abrir, lo que significa que puedes contrastar cada afirmación que hace con el archivo que se supone que la implementa.

Eso es lo que hace este curso. Instala SlashForge donde no puede hacer daño, lee lo que escribió y compara entre sí la documentación, el instalador y las propias reglas de Claude Code. No siempre coinciden: la [tabla de QA](journal/#qa) del diario lista dónde.

## Para quién es este curso

Escribes C# o Java, has usado Claude Code — basta el [curso de programación agéntica](../agentic-coding/) hasta su [lección 3](../agentic-coding/03-hooks-skills-subagents/) — y quieres saber qué añade un kit de workflow con opiniones fuertes, cuánto cuesta y qué instala en tu máquina antes de ejecutarlo. No necesitas saber JavaScript: el instalador se lee, no se escribe.

## Un kit de workflow, en términos de .NET y Java

| | .NET / Java | SlashForge |
|---|---|---|
| Distribución | un paquete NuGet o Maven | un paquete [npm](https://docs.npmjs.com/), ejecutado una vez con `npx` |
| Lo que instala | ensamblados, plantillas (`dotnet new install`) | archivos Markdown bajo `~/.claude/` o `./.claude/` |
| La parte ejecutable | código compilado | un instalador de 676 líneas; el resto es texto que lee Claude Code |
| Cómo se invoca | un verbo de CLI, un comando del IDE | un slash command: `/slashforge:code` |
| Barreras de protección | políticas de rama, revisiones obligatorias | cuatro puertas escritas en las instrucciones — al modelo se le dice que se detenga |
| Configuración | `appsettings.json`, `pom.xml` | el `CLAUDE.md` de tu repositorio y `.claude/rules/` |

Las dos últimas filas son las que hay que tener presentes. Una política de rama la impone el servidor; una puerta de SlashForge es una frase que se le pide al modelo que obedezca. El [curso de programación agéntica](../agentic-coding/03-hooks-skills-subagents/) traza la misma línea entre instrucciones y hooks.

## Al final de este curso, sabré

- instalar SlashForge de forma global o en un solo repositorio sin tocar el resto de `~/.claude/`, y quitarlo limpiamente;
- decir, para cada archivo que escribe, qué hace Claude Code con él y por qué importa su ruta;
- leer un archivo de comando y seguirlo hasta las guías en las que delega;
- ejecutar `/slashforge:setup`, `/slashforge:code` y su modo `-quick`, `/slashforge:investigate` y `/slashforge:review-pr` en un repositorio real, y medir lo que cuestan;
- decidir, para un cambio dado, si la ceremonia vale la pena.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [Lo que escribe el instalador](01-what-the-installer-writes/) | `dotnet tool install`, `dotnet new install`, un paquete que deja archivos |
| 2 | [Dentro de los archivos: comandos, skills, guías](02-inside-the-files/) | los parámetros de plantilla, el enrutamiento por carpeta, un validador más estricto que el runtime |
| 3 | `/slashforge:setup` frente a `/init`, en un repositorio real (próximamente) | una plantilla de proyecto, una checklist de incorporación |
| 4 | `/slashforge:code`: diez fases y cuatro puertas | las políticas de rama, una plantilla de pull request |
| 5 | `-quick`, `/slashforge:investigate` y `/slashforge:review-pr` | un proceso de hotfix, un informe de bug, una revisión de código |
| 6 | Hacerlo tuyo: reglas, comandos de verificación, una instalación de equipo | `.editorconfig`, una configuración de compilación compartida |
| — | [Diario](journal/) | |

## Recursos

- [SlashForge en GitHub](https://github.com/rajdeepratan/SlashForge), su [sitio de documentación](https://www.rajdeepratan.com/slashforge/) y su [changelog](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/CHANGELOG.md)
- [El paquete `slashforge` en npm](https://www.npmjs.com/package/slashforge)
- Claude Code: [skills y comandos personalizados](https://code.claude.com/docs/en/skills), y [el directorio `.claude`](https://code.claude.com/docs/en/claude-directory)
- [superpowers](https://github.com/obra/superpowers), la biblioteca de skills de la que están adaptadas las nueve skills de SlashForge, bajo licencia MIT
- [Agent Skills](https://agentskills.io/), el formato abierto de los archivos de skill
