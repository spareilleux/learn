---
title: Separar los compromisos de rendimiento de los valores
description: Separar los compromisos de rendimiento de los valores — Filosofía
sidebar:
  label: PHI-004 · Separar los compromisos de rendimiento de los valores
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/es/phi-004-separate-performance-tradeoffs-from-values.es.md
---

:::note[Streeling University]
**PHI-004** · Separar los compromisos de rendimiento de los valores · intermedio · 35 minutos

Generado por el departamento *Filosofía* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/es/phi-004-separate-performance-tradeoffs-from-values.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHI-001](../../philosophy/phi-001-how-to-argue-well/)
:::

> **Alcance del borrador.** Tablas de atributos y cálculos de decisión construidos para el curso, motivados por informes del proyecto fijados en una revisión concreta. Siguen pendientes la revisión técnica humana, la revisión lingüística por una persona que domine el idioma, los intentos de estudiantes, la recogida de preferencias de usuarios y la verificación del HTML desplegado. Ninguna puntuación de detalle ni latencia de esta tabla es un resultado medido del producto.

## La pregunta del proyecto

Un agente del Observatorio dice que su política de renderizado más rápida o más detallada es «la mejor». ¿Para quién, con qué prioridades y bajo qué restricciones? La [entrada sobre teoría de la decisión de la Stanford Encyclopedia of Philosophy](https://plato.stanford.edu/entries/decision-theory/) distingue las creencias y los valores implicados en la elección y examina criterios normativos de decisión. Una clasificación numérica necesita premisas sobre lo que importa además de sobre las consecuencias. Esta lección hace visible una de esas premisas; no adopta la utilidad esperada como una teoría ética completa.

La [evaluación histórica de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) motiva la pregunta porque un renderizador adicional y una tarea interactiva vecina comparten recursos. La identidad del código fuente y del informe histórico no determina qué peso deben tener los intereses de sus usuarios. Nuestros ejemplos siguientes se han construido de forma independiente; no son valoraciones extraídas de calidad de imagen ni penalizaciones medidas.

## 1. Declarar los atributos antes de reducirlos a una puntuación

Considera cuatro ajustes hipotéticos. D es una puntuación de detalle construida, expresada en puntos, donde se prefiere un valor mayor. O es una sobrecarga construida añadida a una tarea vecina, en milisegundos, donde se prefiere un valor menor. Supón que estos atributos resumen lo que contempla este cálculo; no tienen por qué recoger todo lo que valora un usuario real.

| Ajuste | D: puntos de detalle | O: sobrecarga de la tarea vecina en ms |
| --- | --- | --- |
| L | 70 | 2 |
| B | 85 | 5 |
| H | 95 | 12 |
| W | 70 | 8 |

Hay dos preguntas distintas. El trabajo empírico preguntaría qué consecuencias produce realmente un ajuste bajo condiciones declaradas. El razonamiento sobre valores preguntaría qué consecuencias son aceptables o preferidas y qué intereses representa la decisión. Una medición futura puede mejorar la primera respuesta sin resolver la segunda.

### Ejercicio práctico 1: exponer la premisa ausente

Un agente selecciona H únicamente porque 95 es la mayor puntuación de detalle. ¿Qué preferencia ha supuesto y qué tipo de evidencia sigue ausente en esta tabla?

> **Respuesta:** Ha tratado el detalle como suficiente para determinar la elección, pasando por alto el coste para la tarea vecina y otras restricciones posibles. Además, la tabla contiene atributos construidos, no consecuencias realmente medidas ni preferencias recogidas. Ni siquiera unas mediciones precisas establecerían por sí solas qué prioridades deberían regir la decisión.

## 2. Usar la dominancia para reducir un orden parcial

Dentro de estos dos atributos, una opción domina a otra cuando ofrece al menos tanto detalle y no más sobrecarga, con una mejora estricta en al menos un atributo. L domina a W: ambas tienen 70 puntos de detalle, pero la sobrecarga es de 2 en vez de 8 ms. B también domina a W, pues ofrece 85 puntos con 5 ms. L, B y H siguen siendo no dominadas porque obtener más detalle cuesta una sobrecarga adicional.

![Opciones hipotéticas de detalle y sobrecarga de la tarea vecina](https://raw.githubusercontent.com/spareilleux/learn/218a2bffc18fe2251956197e882cb6c7ea5d7962/code/streeling/evidence/observatory-decisions-2026-10-22/two-attribute-options.png)

El gráfico muestra las opciones construidas, con preferencia por un D mayor y un O menor. Su frontera discontinua en O igual a 6 ms servirá más adelante como restricción hipotética. La dominancia no proporciona una clasificación total de las opciones restantes, y un atributo omitido podría cambiar la comparación con W.

### Ejercicio práctico 2: distinguir la eliminación de la selección

¿Qué opciones dominan a W y qué opciones son no dominadas? ¿Selecciona ese resultado un único ajuste para un usuario real?

> **Respuesta:** L y B dominan a W bajo los dos atributos indicados. L, B y H son no dominadas. Esto reduce las opciones, pero no elige una sola entre ellas ni establece preferencias reales de usuarios. La conclusión se limita a los atributos declarados y sus valores construidos.

## 3. Explicitar la unidad del peso de un compromiso

Supón una puntuación lineal `U=D-lambda*O`. Aquí lambda tiene unidades de **puntos de detalle por milisegundo**. Esto supone una tasa de intercambio constante y trata D como una escala cardinal en la que la aritmética tiene sentido. Una valoración ordinal numerada, por sí sola, no justificaría ese supuesto.

| Peso en puntos por ms | Puntuación L | Puntuación B | Puntuación H | Puntuación W | Mayor puntuación |
| --- | --- | --- | --- | --- | --- |
| 0.5 | 69 | 82.5 | 89 | 66 | H |
| 2 | 66 | 75 | 71 | 54 | B |
| 6 | 58 | 55 | 23 | 22 | L |

Nada en la tabla de atributos selecciona uno de estos pesos. Bajo la regla supuesta, H y B empatan con lambda `10/7`; B y L empatan con lambda 5. Estas fronteras describen el modelo indicado, no prioridades objetivamente correctas.

### Ejercicio práctico 3: revelar un error de unidades

Con lambda igual a 2 puntos por milisegundo, gana B. Los valores de sobrecarga se convierten a segundos. ¿Qué peso conserva la clasificación? ¿Qué ocurre si el agente mantiene el valor numérico 2 sin cambiar su unidad?

> **Respuesta:** Usa 2000 puntos por segundo para conservar el mismo compromiso y la puntuación de 75 de B. Mantener 2 puntos por segundo hace que la penalización sea mil veces menor y selecciona H en su lugar. Es un cambio del modelo de valores causado por un error de unidades, no una nueva prueba de que los usuarios prefieran H.

## 4. Mantener una restricción estricta fuera de la puntuación compensatoria

Ahora impón un límite construido: la sobrecarga debe ser como máximo de 6 ms. L y B son factibles; H y W se excluyen antes de puntuar. Con un peso de 0.5, la mayor puntuación sin restricciones es la de H, pero la mayor puntuación factible es la de B. Bajo esta regla de decisión, un gran aumento del detalle no puede compensar el incumplimiento de una restricción estricta.

El límite es una nueva premisa de valor. No es un umbral del controlador del código fuente ni una obligación existente del producto. [CYB-005](../../cybernetics/cyb-005-stop-render-policy-flapping/) utiliza otra magnitud, el tiempo de GPU por fotograma; confundir ese sensor con la sobrecarga añadida a la tarea vecina mezclaría tanto el significado de las medidas como el propósito de la decisión.

### Ejercicio práctico 4: aplicar la factibilidad antes de clasificar

Con el límite estricto hipotético de 6 ms y el peso de 0.5, ¿qué ajuste se selecciona? ¿Puede un agente recuperar H promediando silenciosamente su incumplimiento con otros casos satisfactorios?

> **Respuesta:** Se selecciona B entre las opciones factibles L y B. H incumple el límite estricto y no puede volver a entrar gracias a su puntuación más alta ni al promedio de otros casos bajo la regla indicada. Revisar la restricción exigiría un cambio explícito y justificado de las premisas de decisión, no un ajuste aritmético oculto.

## 5. Distinguir un modelo transparente de una decisión legítima

Un peso explícito permite examinar un compromiso. No demuestra que los usuarios afectados lo hayan aceptado, que una puntuación contemple la accesibilidad o la privacidad, ni que el agente tenga autoridad para imponer el resultado. Optimizar una preferencia individual no es automáticamente una asignación aceptable de una máquina compartida. A la inversa, la objeción de otra parte interesada no es simplemente ruido de medición que deba eliminarse mediante suavizado.

La objeción más fuerte a este modelo sencillo es su supuesto de que todos los intereses pertinentes pueden representarse mediante dos atributos cardinales y una tasa de intercambio constante. Una alternativa práctica más sencilla es pedir un intervalo de funcionamiento aceptable, comparar un conjunto pequeño de opciones factibles y mantener una elección reversible mientras se recogen pruebas pertinentes. Rechaza el modelo lineal si preocupaciones omitidas o elecciones observadas contradicen sistemáticamente la clasificación que pretende representar.

### Ejercicio práctico 5: redactar una recomendación justificada

Un agente informa: «el benchmark demuestra que B es éticamente correcto». Sustituye esa afirmación por una recomendación que indique sus límites empíricos, sus premisas de valor y sus límites de autoridad.

> **Respuesta:** Bajo los atributos construidos, la puntuación lineal supuesta con peso 2 selecciona B; bajo la restricción construida de 6 ms, B también es la mejor opción factible con peso 0.5. Estos cálculos no establecen resultados reales de un benchmark ni un mandato ético. Una recomendación real necesita consecuencias medidas, prioridades y restricciones declaradas de las partes interesadas, consideración de los intereses omitidos y autoridad adecuada para realizar el cambio.

El [registro de compromisos fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/observatory-decisions-2026-10-22/value-tradeoffs.json) conserva las puntuaciones, los empates, la dominancia y el control del error de unidades. [FUT-004](../../futurology/fut-004-scenario-test-an-observatory-renderer/) varía por separado las creencias sobre condiciones futuras. Ninguna de las lecciones cambia un renderizador, ratifica una política ni registra las preferencias de un participante.
