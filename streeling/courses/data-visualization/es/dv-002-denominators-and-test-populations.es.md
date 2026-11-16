---
module_id: dv-002-denominators-and-test-populations
department: data-visualization
course: Denominadores y poblaciones de prueba cambiantes
level: beginner
prerequisites: [dv-001-observed-degraded-stale-quality]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: data-visualization-2026-10-11-002
version: "0.1.0"
---

# Denominadores y poblaciones de prueba cambiantes

> **Departamento de Visualización de Datos** | Nivel: principiante | Duración estimada: 30 minutos | Estado: borrador de traducción; pendientes la revisión temática humana, la revisión por una persona con dominio del idioma y la prueba con un estudiante

Datos para los ejercicios sin conexión: [seis instantáneas GA fijadas](../../../../code/streeling/fixtures/data-visualization/historical-ga/README.md). Son datos históricos; no se evalúa el comportamiento actual del servicio.

## Objetivos

Al terminar esta lección, usted podrá:

- reconstruir un porcentaje global a partir de los tamaños y las tasas de las categorías, sin promediar porcentajes a ciegas;
- mostrar el denominador junto a una tasa de aprobación de QA y distinguir un cambio en el resultado de un cambio en la población de prueba;
- etiquetar un cálculo contrafactual para que no pueda confundirse con una ejecución observada de GA;
- indicar qué pruebas adicionales hacen falta para comparar con rigor dos instantáneas históricas de QA.

## La pregunta del proyecto

Las instantáneas de QA del chatbot de GA informan un porcentaje global de aprobación y totales por categoría. Suponga que un panel dice que el chatbot mejoró del 75% al 98.08%. ¿Qué contaban esas cifras y se probaron las mismas preguntas?

Use las instantáneas históricas del [15 de junio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) y del [19 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json) en el commit de GA [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924). Ninguna instantánea aporta pruebas sobre el servicio de hoy. Ambas indican `total_prompts: 52` y `degraded: false`. La de junio indica `pass_pct: 75.0`; la de julio, `pass_pct: 98.08`. Los archivos dan los totales por categoría y porcentajes redondeados, pero no incluyen una lista de identidades de las preguntas ni la revisión del evaluador.

### Ejercicio práctico

Escriba un subtítulo de gráfico de una línea que conserve el denominador y el alcance histórico.

> **Respuesta:** «Instantáneas históricas de QA del chatbot de GA: 75% de 52 preguntas el 15 de junio y 98.08% de 52 preguntas el 19 de julio de 2026; estos archivos no establecen las identidades de las preguntas ni la revisión del evaluador».

## 1. Un porcentaje tiene una población contada

Para un resultado binario de aprobación o fallo, `pass rate = passed / evaluated`. En estos archivos, el 75% de 52 corresponde a 39 aprobaciones. Una tasa del 98.08% corresponde a 51 de 52 tras redondear a dos decimales. Los archivos no almacenan directamente esos recuentos enteros globales de aprobaciones; se reconstruyen a partir de los porcentajes publicados y del denominador. Conserve esta distinción en el registro de auditoría.

El denominador es más que una etiqueta. Identifica cuántos elementos se evaluaron, pero **no cuáles**. Dos ejecuciones de 52 preguntas cada una podrían usar preguntas distintas, respuestas esperadas modificadas o reglas de puntuación diferentes. Un gráfico fiel puede mostrar las dos tasas publicadas e indicar que no se ha verificado su comparabilidad.

### Ejercicio práctico

Calcule el número reconstruido de aprobaciones de cada ejecución y luego evalúe: «Las mismas 52 preguntas mejoraron en 12 aprobaciones».

> **Respuesta:** Junio da `0.75 × 52 = 39`; julio da `0.9808 × 52 ≈ 51`, una diferencia de 12 aprobaciones reconstruidas. La frase citada afirma demasiado: los archivos no establecen que se usaran las mismas 52 preguntas ni el mismo evaluador.

## 2. Ponderar las categorías por su tamaño

La instantánea de junio indica `operations: 28.57%` sobre 7 preguntas y `typo-tolerance: 75%` sobre 4. Esos porcentajes redondeados permiten reconstruir aproximadamente 2 y 3 aprobaciones. Promediar `28.57%` y `75%` da `51.785%`, pero trata una categoría de siete preguntas como si tuviera el mismo tamaño que una de cuatro. Para sus 11 preguntas combinadas, use los recuentos reconstruidos: `(2 + 3) / (7 + 4) = 5 / 11 ≈ 45.45%`.

Para agregar toda la instantánea, sume las aprobaciones y los totales de las categorías. Los totales de las once categorías de junio suman 52, y sus aprobaciones reconstruidas suman 39. Esto coincide con la tasa global publicada del 75%. Un gráfico debe mostrar los tamaños de las categorías, sobre todo si una tiene solo una o dos preguntas. Una etiqueta del 100% sobre una pregunta aporta una cantidad de pruebas distinta de un 100% sobre trece.

