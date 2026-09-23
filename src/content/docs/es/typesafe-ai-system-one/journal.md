---
title: Diario
description: Evidencia fechada sobre TypeSafe AI y Jev — controles sin conexión, pequeños pilotos sintéticos en vivo y calibración pendiente en nuestros repositorios.
sidebar:
  order: 99
---

## Progreso

- [x] Fuentes oficiales sobre introducción, primitivas, modelo, precios, confianza, API y patrones
- [x] Solicitud sin conexión, validador y política sin autoridad
- [x] Runner mock, corpus de 12 casos y 19 pruebas deterministas ejecutados
- [x] Protocolo en vivo detallado de una llamada, con presupuesto y parada
- [x] Hipótesis acotadas para Gaia, GA, Demerzel, IX y TARS
- [x] Versiones francesa y española
- [x] Pequeñas llamadas Jev en vivo con corpus sintéticos; sin calibración en repositorios
- [x] Corpus etiquetado y harness de scoring sin conexión
- [x] Plan de batching con estado idéntico corregido; fixture sintética de estrés del gate y 23 pruebas ejecutadas
- [ ] Estudio de calibración en vivo
- [x] Control negativo determinista sin conexión para evidencia estructurada de Gaia

## Experimentos

| Pregunta | Hipótesis previa | Resultado medido | Veredicto | Evidencia |
|---|---|---|---|---|
| ¿Puede la política fallar de forma cerrada sin proveedor? | Un mock cerrado puede validar y rechazar el despacho sin autoridad | 14/14 pruebas en 0,078 s; `human_review:no_explicit_authority` | confirmado solo para política local | [entrada del 20 de septiembre](#2026-09-20--base-sin-conexión), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |
| ¿Puede un harness acotado probar la hipótesis de ahorro del 50 % antes de gastar? | Un corpus fijo y un plan exacto deben exponer coste, calidad y reintentos sin contactar Jev | Plan histórico: 12 casos, 13 llamadas, 17.663 bytes UTF-8, 19/19 pruebas; confundía bytes con tokens y cambiaba el estado entre brazos | invalidado como límite de tokens/coste; [corregido abajo](#2026-09-22--corrección-del-protocolo-de-batching-y-prueba-del-gate) | [entrada del 20 de septiembre](#2026-09-20--harness-del-benchmark-de-coste), [lección 4](../04-token-cost-benchmark/) |
| ¿Basta un umbral de confianza para evitar falsos soportes? | Un soporte erróneo de alta confianza debe poder pasar un umbral, mientras subirlo reduce cobertura | Fixture sintética: con 0,95 pasa 1/12 y es falso; plan corregido de 13 llamadas con 46.318 bytes; 23/23 pruebas en 0,086 s | refutada la hipótesis de gate basado solo en confianza; sin calidad Jev ni coste facturado medidos | [entrada del 22 de septiembre](#2026-09-22--corrección-del-protocolo-de-batching-y-prueba-del-gate), [lección 5](../05-confidence-gate-stress/) |
| ¿Reduce el batching con estado idéntico la entrada de Jev? | Compartir el estado debe costar menos que repetirlo sin cambiar las decisiones | 11/12 etiquetas en ambos brazos; 2.487 tokens de entrada por lote frente a 14.939 en llamadas individuales (83,4 % menos en esta comparación) | prometedor aquí, sin ahorro integral demostrado | [piloto siguiente](#2026-09-22--piloto-live-de-batching) |
| ¿Ayuda una regla explícita a distinguir ausencia y contradicción? | Corregirá al menos un error sin perder otras respuestas correctas | Nueve casos exploratorios: 8/9 con consigna general, 9/9 y 9/9 con regla explícita; +702 tokens de entrada por lote (+36,5 %) | preliminar; corpus creado después del primer error | [desafío siguiente](#2026-09-22--desafío-live-de-ausencia-frente-a-contradicción) |
| ¿Necesitan Jev las igualdades estructuradas de publicación Gaia? | Una regla determinista clasificará nueve escenarios derivados del código sin llamar al modelo | 9/9 etiquetas de fixture; tres pruebas sin conexión aprobadas; cero llamadas al proveedor | confirmado solo para estas comparaciones sintéticas simples | [control negativo siguiente](#2026-09-23--control-negativo-de-evidencia-estructurada-de-gaia) |

## 2026-09-20 — Revisión de fuentes oficiales

- `jev-1.13.0` es el modelo concreto publicado; `jev-latest` es un alias móvil.
- Precio publicado: 0,042 $ por millón de tokens de entrada; salidas gratuitas. Es un dato fechado.
- Límites publicados: 64k totales, 32k para estado más pregunta más larga, texto, 250.000 tokens/s y 1.200 solicitudes/minuto; pueden cambiar.
- Ninguna cifra del anuncio se presenta como medición en nuestros repositorios.

## 2026-09-20 — Base sin conexión

Windows 11, Python 3.14.2. Digest `67c1ee4bcd36b497f60872c0715d435b364c3b7743ad06f9be543071af044a1b`; decisión `human_review:no_explicit_authority`; 14 pruebas en 0,078 s. Sin red externa; una prueba loopback hermética demuestra que una redirección se detiene antes de que el bearer token llegue a un segundo origen. La fixture se identifica como `mock-jev-course/1`, no Jev.

```text
python typesafe_lab.py mock
python -W error::ResourceWarning -m unittest -v
```

## 2026-09-20 — Harness del benchmark de coste

Se añadieron 12 casos saneados de GA, Gaia y Demerzel, incluido un intento de prompt injection. El `plan` histórico indicaba 13 llamadas, cero reintentos, 17.663 bytes UTF-8 de solicitud llamados erróneamente límite de tokens, un proxy de coste por bytes de 0,000741846 $ llamado erróneamente límite de coste y un límite local de proxy de 0,0021 $ llamado erróneamente techo estricto. La suite combinada pasaba 19/19 pruebas en 0,078 s. Estas etiquetas y el diseño de batching se corrigieron el 22 de septiembre de 2026.

El scorer mock muestra exactitud perfecta de fixture, Brier 0,015 y una razón entrada individual/batch de 2,4. Solo valida el scorer: la fixture es `mock-jev-benchmark/1`, no se llamó a ningún proveedor y no son resultados Jev.

## 2026-09-22 — Corrección del protocolo de batching y prueba del gate

La revisión de fuentes primarias mostró que el lote anterior y las llamadas individuales tenían estados de distinto tamaño: su razón no aislaba el batching. El plan corregido mantiene el mismo estado de 12 casos en todas las solicitudes: 8.034 bytes UTF-8 para el lote, 38.284 para 12 llamadas de una pregunta, 46.318 en total. Con la tarifa consultada, 0,001945356 $ es un **proxy basado en bytes**, no una factura garantizada. La antigua razón mock de 2,4 provenía de una fixture arbitraria y se eliminó de la salida actual.

Hipótesis previa: un umbral de confianza alto no impedirá un falso `supported`. La fixture sintética deliberadamente errónea confirma esta limitación del gate: con 0,95 pasa 1/12 y es falso; con 0,99 no pasa ninguno y los 12 van a revisión. Se ejecutaron localmente `python jev_benchmark.py plan`, `python jev_gate_audit.py synthetic` y `python -W error::ResourceWarning -m unittest -v`; 23/23 pruebas en 0,086 s. No se leyó ninguna clave, no se llamó a Jev y no se midió ningún ahorro real de tokens. Véase la [nota de fuentes primarias](https://github.com/spareilleux/learn/blob/main/docs/research/2026-09-22-jev-experiment-design-primary-sources.md).

## 2026-09-22 — Python 3.10 a 3.14, sin conexión

Hipótesis previa: la suite sin conexión solo usa la biblioteca estándar, así que pasa sin cambios de Python 3.10 a 3.14. Comando, sobre una exportación limpia de `code/typesafe-ai-system-one` en `b3a9c16`, un intérprete cada vez mediante uv 0.10.4: `uv run --no-project --python <v> python -W error::ResourceWarning -m unittest`. Resultado en Windows 11: 23/23 pruebas pasan en 3.10.19, 3.11.14, 3.12.12, 3.13.12 y 3.14.3, en 0,104 a 0,132 s. La CI alojada para el mismo commit ([run 35804194871](https://github.com/spareilleux/learn/actions/runs/35804194871)) pasa en Ubuntu, Windows y macOS con Python 3.14. Veredicto: confirmado para la suite sin conexión; la CI sigue probando solo 3.14. No se leyó ninguna clave de API ni se llamó a ningún proveedor: la llamada en vivo y la calibración de 13 llamadas siguen esperando la `TYPESAFE_API_KEY` del operador y una aprobación explícita del techo, que son decisiones humanas.

La entrada anterior sobre Python describe el estado de aquel momento; las llamadas en vivo posteriores sustituyen su mención de llamadas pendientes.

## 2026-09-22 — Piloto live de batching

Con el mismo corpus sintético de 12 casos, enviamos el estado una vez con 12 preguntas y después lo repetimos en 12 llamadas individuales. Jev acertó 11/12 en ambos brazos, sin falsos `supported`. Uso declarado por el proveedor: 2.487 tokens de entrada por lote frente a 14.939 individualmente (83,4 % menos entrada Jev); Brier multiclase de 0,1505 y 0,1452. Persistió el error de llamar `contradicted` a la falta de digest/revisión, en lugar de `insufficient`. Dos repeticiones del lote y el orden inverso de opciones conservaron las etiquetas. En 17 llamadas capturadas: 25.236 tokens de entrada, coste **estimado** de 0,001059912 $ a la [tarifa publicada](https://docs.typesafe.ai/models); facturación real sin verificar. No medimos ahorros de flujo completo ni transferimos autoridad.

## 2026-09-22 — Desafío live de ausencia frente a contradicción

Tras observar el error, preparamos un [nuevo corpus sintético de nueve casos](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/absence-vs-conflict-corpus.json), **no reservado como holdout intacto**: tres ausencias, tres contradicciones y tres soportes. Hipótesis previa a las llamadas: una regla explícita corregirá al menos una etiqueta sin perder las demás. `jev-latest` resolvió a `jev-1.13.0`. La consigna general obtuvo 8/9, cero falsos soportes, Brier 0,103067 y 1.921 tokens de entrada. La regla explícita obtuvo 9/9, cero falsos soportes, Brier 0,005356 y 2.623 tokens; su repetición exacta obtuvo 9/9, Brier 0,006067 y 2.623 tokens. Se corrigió `missing_receipt_sha` (`contradicted` → `insufficient`). Las tres llamadas capturadas sumaron 7.167 tokens de entrada, coste estimado de 0,000301014 $ a la tarifa publicada. Es desarrollo exploratorio de instrucciones, no calibración ni generalización; 702 tokens adicionales por lote pueden cancelar otros ahorros. Jev sigue siendo consultivo y no autoriza efectos.

## 2026-09-23 — Control negativo de evidencia estructurada de Gaia

Regla fijada antes de probar: una divergencia conocida es `contradicted`; si no, una observación obligatoria ausente es `insufficient`; si no, las comprobaciones coincidentes son `supported`. Nueve escenarios saneados derivan de los seams `validateObservation`, `validateAuthorization` y `validatePullRequest` de Gaia, fijados en `c94df3f5a53cd9f472e8a97b656dc23d7c940389`. El [corpus](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/gaia-structured-evidence-corpus.json) contiene tres casos por clase, pero ningún recibo de producción. La [base sin conexión](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/test_gaia_structured_evidence.py) clasificó 9/9; sus tres pruebas pasaron. Un caso con ausencia y divergencia confirma la prioridad de un conflicto conocido. No hubo llamada Jev ni efecto externo. Estos casos diseñados para la regla no estiman precisión real ni superioridad del modelo. **Decisión:** mantener las igualdades estructuradas en validación determinista y reservar Jev para evidencia verdaderamente ambigua en lo semántico, sin darle autoridad para actuar.

## Por verificar

- Comprobar la facturación real; no confundir tarifa publicada con factura observada.
- Confirmar el esquema vivo y valorar un JSON Schema oficial.
- Evaluar un corpus de repositorios etiquetado, saneado e intacto, con base determinista, latencia y coste de extremo a extremo.
- Revisar precio, modelos y límites justo antes de llamar.

## Preguntas abiertas

- ¿Qué repositorio tiene suficientes decisiones históricas etiquetadas?
- ¿Debe el adaptador exponer confianza, probabilidades o ambas sin convertirlas en autoridad?
- ¿Qué contrato de redacción se necesita antes de enviar artefactos a un proveedor externo?
