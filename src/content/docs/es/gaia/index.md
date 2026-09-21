---
title: Gaia — Misión
description: Gaia es un bus de coordinación duradero y una fábrica de software con evidencia — seis verbos sin privilegios, registro de solo anexión, exact replay de continuidad y recibos cuya procedencia se declara por lección.
sidebar:
  label: Misión
  order: 0
---

:::note[Revisión estudiada, y lo que se mide aquí]
Las lecciones 1–5 estudian Gaia en el commit [`d68e900`](https://github.com/GuitarAlchemist/gaia/tree/d68e90099ae2a6fbbec9d428617bfcd02095aac0) (2026-09-13), entonces cabeza de `main`, en Windows 11 con [Node.js](https://nodejs.org/en) v24.12.0. La lección 6 estudia por separado un candidato aislado de la issue 76 el 20 de septiembre con Node 26.8.1 fijado. Ese candidato no estaba en `main`, fusionado ni publicado al medirlo. Gaia tiene **cero dependencias en tiempo de ejecución**, así que los comandos parten de worktrees limpios sin `npm install`.

Cada salida de las lecciones 1–5 se produjo sobre `d68e900`; cada cifra de la issue 76 en la lección 6 está marcada como evidencia de worktree candidato. **Ninguna lección de este curso lanza un modelo de pago.** El único comando que lo hace — `factory:agent`, que gasta un turno real de Claude y un turno real de Codex — se describe a partir de su código, de su documento de diseño y del esquema de su recibo, y está marcado *por verificar* allí donde no lo he ejecutado.
:::

## Por qué aprendo esto

Ahora escribo la mayor parte de mi código con un agente de programación. El [curso de programación agéntica](../agentic-coding/) trata de un agente en un repositorio: el bucle de herramientas, los permisos, `CLAUDE.md`, los hooks, MCP. Este curso trata del problema que aparece justo después, y que ninguna cantidad de ingeniería de prompts resuelve.

Dos sesiones de agentes, y luego cuatro, trabajan sobre el mismo conjunto de repositorios. No pueden verse entre sí. Cada una termina e informa de su éxito. Y yo no tengo forma de distinguir estas tres frases:

- «He implementado el cambio y las pruebas pasan.»
- «He implementado el cambio, no he ejecutado nada, y la frase anterior es lo que produce un modelo cuando termina una tarea.»
- «Otra sesión cambió ese archivo mientras yo trabajaba, y mi diff es contra un árbol que ya no existe.»

Las tres llegan como el mismo párrafo seguro de sí mismo. El mensaje de fin de un agente es **prosa**, y la prosa no es evidencia. Gaia es mi intento de construir la capa que hace comprobable la diferencia: una coordinación duradera, y resultados que llevan recibos que otra persona puede reproducir o rechazar.

## Lo que Gaia intenta conseguir

El mapa de arquitectura de Gaia enuncia el objetivo en una frase: *Gaia coordina la entrega de software que aporta evidencias manteniendo separadas la observación, la aceptación y la autoridad.*

Esa frase carga con mucho, así que aquí está desglosada en las cuatro afirmaciones sobre las que se construye este curso.

**1. La coordinación y la autoridad son cosas distintas, y no deben viajar juntas.** Un mensaje que dice «por favor, fusiona esto» tiene que poder llegar a otro agente sin poder nunca *provocar* una fusión. En Gaia eso no es una comprobación de permisos que podría eludirse — los verbos que podrían aprobar, fusionar, hacer push o desplegar **no existen**. La lección 2 imprime toda la superficie de herramientas y luego muestra un mensaje que pide autoridad para fusionar, entregado y denegado en el mismo instante.

**2. La frescura, la calidad, la aceptación y la autoridad son cuatro ejes independientes.** Un artefacto fresco puede ser erróneo. Un artefacto de alta calidad puede estar obsoleto. Un artefacto aceptado puede no conceder ninguna autoridad. La mayoría de las herramientas para agentes reducen todo esto a un número o a una marca verde; Gaia los mantiene separados a propósito, y se niega por completo a informar de un único escalar de «confianza».

**3. La evidencia es lo que otro actor puede reproducir, no lo que afirma quien la produce.** Cada cambio de estado escribe un recibo que vincula las entradas exactas, los digests del contenido, las condiciones previas y la autoridad realmente gastada. La lección 4 ejecuta el trazador de la fábrica y lee el recibo que produce — incluidas las partes que dicen lo que el recibo **no** demuestra.

**4. Un límite sin ninguna medida detrás es una preferencia, no un límite.** Gaia admite cuatro carriles activos por espacio de trabajo. No porque cuatro sea un número redondo, sino porque cuatro es el número más grande que alguien ha ejercitado realmente de extremo a extremo. La lección 5 lee esa escalera de evidencias, y los mensajes de rechazo que nombran lo que aún no está demostrado.

El modo de fallo al que apuntan las cuatro es el mismo: **un sistema que produce una respuesta tranquilizadora donde debería producir un rechazo.** Gaia está cerrado ante fallos — un tiempo de espera de un cerrojo, un registro truncado, una revisión obsoleta o una discordancia de identidad no escriben nada y lo dicen, en lugar de dejar un resultado parcial que parece correcto.

## Para quién es este curso

Escribes C# o Java profesionalmente, y has usado un agente de programación lo suficiente como para haberte quemado alguna vez — un cambio que no pediste, una prueba que nunca se ejecutó, un «hecho» que no lo estaba. No necesitas saber Node.js: el código fuente de Gaia son módulos ES sencillos, y este curso lo cita en lugar de pedirte que lo escribas.

El [curso de programación agéntica](../agentic-coding/) ayuda, pero no es obligatorio. Cuando un concepto viene de allí — el bucle de herramientas, MCP, los modos de permisos — este curso enlaza a esa lección en lugar de repetirla.

## El vocabulario de Gaia en una tabla

Aquí las palabras importan más de lo habitual, porque todo el diseño consiste en mantenerlas separadas. Del mapa de arquitectura:

| Concepto | Qué es | Qué **no** es |
|---|---|---|
| Claim (reclamación) | reserva o notifica trabajo observado | permiso para hacer nada |
| Intent (intención) | la mutación propuesta exacta, vinculada a una identidad, una generación, una política y una revisión | un efecto |
| Effect (efecto) | un intento acotado de un único propietario con nombre | algo que un agente pueda iniciar pidiéndolo |
| Receipt (recibo) | condiciones previas, resultado, revisión de la evidencia, autoridad realmente gastada | prueba de que el resultado es correcto |
| Delivery (entrega) | aceptado para su entrega | leído, aceptado o completado |
| Acknowledgement (acuse de recibo) | recepción de un mensaje | acuerdo, aprobación o finalización |
| Handoff (traspaso) | transferencia de trabajo y de contexto | transferencia de privilegios |
| Lane (carril) | una superficie de ejecución | autoridad, o prueba de trabajo útil |

Si solo lees una parte de esa tabla, lee las tres últimas filas. *Entregado*, *acusado su recibo* y *traspasado* son las tres palabras que la orquestación de agentes usa normalmente para decir «ya está resuelto» — y en Gaia las tres están definidas explícitamente para no significar eso.

## Al final de este curso, sabré

- explicar qué es una fábrica que aporta evidencias, y qué pregunta responde que una marca verde de CI no responde;
- poner en marcha el bus, registrar varios actores y leer el registro solo de anexión que producen;
- decir exactamente qué pueden y qué no pueden hacer los seis verbos, y *demostrar* el rechazo en lugar de afirmarlo;
- reproducir un registro, verificarlo y distinguir los tres códigos de salida — rechazado, cerrado ante fallos y correcto;
- leer un recibo de la fábrica y decir qué demuestra y qué deja como residuo declarado;
- justificar el límite de cuatro carriles a partir de su evidencia, y decir qué permitiría subirlo.
- explicar cómo un sucesor acotado continúa trabajo revisado sin duplicar el wake ni heredar autoridad.

## Plan

| # | Lección | Lo que ya conoces |
|---|---|---|
| 1 | [El problema: lo que vale un «hecho»](01-the-problem/) | una revisión de código, una batería de pruebas inestable |
| 2 | [Seis verbos, y la autoridad que falta a propósito](02-six-verbs/) | una cola de mensajes, una ACL |
| 3 | [El registro de eventos: solo de anexión, reproducido, cerrado ante fallos](03-event-log-and-replay/) | el event sourcing, un write-ahead log |
| 4 | [La fábrica: candidatos, revisores y recibos](04-factory-and-receipts/) | una pull request, un artefacto de build |
| 5 | [Límites, evidencias y el ecosistema](05-limits-and-ecosystem/) | la planificación de capacidad, una decisión de integración |
| 6 | [Continuidad y artifact chain](06-continuity-and-artifact-chain/) | idempotencia, write-ahead log, contratos entre repositorios |
| — | [Diario](journal/) | |

## Requisitos previos

- [Node.js](https://nodejs.org/en). En la revisión estudiada, Gaia fija una versión exacta: `.node-version` y `engines.node` de `package.json` dicen ambos `26.8.1`. Nada lo impone cuando invocas `node` directamente, y todo lo de este curso se ejecutó con v24.12.0 sin ninguna advertencia ni fallo — pero ejecutarlo con la versión fijada está *por verificar*.
- [Git](https://git-scm.com/), para los worktrees enlazados que usa la lección 4.
- Un terminal. Gaia no tiene ningún listener de red, ninguna ejecución remota ni ningún transporte de shell — nada de lo que hay aquí abre un puerto.

```bash
git clone https://github.com/GuitarAlchemist/gaia
cd gaia
node scripts/gaia-interagent.mjs doctor
```

## Recursos

- [GuitarAlchemist/gaia](https://github.com/GuitarAlchemist/gaia) — el repositorio. `README.md` es el documento de producto, `ARCHITECTURE.md` el mapa de fronteras de referencia, y `docs/` contiene los registros de diseño y de operación.
- [Principios de ingeniería e investigación](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/engineering-and-research-principles.md) — la doctrina que lee la lección 1, y el único documento que hay que leer antes de proponer un cambio a Gaia.
- [Escala y carriles](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/scale-and-lanes.md) — la escalera de evidencias que hay detrás del número cuatro.
- [Model Context Protocol](https://modelcontextprotocol.io/) — el protocolo que habla el bus sobre stdio, tratado en la [lección 4 de programación agéntica](../agentic-coding/04-mcp/).
- David L. Parnas, [On the Criteria To Be Used in Decomposing Systems into Modules](https://dl.acm.org/doi/10.1145/361598.361623), y Jerome H. Saltzer y Michael D. Schroeder, [The Protection of Information in Computer Systems](https://www.mit.edu/~Saltzer/publications/protection/index.html) — los dos artículos que citan los principios de Gaia para la profundidad de los módulos y para el mínimo privilegio.