| Categoría del 15 de junio | Tasa publicada | Total de preguntas | Aprobaciones reconstruidas |
|---|---:|---:|---:|
| Operaciones | 28.57% | 7 | 2 |
| Tolerancia a errores de escritura | 75% | 4 | 3 |
| Ambas categorías combinadas | **45.45%** | **11** | **5** |

«Reconstruidas» importa: estos recuentos se deducen de porcentajes redondeados y pequeños denominadores enteros; no se copian de un campo de recuento bruto de aprobaciones.

### Ejercicio práctico

Alguien pone los dos porcentajes de las categorías en un gráfico de barras y etiqueta su media simple como «tasa de aprobación combinada». Corrija la etiqueta y el cálculo.

> **Respuesta:** Etiquete cada barra con el total de su categoría. Para la tasa combinada, muestre `5/11 ≈ 45.45%`, derivado de las aprobaciones reconstruidas. No use la media sin ponderar de 51.785%.

## 3. Una población cambiante puede cambiar el titular

Los archivos históricos de junio y julio enumeran 52 preguntas, pero ese recuento por sí solo no prueba que la cohorte sea fija. Para ver por qué importa la composición, haga un **ejercicio contrafactual**, no una tercera observación de GA: quite las siete preguntas de `operations` de junio y sus dos aprobaciones reconstruidas de los totales de junio. El subconjunto resultante es `37 / 45 ≈ 82.22%`, frente al original `39 / 52 = 75%`. Ninguna respuesta mejoró en este cálculo. Solo cambió la población.

El propósito no es recomendar que se retiren las preguntas difíciles. Es mostrar cómo un panel puede aparentar una mejora cuando desaparece una categoría difícil. Una tendencia real de QA debe conservar o declarar el conjunto de preguntas, la composición por categorías, las reglas de puntuación y los casos excluidos. Si el sistema no puede proporcionarlos, la indicación correcta es «cambió la tasa publicada; se desconoce la comparabilidad de las cohortes», seguida de un enlace a la investigación.

### Ejercicio práctico

Haga una tabla de dos filas con la ejecución real de junio y el subconjunto contrafactual. ¿Qué fila puede representarse como medición de GA con fecha?

> **Respuesta:** Junio real: 39 aprobaciones reconstruidas / 52 preguntas = 75%. Subconjunto contrafactual: 37 aprobaciones reconstruidas / 45 preguntas ≈ 82.22%. Solo la fila de 52 preguntas es una medición publicada de GA. Etiquete el subconjunto como cálculo didáctico, sin fecha de ejecución ni punto en la tendencia.

## 4. Diseñar la afirmación de comparación

Una vista útil de la calidad de GA muestra juntos la tasa y el denominador, ofrece la composición por categorías y enlaza la instantánea fijada. Debe mantener el estado de la observación separado de la calidad, como en [DV-001](dv-001-observed-degraded-stale-quality.md). Cuando no se disponga de las identidades de las preguntas ni de la revisión del evaluador, una nota visible de «comparabilidad sin verificar» evita que el gráfico de líneas afirme silenciosamente que hubo un experimento controlado.

Para una comparación futura más sólida, registre una revisión estable del corpus de preguntas, la revisión del evaluador, la configuración del backend/modelo y el resultado de aprobación o fallo de cada pregunta. Luego compare las preguntas emparejadas, informe las incorporaciones y retiradas por separado y conserve las instantáneas históricas originales. Un recuento bruto de aprobaciones es útil, pero no sustituye estas identidades.

### Ejercicio práctico

Revise este titular propuesto: «La calidad de GA ganó 23.08 puntos porcentuales en el mismo conjunto de prueba». Escriba una alternativa defendible y nombre una próxima medición.

> **Respuesta:** «La tasa de aprobación publicada de QA del chatbot fue del 75% de 52 preguntas el 15 de junio y del 98.08% de 52 el 19 de julio; no se ha verificado la equivalencia de los conjuntos de prueba». La diferencia aritmética es de 23.08 puntos porcentuales, pero «el mismo conjunto de prueba» requiere una revisión fijada del corpus de preguntas y una comparación pregunta por pregunta.

## Ideas clave

- Muestre tanto el numerador como el denominador cuando el registro subyacente permita reconstruirlos.
- Combine las categorías por recuentos, no mediante la media sin ponderar de sus porcentajes.
- Un total constante no prueba que la población de prueba no haya cambiado.
- Un subconjunto contrafactual es una herramienta explicativa, no un resultado registrado de QA.
- Una tendencia comparable requiere la identidad de las preguntas y la procedencia del evaluador, además de porcentajes.

## Lecturas y pruebas del proyecto

- GA: [instantánea de QA del 15 de junio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) e [instantánea de QA del 19 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json), fijadas al mismo commit histórico.
- [DV-001](dv-001-observed-degraded-stale-quality.md), sobre observaciones ausentes y valores históricos trasladados.

*Investigación: `data-visualization-2026-10-11-002`. Borrador de traducción; pendientes la revisión temática humana, la prueba con un estudiante, la revisión por una persona con dominio del idioma y la verificación pública.*
