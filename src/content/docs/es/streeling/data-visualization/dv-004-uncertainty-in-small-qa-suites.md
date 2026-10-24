---
title: Incertidumbre en pequeñas baterías de pruebas de QA
description: Incertidumbre en pequeñas baterías de pruebas de QA — Visualización de datos
sidebar:
  label: DV-004 · Incertidumbre en pequeñas baterías de pruebas de QA
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-004-uncertainty-in-small-qa-suites.es.md
---

:::note[Streeling University]
**DV-004** · Incertidumbre en pequeñas baterías de pruebas de QA · principiante · 30 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-004-uncertainty-in-small-qa-suites.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/)
:::

> **Departamento de Visualización de Datos** | Nivel: principiante | Duración estimada: 30 minutos | Estado: borrador de traducción; pendientes la revisión temática humana, la revisión por una persona con dominio del idioma y la prueba con un estudiante

Datos para los ejercicios sin conexión: [seis instantáneas GA fijadas](https://github.com/spareilleux/learn/blob/main/code/streeling/fixtures/data-visualization/historical-ga/README.md). Son datos históricos; no se evalúa el comportamiento actual del servicio.

## Objetivos

Al terminar esta lección, usted podrá:

- calcular el efecto, en puntos porcentuales, de cambiar un resultado en una batería de pruebas o una categoría;
- mostrar recuentos exactos junto a porcentajes redondeados sin afirmar que tiene acceso a los resultados brutos de cada pregunta;
- distinguir la resolución de una batería finita de pruebas de un intervalo de confianza estadístico;
- especificar qué pruebas permitirían repetir una comparación de calidad de GA.

## La pregunta del proyecto

Un panel de GA muestra una tasa histórica de QA del chatbot del 98.08%. ¿Cuánta precisión tiene ese titular si la ejecución contiene 52 preguntas y qué sigue siendo desconocido aunque su aritmética sea correcta? Use las instantáneas del [15 de junio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) y del [19 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json) en el commit fijado de GA [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924). Son registros históricos para la enseñanza, no el estado actual del servicio.

Ambos archivos indican `total_prompts: 52` y `degraded: false`. El de junio indica `pass_pct: 75.0`; el de julio, `pass_pct: 98.08`. Los recuentos globales de aprobaciones se **reconstruyen** como 39/52 y 51/52 a partir de porcentajes redondeados. Las instantáneas no aportan las identidades de las preguntas, los veredictos brutos de cada pregunta ni una revisión del evaluador. [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/) explica por qué la coincidencia de totales no prueba que la población de prueba sea la misma.

### Ejercicio práctico

Escriba una etiqueta de gráfico para julio que dé la cifra y su límite probatorio en una línea.

> **Respuesta:** «QA histórico del chatbot de GA, 19 de julio: 98.08% de 52 preguntas publicado (unas 51 aprobaciones reconstruidas); esta instantánea no incluye los veredictos por pregunta ni la revisión del evaluador».

## 1. Mostrar el tamaño del salto detrás de los decimales

Con 52 resultados binarios, cambiar un resultado mueve la tasa global en `100 / 52 ≈ 1.92` puntos porcentuales. Por eso, una tasa mostrada con dos decimales puede parecer mucho más continua que los saltos subyacentes. Para julio, `51 / 52 × 100 ≈ 98.08%`; una aprobación menos daría `50 / 52 × 100 ≈ 96.15%`. Ninguno de los cálculos predice la siguiente ejecución. Solo muestran cómo afecta un único veredicto a este denominador fijo.

Las tasas publicadas de junio y julio difieren en 23.08 puntos porcentuales, equivalentes a doce aprobaciones reconstruidas si se mantiene el denominador en 52. Es una comparación aritmética, no una prueba de que doce preguntas concretas cambiaran de veredicto. Las instantáneas carecen de las identidades de las preguntas y de la procedencia de la puntuación.

### Ejercicio práctico

Si exactamente uno de los 13 fallos reconstruidos de junio pasara a ser una aprobación **en una batería fija hipotética de 52 preguntas**, ¿qué tasa produciría el cálculo? ¿Puede representarse como una nueva ejecución de GA?

> **Respuesta:** `(39 + 1) / 52 × 100 ≈ 76.92%`, un aumento de unos 1.92 puntos porcentuales. Es un cálculo hipotético de sensibilidad; no se observó ninguna nueva ejecución de GA.

## 2. Las categorías pequeñas tienen saltos mayores

La categoría `operations` de julio informa un 85.71% sobre siete preguntas, compatible con seis aprobaciones reconstruidas. Cambiar un veredicto de esa categoría mueve su tasa en `100 / 7 ≈ 14.29` puntos porcentuales. La categoría `getting-started` informa un 100% sobre **una** pregunta. Una insignia de 100% sobre una pregunta y una de 100% sobre trece preguntas (`modes`) tienen coberturas muy distintas, aunque ambas barras terminen en el mismo punto.

En un gráfico por categorías, sitúe la fracción reconstruida junto al porcentaje y ordene o agrupe según la pregunta real de comparación. Una etiqueta útil es «Operaciones: 6/7 reconstruido, 85.71% publicado». No llame muestra aleatoria a las siete preguntas de la categoría salvo que el diseño de las pruebas establezca un muestreo aleatorio. Un intervalo de confianza convencional respondería a una pregunta estadística de muestreo cuyos supuestos estos archivos no documentan.

### Ejercicio práctico

Compare el cambio de un veredicto en la batería global, en `operations` y en `getting-started`. ¿Qué titular es más sensible a un veredicto?

> **Respuesta:** Los saltos son de unos 1.92 puntos porcentuales para 52 preguntas, 14.29 para siete y 100 para una. La categoría `getting-started`, de una sola pregunta, es la más sensible. Son efectos exactos del denominador, no intervalos de confianza.

## 3. Separar tres límites en la visualización

Primero, el **redondeo**: 98.08% es una cifra redondeada; 51/52 es un recuento entero deducido, no un recuento global de aprobaciones almacenado. Segundo, la **cobertura**: 52 preguntas pueden omitir otras necesidades de los usuarios, idiomas o modos de fallo. Tercero, la **comparabilidad**: los dos archivos dan totales iguales, pero no identificadores estables de preguntas, respuestas esperadas, versiones del evaluador ni configuración del backend. Añadir decimales o una barra de error sin matices no resuelve ninguna de estas limitaciones.

Use un gráfico principal para la tasa publicada y una tabla cercana con la fecha, el denominador, los tamaños de las categorías, el estado de la ejecución y una nota de «base de comparación desconocida». Enlace el JSON histórico exacto. Si la ejecución está degradada o `pass_pct` es `null`, [DV-001](../../data-visualization/dv-001-observed-degraded-stale-quality/) exige un hueco, no un cero. Si pruebas posteriores establecen preguntas emparejadas y ejecuciones repetidas, un análisis separado podrá cuantificar la variabilidad entre ejecuciones; mantenga esa medición separada del tamaño del salto de un veredicto.

### Ejercicio práctico

Un panel dice «98.08% ± 1.92% de confianza» porque una pregunta representa 1/52. Corrija la afirmación.

> **Respuesta:** Muestre «98.08% de 52 preguntas publicado; unas 51 aprobaciones reconstruidas; un veredicto cambia la tasa de esta batería en unos 1.92 puntos porcentuales». No etiquete 1/52 como confianza: no se aportó un modelo de muestreo ni variabilidad entre ejecuciones repetidas.

## 4. Hacer reproducible la próxima comparación

Un registro futuro útil de QA conservaría una revisión del corpus de preguntas y del evaluador, el identificador de cada pregunta, su criterio esperado, el veredicto, la configuración del backend/modelo y la marca de tiempo. Una comparación podría entonces alinear los mismos identificadores, enumerar por separado las preguntas añadidas y retiradas y mostrar los cambios de veredicto. Repetir una batería sin cambios bajo condiciones registradas también revelaría una variabilidad que una sola instantánea no puede medir.

Para el par histórico actual, la frase más sólida que permiten los datos es: «La tasa publicada subió del 75% de 52 el 15 de junio al 98.08% de 52 el 19 de julio; no se ha verificado la equivalencia de las preguntas ni del evaluador». Es una prueba útil sin inventar una explicación causal ni una probabilidad de que la próxima ejecución apruebe.

### Ejercicio práctico

Nombre dos campos que añadir a un registro futuro de GA para poder comprobar «mejoraron doce preguntas». ¿Qué debe hacer la comparación con las preguntas presentes en una sola ejecución?

> **Respuesta:** Añada un `prompt_id` estable y un veredicto `pass` por pregunta, además de una revisión fijada del evaluador para interpretar el veredicto. Compare identificadores emparejados; informe las preguntas añadidas o retiradas como una cohorte separada en lugar de contarlas como respuestas modificadas.

## Ideas clave

- Un veredicto representa unos 1.92 puntos porcentuales en una batería de 52 preguntas, pero 100 puntos en una categoría de una pregunta.
- Los denominadores exactos y los recuentos reconstruidos hacen visible la resolución de una tasa.
- Un salto de un veredicto no es un intervalo de confianza.
- Totales iguales de preguntas no establecen preguntas emparejadas, cobertura ni reglas de puntuación.
- Una comparación futura emparejada requiere identificadores de preguntas, veredictos y procedencia del evaluador.

## Lecturas y pruebas del proyecto

- GA: [instantánea histórica del 15 de junio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) e [instantánea del 19 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json).
- [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/), sobre reconstrucción de recuentos y comprobación de poblaciones de prueba cambiantes.
- [DV-001](../../data-visualization/dv-001-observed-degraded-stale-quality/), sobre observaciones no disponibles.

*Investigación: `data-visualization-2026-10-11-004`. Borrador de traducción; pendientes la revisión temática humana, la prueba con un estudiante, la revisión por una persona con dominio del idioma y la verificación pública.*
