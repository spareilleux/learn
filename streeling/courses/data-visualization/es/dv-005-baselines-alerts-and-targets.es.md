---
module_id: dv-005-baselines-alerts-and-targets
department: data-visualization
course: Referencias, umbrales de alerta y objetivos históricos
level: beginner
prerequisites: [dv-001-observed-degraded-stale-quality, dv-004-uncertainty-in-small-qa-suites]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: data-visualization-2026-10-11-005
version: "0.1.0"
---

# Referencias, umbrales de alerta y objetivos históricos

> **Departamento de Visualización de Datos** | Nivel: principiante | Duración estimada: 30 minutos | Estado: borrador de traducción; pendientes la revisión temática humana, la revisión por una persona con dominio del idioma y la prueba con un estudiante

Datos para los ejercicios sin conexión: [seis instantáneas GA fijadas](../../../../code/streeling/fixtures/data-visualization/historical-ga/README.md). Son datos históricos; no se evalúa el comportamiento actual del servicio.

## Objetivos

Al terminar esta lección, usted podrá:

- identificar una medición de referencia, un umbral de alerta y un objetivo de aceptación sin tratarlos como la misma decisión;
- leer el informe histórico de calidad de GA sin convertir la ausencia de una alerta de regresión en una afirmación de mejora;
- explicar por qué una señal de deriva y una señal de regresión actual pueden discrepar;
- escribir un pie de gráfico que conserve la fecha, la comparación, la disponibilidad de los datos y sus límites.

## La pregunta del proyecto

