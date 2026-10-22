---
title: Visualizar el código fuente, la revisión y la lectura pública de Streeling
description: Visualizar el código fuente, la revisión y la lectura pública de Streeling — Visualización de datos
sidebar:
  label: DV-008 · Visualizar el código fuente, la revisión y la lectura pública de Streeling
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-008-streeling-evidence-stage-map.es.md
---

:::note[Streeling University]
**DV-008** · Visualizar el código fuente, la revisión y la lectura pública de Streeling · intermedio · 35 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-008-streeling-evidence-stage-map.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-001](../../data-visualization/dv-001-observed-degraded-stale-quality/), [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/)
:::

> **Departamento de Visualización de Datos** | Nivel: intermedio | Duración estimada: 35 minutos | Estado: borrador de traducción; pendientes la revisión temática humana, la revisión por una persona con dominio del idioma y la prueba con un estudiante

Datos para los ejercicios sin conexión: [seis instantáneas GA fijadas](https://github.com/spareilleux/learn/blob/main/code/streeling/fixtures/data-visualization/historical-ga/README.md). Son datos históricos; no se evalúa el comportamiento actual del servicio.

## Objetivos

Al terminar esta lección, usted podrá:

- dibujar vías de pruebas separadas para un curso redactado, una revisión aprobada y una comprobación de lectura pública anónima;
- indicar el denominador y la revisión fuente de cada recuento sin convertir en cero una etapa pública no medida;
- mostrar cuándo una página pública y una revisión existen, pero no se refieren a la misma revisión fuente;
- reproducir una pequeña matriz sintética de pruebas y cuestionar un gráfico engañoso de finalización.

## La pregunta del proyecto

La meta de Streeling es contar con 25 cursos útiles para el proyecto, revisados y legibles públicamente en cada uno de los 21 departamentos con cursos: **525 códigos de cursos troncales distintos**. Una persona coordinadora pregunta: «¿Cuántos cursos están terminados?». Una sola barra de progreso ocultaría tres observaciones distintas. El código fuente actual de los cursos vive en Learn bajo `streeling/`; las observaciones históricas siguientes se capturaron cuando Demerzel alojaba ese código fuente. Una revisión humana debe aprobar el contenido pertinente, y Learn debe servir esa versión revisada de forma anónima. Son afirmaciones separadas con pruebas separadas.

En la revisión fijada de Demerzel [`8a37e1d`](https://github.com/GuitarAlchemist/Demerzel/tree/8a37e1d9a728a15ed384cbb912e3c8c518083d12/state/streeling), [`streeling_course_progress.py`](https://github.com/GuitarAlchemist/Demerzel/blob/8a37e1d9a728a15ed384cbb912e3c8c518083d12/scripts/streeling_course_progress.py) informa **120 códigos de cursos troncales**, **121 archivos fuente en inglés** y **cero registros de producción marcados con revisión aprobada**. El archivo adicional en inglés es CYB-026, opcional y fuera de los primeros 25 números troncales. El script examina el estado del repositorio; **no** consulta el sitio público de Learn ni establece la calidad temática. Esos recuentos describen esa revisión, no el catálogo de hoy.

El script separado [`streeling_public_readback.py`](https://github.com/GuitarAlchemist/Demerzel/blob/8a37e1d9a728a15ed384cbb912e3c8c518083d12/scripts/streeling_public_readback.py) acepta un SHA completo de Demerzel e identificadores de módulos. Obtiene anónimamente el índice de Streeling y las páginas de los módulos, y luego comprueba el estado HTTP 200, un enlace exacto al código fuente y el encabezado renderizado. Su resultado solo cubre las páginas y la revisión solicitadas; no certifica revisión humana ni aprendizaje. Como el informe fijado de progreso no contiene una comprobación exhaustiva de lectura pública, el **recuento público es desconocido** dentro de este límite probatorio. No lo dibuje como cero.

### Ejercicio práctico 1: etiquetar la referencia inicial

En la revisión fijada, ¿debería el titular del gráfico decir «121 de 525 terminados», «120 de 525 redactados» o «cero cursos publicados»? Dé el titular más defendible y un subtítulo.

> **Respuesta:** «120 de 525 códigos de cursos troncales tienen borradores fuente en inglés en la revisión de Demerzel `8a37e1d`». El archivo 121 en inglés es el opcional CYB-026. Un subtítulo debería decir: «0 aprobados en los registros de producción examinados en esa revisión; el recuento público exacto no está medido en este informe». Ni un archivo en inglés ni la ausencia de una medición pública prueban la finalización.

## 1. Hacer explícitas las vías de pruebas

Use una fila por código de curso y tres columnas alineadas. **Fuente** significa un archivo en inglés con un código troncal distinto; **revisión** significa un veredicto humano aplicable a esa versión exacta del curso; **público** significa una comprobación anónima de lectura correcta contra el mismo SHA fuente. Un booleano de un registro de producción es una señal de inventario útil, pero también deben inspeccionarse la persona revisora, el veredicto y el blob del contenido antes de afirmar que hay una revisión humana válida. Un HTTP 200 por sí solo solo dice que alguna página respondió.

Las [tarjetas sintéticas](https://github.com/spareilleux/learn/blob/main/code/streeling/fixtures/data-visualization/dv-008/scenarios.json) locales y el [evaluador](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/scripts/streeling_fixtures/data-visualization/dv-008/analyze.py) permiten ensayar esta disposición. El enlace del evaluador fija su implementación archivada; los tres archivos locales de datos de prueba conservan sus datos. Para reproducir ese modelo histórico de seis tarjetas, use un checkout de Demerzel en la revisión fuente archivada y ejecute desde su raíz:

```text
python -I -B scripts/streeling_fixtures/data-visualization/dv-008/analyze.py --check
```

Las seis tarjetas son estados de aula inventados, **no módulos observados de Streeling**. Todas tienen código fuente redactado. Las tarjetas A y B tienen revisión aprobada. A y F tienen una comprobación exacta de lectura pública. Solo A cumple las tres condiciones. F tiene deliberadamente procedencia pública exacta, pero ninguna revisión aprobada; B tiene aprobación, pero un 404 público. C tiene un 200 público con encabezado coincidente, pero enlaces fuente obsoletos en el índice y el módulo. E tiene fuente del módulo y encabezado coincidentes, mientras que el índice aún cita otra revisión. Estas excepciones muestran por qué las columnas deben seguir visibles. Un embudo por sí solo sugeriría que toda etapa posterior es un subconjunto de cada etapa anterior; las pruebas no lo garantizan.

| Tarjeta | Redactada | Revisión aprobada | Público exacto | Las tres |
|---|---|---|---|---|
| A | Sí | Sí | Sí | Sí |
| B | Sí | Sí | No: 404 | No |
| C | Sí | No | No: enlaces obsoletos | No |
| D | Sí | No | No: 404 | No |
| E | Sí | No | No: índice obsoleto | No |
| F | Sí | No | Sí | No |

### Ejercicio práctico 2: contar las tarjetas de aula

Ejecute el evaluador. Dé los cuatro recuentos: redactados, con revisión aprobada, con público exacto y con las tres condiciones. ¿Qué tarjeta refuta la afirmación de que la procedencia pública implica revisión aprobada?

> **Respuesta:** Los recuentos sintéticos son **6, 2, 2 y 1**. F tiene una comprobación exacta de lectura pública, pero ninguna revisión aprobada. B muestra lo contrario: la aprobación no implica una página pública. Los recuentos son propiedades de las tarjetas inventadas, no seis cursos reales de Streeling.

## 2. Dibujar con fidelidad los estados desconocidos y obsoletos

Para una revisión fuente fija, una cuadrícula de estado útil usa **sí**, **no** y **no medido** con palabras o símbolos en cada celda. La vía pública necesita una cuarta explicación cuando una página existe, pero enlaza a una fuente anterior. Una respuesta 200 con el título correcto no es una comprobación de lectura de la fuente exacta; una vista previa generada en un directorio local `dist/` tampoco es una prueba de despliegue anónimo. Etiquete la marca de tiempo de una consulta pública, porque una comprobación de lectura correcta puede quedar obsoleta tras el siguiente despliegue. Esto sigue [DV-001](../../data-visualization/dv-001-observed-degraded-stale-quality/): las observaciones ausentes y las históricas no son ceros actuales.

Para la instantánea fijada de progreso, una vista compacta podría decir:

```text
Core source drafts     120 / 525   observed at Demerzel 8a37e1d
Approved review         0 / 120   production-record signal at that revision
Exact public readback   ? / 120   not exhaustively measured by this report
All gates               ? / 525   cannot be certified from these inputs
```

Esto **no** es un único embudo de conversión. Un recuento de revisados puede usar todos los módulos redactados como denominador para el rendimiento de revisión, mientras que la finalización usa 525 objetivos troncales. Un barrido público exhaustivo, la comparación de fuente exacta y la validación de comprobantes podrían establecer más adelante los números restantes. Hasta entonces, conserve los signos de interrogación. En un panel, muestre el SHA fuente pertinente, la marca de tiempo de la comprobación de lectura, el código del curso y enlaces directos a las pruebas en una tabla accesible; no codifique el estado solo mediante el color.

### Ejercicio práctico 3: corregir el gráfico

Un panel de lanzamiento muestra tres barras de igual anchura etiquetadas «Borradores 120; Revisados 0; Publicados 0» y lo llama «120 cursos terminados». Identifique dos errores probatorios y sustituya su etiqueta pública.

> **Respuesta:** Los 120 son borradores troncales redactados, no cursos terminados, revisados y públicos. El script fijado de progreso no midió todas las páginas públicas, por lo que «Publicados 0» inventa un resultado; use «Comprobación exacta de lectura pública: no medida para todo el conjunto». Otro problema es que las barras de igual anchura ocultarían los recuentos y denominadores distintos. Indique la revisión fijada y muestre 0 como señal de revisión de los registros de producción, pendiente de validar los comprobantes.

## 3. Probar la unión por fuente exacta y su alcance

El script público exige que el índice enlace a `tree/<sha>/state/streeling/courses` y cada página de módulo a `blob/<sha>/<course path>`, además de una coincidencia de encabezado y HTTP 200. Sus comprobaciones son deliberadamente limitadas: establecen la procedencia de páginas anónimas y un título renderizado para el SHA solicitado. No comparan cada párrafo o ejercicio con la fuente ni inspeccionan la revisión. Una revisión humana vinculada a otro blob del curso debe reconsiderarse después de editarlo. Es una unión por versión exacta, no un recuento de etiquetas favorables.

**Límite de la migración:** el script fijado describe la antigua importación de Demerzel a Learn. Las páginas actuales de Learn usan enlaces de fuente/edición a `main` de Learn, y la copia inicial más los manifiestos suplementarios tienen orígenes distintos. Una URL mutable a `main` por sí sola no identifica la revisión de la lección desplegada. El script antiguo no se ha adaptado ni ejecutado como validador de este candidato de Learn. Para la comprobación de lectura actual, vincule el commit desplegado de Learn, el blob fuente revisado, su origen suplementario cuando corresponda y el contenido renderizado de la lección. Que falle solo el patrón antiguo de enlaces no prueba que una página actual sea incorrecta.

El evaluador de aula modela los cuatro booleanos de la comprobación de lectura, pero no hace ninguna solicitud HTTP. Usa una matriz pequeña para que el razonamiento sea reproducible sin acceso a la red. En el pipeline archivado, el script público real podía ejecutarse después de que el SHA de Demerzel estuviera confirmado, accesible y desplegado. Para el pipeline actual, establezca primero una comprobación de lectura contra la revisión desplegada de Learn y el contenido revisado; esa comprobación pública específica del candidato sigue pendiente. Inspeccione de forma independiente la identidad fuente del comprobante de revisión. No copie un resultado sintético «A aprobó» en un registro de producción.

### Ejercicio práctico 4: diagnosticar una coincidencia parcial

La tarjeta E devuelve HTTP 200, el enlace fuente del módulo y el encabezado coinciden con el objetivo, pero el enlace fuente del índice no coincide. ¿Debe contarse la tarjeta en la comprobación exacta de lectura pública? Nombre la próxima comprobación para un despliegue real de Streeling.

> **Respuesta:** No. El contrato fijado de comprobación de lectura exige tanto la procedencia del índice como la del módulo. Para el pipeline histórico, inspeccione la fuente del índice y la revisión del generador antes de desplegar la copia prevista de Demerzel. Para Learn actual, inspeccione la revisión desplegada de Learn, la procedencia de la copia inicial y de los suplementos y la lección renderizada frente a la fuente revisada; luego repita la comprobación anónima de lectura. No deduzca que todo el sitio está en la revisión objetivo a partir de una sola página de módulo coincidente.

## 4. Hacer visible la próxima acción

La cuadrícula debe conducir al trabajo, no solo decorar un informe. Para un borrador sin revisión, dé a la persona revisora del tema una tarea para el estudiante sin respuestas y un encargo de revisión vinculado a la fuente. Para un curso revisado sin comprobación exacta de lectura pública, compruebe la sincronización y el despliegue de Learn. Para una página pública exacta sin revisión, termine la revisión antes de afirmar que está finalizada. Si un archivo fuente cambia tras la aprobación, compare su nuevo blob con el revisado y solicite un nuevo veredicto cuando el cambio afecte al contenido revisado. Estas acciones surgen de las pruebas que faltan en cada fila, no de un «porcentaje completado» genérico.

No convierta `pipeline_review_approved` en un veredicto humano sin inspeccionar el comprobante subyacente. No equipare una vista previa local de Learn con una página pública. Por último, recuerde los términos «útil para el proyecto» y «ejercicios verificables» de la meta: el mapa de tres etapas es necesario para la disciplina de publicación, pero por sí solo no prueba que la lección sea precisa, útil para un usuario de GA/IX/Demerzel/Learn o satisfactoria para un estudiante.

### Ejercicio práctico 5: decidir qué informar

Suponga que un borrador recién redactado de DV-008 supera las comprobaciones previas locales y Learn puede renderizarlo localmente, pero ninguna persona lo ha revisado ni se ha consultado ninguna URL anónima. Escriba un estado de una oración y dos próximas acciones que produzcan pruebas.

> **Respuesta:** «DV-008 es un borrador fuente en inglés con pruebas locales de consistencia y vista previa; siguen pendientes la revisión humana y la comprobación exacta de lectura pública». Dé a una persona revisora la tarea sin respuestas y el blob fuente exacto para obtener un veredicto registrado; luego genere y despliegue la revisión revisada de Learn y ejecute una comprobación anónima actual de lectura contra la lección, el índice y el contenido renderizado esperado. Una vista previa local no es una revisión humana ni una observación pública.

## Ideas clave

- Un borrador fuente, una revisión aprobada y una página pública exacta responden a preguntas distintas.
- La procedencia pública y la aprobación humana pueden producirse en cualquier orden; cuente su intersección para la finalización.
- Cero es un recuento observado; desconocido significa que no se hizo la medición pertinente.
- Fije el SHA fuente, el blob del curso, el comprobante de revisión y la hora de la comprobación de lectura antes de combinar pruebas.
- Un gráfico de estado sigue siendo una ayuda para orientarse; el éxito del estudiante y la utilidad para el proyecto requieren pruebas separadas.

## Pruebas del proyecto y limitaciones

- Los scripts fijados de Demerzel [`streeling_course_progress.py`](https://github.com/GuitarAlchemist/Demerzel/blob/8a37e1d9a728a15ed384cbb912e3c8c518083d12/scripts/streeling_course_progress.py) y [`streeling_public_readback.py`](https://github.com/GuitarAlchemist/Demerzel/blob/8a37e1d9a728a15ed384cbb912e3c8c518083d12/scripts/streeling_public_readback.py) definen los dos alcances medidos. El recuento de progreso se reprodujo en esa revisión; no se realizó un barrido público completo.
- Los [datos de prueba de seis tarjetas](https://github.com/spareilleux/learn/blob/main/code/streeling/fixtures/data-visualization/dv-008/scenarios.json) son sintéticos. Sus resultados 6/2/2/1 no estiman tasas reales de publicación.
- Este es un borrador de traducción al español; los borradores de traducción FR/ES se preparan por separado a partir del inglés. No se afirma ningún veredicto temático humano, prueba con un estudiante, revisión por una persona con dominio del idioma, despliegue de Learn ni comprobación anónima de lectura de DV-008.

*Investigación: `data-visualization-2026-10-21-008`. Borrador de traducción; revisión y publicación pendientes.*
