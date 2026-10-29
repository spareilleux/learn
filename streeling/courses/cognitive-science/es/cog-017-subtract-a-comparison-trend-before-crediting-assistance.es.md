---
module_id: "cog-017-subtract-a-comparison-trend-before-crediting-assistance"
department: "cognitive-science"
course: "Restar la tendencia de comparación antes de atribuir mejoras a la asistencia"
level: "intermediate"
prerequisites: ["cog-009-counterbalance-practice-order-before-comparing-interfaces", "phi-007-test-a-learning-gain-against-counterfactuals"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Restar la tendencia de comparación antes de atribuir mejoras a la asistencia

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un grupo asistido mejora después de cambiar un flujo de Learn. Un grupo de comparación también mejora. Informar solo del cambio asistido ignora una posible tendencia común. El curso contrafactual explica por qué un antes/después no identifica beneficio; este aporta una comparación concreta y su supuesto adicional.

La explicación del World Bank resta el cambio del grupo de comparación al del grupo tratado. La interpretación causal exige tendencias paralelas de los resultados sin intervención. No significa que los niveles iniciales observados deban coincidir. Una única medición previa tampoco demuestra lo que habría ocurrido después sin asistencia.

Trabaje con proporciones e identidades de grupo fijas. Conserve ambos cambios antes del contraste. El control da a los grupos el mismo cambio y mantiene una historia favorable de mejora asistida. El informe del agente debe conservar ese contraejemplo. La tabla construida no contiene participantes reales, tareas comparables ni un diseño justificado.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: cog-009-counterbalance-practice-order-before-comparing-interfaces](../../cognitive-science/en/cog-009-counterbalance-practice-order-before-comparing-interfaces.md)

[Requisito previo: phi-007-test-a-learning-gain-against-counterfactuals](../../philosophy/en/phi-007-test-a-learning-gain-against-counterfactuals.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://blogs.worldbank.org/en/impactevaluations/did-you-see-beta-beta-who-part-1)

## Modelo fijo y control

```json
{
  "values": {
    "assisted_before": 0.4,
    "assisted_after": 0.7,
    "comparison_before": 0.5,
    "comparison_after": 0.6
  },
  "formula": "assisted_change=after-before; comparison_change=after-before; contrast=assisted_change-comparison_change.",
  "expected": {
    "assisted_change": 0.3,
    "comparison_change": 0.1,
    "contrast": 0.2
  },
  "negative_control": {
    "values": {
      "assisted_before": 0.4,
      "assisted_after": 0.7,
      "comparison_before": 0.5,
      "comparison_after": 0.8
    },
    "expected": {
      "assisted_change": 0.3,
      "comparison_change": 0.3,
      "contrast": 0
    },
    "why": "Equal group changes erase the differential despite assisted before-after improvement."
  },
  "assumptions": [
    "Comparable endpoints and stable group composition; no interference.",
    "A causal reading additionally requires parallel untreated trends and no differential concurrent change."
  ],
  "limits": "Arithmetic contrast is descriptive; two periods cannot establish parallel trends, randomization or learner benefit.",
  "input_types": {
    "assisted_before": "proportion",
    "assisted_after": "proportion",
    "comparison_before": "proportion",
    "comparison_after": "proportion"
  }
}
```

### Ejercicio 1

Calcule el cambio asistido.

<details><summary>Respuesta 1</summary>

`0.7-0.4=0.3`. Describe el cambio del grupo dado, no un efecto identificado de la intervención.

</details>

### Ejercicio 2

Calcule el cambio de comparación y el contraste.

<details><summary>Respuesta 2</summary>

`0.6-0.5=0.1`, por lo que el contraste es `0.3-0.1=0.2`. Mantenga el mismo sentido de resta.

</details>

### Ejercicio 3

Aplique el control de cambios iguales.

<details><summary>Respuesta 3</summary>

El cambio de comparación pasa a `0.8-0.5=0.3`; el contraste es `0`. La mejora asistida aislada permanece.

</details>

### Ejercicio 4

¿Un nivel inicial distinto refuta las tendencias paralelas?

<details><summary>Respuesta 4</summary>

No. El supuesto trata los cambios de resultados potenciales sin intervención, no la igualdad inicial. Aquí sigue sin verificarse.

</details>

### Ejercicio 5

¿Por qué los números solos no prueban causalidad?

<details><summary>Respuesta 5</summary>

Las tendencias no observadas, la composición de grupos o cambios simultáneos pueden alterar la interpretación. El cálculo no observa esos contrafactuales.

</details>

## Tarea con consulta de fuentes

Prepare una ficha de comparación para grupos ficticios de revisión de GA antes de pedir a un agente un resumen de beneficios.

**Referencia manual directa:** Escriba ambas diferencias antes/después y réstelas con etiquetas de grupo fijas.

**Criterio de refutación:** El agente equipara el cambio asistido con beneficio pese al contraste nulo del control.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
