---
module_id: "pm-009-separate-release-adoption-from-artifact-downloads"
department: "product-management"
course: "Separar la adopción de una versión de las descargas"
title: "Separar la adopción de una versión de las descargas"
level: "intermediate"
prerequisites: ["pm-002-release-evidence-gate", "pm-006-test-a-pilot-against-its-decision-horizon"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Separar la adopción de una versión de las descargas

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [pm-002-release-evidence-gate.md](../../product-management/en/pm-002-release-evidence-gate.md)
- [pm-006-test-a-pilot-against-its-decision-horizon.md](../../product-management/en/pm-006-test-a-pilot-against-its-decision-horizon.md)

Un artefacto de versión recibe muchas descargas y un agente anuncia adopción amplia. Las descargas pueden incluir reintentos, automatización, espejos y personas ajenas a la cohorte objetivo. Un control de versión indica si el artefacto está listo o accesible; no aporta un denominador de uso. El requisito previo del horizonte pregunta qué decisiones reutilizan pruebas. Aquí se define qué personas y acciones pertenecen a la adopción.

El paquete ofrece recuentos ficticios de eventos y usuarios en una ventana fija. La cohorte activa elegible se define por separado de quienes descargaron. Los usuarios que habilitan la versión pertenecen a esa cohorte; los intentos pertenecen al subconjunto habilitado, y los éxitos a los intentos. Esas inclusiones permiten las razones indicadas. No se declara que quienes descargaron sean la cohorte, por lo que sustituir el denominador cambiaría la pregunta.

Adopción significa aquí habilitar la versión dentro de la cohorte activa elegible. Es un criterio didáctico, no una definición universal. Informe por separado de cobertura de intentos y éxito observado. Una función puede habilitarse y no usarse; una tarea exitosa no demuestra uso sostenido ni aprendizaje. Elegir después un criterio más estricto necesita otro numerador y una frontera de comparación explícita.

La razón descargas/cohorte se puede calcular, pero sus unidades son eventos por miembro. No representa una fracción de usuarios que adoptaron, porque los eventos pueden repetirse y proceder de fuera. Incluso las personas distintas que descargaron pueden superar la cohorte elegible. El panel debe conservar unidades de eventos y personas, en vez de limitar un porcentaje absurdo y dar por resuelto el problema.

El control negativo aumenta las descargas de espejos manteniendo fijas las acciones de la cohorte. Las razones de adopción y tareas deben permanecer iguales. Para la tarea asistida por fuentes, examine las distinciones de la lección sobre controles y redacte una ficha con versión, cohorte, ventana, unidad de evento y resultado. Calcule las razones a mano antes de pedir una frase de estado a un asistente. Rechácela si equipara acceso público con uso o afirma telemetría real a partir de estos recuentos elaborados.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "download_events": 120,
    "distinct_downloaders": 70,
    "eligible_active_cohort": 50,
    "enabled_in_cohort": 30,
    "task_attempted_in_enabled_cohort": 18,
    "task_success_in_attempted": 12
  },
  "formula": "adoption=enabled_in_cohort/eligible_active_cohort; attempted_coverage=attempted/enabled; observed_task_success=success/attempted",
  "expected": {
    "adoption": 0.6,
    "attempted_coverage": 0.6,
    "task_success_fraction": "2/3",
    "cohort_task_success_rate": 0.24,
    "downloads_per_cohort_member": 2.4
  },
  "negative_control": "A mirrored artifact can have more download events without any change in the eligible cohort or enabled users.",
  "assumptions": [
    "Fictional counts in one fixed window, stable release and cohort identity, nested enabled/attempted/success sets, downloader set not identical to eligible cohort."
  ],
  "limits": "No real telemetry, causal benefit, retention, sustained adoption or user-learning improvement was measured."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Calcule la tasa de adopción definida.

<details>
<summary>Respuesta 1</summary>

`30/50=0.6` dentro de la cohorte activa elegible.

</details>

### Ejercicio 2

Calcule la cobertura de intentos.

<details>
<summary>Respuesta 2</summary>

`18/30=0.6` entre los miembros que habilitaron la versión.

</details>

### Ejercicio 3

Calcule el éxito con ambos denominadores.

<details>
<summary>Respuesta 3</summary>

Entre intentos `12/18=2/3`; en toda la cohorte `12/50=0.24`.

</details>

### Ejercicio 4

Interprete descargas divididas entre tamaño de cohorte.

<details>
<summary>Respuesta 4</summary>

`120/50=2.4` eventos por miembro; no es una fracción de adopción.

</details>

### Ejercicio 5

Evalúe el control de descargas de espejos.

<details>
<summary>Respuesta 5</summary>

Las razones permanecen iguales porque todos los numeradores y denominadores de la cohorte siguen fijos.

</details>

[Paquete de pruebas fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
