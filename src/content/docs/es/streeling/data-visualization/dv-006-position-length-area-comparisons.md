---
title: Posición, longitud, área y la tarea de comparación
description: Posición, longitud, área y la tarea de comparación — Visualización de datos
sidebar:
  label: DV-006 · Posición, longitud, área y la tarea de comparación
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-006-position-length-area-comparisons.es.md
---

:::note[Streeling University]
**DV-006** · Posición, longitud, área y la tarea de comparación · principiante · 30 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-006-position-length-area-comparisons.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/), [DV-003](../../data-visualization/dv-003-instrument-cohorts-and-units/)
:::

> **Departamento de Visualización de Datos** | Nivel: principiante | Duración estimada: 30 minutos | Estado: borrador de traducción; pendientes la revisión temática humana, la revisión por una persona con dominio del idioma, la prueba con un estudiante y la revisión de publicación

Datos para los ejercicios sin conexión: [seis instantáneas GA fijadas](https://github.com/spareilleux/learn/blob/main/code/streeling/fixtures/data-visualization/historical-ga/README.md). Son datos históricos; no se evalúa el comportamiento actual del servicio.

## Objetivos

Al terminar esta lección, usted podrá:

- nombrar la comparación y la unidad antes de elegir una codificación visual;
- usar una escala de posición compartida o una longitud con origen común para comparaciones cuantitativas;
- explicar por qué el **área** de un círculo, no su radio, debe representar un recuento si se usan círculos;
- mantener visibles las fechas históricas, los denominadores y los límites de comparabilidad junto a un gráfico.

## La pregunta del proyecto

GA tiene tres instantáneas históricas en el commit fijado [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924). La [instantánea de análisis de voicings del 23 de julio de 2026](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/voicing-analysis/2026-07-23.json) cuenta **297,910 voicings de guitarra**, **7,795 de bajo** y **7,342 de ukelele**, con un total de **313,047**. Las instantáneas de QA del chatbot del [15 de junio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) y del [19 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json) informan un **75% de 52 preguntas** y un **98.08% de 52 preguntas**. Son tareas de comparación diferentes: comparar *recuentos entre instrumentos* y comparar *tasas publicadas entre fechas*. Una única colección de círculos haría que ambas parecieran «más grande frente a más pequeño», ocultando sus unidades.

Decida qué necesita juzgar el lector. Para el corpus de voicings, la pregunta es «¿Qué tamaño tiene cada cohorte de instrumentos y cuánto más pequeñas son las de bajo y ukelele que la de guitarra?». Para QA, la pregunta es «¿Qué tasa publicada corresponde a cada fecha?». Los archivos de QA no identifican preguntas individuales ni revisiones del evaluador, por lo que la diferencia de tasas no permite establecer una mejora sobre un conjunto de prueba emparejado. Ninguno de los registros describe el servicio actual ni la experiencia de los usuarios.

### Ejercicio práctico 1: nombrar la tarea

Un diseñador propone un único gráfico de burbujas con cinco burbujas: tres recuentos de instrumentos y dos porcentajes de QA. Nombre dos problemas y luego escriba las dos preguntas de comparación con sus unidades.

> **Respuesta:** Las burbujas mezclan recuentos de voicings con porcentajes, que tienen unidades distintas; el área de los círculos también dificulta leer comparaciones cercanas más que una escala numérica compartida. Compare los **voicings por instrumento** de guitarra, bajo y ukelele de la auditoría del 23 de julio. Por separado, compare el **porcentaje publicado de aprobaciones sobre 52 preguntas de QA** del 15 de junio y del 19 de julio. Esta última es una comparación descriptiva fechada, no una afirmación de mejora en preguntas emparejadas.

## 1. Posición en una escala compartida

Para valores cercanos, coloque las marcas en sus posiciones numéricas sobre una misma escala etiquetada. Un gráfico de puntos de las dos tasas de QA puede colocar puntos en 75 y 98.08 sobre un eje del 0–100%. La distancia horizontal representa **23.08 puntos porcentuales**. Si una vista de detalle empieza en 70%, etiquete claramente ese eje y el intervalo omitido; una escala de posición ampliada puede ayudar a inspeccionar la diferencia, pero no debe convertir los valores en longitudes de barras medidas desde 70.

Muestre `June 15: 75% (52 prompts)` y `July 19: 98.08% (52 prompts)` como etiquetas directas. Que el denominador no cambie no prueba que las preguntas no hayan cambiado. [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/) analiza las pruebas que faltan sobre el emparejamiento de la población. No dibuje una flecha sin matices de «mejoró la calidad» entre los dos puntos.

### Ejercicio práctico 2: leer el eje

Un gráfico de puntos de QA coloca 75 y 98.08 en un eje porcentual compartido. Calcule su diferencia en puntos porcentuales. ¿Qué tendría que indicar el pie de un eje de detalle del 70–100% y qué conclusión seguiría sin estar disponible?

> **Respuesta:** `98.08 - 75 = 23.08` puntos porcentuales. El pie debe decir que el eje de posición mostrado empieza en 70% y mostrar ambos valores y fechas; de lo contrario, la distancia visual puede confundirse con un intervalo completo del 0–100%. Los registros no establecen que las mismas preguntas y el mismo evaluador produjeran ambas tasas, por lo que sigue sin poder concluirse una mejora en pruebas emparejadas.

## 2. Longitud desde un origen común

Cuando el lector necesita comparar tamaños de cohortes, las barras horizontales pueden codificar los recuentos mediante su longitud. Empiece cada una en **cero**, use una sola escala lineal e imprima el recuento exacto en su extremo. En una composición donde la barra de guitarra mida 100 unidades, la barra de bajo debería medir unas **2.62** unidades y la de ukelele unas **2.46** unidades. Esas longitudes pequeñas son una consecuencia fiel del desequilibrio del corpus, no un error de diseño. Ofrezca una tabla o un acercamiento de los dos grupos pequeños si el lector también necesita distinguir 7,795 de 7,342; conserve la vista general original y etiquete claramente la escala de cualquier acercamiento.

La guitarra tiene aproximadamente **38.22 veces** tantos voicings auditados como el bajo (`297,910 / 7,795`). Una barra recortada en 7,000 codificaría el bajo con solo 795 unidades visibles y el ukelele con 342, exagerando falsamente su diferencia. Si un gráfico con origen en cero resulta poco manejable, use un gráfico de puntos etiquetado o paneles separados de vista general y detalle en lugar de ocultar la línea de base. [DV-003](../../data-visualization/dv-003-instrument-cohorts-and-units/) explica por qué estos tamaños de corpus no miden la corrección musical por instrumento.

### Ejercicio práctico 3: comprobar la geometría de las barras

Si la barra de guitarra, con un recuento de 297,910, se dibuja con una longitud de 100 unidades, calcule las longitudes de las barras de bajo y ukelele con dos decimales. ¿Debería el gráfico acortar ambas barras restando 7,000 antes de dibujarlas?

> **Respuesta:** El bajo mide `100 × 7,795 / 297,910 = 2.62` unidades; el ukelele mide `100 × 7,342 / 297,910 = 2.46` unidades. No. Restar 7,000 a las longitudes cambiaría lo que codifican las barras. Conserve las longitudes con origen en cero y las etiquetas exactas; use una vista de detalle etiquetada explícitamente si la tarea es comparar la diferencia de 453 voicings entre bajo y ukelele.

## 3. El área es una codificación diferente

Los círculos pueden representar recuentos cuando sus **áreas** son proporcionales a los valores. El área de un círculo es `π × radius²`. Para los recuentos de guitarra y bajo, la razón de áreas deseada es `297,910 / 7,795 ≈ 38.22`; por tanto, su razón de radios debe ser `√38.22 ≈ 6.18`. Si alguien hace que el radio de guitarra sea 38.22 veces el de bajo, su área pasa a ser unas **1,460.77 veces** la del bajo (`38.22² = 1460.7684`). Esa geometría exagera mucho la razón de recuentos registrada.

Incluso los círculos con tamaños correctos exigen más estimación mental que comparar marcas en una escala compartida. Resérvelos para una tarea en la que importe una magnitud aproximada o la ubicación espacial, mantenga cerca las cifras exactas y proporcione una tabla accesible. Evite dimensionar círculos con porcentajes de QA junto a recuentos de voicings: una razón de áreas entre unidades distintas no tiene una interpretación útil.

### Ejercicio práctico 4: probar las burbujas

Un borrador dimensiona los **radios** de los círculos de guitarra y bajo en una razón de 38.22:1 y etiqueta el resultado como «38.22 veces tantos voicings». ¿Qué razón de áreas verían los lectores? ¿Qué razón de radios conservaría la razón de recuentos?

> **Respuesta:** El área crece con el cuadrado del radio, por lo que `38.22² ≈ 1,461:1` (unas 1,460.62 usando la razón de recuentos sin redondear). Para mostrar aproximadamente 38.22:1 mediante el área, use una razón de radios de `√38.22 ≈ 6.18:1`. Un gráfico de barras con escala común es más fácil de auditar para esta comparación exacta de cohortes.

## 4. Revisar la comparación y luego la afirmación

Un panel compacto de GA puede mostrar tres barras de recuento con origen en cero y etiquetas exactas, una vista separada de QA con dos puntos fechados y una pequeña tabla de fuentes. Sitúe **voicings** junto a la primera escala y **porcentaje de 52 preguntas** junto a la segunda. Indique que todos los valores proceden de instantáneas históricas en la revisión fijada. El recuento de voicings es el tamaño de un corpus auditado, no una población de usuarios; las tasas de QA son resúmenes de ejecuciones con emparejamiento no verificado de preguntas y evaluador. El panel debe enlazar cada cifra con su fuente y seguir siendo legible sin color.

Antes de aprobar un gráfico, pregunte: ¿Tienen los valores la misma unidad? ¿Es la geometría visual proporcional a la cantidad prevista? ¿Se adapta la escala a la tarea de comparación? ¿Indica el pie las fechas de observación y el límite de las pruebas? Un gráfico visualmente claro aún puede respaldar una afirmación falsa si su pie confunde proporción del corpus, calidad de los nombres y tasa de aprobación de QA.

### Ejercicio práctico 5: corregir el pie de un panel

Revise: «La calidad de GA creció del 75% al 98.08%; la guitarra es 38 veces mejor que el bajo, como muestra la gran burbuja». Sustitúyalo por un pie de dos oraciones que conserve las dos tareas, las fechas, los denominadores y las limitaciones más fuertes.

> **Respuesta:** «En la revisión de GA `dc2e74c`, la auditoría de voicings del 23 de julio de 2026 contó 297,910 voicings de guitarra, 7,795 de bajo y 7,342 de ukelele; son tamaños de corpus, no puntuaciones de calidad de instrumentos. Por separado, las instantáneas de QA del chatbot publicaron un 75% de 52 preguntas el 15 de junio y un 98.08% de 52 el 19 de julio, pero los archivos no establecen identidades de preguntas emparejadas ni revisiones del evaluador, por lo que la diferencia es descriptiva y no una mejora verificada».

## Ideas clave

- Elija la codificación según la tarea de comparación y la unidad: posición compartida para tasas precisas, longitud con origen común para recuentos y área solo cuando la magnitud aproximada se adapte a la tarea.
- La longitud de una barra necesita un cero compartido; la posición de un punto puede usar una escala de detalle etiquetada explícitamente.
- Para los círculos, un valor proporcional al **área** implica un radio proporcional a la raíz cuadrada del valor.
- Imprima fechas, recuentos, denominadores y enlaces a fuentes para que la comparación visible no exagere las pruebas.

## Pruebas del proyecto y limitaciones

- Las instantáneas fijadas de GA de la [auditoría de voicings del 23 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/voicing-analysis/2026-07-23.json), el [QA del 15 de junio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) y el [QA del 19 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json) aportan los valores del ejemplo. Los ejemplos de longitud y radio son cálculos didácticos a partir de esos campos, no mediciones emitidas por GA.
- Las instantáneas no establecen usuarios representativos, calidad de voicings revisada de forma independiente, preguntas de QA emparejadas ni la revisión del evaluador de QA. Esta lección no ha pasado por revisión temática humana, prueba con un estudiante, revisión por una persona con dominio del idioma ni comprobación de lectura pública en Learn.

*Investigación: `data-visualization-2026-10-11-006`. Solo borrador de traducción; revisión y publicación pendientes.*
