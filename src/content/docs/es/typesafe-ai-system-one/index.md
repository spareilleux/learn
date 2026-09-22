---
title: TypeSafe AI System One y Jev — Misión
description: Componer decisiones probabilísticas tipadas con Jev, validarlas sin conexión, ejecutar una sonda opcional con coste acotado y encontrar usos útiles pero sin autoridad en Gaia, GA, Demerzel, IX y TARS.
sidebar:
  label: Misión
  order: 0
---

:::caution[Qué se probó y qué no]
Este curso se basa en la [documentación oficial de TypeSafe AI](https://docs.typesafe.ai/introduction), su [referencia de API](https://docs.typesafe.ai/api), la [página de modelos](https://docs.typesafe.ai/models) y el [anuncio de Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev), consultados el 20 de septiembre de 2026. El laboratorio sin conexión de [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) se ejecutó localmente con Python 3.14.2: **19 pruebas pasaron**, la ruta mock rechazó el despacho porque faltaba autoridad explícita y un plan de benchmark de 12 casos terminó sin acceso de red.

No se leyó ninguna credencial, no se abrió la consola y no se llamó a la API de TypeSafe. Todo resultado en vivo, latencia, número de tokens, afirmación de calibración sobre nuestros datos y beneficio específico para un repositorio queda **por verificar**.
:::

## Por qué estudio esto

Los agentes de programación producen texto, planes y parches. Nuestros repositorios también contienen decisiones pequeñas, repetidas y consumidas por software: clasificar un candidato de Gaia, puntuar una búsqueda de GA, señalar un registro de gobernanza de Demerzel, enrutar un experimento de IX o desambiguar una gramática de TARS. Un LLM puede responder en JSON, pero el programa todavía debe rechazar valores inventados, medir incertidumbre y mantener la autoridad fuera de la prosa.

[Jev](https://docs.typesafe.ai/introduction) usa una interfaz más estrecha: estado, preguntas tipadas y respuestas cerradas. El modelo elige entre valores que definimos; nuestro código conserva umbrales, composición y efectos. La forma es más fácil de validar, pero no vuelve correcta la decisión por sí sola.

## La tesis de seguridad

> Un modelo estima; el código determinista valida, controla y actúa.

- un `Choice` válido todavía puede elegir mal;
- una confianza alta no es autoridad;
- un alias móvil puede cambiar sin un cambio de código;
- un precio bajo también puede abaratar y multiplicar una mala decisión;
- una respuesta del proveedor nunca debe crear un grant de Gaia, fusionar una PR o modificar gobernanza.

## Qué vas a construir

1. **Primero el mock:** reproducir una respuesta guardada, validar formas y distribuciones cerradas y aplicar la política real sin red ni clave.
2. **Una sonda en vivo opcional:** leer `TYPESAFE_API_KEY` del entorno, estimar el presupuesto, hacer exactamente una llamada, no imprimir la clave y guardar digest, modelo concreto, uso, latencia y decisión.

## Plan

| # | Lección | Resultado |
|---|---|---|
| 1 | [Decisiones, no cadenas](01-decisions-not-strings/) | Elegir entre Choice, Score y Noul sin confundir tipos con verdad |
| 2 | [Un experimento reproducible y de coste acotado](02-bounded-experiment/) | Ejecutar la base sin conexión y entender la sonda opcional de una llamada |
| 3 | [Casos de uso en nuestros repositorios](03-repository-use-cases/) | Elegir seams útiles en Gaia, GA, Demerzel, IX y TARS preservando la autoridad |
| 4 | [Benchmark del coste en tokens](04-token-cost-benchmark/) | Probar la hipótesis de ahorro del 50 % frente a calidad, reintentos y coste desplazado |
| — | [Diario](journal/) | Hechos medidos, preguntas abiertas y trabajo en vivo pendiente |

## Requisitos previos

- [Python](https://docs.python.org/3/) 3.10 o posterior; el laboratorio usa solo la biblioteca estándar.
- JSON y lógica condicional ordinaria.
- Cuenta y clave de TypeSafe solo para la sonda opcional. Guarda la clave en `TYPESAFE_API_KEY`; no la pegues en una lección, fuente, transcripción de terminal o chat.

## Fuentes primarias

- [Introducción](https://docs.typesafe.ai/introduction) e [inicio rápido](https://docs.typesafe.ai/introduction/quickstart)
- [Primitivas](https://docs.typesafe.ai/primitives), [confianza](https://docs.typesafe.ai/confidence) y [patrones](https://docs.typesafe.ai/patterns)
- [Modelos y precios](https://docs.typesafe.ai/models), [referencia HTTP](https://docs.typesafe.ai/api) y [anuncio de Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev)
