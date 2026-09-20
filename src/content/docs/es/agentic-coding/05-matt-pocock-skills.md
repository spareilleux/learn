---
title: "5. Skills de Matt Pocock: métodos de ingeniería ejecutables"
description: Instalar una sola distribución de los skills de AI Hero, configurarla para un repositorio y convertir una idea en un tracer bullet con evidencia explícita.
sidebar:
  order: 5
---

Un `SKILL.md` es un procedimiento que un agente carga cuando una tarea coincide. Es más específico que `AGENTS.md`: las instrucciones del proyecto se aplican a cada turno, mientras un skill describe un trabajo repetible como investigación, TDD o revisión de código.

Esta lección usa los [skills de Matt Pocock](https://github.com/mattpocock/skills/tree/c55ee46073ed923f86ce59a5eb3b6d895095d1b7), fijados en `c55ee460` el 20 de septiembre de 2026, y la metodología descrita por [AI Hero](https://www.aihero.dev/skills).

## Instala una sola distribución

El proyecto upstream ofrece dos modelos de instalación. Instalar ambos duplica los mismos skills.

```bash
# Claude Code: plugin administrado y de solo lectura
claude plugins install mattpocock-skills

# Codex y otros agentes compatibles: archivos editables en el proyecto
npx skills@latest add mattpocock/skills
```

Para los skills copiados, actualiza después con `npx skills update`. Luego invoca `setup-matt-pocock-skills` una vez en el repositorio. Este skill inspecciona el gestor de issues, las etiquetas de triage y la organización de documentos de dominio, propone cambios y pregunta antes de escribir. Revisa la propuesta: no es un instalador determinista.

## El flujo principal

```mermaid
flowchart LR
    A[Idea ambigua] --> B[grill-with-docs]
    B --> C[to-spec]
    C --> D[to-tickets]
    D --> E[tdd o implement]
    E --> F[code-review]
```

- `grill-with-docs` aclara requisitos y registra vocabulario de dominio o ADR.
- `to-spec` convierte la conversación acordada en una especificación sin repetir la entrevista.
- `to-tickets` produce tracer bullets verificables de forma independiente y sus dependencias.
- `tdd` acuerda una seam pública, escribe una prueba roja y después la implementación mínima que la vuelve verde.
- `code-review` comprueba por separado el mismo diff contra las normas del repositorio y la especificación.

Un tracer bullet es una rebanada vertical fina que atraviesa todas las capas necesarias. No es una tarea horizontal como «construir toda la capa de datos». Debe revelar pronto los errores de integración y terminar con evidencia observable.

## Ejercicio acotado

Elige una funcionalidad inocua en un repositorio desechable.

1. Escribe el resultado visible para el usuario en una frase.
2. Ejecuta `grill-with-docs` y responde solo las preguntas que cambian el diseño.
3. Inspecciona la spec antes de aceptarla.
4. Rechaza cualquier ticket que no pueda verificarse solo o que cubra una sola capa.
5. Implementa un tracer bullet con una seam de prueba.
6. Revisa el diff fijado contra las normas y la spec.

Detente después de una rebanada. Registra el commit, el comando de prueba y la incertidumbre restante. Un turno de agente terminado no demuestra que el resultado deseado funcione.

## Cuando el trabajo supera una ventana de contexto

Usa `wayfinder` para mapear decisiones, no como sinónimo de un gran plan de implementación. Sus tickets resuelven incógnitas mediante investigación, prototipo, grilling o una tarea acotada. El mapa termina cuando la ruta está clara, no cuando enumera toda función imaginable.

## Fallos frecuentes

- instalar a la vez el plugin administrado y los skills copiados;
- tratar un artículo o alias recordado como contrato de ejecución en vez de leer el `SKILL.md` instalado;
- producir tickets horizontales que posponen la integración;
- dejar que un skill amplíe silenciosamente la autoridad para push, merge, gastar dinero o contactar sistemas externos.

La autoridad específica del repositorio sigue viniendo del usuario y del host. Un skill cambia el procedimiento, no los permisos.

Continúa con [Sandcastle](../06-sandcastle/) para ejecutar un agente dentro de un límite explícito.

