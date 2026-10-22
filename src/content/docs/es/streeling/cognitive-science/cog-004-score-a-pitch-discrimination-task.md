---
title: Puntuar una tarea de discriminación de altura sin inventar un resultado de escucha
description: Puntuar una tarea de discriminación de altura sin inventar un resultado de escucha — Ciencia cognitiva
sidebar:
  label: COG-004 · Puntuar una tarea de discriminación de altura sin inventar un resultado de escucha
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/es/cog-004-score-a-pitch-discrimination-task.es.md
---

:::note[Streeling University]
**COG-004** · Puntuar una tarea de discriminación de altura sin inventar un resultado de escucha · intermedio · 35 minutos

Generado por el departamento *Ciencia cognitiva* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/es/cog-004-score-a-pitch-discrimination-task.es.md) · [Mi diario](../../journal/)

Requisitos previos: [COG-003](../../cognitive-science/cog-003-calibrating-fretboard-confidence/)
:::

> **Alcance del borrador.** Clave pública de respuestas definida para el curso, respuestas sintéticas, cálculos exactos de probabilidades y archivos de tonos originales preparados. Siguen pendientes la revisión técnica humana, la revisión lingüística, los intentos de participantes, los resultados de escucha y la verificación del HTML desplegado. No hay oyentes observados en este conjunto de evidencias.

## La pregunta del proyecto

