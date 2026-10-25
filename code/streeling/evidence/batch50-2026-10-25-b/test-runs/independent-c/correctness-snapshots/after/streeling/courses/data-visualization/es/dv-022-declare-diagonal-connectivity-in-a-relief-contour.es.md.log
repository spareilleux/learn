---
module_id: "dv-022-declare-diagonal-connectivity-in-a-relief-contour"
department: "data-visualization"
course: "Declarar la conectividad diagonal de un contorno de relieve"
level: "advanced"
prerequisites: ["dv-015-map-missing-stitches-without-inventing-holes"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Declarar la conectividad diagonal de un contorno de relieve

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Una vista previa de altura de relieve contiene una celda con esquinas altas diagonalmente opuestas. Todas están presentes, así que tratar datos ausentes no decide por dónde pasa el contorno. La interpolación lineal de aristas aporta posiciones, pero deja una elección de conectividad. Aquí se hace visible antes de asignar componentes a una máscara de bordado o región de metal cincelado en una escena propuesta.

Nombre esquinas y aristas con una orientación de imagen fija. El patrón alterna alto y bajo y cruza cada arista. Conectar la clase alta por el interior separa las esquinas bajas; conectar la baja separa las altas. Guarde coordenadas de cruce y política de emparejamiento en campos distintos. El control cambia solo la política: las posiciones coinciden pero cambia el número local de componentes. Una captura con los mismos puntos puede ocultar el cambio topológico.

La documentación oficial describe el caso ambiguo y ofrece una opción de conectividad; esta construcción en papel no ejecuta esa implementación. No deduce el interior desconocido de la superficie desde las esquinas ni afirma reconstruir físicamente una superficie en forma de silla de montar. Un traspaso futuro debe indicar si la conectividad es una convención inventada o está respaldada por muestreo adicional. Un asistente puede proponer cualquiera según la tarea, pero debe conservar la alternativa rechazada y su consecuencia para la identidad de las regiones.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "corners_TL_TR_BR_BL": [
      1,
      0,
      1,
      0
    ],
    "threshold": 0.5,
    "connect_high": false
  },
  "formula": "classify corners strictly above threshold; alternating high/low is ambiguous; interpolate each crossing at (threshold-a)/(b-a); connect_high false pairs top-left and right-bottom; connect_high true pairs top-right and bottom-left",
  "expected": {
    "ambiguous": true,
    "edge_fractions": [
      0.5,
      0.5,
      0.5,
      0.5
    ],
    "pairs": [
      [
        "top",
        "left"
      ],
      [
        "right",
        "bottom"
      ]
    ],
    "high_components": 2,
    "low_components": 1
  },
  "negative_control": {
    "values": {
      "corners_TL_TR_BR_BL": [
        1,
        0,
        1,
        0
      ],
      "threshold": 0.5,
      "connect_high": true
    },
    "expected": {
      "ambiguous": true,
      "edge_fractions": [
        0.5,
        0.5,
        0.5,
        0.5
      ],
      "pairs": [
        [
          "top",
          "right"
        ],
        [
          "bottom",
          "left"
        ]
      ],
      "high_components": 1,
      "low_components": 2
    }
  }
}
```

### Ejercicio 1

Clasifique el patrón de esquinas.

<details><summary>Respuesta 1</summary>

Alterna alto y bajo, por lo que el caso local es ambiguo. Datos completos de esquinas no eligen por sí solos la conectividad.

</details>

### Ejercicio 2

Localice los cruces de aristas.

<details><summary>Respuesta 2</summary>

Todas las fracciones son `0.5`. La interpolación fija posiciones sin decidir cómo emparejarlas dentro de la celda.

</details>

### Ejercicio 3

Aplique la política principal.

<details><summary>Respuesta 3</summary>

Empareje arriba con izquierda y derecha con abajo. La clase alta local tiene `2` componentes y la baja `1`.

</details>

### Ejercicio 4

Aplique el control de política.

<details><summary>Respuesta 4</summary>

Empareje arriba con derecha y abajo con izquierda. Las componentes altas pasan a `1` y las bajas a `2`, sin cambiar posiciones.

</details>

### Ejercicio 5

¿Alguna política mide el interior superficial?

<details><summary>Respuesta 5</summary>

No. Harían falta muestras adicionales o un modelo de interpolación justificado. Una convención declara significado, sin observación física.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje ambos emparejamientos para la misma celda y etiquete regiones altas. Prepare una anotación que conserve política y alternativa y pida identificar qué muestra futura cuestionaría la elección.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

Los nuevos recuentos locales refutan que la identidad de componentes permanezca igual al cambiar solo la política.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: dv-015-map-missing-stitches-without-inventing-holes](../../data-visualization/en/dv-015-map-missing-stitches-without-inventing-holes.md)
- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://scikit-image.org/docs/stable/api/skimage.measure.html#skimage.measure.find_contours)
- [Paquete inventado](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
