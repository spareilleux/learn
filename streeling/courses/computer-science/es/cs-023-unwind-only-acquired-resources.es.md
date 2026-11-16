---
module_id: "cs-023-unwind-only-acquired-resources"
department: "computer-science"
course: "Liberar solo los recursos adquiridos"
level: "intermediate"
prerequisites: ["cs-010-compose-fail-fast-ga-computations"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Liberar solo los recursos adquiridos

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Una exportación ficticia de GA abre un recurso de entrada y luego uno de salida. El trabajo falla. Conservar el error es necesario, pero también hay que declarar la vida útil de los recursos. Detenerse al primer fallo no define por sí solo quién debe liberarlos. Separe los eventos de adquisición y liberación del resultado del trabajo.

La documentación de F# describe la liberación al salir del ámbito y el orden inverso de las vinculaciones `use` anidadas. Nuestra traza usa recursos simbólicos sin abrir archivos. Solo adquirir un recurso con éxito otorga su propiedad. Si falla la segunda adquisición, no existe un segundo recurso que liberar y el trabajo no comienza. El primer recurso adquirido sí debe liberarse.

Liberar un recurso no borra datos escritos, no anula efectos remotos ni restaura el estado de negocio. Esas acciones necesitan otros contratos. También suponemos que la liberación tiene éxito: un fallo real de limpieza requiere una política explícita. Una propuesta de DSL debe conservar la propiedad y el resultado, sin ocultarlos tras una etiqueta que parezca indicar éxito.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: cs-010-compose-fail-fast-ga-computations](../../computer-science/en/cs-010-compose-fail-fast-ga-computations.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://learn.microsoft.com/dotnet/fsharp/language-reference/resource-management-the-use-keyword)

## Modelo fijo y control

```json
{
  "values": {
    "resources": [
      "input",
      "output"
    ],
    "fail_acquire": null,
    "work_error": true
  },
  "formula": "Acquire in listed order until failure. If acquisition completes run work. Release every successfully acquired resource exactly once in reverse order. Release cannot fail in this model.",
  "expected": {
    "acquired": [
      "input",
      "output"
    ],
    "released": [
      "output",
      "input"
    ],
    "outcome": "work_error"
  },
  "negative_control": {
    "values": {
      "resources": [
        "input",
        "output"
      ],
      "fail_acquire": "output",
      "work_error": true
    },
    "expected": {
      "acquired": [
        "input"
      ],
      "released": [
        "input"
      ],
      "outcome": "acquire_error"
    },
    "why": "A failed acquisition does not create ownership; work is skipped and only input is released."
  },
  "assumptions": [
    "Acquisition failure returns no resource; all releases succeed.",
    "Nested scopes own their acquired resources; no process crash or escaping borrow."
  ],
  "limits": "No implementation, exception suppression policy, asynchronous disposal or crash recovery is provided.",
  "input_types": {
    "resources": "ordered list<unique string>",
    "fail_acquire": "string|null",
    "work_error": "boolean"
  }
}
```

### Ejercicio 1

Describa la limpieza tras el fallo del trabajo.

<details><summary>Respuesta 1</summary>

Se adquieren `[input,output]` y se liberan en orden `[output,input]`. El resultado sigue siendo `work_error`; limpiar no convierte el fallo en éxito.

</details>

### Ejercicio 2

¿Por qué resulta útil el orden inverso?

<details><summary>Respuesta 2</summary>

El ámbito interior puede depender del recurso exterior. Cerrarlo primero respeta la propiedad anidada bajo la relación declarada.

</details>

### Ejercicio 3

Aplique el control de adquisición fallida.

<details><summary>Respuesta 3</summary>

Solo se adquiere y libera `[input]`. El resultado es `acquire_error`; nunca se poseyó `output` y el trabajo se omite.

</details>

### Ejercicio 4

¿Liberar revierte el artefacto exportado?

<details><summary>Respuesta 4</summary>

No. La vida útil y la compensación de negocio son operaciones distintas. La traza no describe bytes parciales, transacciones ni efectos remotos.

</details>

### Ejercicio 5

¿Qué cambia si falla una liberación?

<details><summary>Respuesta 5</summary>

Deja de cumplirse la premisa de liberación exitosa. Hace falta una política que conserve los errores de trabajo y limpieza; aquí no se define su ocultación.

</details>

## Tarea con consulta de fuentes

Escriba una ficha de vida útil para una exportación ficticia de GA y compare la traza de un asistente con los ámbitos anidados.

**Referencia manual directa:** Liste las adquisiciones exitosas, invierta la lista para limpiar y conserve el fallo original.

**Criterio de refutación:** Se libera un recurso nunca adquirido, queda uno sin liberar o la limpieza convierte el fallo en éxito.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
