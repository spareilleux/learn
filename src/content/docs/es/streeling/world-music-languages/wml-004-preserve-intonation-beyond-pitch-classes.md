---
title: Conservar la entonación más allá de las clases de altura
description: Conservar la entonación más allá de las clases de altura — Músicas y lenguas del mundo
sidebar:
  label: WML-004 · Conservar la entonación más allá de las clases de altura
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/es/wml-004-preserve-intonation-beyond-pitch-classes.es.md
---

:::note[Streeling University]
**WML-004** · Conservar la entonación más allá de las clases de altura · intermedio · 35 minutos

Generado por el departamento *Músicas y lenguas del mundo* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/es/wml-004-preserve-intonation-beyond-pitch-classes.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-002](../../world-music-languages/wml-002-dadgad-layout-and-cultural-claims/)
:::

> **Alcance del borrador.** Inspección de fuentes públicas en una revisión concreta y cálculos con frecuencias construidas. Siguen pendientes la revisión técnica humana, la revisión por un músico, la revisión lingüística, los intentos de alumnos y la verificación del HTML desplegado. Aquí no se mide ninguna tradición interpretada, renderización de audio de GA ni resultado de escucha.

## La pregunta del proyecto

Un agente envía una escala de un catálogo a una herramienta para guitarra y afirma que su entonación se ha conservado. ¿Qué información respaldaría esa afirmación? En el [modelo de escalas del mundo de Guitar Alchemist](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/WorldScalesConfig.fs), los intervalos se documentan como pasos de semitonos enteros, las clases de altura como valores dentro de un sistema de doce pasos y la afinación como una anotación de texto. Estos campos sirven para buscar en el catálogo. No declaran una frecuencia ni un valor en cents estructurado para cada grado.

El campo de afinación del modelo es una cadena de texto corriente, no una enumeración impuesta en la definición inspeccionada. Leer un modelo no demuestra que se validen todos los valores del catálogo ni establece el comportamiento de todos los subsistemas de GA. Este curso sigue interfaces concretas en el commit `dc2e74cbd992a298f67efb928b5b3754615e1924`.

## 1. Conservar la etiqueta de aproximación

La [entrada Rast almacenada](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/WorldScales/MaqamScales.yaml) contiene los intervalos `[2,2,1,2,2,2,1]`, las clases de altura `[0,2,4,5,7,9,11]`, la máscara 2741 y la anotación de afinación `approx-12tet`. Reconstruir la máscara como la suma de `1 << p` para esas clases de altura da 2741. La anotación debe acompañar al resultado: la aproximación almacenada en doce pasos no es una descripción certificada de la entonación interpretada.

