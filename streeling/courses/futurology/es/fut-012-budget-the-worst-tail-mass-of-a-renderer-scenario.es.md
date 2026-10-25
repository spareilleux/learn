---
module_id: "fut-012-budget-the-worst-tail-mass-of-a-renderer-scenario"
department: "futurology"
course: "Presupuestar la peor masa de cola de un escenario de renderizado"
level: "advanced"
prerequisites: ["fut-004-scenario-test-an-observatory-renderer", "dv-012-compute-quantiles-before-combining-latency-cohorts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Presupuestar la peor masa de cola de un escenario de renderizado

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Un futuro renderizador artesanal puede tener pérdida media favorable y un resultado raro muy grave. Un cuantil localiza el comienzo de la cola sin describir su severidad. El prerrequisito ya trata arrepentimiento máximo; esta lección usa una distribución declarada para promediar exactamente la peor masa de cola, incluida una parte del átomo límite.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Ordene pérdidas por severidad y complete la probabilidad de cola desde el peor extremo. Si el último escenario supera la masa requerida, incluya solo la fracción necesaria. Esto difiere de promediar todos los escenarios iguales o superiores al cuantil. El artículo primario aporta la minimización de parte positiva y la aproximación finita; la construcción discreta ponderada es inventada. El pipeline aporta controles de captura, sin probabilidades, calibración de pérdidas ni nuevas observaciones de renderizado.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "losses_a": [
      1,
      2,
      3,
      20
    ],
    "probabilities": [
      0.4,
      0.3,
      0.2,
      0.1
    ],
    "losses_b": [
      4,
      4,
      4,
      4
    ],
    "alpha": 0.8
  },
  "formula": "mean=sum(p_i*loss_i); VaR=smallest loss with cumulative probability>=alpha; tail_mean=min_t(t+sum(p_i*max(loss_i-t,0))/(1-alpha)); integrate exactly the worst 1-alpha probability mass, splitting a cutoff atom; compare lower means and tail means",
  "expected": {
    "mean_a": 3.6,
    "mean_b": 4,
    "var_a": 3,
    "tail_a": 11.5,
    "tail_b": 4,
    "mean_choice": "A",
    "tail_choice": "B"
  },
  "negative_control": {
    "values": {
      "losses_a": [
        1,
        2,
        3,
        4
      ],
      "probabilities": [
        0.4,
        0.3,
        0.2,
        0.1
      ],
      "losses_b": [
        4,
        4,
        4,
        4
      ],
      "alpha": 0.8
    },
    "expected": {
      "mean_a": 2,
      "mean_b": 4,
      "var_a": 3,
      "tail_a": 3.5,
      "tail_b": 4,
      "mean_choice": "A",
      "tail_choice": "A"
    }
  }
}
```

### Ejercicio 1

Compare pérdidas esperadas.

<details><summary>Respuesta 1</summary>

Las medias son `3.6` para A y `4` para B; el criterio de media elige `A`. Son puntos de pérdida inventados.

</details>

### Ejercicio 2

Localice el cuantil y calcule la cola.

<details><summary>Respuesta 2</summary>

A tiene cuantil `3`. Su peor masa `0.2` contiene masa `0.1` con pérdida `20` y masa `0.1` con pérdida `3`, dando `11.5`.

</details>

### Ejercicio 3

Compare la decisión basada en cola.

<details><summary>Respuesta 3</summary>

B tiene media de cola `4`, por lo que ese criterio elige `B`. El desacuerdo refleja los criterios declarados, no una incoherencia aritmética.

</details>

### Ejercicio 4

Aplique el control con pérdida extrema reducida.

<details><summary>Respuesta 4</summary>

A tiene media `2`, cuantil `3` y media de cola `3.5`; ambos criterios eligen ahora `A`. El cuantil invariable oculta la mejora de la cola.

</details>

### Ejercicio 5

¿Justifica esto una recomendación de producción?

<details><summary>Respuesta 5</summary>

No. Probabilidades, pérdidas, horizonte y estrategias admisibles necesitan evidencia. Este caso finito plantea una pregunta de planificación, no un pronóstico.

</details>

## Tarea con consulta de fuentes

Complete a mano la masa de cola en una barra de probabilidad, conservando el átomo dividido. Inspeccione los controles de captura e identifique la evidencia de escenarios ausente. Compare media, cuantil y cola antes de proponer un planificador.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

El control conserva el cuantil y cambia la media de cola; refuta que un percentil invariable implique severidad de cola invariable.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: fut-004-scenario-test-an-observatory-renderer](../../futurology/en/fut-004-scenario-test-an-observatory-renderer.md)

- [Prerrequisito ya confirmado: dv-012-compute-quantiles-before-combining-latency-cohorts](../../data-visualization/en/dv-012-compute-quantiles-before-combining-latency-cohorts.md)

- [Fuente de proyecto conservada](../../../../code/blender/scripts/glb_pipeline.py)

- [Lectura primaria](https://sites.math.washington.edu/~rtr/papers/rtr179-CVaR1.pdf)

- [Paquete inventado fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
