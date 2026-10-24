---
title: Comparar cohortes de instrumentos sin ocultar sus tamaños
description: Comparar cohortes de instrumentos sin ocultar sus tamaños — Visualización de datos
sidebar:
  label: DV-003 · Comparar cohortes de instrumentos sin ocultar sus tamaños
  order: 3
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-003-instrument-cohorts-and-units.es.md
---

:::note[Streeling University]
**DV-003** · Comparar cohortes de instrumentos sin ocultar sus tamaños · principiante · 30 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-003-instrument-cohorts-and-units.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/)
:::

> **Departamento de Visualización de Datos** | Nivel: principiante | Duración estimada: 30 minutos | Estado: borrador de traducción; pendientes la revisión temática humana, la revisión por una persona con dominio del idioma y la prueba con un estudiante

Datos para los ejercicios sin conexión: [seis instantáneas GA fijadas](https://github.com/spareilleux/learn/blob/main/code/streeling/fixtures/data-visualization/historical-ga/README.md). Son datos históricos; no se evalúa el comportamiento actual del servicio.

## Objetivos

Al terminar esta lección, usted podrá:

- informar los tamaños de los corpus de guitarra, bajo y ukelele sin ocultar los grupos más pequeños;
- identificar si una métrica cuenta disposiciones de notas (voicings), conjuntos de clases de altura o un representante por instrumento;
- explicar el alcance del resultado de consistencia entre instrumentos de GA sin convertirlo en una afirmación de calidad por instrumento;
- diseñar una comparación que distinga los resultados observados de las mediciones que GA no ha registrado.

## La pregunta del proyecto

La [instantánea de análisis de voicings de GA del 23 de julio de 2026](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/voicing-analysis/2026-07-23.json), fijada al commit [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924), informa un corpus de 313,047 voicings y una métrica de consistencia entre instrumentos del 100%. Una persona que consulta el panel pregunta: «¿Esto prueba que los acordes se nombran igual de bien en guitarra, bajo y ukelele?». La respuesta depende de qué cuenta cada cifra.

| Cohorte del corpus | Voicings | Proporción de todos los voicings |
|---|---:|---:|
| Guitarra | 297,910 | 95.16% |
| Bajo | 7,795 | 2.49% |
| Ukelele | 7,342 | 2.35% |
| **Total** | **313,047** | **100.00%** |

Son recuentos históricos de auditoría, no un catálogo en vivo ni una población de usuarios. Las proporciones se calculan a partir de los campos `Corpus` de la instantánea y se redondean a dos decimales.

### Ejercicio práctico

Compruebe el total y escriba un pie de gráfico que haga visible el desequilibrio.

> **Respuesta:** `297,910 + 7,795 + 7,342 = 313,047`. Un pie defendible es: «Auditoría histórica de voicings de GA: 313,047 voicings generados; la guitarra aporta el 95.16%, el bajo el 2.49% y el ukelele el 2.35%».

## 1. El recuento de una cohorte no es una tasa de error

Una cohorte es el grupo que se compara. Aquí la sección `Corpus` cuenta los voicings por instrumento. Un gráfico de barras puede comparar esos **tamaños**. No puede comparar la precisión musical de los nombres por instrumento, porque la instantánea no tiene una etiqueta de nombre correcto juzgada de forma independiente para cada voicing. El mismo archivo informa los valores globales `UnknownChordName.Count: 0` y `NullChordName.Count: 0`. Como los recuentos de los tres instrumentos dividen este corpus auditado en grupos exhaustivos, cero en total implica cero nombres nulos o desconocidos en cada cohorte de esta ejecución. No establece que cada nombre no nulo sea musicalmente correcto.

Si el gráfico usa un eje porcentual, diga si representa la proporción de todos los voicings o una tasa dentro de cada instrumento. «Bajo: 2.49%» es una proporción del corpus; «tasa de error de nombres del bajo: 2.49%» sería una afirmación inventada. Una cohorte pequeña también necesita su recuento bruto junto a cualquier tasa futura. Un solo error entre 7,342 voicings de ukelele movería su tasa más que un solo error entre 297,910 voicings de guitarra.

### Ejercicio práctico

Un panel etiqueta tres barras como «Calidad de guitarra 95.16%, calidad de bajo 2.49%, calidad de ukelele 2.35%». ¿Qué está mal y qué pueden mostrar legítimamente las barras?

> **Respuesta:** Las cifras son proporciones del corpus auditado, no puntuaciones de calidad. Cambie las etiquetas a «proporción de voicings» y muestre 297,910, 7,795 y 7,342. La auditoría respalda que no hubo nombres nulos o desconocidos en cada cohorte, pero una afirmación más amplia sobre corrección requiere etiquetas juzgadas de forma independiente.

## 2. La métrica de consistencia cuenta conjuntos compartidos

La misma instantánea indica `CrossInstrumentConsistency.SharedSets: 793` y `Consistent: 793`. Su valor del 100% corresponde a `793 / 793` **conjuntos de clases de altura compartidos**, no a `313,047 / 313,047` voicings. En la [implementación fijada de la auditoría](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Demos/VoicingAnalysisAudit/Program.cs), la auditoría conserva el primer nombre canónico de acorde encontrado por instrumento para una máscara de clases de altura, selecciona las máscaras vistas en al menos dos instrumentos y comprueba si coinciden esos nombres conservados. El código usa el nombre canónico cuando está disponible, porque el bajo de un acorde con barra específico de un voicing puede diferir legítimamente entre instrumentos.

Es una **comprobación de consistencia de nombres entre instrumentos para los representantes conservados** que resulta útil. Su alcance es menor que «todos los voicings se nombraron correctamente» o «los tres instrumentos tienen tasas de error iguales». Un gráfico no debe poner el numerador de 793 conjuntos sobre el denominador de 313,047 voicings. Además, el archivo no divide los 793 conjuntos en grupos de guitarra–bajo, guitarra–ukelele, bajo–ukelele o los tres juntos, por lo que no permite extraer tasas por pares.

### Ejercicio práctico

Evalúe el titular «El 100% de 313,047 voicings coincide en los tres instrumentos». Sustitúyalo por una afirmación respaldada.

> **Respuesta:** El titular cambia la unidad e implica que los tres instrumentos participan en todas las comparaciones. Una afirmación respaldada es: «La auditoría encontró nombres canónicos conservados coincidentes para los 793 conjuntos de clases de altura observados en al menos dos instrumentos». Añada que usa el primer nombre encontrado por instrumento y no mide todos los voicings por pares.

## 3. Dar al lector dos vistas y dos denominadores

Use una vista para la composición del corpus: una barra horizontal por instrumento, con recuentos exactos de voicings y sus proporciones. Use otra para la prueba de consistencia: «793 / 793 conjuntos de clases de altura compartidos consistentes (100%)». Sitúe la nota metodológica junto al segundo resultado, sin ocultarla en un texto emergente. Una tabla es una alternativa accesible para ambos gráficos.

Evite una única insignia verde de «calidad 100%». Mezclaría una comprobación de acuerdo por conjuntos con métricas de completitud por voicing y podría ocultar la diferencia de tamaño de 38 a 1 entre los corpus de guitarra y bajo. Las dos vistas responden a preguntas distintas: «¿Qué incluyó la auditoría?» y «¿Qué encontró esta comprobación de acuerdo concreta?». Ninguna dice lo fácil que es tocar un voicing ni si a un guitarrista le gusta su sonido.

### Ejercicio práctico

Escriba una alternativa textual de dos líneas para estas vistas. Incluya ambos denominadores y una limitación.

> **Respuesta:** «La auditoría histórica contiene 297,910 voicings de guitarra, 7,795 de bajo y 7,342 de ukelele. Los nombres conservados coinciden en 793 de 793 conjuntos de clases de altura vistos en al menos dos instrumentos; la instantánea no mide la corrección musical de los nombres por instrumento mediante una revisión independiente».

## 4. Diseñar la próxima medición útil

Para comparar con rigor la **corrección musical de los nombres** por instrumento, una evaluación futura registraría `instrument`, `voicing_id`, `pitch_class_mask`, `canonical_name`, una etiqueta de referencia revisada de forma independiente, un veredicto de coincidencia y la revisión de la auditoría/corpus para cada resultado evaluado. Después dividiría las discrepancias de cada instrumento entre su propio número de voicings **revisados**, no entre todos los generados, salvo que todos se hayan revisado. Informe la incertidumbre o, al menos, los recuentos exactos de las cohortes pequeñas. Para comparaciones emparejadas entre instrumentos, conserve todas las observaciones pertinentes en lugar de solo el primer nombre por máscara e instrumento; defina de antemano si la unidad es un voicing, un conjunto o un par de instrumentos.

Es un contrato de medición propuesto, no una afirmación de que GA ya emita esas etiquetas revisadas. Manténgalo separado de la instantánea histórica. Los recuentos globales de cero nombres nulos/desconocidos son útiles y sí se aplican a cada cohorte de esta partición exhaustiva; aun así, no prueban si un nombre no nulo es correcto ni si un voicing es tocable, útil o agradable al oído.

### Ejercicio práctico

Proponga un campo y un denominador necesarios para una tasa de **discrepancias en nombres musicales** específica del bajo. Indique una pregunta que esa tasa seguiría sin responder.

> **Respuesta:** Registre un nombre de referencia revisado y un veredicto de coincidencia para cada voicing de bajo evaluado; divida las discrepancias entre el número de **voicings de bajo revisados**. El corpus histórico tiene 7,795 voicings de bajo, pero ese solo es el denominador si los 7,795 reciben una revisión. La tasa de discrepancias no determinaría si los bajistas consideran las posiciones tocables o útiles.

## Ideas clave

- Muestre los tamaños de las cohortes de instrumentos antes de comparar resultados.
- Nombre la unidad de análisis junto a cada numerador y denominador.
- `793 / 793` conjuntos compartidos no es una tasa de precisión por voicing ni por instrumento.
- La auditoría conserva un nombre canónico por instrumento y máscara de clases de altura para esta comprobación de consistencia.
- Mantenga separados los recuentos deducidos de cero nombres nulos/desconocidos y la corrección musical de los nombres que no se ha medido.

## Lecturas y pruebas del proyecto

- GA: [instantánea histórica del análisis de voicings](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/voicing-analysis/2026-07-23.json) e [implementación fijada de la auditoría](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Demos/VoicingAnalysisAudit/Program.cs).
- [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/), sobre agregación ponderada y cambios de cohorte.

*Investigación: `data-visualization-2026-10-11-003`. Borrador de traducción; pendientes la revisión temática humana, la prueba con un estudiante, la revisión por una persona con dominio del idioma y la verificación pública.*
