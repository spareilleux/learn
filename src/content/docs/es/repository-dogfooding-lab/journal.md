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
| ¿Las puertas llamadas «exige pruebas» y «veredicto confirmado» rechazan un candidato fabricado? | Comprueban la prueba, así que una entrada con campos vacíos y un artefacto inexistente se rechaza | No rechazaron nada: la entrada llegó a `adopted`/`confirmed` con cero errores. Las puertas comprobaban que las claves estuvieran presentes, nunca su contenido | refutada, luego corregida | [entrada](#2026-09-23--una-lectura-adversaria-rompe-las-puertas-del-laboratorio), [`dogfood.py`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/dogfood.py) |
| ¿Una red de Petri encuentra en un repositorio defectos de concurrencia que su propia suite de pruebas no ve? | Buscar marcados muertos en un grafo de alcanzabilidad encuentra al menos un defecto real, solo de lectura | Tres encontrados en GA en el commit `a826864`, cada uno confirmado línea por línea antes de publicarlo, y una afirmación retirada antes de publicarla; reportados en [ga#700](https://github.com/GuitarAlchemist/ga/issues/700), [#701](https://github.com/GuitarAlchemist/ga/issues/701), [#702](https://github.com/GuitarAlchemist/ga/issues/702) | prometedor — ningún mantenedor las ha triado aún | [`petri-nets`](../../petri-nets/), [entrada](#2026-09-23--una-lectura-adversaria-rompe-las-puertas-del-laboratorio) |

## 2026-09-20 — Primer tracer de matrices

Se implementaron `opportunities.json`, validador y renderer con la biblioteca estándar de Python. El registro contiene Jev, el método Learn, auditoría hexagonal y frontera RabbitMQ.

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Resultado: `validated=4 matrices=current mirrors=current`; 6/6 pruebas en 0,002 s. Se rechaza promoción sin artefactos y adopción sin veredicto confirmado, y se comprueba paridad EN/FR/ES y estructura del diario. Sin red externa ni mutación de repositorios.

## 2026-09-23 — Una lectura adversaria rompe las puertas del laboratorio

Otro modelo revisó el esquema y las puntuaciones con una sola consigna: romperlos. Lo consiguió dos veces, y ambos exploits son ahora pruebas de no regresión en `test_dogfood.py`.

**Las puertas comprobaban la presencia, no la prueba.** Esta entrada validaba sin un solo error antes de hoy:

```json
{ "id": "malicious-fabricated-adoption", "status": "adopted", "verdict": "confirmed",
  "artifacts": ["does-not-exist.txt"],
  "baseline": "", "success_metric": "", "falsifier": "", "result": "", "authority": "" }
```

Un candidato sin prueba, sin resultado y con un artefacto ausente del disco llegaba a `adopted`. Bastaba con que `artifacts` fuera una lista no vacía y que `verdict` valiera la cadena `confirmed`; ningún otro campo se comprobaba por su contenido. El nombre de esas puertas prometía una verificación semántica que el código no hacía, en contra de la lección 2, que pide que un lector juzgue un experimento *sin confiar en el autor*.

**Un rechazo podía no probar nada.** `rejected` quedaba fuera de la exigencia de artefactos: un candidato podía descartarse sin prueba ni resultado, en contra de la lección 1, que conserva los rechazos precisamente para que nadie repita la idea.

**Lo que cambia.** Todo campo de texto debe ser no vacío; toda ruta de artefacto debe existir en el disco, aceptando los enlaces por confianza; `rejected` se une a los estados que exigen prueba y requiere un veredicto refutado o inconcluso; un candidato promovido exige al menos un artefacto en este repositorio, no solo enlaces. Las tablas de promoción y de resultados se ordenan ahora por estado de promoción y no por puntuación: el revisor no encontró ningún camino de la puntuación al estado en los datos, pero una tabla que siempre muestra primero la mejor puntuada ejerce la misma autoridad sobre la atención del lector.

La prueba anterior llamada «la puntuación no muta la autoridad» afirmaba que una suma pura no modificaba su argumento, cierto por construcción y por tanto prueba de nada. Ahora comprueba la tabla de promoción generada.

Resultado medido: `validated=6 matrices=current mirrors=current`, 9/9 pruebas en 0,004 s. Se añadieron dos candidatos: la técnica de redes de Petri que produjo [ga#700 a #702](https://github.com/GuitarAlchemist/ga/issues/700), en `incubating`/`promising`, y un contraste entre las redes de Petri de GA y las cinco reglas `ga.*` del ecosistema de gramáticas TARS, en `discovered`.

**Un hallazgo de la revisión que no se corrige aquí.** La oportunidad que describe este curso es la menos falsable del registro: su métrica de éxito es «tiempo de autoría no peor que la referencia», y ninguna referencia está registrada en ninguna parte. Un criterio cuya referencia nunca se midió no puede refutarse. Queda en *Por verificar* en lugar de reformularse en silencio.

**Y el candidato añadido hoy pasó por las puertas antiguas.** Su estado `incubating` lo otorgó una comprobación que igualmente habría sellado la entrada fabricada de arriba. Lo que lo sostiene es la verificación línea por línea contra la fuente de GA, no la aprobación de este registro, que es justamente el argumento para endurecer las puertas antes de confiar en ninguna, incluida la nuestra.

## Por verificar

- Confirmar la primera ejecución CI alojada para matrices, paridad y diarios.
- Medir tiempo de autoría antes de afirmar menor coste. No existe ningún valor de referencia, así que la métrica de éxito actual de `learn-evidence-first-course-method` es irrefutable tal como está escrita.
- Leer el cuerpo de las cinco reglas TARS `ga.*`, no solo sus pesos, antes de afirmar que los dos codificados coinciden o divergen.
- Que un mantenedor tríe ga#700, #701 y #702; el agente automático falló en las cinco issues, así que ninguna ha sido juzgada.
- Calibración Jev solo con aprobación explícita de gasto.
- Elegir un seam hexagonal exacto o rechazar la oportunidad.

## Preguntas abiertas

- ¿Qué métricas predicen que un hallazgo sobrevivirá la integración?
- ¿Deben separarse siempre ownership y autoridad de merge?
- ¿Cuándo revisar un rechazo en vez de retirarlo?
