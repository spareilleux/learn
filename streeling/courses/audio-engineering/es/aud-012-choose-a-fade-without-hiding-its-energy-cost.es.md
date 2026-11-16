---
module_id: aud-012-choose-a-fade-without-hiding-its-energy-cost
department: audio-engineering
course: "Elegir un fundido explicitando su coste energético"
level: intermediate
prerequisites: ["aud-006-calibrate-spectral-amplitudes", "aud-009-declare-alignment-before-a-null-test"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Elegir un fundido explicitando su coste energético

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Un fundido puede reducir una discontinuidad y cambiar a la vez los datos de una comparación de amplitud. Un informe de GA que solo describe el extremo suavizado omite ese coste. Comparamos dos envolventes finitas sobre las mismas muestras construidas, conservando soporte y sumas de cuadrados. Se decide cómo preparar la medida, sin clasificar auditivamente los fundidos.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: aud-006-calibrate-spectral-amplitudes](../../audio-engineering/en/aud-006-calibrate-spectral-amplitudes.md)

[Prerrequisito: aud-009-declare-alignment-before-a-null-test](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md)

[Artefacto del proyecto conservado](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquete de datos construidos](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Ejercicio 1

Tomemos `[1,1,1]` sobre tres tramas, con suma de cuadrados 3. Definamos la envolvente lineal de amplitud `[1,.5,0]`. Tanto los extremos como el valor central pertenecen a esta definición discreta. Una descripción vaga de la duración del fundido no determinaría esas muestras.

Aplique la envolvente lineal y calcule la suma de cuadrados.

> **Respuesta.** El resultado es `[1,.5,0]` y su suma de cuadrados es 1.25. Los extremos y la ganancia central discreta forman parte de la definición construida.

## 2. Ejercicio 2

Otra envolvente es `[1,sqrt(.5),0]`. Sus ganancias al cuadrado son `[1,.5,0]`, por lo que la entrada unitaria produce energía 1.5. La ganancia central es aproximadamente .707106781. Aunque comparten extremos y soporte, conservan sumas de cuadrados distintas. Llamarlas simplemente fundido oculta una decisión relevante.

Calcule la segunda energía y compárela con el resultado lineal.

> **Respuesta.** La segunda energía es 1.5 frente a 1.25. Igualdad de extremos y duración no implica igualdad energética según la medida declarada.

## 3. Ejercicio 3

Respecto a la energía original 3, las fracciones conservadas son `1.25/3=5/12` y `1.5/3=.5`. Se aplican a esta entrada. Multiplicar después el audio para recuperar un RMS elegido introduce otra transformación y puede cambiar los picos. Registre esa ganancia por separado; no prueba que el fundido original conservara energía.

Dé las fracciones conservadas e indique qué añade una normalización RMS posterior.

> **Respuesta.** Son `5/12` y `.5`. La normalización añade una ganancia distinta; no convierte la envolvente inicial en conservadora de energía.

## 4. Ejercicio 4

Para el control negativo, concentremos toda la energía en la última trama: `[0,0,1]`. Ambas envolventes producen `[0,0,0]`, sin energía conservada. Este caso refuta un factor universal deducido de muestras constantes. Importa tanto dónde cae la energía dentro de la envolvente como la curva de ganancia.

¿El resultado de entrada constante establece un porcentaje universal de conservación?

> **Respuesta.** No. El control limitado a la última trama da `[0,0,0]` con ambas envolventes y energía conservada nula. Toda fracción debe identificar entrada y soporte.

## 5. Ejercicio 5

Examine cómo el ejecutor conservado elige ventanas y mantiene búferes originales. Una comparación futura debe conservar copia original, envolvente, soporte, ganancia opcional y criterio. Un agente puede ayudar con las cuentas, pero la preparación debe responder a una tarea definida para el guitarrista. Ni suavizar extremos ni reducir energía establece una preferencia.

¿Qué debe conservar la nota de revisión antes de comparar resultados?

> **Respuesta.** Conserve muestras originales, envolvente, soporte, definición de energía, ganancias posteriores y criterio. Aquí no se observó ningún nuevo renderizado ni preferencia auditiva.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
