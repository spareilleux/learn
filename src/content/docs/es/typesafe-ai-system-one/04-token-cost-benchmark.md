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

- `plan` no usa la red y muestra el número de llamadas y un proxy de coste basado en bytes de solicitud;
- `mock` valida el scoring con una fixture explícitamente no-Jev;
- `live` es un experimento autorizado aparte: un batch más 12 llamadas de una pregunta sobre **el mismo estado de 12 casos**, `jev-1.13.0` fijado y cero reintentos. Mantener el estado constante aísla el efecto del batching; el ensayo de calidad con estado por caso es distinto.

El plan local corregido mide 13 llamadas: 8.034 bytes UTF-8 para el lote y 38.284 para las llamadas individuales, 46.318 bytes en total. Multiplicarlos por la tarifa comprobada el 22 de septiembre de 2026 da un **proxy de coste de 0,001945356 $**, por debajo del límite local de proxy de 0,0021 $. Los bytes no son tokens facturados y se desconoce el encuadre del servidor: **esto no garantiza un techo real en dólares**. Comprueba los controles de gasto de la cuenta y solicita autorización separada antes de una ejecución en vivo.

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

El modo live exige `TYPESAFE_API_KEY` y `JEV_BENCHMARK_APPROVED=YES`. Reserva la evidencia antes de llamar, la actualiza tras cada respuesta y no reintenta automáticamente. Su guardia local basada en un proxy **no** es un límite de gasto impuesto por el proveedor.

```text
python jev_benchmark.py live --out evidence/jev-live.json
```

Si la calibración pasa, el siguiente experimento será un gate posterior: comparar un modelo costoso fijo en todos los casos con el mismo modelo invocado solo cuando Jev no resuelva el caso con seguridad. Ahí podrá confirmarse o refutarse un ahorro real del 50 %.

Antes de llamar a un proveedor de pago, prueba el [test sin conexión del gate de confianza](../05-confidence-gate-stress/): una puntuación alta no equivale a autoridad.

## Fuentes primarias

- [Modelos Jev y precios actuales](https://docs.typesafe.ai/models)
- [Preguntas paralelas](https://docs.typesafe.ai/cookbooks/parallel_questions)
- [Limitaciones documentadas de Jev 1.13](https://docs.typesafe.ai/model-jaggedness/jev-1.13)
- [Cascada de desarrollo de software](https://docs.typesafe.ai/cookbooks/sde_cascade)
- [Categorías de tokens OpenAI](https://platform.openai.com/docs/api-reference/responses/object#responses/object-usage)
- [Prompt caching de Anthropic](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
