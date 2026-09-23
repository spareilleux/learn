---
title: Repository Dogfooding Lab — Misión
description: Convertir cursos y observaciones en experimentos falsables, incubación con evidencia y adopción medida en GA, Gaia, Demerzel, IX, TARS y Learn.
sidebar:
  label: Misión
  order: 0
---

:::caution[Evidencia actual]
Los tracer bullets siguen siendo locales y sin conexión: un registro JSON con cinco oportunidades, cinco matrices generadas y una prueba sintética del límite de autoridad Jev × Petri. Aún no se afirma integración en producción, ahorro Jev real, mejora arquitectónica ni beneficio de RabbitMQ.
:::

## Misión

Este curso convierte el aprendizaje en un ciclo de investigación:

```text
observación → hipótesis falsable → baseline → experimento acotado
            → revisión adversaria → incubación → integración o rechazo
```

Avanza dos disciplinas:

- **ingeniería clásica:** arquitectura, fiabilidad, pruebas, observabilidad, rendimiento y mantenimiento;
- **IA agéntica:** coste por resultado aceptado, calibración, escalado, reintentos, tokens por proveedor y autonomía segura.

Terminar un curso no es éxito. El resultado es adopción con pruebas o un rechazo útil que evita desperdicio.

## Qué vas a construir

[`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) contiene el registro machine-readable. Una herramienta Python valida promociones y genera cobertura curso × repositorios, puntuación, estado de promoción, resultados y evidencia, y calidad del método del curso.

## Plan

| # | Lección | Resultado |
|---|---|---|
| 1 | [Matrices de oportunidades](01-opportunity-matrices/) | Priorizar sin convertir una puntuación en autoridad |
| 2 | [Experimento y artifact chain](02-experiment-artifact-chain/) | Generar evidencia reproducible desde hipótesis hasta veredicto |
| 3 | [Dogfood del método](03-course-method-dogfood/) | Mejorar ejemplos, diarios, paridad de idiomas y adopción |
| 4 | [Incubar, integrar, rechazar](04-incubate-integrate-reject/) | Promover solo candidatos medidos y reversibles |
| 5 | [Límite de autoridad Jev × Petri](05-jev-petri-authority/) | Mostrar por qué un consejo confiado no concede ningún efecto |
| — | [Diario](journal/) | Experimentos detallados, rechazos y próximos gates |

```text
cd code/repository-dogfooding-lab
python dogfood.py write
python dogfood.py check
python -m unittest -v
```
