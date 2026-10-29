---
module_id: gtr-011-test-barre-coverage-before-calling-a-shape-playable
department: guitar-studies
course: "Comprobar la cobertura de una cejilla antes de declarar tocable una forma"
level: intermediate
prerequisites: ["gtr-003-audit-voicing-playability"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Comprobar la cobertura de una cejilla antes de declarar tocable una forma

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

El prerrequisito mostró que dos heurísticas GA responden a preguntas distintas. Aquí añadimos el intervalo explícito de un dedo propuesto y comprobamos si su contacto contradice una cuerda solicitada al aire. Es más preciso que contar trastes repetidos. No certifica alcance, presión ni sonido y no sustituye ninguna heurística.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: gtr-003-audit-voicing-playability](../../guitar-studies/en/gtr-003-audit-voicing-playability.md)

[Artefacto del proyecto conservado](../../../../streeling/courses/guitar-studies/en/gtr-003-audit-voicing-playability.md)

[Paquete de datos construidos](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Ejercicio 1

Use numeración convencional: 1 aguda y 6 grave. Proponga contacto continuo en traste 2 sobre cuerdas 1 a 3. Los trastes solicitados son `[2,0,2]`. La cuerda central cae dentro del intervalo del dedo aunque no comparta el traste positivo repetido.

¿Qué cuerdas cubre el contacto?

> **Respuesta.** Cubre `[1,2,3]`, incluida la cuerda central solicitada al aire.

## 2. Ejercicio 2

En el modelo de contacto continuo, una cuerda cubierta no puede conservar un traste sonoro inferior a la cejilla. La cuerda 2 pide 0 y el contacto está en 2: hay contradicción. Afecta a la digitación propuesta, no a toda técnica imaginable.

Identifique el conflicto y su supuesto.

> **Respuesta.** La cuerda 2 entra en conflicto porque `0<2`; se supone contacto continuo sin arquear selectivamente el dedo.

## 3. Ejercicio 3

Para el control negativo, cambie solo la petición central a traste 3. Un contacto superior puede imponerse a la cejilla inferior en esta geometría ideal. Desaparece la contradicción, pero sigue faltando la asignación completa de dedos. Superar esta comprobación no demuestra una digitación práctica.

¿Qué cambia con `[2,3,2]`?

> **Respuesta.** Ningún traste pedido queda por debajo del traste cubierto 2. La comprobación pasa; la asignación real de dedos sigue sin resolver.

## 4. Ejercicio 4

Un detector booleano de trastes repetidos no proporciona extremos, dedo ni política de contacto. Por eso su etiqueta no debe convertirse silenciosamente en una cejilla continua. Conserve forma y contacto propuesto por separado: puede rechazarse la digitación manteniendo un voicing útil.

¿Un resultado falso garantiza que no haga falta cejilla?

> **Respuesta.** No. Solo informa su predicado; digitación explícita y observaciones musicales responden a otras preguntas.

## 5. Ejercicio 5

El prerrequisito conservado es un archivo transferido con revisión musical pendiente. Este cálculo no reescribe su historia. Para una prueba futura conserve orden de cuerdas, intervalo del dedo, notas al aire previstas, notas limpias observadas y asistencia. Compruebe primero la tabla antes de ampliar la clasificación GA.

¿Qué queda pendiente tras calcular cobertura?

> **Respuesta.** Contacto real, sonido limpio, transiciones correctas y aceptación musical siguen pendientes; no se probó a ningún intérprete.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
