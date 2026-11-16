---
module_id: cog-002-feedback-integrity-fretboard-recall
department: cognitive-science
course: "Fiabilidad de la retroalimentación para recordar notas en el diapasón"
level: early-intermediate
prerequisites: [gtr-001-the-fretboard-map]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: cognitive-science-2026-10-11-002
version: "0.1.0"
---

# Fiabilidad de la retroalimentación para recordar notas en el diapasón

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](../../../../code/streeling/evidence/voicing-learning-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Ciencias Cognitivas** | Nivel: intermedio inicial | Duración estimada: 35 minutos | Estado: borrador español; pendientes las revisiones temática y lingüística, las pruebas con alumnos y la publicación

## Objetivos

Después de esta lección podrá:

- Comprobar una respuesta mostrada en el diapasón a partir de un orden de cuerdas, una afinación y un cálculo de traste declarados.
- Separar una pista visible, la predicción del alumno, una respuesta verificada y un intento posterior en un registro de práctica.
- Explicar exactamente qué muestra el diapasón SVG de GA en la revisión fijada y qué registra su función de retorno al hacer clic.
- Identificar una clave de respuestas errónea sin convertir una observación del código fuente en una afirmación sin respaldo sobre resultados de aprendizaje.

## La pregunta del proyecto

Un guitarrista que mira la demostración del diapasón SVG de GA ve un conjunto de posiciones llamado acorde de C mayor. ¿Podrían las etiquetas de notas mostradas servir como clave de respuestas para un ejercicio de **predecir la nota y después comprobarla**? Es un problema práctico de ciencias cognitivas: la retroalimentación solo puede corregir una predicción si su clave de respuestas es fiable. Si la clave es errónea, una respuesta correcta del alumno puede marcarse como incorrecta y una respuesta incorrecta puede parecer correcta. Es un riesgo que investigar, no evidencia de que un usuario concreto ya haya aprendido una nota equivocada.

Use una revisión fija del código fuente durante toda esta lección: el commit de GA [`dc2e74cbd992a298f67efb928b5b3754615e1924`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924). Los [seis objetos de posición de la página de demostración](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/pages/GuitarFretboardTest.tsx#L5-L13) constituyen el conjunto de datos del ejercicio. El [tipo y la afinación predeterminada del componente SVG](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/GuitarFretboard.tsx#L4-L85) definen cómo leer las posiciones. La página es explícitamente una **página de prueba del componente SVG antiguo**; su nombre no demuestra la existencia de una prueba automatizada ni de un recorrido de aprendizaje desplegado.

[COG-001](cog-001-your-brain-lies-to-you.es.md) presenta los sesgos cognitivos generales. [GTR-001](../../guitar-studies/en/gtr-001-the-fretboard-map.md) enseña el mapa del diapasón. Aquí la tarea es más concreta: hacer comprobable una consigna de práctica específica de GA y especificar qué tendría que contener una respuesta observada de un alumno. Las fuentes fijadas no incluyen ningún experimento sobre memoria o mejora de habilidades. La idea de que una predicción sin ayuda seguida de retroalimentación verificada pueda facilitar esta tarea sigue siendo una hipótesis didáctica hasta que se pruebe con alumnos.

## 1. Fijar la orientación antes de comprobar la clave

El componente declara que `string: 0` es la cuerda **E aguda** y usa índices de cuerda desde cero, `0–5`. Su arreglo de afinación predeterminada es `['E', 'B', 'G', 'D', 'A', 'E']`, explícitamente de agudo a grave. Difiere de la lista habitual «E A D G B E», recitada de grave a agudo; invertir el orden sin cambiar el índice de cuerda produce respuestas seguras, pero equivocadas. La demostración indica seis cuerdas y mantiene la afinación predeterminada.

Para este conjunto fijo de datos en afinación estándar, avance un semitono por traste. De forma equivalente, asigne las clases de altura `C=0, C#=1, ..., B=11`, sume el número de traste a la clase de altura de la cuerda al aire y reduzca módulo 12. Escriba la clase resultante como nombre de nota. Por ejemplo, el E grave es `E=4`; en el traste 3, `(4+3) mod 12 = 7`, que es **G**. Este cálculo comprueba la etiqueta de una posición; no indica si la forma completa del acorde es cómoda, está bien digitada o se oye.

| Índice de cuerda | Cuerda al aire | Traste | Nota calculada | Etiqueta de la demostración | ¿Coincide? |
|---:|---|---:|---|---|---|
| 0 | E agudo | 0 | E | E | sí |
| 1 | B | 1 | C | C | sí |
| 2 | G | 0 | G | G | sí |
| 3 | D | 2 | E | E | sí |
| 4 | A | 3 | C | C | sí |
| 5 | E grave | 3 | **G** | **C** | **no** |

Cinco de las seis etiquetas mostradas coinciden con las notas calculadas. La sexta posición sigue siendo una **nota del acorde** de C mayor porque G pertenece a la tríada C–E–G. El defecto es más preciso: la etiqueta de esa nota individual es incorrecta. La demostración también marca esa posición con `emphasized: true` y con el mismo color rojo que usa en las otras posiciones etiquetadas C. Como el componente documenta `emphasized` como un énfasis opcional, por ejemplo para una fundamental, la pista visual podría reforzar la etiqueta errónea en una tarea de búsqueda de la fundamental. El código fuente no establece cómo interpreta ese color un usuario.

### Ejercicio práctico 1: leer el sistema de coordenadas

La demostración incluye `{ string: 5, fret: 3, label: 'C' }`. ¿Qué cuerda al aire designa el índice 5 y qué nota da el cálculo del traste con la afinación predeterminada del componente? Muestre el cálculo de clase de altura.

> **Respuesta:** El índice 5 es el E grave, porque el arreglo va del E agudo en el índice 0 al E grave en el índice 5. E tiene clase de altura 4; `4 + 3 = 7`, y la clase de altura 7 es G. La nota calculada es G, así que el C mostrado no concuerda con esta afinación y este traste fijos.

### Ejercicio práctico 2: examinar las seis respuestas

Enumere las notas calculadas en el orden del arreglo de la demostración, cuente las etiquetas coincidentes e indique si la etiqueta discordante refuta por sí sola el nombre «posiciones de acorde de C mayor».

> **Respuesta:** La secuencia calculada es `E, C, G, E, C, G`; la secuencia mostrada es `E, C, G, E, C, C`, con cinco etiquetas coincidentes de seis. G es una nota de una tríada de C mayor, por lo que este cálculo no refuta el conjunto de notas del acorde. Identifica una **etiqueta de marcador** incorrecta, en la cuerda 5, traste 3.

## 2. Separar la pregunta de la retroalimentación

El componente tiene tres clases distintas de pistas textuales. `showFretNumbers` controla los números de traste que aparecen en la parte inferior. `showStringLabels` controla las seis etiquetas de afinación de cuerdas al aire. El campo opcional `label` de cada objeto de posición controla el texto dentro de ese marcador individual; la [rama de renderizado comprueba `pos.label`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/GuitarFretboard.tsx#L239-L318). Ocultar las etiquetas de cuerda **no** oculta los nombres de notas dentro de los marcadores de posición que los contienen. A la inversa, mantener visibles las etiquetas de traste y cuerda no exige que haya una etiqueta de nota dentro del marcador.

Para una tarea de predicción propuesta, un diseñador podría mostrar un conjunto fijo de coordenadas de marcadores sin sus campos opcionales `label`, pedir al alumno que diga una nota y después mostrar por separado una respuesta verificada. Esto describe **dos estados preparados**, no una función de revelación implementada. La página de prueba de la revisión fijada muestra las etiquetas de inmediato; no tiene entrada de respuesta, comprobación de corrección, control de revelación diferida ni historial del alumno. Este límite importa porque leer el código actual no permite establecer cómo se comportan las personas en un recorrido que aún no existe.

Una clave fiable debe derivarse de la misma afinación y las mismas coordenadas declaradas para la pregunta y después comprobarse de forma independiente. No copie el sexto `label` de la demostración tanto en la pregunta como en el validador: el error duplicado haría que una lección defectuosa pareciera coherente consigo misma. Un registro mínimo para un estudio real incluiría la revisión fijada del código fuente, cuerda y traste, afinación, estado de las pistas, respuesta del alumno antes de la retroalimentación, clave verificada, momento en que apareció la retroalimentación y cualquier respuesta posterior. Sin esos campos, «el usuario hizo clic en G» no es una traza de recuerdo.

### Ejercicio práctico 3: identificar la pista visible

Suponga que un renderizado establece `showStringLabels: false` y `showFretNumbers: true`, pero pasa los seis objetos de posición originales sin cambios. ¿Qué textos desaparecen y queda oculto el `C` incorrecto del sexto marcador?

> **Respuesta:** Desaparecen las seis etiquetas de afinación de cuerdas al aire; permanecen los números de traste. Cada `label` de posición suministrado sigue mostrándose dentro de su marcador, así que el sexto `C` incorrecto permanece visible. Un estado de predicción antes de la respuesta tendría que omitir o retener de otra forma las etiquetas de posición; la página existente no ofrece un control de revelación probado.

## 3. Qué puede medir una interacción y cuáles son sus límites

El [`handlePositionClick`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/GuitarFretboard.tsx#L154-L157) del componente crea un objeto nuevo con `{ string, fret }` y lo pasa a la función de retorno opcional `onPositionClick`. Los círculos de los marcadores llaman a ese manejador cuando se hace clic en ellos. La función de retorno no incluye el `label` de la posición original, una nota propuesta por escrito, la corrección ni el momento de la retroalimentación. Un clic puede mostrar qué coordenada se seleccionó si un componente padre registra la llamada; por sí solo no puede indicar qué nota creía el alumno que había allí.

A continuación se presenta una traza de dos intentos deliberadamente **sintética** para el mismo ítem. No es una sesión observada de un usuario de GA: antes de la corrección, un alumno dice `C` para la cuerda 5, traste 3; después de mostrarse una respuesta `G` verificada, dice `G` en un reintento inmediato. Puntuado contra la clave corregida, esto da `0/1` y después `1/1` en ese ítem. Muestra una respuesta distinta en el conjunto de datos. No establece recuerdo sin ayuda al día siguiente, transferencia a otro traste ni beneficio de un diseño de pistas frente a otro. Esas preguntas requieren una prueba adecuada con alumnos, un intervalo y una comparación declarados y respuestas reales registradas.

### Ejercicio práctico 4: examinar la evidencia de un clic

Si un componente padre escucha `onPositionClick` y recibe `{ string: 5, fret: 3 }`, ¿puede puntuar si el alumno predijo G? Nombre dos observaciones que faltan.

> **Respuesta:** No. La función de retorno solo envía la coordenada seleccionada. Como mínimo, el padre necesitaría la nota declarada por el alumno **antes** de la retroalimentación y una clave verificada vinculada a la afinación actual; también necesitaría los momentos de presentación de las pistas y de la retroalimentación para evaluar un recorrido de predicción y comprobación. La ausencia de `label` en la función de retorno es especialmente relevante porque la etiqueta de esa coordenada en la demostración fuente es errónea.

### Ejercicio práctico 5: limitar una afirmación de aprendizaje

Con la traza sintética anterior, calcule ambas puntuaciones del ítem contra la clave verificada G. ¿Qué afirmación limitada tiene respaldo y qué afirmación más amplia carece de él?

> **Respuesta:** La primera respuesta C puntúa `0/1`; la segunda respuesta inmediata G puntúa `1/1`. El registro sintético solo respalda que la respuesta del conjunto de datos cambió después de la corrección proporcionada y que su puntuación inmediata mejoró. No puede mostrar que algún usuario real de GA haya mejorado, retenido G después o se haya beneficiado de una revelación diferida; no aparece ninguna medición de usuarios de ese tipo en los artefactos fijados.

## Evidencia del proyecto y próxima comprobación

El hallazgo en el código fuente es concreto: en la revisión fijada de GA, una de las seis etiquetas de notas mostradas no concuerda con el orden de cuerdas y la afinación estándar del componente. Un pequeño cálculo independiente de clases de altura de las seis entradas fijas produjo `E, C, G, E, C, G` y una coincidencia de etiquetas de `5/6`. Ese cálculo no ejecutó un navegador, una prueba automatizada de interfaz ni un estudio con alumnos. El código fuente muestra las propiedades disponibles y las ramas de renderizado; no demuestra que la página esté desplegada ni que se utilice para enseñar.

Antes de utilizar esta demostración como retroalimentación, corrija y pruebe la clave de respuestas en la misma revisión que el componente mostrado. Para cualquier experiencia propuesta de predicción y comprobación, pruebe los dos estados visibles y registre una respuesta real previa a la retroalimentación antes de hacer afirmaciones sobre el recuerdo. Este curso sigue siendo un borrador traducido del inglés. Todavía faltan la revisión temática, un intento realizado por un alumno, la revisión lingüística, la sincronización o compilación de Learn y la verificación de publicación.

## Fuentes con revisión fijada

- [GA `GuitarFretboardTest.tsx` en `dc2e74cbd992a298f67efb928b5b3754615e1924`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/pages/GuitarFretboardTest.tsx): las seis posiciones etiquetadas de la demostración y la configuración de la página.
- [GA `GuitarFretboard.tsx` en el mismo commit](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/GuitarFretboard.tsx): índices de cuerdas, afinación predeterminada, etiquetas opcionales, datos enviados al hacer clic y renderizado SVG.
