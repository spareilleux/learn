---
title: Diario
description: Evidencia detallada del laboratorio de dogfooding, incluido su método, matrices y decisiones de promoción.
sidebar:
  order: 99
---

## Progreso

- [x] Registro machine-readable y renderer determinista
- [x] Cinco matrices generadas
- [x] Invariantes de promoción y prueba de salida obsoleta
- [x] Primeras oportunidades clásicas y agénticas
- [x] Método del curso como oportunidad
- [x] Checks CI de paridad y estructura del diario
- [ ] Primera revisión adversaria independiente
- [ ] Primer candidato promovido o rechazado con evidencia de repositorio

## Experimentos

| Pregunta | Hipótesis previa | Resultado medido | Veredicto | Evidencia |
|---|---|---|---|---|
| ¿Puede un registro generar vistas sin que una puntuación otorgue autoridad? | Renderer e invariantes separan prioridad y promoción | 4 oportunidades, 5 matrices, 6/6 pruebas en 0,002 s; sin cambiar estado ni autoridad | confirmado para el tracer local | [entrada](#2026-09-20--primer-tracer-de-matrices), [`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) |
| ¿Puede Jev reducir un 50 % el coste posterior a igual calidad? | Un gate tipado resuelve casos sin falsos soportes | Plan: 12 casos, 13 llamadas, cero reintentos, límite local de 0,0021 $ estimado por bytes — no un techo de facturación; sin resultado en vivo | inconcluso | [benchmark TypeSafe](../../typesafe-ai-system-one/04-token-cost-benchmark/) |
| ¿Expone un oráculo Petri sin conexión el salto inseguro de consejo Jev a autoridad? | El flujo basado solo en consejo alcanza un efecto; el protegido exige evidencia independiente y concesión de implementación | Soporte falso sintético de 0,98; pasan 3/3 pruebas C# y 1/1 prueba de paridad de la fixture; sin replay en un repositorio real | prometedor localmente, no integrado | [lección](05-jev-petri-authority/), [`JevEvidenceGateTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs) |

## 2026-09-20 — Primer tracer de matrices

Se implementaron `opportunities.json`, validador y renderer con la biblioteca estándar de Python. El registro contiene Jev, el método Learn, auditoría hexagonal y frontera RabbitMQ.

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Resultado: `validated=4 matrices=current mirrors=current`; 6/6 pruebas en 0,002 s. Se rechaza promoción sin artefactos y adopción sin veredicto confirmado, y se comprueba paridad EN/FR/ES y estructura del diario. Sin red externa ni mutación de repositorios.

## 2026-09-22 — Límite de autoridad Jev × Petri sintético

Hipótesis previa: si una clasificación Jev muy confiada conduce directamente a un efecto, un falso `supported` puede autorizar trabajo; tokens separados de evidencia verificada y concesión de implementación bloquean esa ruta. Baseline: el caso sintético fijado `gaia_design_authority` devuelve `supported` con 0,98 cuando se espera `contradicted`.

La prueba Python vincula la fixture JSON compartida a la respuesta sintética. La prueba C# reproduce `classify → authorize_from_advisory` en la red insegura y explora completamente la red protegida para las tres combinaciones donde falta al menos uno de los tokens independientes. Una ruta válida sigue siendo posible con ambos tokens. Resultado local: pasan 3/3 pruebas C# y 1/1 prueba de paridad; tras regenerar, `dogfood.py check` informa `validated=5 matrices=current mirrors=current`. Sin llamadas al proveedor, tokens facturados, efectos en producción ni replay de Gaia/IX sobre una revisión exacta. Veredicto: experimento de especificación prometedor, todavía no apto para incubación.

## Por verificar

- Confirmar la primera ejecución CI alojada para matrices, paridad y diarios.
- Medir tiempo de autoría antes de afirmar menor coste.
- Revisión adversaria independiente del esquema y puntuaciones.
- Calibración Jev solo con aprobación explícita de gasto.
- Asociar la red protegida con un seam público Gaia o IX en una revisión exacta, reproducir el testigo inseguro y comparar con una prueba determinista sencilla.
- Elegir un seam hexagonal exacto o rechazar la oportunidad.

## Preguntas abiertas

- ¿Qué métricas predicen que un hallazgo sobrevivirá la integración?
- ¿Deben separarse siempre ownership y autoridad de merge?
- ¿Cuándo revisar un rechazo en vez de retirarlo?
