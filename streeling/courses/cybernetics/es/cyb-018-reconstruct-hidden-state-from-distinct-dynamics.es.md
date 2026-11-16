---
module_id: "cyb-018-reconstruct-hidden-state-from-distinct-dynamics"
department: "cybernetics"
course: "Reconstruir un estado oculto mediante dinámicas distintas"
title: "Reconstruir un estado oculto mediante dinámicas distintas"
level: "intermediate"
prerequisites: ["cyb-004-observe-before-correcting-a-feedback-loop", "gas-015-separate-mode-excitation-from-observation"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Reconstruir un estado oculto mediante dinámicas distintas

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un panel de Demerzel muestra una cantidad conjunta de trabajo pendiente. El mismo total puede ocultar proporciones distintas de redacción y revisión, que requerirían intervenciones diferentes. Repetir el agregado no ofrece necesariamente otra vista independiente. Pregunte si una dinámica conocida permite que la siguiente observación distinga los componentes antes de diseñar un estimador o culpar a un agente detenido.

La lección de guitarra vuelve invisible un modo en cierta posición del observador. Aquí el problema es temporal: un sensor observa una suma y otra tras una actualización conocida. Escriba la observación actual como el producto de la fila del sensor por el estado inicial. Sustituya la transición en la observación posterior. Apilar ambas filas forma un sistema cuyo determinante indica si esta reconstrucción exacta es única.

En el modelo fijo, los componentes evolucionan a ritmos distintos. El total posterior aporta una ecuación diferente; restar permite recuperar el segundo componente y después el primero. En el control ambos evolucionan igual. Cualquier par inicial con la misma suma produce el mismo par observado. Repetir totales idénticos no recupera la distinción perdida bajo ese modelo.

Las notas de Harvard definen la matriz de observabilidad; nuestras ecuaciones discretas finitas muestran el cálculo directamente. Los componentes son coordenadas didácticas, no recuentos calibrados de colas reales. Las colas tienen entradas, terminaciones y ruido. Una aplicación mediante agentes tendría que identificar esos efectos y comprobar la transición supuesta. Un determinante exacto en un caso inventado no demuestra observabilidad real ni justifica actuar sin evidencias.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: cyb-004-observe-before-correcting-a-feedback-loop](../../cybernetics/en/cyb-004-observe-before-correcting-a-feedback-loop.md)

[Requisito previo: gas-015-separate-mode-excitation-from-observation](../../guitar-acoustics/en/gas-015-separate-mode-excitation-from-observation.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://hankyang.seas.harvard.edu/OptimalControlEstimation/app-lti-system-theory.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "A": [
      [
        1,
        0
      ],
      [
        0,
        2
      ]
    ],
    "C": [
      1,
      1
    ],
    "x0": [
      3,
      4
    ]
  },
  "formula": "x1=A*x0; y0=C*x0; y1=C*x1; O has rows C and C*A. For 2x2 O, det=O00*O11-O01*O10. Full rank iff det != 0. Reconstruct x0 by solving O*x0=[y0,y1].",
  "expected": {
    "O": [
      [
        1,
        1
      ],
      [
        1,
        2
      ]
    ],
    "determinant": 1,
    "rank": 2,
    "outputs": [
      7,
      11
    ],
    "reconstructed": [
      3,
      4
    ]
  },
  "negative_control": {
    "values": {
      "A": [
        [
          1,
          0
        ],
        [
          0,
          1
        ]
      ],
      "C": [
        1,
        1
      ],
      "x0": [
        3,
        4
      ]
    },
    "expected": {
      "O": [
        [
          1,
          1
        ],
        [
          1,
          1
        ]
      ],
      "determinant": 0,
      "rank": 1,
      "outputs": [
        7,
        7
      ],
      "reconstructed": null
    },
    "why": "Equal dynamics keep the two components inseparable through this sensor."
  },
  "input_types": {
    "A": "2x2 integer matrix",
    "C": "length-2 integer row",
    "x0": "length-2 integer column"
  },
  "assumptions": [
    "Known exact linear autonomous dynamics, synchronized noiseless observations.",
    "No unknown inputs act between the observations."
  ],
  "limits": "Full rank is an exact model property, not measured sensor quality or evidence that a live agent state is reconstructible."
}
```

### Ejercicio 1

Forme la matriz de observaciones.

<details><summary>Respuesta 1</summary>

Las filas son `[1,1]` y `[1,2]`, con determinante `1` y rango `2`. Dos ecuaciones independientes identifican las coordenadas bajo los supuestos declarados.

</details>

### Ejercicio 2

Reconstruya el estado a partir de las salidas.

<details><summary>Respuesta 2</summary>

Las observaciones son `[7,11]`. Restarlas da el segundo componente `4`; el primero es `3`. Es una reconstrucción exacta del modelo, no una estimación medida de una cola.

</details>

### Ejercicio 3

Aplique el control con dinámicas iguales.

<details><summary>Respuesta 3</summary>

Su determinante es `0`, rango `1` y salidas `[7,7]`. La reconstrucción es `null` porque no puede elegirse un par inicial único.

</details>

### Ejercicio 4

¿Conservaría el cálculo una llegada desconocida?

<details><summary>Respuesta 4</summary>

No. Añade una contribución no modelada a la salida posterior. Registre esa entrada o revise el contrato de observación antes de interpretar los componentes reconstruidos.

</details>

### Ejercicio 5

¿Qué necesita un panel real?

<details><summary>Respuesta 5</summary>

Una transición justificada, entradas conocidas, tiempos de observación, evidencias ligadas a las fuentes y límites de ruido. La observabilidad de una matriz construida no demuestra la identidad ni el estado de un worker real.

</details>

## Tarea con consulta de fuentes

Diagnostique si un agregado propuesto para un panel de agentes distingue sus coordenadas ocultas.

**Referencia manual directa:** Escriba las ecuaciones observadas y resuélvalas o muestre a mano un par indistinguible.

**Criterio de refutación:** Estados iniciales distintos producen la misma secuencia completa de observaciones bajo el modelo.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: Forme la matriz de observaciones. — Decisión sin resolver.
- Ejercicio 2: Reconstruya el estado a partir de las salidas. — Decisión sin resolver.
- Ejercicio 3: Aplique el control con dinámicas iguales. — Decisión sin resolver.
- Ejercicio 4: ¿Conservaría el cálculo una llegada desconocida? — Decisión sin resolver.
- Ejercicio 5: ¿Qué necesita un panel real? — Decisión sin resolver.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
