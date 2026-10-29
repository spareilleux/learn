---
title: Distinguir la transposición diatónica de la cromática
description: Distinguir la transposición diatónica de la cromática — Musicología
sidebar:
  label: MCL-008 · Distinguir la transposición diatónica de la cromática
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/musicology/es/mcl-008-keep-diatonic-and-chromatic-transposition-separate.es.md
---

:::note[Streeling University]
**MCL-008** · Distinguir la transposición diatónica de la cromática · intermedio · 45 minutos

Generado por el departamento *Musicología* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/musicology/es/mcl-008-keep-diatonic-and-chromatic-transposition-separate.es.md) · [Mi diario](../../journal/)

Requisitos previos: [MCL-005](../../musicology/mcl-005-preserve-written-and-sounding-pitch/), [WML-005](../../world-music-languages/wml-005-declare-note-name-conventions/)
:::

> **Alcance del borrador.** Cálculos didácticos de escritura de notas por semitonos enteros, controles inversos exactos y lectura de código y documentación primaria en revisiones fijadas. No hubo ninguna ejecución nueva del analizador, adaptador de transposición, salida MusicXML, partitura renderizada ni reproducción. Siguen pendientes las revisiones humanas técnicas, musicales, lingüísticas por personas que dominen el idioma y pedagógicas con estudiantes, así como la verificación del HTML del curso desplegado.

## La pregunta del proyecto

Una parte importada debe sonar un semitono más alto. ¿Debe el C escrito convertirse en C# o en Db? [MCL-005](../../musicology/mcl-005-preserve-written-and-sounding-pitch/) distingue el registro codificado del sonoro. Esta lección añade la coordenada de nombre de nota necesaria para conservar una escritura enarmónica especificada.

El [campo diatónico de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/diatonic/) cuenta los pasos de altura de lo escrito a lo sonoro. Su [campo cromático](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/chromatic/) cuenta semitonos. Ambos excluyen la contribución separada del cambio de octava. Utilizamos estas definiciones en un modelo didáctico de temperamento igual de doce sonidos, con C4 igual a 60 y solo alteraciones enteras.

## 1. Seguir dos coordenadas

Indexemos las letras de C a B con los números de 0 a 6 y sea `j=7*octave+letter_index`. Si el desplazamiento diatónico es `d`, el cromático es `c` y el cambio de octava es `o`, las coordenadas de destino son `j_new=j+d+7*o` y `m_new=m+c+12*o`, donde `m` es el número absoluto de nota.

La nueva coordenada diatónica elige una letra y una octava escrita. La alteración necesaria es la diferencia entre el número de nota de destino y el número de nota natural de esa letra. El desplazamiento en semitonos por sí solo no elige la letra.

### Ejercicio 1: producir dos destinos enarmónicos

Parta de C4 en 60 y aplique un desplazamiento cromático de 1 sin cambio de octava. Compare un desplazamiento diatónico de 0 con uno de 1. Indique ambas escrituras y los números de nota.

> **Respuesta:** El desplazamiento diatónico 0 conserva la letra C, por lo que la alteración +1 da C#4. El diatónico 1 selecciona D4, cuyo número natural es 62, por lo que la alteración -1 da Db4. Ambos tienen como destino 61. Un mismo número sonoro no implica una misma escritura.

## 2. Propagar los cambios de letra a través del límite de octava

B3 en 59, desplazado una letra y un semitono hacia arriba, pasa a ser C4 en 60. Desplazar C4 una letra y un semitono hacia abajo da en cambio B3 en 59. Si esa segunda operación baja dos semitonos, el destino es Bb3 en 58.

La octava escrita pertenece a la escritura de la nota. B#3 tiene el número de nota 60, mientras que Cb4 tiene 59. Reducir una coordenada de nota natural módulo 12 antes de conservar su octava puede ocultar estos efectos del límite.

### Ejercicio 2: examinar los casos límite

Calcule B3 más una letra y un semitono; después C4 menos una letra y dos semitonos. Indique los números de B#3 y Cb4 y explique por qué la octava escrita por sí sola no puede identificar el registro sonoro.

