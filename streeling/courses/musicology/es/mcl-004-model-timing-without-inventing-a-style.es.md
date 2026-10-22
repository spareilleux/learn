---
module_id: mcl-004-model-timing-without-inventing-a-style
department: musicology
course: "Modelar la temporización sin inventar un estilo"
level: intermediate
prerequisites: ["mcl-003-style-labels-as-evidence", "mus-004-rhythm-and-groove"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Modelar la temporización sin inventar un estilo

> **Alcance del borrador.** Anotaciones inventadas de partitura y de una supuesta interpretación, cálculos exactos e inspección de fuentes fijadas a una revisión. Siguen pendientes las revisiones técnicas humanas, musicales, lingüísticas y con estudiantes, así como la verificación del HTML desplegado del curso. No se evaluó ninguna grabación, oyente ni estilo interpretado.

## La pregunta del proyecto

Una lección de GA pide a un agente que explique un ritmo. ¿Debe describir la cuadrícula escrita, ajustar un modelo temporal o nombrar un estilo musical? Son afirmaciones distintas. En su [resumen publicado](https://online.ucpress.edu/mp/article-abstract/19/3/333/61900/Swing-Ratios-and-Ensemble-Timing-in-Jazz?redirectedFrom=fulltext), Friberg y Sundström describen proporciones temporales que dependen del tempo en una selección de grabaciones de jazz. Su [explicación alojada por los autores](https://www.speech.kth.se/music/performance/Texts/ensemble_swing.htm) también distingue los papeles dentro del conjunto. Estas observaciones limitadas aconsejan no tratar una proporción fija como definición universal de un estilo. Solo se leyeron el resumen y la página de los autores; no se reprodujo ni copió ningún audio asociado.

## 1. Separar la partitura y la anotación en dos columnas

Utilicemos los siguientes datos didácticos originales. Los pulsos son unidades absolutas de negra; los segundos son anotaciones creadas para el ejemplo, no mediciones extraídas de una grabación. C4 = MIDI 60 es nuestra convención de altura, pero esta tabla temporal no contiene alturas ni atribución instrumental.

| Inicio escrito en pulsos | Inicio anotado en segundos |
| --- | --- |
| 0 | 0 |
| 0.5 | 0.34 |
| 1 | 0.52 |
| 1.5 | 0.84 |
| 2 | 1.04 |
| 2.5 | 1.37 |
| 3 | 1.56 |
| 3.5 | 1.88 |

La frase termina en el pulso 4 y el segundo 2.08. Los intervalos entre comienzos de pulso duran 0.52 segundos, lo que corresponde a unas 115.384615385 negras por minuto. Esta frecuencia de referencia no sitúa los contratiempos escritos a mitad de los intervalos anotados.

### Ejercicio 1: situar un contratiempo

En un modelo de subdivisión igual que usa la separación de 0.52 segundos entre comienzos de pulso, ¿dónde caería el primer contratiempo? ¿A qué distancia queda del inicio anotado de 0.34 segundos y constituye esa diferencia un error de interpretación observado?

> **Respuesta:** La subdivisión igual está en 0.26 segundos. El inicio anotado llega 0.08 segundos, u 80 ms, más tarde. Es un residuo respecto al modelo elegido en datos inventados. No es un error observado, una etiqueta de género ni una prueba de que un intérprete deba cambiar.

## 2. Comparar modelos con un residuo declarado

Un modelo regular sitúa cada contratiempo a mitad de su intervalo de pulso. Un modelo fijo de 2:1 lo sitúa a dos tercios del intervalo. Una fracción común ajustada a partir de esos mismos contratiempos es `131/208`, con un desplazamiento de 0.3275 segundos dentro de cada pareja. Los comienzos de pulso permanecen en los anclajes declarados en cada modelo.

Entre los ocho inicios, el residuo absoluto medio es de 33.75 ms para el modelo regular, aproximadamente 9.583333333 ms para el modelo fijo y 3.75 ms para el modelo ajustado. El [registro temporal fijo](../../../../code/streeling/evidence/phrase-performance-2026-10-22/timing-models.json) conserva cada predicción y su residuo con signo. Un residuo menor en los datos de ajuste describe la adecuación a esos datos; no mide la calidad musical. El modelo ajustado utilizó los mismos datos con los que se evalúa, por lo que esta comparación no aporta validación independiente.

### Ejercicio 2: reconstruir la fracción ajustada

Los desplazamientos de contratiempo dentro de las parejas son de 0.34, 0.32, 0.33 y 0.32 segundos. Obtén su desplazamiento común por mínimos cuadrados y su fracción de la pareja de 0.52 segundos. ¿Qué afirmación seguiría sin justificar el menor residuo presentado?

> **Respuesta:** El desplazamiento medio es de 0.3275 segundos; al dividirlo por 0.52 se obtiene `131/208`. El modelo resultante tiene un residuo absoluto medio de 3.75 ms entre los ocho inicios. El menor residuo en los datos de ajuste no establece el género, un groove preferible, la destreza del intérprete ni un beneficio para el oyente.

## 3. Una instrucción de reproducción no es una anotación de interpretación

El [elemento swing de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/swing/) puede especificar una proporción para la reproducción a la que se aplique. Sus campos enteros positivos `first` y `second` describen esa instrucción; no identifican la procedencia de una tabla de inicios observados. Una instrucción fija de 2:1 daría un desplazamiento dentro de la pareja de aproximadamente 0.346666667 segundos con nuestra separación de referencia, sin reproducir los cuatro desplazamientos distintos del ejemplo.

No deduzcas de la especificación que existe una implementación completa de importación, exportación o reproducción. En esta lección no se ejecutó ninguna. Las condiciones de aplicación, los tipos de nota y las modificaciones temporales importan al implementar una conversión real. [MUS-024](../../music/en/mus-024-preserve-attacks-and-harmonic-boundaries.md) trata por separado la continuidad de los eventos de nota y las unidades.

### Ejercicio 3: acotar la afirmación sobre la exportación

Un agente sustituye la tabla por una sola instrucción de reproducción de 2:1 y promete una recreación exacta. ¿Qué diferencias quedan y qué exigiría una afirmación real de fidelidad?

> **Respuesta:** Un desplazamiento común cercano a 0.346666667 segundos no reproduce los desplazamientos distintos de 0.34, 0.32, 0.33 y 0.32. La instrucción es un modelo, no las anotaciones originales. Una recreación exacta exigiría conservar los detalles temporales, probar la conversión y observar su salida según las reglas de aplicación pertinentes. Aquí no se ejecutó nada de ello.

## 4. Cuantificar la pérdida de una representación concreta del código fuente

En el commit de GA `dc2e74cbd992a298f67efb928b5b3754615e1924`, el [analizador MIDI](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Parsers/MidiParser.fs) inspeccionado convierte los microsegundos por negra en BPM enteros mediante `60000000 / microsecondsPerQuarter`. Para 520000 microsegundos, la división entera da 115, mientras que la frecuencia de referencia es aproximadamente 115.384615385.

Si un consumidor posterior hipotético reconstruyera cuatro negras a partir de 115 BPM, obtendría unos 2.086956522 segundos en lugar de 2.08, una diferencia de aproximadamente 6.956521739 ms. Es un cálculo condicional apoyado en el código fuente. No se ejecutó ningún analizador, importador ni ruta de reproducción, y el cálculo no demuestra una deriva real de GA ni una diferencia perceptible. Los [tipos MIDI](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MidiTypes.fs), en otro archivo, también declaran deltas en ticks y un campo de división temporal; esas declaraciones no constituyen por sí solas una cronología acumulada de interpretación.

### Ejercicio 4: distinguir una consecuencia modelada de un fallo observado

Calcula los BPM enteros y la duración hipotética de cuatro negras a partir del valor indicado en microsegundos. ¿Puede el agente calificar la diferencia resultante como un fallo de reproducción observado?

> **Respuesta:** Los BPM enteros son 115. La duración reconstruida es `240/115` segundos, aproximadamente 2.086956522, y supera 2.08 en unos 6.956521739 ms. No: el cálculo caracteriza una elección de representación bajo un consumidor hipotético. Afirmar un fallo real exige una ruta probada y una salida registrada.

## 5. Preservar el orden al cambiar las coordenadas temporales

Une los anclajes de pulso/segundo mediante una misma función estrictamente creciente y lineal por tramos, y aplícala a cada inicio y final. Como conserva el orden, dos intervalos de nota semiabiertos se solapan antes de la conversión exactamente cuando se solapan después. Por tanto, el [ejemplo de ocupación de cuerdas](../../guitar-studies/en/gtr-005-plan-which-string-keeps-ringing.md) sigue siendo inviable con el solapamiento de D anticipado y su límite de traste tras esa transformación común.

Cambiar únicamente el inicio de D del pulso 1.5 al 2 es otra operación. En esta transformación creada para el ejemplo, pasa de 0.84 a 1.04 segundos, o 200 ms, mientras su final permanece fijo. Puede cambiar el solapamiento y acortar la nota. La alternativa de 250 ms tratada en [GAA-005](../../guitar-alchemist-academy/en/gaa-005-repair-a-phrase-without-hiding-the-change.md) supone, en cambio, una frecuencia constante de 120 negras por minuto. No mezcles estas referencias.

### Ejercicio 5: explicar por qué cuantizar no es neutro

¿Aplicar la misma función estrictamente creciente a todos los límites resuelve un conflicto de ocupación de cuerdas? ¿En qué se diferencia de mover un solo inicio?

> **Respuesta:** La transformación común conserva todos los solapamientos y, por tanto, la viabilidad de la asignación del modelo. Mover un solo inicio puede cambiar el solapamiento, la articulación y la duración respecto a un final sin cambios. Es una modificación musical que requiere una intención explícita, no un mero cambio de unidades temporales ni una prueba de un estilo mejor.
