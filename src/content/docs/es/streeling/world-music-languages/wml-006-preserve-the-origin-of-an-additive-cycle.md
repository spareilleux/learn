---
title: Conservar el origen de un ciclo aditivo
description: Conservar el origen de un ciclo aditivo — Músicas y lenguas del mundo
sidebar:
  label: WML-006 · Conservar el origen de un ciclo aditivo
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/es/wml-006-preserve-the-origin-of-an-additive-cycle.es.md
---

:::note[Streeling University]
**WML-006** · Conservar el origen de un ciclo aditivo · intermedio · 40 minutos

Generado por el departamento *Músicas y lenguas del mundo* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/es/wml-006-preserve-the-origin-of-an-additive-cycle.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-003](../../world-music-languages/wml-003-term-preservation-and-cultural-review/), [MCL-006](../../musicology/mcl-006-preserve-meter-grouping-and-tempo-units/)
:::

> **Alcance del borrador.** Grupos de pulsos creados para el curso, enumeración finita exacta y lectura de especificaciones y código primarios. Quedan pendientes las revisiones humanas técnica, cultural, musical, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se probaron una grabación, una tradición interpretada, un grupo de traducción ni una herramienta de audio.

## La pregunta del proyecto

Un ejercicio localizado de GA conserva los números de un ritmo aditivo, pero cambia qué grupo inicia el compás. ¿Ha conservado el patrón solicitado? Un patrón circular y una instrucción de práctica anclada responden a preguntas distintas. Esta lección ofrece a la persona revisora un testigo numérico del cambio sin afirmar que alguno de estos patrones inventados pertenezca a una cultura musical concreta.

[MCL-006](../../musicology/mcl-006-preserve-meter-grouping-and-tempo-units/) separa agrupación de duración total y unidades del metrónomo. La [referencia de time de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/time/) permite texto de numerador aditivo. No da permiso a un traductor para cambiar el inicio de un ejercicio didáctico ni atribuir su interpretación a una tradición.

## 1. Mantener unido el origen del compás

Define siete posiciones equidistantes de pulso de corchea, numeradas de 0 a 6, y repite el ciclo. En el patrón didáctico A, las longitudes de grupo son 2, 2, 3; los inicios son 0, 2, 4. El patrón B usa longitudes 3, 2, 2 e inicios 0, 3, 5. El patrón C usa longitudes 2, 3, 2 e inicios 0, 2, 5.

Los tres suman siete pulsos. En el origen fijo del compás solicitan inicios distintos. Estos inicios son marcadores matemáticos de agrupación, no observaciones de sonoridad, énfasis, sílabas ni temporización de un músico. Un traductor puede conservarlos adaptando la explicación del conteo, pero necesita una instrucción explícita antes de cambiar su origen.

### Ejercicio 1: localizar un cambio en la traducción

Un ejercicio fuente pide A y su traducción pide B, ambos desde la misma barra de compás. Indica los conjuntos de inicios y qué se conservó y cambió.

> **Respuesta:** A empieza en 0, 2, 4; B en 0, 3, 5. Se conservó el ciclo total de siete pulsos. Cambiaron los grupos ordenados y sus inicios anclados. La duración total igual no basta para llamar idéntica a la instrucción traducida.

## 2. Cambiar explícitamente el origen de un patrón circular

Conserva los eventos circulares de A, pero declara su antiguo pulso 4 como nuevo origen. Resta 4 de cada inicio antiguo y reduce módulo 7. Los nuevos inicios son 0, 3, 5, con distancias circulares sucesivas 3, 2, 2: esto es B. Cambiar el origen al antiguo pulso 2 da en cambio C.

Este cálculo explica una equivalencia concreta: los patrones tienen la misma secuencia circular de distancias salvo por una elección cíclica del inicio de grupo. No los hace intercambiables frente a una barra de compás, acompañamiento, letra u otra pista sin cambios. Conserva tanto la equivalencia elegida como la transformación de origen al comparar registros.

### Ejercicio 2: recuperar la transformación de origen

¿Qué inicio antiguo de grupo de A se convierte en el origen de B? Calcula el nuevo conjunto de inicios y explica después por qué aplicar silenciosamente esa transformación a una sola pista puede cambiar un arreglo.

