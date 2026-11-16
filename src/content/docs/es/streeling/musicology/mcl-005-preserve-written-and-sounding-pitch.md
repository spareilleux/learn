---
title: Conservar la altura escrita y la altura real al importar una partitura
description: Conservar la altura escrita y la altura real al importar una partitura — Musicología
sidebar:
  label: MCL-005 · Conservar la altura escrita y la altura real al importar una partitura
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/musicology/es/mcl-005-preserve-written-and-sounding-pitch.es.md
---

:::note[Streeling University]
**MCL-005** · Conservar la altura escrita y la altura real al importar una partitura · intermedio · 35 minutos

Generado por el departamento *Musicología* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/musicology/es/mcl-005-preserve-written-and-sounding-pitch.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-005](../../world-music-languages/wml-005-declare-note-name-conventions/)
:::

> **Alcance del borrador.** Nueva ejecución en CPU de dos archivos públicos de F# sin cambios sobre diez entradas XML creadas para el curso, documentación primaria de MusicXML y aritmética explícita. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML del curso desplegado. No se realizaron validación de esquema, importación en la aplicación, representación de la notación, reproducción ni correcciones del analizador de producción.

## La pregunta del proyecto

Un guitarrista compara una partitura, una tablatura y las etiquetas de notas de GA. Una discrepancia de octava puede proceder de la representación de la notación en lugar de la interpretación musical. El elemento [pitch de MusicXML 4.0](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/pitch/) almacena un grado, una alteración cromática opcional y una octava. Su [elemento transpose](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/transpose/) describe por separado el ajuste de la altura escrita a la altura real. Un analizador puede conservar los campos de la nota y perder el contexto que les da la interpretación prevista.

[WML-005](../../world-music-languages/wml-005-declare-note-name-conventions/) estableció una convención de nombres de notas. Esta lección sigue el siguiente límite: ¿qué significa el registro codificado? Los ejemplos son casos didácticos creados para el curso, no una afirmación de que todos los archivos para guitarra utilicen la misma codificación.

## 1. Calcular la transposición declarada por el archivo

Para un caso ordinario de una sola nota sin instrucción de duplicación, usa la coordenada numérica de la nota codificada más el [desplazamiento cromático](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/chromatic/) más 12 veces el [cambio de octava](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/octave-change/). El campo cromático excluye la contribución del cambio de octava. Estos casos de prueba usan semitonos enteros y la convención de que C4 es MIDI 60.

La [aritmética fijada](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/transposition-arithmetic.json) da 52 para E3 codificado. Con chromatic 0 y octave-change -1, la altura real es `52+0+12*(-1) = 40`, E2. Otro archivo puede codificar E2 directamente como 40 sin transposición; ya representa la misma altura real. La etiqueta del instrumento por sí sola no permite decidir entre esas representaciones.

### Ejercicio 1: seguir el desplazamiento declarado

Compara E3 codificado con chromatic 0 y octave-change -1 con E2 codificado sin transposición. Indica el número de la nota real en cada caso. ¿Por qué la palabra «guitarra» por sí sola no debe provocar otra resta de octava?

> **Respuesta:** Ambos dan 40, E2. El primero necesita su desplazamiento declarado; el segundo ya tiene ese registro. Aplicar otro desplazamiento automático de guitarra contaría de nuevo el mismo ajuste previsto o modificaría una representación que ya está a altura real.

## 2. Observar qué conserva realmente el analizador de la revisión fijada

El commit público de GA `dc2e74cbd992a298f67efb928b5b3754615e1924` proporciona [MusicXmlTypes](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MusicXmlTypes.fs) y [MusicXmlParser](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs). Una nueva carga independiente con el SDK instalado 10.0.113 ejecutó sus funciones sin cambios sobre las [diez entradas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/authored-xml-inputs.json). Los [resultados registrados](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/native-parser-results.json) y el [comprobante de ejecución](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/execution.json) conservan el alcance.

Una partitura con E3 y otra con E3 idéntica salvo por la transposición descendente produjeron partituras analizadas estructuralmente iguales. Ambas conservaron E3 y convirtieron esa altura conservada en 52. El tipo Attributes analizado no tiene campo de transposición. Es una pérdida de información reproducida en esa función auxiliar de la revisión fijada, no una prueba de la aplicación completa ni evidencia sobre el servicio desplegado actualmente.

### Ejercicio 2: distinguir aceptación de conservación

Ambas partituras se analizan con éxito y almacenan el mismo número de nota 52. ¿Puede el registro analizado por sí solo determinar que la segunda partitura debe sonar a 40? ¿Qué información falta?

> **Respuesta:** No. Los registros conservados son iguales, pero la segunda partitura original declara una transposición de una octava hacia abajo. El registro analizado ha perdido esa declaración. Un resultado satisfactorio no basta para demostrar que se conservó la interpretación de la altura real.

