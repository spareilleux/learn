---
module_id: "cyb-012-test-feedback-delay-before-reusing-a-gain"
department: "cybernetics"
course: "Probar el retardo de realimentación antes de reutilizar una ganancia"
level: "intermediate"
prerequisites: ["cyb-008-check-convergence-before-repeating-a-correction"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Probar el retardo de realimentación antes de reutilizar una ganancia

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un agente observa que el residuo baja tras una corrección y propone reutilizar una ganancia elegida para realimentación inmediata. La observación siguiente puede describir todavía el estado anterior. El prerrequisito usa el residuo actual en su actualización. Aquí el residuo llega con una actualización de retardo, por lo que predecir el siguiente valor requiere tanto el anterior como el actual.

Mantenga explícita la inicialización. Se estipulan iguales ambos errores iniciales y la secuencia empieza por el valor actual. Aplicar la ganancia al valor anterior produce sobrepaso incluso cuando la recurrencia inmediata avanzaría monótonamente hacia cero. Un cambio de signo no demuestra por sí solo un cálculo fallido. Primero hay que reproducir la recurrencia y después juzgar la traza.

El polinomio característico resulta de sustituir una solución geométrica en la recurrencia retardada. Para la ganancia principal, las raíces conjugadas tienen módulo inferior a la unidad y el modelo lineal exacto converge. Con la ganancia modificada, las raíces están en el círculo unidad y la traza se repite. Los valores finitos ilustran la diferencia; la condición de raíces proporciona el argumento asintótico bajo los supuestos declarados.

El archivo conservado advierte que releer no crea otro ensayo y que los informes históricos no calibran un controlador inventado. Ese es el límite útil para el proyecto: un agente debe identificar qué actualización describe cada observación antes de usarla como evidencia correctiva nueva. Una ficha de etapa componible podría conservar esa relación, pero su utilidad sigue siendo una hipótesis. Compare primero las ecuaciones manualmente, sin introducir un controlador ni deducir retardo real de este ejemplo.

En el bloque [BRUTAL](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs) fijado, los resultados completos de consulta alimentan un valor suavizado guardado antes de decidir rebotes. Es un límite real donde importan identidad y momento de observación. La recurrencia siguiente difiere deliberadamente de ese controlador; sus raíces no certifican el renderizador.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: cyb-008-check-convergence-before-repeating-a-correction](../../cybernetics/en/cyb-008-check-convergence-before-repeating-a-correction.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Lectura primaria: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Lectura primaria: GA 76efbffd5af82b46c3146957a6bd4504008eeb89](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs)

## Modelo fijado y control

```json
{
  "values": {
    "gain": 0.5,
    "initial_previous": 1,
    "initial_current": 1,
    "steps": 6,
    "delay_updates": 1
  },
  "formula": "x[k+1]=x[k]-gain*x[k-1], initialized x[-1]=x[0]=1; roots solve r^2-r+gain=0.",
  "expected": {
    "trace_from_k0": [
      1,
      0.5,
      0,
      -0.25,
      -0.25,
      -0.125,
      0
    ],
    "root_modulus": 0.7071067811865476,
    "asymptotically_stable": true
  },
  "negative_control": {
    "values": {
      "gain": 1,
      "initial_previous": 1,
      "initial_current": 1,
      "steps": 6,
      "delay_updates": 1
    },
    "expected": {
      "trace_from_k0": [
        1,
        0,
        -1,
        -1,
        0,
        1,
        1
      ],
      "root_modulus": 1,
      "asymptotically_stable": false
    },
    "why": "Gain that zeros an immediate-feedback scalar error gives a nondecaying delayed cycle."
  },
  "assumptions": [
    "Exact linear scalar recurrence, fixed gain, one-update delay and no saturation or noise.",
    "Update index is dimensionless; no seconds or worker latency are inferred."
  ],
  "limits": "Root argument concerns this recurrence only; finite trace does not establish real fleet stability."
}
```

### Ejercicio 1

Calcule los primeros valores nuevos con la recurrencia retardada.

<details><summary>Respuesta 1</summary>

Son `0.5`, `0` y `-0.25`. Cada corrección usa el error anterior, incluida la inicialización declarada. Usar el valor actual recién calculado eliminaría silenciosamente el retardo.

</details>

### Ejercicio 2

Explique el polinomio característico y el módulo de las raíces del caso principal.

<details><summary>Respuesta 2</summary>

Sustituir una secuencia geométrica da `r^2-r+0.5=0`. Las raíces conjugadas tienen módulo `sqrt(0.5)=0.7071067811865476`, inferior a la unidad. Solo respalda convergencia asintótica para esta recurrencia lineal fija.

</details>

### Ejercicio 3

Aplique la ganancia del control y conserve la traza completa.

<details><summary>Respuesta 3</summary>

La traza es `[1,0,-1,-1,0,1,1]`. El módulo es `1`, así que falla la convergencia para errores iniciales arbitrarios. Volver a la pareja inicial muestra un ciclo persistente y no progreso.

</details>

### Ejercicio 4

¿Fallaría también la ganancia de control con realimentación inmediata?

<details><summary>Respuesta 4</summary>

No. Para `x[k+1]=(1-gain)*x[k]` y `gain=1`, el siguiente error es cero. La conclusión depende del momento de observación; el retardo cambia la transición analizada.

</details>

### Ejercicio 5

¿Qué evidencia real se necesita para aplicar esta lección a un bucle de agentes?

<details><summary>Respuesta 5</summary>

Conserve identidad de acción y observación, su relación causal, retardo medido y regla real. La lectura y una traza inventada por índice no miden latencia de workers ni establecen estabilidad en producción.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
