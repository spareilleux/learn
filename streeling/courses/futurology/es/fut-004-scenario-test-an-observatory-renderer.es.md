---
module_id: fut-004-scenario-test-an-observatory-renderer
department: futurology
course: "Evaluar un renderizador del Observatorio mediante escenarios"
level: intermediate
prerequisites: ["fut-003-agent-substitution-readiness-drill"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Evaluar un renderizador del Observatorio mediante escenarios

> **Alcance del borrador.** Informes del proyecto fijados en una revisión concreta y tablas de decisión construidas para el curso. Siguen pendientes la revisión técnica humana, la revisión lingüística por una persona que domine el idioma, los intentos de estudiantes, los resultados de renderizado en funcionamiento y la verificación del HTML desplegado. Las pérdidas y probabilidades de los escenarios siguientes son premisas didácticas inventadas, no mediciones ni pronósticos.

## La pregunta del proyecto

¿Qué política visual debería elegir un agente del Observatorio cuando pueden cambiar la capacidad del equipo anfitrión, las cargas que compiten por recursos y la disponibilidad del adaptador? La [página de RAND sobre toma de decisiones robusta](https://www.rand.org/pubs/tools/TL320/tool/robust-decision-making.html) distingue los desacuerdos sobre las relaciones del sistema, las probabilidades y los valores como fuentes de incertidumbre. Describe el planteamiento, la evaluación entre futuros, el análisis de vulnerabilidades y el análisis de compromisos. Practicamos un pequeño cálculo de decisión; no es una implementación completa de ese proceso.

El [informe histórico de coexistencia de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) contiene variaciones incluso sin la carga adicional de renderizado. El [análisis anterior en PM-005](../../product-management/en/pm-005-interpret-brutal-coexistence-experiments.md) conserva el carácter inconcluyente del seguimiento. Esas observaciones motivan examinar alternativas. No proporcionan las pérdidas ni las probabilidades de la tabla de esta lección, ni validan un renderizador adaptativo.

## 1. Plantear la decisión antes de asignar probabilidades

Usa tres estrategias hipotéticas: prioridad a la coexistencia `C`, prioridad al detalle `P` y candidata adaptativa `A`. Usa tres condiciones hipotéticas: equipo limitado, equipo potente y equipo con contención. Cada celda es una puntuación de pérdida construida; se prefiere un valor menor. Supón que los puntos tienen un significado cardinal comparable entre filas y columnas. Este supuesto también necesita justificación antes de tomar una decisión real.

| Estrategia | Equipo limitado | Equipo potente | Equipo con contención |
| --- | --- | --- | --- |
| C | 3 | 6 | 6 |
| P | 8 | 0 | 14 |
| A | 4 | 3 | 5 |

Estas etiquetas no certifican modos instalados ni el comportamiento del controlador de [CYB-005](../../cybernetics/en/cyb-005-stop-render-policy-flapping.md). No hay una distribución de muestreo ni una frecuencia medida de esas condiciones. Enumerar tres escenarios no asigna a cada uno una probabilidad de un tercio.

### Ejercicio práctico 1: identificar la inferencia sin respaldo

Un agente llama a la pérdida de 5 de A en la columna del equipo con contención una penalización de GPU medida y asigna la misma probabilidad a las tres columnas. ¿Qué supuestos añadió?

> **Respuesta:** Convirtió una premisa didáctica en puntos de pérdida en una medición de hardware e introdujo probabilidades ausentes de la tabla. Nada de eso se deduce de enumerar escenarios. Una evaluación real necesita consecuencias medidas o modeladas explícitamente, escalas de valor justificadas y un tratamiento de la incertidumbre declarado por separado.

## 2. Calcular el arrepentimiento respecto al mejor resultado de cada escenario

Para cada columna, encuentra primero la menor pérdida alcanzable por cualquiera de las estrategias enumeradas. Las mejores pérdidas son `[3,0,5]`. Define el arrepentimiento de una estrategia en esa columna como su pérdida menos esa mejor pérdida. El cálculo pregunta cuánto queda por detrás de la alternativa enumerada que se podría seleccionar conociendo esa condición.

| Estrategia | Arrepentimiento, equipo limitado | Arrepentimiento, equipo potente | Arrepentimiento, equipo con contención | Arrepentimiento máximo |
| --- | --- | --- | --- | --- |
| C | 0 | 6 | 1 | 6 |
| P | 5 | 0 | 9 | 9 |
| A | 1 | 3 | 0 | 3 |

Minimizar el arrepentimiento máximo selecciona A en esta tabla. Su arrepentimiento máximo de 3 es una diferencia en puntos de pérdida, no una probabilidad, un tiempo de fotograma, una garantía universal ni una prueba de que la adaptación sea lo mejor. El criterio compara las alternativas declaradas sobre el conjunto de escenarios declarado.

### Ejercicio práctico 2: reconstruir el criterio

Calcula el arrepentimiento de P en el caso del equipo con contención y los tres arrepentimientos máximos. ¿Qué estrategia minimiza el arrepentimiento máximo y cuál es la unidad del resultado?

> **Respuesta:** El arrepentimiento de P con contención es `14-5=9`. Los arrepentimientos máximos son C 6, P 9 y A 3, por lo que se selecciona A. Los números son diferencias en los puntos de pérdida que la tabla supone comparables. No son milisegundos de renderizado medidos ni probabilidades de fallo.

## 3. Comparar con una decisión explícitamente probabilística

Ahora supón las probabilidades `[0.1,0.8,0.1]` para las mismas tres columnas. La pérdida esperada es la suma ponderada de cada fila. C da 5.7, P da 2.2 y A da 3.3; minimizar la pérdida esperada selecciona P. Criterios y premisas distintos pueden producir decisiones diferentes sin contradicción aritmética.

Estas probabilidades se estipulan, no se infieren del informe histórico. El razonamiento por pérdida esperada resulta útil cuando una distribución está justificada para la pregunta y las consecuencias se representan adecuadamente. Un cálculo minimax del arrepentimiento no elimina la necesidad de defender su propia escala de pérdidas, su conjunto de escenarios o su tratamiento de los peores casos.

### Ejercicio práctico 3: explicar el cambio de decisión

Calcula la pérdida esperada de P con las probabilidades indicadas. ¿Por qué puede superar a A según la pérdida esperada y quedar por detrás según el arrepentimiento máximo?

> **Respuesta:** `0.1*8+0.8*0+0.1*14=2.2`, por debajo de los 3.3 de A. La distribución supuesta da la mayor parte del peso a la columna del equipo potente, favorable a P. El arrepentimiento máximo, en cambio, considera la mayor desventaja respecto al mejor resultado de cada columna, donde P tiene 9 y A 3. Las decisiones dependen de premisas y criterios declarados distintos.

## 4. Encontrar la creencia que cambia la comparación

Sea p la probabilidad del equipo potente y asigna a cada una de las otras condiciones la probabilidad `(1-p)/2`. Las pérdidas esperadas pasan a ser `4.5+1.5*p` para C, `11-11*p` para P y `4.5-1.5*p` para A. Igualar P y A da `p=13/19`, aproximadamente 0.684210526. Por encima de ese valor, P tiene menor pérdida esperada; por debajo, A tiene menor pérdida esperada en esta comparación por pares.

Este punto de cruce permite examinar un desacuerdo: ¿cuánto peso tendría que dar la decisión al escenario favorable? No estima ese peso. Cuando p es igual a cero, C y A empatan en pérdida esperada; el álgebra debe conservar los empates en lugar de inventar un ganador único.

### Ejercicio práctico 4: obtener el punto de cruce

Resuelve `11-11*p=4.5-1.5*p`. ¿Es el resultado una prueba de que el escenario del equipo potente ocurrirá con esa probabilidad?

> **Respuesta:** Al reorganizar se obtiene `6.5=9.5*p`, de modo que p es `13/19`, aproximadamente 0.684210526. Es una frontera de decisión condicional a las pérdidas construidas y al reparto de probabilidades. No es un pronóstico, una frecuencia observada ni una probabilidad posterior de una condición futura del equipo.

## 5. Buscar una condición de fallo omitida

Añade una columna con el adaptador no disponible y las pérdidas C 4, P 10 y A 20. Su mejor pérdida es 4, así que sus arrepentimientos son C 0, P 6 y A 16. Entre las cuatro columnas, los arrepentimientos máximos pasan a ser C 6, P 9 y A 16. La elección minimax del arrepentimiento cambia a C.

La objeción más fuerte a la elección original es, por tanto, concreta: la pequeña tabla omitía una condición en la que la candidata adaptativa no puede cumplir su función. La nueva columna también es inventada; identifica una vulnerabilidad del modelo en lugar de demostrar un fallo real del adaptador. Una alternativa más sencilla a cambiar la política es mantener un ajuste fijo mientras se recogen pruebas pertinentes y acotadas.

### Ejercicio práctico 5: redactar la siguiente investigación

Tras añadir el cuarto escenario, ¿qué estrategia minimiza el arrepentimiento máximo? Indica un motivo para revisar la decisión y un resultado que rechazaría la candidata adaptativa sin afirmar que se han cubierto todos los futuros.

> **Respuesta:** Se selecciona C con un arrepentimiento máximo de 6, frente a P 9 y A 16. Revisa la decisión cuando cambien la disponibilidad real del adaptador, las mediciones de cargas representativas o los objetivos de las partes interesadas. Rechaza la candidata para el uso previsto si no puede operar en una condición exigida o incumple un límite declarado de calidad o de la tarea vecina. Prueba directamente esos requisitos; esta tabla finita no puede certificar robustez ante todos los futuros.

El [registro de escenarios fijo](../../../../code/streeling/evidence/observatory-decisions-2026-10-22/scenario-decisions.json) conserva ambas tablas y su aritmética exacta. [PHI-004](../../philosophy/en/phi-004-separate-performance-tradeoffs-from-values.md) examina de dónde vienen esas preferencias sobre pérdidas y esas restricciones. El ejercicio prepara una discusión de decisión; no autoriza sustituir un renderizador ni predice una fecha de llegada de la AGI.
