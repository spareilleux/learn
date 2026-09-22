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
- [ ] Estudio de calibración en vivo

## Experimentos

| Pregunta | Hipótesis previa | Resultado medido | Veredicto | Evidencia |
|---|---|---|---|---|
| ¿Puede la política fallar de forma cerrada sin proveedor? | Un mock cerrado puede validar y rechazar el despacho sin autoridad | 14/14 pruebas en 0,078 s; `human_review:no_explicit_authority` | confirmado solo para política local | [entrada del 20 de septiembre](#2026-09-20--base-sin-conexión), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |
| ¿Puede un harness acotado probar la hipótesis de ahorro del 50 % antes de gastar? | Un corpus fijo y un plan exacto deben exponer coste, calidad y reintentos sin contactar Jev | 12 casos, 13 llamadas, límite conservador de 17.663 tokens, límite de coste 0,000741846 $, 19/19 pruebas en 0,078 s | confirmado para planificación; ahorro en vivo no medido | [entrada del benchmark](#2026-09-20--harness-del-benchmark-de-coste), [lección 4](../04-token-cost-benchmark/) |

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

Se añadieron 12 casos saneados de GA, Gaia y Demerzel, incluido un intento de prompt injection. `plan` indica 13 llamadas, cero reintentos, un límite conservador de 17.663 tokens, un límite estimado de entrada de 0,000741846 $ y un techo de 0,0021 $. La suite combinada pasa 19/19 pruebas en 0,078 s.

El scorer mock muestra exactitud perfecta de fixture, Brier 0,015 y una razón entrada individual/batch de 2,4. Solo valida el scorer: la fixture es `mock-jev-benchmark/1`, no se llamó a ningún proveedor y no son resultados Jev.

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
