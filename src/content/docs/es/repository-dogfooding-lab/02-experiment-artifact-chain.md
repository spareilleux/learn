---
title: Experimento y artifact chain
description: Construir una cadena reproducible desde observación hasta veredicto, con experimento acotado y revisión independiente.
sidebar:
  order: 2
---

Un experimento sirve cuando otra persona o agente puede determinar qué ocurrió sin confiar en el autor.

| Artefacto | Contenido requerido |
|---|---|
| Observación | Dolor concreto, fuente fijada o síntoma medido |
| Hipótesis | Afirmación direccional y falsable escrita antes de medir |
| Baseline | Calidad, coste, latencia o superficie de cambio actual |
| Protocolo | Corpus fijo, comandos, límites y parada |
| Evidencia | Salidas, uso, hashes y entorno; sin secretos |
| Veredicto | Confirmado, refutado o inconcluso según criterios previos |
| Recibo de promoción | Autoridad, evidencia exacta y siguiente paso reversible |

Para ingeniería clásica mide defectos, archivos cambiados, setup de pruebas, p50/p95, recuperación y carga operativa. Para sistemas agénticos añade calidad aceptada, falsos positivos, calibración, escalado, reintentos, tokens de entrada/caché/salida por proveedor y dólares. No sumes tokenizers distintos.

El revisor intenta refutar: fuga del corpus, regla determinista más barata, coste humano desplazado, casos ausentes o artefacto de otra revisión.

<details>
<summary>Ejercicio: definir un ahorro del 50 %</summary>

Fija corpus y modelo posterior. Compara llamarlo siempre con llamarlo solo tras un gate Jev. Conserva el mismo quality gate. Rechaza ante un falso soporte sensible a autoridad o si revisión y reintentos eliminan el ahorro.

</details>
