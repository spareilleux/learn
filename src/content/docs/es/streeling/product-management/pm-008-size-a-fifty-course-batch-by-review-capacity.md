---
title: Dimensionar un lote de cincuenta cursos según la capacidad de revisión
description: Dimensionar un lote de cincuenta cursos según la capacidad de revisión — Gestión de productos y proyectos
sidebar:
  label: PM-008 · Dimensionar un lote de cincuenta cursos según la capacidad de revisión
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/es/pm-008-size-a-fifty-course-batch-by-review-capacity.es.md
---

:::note[Streeling University]
**PM-008** · Dimensionar un lote de cincuenta cursos según la capacidad de revisión · intermedio · 45 minutos

Generado por el departamento *Gestión de productos y proyectos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/es/pm-008-size-a-fifty-course-batch-by-review-capacity.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PM-003](../../product-management/pm-003-review-queue-flow-metrics/)
:::

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [pm-003-review-queue-flow-metrics.md](../../product-management/pm-003-review-queue-flow-metrics/)
- [pm-002-release-evidence-gate.md](../../product-management/pm-002-release-evidence-gate/)
- [production-plan.md](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/production-plan.md)
- [batch-plan.json](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/batch-plan.json)

La solicitud actual especifica un lote de cursos distintos; las traducciones añaden fuentes, no cursos. ¿Cuánta revisión exigiría ese alcance? El requisito previo sobre flujo de colas explica por qué el inventario no es rendimiento. Esta lección utiliza el tamaño realmente solicitado y minutos de revisión explícitamente ficticios para mostrar qué función limitaría un calendario. El número de agentes redactores no mide disponibilidad humana.

Lea el plan de producción y el manifiesto como autoridad del alcance. En este escenario didáctico, cuente revisión técnica por curso inglés, revisión lingüística por fuente traducida y trabajo de aprendiz por curso. La carga lingüística excluye la revisión técnica del idioma fuente, ya contabilizada. Son supuestos de planificación, no afirmaciones de que todos los cursos requieran igual tiempo ni de que un intento baste para aceptar el aprendizaje.

Multiplique el alcance por el tiempo unitario antes de dividir entre capacidad. Mantenga visibles minutos, fuentes, cursos y días. Sumar todos los minutos de revisión oculta especialidades: el tiempo lingüístico libre no realiza automáticamente el trabajo técnico o de aprendices. La finalización paralela optimista es la mayor duración por función, con disponibilidad simultánea y trabajo divisible. Dependencias, calendarios parciales, revisiones fallidas y nuevos intentos exigirían un escenario más detallado; no se midieron aquí.

El paquete también cuenta pares de ejercicio-respuesta localizados y criterios preparados para aprendices. Son obligaciones de autoría e inspección, no observaciones completadas. Un criterio sigue indeciso hasta disponer de una respuesta real y su historial de asistencia. Producir fuentes más deprisa no autoriza a afirmar que los cursos fueron revisados. Conserve hallazgos y retrabajo en vez de borrar controles fallidos para presentar el rendimiento previsto como logrado.

Para la tarea asistida por fuentes, reconcilie a mano los recuentos de módulos e idiomas del manifiesto y construya la tabla de cargas con las tasas estipuladas. Pida a un asistente que encuentre cuellos de botella y mediciones ausentes. La referencia directa es esa tabla, sin DSL de planificación. El control de capacidad nula debe impedir una promesa finita para la función requerida. Rechace anuncios que traten estos minutos ficticios como capacidad observada o cuenten traducciones como cursos distintos.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "courses": 50,
    "locales": 3,
    "translated_sources": 100,
    "exercises_per_course": 5,
    "subject_minutes_per_course": 20,
    "language_minutes_per_translation": 12,
    "learner_minutes_per_course": 25,
    "subject_minutes_per_day": 100,
    "language_minutes_per_day": 200,
    "learner_minutes_per_day": 125
  },
  "formula": "role_work=scope*minutes_per_item; role_days=role_work/role_capacity; optimistic_parallel_days=max(role_days)",
  "expected": {
    "sources": 150,
    "localized_answer_pairs": 750,
    "prepared_learner_criteria": 250,
    "subject_minutes": 1000,
    "language_minutes": 1200,
    "learner_minutes": 1250,
    "total_minutes": 3450,
    "subject_days": 10,
    "language_days": 6,
    "learner_days": 10,
    "optimistic_parallel_days": 10
  },
  "negative_control": "Zero capacity in any required role admits no finite completion estimate for its positive work.",
  "assumptions": [
    "Actual requested fifty-course scope; all durations/capacities fictional, dedicated roles, divisible work, parallel availability, no rework or waiting."
  ],
  "limits": "Capacity planning scenario, not a deadline, measured team rate, completed review or learner result."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Cuente fuentes, pares localizados y criterios preparados.

<details>
<summary>Respuesta 1</summary>

`50*3=150` fuentes; `50*3*5=750` pares; `50*5=250` criterios.

</details>

### Ejercicio 2

Calcule las cargas por función.

<details>
<summary>Respuesta 2</summary>

Técnica `50*20=1000`, idiomas `100*12=1200`, aprendiz `50*25=1250` minutos; total `3450`.

</details>

### Ejercicio 3

Calcule las duraciones y la cota paralela.

<details>
<summary>Respuesta 3</summary>

Técnica `10`, idiomas `6`, aprendiz `10` días; cota paralela optimista `10` días.

</details>

### Ejercicio 4

Evalúe una función requerida sin capacidad.

<details>
<summary>Respuesta 4</summary>

El trabajo positivo requerido no tiene finalización finita estimable; no divida entre cero ni lo dé por completo.

</details>

### Ejercicio 5

¿Qué datos son reales y cuáles ficticios?

<details>
<summary>Respuesta 5</summary>

El alcance solicitado es real; tiempos, capacidades y escenario de calendario son elaborados.

</details>

[Paquete de pruebas fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
