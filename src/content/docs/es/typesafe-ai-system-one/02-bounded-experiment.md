---
title: "2. Un experimento reproducible y de coste acotado"
description: Ejecutar primero la fixture determinista, revisar las pruebas del contrato y la política, y preparar una llamada opcional a Jev con presupuesto local duro, condiciones de parada y registro de evidencia.
sidebar:
  order: 2
---

El experimento parte de una pregunta falsable:

> ¿Puede una recomendación probabilística tipada entrar en una gate al estilo Gaia sin permitir que el proveedor cree autoridad ni coste ilimitado?

La hipótesis es estrecha: la misma política determinista debe aceptar una respuesta cerrada válida, rechazar una opción inventada, rechazar probabilidades mal formadas y mandar a revisión humana cuando falte autoridad explícita. Una llamada en vivo solo mediría después el comportamiento del modelo.

## Fase A — base sin conexión

```bash
cd code/typesafe-ai-system-one
python typesafe_lab.py mock
python -m unittest -v
```

Medido localmente el 20 de septiembre de 2026 con Python 3.14.2:

```text
{
  "mode": "mock",
  "model": "mock-jev-course/1",
  "decision": "human_review:no_explicit_authority",
  "request_sha256": "67c1ee4bcd36b497f60872c0715d435b364c3b7743ad06f9be543071af044a1b"
}

Ran 14 tests in 0.078s
OK
```

Las catorce pruebas solo demuestran propiedades locales: la fixture valida, la ausencia de autoridad impide el despacho, un Choice desconocido se rechaza, las probabilidades y el Score son coherentes, el modelo queda fijado y la evidencia no se sobrescribe. No demuestran que TypeSafe produjera la fixture, que los umbrales estén calibrados ni que la opción conocida sea correcta.

## Fase B — sonda opcional de una llamada

No pegues la clave en un argumento. Define `TYPESAFE_API_KEY` con el mecanismo de secretos de tu sistema y ejecuta:

```bash
python typesafe_lab.py live --out live-result.json
```

El script:

- se niega antes de la red si falta la variable;
- construye una sola solicitud para `jev-1.13.0`;
- usa el número de bytes UTF-8 como estimación local deliberadamente amplia de tokens;
- se niega por encima de 2.500 tokens estimados o **0,000105 $** al precio oficial de 0,042 $/Mtok;
- envía exactamente una solicitud con timeout de 20 segundos;
- rechaza redirecciones para mantener el bearer token ligado al origen API configurado;
- no reintenta automáticamente tras 429, 529, timeout o error de red;
- nunca imprime ni escribe el encabezado de autorización;
- valida la respuesta y exige el modelo fijado exacto antes de enrutar;
- exige autoridad verificada por código local de confianza, nunca por la respuesta Noul del modelo;
- registra fecha, modelo concreto, uso, digest, coste estimado y decisión, pero no la respuesta completa del proveedor.

La estimación por bytes favorece un límite local más seguro sobre la precisión; sigue siendo una barrera, no una factura ni una prueba del tokenizer. El coste observado debe usar `usage.input_tokens` y el precio oficial vigente.

:::caution[Sonda en vivo no ejecutada]
La sonda queda **por verificar**. No se llamó a la API al escribir el curso, así que no hay latencia, respuesta, tokens, coste ni calibración medidos.
:::

## Condiciones de parada

Detente si falta la clave o aparece en una salida, se supera el techo, el contrato es inválido, llega 401/422/429/529 o un estado inesperado, cambia el modelo concreto, la decisión podría autorizar/fusionar/desplegar/publicar/eliminar, o la entrada contiene secretos o datos no aprobados.

## Tabla de evidencia pendiente

| Campo | Evidencia | Estado |
|---|---|---|
| identidad | SHA-256 de la solicitud | solo mock |
| modelo | `model` concreto | vivo no probado |
| uso y coste | tokens × precio actual | vivo no probado |
| latencia | `elapsed_ms` | vivo no probado |
| forma | validador correcto | mock correcto; vivo no probado |
| decisión | valor exacto | mock rechazó el despacho |
| calidad | resultado contra etiqueta previa | no probado |

Una llamada correcta es conectividad, no evaluación. Después hace falta un corpus versionado con casos claros, fronterizos y contraejemplos, puntuado antes de mover umbrales.

## Ejercicios

1. ¿Por qué fijar `jev-1.13.0` en vez de `jev-latest`?

<details><summary>Solución</summary>

Porque un alias puede cambiar sin modificar el código. Umbrales y mediciones pertenecen al modelo concreto.

</details>

2. El SDK puede reintentar, pero esta sonda no. ¿Es un error?

<details><summary>Solución</summary>

No. El presupuesto es exactamente una llamada. Un reintento ocultaría el coste y el número de observaciones. En producción, intentos y coste máximo deben ser explícitos.

</details>

## Fuentes

- TypeSafe AI: [API](https://docs.typesafe.ai/api), [modelos y precios](https://docs.typesafe.ai/models), [inicio rápido](https://docs.typesafe.ai/introduction/quickstart)
- Código: [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one)
