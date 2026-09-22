---
title: "Benchmark del coste en tokens: batch, gate y rechazo"
description: Medir si Jev reduce el trabajo de proveedores costosos sin ocultar pérdida de calidad, reintentos o coste desplazado.
sidebar:
  order: 4
---

Menos tokens solo sirven si la tarea sigue teniendo éxito. Esta lección mide el **coste por resultado aceptado**, no un porcentaje bruto atractivo.

## La hipótesis

> En un corpus etiquetado fijo, una decisión Jev tipada puede reducir al menos un 50 % la entrada de un proveedor costoso, conservando los criterios de aceptación y sin falsos `supported`.

Es una hipótesis, no una promesa. Se rechaza si baja la calidad, si la revisión humana elimina el ahorro o si el trabajo solo se desplaza a otro proveedor.

## El corpus y los tres modos

[`benchmark-corpus.json`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/benchmark-corpus.json) contiene 12 casos saneados de GA, Gaia y Demerzel, etiquetados `supported`, `contradicted` o `insufficient`. Un caso incluye un intento de prompt injection: sigue siendo evidencia, nunca instrucción.

```text
python jev_benchmark.py plan
python jev_benchmark.py mock
python -W error::ResourceWarning -m unittest -v
```

- `plan` no usa la red y muestra llamadas y presupuesto;
- `mock` valida el scoring con una fixture explícitamente no-Jev;
- `live` es un experimento autorizado aparte: un batch más 12 llamadas individuales, `jev-1.13.0` fijado y cero reintentos.

El plan local mide 13 llamadas y un límite superior de 17.663 tokens calculado desde bytes UTF-8. Es conservador, no un conteo del tokenizer del proveedor. Con el precio comprobado el 20 de septiembre de 2026, el límite estimado de entrada es 0,000741846 $ y el techo local 0,0021 $.

## Comparar categorías, no tokenizers distintos

| Medida | Motivo |
|---|---|
| Tokens de entrada y salida Jev | Uso y coste directos |
| Entrada, caché y salida del proveedor posterior | Trabajo evitado o añadido |
| Resultados aceptados | Denominador de la eficiencia real |
| Falsos soportes y calibración | Barreras contra respuestas baratas y erróneas |
| Revisiones, reintentos, latencia p50 y p95 | Coste operativo desplazado |

El resultado principal es dólares por resultado aceptado bajo el mismo quality gate. Reducir un 50 % con un falso soporte es un fracaso en una ruta sensible a autoridad.

## Protocolo A/B en vivo

El modo live exige `TYPESAFE_API_KEY` y `JEV_BENCHMARK_APPROVED=YES`. Reserva la evidencia antes de llamar, la actualiza tras cada respuesta y no reintenta automáticamente.

```text
python jev_benchmark.py live --out evidence/jev-live.json
```

Si la calibración pasa, el siguiente experimento será un gate posterior: comparar un modelo costoso fijo en todos los casos con el mismo modelo invocado solo cuando Jev no resuelva el caso con seguridad. Ahí podrá confirmarse o refutarse un ahorro real del 50 %.

## Fuentes primarias

- [Modelos Jev y precios actuales](https://docs.typesafe.ai/models)
- [Preguntas paralelas](https://docs.typesafe.ai/cookbooks/parallel_questions)
- [Cascada de desarrollo de software](https://docs.typesafe.ai/cookbooks/sde_cascade)
- [Categorías de tokens OpenAI](https://platform.openai.com/docs/api-reference/responses/object#responses/object-usage)
- [Prompt caching de Anthropic](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
