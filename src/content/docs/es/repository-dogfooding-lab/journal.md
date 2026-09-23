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
| ¿Expone un oráculo Petri sin conexión el salto inseguro de consejo Jev a autoridad? | El flujo basado solo en consejo alcanza un efecto; el protegido exige evidencia independiente y concesión de implementación | Soporte falso sintético de 0,98; pasan 3/3 pruebas C# y 1/1 prueba de paridad de la fixture; sin replay en un repositorio real | prometedor localmente, no integrado | [entrada fechada](#jev-petri-2026-09-22), [lección](../05-jev-petri-authority/), [`JevEvidenceGateTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs) |
| ¿Resiste la frontera de autoridad en un seam Gaia fijado? | Una concesión ligada a otra revisión de intención no puede producir un efecto; quitar la comparación debe hacer fallar una prueba determinista | En `c94df3f`, revisión errónea → `AuthorityInvalid` antes de `commit`; el mutante llama `commit` y falla | confirmado solo para este seam secuencial; ningún fallo nuevo en producción | [entrada](#gaia-seam-2026-09-22), [`gaia-publication-authority-check.mjs`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/gaia-publication-authority-check.mjs) |
| ¿Mejora Jev una instrucción explícita sobre evidencia ausente? | Corregir al menos un error inicial sin perder las demás etiquetas correctas | `jev-1.13.0` en vivo: 8/9 inicial, 9/9 explícito en dos llamadas; 1.921 frente a 2.623 tokens de entrada; ningún `supported` falso | exploratorio; ni calibración de repositorio ni autoridad | [entrada](#gaia-seam-2026-09-22), [corpus sintético](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/absence-vs-conflict-corpus.json) |

## 2026-09-20 — Primer tracer de matrices

Se implementaron `opportunities.json`, validador y renderer con la biblioteca estándar de Python. El registro contiene Jev, el método Learn, auditoría hexagonal y frontera RabbitMQ.

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Resultado: `validated=4 matrices=current mirrors=current`; 6/6 pruebas en 0,002 s. Se rechaza promoción sin artefactos y adopción sin veredicto confirmado, y se comprueba paridad EN/FR/ES y estructura del diario. Sin red externa ni mutación de repositorios.

<a id="jev-petri-2026-09-22"></a>

## 2026-09-22 — Límite de autoridad Jev × Petri sintético

Hipótesis previa: si una clasificación Jev muy confiada conduce directamente a un efecto, un falso `supported` puede autorizar trabajo; tokens separados de evidencia verificada y concesión de implementación bloquean esa ruta. Baseline: el caso sintético fijado `gaia_design_authority` devuelve `supported` con 0,98 cuando se espera `contradicted`.

La prueba Python vincula la fixture JSON compartida a la respuesta sintética. La prueba C# reproduce `classify → authorize_from_advisory` en la red insegura y explora completamente la red protegida para las tres combinaciones donde falta al menos uno de los tokens independientes. Una ruta válida sigue siendo posible con ambos tokens. Resultado local: pasan 3/3 pruebas C# y 1/1 prueba de paridad; tras regenerar, `dogfood.py check` informa `validated=5 matrices=current mirrors=current`. Sin llamadas al proveedor, tokens facturados, efectos en producción ni replay de Gaia/IX sobre una revisión exacta. Veredicto: experimento de especificación prometedor, todavía no apto para incubación.

<a id="gaia-seam-2026-09-22"></a>

## 2026-09-22 — Seam Gaia fijado y clasificación de evidencia en vivo

Se intentó el siguiente gate de la lección sobre el commit Gaia [`c94df3f`](https://github.com/GuitarAlchemist/gaia/blob/c94df3f5a53cd9f472e8a97b656dc23d7c940389/src/github-portfolio-publication.mjs). El seam público `createGitHubCandidatePublicationAdapter.publish` observa al candidato, consume una respuesta de autoridad vinculada a `intent.revision` y después llama `commit`, `push` y `openPullRequest`. El lugar Petri `implementation_authority` solo se corresponde aproximadamente con esta autorización: la red pequeña no modela firma, consumo concurrente, idempotencia, fallos ni reconciliación GitHub.

Hipótesis antes de mutar: una respuesta `AUTHORIZED` vinculada a otra revisión no debe mutar nada; eliminar la comparación debe hacer que la prueba observe un `commit` simulado. En un worktree Gaia limpio y separado en `c94df3f`, el [comprobador portable](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/gaia-publication-authority-check.mjs) usa solo efectos inyectados: revisión errónea → `AuthorityInvalid`, llamadas `observe, consume`; revisión simulada correcta → recibo completado y llamadas `observe, consume, commit, push, openPullRequest`. El archivo de pruebas Gaia pasa 8/8. Una prueba nueva para la revisión errónea pasa dos veces; al quitar `value.intentRevision !== intentRevision`, falla con `['commit']`. Se restauró la guarda, sin diff del código fuente. Por separado, la suite Petri pasa 3/3; quitar el arco `implementation_authority → authorize` hace fallar 1/3 prueba, y restaurarlo devuelve 3/3.

La prueba determinista sencilla detecta el defecto inyectado sin la red. **Veredicto:** conservar Petri como herramienta docente y de especificación, no integrarla en runtime; no se ha demostrado un defecto nuevo en Gaia. No se ejercieron la autoridad Ed25519 real, actores concurrentes, crashes/reintentos ni efectos GitHub. Ninguna respuesta Jev se entregó a `publish`.

Se preparó un [corpus sintético de nueve casos](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/absence-vs-conflict-corpus.json) de ausencia frente a contradicción después de un error en doce casos anteriores: **no** es un conjunto de prueba intacto. Antes de las llamadas en vivo sobre estos nueve casos, la hipótesis era que una instrucción explícita corregiría al menos una etiqueta sin perjudicar las otras ocho. En el Playground TypeSafe, `jev-latest` resolvió a `jev-1.13.0`: 8/9 inicial, 9/9 con criterios explícitos y 9/9 al repetir, sin `supported` falso. La ausencia del SHA de un recibo se clasificó erróneamente como `contradicted` y después como `insufficient`. Uso: 1.921 frente a 2.623 tokens de entrada (+36,5 %); con la [tarifa publicada](https://docs.typesafe.ai/models), coste estimado de 0,000080682 $ frente a 0,000110166 $ por llamada capturada, **no** facturación observada. Nueve etiquetas sintéticas y dos ensayos no demuestran calibración ni ahorro del workflow completo. El modelo sigue siendo consultivo.

## 2026-09-23 — Control negativo determinista para recibos Gaia

Este paso comprueba si Jev añade valor a las igualdades estructuradas del seam de publicación Gaia fijado. Una fixture de nueve casos saneados, derivados del código fuente, cubre el HEAD observado del candidato, la revisión de la concesión consumida y el HEAD de la PR: tres coincidencias, tres conflictos y tres pruebas ausentes. Antes de probar, fijamos la regla: primero conflicto conocido, después observación obligatoria ausente y finalmente soporte. La base sin conexión clasifica 9/9 etiquetas de fixture y sus tres pruebas pasan, sin llamada Jev. No son recibos reales de ejecución ni una muestra inédita de campo. Veredicto: no usar el modelo para estas comprobaciones estructuradas; los próximos ensayos Jev deben dirigirse a ambigüedad semántica, con autorización independiente y sin efectos durante el experimento. Véase el [diario TypeSafe](../../typesafe-ai-system-one/journal/) para las limitaciones.

## Por verificar

- Confirmar la primera ejecución CI alojada para matrices, paridad y diarios.
- Medir tiempo de autoría antes de afirmar menor coste.
- Revisión adversaria independiente del esquema y puntuaciones.
- Calibración Jev solo con aprobación explícita de gasto.
- Revisar de forma independiente la correspondencia Petri–Gaia; forzar concesión duplicada, observación obsoleta, crash tras commit y respuesta perdida antes de afirmar seguridad concurrente.
- Comparar Jev con un parser determinista sobre recibos nuevos y saneados; medir el workflow completo y la facturación observada antes de incubar.
- Elegir un seam hexagonal exacto o rechazar la oportunidad.

## Preguntas abiertas

- ¿Qué métricas predicen que un hallazgo sobrevivirá la integración?
- ¿Deben separarse siempre ownership y autoridad de merge?
- ¿Cuándo revisar un rechazo en vez de retirarlo?
