---
title: Fusionar mensajes de agente repetidos según su identidad
description: Fusionar mensajes de agente repetidos según su identidad — Ciencias de la computación
sidebar:
  label: CS-018 · Fusionar mensajes de agente repetidos según su identidad
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-018-merge-replayed-agent-messages-by-identity.es.md
---

:::note[Streeling University]
**CS-018** · Fusionar mensajes de agente repetidos según su identidad · intermedio · 45 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-018-merge-replayed-agent-messages-by-identity.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-005](../../computer-science/cs-005-agent-handoff-evidence-contract/)
:::

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un autor de Learn recibe dos veces un mensaje de finalización después de que el emisor pierda la confirmación. Contar entregas cuenta dos veces el mismo trabajo; borrar cualquier contenido repetido puede eliminar trabajos diferentes. La pregunta útil es qué resultado lógico identifica cada mensaje. El prerrequisito conserva la identidad del artefacto, pero no define el álgebra de la repetición. Aquí la identidad determina los grupos y la igualdad del contenido determina su coherencia.

La utilidad conservada de Learn introduce identificadores de módulos y nombres de archivo en un conjunto. Esa fuente demuestra una representación de pertenencia, sin implementar este protocolo de mensajes. Un conjunto de identificadores no revela que uno llegó con contenido diferente. Por eso el modelo valida cada grupo antes de sumar. Contenidos iguales con identidades distintas siguen siendo resultados separados; una identidad con contenidos distintos sigue siendo un conflicto. Es un contrato didáctico, sin afirmar cómo funciona el transporte actual.

La idempotencia del [RFC](https://www.rfc-editor.org/rfc/rfc9110.html#name-idempotent-methods) trata del efecto previsto de repetir una petición idéntica. No garantiza registros idénticos ni permite repetir cualquier operación con seguridad. La procedencia [W3C](https://www.w3.org/TR/2013/REC-prov-dm-20130430/) también distingue una entidad de la actividad que la utiliza. Mantenga esa distinción cuando un asistente proponga tratar cada entrega como un experimento nuevo. Una segunda notificación aporta otra entrega, sin aportar otro ensayo.

CS015 ya asigna marcos de análisis solapados al primer escritor y rechaza duplicados conflictivos. La cuestión adicional es fusionar estados acumulados por separado en cualquier orden sin borrar conflictos. Represente cada identidad lógica mediante el conjunto de sus contenidos observados. Fusione estados por unión en cada identidad; una identidad ausente aporta el conjunto vacío. La unión es asociativa, conmutativa e idempotente: agrupación, orden de llegada y repetición igual no cambian el estado final. Un conjunto unitario es coherente; varios valores indican conflicto. Una unión posterior no puede retirar un valor conflictivo. Sume contenidos unitarios solo después de validar todas las identidades. Esta álgebra conserva conflictos al fusionar estados, más allá de asignar propiedad de un intervalo de marcos.

Una fusión componible solo resulta útil si productor y consumidor comparten el alcance de la identidad. Una revisión nueva puede necesitar legítimamente otra identidad. Una marca temporal arbitraria o un nombre de wrapper no demuestra esa relación. Primero forme los grupos manualmente y después compruebe si la herramienta propuesta los conserva, rechaza los conflictos y guarda los mensajes para el diagnóstico.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: cs-005-agent-handoff-evidence-contract](../../computer-science/cs-005-agent-handoff-evidence-contract/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria: RFC 9110, June 2022, section 9.2.2](https://www.rfc-editor.org/rfc/rfc9110.html#name-idempotent-methods)

[Lectura primaria: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

## Modelo fijado y control

```json
{
  "values": {
    "messages": [
      {
        "id": "a",
        "value": 3
      },
      {
        "id": "b",
        "value": 5
      },
      {
        "id": "a",
        "value": 3
      }
    ],
    "initial": {}
  },
  "formula": "Group by id; equal repeated values collapse; any unequal values for one id produce conflict; sum unique values only when no conflict.",
  "expected": {
    "unique_count": 2,
    "sum": 8,
    "conflict": false
  },
  "negative_control": {
    "values": {
      "messages": [
        {
          "id": "a",
          "value": 3
        },
        {
          "id": "b",
          "value": 5
        },
        {
          "id": "a",
          "value": 4
        }
      ],
      "initial": {}
    },
    "expected": {
      "unique_count": 2,
      "sum": null,
      "conflict": true
    },
    "why": "Same identity now names unequal content, so replay equivalence fails."
  },
  "assumptions": [
    "Identity is stable for one logical result.",
    "Payload equality is exact; no partial effects are applied before validation."
  ],
  "limits": "An authored merge rule, not an exactly-once transport, authorization or existing GA deduplication implementation."
}
```

### Ejercicio 1

Calcule la suma de entregas y la suma por identidad. ¿Cuál responde a la pregunta sobre resultados lógicos?

<details><summary>Respuesta 1</summary>

La suma de entregas es `11`; la de resultados únicos es `8`, con `2` identidades. La primera cuenta notificaciones. Ninguna demuestra experimentos independientes; el contrato de identidad solo permite agrupar repeticiones.

</details>

### Ejercicio 2

Repita de nuevo el primer mensaje sin cambiar su contenido. ¿Qué debe ocurrir con la suma aceptada?

<details><summary>Respuesta 2</summary>

Sigue siendo `8`. Añadir un miembro igual a un grupo coherente cambia el número de entregas, pero no su contenido único. Esta es la afirmación acotada de idempotencia propuesta.

</details>

### Ejercicio 3

Aplique el contenido modificado del control. ¿Puede elegir silenciosamente el primero recibido para obtener un total válido?

<details><summary>Respuesta 3</summary>

No. La identidad `a` designa `3` y `4`, por lo que `conflict=true` y `sum=null`. Elegir un ganador añadiría una regla de resolución que este modelo no contiene.

</details>

### Ejercicio 4

¿Pueden dos ensayos auténticos devolver el mismo contenido y contarse por separado?

<details><summary>Respuesta 4</summary>

Sí, cuando sus identidades lógicas difieren. La igualdad del contenido no demuestra trabajo duplicado. Deben conservarse la identidad del ensayo y la revisión antes de interpretar el recuento como evidencia.

</details>

### Ejercicio 5

¿Qué comprobación con fuentes podría rechazar una fusión DSL propuesta?

<details><summary>Respuesta 5</summary>

Forme los grupos manualmente y compare ambos casos. Un total para el caso conflictivo, o un cambio tras repetir contenido igual, refuta el contrato. No se probó ningún transporte instalado ni efecto de producción.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
