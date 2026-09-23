---
title: Diario
description: Evidencia fechada del curso TypeSafe AI System One y Jev — hechos oficiales, experimento mock determinista, mediciones en vivo ausentes e hipótesis pendientes de corpus etiquetados.
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
- [ ] Llamada Jev en vivo
- [x] Corpus etiquetado y harness de scoring sin conexión
- [x] Plan de batching con estado idéntico corregido; fixture sintética de estrés del gate y 23 pruebas ejecutadas
- [ ] Estudio de calibración en vivo

## Experimentos

| Pregunta | Hipótesis previa | Resultado medido | Veredicto | Evidencia |
|---|---|---|---|---|
| ¿Puede la política fallar de forma cerrada sin proveedor? | Un mock cerrado puede validar y rechazar el despacho sin autoridad | 14/14 pruebas en 0,078 s; `human_review:no_explicit_authority` | confirmado solo para política local | [entrada del 20 de septiembre](#2026-09-20--base-sin-conexión), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |
| ¿Puede un harness acotado probar la hipótesis de ahorro del 50 % antes de gastar? | Un corpus fijo y un plan exacto deben exponer coste, calidad y reintentos sin contactar Jev | Plan histórico: 12 casos, 13 llamadas, 17.663 bytes UTF-8, 19/19 pruebas; confundía bytes con tokens y cambiaba el estado entre brazos | invalidado como límite de tokens/coste; [corregido abajo](#2026-09-22--corrección-del-protocolo-de-batching-y-prueba-del-gate) | [entrada del 20 de septiembre](#2026-09-20--harness-del-benchmark-de-coste), [lección 4](../04-token-cost-benchmark/) |
| ¿Basta un umbral de confianza para evitar falsos soportes? | Un soporte erróneo de alta confianza debe poder pasar un umbral, mientras subirlo reduce cobertura | Fixture sintética: con 0,95 pasa 1/12 y es falso; plan corregido de 13 llamadas con 46.318 bytes; 23/23 pruebas en 0,086 s | refutada la hipótesis de gate basado solo en confianza; sin calidad Jev ni coste facturado medidos | [entrada del 22 de septiembre](#2026-09-22--corrección-del-protocolo-de-batching-y-prueba-del-gate), [lección 5](../05-confidence-gate-stress/) |

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

## Por verificar

- Ejecutar una llamada tras exportar `TYPESAFE_API_KEY`, sin registrar el secreto.
- Confirmar el esquema vivo y valorar un JSON Schema oficial.
- Ejecutar la calibración en vivo de 13 llamadas solo tras aprobar explícitamente el techo de 0,0021 $.
- Medir precisión, calibración, revisión humana, coste y latencia contra una base determinista.
- Revisar precio, modelos y límites justo antes de llamar.
- Se añadió la matriz CI para Windows, Linux y macOS con Python 3.14; falta confirmar su primer resultado alojado.

## Preguntas abiertas

- ¿Qué repositorio tiene suficientes decisiones históricas etiquetadas?
- ¿Debe el adaptador exponer confianza, probabilidades o ambas sin convertirlas en autoridad?
- ¿Qué contrato de redacción se necesita antes de enviar artefactos a un proveedor externo?
