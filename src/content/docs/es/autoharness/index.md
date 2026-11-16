---
title: AutoHarness, skills que se escriben solas para Claude Code — Misión
description: Evaluar AutoHarness, un plugin de Claude Code que convierte las sesiones terminadas en skills y poda las que dejan de usarse — leído en un commit fijado, probado con fixtures prerregistradas en un laboratorio aislado sin instalarlo ni llamar a un modelo, y juzgado por la evidencia y no por su README.
sidebar:
  label: Misión
  order: 0
---

:::note[Versión estudiada, y qué se ejecutó]
[AutoHarness](https://github.com/tigerless-labs/autoharness) en el commit [`ca39a72`](https://github.com/tigerless-labs/autoharness/tree/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b) (2026-09-25), licencia MIT, con Python 3.14.2 en Windows 11, en septiembre de 2026. El código de este curso está en [`code/autoharness`](https://github.com/spareilleux/learn/tree/main/code/autoharness).

Lo que se ejecutó es la parte de AutoHarness que no necesita un modelo: el promotor, la cola de intenciones, el almacén de skills y el redactor de secretos, importados desde un clon en subprocesos aislados. **Nunca se instaló**: no se cambió ningún plugin, hook, carpeta de skills ni ajuste MCP de Claude Code, y no se llamó a ningún modelo. Todo lo que escribiría el *reflector* (un modelo) queda fuera del alcance de este curso, y cada lección lo dice donde importa. Las ejecuciones son solo en Windows por ahora; Linux y macOS están *por verificar*.
:::

:::caution[Veredicto en `ca39a72`: no adoptar]
Dos fixtures prerregistradas rompen la promesa central del proyecto, según la cual las skills escritas a mano nunca se tocan; una sola línea truncada detiene la promoción para siempre; y el redactor deja pasar los secretos escritos en JSON. Los defectos son pequeños y locales, y la evaluación enumera lo que cambiaría el veredicto: [`evaluation.md`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md).
:::

## Por qué aprendo esto

El [curso de programación agéntica](../agentic-coding/) presentó las piezas que te da Claude Code: hooks, skills, subagentes, servidores MCP. Escribes una skill, haces commit, y sigue siendo lo que escribiste. AutoHarness te quita la pluma. Observa tus sesiones mediante hooks, pide a un modelo en segundo plano que destile lo ocurrido en skills, las deja en `.claude/skills/` sin preguntar y, más tarde, archiva las que dejan de usarse. Su README promete que *«stays clean on its own»* (se mantiene limpio solo), tocando *«only the skills it wrote itself»* (solo las skills que escribió él mismo).

Una herramienta que escribe instrucciones que tu próxima sesión *«MUST consider»* (debe considerar) merece más escrutinio que una que solo lee. Y cada una de sus promesas se puede probar: la parte que decide qué llega al disco es Python corriente, que funciona sin modelo. Así que este curso hace lo que el [curso de SlashForge](../slashforge/) hizo con un instalador, un paso más allá: lee el código fijado, escribe cómo se vería cada promesa si fuera falsa y luego ejecuta el código frente a esas predicciones, en un laboratorio donde nada puede alcanzar el `~/.claude` real.

## Para quién es este curso

Escribes C# o Java, usas Claude Code y sabes qué son un hook y una skill —el [curso de programación agéntica](../agentic-coding/) hasta su [lección 3](../agentic-coding/03-hooks-skills-subagents/) basta— y te preguntas si dejar que una herramienta reescriba por ti las instrucciones de tu agente. No hace falta conocer bien Python: el código del laboratorio es corto y cada línea de salida se explica.

## Una capa de skills que se modifica a sí misma, en términos de .NET y Java

| | .NET / Java | AutoHarness |
|---|---|---|
| Distribución | un paquete NuGet o Maven | un [plugin de Claude Code](https://code.claude.com/docs/en/plugins): hooks, dos agentes, un servidor MCP, código Python |
| Cuándo se ejecuta | cuando lo llamas | en cada llamada a una herramienta, en cada turno y en cada inicio de sesión, mediante [hooks](https://code.claude.com/docs/en/hooks) |
| Qué produce | assemblies que publicas | [skills](https://code.claude.com/docs/en/skills) en Markdown que cargan las sesiones siguientes |
| Quién escribe el resultado | tú, revisado en una pull request | un `claude -p` en segundo plano con Haiku, y luego un *promotor* determinista que lo deja en disco — sin paso de revisión |
| Propiedad | el autor de un archivo en `git blame` | un `.sidecar.json` junto a la skill que dice `"created_by": "agent"` |
| Limpieza | borras el código muerto | las skills sin uso durante bastante tiempo se archivan automáticamente |

La quinta fila es donde este curso pasa la mayor parte del tiempo. Un simple archivo JSON decide qué considera AutoHarness como propio, y la pregunta es qué ocurre alrededor de esa decisión.

## Al final de este curso, sabré

- decir qué eventos hacen que AutoHarness capture, reflexione, promueva, inyecte y archive, y cuáles de ellos implican un modelo;
- ejecutar la parte de una herramienta que no necesita modelo en subprocesos aislados, con un directorio personal desechable y un entorno construido desde cero;
- prerregistrar una fixture —pregunta, hipótesis, control, falsador, huella de las entradas— antes de ejecutarla, y conservar lo que salga aunque me quite la razón;
- distinguir lo que afirma un README, lo que muestra el código, lo que reproduce una fixture y lo que solo un modelo en vivo podría decir;
- decidir, con evidencia, si dejar que una herramienta así toque un proyecto real.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [Un laboratorio de fixtures: seis promesas probadas sin instalar](01-fixture-lab/) | una prueba unitaria con un doble, una prueba que primero debe fallar, un entorno de pruebas limpio |
| 2 | *Prevista:* el bucle y sus fronteras de autoridad — hooks, reflector, promotor, y lo que un repositorio clonado puede encolar | un job en segundo plano, una cuenta de servicio, un pipeline de despliegue sin paso de aprobación |
| 3 | *Prevista:* por qué el uso no es calidad — contadores, madurez y capacidad | la cobertura de código como métrica, un feature flag que nadie retira |
| 4 | *Prevista:* caídas, concurrencia e historial — qué sobrevive a una promoción interrumpida | una cola «al menos una vez», una actualización perdida, una copia de seguridad que sobrescribe la anterior |
| 5 | *Prevista:* la evaluación y una lista de comprobación de adopción | una prueba de concepto, una revisión go/no-go |
| — | [Diario](journal/) | |

Las lecciones 2 a 5 están previstas, no escritas. Sus hipótesis ya figuran en la evaluación (§2, *read in the source, not run*), y cada una necesitará sus propias fixtures prerregistradas antes de afirmar nada.

## Recursos

- [AutoHarness en GitHub](https://github.com/tigerless-labs/autoharness), y su [README en el commit fijado](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/README.md)
- Claude Code: [hooks](https://code.claude.com/docs/en/hooks), [skills](https://code.claude.com/docs/en/skills), [subagentes](https://code.claude.com/docs/en/sub-agents) y [plugins](https://code.claude.com/docs/en/plugins)
- [HAL](https://arxiv.org/abs/2510.11977), el artículo que el README cita para su línea *42% → 78% on CORE-Bench* — un resultado de ese artículo, no de AutoHarness
- La [prerregistración](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/preregistration.md) y la [evaluación](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md) de este curso
