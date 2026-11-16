---
module_id: gas-011-track-reflection-polarity-at-string-boundaries
department: guitar-acoustics
course: "Seguir la polaridad de las reflexiones en los extremos de una cuerda"
level: intermediate
prerequisites: ["gas-006-relate-pluck-position-to-string-modes"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Seguir la polaridad de las reflexiones en los extremos de una cuerda

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Un diagrama de cuerda muestra una ganancia de reflexión sin nombrar la variable propagada. Esa omisión puede invertir el signo de una explicación cuidadosa. Seguimos ondas de desplazamiento en un extremo fijo ideal, comprobamos la cancelación y distinguimos las convenciones de fuerza. Los pulsos son construidos; no se midió un puente real.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: gas-006-relate-pluck-position-to-string-modes](../../guitar-acoustics/en/gas-006-relate-pluck-position-to-string-modes.md)

[Artefacto del proyecto conservado](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Paquete de datos construidos](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Referencia primaria](https://www.dsprelated.com/freebooks/pasp/Rigid_Terminations.html)

## 1. Ejercicio 1

Declare amplitud incidente .2 mm y un mismo eje transversal positivo para ambas componentes. En un extremo fijo inmóvil ideal, la suma debe anularse. El desplazamiento reflejado es -.2 mm. La restricción afecta a la suma, sin exigir que la onda incidente sea nula.

¿Qué coeficiente satisface esta frontera?

> **Respuesta.** El coeficiente de desplazamiento es -1: produce -.2 mm y desplazamiento total 0 mm.

## 2. Ejercicio 2

Pruebe +1 como control negativo conservando la convención de desplazamiento. La amplitud reflejada es .2 mm y la suma .4 mm. Viola la premisa de extremo fijo. Es un fallo algebraico reproducible, no una afirmación de que un búfer GA moviera un puente real.

¿Por qué falla aquí el coeficiente positivo?

> **Respuesta.** Produce .4 mm en vez de los 0 mm requeridos en la frontera fija.

## 3. Ejercicio 3

Un pulso reflejado una vez en cada extremo fijo recibe `(-1)*(-1)=+1`. El signo tras la ida y vuelta es positivo pese a las inversiones locales. Tiempo y atenuación requieren otros datos. El signo positivo del bucle no revela por sí solo si se respetaron las fronteras.

¿Un signo positivo de ida y vuelta implica extremos sin inversión?

> **Respuesta.** No. Dos inversiones producen +1; conserve por separado ambas ganancias locales.

## 4. Ejercicio 4

El texto primario distingue desplazamiento y velocidad de ondas de fuerza: sus signos en un extremo rígido difieren. Un coeficiente sin calificar queda incompleto. Antes de reutilizar una fórmula, conserve variable, orientación, unidades y tipo de frontera. Copiar un signo sin contexto puede responder correctamente a otra pregunta.

¿Qué contexto evita comparar signos de forma engañosa?

> **Respuesta.** Nombre desplazamiento o fuerza, orientación común, unidades y condición de frontera antes de comparar ganancias.

## 5. Ejercicio 5

Lea los estados de realimentación y cuerpo sin llamar frontera física a cada recurrencia. La implementación es un modelo de síntesis; el ejercicio comprueba una interpretación ideal. La nota debe identificar la recurrencia exacta y la correspondencia de modelo que falta antes de una afirmación física.

¿Este cálculo valida un puente real o repara el resultado de decaimiento?

> **Respuesta.** No. Solo valida el álgebra estipulada; la correspondencia física y el antiguo criterio de decaimiento siguen separados.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