La [página sobre Rast de MaqamWorld](https://maqamworld.com/en/maqam/rast.php), escrita por un músico, trata las relaciones entre jins y ejemplos del repertorio. Una máscara compartida de clases de altura no permite establecer esas relaciones, el fraseo, la práctica ni la identidad musical. No se copió, reprodujo ni analizó ninguna grabación enlazada en este conjunto de evidencias. No convierta un texto de catálogo sin revisar en autoridad musical.

### Ejercicio práctico 1: interpretar una máscara coincidente

Un agente encuentra la máscara 2741 tanto en esta entrada Rast como en un conjunto de clases de altura de una escala mayor. ¿Qué ha coincidido y qué anotación debe seguir visible?

> **Respuesta:** Ha coincidido el conjunto seleccionado de clases de altura del sistema de doce pasos. Conserve `approx-12tet`, la tradición de la entrada y la identidad de su fuente. La coincidencia no establece una práctica interpretativa equivalente, una entonación exacta ni un significado musical intercambiable.

## 2. Medir la información que pierde una proyección

Utilice A4 = 440 Hz y la fórmula de referencia de doce pasos `f(m)=440*2^((m-69)/12)`. C4, con el número MIDI 60 bajo esta referencia, equivale a 261.625565301 Hz. Construya un tono en `f_a=(5/4)*f(60)` y otro en `f_b=f(64)`. Sus frecuencias son 327.031956626 Hz y 329.627556913 Hz, respectivamente.

Un [cent musical](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z) corresponde a una razón de frecuencias de `2^(1/1200)`. Por tanto, `1200*log2(f_a/f(60))` da 386.313713865 cents, mientras que el segundo tono está 400 cents por encima de la tónica de referencia. El primero está 13.686286135 cents por debajo del segundo. Este ejercicio de razones es una construcción matemática original. **No prescribe un grado de razón 5:4 para Rast ni para ninguna tradición.**

### Ejercicio práctico 2: recuperar el desplazamiento

Calcule la distancia en cents desde la tónica de referencia hasta la construcción de razón 5:4 y su desplazamiento con signo respecto al tono de 400 cents. ¿Especifica este cálculo la interpretación de Rast?

> **Respuesta:** `1200*log2(5/4)` da 386.313713865 cents. Al restar 400 se obtiene -13.686286135 cents. El signo indica que el primer tono construido es más grave. El cálculo solo establece una relación entre razones; no especifica la práctica interpretativa de ninguna tradición.

## 3. Distinguir una proyección definida para el curso de un convertidor observado

Defina una proyección didáctica: calcule `u=69+12*log2(f/440)` y elija el paso entero más cercano. Los dos tonos construidos dan aproximadamente 63.863137139 y 64, por lo que esta regla asigna ambos a MIDI 64. Si solo se conserva ese entero, se pierde su diferencia. Esta regla se definió para la lección; aquí no se ejecutó ni certificó ningún convertidor de frecuencia a MIDI de GA.

Dos alternativas orientativas de transferencia conservan el objetivo construido: la frecuencia 327.031956626 Hz con la referencia A4 = 440 Hz, o MIDI 64 con un desplazamiento de -13.686286135 cents y la misma referencia. Son alternativas didácticas, no un esquema ratificado ni un contrato entre repositorios ya implementado. La referencia, las unidades, la procedencia y el estado de aproximación deben acompañar cualquier significado que se quiera transmitir.

### Ejercicio práctico 3: corregir la afirmación sobre la transferencia

Los dos tonos llegan como MIDI 64. ¿Puede el receptor recuperar su diferencia original? Proponga un valor que permita distinguirlos sin afirmar que existe un nuevo esquema de GA.

> **Respuesta:** El entero por sí solo no permite recuperar la diferencia. Conserve una frecuencia con su referencia, o MIDI 64 con un desplazamiento explícito en cents y una referencia. El desplazamiento del primer tono es de -13.686286135 cents; el del segundo es de 0. Marque estos registros como ejemplos orientativos y conserve la procedencia. Su existencia en esta lección no demuestra que una implementación los admita.

## 4. Seguir la representación real de cada interfaz

El [objeto de valor MidiNote](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Primitives/Notes/MidiNote.cs) representa un entero entre 0 y 127, con la clase de altura calculada módulo 12. El [mapeador de posiciones del diapasón](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Analysis/FretboardPositionMapper.cs) resta el MIDI de la cuerda al aire al MIDI objetivo y comprueba el rango de trastes. Estas interfaces concretas son discretas.

En cambio, el [punto de entrada de audio en Rust](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs) acepta `freq:f32` en `engine_note_on` y lo transmite a la excitación. Un argumento de frecuencia en coma flotante constituye otra representación. Su firma por sí sola no demuestra que una renderización produzca con precisión la altura solicitada. Conserve el objetivo durante todo el recorrido y después mida la señal resultante antes de afirmar su fidelidad.

### Ejercicio práctico 4: localizar la prueba pendiente

Un receptor acepta una frecuencia en coma flotante. ¿Demuestra eso que un desplazamiento ha sobrevivido a la búsqueda en el catálogo, al mapeo del diapasón y a la síntesis de audio? Indique las evidencias que siguen siendo necesarias.

> **Respuesta:** No. Siga el objetivo conservado, la referencia y las unidades a través de cada interfaz, identifique cualquier proyección discreta y mida la frecuencia renderizada respecto al objetivo previsto. El argumento flotante demuestra la aceptación en un punto de entrada; no certifica la transferencia previa ni el audio resultante.

## 5. Ajustar la conclusión a la consulta

La [consulta real de nombres de intervalos de GA](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/ga-intervals-probe.json) para C devolvió `P1, M3, P5`. No devolvió frecuencia, cents, referencia de afinación, interpretación ni revisión de las fuentes en ejecución. El [registro de cálculo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/intonation.json) contiene por separado la construcción definida para el curso y los campos del catálogo. No los combine para anunciar un éxito de extremo a extremo que no se ha observado.

### Ejercicio práctico 5: redactar una conclusión acotada para el agente

Un agente dice: «La consulta de intervalos confirma que el motor de guitarra conserva la entonación de Rast». Sustituya esa afirmación por una conclusión respaldada por estas evidencias.

> **Respuesta:** La consulta para C devolvió nombres de intervalos. Las fuentes en la revisión indicada exponen una aproximación de Rast de doce pasos y, por separado, un punto de entrada de audio con frecuencia flotante. El cálculo construido muestra cómo una proyección a un entero puede perder una diferencia en cents. Siguen sin verificarse la conservación en un pipeline real, la validez musical y los resultados de escucha.

## Evidencias y próximo experimento

El [registro de fuentes públicas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/primary-readback.json) vincula ocho archivos al commit indicado. [PHY-007](../../physics/phy-007-separate-beating-from-decay/) usa las mismas frecuencias construidas para examinar la interferencia; [COG-004](../../cognitive-science/cog-004-score-a-pitch-discrimination-task/) distingue la separación numérica de un resultado de escucha observado. Una futura lección sobre una tradición concreta necesita la revisión de un músico y evidencias interpretadas pertinentes antes de formular afirmaciones sobre la práctica.
