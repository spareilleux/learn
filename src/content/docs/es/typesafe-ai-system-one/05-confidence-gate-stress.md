---
title: "Prueba de estrés del gate de confianza: cuándo abstenerse"
description: Repetir una respuesta sintética deliberadamente errónea para medir falsos soportes, carga de revisión y límites de un umbral de confianza.
sidebar:
  order: 5
---

Este experimento es **local y sintético**. Prueba nuestro gate, no la precisión de Jev. Dos etiquetas se convierten deliberadamente en respuestas `supported` erróneas, una con confianza 0,98. No autoriza ninguna acción en un repositorio.

## Pregunta e hipótesis previa

> ¿Puede un umbral de confianza, por sí solo, impedir un falso `supported` sin perder cobertura útil?

Esperamos que **no**: subir el umbral debería reducir la cobertura, pero una respuesta errónea muy confiada aún puede pasar. La [documentación de confianza de TypeSafe](https://docs.typesafe.ai/confidence) describe una salida del modelo, no una prueba. Las [limitaciones de Jev 1.13](https://docs.typesafe.ai/model-jaggedness/jev-1.13) incluyen indirección, estado irrelevante y prompt injection como casos que requieren pruebas específicas.

## Ejecutar la fixture de estrés

Desde `code/typesafe-ai-system-one/`:

```text
python jev_gate_audit.py synthetic
python -W error::ResourceWarning -m unittest -v
```

Mediciones locales de la fixture:

| Umbral | Pasarían un gate `supported` basado solo en confianza | Falsos soportes | A revisión |
|---:|---:|---:|---:|
| 0,50 | 6 | 2 | 6 |
| 0,90 | 5 | 1 | 7 |
| 0,95 | 1 | 1 | 11 |
| 0,99 | 0 | 0 | 12 |

Con 0,95, el **único** caso que pasa es erróneo. Un umbral intercambia carga de revisión por cobertura; no establece verdad ni autoridad para fusionar, desplegar o implementar. El script siempre informa `authority_granted: false` y `provider_called: false`.

## Reutilizar un recibo live completo, sin otra llamada

Solo después de que un benchmark autorizado por separado produzca un recibo local completo:

```text
python jev_gate_audit.py record --input evidence/jev-live.json
```

La auditoría rechaza recibos incompletos y digests de solicitud que no coincidan con el corpus fijado. Solo muestra métricas agregadas. No se debe guardar ninguna clave ni recibo live en Git. El umbral de un modelo real se debe elegir con datos reservados; ajustarlo a estas 12 etiquetas sería sobreajuste.

## Ejercicio

En una ruta sensible al despliegue, ¿basta un umbral de 0,99 para convertir un `supported` de Jev en permiso de desplegar? Explica los límites entre evidencia y autoridad.

<details>
<summary>Solución</summary>

No. Esta fixture simplemente envía los 12 casos a revisión con 0,99; no demuestra nada sobre futuras respuestas del modelo. La puntuación es evidencia a considerar, mientras que un control determinista e independiente autoriza el efecto. Sigue siendo posible un falso soporte por encima de cualquier umbral fijo.

</details>

## Siguiente falsador

Un piloto de calidad aprobado por separado debería comparar la misma pregunta sobre un estado por caso y sobre el estado compartido de 12 casos, con modelo exacto, uso real, falsos soportes, latencia y grupos lingüísticos. La comparación de coste del batching puro debe mantener el estado idéntico en ambos brazos, como hace el [ejemplo oficial de preguntas paralelas](https://docs.typesafe.ai/cookbooks/parallel_questions). La [nota de investigación](https://github.com/spareilleux/learn/blob/main/docs/research/2026-09-22-jev-experiment-design-primary-sources.md) detalla el protocolo. Ninguno de esos resultados del proveedor se ha medido aquí.