## 3. Separar la apariencia de la clave y la transposición declarada

MusicXML también tiene [clef-octave-change](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/clef-octave-change/), que pertenece a una clave. La prueba didáctica añadió un valor de -1 a la clave manteniendo E3 codificado. Su registro analizado volvió a ser igual al de la partitura base: la función auxiliar conserva el signo de la clave, pero no esos metadatos de octava. Esto demuestra otra pérdida; no resuelve por sí solo la política de alturas de todos los programas que generan partituras.

Trata la altura codificada, la transposición del instrumento y la información de notación de la clave como entradas distintas que deben examinarse. No sumes a ciegas los dos campos que parecen referirse a octavas como desplazamientos independientes de altura real. El consumidor necesita una política de codificación explícita y pruebas de importación representativas. Con la transposición declarada del primer caso, restar la octava dos veces convertiría 52 en 28, E1, en lugar de 40.

### Ejercicio 3: detectar la doble aplicación

El caso didáctico de E3 escrito declara un único ajuste de una octava hacia abajo. Un importador resta 12 una vez por esa declaración y otra porque reconoce una parte de guitarra. Indica su salida y la salida prevista. ¿Encontrar metadatos de octava en una clave justifica esta regla?

> **Respuesta:** Produce 28, E1; el valor previsto es 40, E2. Los metadatos de octava de la clave no justifican aplicar a ciegas un segundo desplazamiento del instrumento. Establece cómo codifica las alturas el archivo y aplica la transformación prevista una sola vez.

## 4. Examinar las pérdidas dentro de una nota aceptada

La [definición oficial de alter](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/alter/) permite alteraciones de fracciones de semitono. La entrada didáctica C4 con alter 0.5 conservó una altura con la alteración ausente y el número de nota auxiliar 60. El analizador de la revisión fijada usa conversión a enteros; la alteración fraccionaria de la entrada no se conservó. En cambio, un alter entero 0 produjo un 0 almacenado explícitamente, que también se convirtió en 60. La igualdad de los números convertidos no demuestra igualdad de los registros conservados ni una interpretación sin pérdidas.

Dos controles negativos usaron el grado H y una octava ausente. Ambas partituras completas siguieron devolviendo éxito y conservaron una nota, pero esa nota no tenía altura. Los valores -999 de la tabla de observación son valores centinela de la prueba para campos ausentes, no notas musicales devueltas por GA. Estas entradas deliberadamente deficientes no se validaron contra un esquema y no deben presentarse como documentos MusicXML válidos.

### Ejercicio 4: examinar el resultado anidado

En el caso de la alteración fraccionaria, ¿qué distinción desapareció? En el caso H, ¿cuántas notas y alturas se conservaron? ¿Puede el éxito del resultado externo certificar la conservación?

> **Respuesta:** La alteración 0.5 desapareció; la alteración ausente tomó el valor predeterminado 0 durante la conversión. El caso H conservó una nota y ninguna altura. El éxito externo no certifica ni la conservación de la alteración fraccionaria ni la presencia de una altura válida en cada nota conservada.

## 5. Elegir una comparación que detecte el error real

E3 en 52 y E2 en 40 tienen ambos la clase de altura 4. Por tanto, una comparación solo de clases de altura no puede detectar este error de octava. Conserva el registro absoluto cuando la pregunta trate de las notas que suenan, y conserva la grafía y la procedencia de la transposición para las preguntas de notación. La tablatura necesita además la afinación y las convenciones de cuerdas y trastes; un número de nota por sí solo no permite reconstruirlo todo.

Los ejercicios proponen criterios de aceptación de importación sin cambiar el contrato de producción de GA. Una implementación posterior debería conservar o rechazar explícitamente el contexto no admitido y validar la ruta de la aplicación. Aquí no se incluye ninguna corrección de ese tipo ni comparación de partituras representadas.

### Ejercicio 5: diseñar una comprobación que distinga el error

Una comprobación de importación compara solo clases de altura y acepta 52 donde se esperaba 40. Explica por qué pasa y propone una comprobación que falle en este caso. Indica un límite que siga sin probarse.

> **Respuesta:** Ambos valores se reducen a la clase 4, de modo que la comprobación descarta la octava que los diferencia. Comparar el número absoluto real previsto 40 con el obtenido 52 detecta el error. La importación completa en la aplicación, la representación de la notación, la reproducción y la validación de esquema siguen sin probarse aquí.

## Tarea del estudiante con acceso a las fuentes

Usa la [tarea preparada](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/learner-task.md) para reconstruir las dos codificaciones, explicar la igualdad de los registros analizados y proponer una comprobación de importación. Distingue la ejecución de la función auxiliar, la interpretación de la especificación y el comportamiento de la aplicación. Los resultados de los estudiantes y de la revisión humana siguen pendientes.
