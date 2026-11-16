---
module_id: dv-007-optick-partition-small-multiples
department: data-visualization
course: Pequeños múltiplos para diagnosticar las particiones de OPTIC-K
level: intermediate
prerequisites: [dv-001-observed-degraded-stale-quality, dv-006-position-length-area-comparisons]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: data-visualization-2026-10-11-007
version: "0.1.0"
---

# Pequeños múltiplos para diagnosticar las particiones de OPTIC-K

> **Departamento de Visualización de Datos** | Nivel: intermedio | Duración estimada: 35 minutos | Estado: borrador de traducción; pendientes la revisión temática humana, la revisión por una persona con dominio del idioma, la prueba con un estudiante y la revisión de publicación

Datos para los ejercicios sin conexión: [seis instantáneas GA fijadas](../../../../code/streeling/fixtures/data-visualization/historical-ga/README.md). Son datos históricos; no se evalúa el comportamiento actual del servicio.

## Objetivos

Al terminar esta lección, usted podrá:

- decidir cuándo los pequeños múltiplos ayudan a comparar la **misma medida diagnóstica** entre particiones de OPTIC-K;
- mantener fijas las escalas, la referencia, la muestra y el clasificador entre paneles, etiquetando a la vez la función y la dimensión de cada partición;
- distinguir los desplazamientos del vector compacto de un diagnóstico de los desplazamientos del vector bruto del esquema;
- explicar por qué la capacidad de predecir el instrumento no prueba la invariancia por transposición ni la calidad de la recuperación musical.

## La pregunta del proyecto

Un ingeniero de GA quiere inspeccionar la información sobre instrumentos en el embedding de OPTIC-K. En la revisión fijada de GA [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924), el [diagnóstico de embeddings del 25 de junio de 2026](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embeddings/2026-06-25.json) registra la precisión de un clasificador para predecir instrumentos a partir de seis particiones. ¿Debe un panel mostrar un gráfico de barras ordenadas por «calidad de partición», seis pequeños gráficos o una sola puntuación global?

Elija **seis pequeños múltiplos alineados** para esta comparación concreta: un panel por partición probada, cada uno mostrando la misma precisión de clasificación de instrumentos en una escala del 0–100%, con la **referencia de azar del 33.33% para tres clases equilibradas** repetida. El diagnóstico fijado tomó una muestra de 12,000 elementos, 4,000 por instrumento, usó cinco pliegues y especifica un bosque aleatorio de 30 árboles con profundidad máxima de 10. Estos campos metodológicos deben figurar en el pie común. Cada panel necesita el nombre de la partición, su dimensión, la función en el esquema, la media observada y las etiquetas propias de hipótesis/estado del diagnóstico. Una tabla debe aportar los valores exactos.

El [registro canónico `EmbeddingSchema.cs`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs) declara `Version = OPTIC-K-v1.8` y `TotalDimension = 240`. Sus particiones de similitud incluyen STRUCTURE, MORPHOLOGY, CONTEXT, SYMBOLIC, MODAL y ROOT. Por eso estos seis paneles forman un conjunto coherente. Es un diagnóstico histórico de un índice fijo, no el estado actual de los embeddings.

### Ejercicio práctico 1: elegir el conjunto de paneles

¿Por qué son preferibles aquí seis paneles a una sola puntuación de «calidad del embedding»? ¿Deben IDENTITY, SPECTRAL y HIERARCHY recibir paneles de precisión vacíos?

> **Respuesta:** Las seis particiones de similitud probadas tienen la misma medida de clasificación de instrumentos, por lo que los paneles repetidos permiten una comparación con la misma unidad y conservan la función distinta de cada partición. Una sola puntuación de calidad combinaría interpretaciones diferentes. IDENTITY tiene la función de filtro estricto, y SPECTRAL y HIERARCHY tienen funciones informativas en el registro canónico; el diagnóstico fijado no aporta filas del clasificador para ellas. No invente paneles de precisión cero. Enumérelas por separado como «no medidas en este diagnóstico» si debe mostrarse el esquema completo.

## 1. Fijar la regla y mostrar las cifras

Dé a los seis paneles el mismo eje horizontal del 0–100%. Sitúe una línea de referencia en el nivel aleatorio registrado, **33.33%**, y un punto en cada precisión media. No ajuste automáticamente un panel al 30–40% y otro al 85–95%: haría que una pequeña diferencia alrededor del azar pareciera tan grande como la diferencia entre el azar y el 90%. Use una etiqueta numérica directa, no un código de «fuga» basado solo en color. Los cinco valores registrados de los pliegues podrían aparecer como pequeñas marcas secundarias, pero son pliegues de una ejecución, no cinco despliegues independientes ni un intervalo de confianza.

[DV-006](dv-006-position-length-area-comparisons.md) introduce la decisión de comparar mediante una escala compartida; aquí los paneles repetidos la aplican a una sola medida diagnóstica.

