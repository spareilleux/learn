---
title: "La IA de GA: OPTIC-K, ML, agentes y chatbot — Misión"
description: El lado de aprendizaje automático y de agentes de Guitar Alchemist para desarrolladores C# — el embedding OPTIC-K, el índice de voicings y su búsqueda, el enrutamiento y los agentes del chatbot, y lo que el chatbot debe llegar a ser, cada parte ejecutada sin conexión contra el propio código de GA.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada tabla de salida de las lecciones procede de [`code/ga-ai`](https://github.com/spareilleux/learn/tree/main/code/ga-ai), un programa de consola .NET 10 que referencia directamente tres proyectos de Guitar Alchemist: `GA.Business.ML`, la herramienta de línea de comandos que escribe el índice de voicings, y el host del chatbot `GaChatbot.Api`. GA se clona en el commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). El programa no necesita clave de API, ni GPU, ni servidor de modelos: construye él mismo un índice pequeño y arranca el chatbot en su propio proceso, con la dirección del modelo apuntando a un puerto cerrado. [`.github/workflows/ga-ai-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ga-ai-examples.yml) lo ejecuta en Linux, Windows y macOS y compara la salida de cada lección con los archivos de `expected/`. Las salidas se capturaron en septiembre de 2026.
:::

## Por qué aprendo esto

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) tiene un chatbot para guitarristas. Detrás hay una descripción de 240 números de cada forma de acorde de guitarra, llamada OPTIC-K, un índice de 313.047 de esas descripciones, un enrutador que decide qué parte del código responde a una pregunta, y un puñado de agentes que llaman a un modelo de lenguaje. La documentación que lo rodea es extensa y en parte está desactualizada, y el código cambia cada semana.

Quiero saber qué pasa de verdad: qué números recibe un acorde, por qué dos acordes salen parecidos, qué contiene el archivo del índice y qué hace el chatbot con una pregunta cuando no hay ningún modelo accesible. La forma de averiguarlo es llamar a las propias clases de GA desde un programa, imprimir lo que devuelven y compararlo con lo que dicen los comentarios y los documentos. Cuando los dos no coinciden, la diferencia va al [diario](journal/).

## Para quién es este curso

Escribes C#. Conoces `float[]`, LINQ, la inyección de dependencias y ASP.NET Core lo bastante como para leer un `Program.cs`. No necesitas saber nada de aprendizaje automático: el curso usa tres ideas, cada una explicada donde aparece por primera vez.

1. **Un embedding** (vector de incrustación) es un array de números de longitud fija que describe un objeto, de modo que objetos parecidos reciben arrays parecidos.
2. **La similitud del coseno** mide cuánto apuntan dos de esos arrays en la misma dirección: 1 para la misma dirección, 0 si no tienen nada en común.
3. **La búsqueda de vecinos más cercanos** devuelve los arrays almacenados más próximos a un array de consulta.

Otros tres cursos de este sitio cubren el trasfondo, y este enlaza con ellos en lugar de repetirlos:

- [Teoría musical para Guitar Alchemist](../music-theory-ga/): clases de altura, voicings, vectores interválicos y clases de conjuntos, el vocabulario que codifica OPTIC-K;
- [Aprendizaje automático, aplicado en IX](../machine-learning-ix/): variables, distancias, vecinos más cercanos y agrupamiento, escritos a mano;
- [Programación agéntica con Claude Code y Codex](../agentic-coding/): el bucle de herramientas, los hooks, las skills y los servidores MCP, desde el lado de un desarrollador que usa agentes.

## Al terminar este curso, sabré

- dibujar la pila de IA de GA: qué proyecto calcula los embeddings, cuál escribe el índice, cuál enruta un mensaje de chat, y qué hacen ix, Demerzel y TARS a su alrededor;
- leer un vector OPTIC-K partición por partición, calcular a mano la similitud ponderada de dos voicings y decir a qué es invariante el vector y a qué no;
- abrir un archivo de índice OPTK, explicar su cabecera y predecir qué devuelve una búsqueda y por qué;
- seguir un mensaje de chat a través de los hooks, las guardas deterministas, el enrutador de intenciones y los agentes de GA, y explicar por qué algunas preguntas funcionan sin modelo y otras fallan;
- distinguir, en la IA de GA, lo que funciona hoy, lo que se está construyendo y lo que solo está planeado.

## Plan

| # | Lección | En GA | Si escribes C# |
|---|---|---|---|
| 1 | [El mapa](01-the-map/) | las cinco capas, la cadena del índice, el host del chatbot, los repositorios hermanos | leer un contenedor de DI, `WebApplicationFactory` |
| 2 | [Embeddings OPTIC-K](02-optic-k-embeddings/) | `EmbeddingSchema`, `MusicalEmbeddingGenerator`, `VoicingAnalyzer` | records posicionales, `TensorPrimitives` |
| 3 | [El índice y la búsqueda](03-index-and-search/) | `OptickIndexWriter`, `OptickIndexReader`, `OptickSearchStrategy`, `MusicalQueryEncoder` | formatos binarios, archivos proyectados en memoria, montículos top-k |
| 4 | [El chatbot y sus agentes](04-chatbot-and-agents/) | `ProductionOrchestrator`, `SemanticIntentRouter`, `SemanticRouter`, skills, hooks | servicios hospedados, respaldos, probar un host dentro del proceso |
| — | [Diario](journal/) | | |

## Requisitos previos

- El [SDK de .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) y [Git](https://git-scm.com/downloads). En Windows, ejecuta los scripts del curso desde Git Bash.
- Unos 20 MB de disco para el clon parcial de GA, y alrededor de 1,1 GB una vez compilados los proyectos de GA y el programa del curso.
- Una conexión de red solo para la primera ejecución, para clonar GA y restaurar los paquetes NuGet. Después, todo funciona sin conexión.
- No hace falta guitarra, pero las formas de acorde de la lección 2 son las primeras que aprende un guitarrista.

## Recursos

- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) en `a826864`, en particular su [`CLAUDE.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md), los [documentos del esquema OPTIC-K](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Documentation/Schema) y la [hoja de ruta del chatbot](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/docs/plans/2026-05-07-chatbot-roadmap.md).
- Clifton Callender, Ian Quinn y Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://doi.org/10.1126/science.1153021), *Science* 320, 2008: el artículo que dio nombre a las equivalencias OPTIC.
- [Pruebas de integración en ASP.NET Core](https://learn.microsoft.com/aspnet/core/test/integration-tests), para `WebApplicationFactory`, y [Microsoft.Extensions.AI](https://learn.microsoft.com/dotnet/ai/microsoft-extensions-ai), las abstracciones con las que el chatbot de GA llama a los modelos.
