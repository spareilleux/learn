---
title: Mantener las normales perpendiculares a las superficies
description: Mantener las normales perpendiculares a las superficies — Física
sidebar:
  label: PHY-008 · Mantener las normales perpendiculares a las superficies
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/es/phy-008-keep-surface-normals-perpendicular.es.md
---

:::note[Streeling University]
**PHY-008** · Mantener las normales perpendiculares a las superficies · intermedio · 40 minutos

Generado por el departamento *Física* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/es/phy-008-keep-surface-normals-perpendicular.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/), [CS-014](../../computer-science/cs-014-compose-brutal-scene-descriptions/)
:::

> **Alcance del borrador.** Nueva ejecución en CPU de las funciones geométricas públicas sin modificar de BRUTAL, con entradas creadas para el ejercicio, cálculos matemáticos independientes e inspección del código del renderizador en una revisión fija. Siguen pendientes las revisiones humanas técnica, lingüística y pedagógica, así como la verificación del HTML del curso desplegado. No se ejecutó ningún shader, anfitrión Colossus, GPU ni aplicación Blender o Godot.

## La pregunta del proyecto

Un agente estira una pieza esculpida y gira un componente hijo. Las posiciones parecen matemáticamente válidas, pero ¿se debe seguir usando un eje local transformado como normal de la superficie? Una normal proporciona una dirección perpendicular a una superficie. La iluminación y el muestreo de superficies pueden usar esa dirección, por lo que conservar solo las posiciones no basta.

