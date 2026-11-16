---
title: Distinguir apagar una cuerda de liberar una nota pisada
description: Distinguir apagar una cuerda de liberar una nota pisada — Estudios de guitarra
sidebar:
  label: GTR-010 · Distinguir apagar una cuerda de liberar una nota pisada
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/es/gtr-010-separate-muting-from-releasing-a-fretted-note.es.md
---

:::note[Streeling University]
**GTR-010** · Distinguir apagar una cuerda de liberar una nota pisada · intermedio · 45 minutos

Generado por el departamento *Estudios de guitarra* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/es/gtr-010-separate-muting-from-releasing-a-fretted-note.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GTR-005](../../guitar-studies/gtr-005-plan-which-string-keeps-ringing/)
:::

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Una instrucción pide liberar una nota pisada y supone que después habrá silencio. El final simbólico de una nota y el cese de vibración de la cuerda son eventos distintos. Construimos una tabla cualitativa para una cuerda, con transiciones estipuladas sin predecir amplitud. El resultado útil es un requisito explícito de apagado para revisar.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: gtr-005-plan-which-string-keeps-ringing](../../guitar-studies/gtr-005-plan-which-string-keeps-ringing/)

[Artefacto del proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Paquete de datos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Ejercicio 1

Estipule cuerda al aire 64 y traste 3, que produce nota 67. Liberar en el pulso 1 quita la restricción del traste sin prescribir la amplitud restante. La posible altura al aire importa para la revisión, pero no constituye un sonido grabado.

¿Qué altura tendría la cuerda al aire y qué sigue desconocido?

> **Respuesta.** La altura al aire es 64; amplitud residual y salida audible siguen desconocidas.

## 2. Ejercicio 2

Añada un evento de apagado en 1.25. En el modelo solo ese evento pasa al estado apagado. Entre liberación y apagado hay un intervalo que requiere observación. La tabla no afirma que liberar produzca siempre la nota al aire ni que una técnica siempre funcione.

¿Qué intervalo de silencio sigue sin verificar?

> **Respuesta.** `1.25-1=.25` pulsos; consérvelo como no verificado sin inventar una grabación.

## 3. Ejercicio 3

Un final de nota puede liberar un recurso en la tabla de ocupación mientras el silencio acústico exige todavía apagar la cuerda. Mantenga disponibilidad y estado sonoro como salidas distintas. De otro modo una asignación parece libre de conflictos sin haber comprobado resonancias no deseadas.

¿Una cuerda disponible es necesariamente silenciosa?

> **Respuesta.** No. La disponibilidad deriva del horario; el silencio requiere su propio modelo o una observación medida.

## 4. Ejercicio 4

Elimine el apagado como control negativo. La liberación restante no basta para entrar en el estado apagado del modelo. Refuta un adaptador que convirtiera cada final de nota en silencio garantizado. No elige el gesto de un intérprete ni establece una recomendación de comodidad.

¿Qué estado debe informar un adaptador que solo libera?

> **Respuesta.** Debe conservar el estado acústico sin resolver y la instrucción de apagado ausente, sin declarar silencio verificado.

## 5. Ejercicio 5

Localice las exclusiones explícitas del paquete de frase. Una tarea futura debe nombrar cuerdas que siguen sonando, liberaciones, apagados, tempo, sonidos no deseados observados y asistencia. La referencia manual es la tabla de estados, sin simulador nuevo. Un agente puede comprobarla sin afirmar que oyó el resultado.

¿Qué evidencia resuelve la cuestión acústica?

> **Respuesta.** Hace falta una observación real de ejecución o audio según la tarea prevista; aquí no se conserva ese resultado.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
