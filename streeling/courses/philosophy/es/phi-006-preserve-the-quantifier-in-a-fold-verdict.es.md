---
module_id: phi-006-preserve-the-quantifier-in-a-fold-verdict
department: philosophy
course: "Conservar el cuantificador en un veredicto de plegado"
level: intermediate
prerequisites: ["phi-002-when-is-an-advisory-decision-justified", "phy-010-check-local-flat-fold-angles", "cs-009-composing-origami-panel-constraints"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar el cuantificador en un veredicto de plegado

> **Alcance del borrador.** Interpretación de teoremas a partir de fuentes primarias, inspección de código fijado a una revisión y contraejemplos creados para el curso. Quedan pendientes las revisiones humanas técnica, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se ejecutaron un análisis completo de IX, un plegado físico, una exportación de malla ni una prueba de escena de [Godot](https://docs.godotengine.org/en/4.6/).

## La pregunta del proyecto

Un agente dice «el vértice se pliega en plano». ¿Afirma que existe alguna asignación, que funciona la asignación proporcionada o que se ha validado un objeto entero? Estas afirmaciones tienen sujetos y cuantificadores distintos. Un mensaje de agentes de alto nivel debería conservar esa distinción al comprimir detalles de una API en una conclusión.

[PHY-010](../../physics/en/phy-010-check-local-flat-fold-angles.md) proporciona un entorno didáctico: sectores de 60, 90, 120 y 90 grados en orden de pliegues de e0 a e3. [CS-009](../../computer-science/en/cs-009-composing-origami-panel-constraints.md) ya distingue las comprobaciones locales de solapamiento del orden global de paneles rígidos. Esta lección se centra en un paso lógico previo: qué nos permite afirmar realmente un teorema o una comprobación acotada.

## 1. Leer la existencia como existencia

La [revisión primaria de Demaine](https://erikdemaine.org/papers/OSME2001/paper.pdf#page=6) enuncia la caracterización angular de vértice único sin direcciones de pliegues especificadas. Bajo sus hipótesis ideales, el grado par y la condición angular de Kawasaki establecen que existe una asignación montaña/valle que admite un estado local plegado en plano. No dicen que funcionen todas las asignaciones.

Para esta geometría didáctica, la suma alternada es `60-90+120-90=0`. Superarla responde a una pregunta de existencia sin asignación bajo las hipótesis del teorema. El receptor no debe insertar silenciosamente una asignación concreta y atribuirle la misma conclusión. Conserva en el enunciado el espesor cero, un único entorno interior, los pliegues usados y la ausencia de direcciones prescritas.

### Ejercicio 1: recuperar el cuantificador ausente

Un agente lee la prueba angular superada y escribe «todas las asignaciones M/V de estos cuatro pliegues se pliegan en plano». Reescribe la conclusión que permite el teorema. ¿Qué afirmación adicional insertó el agente?

> **Respuesta:** Bajo las hipótesis ideales declaradas de vértice único sin asignación, existe una asignación M/V que admite un plegado plano local. El agente sustituyó existencia por una afirmación universal sobre todas las asignaciones. La condición angular por sí sola no permite esa sustitución ni una afirmación sobre una hoja completa o un objeto grueso.

## 2. No convertir condiciones necesarias en un certificado

La [función auxiliar local de IX de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs) calcula ángulos alternados y el recuento de montañas menos valles. Para el etiquetado `MMMV`, el residuo angular es cero y `M-V=2`.

Sin embargo, las dos montañas e0 y e1 delimitan el mínimo estricto de 60 grados, cuyos sectores vecinos son ambos de 90 grados. Violan la restricción adicional de etiquetas opuestas descrita por el [argumento del ángulo menor de Hull](https://arxiv.org/pdf/1307.1065#page=8). Esto proporciona un contraejemplo a la suficiencia de esas dos condiciones numéricas para una asignación prescrita. No refuta el teorema angular sin asignación: su testigo existencial puede ser otra asignación.

### Ejercicio 2: separar dos proposiciones

¿Por qué puede la geometría admitir alguna asignación plana mientras `MMMV` es rechazada por una regla necesaria adicional? ¿Demuestra esta contradicción que falló el teorema de Kawasaki?

> **Respuesta:** La existencia de alguna asignación y la validez de esta asignación concreta son proposiciones distintas. La geometría didáctica satisface la condición angular sin asignación; `MMMV` viola la restricción de etiquetas del ángulo estrictamente menor pese a superar los dos filtros numéricos. No hay contradicción ni refutación del teorema de existencia.

## 3. Tratar honestamente un dominio comprobado vacío

La [lógica de aplicabilidad de IX](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs#L106-L143) excluye vértices de borde, aislados y de otros tipos de pliegue de estas comprobaciones locales de teoremas. La [especificación FOLD de la revisión fijada](https://raw.githubusercontent.com/edemaine/fold/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md) da al desconocido `U` su propio significado; no es una elección M/V satisfactoria.

En la [ficha didáctica de aplicabilidad](../../../../code/streeling/evidence/origami-local-2026-10-22/applicability-cards.json), cambiar un pliegue central a `U` deja 0 vértices aplicables. Las listas de fallos están vacías y el residuo máximo es 0. «Ningún vértice comprobado falló» puede ser cierto sin vértices comprobados. No implica que se comprobara al menos un vértice, que se resolvieran elecciones desconocidas ni que pasara el dominio completo previsto.

### Ejercicio 3: revelar una cobertura vacía

Un resumen conserva listas de fallos vacías y máximo 0, pero descarta `applicable=0`. ¿Qué inferencia errónea puede hacer el receptor? Escribe un enunciado de sustitución preciso.

> **Respuesta:** El receptor puede confundir ausencia de fallos con cobertura positiva. Un enunciado preciso es: el conjunto local comprobado está vacío porque el centro tiene un pliegue incidente desconocido; no se informó de ningún fallo dentro de ese conjunto vacío. La ficha didáctica es un modelo de ramas del código, no una ejecución del analizador completo ni una asignación resuelta.

## 4. Distinguir el analizador completo de una función auxiliar

El [predicado agregado de IX](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/layers.rs#L879-L889) combina los fallos locales con comprobaciones de isometría, orientación de pliegues, orden y otras. Nuestro contraejemplo no se proporcionó como un patrón completo de pliegues junto con un marco plegado y un orden de capas. Por tanto, no hemos observado qué devolvería ese analizador completo para un objeto completado.

Igualmente, un resultado local de plegado plano no proporciona un estado de toda la hoja sin intersecciones, una pila rígida de espesor positivo ni una trayectoria de movimiento. La [declaración de alcance de la biblioteca](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/lib.rs#L1-L46) describe comprobaciones de un estado plegado declarado y una lectura separada del espesor. La lección pertinente es conservar el dominio y el testigo de la afirmación; no hace falta una afirmación actual sobre complejidad o fabricación física.

### Ejercicio 4: acotar la afirmación sobre la implementación

Un agente informa de que «IX acepta un origami imposible» porque `MMMV` supera las dos fórmulas locales. ¿Qué pruebas faltan? Indica qué establece realmente este paquete sobre la función auxiliar.

> **Respuesta:** Faltan una entrada completa vinculada al código, un marco plegado y un orden, además de un resultado real de análisis completo. Este paquete establece que las dos condiciones numéricas locales son insuficientes para la asignación prescrita, con un contraejemplo basado en una regla necesaria adicional. No establece aceptación por el analizador completo, imposibilidad física bajo otros modelos ni un fallo de producción reproducido.

## 5. Componer conclusiones a un nivel superior

Un traspaso útil propuesto indica el sujeto, la identidad de entrada, el predicado, el dominio comprobado, las hipótesis y el testigo disponible. Para el resultado angular, el sujeto es un entorno ideal de vértice único sin asignación y la conclusión es existencial. Para una asignación proporcionada, informa de qué filtros necesarios se comprobaron y cuáles siguen ausentes. Para cobertura vacía, conserva la razón de la omisión.

Estas distinciones pueden estar en un informe tipado; un nuevo DSL sigue siendo candidato hasta que reduzca errores reales posteriores frente a esa alternativa más sencilla. Un renderizador puede mostrar un candidato mientras un solucionador todavía carece de su testigo plegado. Las [fichas de afirmaciones lógicas](../../../../code/streeling/evidence/origami-local-2026-10-22/logical-claims.json) son ejemplos didácticos, no un esquema normativo ni un puente a escenas implementado.

### Ejercicio 5: redactar el traspaso semántico

Sustituye «origami validado, listo para Godot» para el ejemplo `MMMV` por un mensaje que conserve asignación, resultados numéricos, restricción adicional y resultados ausentes. ¿Implementa escribir ese mensaje el DSL propuesto?

> **Respuesta:** La asignación didáctica `MMMV` sobre sectores 60, 90, 120 y 90 supera la condición angular de Kawasaki y el recuento de Maekawa, pero viola la regla de etiquetas opuestas del ángulo estrictamente menor. No se observaron un testigo completo de estado plegado, un resultado completo de IX, un plegado físico ni una importación de Godot. Este mensaje conserva el alcance de la conclusión; no implementa ni valida un nuevo DSL.