Un agente puede producir dos frecuencias distintas y puntuar respuestas. Eso no demuestra que un guitarrista haya oído la diferencia, preferido un sonido ni aprendido nada. El [resumen de Creelman y Macmillan sobre procedimientos auditivos](https://pubmed.ncbi.nlm.nih.gov/528924/) describe cómo la sensibilidad medida depende del procedimiento psicofísico. Aquí solo se leyó el resumen indexado; no valida nuestros estímulos ni a ningún oyente.

Esta lección define una tarea concreta: después de dos intervalos temporales secuenciales con un tono aislado cada uno, elegir cuál contiene la frecuencia más alta. El [registro de frecuencias construidas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/intonation.json) da 327.031956626 Hz y 329.627556913 Hz, separadas por 13.686286135 cents. La construcción de la razón no prescribe la práctica de una tradición musical. [WML-004](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/) aborda ese límite.

## 1. Definir la pregunta antes de puntuar

Los archivos preparados [tono A](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/tone-a.wav) y [tono B](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/tone-b.wav) son PCM16 mono a 44100 Hz y duran un segundo cada uno. Tienen fundidos de 10 ms en los extremos. Su RMS en coma flotante se igualó a 0.05 antes de la cuantización; el [registro de archivos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/audio-assets.json) conserva las mediciones decodificadas. Ninguna preparación numérica del nivel demuestra una sonoridad percibida igual, una reproducción calibrada ni una presentación efectiva de los estímulos.

La respuesta solicitada es el intervalo 1 o el intervalo 2. No es una valoración de calidad sonora, una preferencia de afinación, una estimación de confianza ni una prueba de memoria. La mezcla simultánea de [PHY-007](../../physics/phy-007-separate-beating-from-decay/) sirve para otra tarea y no debe sustituir estos estímulos secuenciales sin indicarlo.

### Ejercicio práctico 1: identificar el resultado

Un participante elige el intervalo 2 cuando contiene el tono más agudo. ¿Qué resultado definido es correcto y qué conclusiones más amplias no pueden inferirse de esa respuesta por sí sola?

> **Respuesta:** La respuesta es correcta para la tarea de discriminación de la frecuencia más alta. Una sola respuesta no establece una capacidad estable, un umbral perceptivo, una preferencia sonora, una calidad de afinación ni un aprendizaje. También habría que registrar la presentación real del estímulo y las evidencias del participante antes de tratarla como un resultado observado.

## 2. Auditar un conjunto de datos aritmético deliberadamente público

La [traza sintética](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/synthetic-trials.json) tiene 20 ensayos definidos para el curso. El intervalo correcto es 1 en los identificadores impares y 2 en los pares. Las respuestas son deliberadamente incorrectas en los identificadores 3, 7, 12, 16 y 20, y correctas en los demás. Esta clave pública alterna resulta cómoda para comprobar la aritmética. No es una secuencia de escucha aleatoria, oculta ni administrada.

La traza obtiene 15/20, o 0.75. Elegir siempre el intervalo 1 obtiene 10/20, o 0.5. Los recuentos condicionales son 8/10 respuestas correctas cuando el tono más agudo va primero y 7/10 cuando va segundo. El participante sintético elige el intervalo 1 once veces. Son resúmenes diferentes; ninguno convierte respuestas inventadas en datos de participantes.

### Ejercicio práctico 2: comprobar los resúmenes por posición

Cinco respuestas definidas para el curso son incorrectas. Indique la exactitud global, la referencia de elegir siempre el primero y los dos recuentos condicionales de respuestas correctas. ¿Publicar estos números establecería el rendimiento de un oyente?

> **Respuesta:** La exactitud global es 15/20 = 0.75; la referencia de elegir siempre el primero es 10/20 = 0.5. Los recuentos condicionales son 8/10 y 7/10 para los ensayos con el tono más agudo primero y segundo, respectivamente. Solo auditan el conjunto de datos. Ningún participante completó esta secuencia, así que no se observó ningún rendimiento de escucha.

## 3. Distinguir una regla de decisión de una probabilidad posterior

Suponga ensayos independientes con respuestas al azar equiprobables y una probabilidad de acierto de 0.5. Bajo este modelo, el número de respuestas correctas sigue una distribución binomial con 20 ensayos. La probabilidad unilateral exacta de alcanzar al menos un número dado de aciertos es la suma de las combinaciones enteras correspondientes dividida entre `2^20`.

La [documentación oficial de la distribución binomial de SciPy](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.binom.html) define su función de supervivencia como la probabilidad de un valor estrictamente superior al argumento. Por tanto, «al menos 15» utiliza `binom.sf(14,20,0.5)`, no `binom.sf(15,20,0.5)`. Los cálculos independientes mediante combinaciones enteras coinciden con la función instalada dentro de `1e-14`.

| Al menos este número de respuestas correctas | Probabilidad de cola unilateral |
| --- | --- |
| 12 | 0.2517223358154297 |
| 14 | 0.057659149169921875 |
| 15 | 0.020694732666015625 |
| 16 | 0.005908966064453125 |

Para una regla unilateral declarada de antemano con alfa 0.05, el menor recuento entero que cumple el criterio es 15. Se trata de un modelo estadístico y una regla supuestos, no de un resultado de escucha observado. Una probabilidad de cola no es la probabilidad de que la hipótesis de respuestas al azar sea cierta, y una puntuación que no alcance el umbral no demuestra una incapacidad para discriminar.

### Ejercicio práctico 3: aplicar la regla exacta

¿Cumple 14/20 la regla declarada? ¿Qué argumento de la función de supervivencia representa al menos 15 aciertos y qué significa su probabilidad?

> **Respuesta:** No: la cola para al menos 14 es 0.057659149169921875, por encima de 0.05. Al menos 15 utiliza el argumento 14 y tiene una cola de 0.020694732666015625. Bajo el modelo supuesto de respuestas independientes al azar equiprobables, es la probabilidad de un recuento al menos tan grande. No es una probabilidad posterior de que el modelo sea cierto.

## 4. Tener en cuenta la selección de un bloque aprobado

Suponga que un agente ejecuta ocho pruebas completas independientes bajo ese mismo modelo nulo e informa solo de un bloque que alcanza 15 aciertos. La probabilidad real de falso positivo de una prueba con esta regla discreta es `q=0.020694732666015625`. La probabilidad de que al menos una de las ocho cruce el umbral es `1-(1-q)^8`, aproximadamente 0.154049944.

Usar la cola discreta real importa: el alfa nominal de 0.05 no es aquí su probabilidad exacta de cruzar el umbral. La independencia también es un supuesto. Los bloques repetidos por una misma persona pueden ser dependientes, y detenerse antes de tiempo, cambiar los estímulos o seleccionar análisis exige un tratamiento adicional. El cálculo no describe un experimento realizado.

### Ejercicio práctico 4: revelar la selección

Un agente informa de su mejor bloque aprobado entre ocho pruebas nulas independientes como si fuera la única prueba. Calcule la probabilidad de al menos un cruce del umbral e identifique la información omitida.

> **Respuesta:** `1-(1-q)^8` es aproximadamente 0.154049944 con el q indicado. El informe debe revelar las ocho pruebas, la regla de selección y el supuesto de independencia. Un bloque aprobado seleccionado no conserva la interpretación del falso positivo de una sola prueba sin tener en cuenta la selección.

## 5. Preparar una prueba real sin afirmar que ocurrió

Un futuro protocolo debe declarar la comparación, la regla de orden de presentación, las condiciones de reproducción, el plazo de respuesta, las exclusiones y el análisis antes de recoger resultados. Mantenga la clave de respuestas y los nombres de archivo que revelan las frecuencias fuera de la interfaz del participante. Utilice una secuencia aleatoria equilibrada y oculta en vez de este conjunto predecible, conservando un registro privado reproducible de las asignaciones. Compruebe el nivel y las pistas involuntarias del inicio de los sonidos o de la interfaz, además de la frecuencia.

Registre cada intento y cada exclusión declarada, preserve la privacidad de los participantes e informe de la incertidumbre y de la población realmente muestreada. Probar una sola separación no permite localizar un umbral perceptivo; eso requiere un procedimiento adecuado de varios niveles y evidencias. Una afirmación de preferencia o aprendizaje necesita su propio resultado y diseño de estudio. La revisión humana y el consentimiento de los participantes siguen siendo requisitos para un estudio real, no etapas completadas en este conjunto de evidencias.

### Ejercicio práctico 5: reescribir la afirmación de publicación

La nota de publicación dice: «Una puntuación de 15/20 demuestra que los guitarristas pueden oír una diferencia de 13.686286135 cents y aprender más rápido». ¿Qué formulación está respaldada?

> **Respuesta:** El conjunto prepara dos tonos construidos y verifica la puntuación sintética y una regla estadística declarada. No incluye ninguna respuesta observada de participantes, umbral perceptivo, resultado poblacional ni comparación de aprendizaje. Sigue siendo necesario un protocolo real con presentación controlada, asignaciones ocultas, análisis declarado y resultados adecuados antes de poder probar esas afirmaciones.
