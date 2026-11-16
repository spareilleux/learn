---
title: Proyectar acciones propuestas sobre un conjunto factible
description: Proyectar acciones propuestas sobre un conjunto factible — Cibernética
sidebar:
  label: CYB-022 · Proyectar acciones propuestas sobre un conjunto factible
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/es/cyb-022-project-proposed-actions-onto-a-declared-feasible-set.es.md
---

:::note[Streeling University]
**CYB-022** · Proyectar acciones propuestas sobre un conjunto factible · intermedio · 45 minutos

Generado por el departamento *Cibernética* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/es/cyb-022-project-proposed-actions-onto-a-declared-feasible-set.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CYB-017](../../cybernetics/cyb-017-limit-command-change-separately-from-amplitude/), [CYB-020](../../cybernetics/cyb-020-check-disturbance-robust-set-closure/)
:::

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un asistente puede proponer una acción que exceda el límite del estado siguiente aunque respete el del actuador. Limitar solo el actuador omite esa otra obligación. Un filtro de viabilidad intersecta todas las restricciones declaradas y elige la acción factible más cercana a la propuesta. Las restricciones deberían provenir del contrato operativo real antes de usarlo.

El estado siguiente es aquí el estado escalar actual más la acción elegida. Transforme la cota del estado en una cota de acción e interséquela con el intervalo del actuador. Después minimice la distancia cuadrática a la propuesta. Para un intervalo cerrado no vacío, se conserva la propuesta interior y, si está fuera, se elige el extremo más próximo. Este pequeño problema explícito no certifica un filtro general.

El control exige una cota que el actuador no puede alcanzar. El conjunto factible queda vacío: debe declararse la imposibilidad en vez de inventar una orden supuestamente segura. Cercanía no significa seguridad en un mundo no modelado; faltan perturbaciones, antigüedad de observaciones y error de modelo. Un futuro artefacto agéntico debería conservar la propuesta, las restricciones activas y la razón del rechazo para no ocultar una solicitud imposible.

## Fuentes y alcance del proyecto

[Prerrequisito: cyb-017-limit-command-change-separately-from-amplitude](../../cybernetics/cyb-017-limit-command-change-separately-from-amplitude/)

[Prerrequisito: cyb-020-check-disturbance-robust-set-closure](../../cybernetics/cyb-020-check-disturbance-robust-set-closure/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://web.stanford.edu/~boyd/cvxbook/bv_cvxslides.pdf)

## Modelo fijo y control negativo

```json
{
  "values": {
    "state": 0,
    "desired_action": 3,
    "action_interval": [
      -2,
      2
    ],
    "next_state_upper": 1
  },
  "formula": "next_state=state+u. Feasible interval=[action_interval[0], min(action_interval[1], next_state_upper-state)]. If lower>upper return infeasible; otherwise project desired_action onto interval and compute squared change.",
  "expected": {
    "feasible": true,
    "feasible_interval": [
      -2,
      1
    ],
    "action": 1,
    "next_state": 1,
    "squared_change": 4
  },
  "negative_control": {
    "values": {
      "state": 0,
      "desired_action": 3,
      "action_interval": [
        -2,
        2
      ],
      "next_state_upper": -3
    },
    "expected": {
      "feasible": false,
      "feasible_interval": null,
      "action": null,
      "next_state": null,
      "squared_change": null
    },
    "why": "The tightened next-state obligation and actuator interval have no common action."
  },
  "input_types": {
    "state": "finite scalar",
    "desired_action": "finite scalar",
    "action_interval": "ordered closed real interval",
    "next_state_upper": "finite scalar upper bound"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No disturbance robustness, physical safety, actual agent action or generic quadratic-program solver is established."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Intersectar restricciones y hallar el punto más cercano, o demostrar que no existe.

**Criterio de refutación:** Se emite una orden pese a una intersección vacía o una cota de estado ignorada.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Halle el intervalo factible.

> **Respuesta:** La intersección da `[-2,1]`, no solo `[-2,2]`.

### Ejercicio 2

Proyecte la propuesta fija.

> **Respuesta:** La propuesta `3` se proyecta a `1`; el estado siguiente es `1` y el cambio cuadrático vale `4`.

### Ejercicio 3

Trate el control imposible.

> **Respuesta:** La cota superior pasa a `-3`, por debajo de la inferior `-2`. La intersección está vacía; acción y estado siguiente quedan en `null`.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: La intersección da `[-2,1]`, no solo `[-2,2]`.
- Ejercicio 2: La propuesta `3` se proyecta a `1`; el estado siguiente es `1` y el cambio cuadrático vale `4`.
- Ejercicio 3: La cota superior pasa a `-3`, por debajo de la inferior `-2`. La intersección está vacía; acción y estado siguiente quedan en `null`.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