> **Respuesta:** El antiguo pulso 4 se convierte en el origen. Restar 4 módulo 7 de 0, 2, 4 da 3, 5, 0, o inicios ordenados 0, 3, 5. Cambiar el origen de una sola pista cambia su alineación con pistas y referencias de compás cuyo origen no cambió. Una comparación circular no borra esa fase relativa.

## 3. Separar rotaciones de pulsos de elecciones de inicio de grupo

Hay siete desplazamientos enteros posibles de A en pulsos. Los siete dan conjuntos de inicios distintos. Solo tres incluyen el pulso 0 como inicio de grupo y corresponden a las tres elecciones de límite de grupo original. Desplazar A hacia delante en 1 da inicios 1, 3, 5: el ciclo sigue repitiéndose cada siete pulsos, pero su nuevo pulso 0 no es inicio de grupo.

El [registro de enumeración](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/meter-picking-2026-10-22/anchored-cycles.json) conserva los desplazamientos y los cambios de origen a inicios de grupo etiquetados por separado. Tratar «tres permutaciones cíclicas de la lista de grupos» como «las siete fases de pulso» confundiría dos conjuntos distintos de comparaciones.

### Ejercicio 3: contar las transformaciones correctas

¿Cuántos desplazamientos de pulso distintos tiene A? ¿Cuántos sitúan un inicio de grupo en el pulso 0? Indica los inicios después de desplazar hacia delante en 1.

> **Respuesta:** Hay siete desplazamientos distintos y tres incluyen un inicio de grupo en 0. El desplazamiento en 1 da inicios 1, 3, 5. Un nuevo origen no tiene por qué coincidir con un evento de agrupación salvo que se exija esa condición por separado.

## 4. Enunciar qué clasifica un código circular

Elige tres posiciones distintas de inicio entre las siete posiciones de pulso etiquetadas. La enumeración exacta da 35 conjuntos anclados. Compararlos identificando los que difieren solo en una rotación entera los divide en cinco clases, cada una con siete conjuntos. Es un resultado combinatorio finito para esta población didáctica. No es una distribución de ritmos de grabaciones ni una taxonomía de cinco tradiciones.

La restricción a tres inicios importa. Como controles negativos, un conjunto vacío y otro que contiene los siete pulsos tienen cada uno una sola rotación distinta. Por tanto, «todo patrón tiene siete fases distintas» es falso cuando cambia la población. Las etiquetas, multiplicidades de eventos, espaciado desigual o datos interpretativos más ricos también definirían otro problema de clasificación.

### Ejercicio 4: acotar la clasificación

Indica el número de conjuntos anclados de tres inicios y clases de rotación en esta población de siete pulsos. ¿Por qué el control de patrón vacío refuta una afirmación universal de siete fases y por qué las cinco clases no establecen una clasificación cultural?

> **Respuesta:** Hay 35 conjuntos anclados y cinco clases de siete. El patrón vacío no cambia con ningún desplazamiento y tiene una sola rotación distinta. Estas clases proceden de posiciones abstractas seleccionadas y una equivalencia elegida, no de pruebas sobre comunidades, repertorio, músicos ni práctica interpretativa.

## 5. Conservar notación y atribución por separado

La [representación de compás de GA de la revisión fijada](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L115-L138) conserva un numerador y denominador enteros; no conserva en esos campos la lista ordenada de grupos ni la transformación de origen de esta lección. El [analizador seleccionado](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L123-L138) también tiene el límite de texto aditivo tratado en MCL-006. Esto no demuestra que todos los subsistemas de GA carezcan de datos más ricos.

### Ejercicio 5: redactar un comprobante de localización

¿Qué debería conservar un registro de revisión cuando un traductor cambia intencionadamente A por B? ¿Puede un código circular coincidente autorizar una atribución cultural concreta o una afirmación de equivalencia musical?

> **Respuesta:** Conserva los grupos ordenados originales y traducidos, unidad de pulso, referencia común de compás, transformación de origen antiguo a nuevo, pistas afectadas, motivo y decisión de revisión. El ejemplo de A a B cambia el origen al antiguo pulso 4. La igualdad circular por sí sola no autoriza ninguna afirmación cultural, perceptiva ni de equivalencia de arreglo. Esas afirmaciones necesitan pruebas adecuadas de repertorio, músicos e idioma; aquí no se recogió ninguna.

La [tarea preparada del estudiante](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/meter-picking-2026-10-22/learner-task.md) pide una comparación explícita de origen. Su existencia no es un resultado observado de estudiantes ni de revisión cultural.
