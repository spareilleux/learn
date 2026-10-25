---
module_id: "phy-019-test-sliding-before-calling-a-sculpture-stable"
department: "physics"
course: "Comprobar el deslizamiento antes de declarar estable una escultura"
level: "advanced"
prerequisites: ["phy-018-locate-a-sculpture-mass-projection"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Comprobar el deslizamiento antes de declarar estable una escultura

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

La proyección del centro de masa puede quedar dentro del apoyo y, aun así, la escultura puede deslizarse por una base inclinada. El cálculo anterior estudia el vuelco con sus propias hipótesis. Esta lección añade una desigualdad de fuerzas a una propuesta de transferencia artesanal de Blender a Godot. Una captura de aspecto estable no aporta fuerzas de contacto ni un coeficiente de fricción medido.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Descomponga el peso en las direcciones tangencial y normal. La fricción estática responde a la fuerza tangencial necesaria hasta alcanzar su límite; no equivale siempre a ese límite. Una reserva positiva significa que esta desigualdad ideal admite el equilibrio. No demuestra el coeficiente real, la resistencia al vuelco ni la detención tras una perturbación. El helper Atlas inspeccionado define posiciones y materiales, sin asignar estos parámetros de contacto.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "mass_kg": 2,
    "g_m_s2": 10,
    "sin_theta": 0.6,
    "cos_theta": 0.8,
    "mu_static": 0.8
  },
  "formula": "normal_N=m*g*cos_theta; demand_N=m*g*sin_theta; capacity_N=mu_static*normal_N; reserve_N=capacity_N-demand_N; static_feasible=reserve_N>=0",
  "expected": {
    "normal_N": 16,
    "demand_N": 12,
    "capacity_N": 12.8,
    "reserve_N": 0.8,
    "static_feasible": true
  },
  "negative_control": {
    "values": {
      "mass_kg": 2,
      "g_m_s2": 10,
      "sin_theta": 0.6,
      "cos_theta": 0.8,
      "mu_static": 0.5
    },
    "expected": {
      "normal_N": 16,
      "demand_N": 12,
      "capacity_N": 8,
      "reserve_N": -4,
      "static_feasible": false
    }
  }
}
```

### Ejercicio 1

Calcule la fuerza normal y la fuerza pendiente abajo.

<details><summary>Respuesta 1</summary>

Son `16 N` y `12 N`. Ambas usan la misma gravedad y masa declaradas; importa la dirección de cada componente.

</details>

### Ejercicio 2

Calcule el límite y la reserva.

<details><summary>Respuesta 2</summary>

El límite es `12.8 N` y la reserva `0.8 N`. La fricción estática necesaria es `12 N`, por debajo del límite.

</details>

### Ejercicio 3

¿Duplicar la masa puede resolver una desigualdad incumplida?

<details><summary>Respuesta 3</summary>

No. Demanda y capacidad aumentan en la misma proporción; el signo de la reserva no cambia para una masa positiva bajo estas hipótesis.

</details>

### Ejercicio 4

Aplique el coeficiente modificado.

<details><summary>Respuesta 4</summary>

La capacidad pasa a `8 N`, la reserva a `-4 N` y `static_feasible=false`. El resultado sobre el vuelco no corrige este fallo.

</details>

### Ejercicio 5

¿Qué justificaría una afirmación sobre el contacto en la escena?

<details><summary>Respuesta 5</summary>

Registre el marco de la pendiente, el modelo de contacto, la procedencia del coeficiente y las demás cargas. Compruebe el deslizamiento por separado de la proyección e identifique la versión del motor antes de comparar comportamientos.

</details>

## Tarea con consulta de fuentes

Dibuje el diagrama de fuerzas antes de abrir las respuestas. Inspeccione la colocación de objetos de Atlas e indique dónde haría falta un contrato de contacto. Compare a mano los coeficientes original y modificado; mantenga el vuelco como requisito independiente.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

El control refuta que la proyección sobre el apoyo baste para demostrar estabilidad estática: la geometría de apoyo permanece igual mientras falla la desigualdad de fricción.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: phy-018-locate-a-sculpture-mass-projection](../../physics/en/phy-018-locate-a-sculpture-mass-projection.md)

- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)

- [Lectura primaria](https://openstax.org/books/university-physics-volume-1/pages/6-2-friction)

- [Paquete inventado fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
