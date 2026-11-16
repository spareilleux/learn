---
module_id: dv-010-show-pitch-errors-and-missing-estimates
department: data-visualization
course: "Mostrar los errores de altura y las estimaciones ausentes"
level: intermediate
prerequisites: ["dv-003-instrument-cohorts-and-units", "dv-009-compare-spectrogram-color-scales"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Mostrar los errores de altura y las estimaciones ausentes

> **Alcance del borrador.** Tabla diagnóstica original de seis filas y gráfico científico, además de un análisis acotado de guitarra conservada usado por separado. Siguen pendientes las revisiones humanas técnica y lingüística, las pruebas con estudiantes y la verificación del HTML publicado. Las filas representadas se han creado para el ejercicio; no son datos de participantes ni una curva real de altura de guitarra.

## La pregunta del proyecto

Un panel de altura dibuja una línea limpia porque sustituye los valores ausentes por cero, elimina un valor atípico de octava y comunica la exactitud solo donde respondió el detector. Esa visualización puede ocultar precisamente los fallos que un ciclo de mejora de audio necesita examinar. Esta lección mantiene separadas la disponibilidad, el error y el denominador.

La [tabla completa creada para el ejercicio](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/pitch-trace.json) usa una referencia de 100 Hz. Se mantiene deliberadamente separada del análisis real conservado de E2 en [GAS-005](../../guitar-acoustics/en/gas-005-separate-a-partial-peak-from-a-period.md). No mezcle sus referencias ni describa esta tabla como una nueva medición del motor.

## 1. Hacer explícitas las filas no disponibles

| Tiempo creado para el ejercicio, segundos | Frecuencia comunicada, Hz | Estado |
| --- | --- | --- |
| 0 | 100 | comunicada |
| 0.1 | 200 | comunicada |
| 0.2 | ausente | falta |
| 0.3 | 100.5 | comunicada |
| 0.4 | 0 | entrada inválida |
| 0.5 | 99.5 | comunicada |

Hay cuatro resultados positivos y finitos, una fila ausente y una entrada cero inválida. Ausente e inválido son estados diagnósticos distintos. Ninguno se convierte en una estimación válida de frecuencia cero, en un error de cero cents ni en una observación interpolada. Solo se permite filtrar para una métrica si los estados excluidos y el denominador siguen visibles.

### Ejercicio 1: conservar los dos estados no disponibles

¿Cuántas filas permiten calcular un error de frecuencia logarítmico? ¿Por qué no deben mostrarse tanto la fila ausente como la entrada cero como errores de cero cents?

> **Respuesta:** Cuatro filas permiten el cálculo. La fila ausente no tiene frecuencia, mientras que la entrada cero es inválida para el logaritmo de una frecuencia positiva. Representar cualquiera de ellas en cero cents afirmaría falsamente que existe una estimación válida que coincide exactamente con la referencia. Mantenga visibles sus estados sin inventar valores numéricos de altura.

## 2. Convertir una razón de frecuencias en una unidad de error declarada

Para una frecuencia comunicada válida f y una referencia positiva, defina el error con signo como `1200*log2(f/reference)`. Esto da 0 cents a 100 Hz y +1200 a 200 Hz. Las filas de 100.5 y 99.5 Hz dan aproximadamente +8.634601685 y -8.677883077 cents. Desviaciones aditivas iguales en Hz alrededor de la referencia no son exactamente simétricas en una escala logarítmica.

El gráfico original conserva los cuatro errores válidos, incluido el valor atípico de octava, y coloca la disponibilidad en un panel categórico separado. No hay segmentos que unan las alturas, barras de error inventadas ni estimaciones interpoladas. El [registro de puntos del gráfico](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/plot-points.json) vincula las filas subyacentes con la imagen.

![Errores en cents creados para el ejercicio, con el valor atípico de octava conservado y los estados ausente e inválido mostrados por separado](https://raw.githubusercontent.com/spareilleux/learn/c953607dc38126877032dd5919e57d894971b257/code/streeling/evidence/pitch-estimates-2026-10-22/pitch-errors-and-availability.png)

La única figura con etiquetas en inglés es una ilustración matemática original; el texto localizado que la rodea explica sus magnitudes. Las posiciones verticales de sus categorías no son mediciones del error de altura. El rango vertical completo incluye el punto de +1200 cents, aunque esto comprima el grupo de errores pequeños.

### Ejercicio 2: interpretar el punto de octava

Calcule el error de 200 Hz respecto a 100 Hz. ¿Debe un agente dividirlo silenciosamente por 2 o eliminarlo para que la curva parezca estable?

> **Respuesta:** `1200*log2(200/100)=1200` cents. Dividir por 2 o eliminar la fila cambiaría los datos o la convención de evaluación. Una métrica invariante a la octava, declarada por separado, puede responder a otra pregunta, pero no debe sustituir silenciosamente el resultado mostrado que sí es sensible a la octava. Conserve el punto y explique cualquier vista adicional.

## 3. Comparar resúmenes sin cambiar de escala a escondidas

La media aritmética de las cuatro frecuencias válidas es 125 Hz, cuyo error en cents es aproximadamente 386.313713865. La media de sus errores con signo en cents es, en cambio, aproximadamente 299.989179652 cents; su frecuencia media geométrica correspondiente es aproximadamente 118.919968239 Hz. Son operaciones distintas. La mediana del error con signo es aproximadamente 4.317300843 cents, mientras que el error absoluto máximo sigue siendo de 1200 cents.

Una mediana pequeña puede coexistir con un gran valor atípico de octava. La media del error con signo también puede ocultar cancelaciones en otro conjunto de datos. Elija un resumen para una pregunta declarada y conserve la distribución o los fallos pertinentes. Ninguno de estos resúmenes de cuatro filas aporta un intervalo de confianza ni un veredicto general sobre la calidad del detector.

### Ejercicio 3: identificar el cambio de agregación

¿Por qué convertir la frecuencia media y promediar los cents con signo da respuestas diferentes? ¿Qué par de estadísticas comunicadas demuestra que una mediana pequeña no elimina un fallo grande?

> **Respuesta:** El logaritmo no es lineal, por lo que calcular la media aritmética antes del logaritmo difiere de promediar las razones logarítmicas. Aquí la media aritmética convertida es aproximadamente 386.313713865 cents, mientras que la media del error con signo es aproximadamente 299.989179652 cents. Una mediana de aproximadamente 4.317300843 y un error absoluto máximo de 1200 coexisten; la mediana no borra el fallo de octava.

## 4. Publicar la disponibilidad junto con el denominador de la exactitud

Según la regla creada para el ejercicio de estar dentro de 10 cents, tres de los cuatro resultados válidos cumplen el criterio. La exactitud condicional es, por tanto, `3/4`, o 75%. La cobertura es `4/6`, aproximadamente 66.666666667%. Un criterio conjunto que exige un resultado disponible y válido dentro de la tolerancia se cumple en `3/6`, o el 50% de todas las filas. Estos tres porcentajes responden a preguntas distintas.

La regla conjunta cuenta las filas ausentes e inválidas como incumplimientos de esa condición combinada de éxito. No las transforma en errores numéricos de altura. Declare la regla antes de comparar métodos; de lo contrario, abstenerse más a menudo puede mejorar la apariencia de una visualización solo condicional sin mejorar la tarea de su destinatario.

### Ejercicio 4: revelar el denominador omitido

Un panel dice «75% de exactitud» y oculta las filas no disponibles. Indique la cobertura, el resultado condicional y el conjunto, y explique qué contiene cada denominador.

> **Respuesta:** La cobertura es `4/6`, aproximadamente 66.666666667%, sobre todas las filas. La exactitud condicional es `3/4`, o 75%, solo sobre los resultados válidos. El éxito conjunto es `3/6`, o 50%, sobre todas las filas según la regla declarada de disponibilidad y tolerancia. Son estadísticas del conjunto creado para el ejercicio, no rendimiento medido en despliegue ni con oyentes.

## 5. No poner una puntuación de señal en la leyenda de confianza

En las [ventanas de guitarra conservadas](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/native-pitch-windows.json), usadas por separado, cuatro puntuaciones de recurrencia superan 0.999 mientras que ninguna estimación cumple el control elegido de 5 cents respecto a la referencia nominal. Una leyenda que dijera «99.9% de probabilidad de altura correcta» inventaría una calibración. Del mismo modo, la variación entre ventanas adyacentes no es automáticamente un intervalo de confianza.

La objeción más fuerte a una visualización diagnóstica detallada es su coste de lectura. Un resumen más sencillo puede mostrar la cobertura, un criterio de error declarado y un enlace a las filas y la figura completas. No lo considere suficiente si oculta fallos necesarios para la decisión real. [COG-005](../../cognitive-science/en/cog-005-separate-pitch-estimates-from-listener-reports.md) explica por qué incluso un estimador de señal calibrado no establecería por sí solo una preferencia de los oyentes ni un aprendizaje.

### Ejercicio 5: corregir la afirmación del panel

Un agente etiqueta la puntuación de recurrencia conservada como probabilidad, une los puntos a través de tramas ausentes y llama al resultado una mejora validada por oyentes. Sustituya la afirmación y especifique la corrección de la visualización.

> **Respuesta:** Etiquete la recurrencia como la puntuación declarada de similitud de la señal, conserve sus controles fallidos respecto a la referencia nominal y mantenga las ventanas reales conservadas separadas de las filas creadas para el gráfico. Muestre las estimaciones válidas y los distintos estados no disponibles sin inventar observaciones entre los puntos; exponga los denominadores y cualquier filtrado. La validación por oyentes y un ensayo real de mejora requieren pruebas adicionales, por lo que esta visualización no establece ninguna de las dos.
