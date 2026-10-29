---
module_id: "sem-015-bind-a-surface-marker-to-barycentric-vertex-identity"
department: "semiotics"
course: "Vincular un marcador de superficie a la identidad de sus vértices baricéntricos"
level: "advanced"
prerequisites: ["sem-004-face-identity-under-reindexing"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Vincular un marcador de superficie a la identidad de sus vértices baricéntricos

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Un marcador de revisión puede permanecer en la misma cara nombrada y desplazarse al reordenar vértices. La identidad de cara señala la superficie; los pesos baricéntricos fijan un punto interior respecto a una terna ordenada. El curso anterior conserva el significado de la cara; este añade la vinculación necesaria para un marcador preciso.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Reordenar vértices es inocuo solo si los pesos acompañan a sus identidades. El punto permanece igual porque las contribuciones cambian de posición en la lista, no de valor. [PBRT](https://pbr-book.org/4ed/Shapes/Triangle_Meshes) muestra interpolación baricéntrica de impactos y texturas. Atlas construye mallas con colecciones de vértices, sin ser un sistema de anotaciones persistentes. Conservar la cara y los antiguos puestos de los pesos cambia el punto indicado. Remallar exige otro argumento de correspondencia.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "vertices": [
      [
        0,
        0
      ],
      [
        4,
        0
      ],
      [
        0,
        2
      ]
    ],
    "weights": [
      0.25,
      0.5,
      0.25
    ],
    "new_vertex_order": [
      0,
      2,
      1
    ],
    "remap_weights": true
  },
  "formula": "p=sum(weights[i]*vertices[i]); vertices_new=vertices[order]; weights_new=weights[order] if remap else weights; p_new=sum(weights_new[i]*vertices_new[i]); preserved=(p_new==p)",
  "expected": {
    "original": [
      2,
      0.5
    ],
    "remapped_weights": [
      0.25,
      0.25,
      0.5
    ],
    "new_point": [
      2,
      0.5
    ],
    "preserved": true
  },
  "negative_control": {
    "values": {
      "vertices": [
        [
          0,
          0
        ],
        [
          4,
          0
        ],
        [
          0,
          2
        ]
      ],
      "weights": [
        0.25,
        0.5,
        0.25
      ],
      "new_vertex_order": [
        0,
        2,
        1
      ],
      "remap_weights": false
    },
    "expected": {
      "original": [
        2,
        0.5
      ],
      "remapped_weights": [
        0.25,
        0.5,
        0.25
      ],
      "new_point": [
        1,
        1
      ],
      "preserved": false
    }
  }
}
```

### Ejercicio 1

Sitúe el marcador original.

<details><summary>Respuesta 1</summary>

Está en `[2,0.5]` en las unidades del plano declarado. Los pesos corresponden al orden original de vértices.

</details>

### Ejercicio 2

Reordene conjuntamente vértices y pesos.

<details><summary>Respuesta 2</summary>

Los pesos nuevos son `[0.25,0.25,0.5]` y producen `[2,0.5]`; `preserved=true`.

</details>

### Ejercicio 3

Aplique el control con posiciones obsoletas.

<details><summary>Respuesta 3</summary>

Los pesos sin cambiar `[0.25,0.5,0.25]` producen `[1,1]`; `preserved=false`. La cara nombrada puede seguir siendo idéntica.

</details>

### Ejercicio 4

¿Basta con que los pesos sumen la unidad para un marcador interior?

<details><summary>Respuesta 4</summary>

No. También deben ser no negativos y conservar la correspondencia con los vértices deseados.

</details>

### Ejercicio 5

¿Qué debe acompañar una anotación transferida?

<details><summary>Respuesta 5</summary>

Vincule revisión de superficie, identidades ordenadas de vértices y pesos. Una triangulación nueva requiere un traslado justificado, no reutilización ciega de índices.

</details>

## Tarea con consulta de fuentes

Dibuje manualmente el triángulo y ambos marcadores. Inspeccione la creación de mallas Atlas y proponga una anotación vinculada a la fuente y a las identidades de vértices. Confronte la conservación del identificador de cara con el control.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

La cara y su geometría no cambian, pero los pesos obsoletos desplazan el punto: esto refuta que conservar la identidad de cara baste para conservar un marcador interior.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: sem-004-face-identity-under-reindexing](../../semiotics/en/sem-004-face-identity-under-reindexing.md)

- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)

- [Lectura primaria](https://pbr-book.org/4ed/Shapes/Triangle_Meshes)

- [Paquete inventado fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