> **Respuesta:** El primer resultado es C4 en 60; el segundo es Bb3 en 58. B#3 es 60 y Cb4 es 59 porque sus alteraciones cruzan el límite natural de C. La letra, la alteración y la octava determinan juntas el número; un campo aislado de octava escrita no basta.

## 3. Aplicar un cambio de octava en ambos dominios

Para C4 con desplazamientos diatónico y cromático nulos pero un cambio de octava de -1, reste siete pasos de letra y doce semitonos. El destino es C3 en 48. Añadir solo la contribución en semitonos y mantener la antigua octava de la letra exigiría en cambio una alteración artificial de -12 sobre C4. Esto puede coincidir con un número y a la vez incumplir la representación escrita prevista.

### Ejercicio 3: mantener la representación

Deduza las dos coordenadas de destino para esta octava descendente. ¿Por qué C4 con alteración -12 no es la salida prevista y basta un tipo entero para imponer un intervalo reducido de alteraciones?

> **Respuesta:** El índice diatónico disminuye en 7 y el número de nota en 12, dando C3 en 48. Mantener C4 y añadirle -12 cambia la representación en vez de trasladar el cambio de octava a la coordenada escrita. Un tipo entero por sí solo no impone ningún intervalo de alteraciones; cualquier validación debe inspeccionarse por separado.

## 4. Conservar información suficiente para invertir la transformación

Desplace C#4 y Db4 una letra y dos semitonos hacia arriba cada uno. Se convierten respectivamente en D#4 y Eb4, ambos en 63. Invertir ambos desplazamientos sobre los resultados escritos conservados recupera los originales distintos. Conservar solo 63 pierde la distinción necesaria para recuperar la escritura suministrada.

El [registro fijado de transposiciones](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/capo-spelling-2026-10-22/spelled-transpositions.json) contiene diez casos didácticos con controles inversos exactos. Es un resultado aritmético acotado, no una implementación general de MusicXML, una demostración sobre todas las tradiciones de notación ni una prueba de escucha.

### Ejercicio 4: identificar la representación reversible

Muestre ambas escrituras tras la transformación y su mismo número proyectado. ¿Qué datos deben conservarse para que la inversa demostrada recupere la escritura original? ¿Basta conservar solo el número proyectado?

> **Respuesta:** C#4 pasa a D#4 y Db4 pasa a Eb4; ambos se proyectan en 63. Conserve la letra de destino, la alteración y la octava junto con los desplazamientos diatónico, cromático y de octava especificados. Negar esos desplazamientos recupera C#4 y Db4 en estos casos. El único número proyectado no puede distinguir sus orígenes.

## 5. Distinguir la escritura almacenada de la transposición implementada

Los [tipos MusicXML](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L282-L295) en la revisión fijada conservan el nombre de nota, una alteración entera opcional y la octava, y después ofrecen una conversión a un número entero de nota. Los [atributos del analizador](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L165-L180) seleccionados no contienen un campo de transposición. Conservar una altura escrita no demuestra que esta utilidad realice nuestra transformación. Su comentario sobre la alteración tampoco impone por sí solo un intervalo.

La [política de escritura de CapoSkill](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs), separada, elige una preferencia de escritura con sostenidos o bemoles para una clase de altura. Esa política no es la transposición diatónica de dos coordenadas deducida aquí.

### Ejercicio 5: preparar una comprobación de importación con ayuda de las fuentes

Lea las definiciones y el código; después proponga una comparación acotada antes de añadir un nuevo DSL de notación o afirmar que una importación tuvo éxito.

> **Respuesta:** Conserve la altura escrita original, los desplazamientos declarados de lo escrito a lo sonoro, la escritura y el número de destino previstos, la revisión del código y la política de alteraciones admitida. Pruebe ambas ramas enarmónicas, los límites de octava y las inversas frente a resultados esperados independientes; conserve o rechace explícitamente el contexto no admitido. Compare una pequeña transformación tipada antes de añadir un DSL. La inspección actual del código y los cálculos no establecen una corrección del analizador, una importación en la aplicación, una partitura renderizada ni un resultado de reproducción.
