---
module_id: "cs-021-accumulate-independent-validation-errors"
department: "computer-science"
course: "Acumular errores de validación independientes"
level: "intermediate"
prerequisites: ["cs-010-compose-fail-fast-ga-computations"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Acumular errores de validación independientes

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Una solicitud de audio de GA puede tener una frecuencia inválida, un número de canales no admitido y una cantidad negativa de tramas. Devolver solo el primer error obliga a corregirla en varios ciclos. Aun así, las etapas de audio dependientes no deben continuar tras un fallo. Separe la inspección de entradas independientes del cálculo dependiente antes de elegir cómo componerlas.

La documentación de FSharp.Core define el comportamiento de `Result.bind` ante un error. No promete recopilar los posteriores. Nuestra tabla construida define otra operación: inspeccionar cada campo independiente, concatenar los nombres de los errores y no crear una solicitud aceptada hasta que la lista quede vacía. Es un ejercicio de diseño de interfaz, no un sustituto del módulo de resultados de GA.

Un atajo tentador consiste en ejecutar todas las etapas y reunir sus fallos. Eso pierde la premisa de independencia: decodificar muestras puede requerir un formato válido. En una propuesta de DSL, anote las dependencias junto a cada comprobación. Tener más diagnósticos solo ayuda si tienen sentido y preceden a los efectos.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: cs-010-compose-fail-fast-ga-computations](../../computer-science/en/cs-010-compose-fail-fast-ga-computations.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-resultmodule.html)

## Modelo fijo y control

```json
{
  "values": {
    "sample_rate_hz": 0,
    "channels": 3,
    "frames": -1
  },
  "formula": "Validate fields independently in sample_rate_hz, channels, frames order: rate>0; channels in [1,2]; frames>=0. Concatenate error field names. Reject if any error; no effects occur.",
  "expected": {
    "errors": [
      "sample_rate_hz",
      "channels",
      "frames"
    ],
    "error_count": 3,
    "accepted": false
  },
  "negative_control": {
    "values": {
      "sample_rate_hz": 48000,
      "channels": 2,
      "frames": 64
    },
    "expected": {
      "errors": [],
      "error_count": 0,
      "accepted": true
    },
    "why": "Valid inputs remove every independent error without substituting defaults."
  },
  "assumptions": [
    "Pure total field checks; no check depends on another field being valid.",
    "Error order follows declared field order; frames is an integer."
  ],
  "limits": "Accumulation does not authorize dependent audio work or provide a GA implementation.",
  "input_types": {
    "sample_rate_hz": "integer",
    "channels": "integer",
    "frames": "integer"
  }
}
```

### Ejercicio 1

Enumere los errores del caso fijo.

<details><summary>Respuesta 1</summary>

La lista ordenada es `[sample_rate_hz,channels,frames]`, con `3` errores. Cada campo incumple su regla; el orden procede del contrato, no del momento del hallazgo.

</details>

### Ejercicio 2

¿Qué devolvería una cadena que se detiene al primer fallo?

<details><summary>Respuesta 2</summary>

Conservaría solo `sample_rate_hz` con este orden. Puede ser correcto para cálculos dependientes, pero no produce la lista completa solicitada.

</details>

### Ejercicio 3

Aplique el control válido.

<details><summary>Respuesta 3</summary>

Con `48000`, `2` y `64`, la lista es `[]`, el recuento es `0` y la solicitud se acepta. Ningún valor predeterminado reparó una entrada.

</details>

### Ejercicio 4

¿Puede ejecutarse un decodificador durante la recopilación?

<details><summary>Respuesta 4</summary>

Solo si sus propios requisitos se establecen por separado. Estas comprobaciones puras no aportan un búfer válido ni autorizan efectos dependientes.

</details>

### Ejercicio 5

¿Qué refutaría una propuesta de acumulación?

<details><summary>Respuesta 5</summary>

Perder un error, cambiar su identidad o aceptar una solicitud con errores pendientes refuta el contrato. Añadir texto no compensa un diagnóstico ausente.

</details>

## Tarea con consulta de fuentes

Prepare una nota de diagnóstico para una solicitud de audio ficticia de GA y pida a un asistente que conserve todos los fallos independientes.

**Referencia manual directa:** Escriba una tabla campo/regla/error y concatene los errores en el orden declarado.

**Criterio de refutación:** Desaparece un error independiente o se acepta una lista no vacía.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
