---
module_id: "cog-015-transport-alert-precision-only-with-prevalence"
department: "cognitive-science"
course: "Transferir la precisión de alertas solo junto con la prevalencia"
level: "intermediate"
prerequisites: ["cog-012-separate-review-alert-hit-rate-from-response-bias"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Transferir la precisión de alertas solo junto con la prevalencia

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un asistente de revisión se evalúa con muchos defectos y después se aplica a fuentes de Learn mayormente correctas. Su precisión puede cambiar aunque conserve la tasa de detección y la de falsas alarmas. El curso previo distingue esas tasas condicionales; este reconstruye la mezcla que encontraría el usuario.

Google define la precisión como verdaderos positivos divididos entre todas las alertas. Para prever ese denominador, separe primero la población construida en elementos defectuosos y correctos y aplique la tasa correspondiente a cada grupo. Los recuentos resultantes son esperanzas del modelo, no una matriz observada nueva.

Suponer que ambas tasas permanecen fijas es una premisa sustancial. Nuevos defectos, revisores, umbrales o formatos pueden invalidarla. Calcular bien no demuestra transferibilidad. Un DSL de evidencia debe conservar por separado la prevalencia, las tasas y su procedencia. Copiar la precisión de un ejercicio equilibrado importaría su mezcla de tareas de forma implícita.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: cog-012-separate-review-alert-hit-rate-from-response-bias](../../cognitive-science/en/cog-012-separate-review-alert-hit-rate-from-response-bias.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://developers.google.com/machine-learning/crash-course/classification/accuracy-precision-recall)

## Modelo fijo y control

```json
{
  "values": {
    "items": 1000,
    "prevalence": 0.1,
    "hit_rate": 0.8,
    "false_alarm_rate": 0.1
  },
  "formula": "TP=N*pi*hit; FP=N*(1-pi)*false_alarm; precision=TP/(TP+FP); counts are expected counts under stipulated rates.",
  "expected": {
    "true_positives": 80,
    "false_positives": 90,
    "alerts": 170,
    "precision": 0.47058823529411764
  },
  "negative_control": {
    "values": {
      "items": 1000,
      "prevalence": 0.5,
      "hit_rate": 0.8,
      "false_alarm_rate": 0.1
    },
    "expected": {
      "true_positives": 400,
      "false_positives": 50,
      "alerts": 450,
      "precision": 0.8888888888888888
    },
    "why": "Class-conditional rates stay fixed while prevalence changes the composition of alerts."
  },
  "assumptions": [
    "Same fixed threshold and class-conditional response rates in both populations.",
    "Prevalence stipulated; expected counts happen to be integers."
  ],
  "limits": "No observed review behavior or evidence that class-conditional rates actually transport.",
  "input_types": {
    "items": "positive integer",
    "prevalence": "real in [0,1]",
    "hit_rate": "real in [0,1]",
    "false_alarm_rate": "real in [0,1]"
  }
}
```

### Ejercicio 1

Calcule las alertas esperadas.

<details><summary>Respuesta 1</summary>

Hay `80` verdaderos positivos y `90` falsos positivos, para `170` alertas. Cada tasa usa su propio denominador de clase real.

</details>

### Ejercicio 2

Calcule la precisión del caso fijo.

<details><summary>Respuesta 2</summary>

`80/170=0.47058823529411764`. La precisión describe la composición de las alertas, no la fracción de defectos detectados.

</details>

### Ejercicio 3

Aplique el control con mayor prevalencia.

<details><summary>Respuesta 3</summary>

Se esperan `400` verdaderos positivos y `50` falsos positivos, para `450` alertas; la precisión es `0.8888888888888888`.

</details>

### Ejercicio 4

¿Mejoraron las tasas condicionales del revisor?

<details><summary>Respuesta 4</summary>

No. Las tasas permanecen fijas y cambia la mezcla. Llamarlo mejora de habilidad atribuiría mal el resultado construido.

</details>

### Ejercicio 5

¿Qué invalidaría la estimación transferida?

<details><summary>Respuesta 5</summary>

Un cambio de umbral o de comportamiento condicional. Hacen falta datos reales; la definición de una métrica no aporta esas tasas.

</details>

## Tarea con consulta de fuentes

Redacte un resumen de alertas con prevalencia para una revisión ficticia de Learn.

**Referencia manual directa:** Construya filas separadas de elementos defectuosos y correctos antes de calcular las alertas.

**Criterio de refutación:** Se copia la precisión entre poblaciones sin reconstruir la mezcla de clases.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
