---
module_id: "inf-014-retain-message-codebook-versions"
department: "information-theory"
course: "Conservar las versiones de los diccionarios de mensajes"
level: "intermediate"
prerequisites: ["inf-004-information-loss-in-agent-handoffs"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Conservar las versiones de los diccionarios de mensajes

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un handoff compacto sustituye palabras de veredicto por etiquetas pequeñas. Todas llegan intactas, pero el agente receptor comunica el veredicto opuesto. El prerrequisito pregunta qué campos desaparecen de un resumen. Esta lección aísla otro fallo: los mismos símbolos cambian de significado entre dos diccionarios perfectamente invertibles. Transferir bytes correctamente no establece que ambos agentes eligieran la misma interpretación.

La versión del diccionario forma parte del contexto. Decodifique con la regla del emisor para obtener las etiquetas previstas y después con la del receptor, sin modificar los símbolos. Cuente discrepancias por posición en vez de comparar solo totales. Invertir la correspondencia puede conservar frecuencia y longitud cambiando todos los veredictos. Una huella de los símbolos no detectaría ese desacuerdo ni la versión semántica ausente.

El problema de comunicación de [Shannon](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf) distingue mensaje elegido y representación transmitida. Aquí suponemos un canal sin errores y examinamos las correspondencias. La procedencia [W3C](https://www.w3.org/TR/2013/REC-prov-dm-20130430/) motiva conservar la identidad de la entidad que aporta una regla de derivación. Ninguna referencia define un esquema GA nuevo. Los campos separados de metadatos y cuerpo del parser Learn ofrecen una representación concreta para examinar, sin implementar estas etiquetas binarias.

El control cambia la selección del receptor conservando todas las etiquetas. Hace explícito el acuerdo perdido y proporciona una referencia manual. Un DSL puede abreviar la correspondencia, pero debe mantener recuperable la identidad del diccionario y dejar sin resolver una versión desconocida. Elegir por plausibilidad invertiría la evidencia: el significado deseado no debe elegir el decodificador después. Aquí no se implementa migración ni política de compatibilidad.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: inf-004-information-loss-in-agent-handoffs](../../information-theory/en/inf-004-information-loss-in-agent-handoffs.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria: Shannon 1948 corrected reprint, section 6](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf)

[Lectura primaria: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

## Modelo fijado y control

```json
{
  "values": {
    "codebooks": {
      "v1": {
        "0": "pass",
        "1": "fail"
      },
      "v2": {
        "0": "fail",
        "1": "pass"
      }
    },
    "sent_version": "v2",
    "decoded_version": "v1",
    "tags": [
      0,
      1,
      1
    ]
  },
  "formula": "Decode each tag by its versioned codebook; compare intended versus receiver labels positionwise.",
  "expected": {
    "intended": [
      "fail",
      "pass",
      "pass"
    ],
    "received": [
      "pass",
      "fail",
      "fail"
    ],
    "mismatches": 3
  },
  "negative_control": {
    "values": {
      "codebooks": {
        "v1": {
          "0": "pass",
          "1": "fail"
        },
        "v2": {
          "0": "fail",
          "1": "pass"
        }
      },
      "sent_version": "v2",
      "decoded_version": "v2",
      "tags": [
        0,
        1,
        1
      ]
    },
    "expected": {
      "intended": [
        "fail",
        "pass",
        "pass"
      ],
      "received": [
        "fail",
        "pass",
        "pass"
      ],
      "mismatches": 0
    },
    "why": "Correct decoder version restores intended labels without changing transported tags."
  },
  "assumptions": [
    "Codebooks are exact bijections on supplied symbols.",
    "Tags arrive in order without channel errors; version identity is trusted for this case."
  ],
  "limits": "No real wire format or production protocol change; transport fidelity alone does not certify semantic agreement."
}
```

### Ejercicio 1

Decodifique las etiquetas con la versión del emisor.

<details><summary>Respuesta 1</summary>

Las etiquetas previstas son `[fail,pass,pass]` bajo `v2`. La correspondencia determina significado, no el tamaño visual del símbolo. Conserve la versión antes de comparar veredictos.

</details>

### Ejercicio 2

Decodifique las mismas etiquetas con la versión del receptor y cuente discrepancias.

<details><summary>Respuesta 2</summary>

El receptor obtiene `[pass,fail,fail]` bajo `v1`. Hay `3` discrepancias posicionales. Los símbolos no cambian, de modo que la integridad de bytes no distingue interpretaciones.

</details>

### Ejercicio 3

Aplique el control con versión correcta. ¿Qué repara el desacuerdo?

<details><summary>Respuesta 3</summary>

Usar `v2` en ambos extremos produce `[fail,pass,pass]` y `0` discrepancias. No cambia ninguna etiqueta transmitida. El acuerdo se restaura seleccionando el diccionario compartido, sin corregir resultados después.

</details>

### Ejercicio 4

¿Una huella de la secuencia demuestra compatibilidad semántica?

<details><summary>Respuesta 4</summary>

No. Bytes iguales pueden interpretarse con reglas distintas. La compatibilidad debe conservar identidad del diccionario y asociación con el mensaje, además de la huella del contenido.

</details>

### Ejercicio 5

¿Cómo debe informar un asistente sobre una versión desconocida?

<details><summary>Respuesta 5</summary>

Conserve etiquetas originales y marque decodificación sin resolver. No elija una regla porque su veredicto parezca plausible. Un cambio real necesita contrato de compatibilidad y pruebas más allá de esta tabla construida.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