| Panel | Posiciones brutas en el esquema | Función | Media del diagnóstico | Etiqueta del diagnóstico |
|---|---:|---|---:|---|
| STRUCTURE | 6–29 (24 dimensiones) | Similitud | 50.20% | `likely_leak`; confirmada |
| MORPHOLOGY | 30–53 (24 dimensiones) | Similitud | 90.32% | `by_design`; no confirmada como fuga |
| CONTEXT | 54–65 (12 dimensiones) | Similitud | 33.33% | `possible`; no confirmada |
| SYMBOLIC | 66–77 (12 dimensiones) | Similitud | 53.74% | `likely_leak`; confirmada |
| MODAL | 109–148 (40 dimensiones) | Similitud | 48.70% | `possible`; confirmada |
| ROOT | 228–239 (12 dimensiones) | Similitud | 34.98% | `by_design`; no confirmada como fuga |

Los porcentajes anteriores son los valores `accuracy_mean` de la instantánea redondeados a dos decimales. Las notas de la instantánea llaman a una precisión superior a **0.40**, en su problema equilibrado de tres clases, un criterio de «fuga confirmada», pero importan las etiquetas `by_design`: MORPHOLOGY está ligada físicamente a un instrumento, por lo que su 90.32% no debe convertirse en el panel de fallo más rojo. Muestre como texto los campos registrados `leak_hypothesis` y `leak_confirmed` del diagnóstico en lugar de reconstruir una alarma solo a partir de la precisión.

### Ejercicio práctico 2: usar la referencia compartida

¿Cuántos puntos porcentuales por encima de la referencia de azar mostrada del 33.33% están STRUCTURE y CONTEXT? ¿Ayudaría a esta comparación un eje vertical separado para cada panel?

> **Respuesta:** STRUCTURE está `50.20 - 33.33 = 16.87` puntos porcentuales por encima de la referencia mostrada. CONTEXT está `33.33 - 33.33 = 0.00` puntos porcentuales por encima con la precisión mostrada. Los ejes separados con ajuste automático ocultarían la magnitud común; use la misma escala del 0–100% y etiquete ambos valores. Esta aritmética describe el diagnóstico fijado del clasificador, no una prueba de significación estadística.

## 2. Separar la medición de la interpretación

Cada panel responde **con qué precisión este clasificador concreto predijo el instrumento a partir del vector de esta partición**. No responde si la partición es «buena». Se espera que una partición de realización física como MORPHOLOGY conserve información del instrumento. El 50.20% de STRUCTURE y el 53.74% de SYMBOLIC están marcados como fugas confirmadas por el diagnóstico registrado; son pistas para investigar bajo su criterio. Las seis particiones también tienen dimensiones y significados distintos, por lo que este gráfico no permite atribuir las diferencias de precisión a un único mecanismo causal. El 83.11% de `full_classifier_accuracy` es un resultado separado del vector completo, no una séptima partición para ordenar junto a estos paneles.

Use anotaciones en los paneles para la función y la hipótesis registrada, quizá agrupadas con un separador fino entre interpretaciones de «por diseño» e «investigar». Mantenga igual la escala de posición numérica. El color puede reforzar el texto, pero no debe ser la única manera de identificar un estado diagnóstico. Ponga la fecha y el método en un solo pie común para evitar repetirlos tanto que resten espacio a los datos.

### Ejercicio práctico 3: rechazar una clasificación falsa

Una persona revisora dice: «MORPHOLOGY es la peor partición con un 90.32%, mientras que CONTEXT es la mejor con un 33.33%». Corrija la afirmación usando la función del esquema y los campos del diagnóstico.

> **Respuesta:** Las medias ordenan la capacidad de este clasificador para deducir el instrumento, no la calidad de las particiones. MORPHOLOGY representa la realización física y está etiquetada `by_design` con `leak_confirmed: false` en el artefacto fijado; allí se espera una alta capacidad de predecir el instrumento. CONTEXT está cerca de la referencia de azar registrada y lleva la etiqueta `possible` con `leak_confirmed: false`, pero eso por sí solo no establece una codificación útil del contexto ni el rendimiento de recuperación.

## 3. Etiquetar qué sistema de coordenadas está leyendo el usuario

El vector bruto del esquema canónico tiene **240 dimensiones**. Sitúa STRUCTURE en las posiciones brutas **6–29** y ROOT en **228–239**. El diagnóstico de junio describe un índice con `corpus.dims: 124` e informa las coordenadas compactas `start: 0`, `end: 24`, `dims: 24` para STRUCTURE; ROOT aparece en `start: 112`, `end: 124`, `dims: 12`. Esos valores de `end` son exclusivos según la aritmética registrada de `start`, `end` y `dims`. Las particiones de similitud del esquema se empaquetan en la vista compacta de 124 dimensiones, omitiendo las particiones de identidad e informativas. Etiquete explícitamente las coordenadas brutas y compactas. De lo contrario, un lector podría confundir dos sistemas de coordenadas válidos con una deriva del esquema.

No ponga índices de posiciones brutas en el eje de precisión del diagnóstico: una posición de vector no es ni un porcentaje ni una puntuación. Si la lección necesita una vista de distribución, use una franja separada con intervalos brutos y funciones; conserve los seis paneles porcentuales alineados del diagnóstico para los resultados del clasificador.

