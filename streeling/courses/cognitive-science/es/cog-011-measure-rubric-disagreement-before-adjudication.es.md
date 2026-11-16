---
module_id: "cog-011-measure-rubric-disagreement-before-adjudication"
department: "cognitive-science"
course: "Medir el desacuerdo de la rúbrica antes de adjudicar"
title: "Medir el desacuerdo de la rúbrica antes de adjudicar"
level: "intermediate"
prerequisites: ["cog-008-choose-probes-that-distinguish-reasoning-models"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Medir el desacuerdo de la rúbrica antes de adjudicar

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [cog-008-choose-probes-that-distinguish-reasoning-models.md](../../cognitive-science/en/cog-008-choose-probes-that-distinguish-reasoning-models.md)
- [cs-008-compose-exact-source-review-verdicts.md](../../computer-science/en/cs-008-compose-exact-source-review-verdicts.md)

Dos evaluadores dan la misma puntuación total a una explicación de práctica de GA. ¿Coincidieron en cada respuesta? Un total puede ocultar desacuerdos opuestos. El requisito previo conserva patrones de respuesta y no solo totales. Aquí las observaciones son valoraciones emparejadas ficticias; la operación consiste en conservar el desacuerdo antes de que una adjudicación determine el resultado final.

La lección sobre revisión de fuentes exactas ya distingue las afirmaciones de cada tipo de recibo. Respete esa frontera: ambos evaluadores deben examinar el mismo artefacto y revisión de rúbrica. Otros bytes o reglas producen otra comparación. Las etiquetas binarias están estipuladas para el cálculo y no autentican aprobaciones humanas. Sus totales iguales no demuestran independencia ni corrección.

Construya una tabla emparejada con ambos aprueban, solo aprueba el primer evaluador, solo aprueba el otro y ambos suspenden. Cada elemento pertenece exactamente a una celda. La diagonal da el acuerdo; las otras celdas identifican casos para discutir. Conserve la identidad de los elementos para inspeccionar las explicaciones en disputa. Un porcentaje sin identidades no basta para dirigir la corrección.

Los vectores tienen iguales totales de aprobados, pero discrepan en elementos concretos. La decisión mayoritaria o consensuada es posterior y no debe sustituir los vectores originales. Tras una adjudicación, conserve las notas iniciales, el motivo y la etiqueta final. De lo contrario, el registro podría sugerir que las valoraciones independientes coincidieron desde el principio. El consenso también puede ser incorrecto; este modelo no aporta un oráculo externo.

El control negativo copia un vector en el otro. Produce acuerdo perfecto aritméticamente, pero destruye la independencia necesaria para la comparación. Para la tarea asistida por fuentes, elija una tarea de explicación sin soluciones del requisito previo y redacte una rúbrica binaria con ejemplos de fallo. La referencia directa es una tabla completada a mano. Pida a un asistente que encuentre discrepancias y separe su ayuda de futuras valoraciones humanas. Rechace informes que conviertan totales iguales en acuerdo o llamen independientes a etiquetas copiadas.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "rater_A": [
      1,
      1,
      0,
      0,
      1,
      0
    ],
    "rater_B": [
      1,
      0,
      0,
      1,
      1,
      0
    ]
  },
  "formula": "agreement=count(A_i=B_i)/paired_count; disagreement=1-agreement",
  "expected": {
    "both_pass": 2,
    "A_only": 1,
    "B_only": 1,
    "both_fail": 2,
    "paired": 6,
    "agreement_fraction": "4/6",
    "disagreement_fraction": "2/6",
    "disputed_items": [
      2,
      4
    ],
    "unanimous_pass_fraction": "2/6"
  },
  "negative_control": "Replacing B with A creates perfect agreement but supplies no independent rating.",
  "assumptions": [
    "Binary fixed rubric, same six artifacts, independent fictional ratings, no missing ratings."
  ],
  "limits": "Raw agreement is neither validity nor chance-corrected reliability; no human raters were observed."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Complete los recuentos emparejados.

<details>
<summary>Respuesta 1</summary>

Ambos aprueban `2`, solo A `1`, solo B `1`, ambos suspenden `2`; total `6`.

</details>

### Ejercicio 2

Calcule acuerdo y desacuerdo.

<details>
<summary>Respuesta 2</summary>

Acuerdo `4/6`; desacuerdo `2/6`.

</details>

### Ejercicio 3

Identifique los elementos discutidos.

<details>
<summary>Respuesta 3</summary>

Elementos `[2,4]`; proporción de aprobados unánimes `2/6`.

</details>

### Ejercicio 4

Interprete el control por copia.

<details>
<summary>Respuesta 4</summary>

Acuerdo numérico perfecto, sin segunda valoración independiente.

</details>

### Ejercicio 5

¿Qué debe conservar la adjudicación?

<details>
<summary>Respuesta 5</summary>

Valoraciones originales, revisiones del artefacto y rúbrica, pruebas discutidas, motivo y decisión final.

</details>

[Paquete de pruebas fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
