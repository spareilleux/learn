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
| ¿Clasifica Jev evidencia de Demerzel en T/P/U/D/F/C separando ausencia y refutación? | Prerregistrado: ADVISORY_USEFUL exige ≥ 75 % exacto, ≤ 1 T falso, ≤ 1 ausencia leída F/D | Paso 1: 41/58, 0 T falsos, 7/10 ausencias leídas F/D. Paso 2 (textos U y C explícitos): 46/58 y 44/58, conflictos 10/10, ausencias 4–5/10, pero P cae en U 6/10 | INCONCLUSIVE, luego NOT_FIXED | [entrada](#2026-09-25--lógica-hexavalente-de-demerzel-con-jev), [prerregistro](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/demerzel-hexavalent-PREREG.md) |

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

## 2026-09-25 — Lógica hexavalente de Demerzel con Jev

Pregunta prerregistrada en [`demerzel-hexavalent-PREREG.md`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/demerzel-hexavalent-PREREG.md) y confirmada antes de la primera llamada: con solo las definiciones de una línea de Demerzel (`logic/hexavalent-logic.md`), ¿clasifica `jev-1.13.0` evidencia de gobernanza en Verdadero, Probable, Desconocido, Dudoso, Falso o Contradictorio, y separa la *ausencia de evidencia* (U) de la *refutación* (F/D)? Esa segunda mitad es el error `demerzel_immutable` del 22 de septiembre.

Corpus: 60 casos sintéticos, 10 por valor, escritos por un agente con una norma explícita y etiquetados a ciegas por otro. Coinciden en 58; h39 y h57 (D frente a U) quedan fuera de la puntuación. Ninguna palabra de etiqueta aparece en la evidencia, y tres casos llevan una inyección de prompt. Dos brazos por paso: orden canónico de las opciones y orden invertido. Una llamada por caso, sin reintentos, parada a 0,05 $ de entrada declarada.

| N = 58 | Palabras clave | Paso 1: texto de Demerzel | Paso 2: U y C explícitos |
|---|---:|---:|---:|
| Exacto (canónico / invertido) | 12 | 41 / 41 | 46 / 44 |
| T falso | 5 | 0 / 0 | 0 / 0 |
| Ausencia leída F/D (de 10 U) | 0 | **7 / 7** | 4 / 5 |
| Conflicto resuelto hacia un lado (de 10 C) | — | 4 / 4 | **0 / 0** |
| No-U leído U | — | 5 / 4 | 7 / 8 |
| Costo calculado (no facturado) | — | 0,0027 $ | 0,0030 $ |

240/240 respuestas válidas, todas `jev-1.13.0`; latencia media de 372 a 392 ms. Veredictos según las reglas prerregistradas: paso 1 **INCONCLUSIVE** (por encima del umbral de descarte, cero T falsos, pero bajo el 75 % y muy por encima del límite de ausencia); paso 2 **NOT_FIXED** (el peor brazo sigue en 5/10).

Lo que muestra:

- **Los errores bajan por el retículo, nunca suben.** Ningún T falso en 240 llamadas, y ninguna inyección produjo una T.
- **La ausencia se vuelve refutación, de forma sistemática.** En el paso 1 los siete errores U son idénticos en ambos órdenes. Escribir «la ausencia es Desconocido, no evidencia en contra» los reduce a la mitad y nada más: h02, h29 y h41 siguen mal en ambos órdenes, y h36 y h48 ahora cambian con el orden.
- **La frase sobre conflictos funciona por completo.** «Al menos dos registros fuertes y directos apuntan en sentidos opuestos; no lo resuelvas eligiendo un lado» lleva C de 6/10 a 10/10 en ambos órdenes.
- **La frase sobre la ausencia crea un error nuevo.** P cae en U 6/10 (antes 3): los casos P son «sin ejecución directa, pero indicios indirectos inclinan hacia verdadero», lo que el nuevo texto U también describe. La ambigüedad está en las definiciones, no solo en el modelo.

Una prueba encontró un fallo antes de cualquier llamada: con tolerancia 0,01, una suma de dos decimales igual a 0,99 seguía rechazándose, porque el error de coma flotante deja la diferencia justo por encima de 0,01. Es la trampa que hizo fallar el brazo francés de [ix#355](https://github.com/GuitarAlchemist/ix/pull/355); el harness añade ahora un epsilon. Recibos: [paso 1](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/evidence/demerzel-hexavalent-live.json), [paso 2](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/evidence/demerzel-hexavalent-step2-live.json); `python demerzel_hexavalent.py score --out <recibo>` recalcula cada veredicto. Acumulado frente al tope de 1 $ del operador: unos 0,027 $ calculados.

## Por verificar

- Repetir el hexavalente de Demerzel con una definición U que ceda ante indicios que inclinan (P o D), prerregistrada, y probar la frase sobre conflictos con archivos de creencias reales de Demerzel antes de proponerla aguas arriba.
- Ejecutar una llamada tras exportar `TYPESAFE_API_KEY`, sin registrar el secreto.
- Confirmar el esquema vivo y valorar un JSON Schema oficial.
- Ejecutar la calibración en vivo de 13 llamadas solo tras aprobar explícitamente el techo de 0,0021 $.
- Medir precisión, calibración, revisión humana, coste y latencia contra una base determinista.
- Revisar precio, modelos y límites justo antes de llamar.

## Preguntas abiertas

- ¿Qué repositorio tiene suficientes decisiones históricas etiquetadas?
- ¿Debe el adaptador exponer confianza, probabilidades o ambas sin convertirlas en autoridad?
- ¿Qué contrato de redacción se necesita antes de enviar artefactos a un proveedor externo?
