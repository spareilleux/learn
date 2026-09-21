---
title: Incubar, integrar, rechazar
description: Convertir evidencia prometedora en el menor cambio reversible, con autoridad y rollback explícitos.
sidebar:
  order: 4
---

Incubar no es adoptar: el candidato compite con la solución actual.

| Transición | Gate |
|---|---|
| discovered → experimenting | Dolor e hipótesis evidenciados; alternativa simple registrada |
| experimenting → incubating | Baseline, resultado reproducible y revisión independiente |
| incubating → integrating | El tracer bullet gana en métricas y tiene rollback |
| integrating → adopted | Checks pasan, autoridad acepta y evidencia operativa sigue sana |
| any → rejected | Falsador alcanzado, seam inútil o alternativa simple ganadora |

- integra un tracer bullet vertical, no una plataforma horizontal;
- preserva contratos hasta probar su reemplazo;
- fija versiones y revisiones;
- separa autor, revisor y autoridad de merge;
- conserva el rechazo y su evidencia.

Para Jev, una buena calibración solo permite el siguiente A/B acotado; no autoriza routing en GA, Gaia o Demerzel.

<details>
<summary>Ejercicio: escribir un recibo de rechazo</summary>

Elige un candidato derrotado por su alternativa simple. Registra baseline, resultado, criterio violado, artefacto y condición de revisión. Cambia `status` a `rejected` sin borrar la fila.

</details>
