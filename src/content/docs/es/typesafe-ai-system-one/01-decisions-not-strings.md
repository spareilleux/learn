---
title: "1. Decisiones, no cadenas"
description: El modelo mental System One, las tres primitivas tipadas, por qué la confianza no es autoridad y dónde ayudan las salidas cerradas de Jev sin probar la corrección semántica.
sidebar:
  order: 1
---

[TypeSafe AI](https://docs.typesafe.ai/introduction) presenta Jev como un modelo para juicios rápidos y enfocados dentro del software. Una solicitud contiene un `state` y una o más preguntas. Cada pregunta se evalúa de manera independiente contra el mismo estado, y la respuesta vuelve bajo el identificador elegido por quien llama.

Es deliberadamente menos general que el texto generado. La ventaja no es una corrección mágica, sino una interfaz pequeña que el código puede validar y componer.

## Tres primitivas

| Primitiva | Cuándo usarla | Valor devuelto |
|---|---|---|
| [`Choice`](https://docs.typesafe.ai/primitives/choice) | debe ganar un miembro de un conjunto cerrado | opción, probabilidades y confianza |
| [`Score`](https://docs.typesafe.ai/primitives/score) | la respuesta ocupa una posición en una rúbrica ordenada | puntuación ponderada, leyenda, probabilidades y confianza |
| [`Noul`](https://docs.typesafe.ai/primitives/noul) | la respuesta útil es un grado de sí frente a no | número de 0 a 1 |

`Noul` es el nombre de la primitiva binaria de TypeSafe. A diferencia de Choice y Score, no incluye un campo `confidence` separado.

El laboratorio pregunta las tres dimensiones en una sola llamada:

```json
{
  "next_step": {
    "type": "choice",
    "instructions": "¿Qué siguiente paso del ciclo de vida respaldan las evidencias proporcionadas?",
    "criteria": {
      "design_review": "Revisar el diseño; falta autoridad de implementación o la evidencia está incompleta.",
      "bounded_implementation": "Implementar un único tracer acotado solo cuando el diseño y la evidencia de autoridad sean explícitos.",
      "reject": "La propuesta contradice una restricción firme o no puede fallar de forma cerrada."
    }
  },
  "delivery_risk": {
    "type": "score",
    "instructions": "¿Qué tan difícil sería revertir el efecto propuesto?",
    "criteria": ["Bajo y reversible", "Moderado o compensable", "Alto o difícil de revertir"]
  },
  "authority_present": {
    "type": "noul",
    "instructions": "¿Contiene el estado una autoridad de implementación explícita y acotada?"
  }
}
```

No pregunta «¿Debe Gaia implementar esto de forma segura?», porque esa pregunta mezcla varios juicios.

## Preguntas atómicas, composición en código

La decisión final sigue siendo código:

```python
if not authority_artifact_verified:
    return "human_review:no_explicit_authority"
if authority_present < 0.9:
    return "human_review:model_did_not_observe_authority"
if next_step_confidence < 0.75:
    return "human_review:uncertain_next_step"
if delivery_risk > 1.0:
    return "human_review:risk_above_bound"
```

`authority_artifact_verified` lo aporta código local de confianza, nunca Jev. La respuesta Noul puede volver la ruta más conservadora, pero no puede convertir la ausencia de un artefacto de autoridad en permiso.

Los umbrales son hipótesis, no constantes universales. La [guía de confianza](https://docs.typesafe.ai/confidence) recomienda empezar de forma conservadora y ajustar con datos propios. Una acción destructiva exige una política distinta de una recomendación de solo lectura.

## Seguridad de tipos no significa verdad semántica

La API puede limitar `next_step.choice` a las opciones de la solicitud. Nuestro validador rechaza `"merge_now"`; una respuesta válida no puede introducir un comando inventando una cadena.

Pero hay dos afirmaciones distintas:

1. **Forma:** la respuesta pertenece al espacio declarado.
2. **Significado:** la opción es correcta para este estado.

La primera se comprueba mecánicamente. La segunda requiere ejemplos etiquetados, análisis de errores, calibración y una política según las consecuencias. La afirmación «can't hallucinate» del anuncio se refiere a la interfaz cerrada; este curso no la usa como prueba de que Jev no pueda juzgar mal.

## Disciplina de versión y probabilidades

La página actual lista `jev-1.13.0` y los alias `jev-latest` y `jev-preview`. Un alias puede moverse. Si se evaluaron umbrales contra un modelo, fija su versión y registra el `model` concreto de cada respuesta.

Usa la distribución completa cuando importe la segunda opción. `confidence` resume la forma de la distribución; no decide qué alternativa merece escalado ni qué margen sirve en tu dominio.

## Puntos clave

- Choice, Score y Noul son primitivas cerradas, no generación libre.
- Formula preguntas atómicas y combina respuestas en código.
- Una forma válida evita opciones inventadas; no prueba corrección.
- La confianza guía una política; no es autoridad ni aceptación.
- Fija el modelo si importan los umbrales y mide cada actualización.

## Ejercicios

1. Hay que decidir qué repositorio posee un error: Gaia, GA, IX, TARS o Demerzel. ¿Qué primitiva encaja y qué opción falta si la lista puede estar incompleta?

<details><summary>Solución</summary>

Choice, porque la respuesta es un miembro de un conjunto cerrado sin orden. Añade `unknown` o `none_of_the_above`; de lo contrario el modelo debe asignar probabilidad a una opción aunque ninguna encaje.

</details>

2. La respuesta elige `bounded_implementation` con confianza 0,98, pero no hay autorización. ¿Se puede despachar?

<details><summary>Solución</summary>

No. La confianza describe la distribución del modelo, no autoridad. El código debe verificar el artefacto real. Incluso Noul es consultivo y no sustituye pruebas criptográficas o del repositorio.

</details>

## Fuentes

- TypeSafe AI: [introducción](https://docs.typesafe.ai/introduction), [primitivas](https://docs.typesafe.ai/primitives), [confianza](https://docs.typesafe.ai/confidence), [modelos](https://docs.typesafe.ai/models)
- TypeSafe AI: [Introducing System One Models & Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev)
