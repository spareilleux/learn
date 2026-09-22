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
| ¿Puede Jev reducir un 50 % el coste posterior a igual calidad? | Un gate tipado resuelve casos sin falsos soportes | Plan: 12 casos, 13 llamadas, cero reintentos, techo 0,0021 $; sin resultado en vivo | inconcluso | [benchmark TypeSafe](../../typesafe-ai-system-one/04-token-cost-benchmark/) |

## 2026-09-20 — Primer tracer de matrices

Se implementaron `opportunities.json`, validador y renderer con la biblioteca estándar de Python. El registro contiene Jev, el método Learn, auditoría hexagonal y frontera RabbitMQ.

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Resultado: `validated=4 matrices=current mirrors=current`; 6/6 pruebas en 0,002 s. Se rechaza promoción sin artefactos y adopción sin veredicto confirmado, y se comprueba paridad EN/FR/ES y estructura del diario. Sin red externa ni mutación de repositorios.

## Por verificar

- Confirmar la primera ejecución CI alojada para matrices, paridad y diarios.
- Medir tiempo de autoría antes de afirmar menor coste.
- Revisión adversaria independiente del esquema y puntuaciones.
- Calibración Jev solo con aprobación explícita de gasto.
- Elegir un seam hexagonal exacto o rechazar la oportunidad.

## Preguntas abiertas

- ¿Qué métricas predicen que un hallazgo sobrevivirá la integración?
- ¿Deben separarse siempre ownership y autoridad de merge?
- ¿Cuándo revisar un rechazo en vez de retirarlo?
