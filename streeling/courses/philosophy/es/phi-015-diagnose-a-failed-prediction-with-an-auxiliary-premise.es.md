---
module_id: "phi-015-diagnose-a-failed-prediction-with-an-auxiliary-premise"
department: "philosophy"
course: "Diagnosticar una predicción fallida con una premisa auxiliar"
level: "advanced"
prerequisites: ["phi-008-separate-a-test-oracle-from-a-specification"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Diagnosticar una predicción fallida con una premisa auxiliar

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Una prueba propuesta de origami a escena predice una cresta visible si la geometría se conserva y la captura es adecuada. La captura fracasa hipotéticamente. Un agente culpa de inmediato a la geometría, aunque pudo fallar la cámara o la iluminación. Aquí se enumeran explicaciones compatibles antes y después de verificar independientemente una premisa auxiliar. No se informa de una captura nueva ni se afirma que todos los fallos científicos se reduzcan a lógica booleana.

Defina con cuidado el modelo finito. Aquí el éxito es exactamente la conjunción de hipótesis geométrica y auxiliar de captura. Es más fuerte que afirmar que su conjunción solo implica éxito; la equivalencia es una premisa didáctica inventada. El fracaso excluye el mundo con ambas verdaderas y deja mundos con una o ambas falsas. Por sí solo no implica falsedad de la hipótesis principal. Distinga compatibilidad lógica de plausibilidad o probabilidad posterior: la tabla no aporta pesos previos.

El control verifica el auxiliar independientemente conservando la predicción fallida. Solo queda el mundo con hipótesis falsa y auxiliar verdadero. Reutilizar la misma imagen fallida como supuesta verificación de captura no aportaría la evidencia independiente estipulada. Un futuro traspaso artesanal debe nombrar comprobación auxiliar, fuente y resultado que podría contradecirla. El asistente debe conservar alternativas sin resolver, sin convertir un fallo de extremo a extremo en diagnóstico injustificado del mallado.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "observed_prediction": false,
    "auxiliary_verified": null
  },
  "formula": "enumerate Boolean worlds [H,A] lexicographically; retain worlds with (H and A)==observed_prediction and, when auxiliary_verified is not null, A==auxiliary_verified; H_false_entailed=all(not H for retained worlds) with nonempty retained set",
  "expected": {
    "worlds": [
      [
        false,
        false
      ],
      [
        false,
        true
      ],
      [
        true,
        false
      ]
    ],
    "count": 3,
    "H_false_entailed": false
  },
  "negative_control": {
    "values": {
      "observed_prediction": false,
      "auxiliary_verified": true
    },
    "expected": {
      "worlds": [
        [
          false,
          true
        ]
      ],
      "count": 1,
      "H_false_entailed": true
    }
  }
}
```

### Ejercicio 1

¿Qué mundo elimina el fracaso?

<details><summary>Respuesta 1</summary>

Elimina `[true,true]`. Bajo la equivalencia declarada ese mundo produciría necesariamente éxito.

</details>

### Ejercicio 2

Enumere los mundos restantes.

<details><summary>Respuesta 2</summary>

Son `[[false,false],[false,true],[true,false]]`, un total de `3`. No elija uno sin evidencia adicional.

</details>

### Ejercicio 3

¿Ya se refuta la hipótesis principal en el modelo?

<details><summary>Respuesta 3</summary>

No. Permanece `[true,false]`. Puede fallar el auxiliar mientras la hipótesis principal sigue verdadera.

</details>

### Ejercicio 4

Aplique verificación auxiliar independiente.

<details><summary>Respuesta 4</summary>

Solo queda `[[false,true]]`, con cuenta `1`; la hipótesis principal es falsa en todos los mundos restantes. La independencia se estipula, no se observa aquí.

</details>

### Ejercicio 5

¿La compatibilidad ordena explicaciones por probabilidad?

<details><summary>Respuesta 5</summary>

No. Faltan verosimilitudes y probabilidades previas. Contar mundos lógicos no demuestra que sus equivalentes reales sean equiprobables.

</details>

## Tarea con fuentes y referencia manual directa

Redacte una tabla manual de diagnóstico para una captura propuesta de pliegue. Nombre una comprobación geométrica y otra independiente de captura, conservándolas sin ejecutar. Pida señalar qué explicación excluiría cada una.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

El mundo restante de hipótesis verdadera y auxiliar falso refuta culpar a la hipótesis solo por el fracaso.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/en/phi-008-separate-a-test-oracle-from-a-specification.md)
- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://plato.stanford.edu/entries/scientific-method/)
- [Paquete inventado](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
