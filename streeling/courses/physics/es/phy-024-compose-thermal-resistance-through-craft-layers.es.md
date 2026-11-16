---
module_id: "phy-024-compose-thermal-resistance-through-craft-layers"
department: "physics"
course: "Componer la resistencia térmica de capas artesanales"
level: "advanced"
prerequisites: ["phy-017-budget-thermal-growth-at-a-metal-joint"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Componer la resistencia térmica de capas artesanales

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Se propone un relieve metálico con respaldo textil como objeto interactivo. Los nombres de los materiales sugieren una historia térmica, pero un shader superficial no determina el flujo a través del conjunto. Esta lección compone una pila plana de capas inventadas y calcula la potencia común en régimen estacionario. Amplía el prerrequisito de dilatación al determinar cómo se reparte una diferencia térmica total, en lugar de asignar esa diferencia completa a cada pieza.

En régimen estacionario sin fuente interna, todas las capas transmiten la misma potencia. La caída de temperatura de una capa es esa potencia multiplicada por su resistencia térmica. Sume resistencias antes de dividir la diferencia total; promediar conductividades ocultaría los espesores y podría cambiar la respuesta. La mayor parte de la resistencia recibe la mayor parte de la caída térmica. La igualdad de áreas es esencial para esta fórmula concreta.

El control cambia el espesor y produce resistencias iguales aunque las conductividades difieran. Comprueba si la explicación asistida conserva geometría y unidades, en vez de tratar un nombre atractivo de material como respuesta. Una futura anotación artesanal debe guardar procedencia de conductividades, contactos y temperaturas de contorno junto a las dimensiones del mallado. Los parámetros de materiales Atlas describen apariencia, no conductividad térmica medida. Un motivo repujado, un hueco adhesivo o un tejido poroso puede invalidar el modelo de placa y exigir otro experimento.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "thickness_m": [
      0.02,
      0.01
    ],
    "conductivity_W_mK": [
      0.2,
      0.5
    ],
    "area_m2": 0.5,
    "delta_K": 30
  },
  "formula": "R_i=d_i/(k_i*A); R_total=sum(R_i); power=delta/R_total; drop_i=power*R_i",
  "expected": {
    "resistances_K_W": [
      0.2,
      0.04
    ],
    "total_K_W": 0.24,
    "power_W": 125,
    "drops_K": [
      25,
      5
    ]
  },
  "negative_control": {
    "values": {
      "thickness_m": [
        0.02,
        0.05
      ],
      "conductivity_W_mK": [
        0.2,
        0.5
      ],
      "area_m2": 0.5,
      "delta_K": 30
    },
    "expected": {
      "resistances_K_W": [
        0.2,
        0.2
      ],
      "total_K_W": 0.4,
      "power_W": 75,
      "drops_K": [
        15,
        15
      ]
    }
  }
}
```

### Ejercicio 1

Calcule ambas resistencias.

<details><summary>Respuesta 1</summary>

Son `[0.2,0.04] K/W`. Divida espesor por conductividad y área común; el espesor solo no es resistencia.

</details>

### Ejercicio 2

Halle resistencia total y potencia común.

<details><summary>Respuesta 2</summary>

Son `0.24 K/W` y `125 W`. La misma potencia estacionaria atraviesa cada capa.

</details>

### Ejercicio 3

Reparta las caídas de temperatura.

<details><summary>Respuesta 3</summary>

Son `[25,5] K` y suman la diferencia impuesta. Aplicar la diferencia completa a ambas capas incumpliría el modelo en serie.

</details>

### Ejercicio 4

Aplique el control de capa más gruesa.

<details><summary>Respuesta 4</summary>

Las resistencias son `[0.2,0.2] K/W`, la potencia `75 W` y las caídas `[15,15] K`. Las conductividades solas no explican el reparto.

</details>

### Ejercicio 5

¿Un shader metálico establece la conductividad?

<details><summary>Respuesta 5</summary>

No. No se aporta calibración que relacione apariencia y coeficiente de transporte. Separe medición material y representación visual.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje una sección de un relieve con respaldo textil propuesto y reparta las caídas a mano. Examine los campos de apariencia Atlas y redacte por separado la solicitud de datos materiales que necesitaría el cálculo físico.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

El control de resistencias iguales refuta que la capa de mayor conductividad deba tener siempre la menor caída.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: phy-017-budget-thermal-growth-at-a-metal-joint](../../physics/en/phy-017-budget-thermal-growth-at-a-metal-joint.md)
- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://openstax.org/books/university-physics-volume-2/pages/1-6-mechanisms-of-heat-transfer)
- [Paquete inventado](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