El caso procede de las [convenciones espaciales públicas de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs) y de la [composición anidada](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Generate.fs#L165), fijadas en el commit de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`. Las matrices actúan sobre vectores fila, y la matriz global de un hijo es su matriz local multiplicada por la de su padre. [CS-014](../../computer-science/cs-014-compose-brutal-scene-descriptions/) presenta ese orden; aquí probamos un invariante geométrico tras la composición.

## 1. Comprobar la perpendicularidad, además de la longitud unitaria

Consideremos una cara local de una caja con normal exterior en la dirección X positiva y tangentes en las direcciones Y y Z. Tras una transformación lineal invertible, una normal válida debe seguir teniendo producto escalar cero con ambas tangentes transformadas. Normalizar hace que la longitud de un vector sea uno; no corrige su dirección.

La [deducción de PBRT](https://pbr-book.org/4ed/Geometry_and_Transformations/Applying_Transformations) obtiene la regla de la inversa transpuesta para las normales a partir de esa condición de perpendicularidad. Mantén explícita la convención matricial al usar la fórmula. El programa nativo de comprobación didáctica llama a [Vector3.TransformNormal de .NET](https://learn.microsoft.com/dotnet/api/system.numerics.vector3.transformnormal?view=net-10.0) con la matriz global o con su inversa transpuesta calculada explícitamente. El nombre del método no toma esa decisión por quien lo llama.

### Ejercicio práctico 1: rechazar una normal normalizada pero inclinada

Una normal candidata unitaria tiene un producto escalar de 0.6 con una tangente unitaria de la superficie. ¿La normalización la ha convertido en una normal válida? Indica una prueba que compruebe la propiedad que falta.

> **Respuesta:** No. Un producto escalar distinto de cero significa que la candidata no es perpendicular a esa tangente. Comprueba sus productos escalares con dos tangentes transformadas independientes, usando una tolerancia numérica declarada. La longitud unitaria es otra propiedad; volver a normalizar la misma dirección no puede anular el producto escalar de 0.6.

## 2. Componer un caso que invalida el atajo

Usa un giro de guiñada de 45 grados del hijo bajo una escala del padre de `(2,1,1)`. En el orden de vectores fila, la matriz global lineal es `R45*S`. Sus ejes locales X y Z transformados son `(sqrt2,0,-1/sqrt2)` y `(sqrt2,0,1/sqrt2)`. Su producto escalar sin normalizar es 1.5, de modo que los ejes no son perpendiculares. Ambas longitudes son `sqrt(2.5)` y su producto escalar normalizado es 0.6.

Este cizallamiento efectivo surge de la composición. En el orden de control `S*R45`, los ejes escalados giran juntos y siguen siendo perpendiculares. Una única escala no uniforme en estas caras de caja alineadas con los ejes no produce automáticamente la misma discrepancia. Los [casos nativos realmente ejecutados](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/native-cases.json) conservan ambos órdenes en lugar de atribuir todos los errores únicamente a la escala.

### Ejercicio práctico 2: distinguir las dos composiciones

Calcula los productos escalares sin normalizar y normalizado de los ejes X/Z anidados indicados. ¿Para qué sirve un control con escala seguida de guiñada?

> **Respuesta:** El producto escalar sin normalizar es `2-0.5=1.5`; al dividirlo por el producto de las longitudes, 2.5, se obtiene 0.6. Con escala seguida de guiñada, los ejes transformados de la caja siguen siendo perpendiculares. El control muestra que importan el orden de composición y la geometría de la base resultante; la escala no uniforme por sí sola no explica este contraejemplo.

## 3. Comparar directamente las dos direcciones

Para esa cara, normalizar el eje X transformado da `(2/sqrt5,0,-1/sqrt5)`. Aplicar la inversa transpuesta y normalizar da `(1/sqrt5,0,-2/sqrt5)`. Esta última tiene producto escalar cero con la tangente Z transformada; la primera tiene producto escalar normalizado 0.6. El coseno entre las candidatas es 0.8, que corresponde aproximadamente a 36.869897646 grados.

La [comparación de normales](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/normal-comparison.json) separa las expresiones exactas de los cálculos reales de las funciones nativas en float32. Las comprobaciones nativas usan la tolerancia `1e-5`. Son direcciones calculadas, no errores medidos en píxeles ni pruebas de que alguien haya percibido un cambio de iluminación.

### Ejercicio práctico 3: verificar la corrección

Usando las dos candidatas unitarias indicadas y la tangente Z unitaria `(2/sqrt5,0,1/sqrt5)`, calcula el producto escalar de cada candidata con la tangente y el coseno entre las candidatas. ¿Qué invariante selecciona la dirección perpendicular?

> **Respuesta:** La candidata del eje transformado da `(4-1)/5=0.6`; la de la inversa transpuesta da `(2-2)/5=0`. El coseno entre las candidatas es `(2+2)/5=0.8`. La perpendicularidad selecciona la segunda dirección para esta cara transformada. La diferencia aproximada de 36.869897646 grados es geométrica, no una puntuación observada de calidad visual.

## 4. Localizar la parte del código que usa la dirección

El [shader de rasterización inspeccionado](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L453) ya usa una inversa transpuesta. Una [ruta separada de muestreo de caras para el enjambre](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L3625-L3638) normaliza un eje transformado de la caja y calcula el área de la cara a partir del producto vectorial de los otros ejes. Cuando los ejes transformados son ortogonales, esas direcciones normales coinciden; el caso compuesto creado para el ejercicio revela una suposición más limitada.

El [registro de esta nueva ejecución](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/native-execution.json) documenta funciones públicas F# ejecutadas de forma autónoma y borradores didácticos construidos explícitamente. No ejecuta ninguna de las dos rutas de Colossus, ninguna solicitud de escena incorporada ni el recorrido de generación. Una discrepancia fundamentada en el código para una colocación construida es un caso candidato a prueba. No demuestra un defecto visible en las escenas incorporadas actuales ni en un renderizador desplegado.

### Ejercicio práctico 4: redactar un hallazgo técnico acotado

Un agente afirma: «Todos los objetos estirados rompen la iluminación de BRUTAL». Sustituye esa afirmación por las pruebas reales y la siguiente comprobación que permita distinguir las posibilidades.

> **Respuesta:** El shader de rasterización de la revisión inspeccionada usa normales con inversa transpuesta; el muestreador de caras separado usa ejes transformados. Una guiñada anidada bajo una escala no uniforme, creada para el ejercicio, hace que esta última dirección no sea perpendicular en los cálculos CPU, mientras que el control ortogonal coincide. Después hay que ejecutar el muestreador real sobre esa colocación y comprobar sus consumidores y su salida antes de afirmar que existe un defecto de renderizado o visible. Aquí no se realizó esa ejecución del anfitrión.

## 5. Tratar la singularidad como una cuestión separada

El [validador existente](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Validate.fs) comprueba dimensiones locales de caja positivas y finitas y elementos finitos en la colocación. En los borradores didácticos realmente probados, una escala X cero supera esas comprobaciones, pero su determinante es 0 y su matriz no tiene inversa. Se rechazan una dimensión local negativa y una colocación con NaN. Todavía se pueden calcular los límites de la caja aplanada; no certifican un sólido no degenerado ni una normal utilizable mediante la inversa transpuesta.

Una regla propuesta para un anfitrión podría rechazar colocaciones singulares cuando un consumidor necesita una inversa. El contraargumento es que otro consumidor puede aceptar deliberadamente una primitiva aplanada. Restringir las transformaciones admitidas puede ser más sencillo que ampliar todos los muestreadores. Ambas opciones necesitan un requisito definido del consumidor y pruebas de compatibilidad; este curso no modifica ningún validador ni contrato público. [SEM-006](../../semiotics/sem-006-preserve-orientation-across-scene-frames/) trata la orientación por separado de la invertibilidad.

### Ejercicio práctico 5: no convertir la aceptación en una garantía

Se aceptó un borrador con escala cero y sus límites son finitos. ¿Puede un agente afirmar que todos los anfitriones pueden sombrearlo de forma segura? ¿Qué pruebas justificarían una comprobación adicional?

> **Respuesta:** No. La comprobación observada verifica la forma local y la finitud de la colocación, mientras que la matriz con escala cero es singular. Un consumidor que necesita invertirla requiere una regla explícita de tratamiento y una prueba real de esa ruta. Demostrar que el consumidor nunca necesita una inversa, o que maneja deliberadamente el caso aplanado, debilitaría la necesidad de un rechazo general. La aceptación, los límites finitos, la corrección de las normales y el renderizado observado siguen siendo resultados separados.
