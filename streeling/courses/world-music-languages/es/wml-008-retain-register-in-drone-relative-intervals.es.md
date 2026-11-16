---
module_id: wml-008-retain-register-in-drone-relative-intervals
department: world-music-languages
course: "Conservar el registro en intervalos relativos a un bordón"
level: intermediate
prerequisites: ["wml-007-resolve-scale-degrees-against-tonic-and-mode"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Conservar el registro en intervalos relativos a un bordón

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Un agente describe notas respecto a un bordón, pero reduce intervalos a una octava. Las etiquetas pueden ocultar si una nota está por encima o por debajo. Conservamos por separado distancia con signo en semitonos y clase reducida. El ejemplo inventado no atribuye sistemas, escalas ni convenciones a ninguna comunidad.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: wml-007-resolve-scale-degrees-against-tonic-and-mode](../../world-music-languages/en/wml-007-resolve-scale-degrees-against-tonic-and-mode.md)

[Artefacto del proyecto conservado](../../../../code/streeling/evidence/capo-spelling-2026-10-22/degree-context.json)

[Paquete de datos construidos](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Ejercicio 1

Estipule bordón absoluto 60 y notas `[55,67,79]`. Reste la misma referencia antes de reducir. Los intervalos con signo son `[-5,7,19]` semitonos. El signo negativo importa: la primera nota está debajo y las demás encima.

Dé las distancias e identifique la nota inferior.

> **Respuesta.** Son `[-5,7,19]`; la nota 55 está por debajo del bordón 60.

## 2. Ejercicio 2

Reduzca cada intervalo módulo 12 a clase no negativa. Todos pasan a 7. Esa equivalencia de octava descarta dirección y registro. Puede servir para una tarea, pero no demuestra que las notas ocupen igual posición absoluta ni tengan igual procedencia.

¿Qué clases resultan y qué se pierde?

> **Respuesta.** Las clases son `[7,7,7]`; se pierden dirección y desplazamiento de octava.

## 3. Ejercicio 3

Con la distancia completa recupere la nota mediante `note=drone+delta`. Sumar solo la clase reducida daría siempre 67, sustituyendo incorrectamente 55 y 79. Este control refuta un adaptador reversible de solo clases. Ni una etiqueta ni una puntuación de confianza recuperan la octava perdida.

Reconstruya las notas con distancias completas.

> **Respuesta.** Son `[55,67,79]`; usar solo clases daría erróneamente `[67,67,67]`.

## 4. Ejercicio 4

El paquete de grados ya exige registro de tónica para notas absolutas. Una interfaz relativa al bordón necesita además referencia y política de rango, sobre todo al cruzarlo. Los semitonos excluyen deliberadamente razones de afinación, alturas continuas y convenciones no declaradas.

¿Establece un vocabulario universal relativo al bordón?

> **Respuesta.** No. Solo establece coordenadas completas y reducidas del ejemplo temperado declarado.

## 5. Ejercicio 5

Una tarea localizada debe conservar término original y referencia junto a cada coordenada derivada. Las fuentes ayudan a comprobar restas; una persona competente en la lengua y un músico evalúan terminología y realización aparte. La tabla no autoriza equivalencia cultural ni afirma canto o escucha.

¿Qué debe conservarse para mantener reversibilidad?

> **Respuesta.** Referencia60, distancias con signo, convención y etiquetas originales; la clase7 sola no basta.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
