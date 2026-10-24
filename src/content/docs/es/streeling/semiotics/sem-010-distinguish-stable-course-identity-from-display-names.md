---
title: Distinguir la identidad estable del curso de su título visible
description: Distinguir la identidad estable del curso de su título visible — Semiótica
sidebar:
  label: SEM-010 · Distinguir la identidad estable del curso de su título visible
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/es/sem-010-distinguish-stable-course-identity-from-display-names.es.md
---

:::note[Streeling University]
**SEM-010** · Distinguir la identidad estable del curso de su título visible · intermedio · 40 minutos

Generado por el departamento *Semiótica* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/es/sem-010-distinguish-stable-course-identity-from-display-names.es.md) · [Mi diario](../../journal/)

Requisitos previos: [SEM-004](../../semiotics/sem-004-face-identity-under-reindexing/), [DV-008](../../data-visualization/dv-008-streeling-evidence-stage-map/)
:::

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Learn traduce el título de un curso y después modifica su redacción. ¿Debe eso crear otro curso, otra lengua u otra versión del contenido? El lector fijado extrae metadatos y encabezado; la clave de módulo elimina sufijos de idioma del nombre de archivo. La tarea es interpretar estos signos sin contar traducciones como cursos nuevos. La identidad de la fuente y la etiqueta visible responden a preguntas distintas.

[Requisito previo: sem-004-face-identity-under-reindexing](../../semiotics/sem-004-face-identity-under-reindexing/); [Requisito previo: dv-008-streeling-evidence-stage-map](../../data-visualization/dv-008-streeling-evidence-stage-map/)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

Use una tabla construida con identidad estable, idioma, título y revisión. Cuente identidades distintas para el inventario, pares identidad-idioma para cobertura y revisiones para versiones. Dos títulos iguales pueden identificar cursos distintos; títulos diferentes pueden ser traducciones del mismo curso. A su vez, reutilizar una identidad no demuestra que el contenido no cambió. El helper aporta una convención de indexación, no una garantía global de identificadores únicos en todos los productores. Siguen siendo necesarias la detección de duplicados y la revisión vinculada a la fuente exacta.

## Caso fijo y supuestos

```text
rows=[
 {"id":"course-a","locale":"en","title":"Clearance","revision":"r1"},
 {"id":"course-a","locale":"fr","title":"Jeu","revision":"r1"},
 {"id":"course-a","locale":"es","title":"Holgura","revision":"r1"},
 {"id":"course-b","locale":"en","title":"Clearance","revision":"r1"}
]
rows_count=4; distinct_ids=2; distinct_id_locale_pairs=4
rename_course_a_en_title="Panel Clearance"
renamed_distinct_ids=2
control_duplicate={"id":"course-a","locale":"en","revision":"r2"}
```

## Ejercicios resueltos

### Ejercicio 1

Cuente identidades y filas de cobertura lingüística.

> **Respuesta:** Hay `2` identidades y `4` pares identidad-idioma. El número de filas no equivale al de cursos distintos.

### Ejercicio 2

Renombre el primer título visible. ¿Qué recuento de inventario cambia?

> **Respuesta:** Ninguno cambia: siguen siendo `2` identidades y `4` pares. Cambiar el título sí modifica los bytes revisados y puede requerir otra comprobación.

### Ejercicio 3

¿Permiten títulos iguales fusionar ambas identidades?

> **Respuesta:** No. La palabra visible compartida no establece identidad común. Conserve ambas claves e investigue por separado posibles duplicados.

### Ejercicio 4

Añada el duplicado de control. ¿Aumenta la cobertura?

> **Respuesta:** Las filas pasan a `5`, pero los pares distintos siguen en `4`. El par repetido tiene revisiones contradictorias: exige conciliación, no crédito por otra traducción.

### Ejercicio 5

¿La identidad estable traslada la aprobación a bytes modificados?

> **Respuesta:** No. La identidad permite correspondencia; la revisión cubre el contenido exacto. Conserve hashes y dictámenes aplicables separados de los títulos.

## Tarea con consulta de fuentes

Inspeccione parseModule y moduleKey en el helper fijado. Siga manualmente un curso existente y sus traducciones mediante archivo, metadatos y encabezado. Compare el recuento asistido con la tabla de claves distintas. Contar un título renombrado o idioma duplicado como curso nuevo refuta la regla propuesta.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)
- [Fuente primaria](https://github.com/spareilleux/learn/blob/8f13637ae4596b614c2ba493b596b6a08e1cf43a/scripts/streeling-lib.mjs)
- [Expediente de evidencias fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
