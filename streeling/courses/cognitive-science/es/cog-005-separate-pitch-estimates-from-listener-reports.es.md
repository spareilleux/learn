---
module_id: cog-005-separate-pitch-estimates-from-listener-reports
department: cognitive-science
course: "Separar las estimaciones de altura de las respuestas de los oyentes"
level: intermediate
prerequisites: ["cog-004-score-a-pitch-discrimination-task", "gas-005-separate-a-partial-peak-from-a-period"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separar las estimaciones de altura de las respuestas de los oyentes

> **Alcance del borrador.** Comparaciones originales de señales matemáticas y diseño preparado de una tarea de escucha. Siguen pendientes las revisiones humanas técnica, musical o perceptiva y lingüística, las pruebas con estudiantes y la verificación del HTML publicado. No se observó ningún participante, estímulo reproducido, respuesta perceptiva ni resultado de aprendizaje.

## La pregunta del proyecto

Un agente de guitarra predice una frecuencia de repetición y después considera equivocado al oyente que comunica otra altura. Ha cambiado la pregunta «¿qué oyó la persona?» por «¿qué respuesta coincide con mi algoritmo?». Un ejercicio útil de dogfooding mantiene separados esos dos resultados.

El [resumen indexado de la revisión de Oxenham de 2012](https://pubmed.ncbi.nlm.nih.gov/23015422/) describe la frecuencia de repetición como un correlato físico principal de la altura, a la vez que destaca interacciones que complican la percepción. Para esta lección solo se leyó ese resumen; no se reprodujo ningún protocolo ni grabación del artículo completo. Los ejemplos originales siguientes comparan predicciones numéricas explícitas. No establecen una percepción universal ni una clasificación individual de un oyente.

## 1. Definir la respuesta antes de elegir su clave de corrección

Una tarea técnica puede preguntar por el período fundamental de una señal suministrada. Su respuesta se deduce de las matemáticas declaradas. Una tarea perceptiva puede preguntar al participante cuál de dos sonidos le parece más agudo, o pedirle que ajuste un tono de referencia. Ese resultado es una respuesta registrada con sus propias unidades y procedimiento. No es automáticamente la misma variable que un pico espectral, un desplazamiento de recurrencia, una preferencia de realismo o una puntuación de aprendizaje.

Si el objetivo es la exactitud algorítmica frente a una frecuencia construida conocida, declare esa referencia y la regla de puntuación. Si el objetivo es investigar la percepción, conserve la respuesta del participante antes de interpretarla. «Diferente del detector» puede ser una observación; «incorrecto» requiere un criterio justificado específico de la tarea.

### Ejercicio 1: separar los resultados

Un evaluador pregunta «¿Cuál suena más agudo?», pero solo puntúa la coincidencia con un resultado de autocorrelación. ¿Qué distinción se ha perdido y qué debe conservarse?

> **Respuesta:** El evaluador ha sustituido una respuesta perceptiva por una referencia técnica definida por el modelo. Conserve la pregunta real, las condiciones de los estímulos, la elección o el ajuste del participante y la predicción separada del algoritmo. La coincidencia puede analizarse bajo una hipótesis explícita, pero no define retroactivamente lo que oyó el participante ni mide el realismo o el aprendizaje.

## 2. Construir predicciones numéricas opuestas

Los [controles originales](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/synthetic-periods.json) usan sumas de cosenos de fase cero de un segundo, con amplitudes de 0.3, 0.2 y 0.1 a una frecuencia de muestreo de 48000 Hz:

| Complejo | Componentes suministradas, Hz | Componente más fuerte, Hz | Frecuencia fundamental de repetición, Hz |
| --- | --- | --- | --- |
| A | 1000, 1200, 1400 | 1000 | 200 |
| B | 1050, 1200, 1350 | 1050 | 150 |

La componente más fuerte sube 50 Hz de A a B, mientras que la frecuencia de repetición baja 50 Hz. Sus cambios en cents son aproximadamente +84.467193470 y -498.044999135, respectivamente. Son dos comparaciones numéricas opuestas, no una predicción de que todo oyente deba usar una de ellas ni siquiera de que experimente una única altura inequívoca.

### Ejercicio 2: conservar el conflicto

¿Qué complejo es más alto según la comparación de las componentes más fuertes y cuál según la comparación de las frecuencias fundamentales de repetición? ¿Puede esta tabla por sí sola determinar la elección de un participante real?

> **Respuesta:** B es más alto según la comparación de las componentes más fuertes, 1050 frente a 1000 Hz. A es más alto según la repetición fundamental, 200 frente a 150 Hz. El conflicto matemático motiva una tarea de respuesta; no aporta una elección observada de un participante ni demuestra que toda percepción siga una sola regla.

## 3. La igualación matemática del nivel no certifica la reproducción

Para los controles coherentes sin fundidos, el valor medio de los cuadrados es `(0.3²+0.2²+0.1²)/2 = 0.07`, por lo que ambos valores RMS son aproximadamente 0.264575131. Sus picos de fase cero son de 0.6. Estas igualdades se refieren a las matrices originales. El análisis no generó WAV de escucha ni reprodujo nada.

Un ensayo real necesita archivos de reproducción preparados, tratamiento de los inicios y finales, nivel y formato verificados, una cadena de reproducción documentada y un procedimiento que evite revelar la respuesta prevista. Aplicar fundidos cambia las matrices; vuelva a medir los archivos reales en lugar de copiar el RMS sin fundidos en sus metadatos. La coincidencia numérica de RMS tampoco establece una sonoridad percibida igual ni elimina todas las pistas espectrales.

### Ejercicio 3: distinguir un conjunto de control de un ensayo listo

Calcule los valores matemáticos de media de los cuadrados y RMS. Un agente añade después fundidos y afirma que los estímulos finales ya están igualados y probados. ¿Qué pruebas faltan?

> **Respuesta:** La media de los cuadrados es 0.07 y el RMS es aproximadamente 0.264575131 para cada matriz coherente sin fundidos. Los archivos reales con fundidos y codificados necesitan hashes, nuevas mediciones de nivel y pico, condiciones de reproducción y un ensayo de presentación documentado. La igualdad del cálculo sin fundidos no es una prueba de reproducción ejecutada ni una sonoridad percibida igual. Aquí no se produjeron archivos de escucha ni se reclutaron participantes.

## 4. Mantener independientes el orden, las instrucciones y la interpretación

Antes de un futuro ensayo, defina la respuesta del participante, las instrucciones, la familiarización permitida, el orden de presentación y el análisis. Contrabalancee las presentaciones A/B y B/A sin revelar las etiquetas matemáticas. Registre las identidades reales de los estímulos, el orden, la respuesta y cualquier exclusión. No entrene a los participantes para elegir la respuesta del detector mientras afirma estudiar una percepción espontánea.

Un control inequívoco de tonos puros puede comprobar si el participante entendió la dirección solicitada bajo sus condiciones declaradas. No establece que un complejo ambiguo deba juzgarse por la misma pista. Una tarea de igualación de tonos puede revelar información distinta de una comparación forzada; cambiar la tarea cambia el resultado estudiado. [COG-004](cog-004-score-a-pitch-discrimination-task.md) trata por separado las claves de respuesta y el cálculo exacto de puntuaciones por azar.

### Ejercicio 4: corregir un procedimiento sesgado

La interfaz etiqueta A como «200 Hz, correcto» antes de preguntar cuál suena más agudo. El evaluador llama después error auditivo al desacuerdo. Proponga un procedimiento mejor y una interpretación acotada.

> **Respuesta:** Oculte las etiquetas del modelo durante la tarea perceptiva, declare la pregunta y el orden contrabalanceado, conserve las respuestas reales y utilice controles de comprensión adecuados. Compare después las respuestas con las predicciones separadas del algoritmo bajo una hipótesis declarada. El desacuerdo por sí solo no diagnostica un problema auditivo ni demuestra que el participante no entendiera un complejo ambiguo. Aquí no se realizó ninguna prueba de ese tipo con participantes.

## 5. Aportar pruebas diferentes para decisiones diferentes

Para calibrar un detector, use los períodos construidos conocidos y tolerancias definidas explícitamente. Para una tarea de afinación del motor, conserve la referencia del estimador, su incertidumbre y las entradas realmente renderizadas. Para una afirmación perceptiva o de preferencia, exija el procedimiento correspondiente con participantes y sus observaciones. Para el aprendizaje, exija una evaluación adecuada de los estudiantes. Nada de ello se obtiene simplemente cambiando el nombre de una puntuación numérica.

El [análisis de guitarra conservado](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/native-pitch-windows.json) contiene cuatro estimaciones de recurrencia con puntuaciones altas que incumplen su control declarado de proximidad a la referencia nominal. Es una advertencia concreta sobre la interpretación de las puntuaciones, no una prueba de lo que oyó un guitarrista. La tarea preparada en este paquete sigue sin ejecutarse y sus resultados siguen sin registrarse.

### Ejercicio 5: redactar la conclusión del agente

Un agente afirma: «Una alta confianza en la periodicidad demuestra que los oyentes prefieren la guitarra corregida». Sustituya esa frase por afirmaciones respaldadas y las pruebas que faltan.

> **Respuesta:** La puntuación de recurrencia describe la coincidencia entre formas de onda según el estimador declarado; no es una confianza perceptiva calibrada. Los controles construidos verifican determinadas predicciones matemáticas y los resultados de las ventanas conservadas incumplen el control declarado respecto a la referencia nominal. La altura percibida por los oyentes, su preferencia por la guitarra y cualquier beneficio de una corrección necesitan sus propios estímulos reales, protocolo de comparación y respuestas. Aquí no se observó ninguna corrección, preferencia ni resultado de escucha.
