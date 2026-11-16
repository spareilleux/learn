---
module_id: "cog-009-counterbalance-practice-order-before-comparing-interfaces"
department: "cognitive-science"
course: "Contrabalancear el orden de práctica antes de comparar interfaces"
title: "Contrabalancear el orden de práctica antes de comparar interfaces"
level: "intermediate"
prerequisites: ["cog-007-separate-unaided-recall-from-assisted-success"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Contrabalancear el orden de práctica antes de comparar interfaces

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [cog-007-separate-unaided-recall-from-assisted-success.md](../../cognitive-science/en/cog-007-separate-unaided-recall-from-assisted-success.md)
- [pri332.htm](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm)

Una interfaz de práctica de GA parece más rápida después de que un agente rediseñe sus instrucciones. Sin embargo, el aprendiz siempre ve primero la interfaz antigua. ¿Podría explicar la familiaridad parte de la diferencia? El requisito previo sobre asistencia identifica las respuestas elegibles. Esta lección añade otra pregunta: ¿qué diseño distingue una diferencia de interfaz de un efecto supuesto del orden de práctica? Todos los tiempos son ficticios y deterministas; no hay aprendices observados.

La guía del NIST explica por qué registrar y controlar un factor ajeno al interés principal. Declaramos el periodo como ese factor y situamos cada interfaz en cada periodo con igual peso. Esta construcción didáctica equilibrada no afirma que invertir el orden elimine todo efecto de arrastre humano. El modelo supone un beneficio aditivo común en el periodo posterior y ningún aprendizaje específico de interfaz. Un piloto real tendría que cuestionar precisamente esos supuestos.

En el orden directo, la interfaz posterior combina su ventaja inicial con el beneficio del periodo. En el inverso, ambas contribuciones se compensan en el contraste interno. Mantenga la dirección de resta según la identidad de las interfaces, con independencia del orden de presentación. Cambiar también la dirección de resta fabricaría la cancelación. Menos segundos significa completar antes según este criterio; no demuestra mejor aprendizaje ni menos errores.

Promedie los contrastes con pesos iguales. Bajo el modelo aditivo declarado, el término del periodo se cancela y queda la diferencia inicial entre interfaces. El control negativo asigna tiempos iniciales idénticos. Debe conservar efectos de orden opuestos y ninguna diferencia equilibrada entre interfaces. Si un informe encuentra ventaja inicial en ese control, ha confundido orden, pesos o dirección.

Para la tarea asistida por fuentes, lea la tabla de asistencia del requisito previo y la definición del NIST. Prepare una ficha sin respuestas para una tarea de diapasón de GA: defina límites temporales, elegibilidad, registro de errores y asignación de órdenes antes de cualquier intento. La referencia directa es una tabla de asignación en papel. Pida a un asistente que critique arrastre y dificultad desigual. Rechace conclusiones basadas solo en el orden directo o que presenten estos segundos inventados como rendimiento medido de usuarios.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "A_base_seconds": 60,
    "B_base_seconds": 50,
    "second_period_change_seconds": -10,
    "AB": [
      60,
      40
    ],
    "BA": [
      50,
      50
    ]
  },
  "formula": "contrast=B_time-A_time within each order; balanced contrast=mean(order contrasts)",
  "expected": {
    "AB_contrast_seconds": -20,
    "BA_contrast_seconds": 0,
    "balanced_contrast_seconds": -10,
    "A_mean_seconds": 55,
    "B_mean_seconds": 45,
    "null_interface_balanced_contrast": 0
  },
  "negative_control": "Set both interface base times to60; order contrasts are -10 and+10 and average0.",
  "assumptions": [
    "Invented matched tasks, additive identical period benefit, no carryover, complete observations, equal order weights."
  ],
  "limits": "Not a user study, statistical significance estimate or general proof that counterbalancing removes carryover."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Calcule el contraste del orden directo.

<details>
<summary>Respuesta 1</summary>

`40-60=-20` segundos, combinando interfaz y periodo.

</details>

### Ejercicio 2

Calcule el contraste del orden inverso.

<details>
<summary>Respuesta 2</summary>

`50-50=0` segundos, conservando la dirección B menos A.

</details>

### Ejercicio 3

Calcule el contraste equilibrado.

<details>
<summary>Respuesta 3</summary>

`(-20+0)/2=-10` segundos; medias A `55`, B `45`.

</details>

### Ejercicio 4

Evalúe interfaces con igual tiempo inicial.

<details>
<summary>Respuesta 4</summary>

Los contrastes `-10` y `+10` promedian `0`.

</details>

### Ejercicio 5

¿Qué supuesto violaría el arrastre?

<details>
<summary>Respuesta 5</summary>

El modelo aditivo común sin arrastre específico de interfaz; el aprendizaje real sigue sin medirse.

</details>

[Paquete de pruebas fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
