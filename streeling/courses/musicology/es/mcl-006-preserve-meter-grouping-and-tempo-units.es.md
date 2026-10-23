---
module_id: mcl-006-preserve-meter-grouping-and-tempo-units
department: musicology
course: "Conservar la agrupación métrica y las unidades de tempo"
level: intermediate
prerequisites: ["mcl-004-model-timing-without-inventing-a-style", "mcl-005-preserve-written-and-sounding-pitch"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar la agrupación métrica y las unidades de tempo

> **Alcance del borrador.** Aritmética de compases completos creada para el curso, lectura de especificaciones primarias e inspección de código fijado a una revisión. Quedan pendientes las revisiones humanas técnica, musical, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se probaron un analizador, un importador de partituras, un motor de reproducción ni un intérprete.

## La pregunta del proyecto

Un guitarrista pide a GA que conserve una agrupación escrita al importar un patrón de práctica. Conservar la duración total es necesario, pero no basta para conservar dónde empiezan los grupos. Esta lección distingue indicación de compás, secuencia de grupos, unidades de duración de la partitura y unidad del metrónomo antes de seguir los límites reales de representación del proyecto.

La [referencia de time de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/time/) permite un numerador aditivo en un par numerador/denominador y varios pares para denominadores mixtos. Por tanto, una indicación simple 7/8 y una explícita 2+2+3 sobre 8 contienen distinta información de agrupación aunque coincida la duración total del compás. Estos campos escritos no implican automáticamente un acento interpretado ni una identidad cultural.

## 1. Nombrar qué se repite por minuto

Estipula un compás completo de 7/8, tempo constante de negra 120 por minuto, sin anacrusa ni cambio de tempo. Cada negra dura 0.5 segundos y cada corchea 0.25 segundos. El compás dura 1.75 segundos. Si el metrónomo cuenta en cambio corcheas a 120 por minuto, cada corchea dura 0.5 segundos y el compás 3.5 segundos.

La [referencia de metronome de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/metronome/) combina un grupo beat-unit con un valor per-minute para una indicación ordinaria. La [definición de beat-unit](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/beat-unit/) identifica su valor gráfico de nota; [per-minute](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/per-minute/) también puede contener texto. Aquí el número 120 es una premisa explícita, no una interpretación universal de cualquier texto de indicación. El denominador del compás por sí solo no especifica la unidad del metrónomo.

### Ejercicio 1: desambiguar el tempo

Compara un compás de 7/8 a negra 120 con el mismo compás a corchea 120. Indica cada duración e identifica el campo ausente en una instrucción que solo diga «7/8, 120 BPM».

> **Respuesta:** El primero dura 1.75 segundos; el segundo, 3.5 segundos. Falta el valor de nota nombrado como unidad del metrónomo. Un denominador 8 no resuelve por sí solo esa omisión.

## 2. Conservar una agrupación además de una suma

Usa los grupos didácticos de 2+2+3 corcheas. Sus inicios dentro del compás son las posiciones de pulso de corchea 0, 2 y 4. Una indicación de denominadores mixtos 2/4+3/8 suma las mismas siete corcheas, pero separa explícitamente cuatro corcheas de tres. Sus componentes empiezan en 0 y 4. Reducir ambas indicaciones al total 7/8 borra esa distinción.

Son agrupaciones declaradas de partitura. Llamar a cada inicio un acento fuerte interpretado añadiría una realización no observada. Un informe útil del importador puede mostrar por separado el texto de compás introducido, la secuencia de grupos conservada y cualquier aproximación, además de los comentarios de audio o del intérprete.

### Ejercicio 2: comparar totales iguales

Indica las longitudes de grupo y los inicios en unidades de pulso de corchea para 2+2+3 sobre 8 y para 2/4+3/8. ¿Establece una duración total igual la misma agrupación o los mismos acentos tocados?

> **Respuesta:** El primero tiene longitudes 2, 2, 3 e inicios 0, 2, 4. El segundo tiene longitudes 4, 3 e inicios 0, 4. Ambos suman 7 corcheas; ni agrupación igual ni acentos tocados iguales se derivan de esa suma.

## 3. Distinguir las divisiones de partitura del denominador

Estipula 24 divisiones por negra. La [definición de divisions de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/divisions/) fija la referencia de negra para estas unidades. Una corchea ocupa 12 divisiones, así que el compás de siete corcheas ocupa 84. Sus límites 2+2+3 son 0, 24, 48 y 84 divisiones. Los límites de componentes de denominador mixto son 0, 48 y 84.

Con la misma referencia de divisiones y negra 120, un compás de 6/8 y uno de 3/4 abarcan ambos 72 divisiones y 1.5 segundos. Esa aritmética no especifica la misma agrupación ni el mismo pulso de dirección musical. La [referencia de duration](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/duration/) también tiene reglas de posición de partitura: contar cada elemento de nota como un avance independiente no es un algoritmo general de temporización para varias voces o acordes. Aquí no se ejecutó tal algoritmo.

### Ejercicio 3: reconstruir las unidades

A 24 divisiones por negra, calcula una corchea, un compás de 7/8 y el total de cada uno de 6/8 y 3/4. ¿Qué equivalencia más fuerte no demuestra la última igualdad?

> **Respuesta:** Una corchea son 12 divisiones; 7/8 son 84; 6/8 y 3/4 son 72 cada uno. Los totales iguales no establecen la misma estructura de grupos, unidad de metrónomo, acento interpretado ni interpretación musical. Las divisiones de partitura no son automáticamente la resolución en ticks del archivo MIDI.

## 4. Seguir el límite exacto del importador

En el commit de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`, el [tipo de compás de MusicXML](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L115-L138) conserva un numerador entero y un denominador entero. El [analizador de compás](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L123-L138) selecciona el primer hijo de cada nombre e intenta analizar sus textos como enteros.

Para las entradas fijas seleccionadas, la inspección estática predice 7 y 8 para 7/8 simple; ningún valor de compás para el texto de numerador `2+2+3`; y solo 2 y 4 para la entrada de dos pares 2/4+3/8. La última predicción descarta el segundo par en lugar de conservar una suma 7/8. Son predicciones derivadas del código, no resultados de importador recién ejecutados. Identifican casos límite concretos que probar antes de prometer una importación fiel.

### Ejercicio 4: evitar una afirmación falsa de normalización

Indica los tres resultados predichos. ¿Por qué no respaldaría este código que «el importador normaliza fielmente ambas formas compuestas a 7/8»?

> **Respuesta:** 7/8 simple predice los enteros 7 y 8. El texto aditivo del numerador `2+2+3` predice ningún valor de compás. Dos pares 2/4 y 3/8 predicen solo 2 y 4. La rama inspeccionada ni conserva la expresión aditiva ni suma los pares; no se obtuvo ningún resultado nuevo en ejecución.

## 5. Explicitar la comprobación de transferencia

Los [tipos MIDI](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MidiTypes.fs#L19-L46) también representan un evento de indicación de compás como dos enteros. El [cuerpo seleccionado de la rama de metadatos](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L208-L217) eleva 2 al exponente del denominador y omite los otros dos bytes de la carga útil. Si se alcanzara este cuerpo, una carga útil didáctica con bytes 7, 3, 24, 8 construiría 7/8. No proporcionaría una agrupación ordenada 2+2+3 conservada.

**Corrección de alcanzabilidad del código.** El distribuidor circundante enmascara el estado para conservar su medio byte alto antes de buscar un estado completo de metaevento, así que esta rama de metaevento es inalcanzable mediante la selección mostrada. El ejemplo de carga útil anterior es una interpretación condicional del cuerpo, no una predicción válida de análisis MIDI satisfactorio. [MCL-007](mcl-007-integrate-a-midi-tempo-map-before-scheduling.md) explicita esa distinción. Las predicciones de la rama MusicXML de la sección anterior son observaciones separadas del código.

### Ejercicio 5: especificar una comprobación útil de importación

¿Qué puede conservar esa rama MIDI seleccionada de la carga útil didáctica? Indica la comparación adicional necesaria antes de que un agente diga que el ejercicio agrupado de un guitarrista sobrevivió a una ruta de importación y exportación.

> **Respuesta:** Si se alcanzara ese cuerpo seleccionado, construiría numerador 7 y denominador 8 y omitiría los bytes de carga útil 24 y 8. El distribuidor circundante real no lo alcanza, así que no llames a esos valores salida del analizador. La representación de evento tampoco contiene el orden de grupos didáctico. Compara los textos de compás introducidos y recuperados, los límites de grupos, las unidades de duración y la unidad nombrada de metrónomo en una ruta fijada a una revisión y ejecutada; examina por separado la partitura representada y la reproducción prevista. Aquí no se midió una pérdida de todo el sistema ni una ida y vuelta satisfactoria.

El [paquete fijado](../../../../code/streeling/evidence/meter-picking-2026-10-22/README.md) conserva cálculos exactos, predicciones del código y hashes del código público. [WML-006](../../world-music-languages/en/wml-006-preserve-the-origin-of-an-additive-cycle.md) sigue qué hace un cambio de origen de ciclo a la misma agrupación.
