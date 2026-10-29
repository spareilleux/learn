---
module_id: gaa-009-test-transposition-beyond-a-memorized-fret-pattern
department: guitar-alchemist-academy
course: "Evaluar la transposición más allá de un patrón de trastes memorizado"
level: intermediate
prerequisites: ["gaa-006-separate-capo-shapes-from-sounding-pitches", "gaa-007-turn-a-voicing-result-into-a-practice-item"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Evaluar la transposición más allá de un patrón de trastes memorizado

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Reproducir un diagrama familiar no demuestra necesariamente la operación de transposición. Diseñamos una tarea con fuentes cuya clave conserva intervalos absolutos, registro y afinación. Las listas son construidas, no respuestas reales. Se permiten realizaciones distintas, pero la transformación de alturas debe poder comprobarse; las conclusiones educativas siguen pendientes.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: gaa-006-separate-capo-shapes-from-sounding-pitches](../../guitar-alchemist-academy/en/gaa-006-separate-capo-shapes-from-sounding-pitches.md)

[Prerrequisito: gaa-007-turn-a-voicing-result-into-a-practice-item](../../guitar-alchemist-academy/en/gaa-007-turn-a-voicing-result-into-a-practice-item.md)

[Artefacto del proyecto conservado](../../../../code/streeling/evidence/capo-spelling-2026-10-22/degree-context.json)

[Paquete de datos construidos](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Ejercicio 1

Parta de notas absolutas `[60,64,67]` y pida subir cada una 2 semitonos. Resulta `[62,66,69]`. La clave comprueba todas las notas y el orden. Verificar solo la raíz no basta aunque la primera altura sea correcta.

Dé el objetivo y sus intervalos desde la primera nota.

> **Respuesta.** El objetivo es `[62,66,69]`; los intervalos son `[0,4,7]`.

## 2. Ejercicio 2

Use `[62,65,69]` como control negativo. Alcanza la primera nota pedida, pero cambia el intervalo central de 4 a 3 semitonos. Una forma menor memorizada podría pasar una prueba de tónica y fallar la petición. La clave debe comprobar la transformación, no solo una etiqueta familiar.

¿Por qué falla esta propuesta?

> **Respuesta.** Sus intervalos son `[0,3,7]`; la nota central debería ser 66, no 65.

## 3. Ejercicio 3

Otro control es `[74,78,81]`: sus clases de altura coinciden, pero todas las notas están una octava por encima del objetivo absoluto. Aceptar equivalencia de octava depende de la consigna. Aquí se exige registro explícito; la igualdad de clases no amplía silenciosamente las respuestas aceptadas.

¿Es correcto el control desplazado de octava?

> **Respuesta.** No. Añade 12 al objetivo e incumple el requisito de registro absoluto.

## 4. Ejercicio 4

Para sondear transferencia, oculte la lista objetivo antes de responder y cambie el ítem inicial respecto al practicado. Conserve fuentes y calculadora permitidas. Resolver con la clave visible evalúa otro resultado. Esta distinción de diseño no valida transferencia real.

¿Qué debe conservarse antes de revelar la clave?

> **Respuesta.** La respuesta real, el ítem inicial, la ayuda y la regla de puntuación, antes de revelarla.

## 5. Ejercicio 5

La tabla conservada distingue mayor y menor natural con tónica y registro fijos. Ayuda a explicar la tercera alterada, sin probar que un alumno cometiera ese error. Una realización en el diapasón exige orden de cuerdas, afinación, posiciones permitidas y revisión musical.

¿La lista correcta demuestra digitación tocable o transferencia aprendida?

> **Respuesta.** No. Solo comprueba la clave aritmética construida; no hubo ejecución ni intento de alumno.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
