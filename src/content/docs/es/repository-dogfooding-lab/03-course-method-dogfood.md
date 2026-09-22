---
title: Dogfood del método del curso
description: Tratar escritura, verificación y diarios multilingües como un sistema de ingeniería medible.
sidebar:
  order: 3
---

Un curso puede enseñar buenas prácticas y producirse con un proceso débil. Por eso evaluamos el método.

1. **Ejemplos ejecutables:** cada salida viene de código o se marca sin probar.
2. **Evidencia del diario:** hipótesis, baseline, resultado, veredicto y artefacto son distintos.
3. **Paridad de idiomas:** EN, FR y ES comparten archivos y enlaces; automatización revisa estructura, humanos significado.
4. **Adopción:** el diario sigue rechazo, incubación e integración más allá de publicar.
5. **Eficiencia agéntica:** coste por resultado aceptado, no actividad o tokens solos.

Un curso puede publicarse cuando los hechos inestables usan fuentes oficiales, se reprodujeron comandos, lo no probado es explícito, las medidas enlazan evidencia, las traducciones reflejan la fuente y las recomendaciones siguen siendo hipótesis antes de probarse.

La automatización prueba paridad, enlaces, matrices y tests. No prueba una traducción idiomática ni una decisión arquitectónica sabia.

<details>
<summary>Ejercicio: dejar obsoleta la matriz</summary>

Cambia una puntuación sin regenerar `matrices.md` y ejecuta `python dogfood.py check`. Debe fallar. Regenera con `python dogfood.py write` y repite las pruebas.

</details>
