---
title: "3. Casos de uso en nuestros repositorios"
description: Hipótesis prácticas y acotadas para Gaia, GA, Demerzel, IX y TARS, con seam determinista, rol consultivo del modelo, datos de evaluación y criterios de rechazo.
sidebar:
  order: 3
---

La pregunta útil no es «¿Dónde añadimos IA?», sino:

> ¿Dónde necesitamos ya un juicio difuso, repetido y rápido, con respuestas cerradas y un efecto que pueda quedarse detrás de una gate determinista?

Son experimentos propuestos, no funciones. Ninguno se probó con Jev.

| Repositorio | Juicio candidato | Primitiva | Dueño determinista | Primera evaluación |
|---|---|---|---|---|
| [Gaia](https://github.com/GuitarAlchemist/gaia) | enrutar evidencia a revisión, implementación acotada, rechazo o desconocido | Choice + Noul | verificador de autoridad y máquina de estados | recibos históricos etiquetados a ciegas |
| [GA](https://github.com/GuitarAlchemist/ga) | enrutar una consulta musical o puntuar intención ambigua | Choice + Score | parser, registro de capacidades y búsqueda de solo lectura | corpus de consultas etiquetadas |
| [Demerzel](https://github.com/GuitarAlchemist/Demerzel) | escoger tribunal o cola humana para un registro | Choice | constitución, esquemas y tribunal | veredictos anteriores sin campos de autoridad en la entrada |
| [IX](https://github.com/GuitarAlchemist/ix) | puntuar observaciones por anomalía o prioridad | Score + Noul | pipeline Rust y pruebas estadísticas | informes reservados para evaluación |
| [TARS](https://github.com/GuitarAlchemist/tars) | escoger entre varios parses DSL válidos | Choice | parser F# y AST tipado | corpus de ambigüedad con candidatos |

## Gaia — consejo al lado de la gate

Jev puede estimar próximo paso, riesgo y lenguaje aparente de autoridad. Nunca debe convertir esa probabilidad en prueba. Recibos, digests, generaciones y grants exactos siguen siendo la verdad. Rechaza la integración si una respuesta puede crear sucesor, enviar wake, crear grant o evitar exact replay sin que el controlador demuestre cada precondición.

## GA — enrutar intención, preservar verdad musical

«¿La consulta trata de voicings, armonía, reproducción o soporte?» es Choice. El modelo no debe inventar notas, acordes, afinaciones ni dimensiones OPTIC-K. Eso pertenece a tipos y algoritmos de GA. Compara con corpus etiquetado y rechaza si oculta `unknown` o cambia un endpoint con efectos.

## Demerzel — clasificar evidencia, no interpretar la constitución

Un Choice cerrado puede priorizar tribunal o cola. Constitución, esquemas y autoridad siguen siendo deterministas. Una propuesta atractiva pero no autorizada debe ir a revisión, nunca mutar gobernanza.

## IX — convertir informes en features, no conclusiones

Jev podría estructurar riesgo de reproducibilidad, probabilidad de baseline ausente o prioridad. Estadísticas e invariantes Rust deciden el resultado. Compara con regex, metadatos o un clasificador pequeño; rechaza Jev si un campo determinista basta.

## TARS — elegir candidatos del parser

El seam más limpio aparece después de obtener varios AST válidos. Jev ordena identificadores cerrados; TARS valida el AST y pregunta al usuario si la distribución está dividida. No envíes generación libre directamente a ejecución.

## Adaptador compartido

Si dos pruebas funcionan, usa un puerto pequeño e independiente del proveedor:

```text
evaluate(state, questions, budget) -> typed answers + provider evidence
```

Cada repositorio posee preguntas, umbrales, corpus y política de efectos. El adaptador posee HTTP, modelo, timeout, costes, validación y redacción. Gaia puede registrar evidencia sin convertirse en servicio universal de decisiones.

## Límites de coste y proveedor

- mock y replay por defecto en CI;
- flag live y clave de entorno explícitos;
- modelo, entrada, llamadas, reintentos, tiempo y dólares limitados por separado;
- proveedor, modelo y uso registrados sin secretos;
- fallback determinista o humano, nunca otro proveedor de pago silencioso;
- comparación con la base sin modelo más simple.

## Ejercicios

1. ¿Qué caso ofrece el tracer más limpio?

<details><summary>Solución</summary>

TARS: el parser ofrece una lista cerrada y valida el AST elegido. El modelo no inventa una orden y un corpus de ambigüedad permite medir.

</details>

2. GA llama a Jev y luego a un LLM si hay poca confianza. ¿Qué falta?

<details><summary>Solución</summary>

Un techo total de proveedores/coste y autorización explícita del fallback. La segunda llamada amplía silenciosamente autoridad y gasto.

</details>

## Fuentes

- TypeSafe AI: [fan-out especulativo](https://docs.typesafe.ai/patterns/fan-out), [routing por confianza](https://docs.typesafe.ai/patterns/confidence-routing), [puntuación compuesta](https://docs.typesafe.ai/patterns/composite-scoring)
- Repositorios: [Gaia](https://github.com/GuitarAlchemist/gaia), [GA](https://github.com/GuitarAlchemist/ga), [Demerzel](https://github.com/GuitarAlchemist/Demerzel), [IX](https://github.com/GuitarAlchemist/ix), [TARS](https://github.com/GuitarAlchemist/tars)
