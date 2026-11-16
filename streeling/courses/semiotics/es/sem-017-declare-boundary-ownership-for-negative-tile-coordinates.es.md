---
module_id: "sem-017-declare-boundary-ownership-for-negative-tile-coordinates"
department: "semiotics"
course: "Declarar la pertenencia de fronteras para coordenadas de teselas negativas"
level: "advanced"
prerequisites: ["sem-013-align-two-motif-periods-at-a-textile-seam", "cs-015-compose-overlapping-chunks-without-duplicate-frames"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Declarar la pertenencia de fronteras para coordenadas de teselas negativas

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Un motivo artesanal repetido cruza el origen del mundo. Una búsqueda que trunca hacia cero parece correcta en coordenadas positivas, pero asigna un punto a la izquierda del origen a otra tesela. Alinear períodos conserva fases; no define a qué tesela pertenece cada frontera espacial.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Defina cada celda como un intervalo semiabierto que incluye su extremo inferior. El suelo de la coordenada normalizada identifica entonces un único propietario, también en el lado negativo. La referencia [Python](https://docs.python.org/3/library/math.html) define floor, sin demostrar ejecución en una escena. Atlas guarda posiciones locales sin suministrar esta regla de índices. El control modifica solo la regla y viola el mismo contrato de pertenencia, sin cambiar a escondidas la especificación. Un futuro adaptador también necesita una política de tolerancia numérica cerca de fronteras calculadas. El prerrequisito de bloques ya adopta intervalos de fotogramas semiabiertos. Su unión no deriva la dirección de una celda a partir de una coordenada real negativa; esa operación de cociente adicional es el tema de esta lección.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "coordinates": [
      -0.1,
      0,
      0.999,
      1
    ],
    "origin": 0,
    "pitch": 1,
    "index_rule": "floor"
  },
  "formula": "index=floor((x-origin)/pitch) for floor, otherwise trunc((x-origin)/pitch); lower=origin+index*pitch; owns=(lower<=x<lower+pitch); list failing coordinates",
  "expected": {
    "indices": [
      -1,
      0,
      0,
      1
    ],
    "ownership": [
      true,
      true,
      true,
      true
    ],
    "violating_coordinates": []
  },
  "negative_control": {
    "values": {
      "coordinates": [
        -0.1,
        0,
        0.999,
        1
      ],
      "origin": 0,
      "pitch": 1,
      "index_rule": "trunc"
    },
    "expected": {
      "indices": [
        0,
        0,
        0,
        1
      ],
      "ownership": [
        false,
        true,
        true,
        true
      ],
      "violating_coordinates": [
        -0.1
      ]
    }
  }
}
```

### Ejercicio 1

Obtenga los índices basados en floor.

<details><summary>Respuesta 1</summary>

Son `[-1,0,0,1]`. Cada punto pertenece al intervalo semiabierto declarado.

</details>

### Ejercicio 2

¿Quién posee el punto sobre la frontera compartida?

<details><summary>Respuesta 2</summary>

El punto `1` pertenece a la tesela `1`; la tesela `0` excluye su extremo superior. No hay doble pertenencia.

</details>

### Ejercicio 3

Aplique el control de truncamiento.

<details><summary>Respuesta 3</summary>

Produce `[0,0,0,1]`. La coordenada `-0.1` queda fuera de su intervalo asignado; su comprobación es `false`.

</details>

### Ejercicio 4

¿Los ejemplos solo positivos detectan el error?

<details><summary>Respuesta 4</summary>

No. Las coordenadas no negativas suministradas coinciden con ambas reglas. Una coordenada negativa sí discrimina entre ellas.

</details>

### Ejercicio 5

¿Qué debe conservar una colocación compuesta?

<details><summary>Respuesta 5</summary>

Mantenga origen, paso, marco de coordenadas, convención de frontera y regla de índices. Un nombre de motivo periódico no permite reconstruirlos.

</details>

## Tarea con consulta de fuentes

Dibuje intervalos vecinos alrededor del origen, coloque cada coordenada a mano y compare reglas. Inspeccione las posiciones locales Atlas e identifique la convención de pertenencia ausente antes de proponer un DSL de teselas.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

El testigo de coordenada negativa refuta que truncamiento y floor sean intercambiables para asignar teselas.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: sem-013-align-two-motif-periods-at-a-textile-seam](../../semiotics/en/sem-013-align-two-motif-periods-at-a-textile-seam.md)

- [Prerrequisito ya confirmado: cs-015-compose-overlapping-chunks-without-duplicate-frames](../../computer-science/en/cs-015-compose-overlapping-chunks-without-duplicate-frames.md)

- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)

- [Lectura primaria](https://docs.python.org/3/library/math.html)

- [Paquete inventado fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
