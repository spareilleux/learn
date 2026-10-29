---
module_id: "pm-019-minimize-stratified-review-variance-over-integer-allocations"
department: "product-management"
course: "Minimizar la varianza de revisión estratificada con asignaciones enteras"
title: "Minimizar la varianza de revisión estratificada con asignaciones enteras"
level: "intermediate"
prerequisites: ["pm-010-standardize-dogfood-failures-to-a-declared-task-mix", "pm-008-size-a-fifty-course-batch-by-review-capacity"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Minimizar la varianza de revisión estratificada con asignaciones enteras

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un estudio de revisión reparte un presupuesto fijo de muestreo entre clases con distinta variabilidad. Dar el mismo número de observaciones a todas puede desperdiciar precisión. La pregunta es limitada: ¿qué asignación entera positiva minimiza la varianza estipulada de una media estratificada bajo los supuestos declarados?

La media objetivo es una suma ponderada de medias muestrales independientes. Con muestreo independiente con reemplazo y varianzas internas conocidas, su varianza suma los pesos objetivo al cuadrado por la varianza del estrato, dividido por su tamaño muestral. Enumere todas las divisiones enteras positivas del total. Compare racionales exactos y conserve todos los mínimos. La asignación continua aporta intuición, pero redondearla no demuestra en general el óptimo entero.

Las varianzas fijas favorecen más observaciones en el estrato más variable; el control las intercambia e invierte la asignación. Los valores no provienen de defectos observados ni de disponibilidad real. Cobertura obligatoria, aprendices repetidos dependientes, costes desiguales y correcciones de población finita cambiarían el diseño. El resumen primario distingue asignación entera exacta de redondeo continuo. Un futuro planificador debería conservar la tabla completa de divisiones factibles.

## Fuentes y alcance del proyecto

[Prerrequisito: pm-010-standardize-dogfood-failures-to-a-declared-task-mix](../../product-management/en/pm-010-standardize-dogfood-failures-to-a-declared-task-mix.md)

[Prerrequisito: pm-008-size-a-fifty-course-batch-by-review-capacity](../../product-management/en/pm-008-size-a-fifty-course-batch-by-review-capacity.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://www.census.gov/library/working-papers/2014/adrm/rrs2014-07.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "total_samples": 8,
    "target_weights": [
      "1/2",
      "1/2"
    ],
    "stratum_variances": [
      1,
      9
    ]
  },
  "formula": "Enumerate [n1,total_samples-n1] with 1<=n1<total_samples. Under independent with-replacement samples, variance=sum(target_weights[h]**2*stratum_variances[h]/n[h]); keep all exact-rational minima in n1 order.",
  "expected": {
    "candidate_variances": [
      "4/7",
      "1/2",
      "8/15",
      "5/8",
      "4/5",
      "7/6",
      "16/7"
    ],
    "optimal_allocations": [
      [
        2,
        6
      ]
    ],
    "minimum_variance": "1/2"
  },
  "negative_control": {
    "values": {
      "total_samples": 8,
      "target_weights": [
        "1/2",
        "1/2"
      ],
      "stratum_variances": [
        9,
        1
      ]
    },
    "expected": {
      "candidate_variances": [
        "16/7",
        "7/6",
        "4/5",
        "5/8",
        "8/15",
        "1/2",
        "4/7"
      ],
      "optimal_allocations": [
        [
          6,
          2
        ]
      ],
      "minimum_variance": "1/2"
    },
    "why": "Swapping stratum variability reverses the exact optimal integer allocation."
  },
  "input_types": {
    "total_samples": "integer at least two",
    "target_weights": "two nonnegative rational strings summing to one",
    "stratum_variances": "two strictly positive rational variances"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No actual review precision, independent learner sampling, measured stratum variance, finite-population correction or staffing decision is established."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Enumerar cada división entera positiva y calcular su varianza exacta.

**Criterio de refutación:** El óptimo anunciado ignora una división de menor varianza o trata intentos dependientes como muestras independientes.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Halle el óptimo exacto fijo.

> **Respuesta:** La asignación `[2,6]` da varianza `1/2`, mínima entre divisiones enteras positivas. La asignación igual da `5/8`.

### Ejercicio 2

Aplique el control de varianzas intercambiadas.

> **Respuesta:** El óptimo pasa a `[6,2]` con mínimo `1/2`. Los pesos objetivo y el total muestral no cambian.

### Ejercicio 3

¿La asignación proporcional resuelve este objetivo?

> **Respuesta:** En general, no. Usa solo los pesos objetivo; esta varianza depende también de la variabilidad interna y de la factibilidad entera.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: La asignación `[2,6]` da varianza `1/2`, mínima entre divisiones enteras positivas. La asignación igual da `5/8`.
- Ejercicio 2: El óptimo pasa a `[6,2]` con mínimo `1/2`. Los pesos objetivo y el total muestral no cambian.
- Ejercicio 3: En general, no. Usa solo los pesos objetivo; esta varianza depende también de la variabilidad interna y de la factibilidad entera.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
