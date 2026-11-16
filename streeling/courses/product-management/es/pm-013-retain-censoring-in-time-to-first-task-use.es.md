---
module_id: "pm-013-retain-censoring-in-time-to-first-task-use"
department: "product-management"
course: "Conservar la censura del tiempo hasta el primer uso de la tarea"
level: "intermediate"
prerequisites: ["pm-009-separate-release-adoption-from-artifact-downloads"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Conservar la censura del tiempo hasta el primer uso de la tarea

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Los miembros de una cohorte ficticia de GA tienen duraciones de seguimiento distintas. No observar uso antes de que termine el seguimiento no significa que esa persona nunca vaya a usar la tarea. La fracción de eventos en una ventana fija y una estimación del tiempo hasta primer uso responden a preguntas diferentes cuando la observación termina pronto. El curso previo fija personas y tareas; este añade tiempo de exposición.

La lectura Kaplan-Meier de NIST define conjuntos en riesgo y factores del producto límite para historias censuradas. Adaptamos el evento de fallo a primer uso elegible de una tarea. Es un punto de evaluación construido, sin telemetría real. Quite a las personas censuradas de conjuntos posteriores, sin contar la censura como evento.

El control amplía un seguimiento sin evento. El recuento de eventos no cambia, pero sí el conjunto posterior y la estimación. Interpretar una población también exige censura no informativa. Usuarios frustrados que desaparecen antes podrían incumplir esa premisa. Calcular correctamente no diagnostica ese mecanismo. Conserve los seguimientos individuales y las marcas de censura en los resúmenes propuestos.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: pm-009-separate-release-adoption-from-artifact-downloads](../../product-management/en/pm-009-separate-release-adoption-from-artifact-downloads.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://itl.nist.gov/div898/handbook/apr/section2/apr215.htm)

## Modelo fijo y control

```json
{
  "values": {
    "followup_days": [
      1,
      2,
      3,
      4
    ],
    "event": [
      1,
      0,
      1,
      0
    ],
    "horizon_days": 3
  },
  "formula": "Event=first eligible task use; zero=censored at followup. At each event time <=horizon, risk=count(followup>=time), failures=count(event=1 at time); S multiplies (1-failures/risk). Report 1-S and raw observed events/N separately.",
  "expected": {
    "event_times": [
      1,
      3
    ],
    "risk_sets": [
      4,
      2
    ],
    "survival": [
      0.75,
      0.375
    ],
    "cumulative_first_use": 0.625,
    "raw_event_fraction": 0.5
  },
  "negative_control": {
    "values": {
      "followup_days": [
        1,
        4,
        3,
        4
      ],
      "event": [
        1,
        0,
        1,
        0
      ],
      "horizon_days": 3
    },
    "expected": {
      "event_times": [
        1,
        3
      ],
      "risk_sets": [
        4,
        3
      ],
      "survival": [
        0.75,
        0.5
      ],
      "cumulative_first_use": 0.5,
      "raw_event_fraction": 0.5
    },
    "why": "Extending the early censored followup changes the later risk set without changing observed event count."
  },
  "assumptions": [
    "Common eligible entry time and exact first-event times; distinct event times.",
    "Independent noninformative censoring is required for a population interpretation; no competing events."
  ],
  "limits": "Authored time-to-event estimate, not observed adoption, causal benefit, retention or uncertainty interval.",
  "input_types": {
    "followup_days": "list<positive real>",
    "event": "same-length list<0|1>",
    "horizon_days": "positive real"
  }
}
```

### Ejercicio 1

Construya los conjuntos en riesgo.

<details><summary>Respuesta 1</summary>

En los tiempos `[1,3]`, sus tamaños son `[4,2]`. La persona censurada antes ya no está en el conjunto posterior.

</details>

### Ejercicio 2

Calcule la supervivencia por producto límite.

<details><summary>Respuesta 2</summary>

Los valores son `[0.75,0.375]`; cada evento multiplica la supervivencia previa por su fracción sin evento.

</details>

### Ejercicio 3

Compare primer uso acumulado y fracción bruta.

<details><summary>Respuesta 3</summary>

La estimación es `0.625`, mientras la fracción observada es `0.5`. Tratan el seguimiento de forma distinta.

</details>

### Ejercicio 4

Aplique el control con seguimiento ampliado.

<details><summary>Respuesta 4</summary>

Los conjuntos pasan a `[4,3]`, la supervivencia a `[0.75,0.5]` y el uso acumulado a `0.5`. La fracción bruta sigue en `0.5`.

</details>

### Ejercicio 5

¿Un cálculo correcto demuestra censura independiente?

<details><summary>Respuesta 5</summary>

No. Trata el motivo del fin de seguimiento respecto a eventos futuros. Hace falta contexto real; la tabla no observa ese mecanismo.

</details>

## Tarea con consulta de fuentes

Prepare una ficha de primer uso para una cohorte ficticia de GA con marcas de censura.

**Referencia manual directa:** Ordene eventos, cuente quién sigue observado justo antes de cada uno y multiplique los factores a mano.

**Criterio de refutación:** Se cuenta censura como evento o alguien sigue en riesgo tras terminar su seguimiento.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
