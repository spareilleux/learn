---
module_id: "dv-017-summarize-fibre-axes-without-inventing-a-direction"
department: "data-visualization"
course: "Resumir los ejes de fibras sin inventar una dirección"
level: "advanced"
prerequisites: ["dv-006-position-length-area-comparisons"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Resumir los ejes de fibras sin inventar una dirección

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Un panel textil promedia ángulos próximos al límite de representación y dibuja un eje medio perpendicular. Los ejes no tienen flecha: invertirlos conserva la orientación. Las codificaciones de posición y longitud no corrigen este error aritmético. Esta lección deriva un resumen axial antes de mostrarlo en una escena artesanal propuesta.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Duplicar cada ángulo convierte la equivalencia de media vuelta en una vuelta circular completa. Promedie los vectores unitarios resultantes y divida su ángulo. La longitud detecta cancelación; si se anula, no dibuje un eje medio. [SciPy](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.circmean.html) documenta medias circulares y advierte sobre el vector nulo; esta lección elige explícitamente null en vez de un ángulo dependiente de la implementación. Atlas contiene direcciones geométricas, sin aportar observaciones de fibras. Una media aislada también oculta grupos separados.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "angles_deg": [
      10,
      170
    ],
    "zero_tolerance": 1e-12
  },
  "formula": "C=mean(cos(2*theta*pi/180)); S=mean(sin(2*theta*pi/180)); R=hypot(C,S); axial_mean_deg=(atan2(S,C)*90/pi)%180 if R>tolerance else null; arithmetic_mean=mean(theta); normalize near-180 roundoff to 0",
  "expected": {
    "C": 0.9396926207859084,
    "S": 0,
    "R": 0.9396926207859084,
    "axial_mean_deg": 0,
    "arithmetic_mean_deg": 90
  },
  "negative_control": {
    "values": {
      "angles_deg": [
        0,
        90
      ],
      "zero_tolerance": 1e-12
    },
    "expected": {
      "C": 0,
      "S": 0,
      "R": 0,
      "axial_mean_deg": null,
      "arithmetic_mean_deg": 45
    }
  }
}
```

### Ejercicio 1

Calcule la media aritmética de los ángulos.

<details><summary>Respuesta 1</summary>

Es `90` grados y cruza los ejes casi horizontales en vez de seguir su orientación común.

</details>

### Ejercicio 2

Calcule el resumen de ángulos duplicados.

<details><summary>Respuesta 2</summary>

La longitud resultante es `0.9396926207859084` y el eje medio es `0` grados. El redondeo en el límite no debe crear otro eje.

</details>

### Ejercicio 3

Aplique el control ortogonal.

<details><summary>Respuesta 3</summary>

La longitud es `0` dentro de la tolerancia y el eje medio es `null`; la media aritmética es `45` grados.

</details>

### Ejercicio 4

¿Una media indefinida implica observaciones ausentes?

<details><summary>Respuesta 4</summary>

No. Las observaciones existen; sus orientaciones axiales equilibradas se cancelan. Distinga un resumen indefinido de datos originales ausentes.

</details>

### Ejercicio 5

¿Qué debe conservar la visualización?

<details><summary>Respuesta 5</summary>

Muestre los ejes originales o un histograma de orientación junto a la longitud resultante. Indique la convención de media vuelta y evite una flecha que implique flujo dirigido.

</details>

## Tarea con consulta de fuentes

Dibuje los ejes y después los vectores de ángulos duplicados. Inspeccione el helper direccional Atlas y explique por qué no contiene observaciones de fibras. Proponga estados visuales distintos para datos ausentes y resumen cancelado.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

La afirmación de que toda muestra no vacía de orientaciones tiene un eje medio significativo falla con el control ortogonal equilibrado.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: dv-006-position-length-area-comparisons](../../data-visualization/en/dv-006-position-length-area-comparisons.md)

- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)

- [Lectura primaria](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.circmean.html)

- [Paquete inventado fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
