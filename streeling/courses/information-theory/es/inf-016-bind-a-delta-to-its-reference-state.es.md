---
module_id: "inf-016-bind-a-delta-to-its-reference-state"
department: "information-theory"
course: "Vincular un delta a su estado de referencia"
level: "intermediate"
prerequisites: ["inf-011-separate-compressed-size-from-preserved-information", "inf-014-retain-message-codebook-versions"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Vincular un delta a su estado de referencia

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un agente envía solo el cambio de un contador de Learn para abreviar el traspaso. El receptor añade ese cambio intacto a su contador y obtiene un total incorrecto. Ambos pueden acordar la operación y partir de estados distintos. La reversibilidad depende de la referencia, no solo del delta.

El RFC 3284 distingue una diferencia relativa a una fuente de la compresión sin fuente. Usamos una resta de enteros como analogía construida, no como su formato binario. Calcule una vez el delta del emisor y aplíquelo a cada estado receptor. No lo recalcule después de ver la meta deseada.

Un identificador de base inmutable y fiable hace explícito el requisito. La guarda rechaza otra base en vez de confundir una suma válida con el estado deseado. En un sistema real, la identidad también necesita integridad y procedencia. Una etiqueta de hash sin comprobar los bytes no establece esa premisa. Este curso propone una comprobación de traspaso sin crear un protocolo de sincronización.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: inf-011-separate-compressed-size-from-preserved-information](../../information-theory/en/inf-011-separate-compressed-size-from-preserved-information.md)

[Requisito previo: inf-014-retain-message-codebook-versions](../../information-theory/en/inf-014-retain-message-codebook-versions.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://www.rfc-editor.org/rfc/rfc3284.html)

## Modelo fijo y control

```json
{
  "values": {
    "sender_base_id": "b1",
    "sender_base": 10,
    "target": 13,
    "receiver_base_id": "b1",
    "receiver_base": 10
  },
  "formula": "delta=target-sender_base; naive=receiver_base+delta; accept iff receiver_base_id==sender_base_id; guarded reconstruction is naive if accepted else null.",
  "expected": {
    "delta": 3,
    "naive_reconstruction": 13,
    "accepted": true,
    "guarded_reconstruction": 13
  },
  "negative_control": {
    "values": {
      "sender_base_id": "b1",
      "sender_base": 10,
      "target": 13,
      "receiver_base_id": "b2",
      "receiver_base": 20
    },
    "expected": {
      "delta": 3,
      "naive_reconstruction": 23,
      "accepted": false,
      "guarded_reconstruction": null
    },
    "why": "An intact delta added to another base produces another value; a base-identity guard rejects it."
  },
  "assumptions": [
    "Integers exact; each trusted base identity denotes one immutable value.",
    "No overflow, missing delta or transport corruption."
  ],
  "limits": "Toy scalar differencing, not VCDIFF encoding, authentic identity or production synchronization.",
  "input_types": {
    "sender_base_id": "string",
    "sender_base": "integer",
    "target": "integer",
    "receiver_base_id": "string",
    "receiver_base": "integer"
  }
}
```

### Ejercicio 1

Calcule el delta del emisor.

<details><summary>Respuesta 1</summary>

`13-10=3`. El delta describe una relación con su base; no es el valor objetivo por sí solo.

</details>

### Ejercicio 2

Reconstruya con la base coincidente.

<details><summary>Respuesta 2</summary>

`10+3=13`; los identificadores coinciden, por lo que `accepted=true` y la reconstrucción protegida es `13`.

</details>

### Ejercicio 3

Aplique el control con base distinta.

<details><summary>Respuesta 3</summary>

La suma ingenua da `20+3=23`, pero `accepted=false` y la reconstrucción protegida es `null`. La base distinta conserva el motivo.

</details>

### Ejercicio 4

¿Una suma de comprobación del delta detectaría el error?

<details><summary>Respuesta 4</summary>

No. El delta puede llegar intacto con una referencia distinta. Conserve la identidad de la base y verifique el estado asociado.

</details>

### Ejercicio 5

¿La igualdad de bases autoriza la actualización?

<details><summary>Respuesta 5</summary>

No. El requisito aritmético no aporta autoridad ni actualización atómica. Se necesitan otros contratos y evidencia.

</details>

## Tarea con consulta de fuentes

Prepare una ficha de referencia para contadores ficticios de Learn y desafíe a un asistente con una base incorrecta.

**Referencia manual directa:** Reste la base del emisor y sume el delta sin cambiarlo a cada base receptora declarada.

**Criterio de refutación:** Se acepta una meta con base distinta o el receptor recalcula el delta sin declararlo.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