### Ejercicio práctico 4: relacionar los desplazamientos

El diagnóstico dice `STRUCTURE start=0, end=24, dims=24`, mientras que el esquema dice posiciones brutas 6–29. ¿Eso prueba que el diagnóstico usó la partición equivocada? ¿Cuál sería el intervalo compacto de ROOT?

> **Respuesta:** No. El diagnóstico describe el índice compacto de 124 dimensiones, cuyo intervalo de STRUCTURE es `[0,24)`; el intervalo bruto de STRUCTURE en el esquema ocupa las posiciones 6 a 29. El intervalo de ROOT en el diagnóstico es `[112,124)` para 12 dimensiones, mientras su intervalo bruto ocupa las posiciones 228 a 239. Indique el sistema de coordenadas y la convención del extremo final junto a cada distribución antes de comparar desplazamientos.

## 4. Conservar el límite de la afirmación

El esquema dice que ROOT se separó en v1.8 para que STRUCTURE coincidiera entre **voicings del mismo conjunto de clases de altura**, con independencia de la octava, el voicing o el instrumento. También advierte que STRUCTURE en su conjunto contiene croma de clases de altura y **no es invariante por transposición**; solo sus subdimensiones de ICV y cardinalidad tienen esa propiedad. La precisión de clasificación de instrumentos no prueba ninguna de las dos afirmaciones de invariancia. Un resultado diagnóstico fijado separado informa un promedio de coincidencia de conjuntos de clases de altura del 100% entre los diez primeros resultados de 50 consultas probadas, pero esa medida de recuperación corresponde a otra tarea y muestra. Si se muestra, necesita su propio panel o tabla y denominador, no un séptimo punto en la escala de precisión.

El [informe de calidad del 23 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/quality/README.md) marca como obsoletas sus cinco fuentes seguidas de particiones de embeddings: su última observación real fue el 25 de junio, 28 días antes del informe. El valor separado de ROOT está fechado el 25 de junio por la instantánea fijada del diagnóstico, no por una fuente de ROOT de ese informe. Un gráfico de pequeños múltiplos puede representar fielmente el 25 de junio y aun así no servir como estado operativo actual. Feche la visualización según la observación de origen y enlace tanto la instantánea fuente como la revisión del esquema.

[DV-001](dv-001-observed-degraded-stale-quality.md) explica por qué una observación histórica y un estado operativo actual requieren pies distintos.

### Ejercicio práctico 5: escribir el pie del panel

Escriba dos oraciones para el gráfico de seis paneles. Incluya la fecha fijada, la medida, la referencia y un límite de interpretación. Corrija esta afirmación propuesta: «La baja fuga de ROOT prueba que STRUCTURE es invariante por transposición y que el índice en vivo está sano».

> **Respuesta:** «En el diagnóstico de embeddings de GA del 25 de junio de 2026, en la revisión `dc2e74c`, seis paneles alineados muestran la precisión media de clasificación de instrumentos por partición de similitud sobre un eje compartido del 0–100%, con una referencia de azar del 33.33% para tres clases equilibradas. La función y las etiquetas de fuga del diagnóstico matizan esos porcentajes y este no prueba la invariancia por transposición; el informe del 23 de julio marca cinco fuentes seguidas de particiones como obsoletas, mientras que ROOT está fechado por el propio diagnóstico, por lo que el gráfico no puede establecer la salud actual del índice».

## Ideas clave

- Los pequeños múltiplos funcionan aquí porque los seis paneles comparten una medida diagnóstica y una escala.
- Conserve la función, las dimensiones y la interpretación registrada de cada partición junto a su cifra.
- Las coordenadas del esquema bruto de 240 dimensiones y las del índice compacto de 124 dimensiones sirven para distribuciones diferentes.
- La capacidad de predecir instrumentos, la recuperación de conjuntos de clases de altura, la invariancia del mismo conjunto y la invariancia por transposición son preguntas distintas.
- Feche un artefacto fijo y exponga su obsolescencia antes de que los lectores actúen basándose en él.

## Pruebas del proyecto y limitaciones

- GA: [esquema canónico](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs), [diagnóstico de embeddings del 25 de junio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embeddings/2026-06-25.json) e [informe de calidad del 23 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/quality/README.md), fijados a la revisión indicada. El registro del esquema y las constantes de versión son la autoridad para esta lección; los comentarios de texto más antiguos de ese archivo aún describen distribuciones anteriores del esquema.
- La disposición de pequeños múltiplos es un diseño didáctico propuesto, no un panel publicado de GA. El diagnóstico es una sola ejecución fija con un clasificador, una muestra equilibrada y un índice concretos; no establece el comportamiento actual ni las fuentes causales de la información sobre instrumentos. Quedan pendientes la revisión temática humana, la prueba con un estudiante, la revisión por una persona con dominio del idioma y la comprobación de lectura pública en Learn.

*Investigación: `data-visualization-2026-10-11-007`. Solo borrador de traducción; revisión y publicación pendientes.*
