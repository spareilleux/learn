---
module_id: "net-013-trace-causal-concurrency-with-vector-clocks"
department: "network-science"
course: "Trazar concurrencia causal con relojes vectoriales"
level: "intermediate"
prerequisites: ["net-008-map-clock-domains-before-ordering-events", "inf-012-retain-event-order-in-a-handoff-summary"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Trazar concurrencia causal con relojes vectoriales

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Dos agentes editan notas distintas y envían mensajes al coordinador. Ordenar por reloj físico puede colocar una acción antes aunque ninguna dependa de la otra. El prerrequisito de relojes alinea coordenadas; el de resúmenes conserva orden. Esta lección añade un orden causal parcial que permite dejar eventos incomparables. Una lista total facilita mostrar información, pero no describe causalidad automáticamente.

Cada componente registra conocimiento de eventos en un nodo fijo. Compare componente a componente. Un vector precede a otro cuando todos sus valores son menores o iguales y alguno estrictamente menor. Si cada uno tiene información que falta en el otro, ninguno domina: son concurrentes bajo el modelo. Sumar componentes o comparar lexicográficamente pierde esa distinción.

El artículo original de [Lamport](https://lamport.azurewebsites.net/pubs/time-clocks.pdf) define precedencia mediante secuencia local, envío/recepción y transitividad. Las notas de [Cambridge](https://www.cl.cam.ac.uk/teaching/2021/ConcDisSys/dist-sys-notes.pdf) presentan relojes vectoriales y la operación de recepción. Fusione con máximo por componente y después incremente la del receptor. Así se registran conocimiento entrante y evento de recepción; añadir un total escalar no conservaría esa información.

La fuente [F#](https://learn.microsoft.com/dotnet/fsharp/) conservada declara composición paralela de resultados. No proporciona marcas temporales ni demuestra qué callback real ocurrió antes. Los vectores construidos suponen toda comunicación relevante modelada y ninguna reutilización de identidad. Un sobre de traza sigue siendo consultivo hasta compararlo con un grafo manual en una tarea real. La concurrencia tampoco determina autorización o seguridad de escrituras; hace falta el contrato separado de propiedad y efectos.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: net-008-map-clock-domains-before-ordering-events](../../network-science/en/net-008-map-clock-domains-before-ordering-events.md)

[Prerrequisito: inf-012-retain-event-order-in-a-handoff-summary](../../information-theory/en/inf-012-retain-event-order-in-a-handoff-summary.md)

[Artefacto conservado del proyecto](../../../../code/streeling/functional-composition/vendor/GaAsync.fs)

[Lectura primaria: Lamport 1978, Communications of ACM 21(7), pp. 558-565](https://lamport.azurewebsites.net/pubs/time-clocks.pdf)

[Lectura primaria: Kleppmann, Cambridge Distributed Systems 2020/21](https://www.cl.cam.ac.uk/teaching/2021/ConcDisSys/dist-sys-notes.pdf)

[Lectura primaria: Microsoft F# documentation, read 2026-10-24](https://learn.microsoft.com/dotnet/fsharp/)

## Modelo fijado y control

```json
{
  "values": {
    "a": [
      2,
      0
    ],
    "b": [
      0,
      3
    ],
    "receiver_local": [
      0,
      3
    ],
    "incoming": [
      2,
      0
    ],
    "receiver_index": 1
  },
  "formula": "a precedes b iff every a[i]<=b[i] and at least one strict; concurrent iff neither precedes nor equal; receive=max(local,incoming) componentwise then increment receiver component.",
  "expected": {
    "a_before_b": false,
    "b_before_a": false,
    "concurrent": true,
    "receive_clock": [
      2,
      4
    ],
    "a_before_receive": true
  },
  "negative_control": {
    "values": {
      "a": [
        2,
        0
      ],
      "b": [
        3,
        1
      ],
      "receiver_local": [
        3,
        1
      ],
      "incoming": [
        2,
        0
      ],
      "receiver_index": 1
    },
    "expected": {
      "a_before_b": true,
      "b_before_a": false,
      "concurrent": false,
      "receive_clock": [
        3,
        2
      ],
      "a_before_receive": true
    },
    "why": "Componentwise dominance replaces incomparability when causal knowledge includes the earlier event."
  },
  "assumptions": [
    "Fixed node identities and component order.",
    "Clocks are generated by the stated local-event/send/receive discipline with complete modeled communication."
  ],
  "limits": "Authored vectors are not live agent traces; omitted channels or restarted identities invalidate causal interpretation. No physical duration or permission follows."
}
```

### Ejercicio 1

Compare los vectores principales. ¿Algún evento es causalmente anterior?

<details><summary>Respuesta 1</summary>

Ninguno domina: `a=[2,0]` es mayor en la primera componente y `b=[0,3]` en la segunda. Por tanto `concurrent=true`. Las sumas no proporcionan relación causal.

</details>

### Ejercicio 2

Calcule el vector recibido manteniendo el orden del incremento.

<details><summary>Respuesta 2</summary>

El máximo es `[2,3]`; incrementar la componente receptora `1` da `[2,4]`. La fusión precede al incremento. El índice utiliza el orden fijo declarado de componentes.

</details>

### Ejercicio 3

¿Precede el evento original a la recepción?

<details><summary>Respuesta 3</summary>

Sí. `[2,0]` no supera a `[2,4]` en ninguna componente y es menor en una, así que `a_before_receive=true`. Es relación causal, sin estimar duración física.

</details>

### Ejercicio 4

Aplique el control de dominancia y contraste.

<details><summary>Respuesta 4</summary>

Para `b=[3,1]`, `a_before_b=true` y `concurrent=false`. El reloj recibido es `[3,2]`. Conocimiento causal adicional cambia la relación, no solo una marca mostrada.

</details>

### Ejercicio 5

¿Qué puede invalidar una interpretación real de trazas?

<details><summary>Respuesta 5</summary>

Canales omitidos, contadores reiniciados, identidades reutilizadas u orden cambiado rompen los supuestos. Un orden total o declaración de paralelismo no sustituye trazas ausentes ni autoriza escrituras concurrentes.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