Un panel de GA necesita una sola frase sobre el QA del chatbot. Su [informe histórico de tendencias de calidad en la revisión de GA `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/quality/README.md) dice que la tasa de aprobación más reciente es del **98.08%**, su media de siete días es del **98.08%**, **no se señala ninguna regresión** y se detectó una **deriva** alrededor del 15 de junio de 2026. ¿Cuál de estos datos respalda la afirmación de que el chatbot cumple actualmente un objetivo del producto?

Ninguno por sí solo. El informe es un artefacto histórico generado el 23 de julio de 2026; su medición de QA del chatbot más reciente procede de la instantánea del 19 de julio. No establece un objetivo de aceptación del producto y su propia fila de detalle contiene observaciones degradadas. Empiece por [DV-001](dv-001-observed-degraded-stale-quality.md) para distinguir observaciones reales de fuentes degradadas u obsoletas, y por [DV-004](dv-004-uncertainty-in-small-qa-suites.md) para la resolución de la batería de QA de 52 preguntas. No use este informe como estado actual del servicio.

### Ejercicio práctico 1: nombrar las tres funciones

Para cada elemento, escriba *referencia*, *regla de alerta* u *objetivo de aceptación*: (a) la media de siete días del informe, (b) el umbral de regresión predeterminado del generador del informe, del 5.0%, (c) «Al menos el 95% de una batería de preguntas identificada y estable debe aprobar antes del lanzamiento», una regla hipotética del equipo. ¿Qué elemento falta en el informe histórico?

> **Respuesta:** (a) es una referencia móvil, (b) es una regla de alerta que compara mediciones y (c) es un objetivo de aceptación hipotético. El informe contiene (a) y (b), pero ningún objetivo del producto establecido como (c). Un equipo tendría que aprobar y registrar esa regla por separado, incluidos su batería de pruebas y método de evaluación.

## 1. Una referencia es una comparación, no una promesa

El archivo fijado de GA [`state/quality/README.md`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/README.md) describe la opción `--baseline YYYY-MM-DD` del generador de tendencias como un **marcador informativo**. El informe generado también tiene medias móviles de siete días y 30 días. Son usos distintos de «referencia»: una fecha histórica identificada y una referencia móvil calculada. Ninguna es un resultado mínimo aceptable.

El titular del chatbot del informe muestra un valor más reciente de 98.08% y una media de siete días de 98.08%. Su diferencia mostrada es cero. Esa aritmética explica por qué no tiene que activarse una alerta basada en un cambio desfavorable respecto a la media mostrada. No prueba que el conjunto de preguntas, el evaluador o el backend permanecieran fijos, ni establece que el 98.08% sea suficientemente bueno para los usuarios. Los archivos del [15 de junio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) y del [19 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json) indican 52 preguntas, pero no proporcionan identificadores estables de preguntas ni una revisión del evaluador. Los denominadores iguales no bastan para establecer una población emparejada; véase [DV-002](dv-002-denominators-and-test-populations.md).

### Ejercicio práctico 2: leer la línea sin alerta

El informe dice «Ninguna. Todas las métricas seguidas están dentro del umbral respecto a su media de 7 días» bajo regresiones, mientras el titular del chatbot indica 98.08% tanto para el valor más reciente como para la media de siete días. Escriba la afirmación más sólida respaldada sobre el chatbot y una conclusión no respaldada.

> **Respuesta:** «En el informe generado el 23 de julio, la medición de QA del chatbot más reciente es del 19 de julio; su tasa de aprobación mostrada iguala la media mostrada de siete días, al 98.08%, y no se señala ninguna regresión». «El chatbot cumple ahora un objetivo del producto del 98%» carece de respaldo: el informe no tiene ese objetivo, la observación es histórica y las instantáneas de QA no establecen resultados actuales para los usuarios.

## 2. Una regla de alerta hace una pregunta más limitada

Las instrucciones fijadas del archivo histórico indican que `ix-quality-trend` usa por defecto un umbral de regresión del 5.0% respecto a una media de siete días. El informe describe cambios en dirección desfavorable y considera mejores las tasas de aprobación más altas. La regla de alerta pregunta si un cambio medido cruza su comparador y umbral configurados. No decide si todo el servicio está sano, si debe lanzarse una versión ni por qué cambió una métrica. En un informe nuevo, conserve la unidad exacta del umbral y la revisión del generador antes de calcular un caso límite; «cambio relativo del 5%» y «cinco puntos porcentuales» son distintos.

El mismo informe enumera una señal de deriva del chatbot «desde 2026-06-15» mientras su lista actual de regresiones está vacía. Su metodología menciona la detección de deriva Page–Hinkley sobre niveles de métricas ajustados por dirección. La detección de deriva pregunta por un patrón o punto de cambio en una serie; la regla de regresión pregunta por una comparación más reciente frente a una media reciente. Son pruebas distintas con ventanas distintas. Una señal histórica de deriva no prueba una regresión actual, y una lista actual de regresiones vacía no borra un cambio anterior de la serie registrada.

### Ejercicio práctico 3: conciliar dos indicadores

Un colega dice: «El informe es contradictorio: señala una deriva del chatbot pero dice que no hay regresión». Corrija la frase sin inventar una causa de la deriva.

> **Respuesta:** «Los dos indicadores responden a preguntas distintas. La regla actual de regresión no encontró un cambio desfavorable que superara su umbral respecto a la referencia de siete días; el detector de deriva marcó un cambio en la serie alrededor del 15 de junio. Inspeccione las observaciones fechadas subyacentes, los registros degradados y la versión del generador antes de explicar ese cambio». El informe por sí solo no identifica un cambio causal en las preguntas, el modelo o el código.

## 3. La disponibilidad y la cobertura limitan ambas comparaciones

El informe histórico enumera 35 archivos cargados de instantáneas de QA del chatbot. Su fila de detalle de la tasa global de aprobación del chatbot muestra `n = 26` y `n_degraded = 23`. Estas cifras tienen alcances distintos: «archivos cargados» cubre la categoría de instantáneas, mientras que `n` y `n_degraded` describen esta serie de métricas representada. Veintitrés de los 26 puntos de esa fila llevan un marcador de degradación. No interprete silenciosamente el minigráfico como 26 evaluaciones independientes y sanas del chatbot.

Por separado, el informe marca varias fuentes de embeddings y topología como obsoletas, con su última observación real el 25 de junio, 28 días antes del informe. Un valor antiguo llamado «más reciente» aún puede tener una media y una comparación de umbral perfectamente formateadas. Marque la vigencia por métrica. Una observación ausente o degradada es un hueco en las pruebas, no una puntuación de fallo ni una aprobación. Un objetivo del producto también necesita una población de prueba acordada, puntuación estable, una regla de calidad de ejecución y un intervalo de fechas; de lo contrario, una comprobación de umbral puede parecer decisiva mientras responde a la pregunta equivocada.

### Ejercicio práctico 4: conservar el denominador

¿Qué puede calcular a partir de `n = 26` y `n_degraded = 23` en la fila del chatbot, y qué **no** puede deducir de ese cálculo? ¿Por qué no debería un pie decir «23 de 35 archivos de QA del chatbot estaban degradados»?

> **Respuesta:** La fila tiene `26 - 23 = 3` puntos sin marcador de degradación, y 23/26 puntos de la fila están marcados como degradados. El informe no establece que los tres puntos cubran todas las necesidades de los usuarios ni que los 35 archivos cargados contribuyeran todos a esta única métrica. «23 de 35 archivos» mezcla el recuento de archivos de la categoría con el de una serie de métricas.

## 4. Escribir el límite de decisión en el gráfico

En un panel de calidad, sitúe la fecha de observación y la población medida junto a la cifra e identifique por separado la fecha de generación del informe. Etiquete la referencia móvil como comparación. Etiquete un umbral como configuración de alerta y un objetivo de aceptación solo cuando un registro de decisión separado realmente lo defina. Muestre la deriva como un marcador distinto con su propia explicación. Enlace una fuente fechada y exponga el estado degradado u obsoleto cerca de los datos representados. Si falta la revisión exacta del corpus de preguntas o del evaluador, indíquelo en el texto de decisión en lugar de ocultarlo en un texto emergente.

### Ejercicio práctico 5: poner un pie al informe histórico

Escriba un pie de dos oraciones que una persona revisora del lanzamiento pueda usar para la fila fijada de QA del chatbot. Incluya tanto la fecha del informe, el 23 de julio, como la de observación, el 19 de julio, la tasa, el comparador, el resultado sin alerta, la deriva y la limitación más fuerte. No recomiende un lanzamiento basándose solo en este artefacto.

> **Respuesta:** «El informe de GA generado el 23 de julio de 2026 muestra la medición de QA del chatbot del 19 de julio al 98.08%, igual a la media mostrada de siete días; no se señala una regresión del valor más reciente frente a la media, mientras se marca una deriva alrededor del 15 de junio. La fila incluye 23 puntos degradados entre 26 puntos de la serie de métricas, y las instantáneas subyacentes no identifican preguntas emparejadas ni versiones del evaluador, por lo que este informe por sí solo no puede establecer un objetivo actual del producto ni una decisión de lanzamiento».

## Ideas clave

- Un marcador histórico, una media móvil, un umbral de alerta y un objetivo de lanzamiento sirven para decisiones distintas.
- «No se señala regresión» significa que una regla de alerta concreta no se activó; no es un veredicto general de calidad.
- La deriva y la regresión del valor más reciente frente a la media pueden discrepar legítimamente.
- Mantenga visibles los recuentos de la serie de métricas, los de archivos de categoría, la vigencia y el estado degradado.
- Un objetivo del producto necesita su propia población acordada, regla de puntuación, ventana temporal y responsable de la decisión.

## Pruebas del proyecto

- GA: [informe de calidad](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/quality/README.md), [instrucciones del archivo histórico](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/README.md) e instantáneas del [15 de junio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) / [19 de julio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json), fijados a la revisión indicada.
- El umbral del 5.0% es una configuración de alerta del generador descrita por las instrucciones fijadas del archivo histórico, no un objetivo documentado de lanzamiento de GA. El informe no fija la revisión exacta del generador IX; verifíquela antes de explicar un cálculo de alerta en un caso límite.

*Investigación: `data-visualization-2026-10-11-005`. Borrador de traducción; pendientes la revisión temática humana, la prueba con un estudiante, la revisión por una persona con dominio del idioma y la comprobación de lectura pública en Learn.*
