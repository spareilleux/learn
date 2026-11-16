---
module_id: "inf-010-keep-joint-outcomes-when-composing-verdicts"
department: "information-theory"
course: "Conservar resultados conjuntos al componer veredictos"
title: "Conservar resultados conjuntos al componer veredictos"
level: "intermediate"
prerequisites: ["cs-008-compose-exact-source-review-verdicts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Conservar resultados conjuntos al componer veredictos

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [cs-008-compose-exact-source-review-verdicts.md](../../computer-science/en/cs-008-compose-exact-source-review-verdicts.md)
- [inf-003-verdict-distribution-drift.md](../../information-theory/en/inf-003-verdict-distribution-drift.md)

Un panel de Streeling muestra iguales tasas de aprobación para dos revisiones obligatorias. ¿Puede el coordinador multiplicarlas para estimar cuántos cursos aprobaron ambas? Hace falta un modelo conjunto. Los recibos ligados a fuentes exactas definen el alcance de cada veredicto; la lección de distribuciones estudia proporciones marginales. Aquí conservamos qué resultados pertenecen al mismo artefacto antes de componer una decisión que exige ambos.

Los casos elaborados comparten tasas marginales, pero emparejan las etiquetas de forma distinta. En el primero coinciden los aprobados. En el segundo, muchos corresponden a artefactos diferentes. Construya una tabla emparejada antes del titular. Cada fila representa la misma identidad de fuente en ambas comprobaciones y cada artefacto aparece una vez. Emparejar aprobaciones arbitrarias de revisiones distintas no satisface el requisito del consumidor.

Lea la separación de tipos de revisión del requisito previo. Un veredicto técnico y otro lingüístico son afirmaciones diferentes; este modelo binario los reduce deliberadamente a aprobado o suspendido para el cálculo. No autentica evaluadores ni deduce un juicio de aprendiz ausente. Incluso una aprobación conjunta es solo el resultado de su política declarada de dos controles. No autoriza globalmente la publicación ni representa todas las condiciones reales.

El producto de tasas marginales corresponde a un supuesto de independencia. Los recuentos emparejados disponibles determinan directamente la tasa conjunta: sustituirlos por el producto descarta información. La estimación puede quedar por encima o por debajo según el emparejamiento. El control negativo aporta otra tabla construida para cumplir la relación de producto. Comprueba la aritmética sin fingir que se descubrió independencia en los otros casos.

Para la tarea asistida por fuentes, examine los tipos de recibo del requisito previo y reproduzca ambas tablas a mano. Pida a un asistente que calcule la elegibilidad conjunta sin multiplicar salvo supuesto explícito. Conserve las estimaciones fallidas junto a los valores correctos. Rechace propuestas de panel que asignen igual elegibilidad conjunta a ambos casos solo porque coinciden sus resúmenes marginales.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "total": 10,
    "case_X": {
      "both_pass": 6,
      "A_only": 0,
      "B_only": 0,
      "both_fail": 4
    },
    "case_Y": {
      "both_pass": 2,
      "A_only": 4,
      "B_only": 4,
      "both_fail": 0
    }
  },
  "formula": "all_required_pass=both_pass/total; marginal_A=(both_pass+A_only)/total",
  "expected": {
    "A_rate": 0.6,
    "B_rate": 0.6,
    "X_joint_rate": 0.6,
    "Y_joint_rate": 0.2,
    "independence_product": 0.36,
    "X_product_error": -0.24,
    "Y_product_error": 0.16
  },
  "negative_control": "An explicitly independent authored table with total25 and cells9,6,6,4 gives joint9/25 equal to(15/25)^2.",
  "assumptions": [
    "Same ten fictional artifacts per table; paired verdicts use identical scope; all-input policy requires both passes."
  ],
  "limits": "No actual approval prevalence or independence is measured; valid verdicts still require identity and authority checks."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Calcule ambas tasas marginales.

<details>
<summary>Respuesta 1</summary>

En ambos casos A y B aprueban `6/10=0.6` cada uno.

</details>

### Ejercicio 2

Calcule las tasas de aprobación conjunta.

<details>
<summary>Respuesta 2</summary>

X da `6/10=0.6`; Y da `2/10=0.2`.

</details>

### Ejercicio 3

Compare la estimación por producto.

<details>
<summary>Respuesta 3</summary>

`0.6*0.6=0.36`; estimación menos valor real: X `-0.24`, Y `0.16`.

</details>

### Ejercicio 4

Verifique el control independiente.

<details>
<summary>Respuesta 4</summary>

Las celdas `9,6,6,4` suman `25`; `9/25=(15/25)^2=0.36`.

</details>

### Ejercicio 5

¿Aprobar conjuntamente autoriza publicar?

<details>
<summary>Respuesta 5</summary>

No. Identidad, alcance, otros controles y autoridad del efecto siguen siendo requisitos distintos.

</details>

[Paquete de pruebas fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
