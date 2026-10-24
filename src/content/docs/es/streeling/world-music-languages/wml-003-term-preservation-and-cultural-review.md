---
title: Auditar términos de guitarra en seis idiomas
description: Auditar términos de guitarra en seis idiomas — Músicas y lenguas del mundo
sidebar:
  label: WML-003 · Auditar términos de guitarra en seis idiomas
  order: 3
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/es/wml-003-term-preservation-and-cultural-review.es.md
---

:::note[Streeling University]
**WML-003** · Auditar términos de guitarra en seis idiomas · intermedio · 40 minutos

Generado por el departamento *Músicas y lenguas del mundo* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/es/wml-003-term-preservation-and-cultural-review.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-001](../../world-music-languages/wml-001-guitar-around-the-world/), [WML-002](../../world-music-languages/wml-002-dadgad-layout-and-cultural-claims/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/voicing-learning-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Músicas del Mundo e Idiomas** | Intermedio | 40 minutos | Borrador español; pendientes la revisión cultural, la revisión lingüística y la evaluación con alumnos

## Objetivos y pregunta del proyecto

Reproducirás un inventario de términos en seis idiomas a partir de fuentes Git exactas, distinguirás la grafía literal del significado traducido y decidirás qué puede afirmar de forma segura una comprobación automática sobre una lección de música culturalmente específica. **Pregunta del proyecto:** ¿cómo puede Streeling ampliar la localización de sus cursos de guitarra sin convertir una búsqueda de cadenas satisfactoria en una afirmación sin respaldo de que todas las traducciones son correctas o están publicadas? Esta lección utiliza un curso existente y una auditoría determinista. No contiene ningún dictamen cultural o lingüístico aprobado.

[WML-001 en el commit de Demerzel `f5b040a`](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/en/wml-001-guitar-around-the-world.md) presenta varias tradiciones de guitarra. Tiene archivos fuente en inglés, francés, español, portugués, italiano y alemán. [WML-002 en el mismo commit](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/en/wml-002-dadgad-layout-and-cultural-claims.md) muestra por qué una tabla de afinación puede establecer nombres de notas mientras que una asociación cultural necesita otro tipo de fuente. Aquí auditamos una pregunta mecánica más limitada: ¿aparecen literalmente siete términos seleccionados de WML-001 en cada uno de sus seis archivos fuente? Esos siete términos son una **muestra didáctica**, no un glosario completo ni una lista de traducciones obligatorias.

## 1. Reproducir el inventario léxico

El [script de comprobación de términos en la revisión fijada](https://github.com/GuitarAlchemist/Demerzel/blob/882d5284426ea230d08f067f74e1f95ca56fb90d/state/streeling/fixtures/world-music-languages/wml-003/check_terms.py) lee **objetos Git** en el commit fuente completo, no los archivos que pueda haber en un árbol de trabajo. Para cada idioma registra la ruta del archivo, el identificador del blob de Git y un booleano de presencia literal sin distinguir mayúsculas de minúsculas para `rasgueado`, `picado`, `alzapúa`, `compás`, `golpe`, `batidas` y `la pompe`. Su [registro JSON versionado](https://github.com/GuitarAlchemist/Demerzel/blob/882d5284426ea230d08f067f74e1f95ca56fb90d/state/streeling/fixtures/world-music-languages/wml-003/term-presence-f5b040a.json) puede reproducirse con este comando desde la raíz del repositorio Demerzel:

```text
python state/streeling/fixtures/world-music-languages/wml-003/check_terms.py --ref f5b040ae040a5a7f1fe6c3f609f878c00a3a1859
```

El resultado fijado contiene **42 pares término-idioma** (`7 × 6`). Cuarenta son coincidencias exactas sin distinguir mayúsculas de minúsculas. Las dos formas literales ausentes son `fr:alzapúa` y `fr:compás`. La [fuente francesa de WML-001 en ese commit](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/fr/wml-001-guitar-around-the-world.fr.md) muestra en su lugar `Alzapua` y `Compas`, sin tildes, en la lista de técnicas. Una búsqueda anterior más permisiva de `alzap` y `comp.s` devolvió seis archivos para ambos patrones; ocultó esta diferencia de grafía exacta. Ese hallazgo al utilizar el proyecto sobre sus propios contenidos es el origen de esta lección.

El script devuelve deliberadamente un registro de auditoría incluso cuando faltan formas. Su opción `--require-exact` termina con el código 1 para un control léxico estricto. Ninguno de los dos modos declara que el archivo francés sea incorrecto. Un músico que domine el francés puede considerar aceptable un préstamo sin tilde o preferir la grafía del idioma de origen; un reemplazo a ciegas podría empeorar el texto o no resolver una traducción errónea más profunda. La auditoría da al revisor líneas concretas que examinar.

### Ejercicio práctico 1

Calcula el total de pares y coincidencias exactas a partir del registro de siete términos y seis idiomas. Nombra los dos pares literales ausentes y las dos cadenas que aparecen en su lugar en francés.

> **Respuesta:** Siete términos por seis archivos dan 42 pares. Cuarenta coinciden literalmente sin distinguir mayúsculas de minúsculas. Los dos pares ausentes son `alzapúa` en francés y `compás` en francés; la fuente francesa utiliza `Alzapua` y `Compas`. Esta cuenta todavía no dice nada sobre si esas grafías son aceptables en la terminología francesa de guitarra.

## 2. Respetar los límites de la evidencia

La comprobación actual utiliza el método Unicode `casefold()`, por lo que `Rasgueado` coincide con `rasgueado`, pero `Alzapua` no coincide con `alzapúa`. Podría añadirse una comparación que ignore los acentos como comprobación **aparte**, mediante descomposición Unicode y eliminación de marcas combinantes. No debería reemplazar la columna de formas exactas: una coincidencia normalizada y una exacta responden a preguntas diferentes. El término de origen puede ser un préstamo, un nombre propio o una palabra cuyo acento distinga significados. Antes de convertir una regla ortográfica en norma, debe establecerse una política terminológica con los conocimientos lingüísticos y musicales pertinentes.

La presencia literal también es una evidencia limitada de cobertura del contenido. Un término puede aparecer solo en un glosario mientras el cuerpo de la lección omite el concepto subyacente. Una traducción puede conservar un título y cambiar la afirmación que lo sigue. A la inversa, una traducción correcta puede utilizar otra expresión y no superar la comprobación exacta. Para evaluar el significado, compara la frase, el ejemplo, la respuesta y el contexto musical con la fuente inglesa; para evaluar la autoridad cultural, consulta a músicos o estudios especializados pertinentes para la tradición concreta. El script no hace nada de eso. No compara definiciones de términos ni comprueba si un lector francófono puede ejecutar una técnica.

El párrafo inglés de WML-001 sobre el flamenco describe el `compás` y después habla de ciclos de 12 tiempos. La auditoría léxica puede confirmar si la palabra aparece en cada archivo. No puede establecer que el párrafo represente con precisión todas las prácticas del flamenco ni que una traducción conserve el matiz previsto. Trata el párrafo como una **afirmación del curso que debe revisarse**, no como un hecho demostrado por los recuentos de términos de esta lección. [El ejercicio de WML-002 sobre DADGAD](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/en/wml-002-dadgad-layout-and-cultural-claims.md) aplica la misma separación a los datos de notas y a los comentarios culturales generales de un skill de GA.

### Ejercicio práctico 2

Si un nuevo comprobador elimina los acentos antes de buscar coincidencias, ¿qué resultado daría en francés para estos dos términos? ¿Debería su resultado sustituir al de la comprobación de grafía exacta? Da una razón para cada respuesta.

> **Respuesta:** Probablemente haría coincidir `Alzapua` con `alzapúa` y `Compas` con `compás`, lo que daría dos coincidencias adicionales sin distinguir acentos, siempre que aplicara la misma normalización a ambas cadenas. Debería añadir una columna normalizada aparte, no sustituir la exacta, porque la diferencia original resulta útil para un revisor que deba decidir si importa la grafía del idioma de origen. Ninguna de las dos comparaciones determina la corrección semántica.

### Ejercicio práctico 3

El registro indica que un blob francés contiene `Compas`. Un commit posterior modifica ese archivo, pero deja intacto el archivo inglés. ¿Puede el registro anterior demostrar que el nuevo archivo francés sigue conteniendo el término? ¿Qué dos valores de Git debería comparar un revisor antes de reutilizar la auditoría?

> **Respuesta:** No. El registro está vinculado al blob de Git francés en `f5b040a`; una modificación posterior del francés produce un blob distinto aunque la palabra permanezca. Compara los identificadores de los blobs franceses anterior y nuevo y el commit fuente fijado; vuelve a ejecutar la comprobación para el nuevo commit en lugar de atribuirle la auditoría anterior. Para revisar la traducción también debes saber con qué blob inglés se comparó la versión francesa.

## 3. Coordinar la revisión lingüística con la publicación del sitio

Los seis archivos *fuente* de WML-001 representan un estado concreto. El [código provisional de sincronización de Learn en `02fc08c`](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/sync-streeling.mjs) genera actualmente páginas de cursos en inglés, francés y español; una importación aislada de Demerzel `f5b040a` registró 113 páginas EN, 80 FR y 80 ES en todo el sitio. Esto es evidencia local de las entradas de compilación, no una lectura pública anónima. Los archivos fuente portugueses, italianos y alemanes de WML-001 no bastan por sí solos para establecer que existan esas rutas del sitio. Incluso una página generada puede seguir pendiente de revisión temática, revisión de traducción y evaluación con alumnos; el despliegue debe inspeccionarse por separado.

**Alcance actual de las fuentes de Learn.** El experimento de importación anterior es histórico. Las [convenciones de las fuentes de Learn en `09b13e7f`](https://github.com/spareilleux/learn/blob/09b13e7f9eddc2b4ddbd87356001c1da2eec6b58/AGENTS.md) sitúan los archivos de autoría EN/FR/ES en `streeling/courses/` dentro de Learn; las páginas generadas se sincronizan desde esa copia. PT/IT/DE y los ciclos de investigación permanecen en Demerzel. El registro de términos en seis idiomas descrito anteriormente sigue vinculado a sus blobs históricos de Demerzel y no puede aprobar una traducción de Learn modificada. Antes de reutilizar una revisión léxica o de significado posterior, vincúlala a los blobs reales de Learn en inglés y en el idioma correspondiente.

Una cadena de revisión segura puede expresarse mediante funciones pequeñas: `read_source(commit, path)` devuelve los bytes y el blob; `check_terms(bytes, glossary)` devuelve observaciones léxicas; `review_meaning(locale_blob, english_blob, evidence)` devuelve un dictamen humano; `render_status(receipts, imported_commit)` indica el estado de la página generada; `read_public_page(url, expected_commit)` verifica qué reciben los lectores anónimos. Cada función tiene un resultado más limitado que «curso aprobado». El [contrato provisional de registro vinculado a las fuentes exactas](https://github.com/GuitarAlchemist/Demerzel/blob/5d7c1d1bd9972fe9d6d2e7a90ab3cdddabb8ed44/schemas/streeling-review-receipt.schema.json) exige el blob de la traducción y su dependencia inglesa. El esquema sigue bajo revisión humana; esta lección no crea ningún registro ni elude ese contrato.

### Ejercicio práctico 4

Los siete términos superan una comprobación sin distinguir acentos en francés, pero ningún revisor ha examinado el párrafo sobre el `compás` ni su ejercicio. ¿Qué estado puede comunicar el agente: comprobación léxica superada, significado francés aprobado o lección francesa publicada? Indica la evidencia mínima necesaria para cada estado posterior.

> **Respuesta:** Solo puede comunicar que la comprobación léxica indicada se superó para el archivo en la revisión fijada. La aprobación del significado francés requiere una revisión humana de los blobs franceses e ingleses pertinentes, del párrafo, de los ejemplos y de los ejercicios, con un dictamen y evidencia registrados. La publicación pública requiere una revisión fuente aceptada, una página generada y desplegada y una lectura anónima vinculada a esa revisión. La presencia de términos no autoriza ninguno de esos pasos posteriores.

### Ejercicio práctico 5

Una persona que planifica ve seis idiomas fuente de WML-001, los tres idiomas generados por la importación local de Learn y ningún registro de revisión. ¿Cuántas versiones lingüísticas de WML-001 puede describir verazmente como revisadas por una persona? ¿Puede afirmar que hay seis rutas públicas? Identifica la próxima comprobación útil para un alumno francófono.

> **Respuesta:** Ningún idioma cuenta con un dictamen humano registrado en esta lección. El número de archivos fuente no puede demostrar que existan seis rutas públicas; la importación local solo respalda la generación EN/FR/ES y ni siquiera demuestra que esas páginas se hayan desplegado. Para un alumno francófono, primero hay que obtener revisiones temáticas y de lengua francesa vinculadas a los blobs ingleses y franceses exactos; después, proponer una tarea sin dar la respuesta, registrar el resultado, desplegar la revisión aceptada y leer la página pública francesa de forma anónima.

## Fuentes, límites y próxima comprobación

Los datos fuente son [WML-001 EN](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/en/wml-001-guitar-around-the-world.md) y [FR](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/fr/wml-001-guitar-around-the-world.fr.md) en `f5b040a`, junto con los otros cuatro blobs de idiomas identificados en el registro reproducible. El script comprueba la presencia literal sin distinguir mayúsculas de minúsculas en cualquier parte de un archivo, utilizando siete términos seleccionados. No puede juzgar la traducción, las afirmaciones culturales, el desempeño del alumno ni la publicación. Ningún revisor que domine el idioma ni especialista en la materia ha aprobado este curso o WML-001 durante este ciclo. La próxima comprobación consiste en que un guitarrista francófono y un revisor que domine el francés evalúen las dos diferencias de acentuación y las definiciones que las rodean frente a los blobs ingleses y franceses fijados; sus hallazgos podrán justificar cambios y una nueva auditoría vinculada a las fuentes exactas.
