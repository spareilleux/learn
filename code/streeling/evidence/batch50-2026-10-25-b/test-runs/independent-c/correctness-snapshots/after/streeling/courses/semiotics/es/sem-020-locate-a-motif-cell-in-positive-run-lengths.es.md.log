---
module_id: "sem-020-locate-a-motif-cell-in-positive-run-lengths"
department: "semiotics"
course: "Localizar una celda de motivo mediante longitudes de tramo positivas"
level: "advanced"
prerequisites: ["sem-013-align-two-motif-periods-at-a-textile-seam", "inf-011-separate-compressed-size-from-preserved-information"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Localizar una celda de motivo mediante longitudes de tramo positivas

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Un borde bordado repite un motivo guardado por tramos, no por símbolos de cada celda. Tratar índice de tramo como índice de celda cambia el referente: un tramo largo de urdimbre abarca varias celdas, mientras el siguiente de trama puede abarcar solo una. Esta operación localiza una celda global reduciendo su dirección con fase al período y buscando finales acumulados. Es un contrato de significado en papel, sin analizador de producción ni nuevo formato de compresión.

Valide longitudes antes de calcular el período. Deben ser enteros positivos para que los finales acumulados crezcan estrictamente. La celda pertenece al primer final estrictamente mayor que el desplazamiento reducido; la igualdad pertenece al tramo siguiente. Así se conserva pertenencia semiabierta en fronteras internas sin confundirla con índices de teselas negativas. El módulo resuelve la repetición; la búsqueda resuelve regiones internas desiguales.

El control con longitud nula requiere rechazo, no reparación supuesta. Cambiar la longitud uno del caso principal a cero reduciría su suma de `6` a `5` si se aceptase la entrada. Eliminar después el registro de longitud nula no cambia esa suma ni los símbolos expandidos; borra la instrucción malformada y su procedencia. El contrato de longitudes positivas rechaza la entrada antes de asignarle un período. Un traspaso IX futuro puede conservar tramos adyacentes del mismo símbolo con procedencias distintas; fusionarlos debe ser una reescritura explícita con correspondencia. El asistente puede explicarla o proponerla, pero no admitir la entrada malformada porque la vista previa siga mostrando franjas.

El prerrequisito confirmado de compresión ya enseña expansión de tramos y contabilidad de tamaño. La operación nueva es consulta de celdas indexadas con fase y pertenencia de fronteras internas; no se reivindica nueva codificación ni ida y vuelta.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "runs": [
      [
        "warp",
        2
      ],
      [
        "weft",
        1
      ],
      [
        "warp",
        3
      ]
    ],
    "indices": [
      0,
      2,
      5,
      6,
      8
    ],
    "phase": 0
  },
  "formula": "reject any run length <=0 or non-integer; period=sum(lengths); offset=(index+phase)%period; choose first cumulative end strictly greater than offset",
  "expected": {
    "status": "valid",
    "period": 6,
    "samples": [
      "warp",
      "weft",
      "warp",
      "warp",
      "weft"
    ]
  },
  "negative_control": {
    "values": {
      "runs": [
        [
          "warp",
          2
        ],
        [
          "weft",
          0
        ],
        [
          "warp",
          3
        ]
      ],
      "indices": [
        0,
        2,
        5,
        6,
        8
      ],
      "phase": 0
    },
    "expected": {
      "status": "invalid_run",
      "period": null,
      "samples": null
    }
  }
}
```

### Ejercicio 1

Calcule el período.

<details><summary>Respuesta 1</summary>

Es `6`. Sume longitudes de celda, no registros de tramo, que cuentan otro objeto.

</details>

### Ejercicio 2

Resuelva la consulta en frontera interna.

<details><summary>Respuesta 2</summary>

En el índice `2`, el símbolo es `weft`. Igualar el final acumulado anterior transfiere pertenencia al tramo siguiente.

</details>

### Ejercicio 3

Resuelva todas las celdas solicitadas.

<details><summary>Respuesta 3</summary>

Los símbolos son `[warp,weft,warp,warp,weft]`. Reduzca la repetición global antes de buscar los tramos desiguales.

</details>

### Ejercicio 4

Aplique el control de tramo nulo.

<details><summary>Respuesta 4</summary>

Devuelva `invalid_run`, con período y muestras `null`. Eliminar un registro de longitud nula no cambia su contribución aritmética, pero aceptar silenciosamente el resto ocultaría la infracción del contrato de longitudes positivas.

</details>

### Ejercicio 5

¿Deben fusionarse siempre símbolos adyacentes iguales?

<details><summary>Respuesta 5</summary>

No. Los valores pueden conservarse y perderse la procedencia. Declare la equivalencia permitida y conserve correspondencia antes de reescribir.

</details>

## Tarea con fuentes y referencia manual directa

Expanda el borde a mano con direcciones de celda e identidades de tramo. Compare búsquedas y conserve el rechazo del control en vez de repararlo. Proponga una nota mínima de evidencia para un motivo IX.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

Un intérprete que anuncie `valid` para la entrada de tramo nulo incumple el contrato de longitudes positivas. Eliminar el registro no restablece la procedencia ausente ni demuestra el motivo previsto.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: sem-013-align-two-motif-periods-at-a-textile-seam](../../semiotics/en/sem-013-align-two-motif-periods-at-a-textile-seam.md)
- [Prerrequisito confirmado: inf-011-separate-compressed-size-from-preserved-information](../../information-theory/en/inf-011-separate-compressed-size-from-preserved-information.md)
- [Fuente de proyecto conservada](../../../../code/streeling/weave-godot/trial.gd)
- [Lectura primaria](https://docs.python.org/3/library/itertools.html#itertools.product)
- [Paquete inventado](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
