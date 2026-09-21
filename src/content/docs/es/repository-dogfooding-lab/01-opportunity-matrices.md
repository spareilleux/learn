---
title: Matrices de oportunidades
description: Usar matrices pequeñas para mostrar cobertura, valor, evidencia y promoción sin esconder la incertidumbre en una puntuación única.
sidebar:
  order: 1
---

Una clasificación gigante oculta demasiado. El laboratorio conserva cinco vistas. Los valores actuales están publicados en el [`matrices.md`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/matrices.md) generado; `python dogfood.py check` falla si el artefacto difiere del registro JSON.

## 1. Cobertura curso × repositorios

Encuentra transferencias y puntos ciegos. Que una técnica encaje en varios repositorios no significa que todos deban adoptarla.

## 2. Puntuación de oportunidad

Suma dolor, encaje, valor esperado, evidencia y reversibilidad; resta coste y riesgo. Cada dimensión vale 0–5 y solo ordena la investigación.

- la puntuación no cambia `status` ni `authority`;
- una puntuación alta con evidencia débil sigue siendo descubrimiento.

## 3. Estado de promoción

```text
discovered → experimenting → incubating → integrating → adopted
       └──────────────→ rejected                         → retired
```

Promover exige artefactos; `adopted` también exige veredicto confirmado. Los rechazos permanecen para evitar repetir ideas fallidas.

## 4. Resultados y evidencia

Muestra qué se midió, el artefacto y cuándo revisar la conclusión. Un agente `running`, comentario o relato plausible no es evidencia.

## 5. Calidad del método

El método también se somete a dogfooding: ejemplos ejecutables, evidencia del diario, paridad EN/FR/ES, adopción y eficiencia agéntica.

<details>
<summary>Ejercicio: añadir un candidato sin exagerarlo</summary>

Añade dolor observado, alternativa simple y falsador. Mantén `discovered` hasta tener baseline. Ejecuta `python dogfood.py write` y `python -m unittest -v`.

</details>
