---
module_id: "vc-022-project-a-craft-shadow-onto-a-declared-plane"
department: "visual-computing"
course: "Proyectar una sombra artesanal sobre un plano declarado"
level: "advanced"
prerequisites: ["sem-006-preserve-orientation-across-scene-frames"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Proyectar una sombra artesanal sobre un plano declarado

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Una cresta de papel plegado proyecta una sombra propuesta sobre un pedestal del Observatory. Situarla justo debajo de la cresta presupone una luz vertical que la escena quizá no tenga. La operación sigue la dirección declarada de propagación hasta el plano receptor. Es una construcción geométrica para una anotación, sin nuevo renderizador de sombras ni observación de una escultura iluminada físicamente.

Resuelva la ecuación de profundidad del receptor para el parámetro del rayo y sustitúyalo después en todas las coordenadas. Distinga la propagación de la luz de un vector dirigido hacia la fuente. Invertir la convención puede llevar la intersección detrás del punto. El rayo frontal rechaza un parámetro negativo aunque la recta infinita corte el plano. Una dirección paralela requiere una rama explícita porque dividir por su componente de profundidad no está definido.

El control conserva punto y receptor, pero elimina el movimiento en profundidad. Aísla una condición geométrica ausente. No se corrige limitando arbitrariamente el parámetro ni inventando un punto lejano. Un futuro traspaso de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) a [Godot](https://docs.godotengine.org/en/4.5/) debe conservar marco, ecuación del receptor y convención de propagación, y después probar visibilidad y oclusión con una captura fija. Un punto puede proyectarse sobre el plano infinito fuera del pedestal real o quedar oculto por otro pliegue. La intersección simple no representa esos problemas.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "point": [
      2,
      3,
      4
    ],
    "light_travel": [
      1,
      0,
      -2
    ],
    "plane_z": 0
  },
  "formula": "if d.z==0 return parallel; t=(plane_z-point.z)/d.z; if t<0 return behind; otherwise intersection=point+t*d",
  "expected": {
    "status": "hit",
    "t": 2,
    "intersection": [
      4,
      3,
      0
    ]
  },
  "negative_control": {
    "values": {
      "point": [
        2,
        3,
        4
      ],
      "light_travel": [
        1,
        0,
        0
      ],
      "plane_z": 0
    },
    "expected": {
      "status": "parallel",
      "t": null,
      "intersection": null
    }
  }
}
```

### Ejercicio 1

Derive el parámetro de intersección.

<details><summary>Respuesta 1</summary>

Es `2`. Divida el desplazamiento firmado del receptor por la componente de profundidad firmada; el valor positivo permite avanzar.

</details>

### Ejercicio 2

Halle el punto de sombra candidato.

<details><summary>Respuesta 2</summary>

Es `[4,3,0]`. El desplazamiento horizontal sigue la dirección dada; la coordenada central no cambia porque su componente es nula.

</details>

### Ejercicio 3

¿Qué convención acompaña los datos?

<details><summary>Respuesta 3</summary>

El vector describe propagación desde el punto al receptor. Un vector hacia la luz tiene sentido opuesto y no puede sustituirse sin indicarlo.

</details>

### Ejercicio 4

Aplique el control paralelo.

<details><summary>Respuesta 4</summary>

El resultado es `parallel`, con parámetro e intersección `null`. No debe fabricarse un impacto finito sustituyendo un denominador grande.

</details>

### Ejercicio 5

¿El punto candidato demuestra una sombra visible?

<details><summary>Respuesta 5</summary>

No. La superficie puede ser limitada u ocluida y falta transporte luminoso. Una captura fija del motor sigue siendo otra observación propuesta.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje cresta plegada, pedestal y flecha de propagación en un marco común. Derive el punto a mano y redacte las comprobaciones de superficie limitada y oclusión para un ensayo futuro.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

Cualquier punto de sombra finito anunciado para el control paralelo fuera del plano contradice la ecuación declarada del rayo.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: sem-006-preserve-orientation-across-scene-frames](../../semiotics/en/sem-006-preserve-orientation-across-scene-frames.md)
- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://pbr-book.org/4ed/Shapes/Basic_Shape_Interface)
- [Paquete inventado](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
