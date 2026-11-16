---
module_id: cog-008-choose-probes-that-distinguish-reasoning-models
department: cognitive-science
course: "Elegir preguntas que distingan modelos de razonamiento"
level: intermediate
prerequisites: ["cog-007-separate-unaided-recall-from-assisted-success", "phy-012-rotate-directional-stiffness-with-the-material"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Elegir preguntas que distingan modelos de razonamiento

> **Alcance del borrador.** Leyes candidatas, firmas de predicción y un patrón ficticio de respuestas elaborados para el curso. No se observó ningún participante, instrumento diagnóstico validado, intervención educativa ni experimento con materiales. Siguen pendientes las revisiones humanas técnicas, artesanales, lingüísticas por personas que dominen el idioma y pedagógicas con estudiantes; la verificación del HTML del curso desplegado es independiente.

## La pregunta del proyecto

Si un estudiante predice correctamente una fuerza, ¿podemos saber cómo razonó sobre el sistema de referencia del material? [PHY-012](../../physics/en/phy-012-rotate-directional-stiffness-with-the-material.md) ofrece un modelo manejable para diseñar preguntas con predicciones distinguibles. [COG-007](cog-007-separate-unaided-recall-from-assisted-success.md) conserva por separado la ayuda recibida y el historial de intentos. Aquí la tarea consiste en elegir preguntas informativas antes de asignar una puntuación total o proponer tutoría adaptativa.

El [resumen de Scott y Schumayer publicado por la editorial](https://journals.aps.org/prper/abstract/10.1103/PhysRevPhysEducRes.14.010106) trata la información contenida en respuestas incorrectas a una evaluación de conceptos de fuerza. El [resumen de autor de Persson](https://arxiv.org/abs/1504.06099v1) destaca la necesidad de comprobar la fiabilidad y el poder discriminativo de una evaluación en un contexto nuevo. Solo se leyeron estos resúmenes. Motivan la cautela y registros de respuestas más ricos; no validan nuestra nueva tarea matricial, no establecen las frecuencias de sus distractores ni aportan un efecto de aprendizaje.

## 1. Definir un catálogo finito de candidatos

Utilice la rigidez local de resorte `diag(4,1)` N/mm elaborada para el curso. Considere cuatro leyes ideales de predicción, no cuatro poblaciones de estudiantes medidas:

| Ley | Cálculo indicado |
| --- | --- |
| T | Rotar la rigidez completa con el material. |
| F | Mantener la rigidez original fija en los ejes globales. |
| D | Rotar la rigidez y después eliminar sus elementos fuera de la diagonal. |
| I | Utilizar la rigidez isótropa `2.5*I` en todos los ángulos. |

Una pregunta de sondeo especifica el ángulo del material y el desplazamiento en el sistema global. Observe el vector de fuerza predicho en N y la energía en N*mm. La pregunta P0 utiliza un ángulo de 0 grados y un desplazamiento de `[1,0]` mm. Las leyes T, F y D predicen todas `[4,0]` N; I predice `[2.5,0]` N. Una respuesta correcta aquí no puede separar las tres primeras leyes.

### Ejercicio 1: localizar un acierto no informativo

Deduza las predicciones de P0. Una respuesta ficticia coincide con `[4,0]` N. ¿Qué entradas del catálogo siguen siendo compatibles y demuestra esa respuesta una comprensión correcta de la rotación?

> **Respuesta:** Con el ángulo 0, las matrices completa, fija y limitada a la diagonal coinciden, por lo que T, F y D predicen `[4,0]` N; I predice `[2.5,0]` N. La respuesta ficticia es compatible con T, F y D. No permite distinguir sus reglas de rotación y no es una observación de un estudiante real.

## 2. Combinar preguntas complementarias

La pregunta P1 utiliza una rotación del material de 90 grados y un desplazamiento de `[1,0]` mm. La pregunta P2 utiliza una rotación de 45 grados y el mismo desplazamiento en el sistema global. Sus predicciones exactas de fuerza son:

| Ley | Fuerza P1, N | Fuerza P2, N |
| --- | --- | --- |
| T | `[1,0]` | `[2.5,1.5]` |
| F | `[4,0]` | `[4,0]` |
| D | `[1,0]` | `[2.5,0]` |
| I | `[2.5,0]` | `[2.5,0]` |

P1 por sí sola agrupa T con D; P2 por sí sola agrupa D con I. Juntas, sus firmas son únicas entre estas cuatro leyes estipuladas. Se trata de identificabilidad en un catálogo finito bajo predicciones exactas, no de identificación psicológica de cómo piensa una persona real.

### Ejercicio 2: interpretar una firma ficticia

Un patrón de respuestas elaborado para el curso da la fuerza P1 `[1,0]` y la fuerza P2 `[2.5,0]` N. ¿Qué ley del catálogo coincide con ambas? ¿Por qué no basta utilizar solo P2?

> **Respuesta:** Solo D coincide con ambas dentro de este catálogo. P2 por sí sola es compatible con D e I. La firma de dos vectores separa las leyes deterministas enumeradas, pero un error aritmético, una conjetura al azar u otra regla no incluida podría producir las mismas respuestas. No se diagnosticó a ningún estudiante real.

## 3. Conservar la observación que aporta la distinción

En P2, las energías de T, D e I son todas 1.25 N*mm; F da 2 N*mm. La energía por sí sola pierde la distinción de fuerza transversal entre T y D para este desplazamiento concreto. Guardar únicamente «correcto» o «incorrecto» puede descartar aún más información sobre el cálculo.

Esto no significa que las observaciones escalares nunca puedan distinguir las entradas del catálogo. Otra pregunta P3, a 45 grados con un desplazamiento de `[1,-1]` mm, da una energía de 1 para T y de 2.5 para F, D e I. Combinada con las energías de P1, P3 puede distinguir las cuatro entradas del catálogo. La utilidad de una proyección depende de los sondeos elegidos y de la pregunta planteada.

### Ejercicio 3: comparar la evidencia vectorial y energética

Deduza la energía de P2 para T y D, explicando por qué la fuerza transversal no contribuye en este caso. Después muestre cómo las energías de P1 y P3 distinguen T de D.

> **Respuesta:** Para el desplazamiento `[1,0]`, la energía es la mitad de su producto escalar con la fuerza, por lo que tanto `[2.5,1.5]` como `[2.5,0]` dan 1.25 N*mm. El segundo desplazamiento nulo elimina la contribución transversal. P1 da una energía de 0.5 tanto para T como para D, pero P3 da 1 para T y 2.5 para D. El par escalar elegido las separa; la energía de P2 por sí sola no lo hace.

## 4. Poner a prueba el propio catálogo

Definamos otra ley M para el curso: utilizar T salvo en el ángulo de 60 grados, donde utiliza en cambio una rigidez isótropa. M coincide con T en P0, P1, P2 y P3. Por tanto, estos sondeos finitos no demuestran que una regla de respuesta sea igual a T en todos los ángulos.

El [registro fijado de firmas](../../../../code/streeling/evidence/constraint-feedback-2026-10-22/probe-signatures.json) conserva las particiones del catálogo y este contraejemplo reservado para la comprobación. No contiene etiquetas de participantes, prevalencia, coeficiente de fiabilidad ni estimación de precisión diagnóstica. Las leyes ideales también suponen una aritmética exacta y coherente; el razonamiento real puede depender del contexto o estar incompleto.

### Ejercicio 4: indicar el límite de la identificación

¿Una firma similar a T en los cuatro sondeos descarta M? ¿Qué se necesitaría antes de llamar al ejercicio un detector validado de concepciones erróneas?

> **Respuesta:** No. M se construyó para coincidir en esos sondeos y diferir en un ángulo reservado para la comprobación. El resultado de unicidad está condicionado al catálogo finito. La validación requeriría respuestas reales de la población objetivo, razonamiento y ayuda documentados, una revisión adecuada de los ítems y evidencia sobre fiabilidad, poder discriminativo e interpretación. Una tabla matemática de predicciones no aporta por sí sola ninguna de esas propiedades empíricas.

## 5. Preparar una evaluación antes de automatizar la adaptación

### Ejercicio 5: redactar un protocolo para estudiantes con ayuda de las fuentes

Lea los dos resúmenes, PHY-012 y el registro fijado de firmas. Proponga un intento real acotado que conserve los errores útiles y evite atribuir una etiqueta de modelo mental o afirmar una ganancia de aprendizaje sin fundamento.

> **Respuesta:** Conserve, antes de ofrecer retroalimentación, el ángulo, el sistema de referencia, el desplazamiento, las unidades, el vector y la energía predichos, la explicación, la confianza y la ayuda de cada consigna. Compruebe la clave de respuestas de forma independiente, varíe los ángulos y casos reservados para la comprobación, y pregunte por qué se eligió una respuesta en vez de asignar una etiqueta estable de modelo mental a partir de una sola coincidencia. Registre las respuestas ausentes o incoherentes. Examine la interpretación real con estudiantes y un especialista en la materia antes de probar cualquier retroalimentación adaptativa frente a una comparación declarada y un criterio de evaluación diferido. Compare primero una retroalimentación escrita sencilla antes de añadir un tutor agéntico. Aquí no se estableció validez con participantes, beneficio causal ni despliegue.
