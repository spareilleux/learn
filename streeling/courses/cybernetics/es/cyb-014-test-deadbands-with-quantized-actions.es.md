---
module_id: "cyb-014-test-deadbands-with-quantized-actions"
department: "cybernetics"
course: "Probar bandas muertas con acciones cuantizadas"
level: "intermediate"
prerequisites: ["cyb-005-stop-render-policy-flapping", "cyb-011-prevent-integral-accumulation-under-saturation"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Probar bandas muertas con acciones cuantizadas

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un agente propone corregir todo residuo distinto de cero con una unidad entera de acción. Cerca del objetivo, el actuador no puede realizar el pequeño cambio necesario. Puede atravesar el objetivo y regresar después. El prerrequisito de oscilación usa histéresis con memoria y reglas temporales; esta lección estudia una banda muerta sin memoria y una magnitud de acción discreta. El modelo no contiene rachas, reloj de permanencia ni modo anterior.

Aplique la comparación estricta antes de cada acción. Dentro de la banda, incluida su frontera, conserve el error actual. Fuera, reste un paso completo en la dirección del error. Esa corrección puede sobrepasar el objetivo. El residuo conservado es una consecuencia prevista, sin demostrar convergencia exacta. Compare tanto el número de acciones como el error restante con una política que siempre corrige.

El caso principal actúa y después permanece en un error no nulo. El control estrecha la banda y hace que ambos errores visitados exijan acción. Aparece una pareja repetida aunque no existe ruido de medida. La cuantización basta para este ciclo construido, sin explicar toda oscilación real. Añadir acumulación integral o retardo definiría otro modelo y exigiría otra traza.

El registro conservado no contiene una nueva observación de controlador. Se enlaza para separar razonamiento construido de informes históricos. Un asistente puede ayudar con una tabla o un predicado DSL, pero una traza más tranquila no justifica por sí sola un valor predeterminado del producto. La referencia manual debe incluir la tolerancia que hace aceptable el residuo y el coste de acciones repetidas. Esas elecciones requieren la tarea real y aquí siguen abiertas.

La rama adaptativa [BRUTAL](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs) fijada cambia `bounces` por pasos enteros e incluye umbrales distintos de recuperación y reducción y una guarda de permanencia. Examine esos predicados antes de compararlos con nuestra regla sin memoria. La fuente muestra elección cuantizada; la banda construida aísla otro mecanismo.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: cyb-005-stop-render-policy-flapping](../../cybernetics/en/cyb-005-stop-render-policy-flapping.md)

[Prerrequisito: cyb-011-prevent-integral-accumulation-under-saturation](../../cybernetics/en/cyb-011-prevent-integral-accumulation-under-saturation.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Lectura primaria: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Lectura primaria: GA 76efbffd5af82b46c3146957a6bd4504008eeb89](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs)

## Modelo fijado y control

```json
{
  "values": {
    "initial_error": 0.6,
    "action_step": 1,
    "deadband": 0.5,
    "updates": 4
  },
  "formula": "If abs(x)>deadband, x_next=x-action_step*sign(x); otherwise x_next=x. Equality retains the state.",
  "expected": {
    "trace": [
      0.6,
      -0.4,
      -0.4,
      -0.4,
      -0.4
    ],
    "final_error": -0.4,
    "action_count": 1
  },
  "negative_control": {
    "values": {
      "initial_error": 0.6,
      "action_step": 1,
      "deadband": 0.3,
      "updates": 4
    },
    "expected": {
      "trace": [
        0.6,
        -0.4,
        0.6,
        -0.4,
        0.6
      ],
      "final_error": 0.6,
      "action_count": 4
    },
    "why": "A narrower deadband excludes both quantized residuals and sustains alternating action."
  },
  "assumptions": [
    "Exact decimal arithmetic and instantaneous fixed-size actions.",
    "No noise, plant lag, integral term or actuator saturation."
  ],
  "limits": "Deadband reduces action in this example at the cost of nonzero residual; no production threshold or stability guarantee follows."
}
```

### Ejercicio 1

Aplique la primera acción y explique el cambio de signo.

<details><summary>Respuesta 1</summary>

Desde `0.6`, restar el paso `1` produce `-0.4`. El signo cambia porque la acción supera al error. Es coherente con el actuador cuantizado declarado y no es un efecto de redondeo.

</details>

### Ejercicio 2

Complete la traza principal y cuente acciones.

<details><summary>Respuesta 2</summary>

La traza es `[0.6,-0.4,-0.4,-0.4,-0.4]` y el número de acciones `1`. Dentro de la banda `0.5`, la regla conserva el estado. No lleva el error restante a cero.

</details>

### Ejercicio 3

Aplique el control más estrecho y explique su alternancia.

<details><summary>Respuesta 3</summary>

Con banda `0.3`, la traza es `[0.6,-0.4,0.6,-0.4,0.6]` y el número de acciones `4`. Ambas magnitudes superan la banda, así que el paso fijo sigue cruzando el objetivo.

</details>

### Ejercicio 4

¿Tiene la banda muerta la misma memoria que la histéresis del prerrequisito?

<details><summary>Respuesta 4</summary>

No. La decisión depende solo de la magnitud actual y el umbral fijo. No contiene modo retenido, contador de persistencia ni tiempo mínimo. Confundirlos cambiaría el contrato de transición.

</details>

### Ejercicio 5

¿Qué haría útil la traza principal para un proyecto real?

<details><summary>Respuesta 5</summary>

Se necesitan residuo aceptable, coste de acción, comportamiento medido del actuador y tarea comparativa conservada. Rechace recomendaciones que llamen convergencia exacta al residuo no nulo o adopten esta banda sin evidencia.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
