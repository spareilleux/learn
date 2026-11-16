---
module_id: "phy-021-separate-rebound-speed-from-retained-energy"
department: "physics"
course: "Distinguir la velocidad de rebote de la energía conservada"
level: "advanced"
prerequisites: ["phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Distinguir la velocidad de rebote de la energía conservada

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Una cuenta artesanal rebota en una escena propuesta con una fracción de su velocidad de aproximación. Llamar energía conservada a esa fracción confunde una razón lineal de velocidades con una razón cuadrática de energías. El prerrequisito aporta las unidades de masa; esta lección añade un impacto con signo y define el sistema que recibe el impulso externo.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Elija como positiva la velocidad que se aleja de una pared fija. Invierta el signo de entrada y multiplique la rapidez por la restitución. La energía cinética usa el cuadrado de la velocidad, por lo que pierde la dirección que sigue siendo esencial para el impulso. El momento de la cuenta sola no se conserva: la pared actúa sobre ella. [OpenStax](https://openstax.org/books/university-physics-volume-1/pages/9-4-types-of-collisions) distingue el sistema cerrado; nuestra pared ideal queda fuera del subsistema de la cuenta. Atlas define geometría, sin medir rebotes ni resolver contactos.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "mass_kg": 0.5,
    "incoming_m_s": -4,
    "restitution": 0.5
  },
  "formula": "outgoing=-e*incoming; K_before=mass*incoming**2/2; K_after=mass*outgoing**2/2; retained_fraction=e**2; impulse=mass*(outgoing-incoming)",
  "expected": {
    "outgoing_m_s": 2,
    "K_before_J": 4,
    "K_after_J": 1,
    "retained_fraction": 0.25,
    "impulse_Ns": 3
  },
  "negative_control": {
    "values": {
      "mass_kg": 0.5,
      "incoming_m_s": -4,
      "restitution": 1
    },
    "expected": {
      "outgoing_m_s": 4,
      "K_before_J": 4,
      "K_after_J": 4,
      "retained_fraction": 1,
      "impulse_Ns": 4
    }
  }
}
```

### Ejercicio 1

Calcule la velocidad de salida.

<details><summary>Respuesta 1</summary>

Es `2 m/s`, alejándose de la pared. La inversión del signo forma parte de la regla de impacto declarada.

</details>

### Ejercicio 2

Calcule ambas energías cinéticas.

<details><summary>Respuesta 2</summary>

Son `4 J` antes y `1 J` después. La fracción conservada es `0.25`, no `0.5`.

</details>

### Ejercicio 3

Calcule el impulso sobre la pieza.

<details><summary>Respuesta 3</summary>

Es `3 N*s`. Restar un momento de entrada negativo aumenta el cambio con signo.

</details>

### Ejercicio 4

Aplique el control elástico.

<details><summary>Respuesta 4</summary>

La velocidad de salida es `4 m/s`, la fracción conservada es `1` y el impulso es `4 N*s`. Igual energía cinética no significa momento invariable.

</details>

### Ejercicio 5

¿Qué no permite establecer la fuente?

<details><summary>Respuesta 5</summary>

El helper no aporta calibración de restitución ni comportamiento de contacto. Una afirmación sobre la escena requiere ajustes del entorno y observaciones reales con el mismo límite del sistema.

</details>

## Tarea con consulta de fuentes

Dibuje la pared y las flechas de velocidad, calcule las energías a mano e inspeccione la geometría Atlas. Proponga una observación que permita comparar una trayectoria con este modelo ideal; deje vacíos los campos de medición.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

La identificación de restitución y fracción de energía cinética conservada queda refutada cuando la restitución es `0.5` y la fracción es `0.25`.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh](../../physics/en/phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh.md)

- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)

- [Lectura primaria](https://openstax.org/books/university-physics-volume-1/pages/9-4-types-of-collisions)

- [Paquete inventado fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
