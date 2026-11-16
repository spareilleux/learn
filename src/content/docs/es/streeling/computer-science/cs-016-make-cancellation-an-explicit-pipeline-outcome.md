---
title: Convertir la cancelación en un resultado explícito del pipeline
description: Convertir la cancelación en un resultado explícito del pipeline — Ciencias de la computación
sidebar:
  label: CS-016 · Convertir la cancelación en un resultado explícito del pipeline
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-016-make-cancellation-an-explicit-pipeline-outcome.es.md
---

:::note[Streeling University]
**CS-016** · Convertir la cancelación en un resultado explícito del pipeline · intermedio · 45 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-016-make-cancellation-an-explicit-pipeline-outcome.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-011](../../computer-science/cs-011-preserve-absence-and-failure-boundaries/)
:::

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [cs-011-preserve-absence-and-failure-boundaries.md](../../computer-science/cs-011-preserve-absence-and-failure-boundaries/)
- [GaAsync.fs](https://raw.githubusercontent.com/GuitarAlchemist/ga/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs)
- [cancellation-in-managed-threads](https://learn.microsoft.com/dotnet/standard/threading/cancellation-in-managed-threads)

Un coordinador solicita detener un pipeline de análisis de audio y recibe una respuesta satisfactoria a la petición de cancelación. ¿Se han detenido todas las ramas y puede borrarse su archivo de salida? Hacen falta observaciones de cada rama. La unión de errores de GA fijada contiene un caso de cancelación, pero su existencia no indica dónde atiende cada operación la solicitud. El requisito previo deja abierta la seguridad de la cancelación; esta lección ofrece un pequeño modelo de auditoría sin atribuirle una ejecución.

La documentación de Microsoft describe una solicitud cooperativa y un receptor que debe responder. Lea ese mecanismo introductorio y separe el recibo de la solicitud de las pruebas terminales. En nuestro registro elaborado, todos los intentos nombrados reciben una solicitud. Uno confirma su cancelación antes de producir efectos, otro termina y registra una escritura, y el último carece de observación terminal. Los recuentos del paquete se derivan exactamente de esos datos. No son mediciones de un servicio GA.

La identidad del intento importa: una confirmación tardía podría atribuirse por error a un intento sustituto. La marca temporal ayuda a localizar el evento, pero no reemplaza esa identidad. Conserve el evento que registra un efecto aunque una solicitud posterior pida detener el trabajo. Cancelar no compensa por sí solo una escritura terminada. Cualquier borrado o reversión necesita su propia autoridad, modelo de efectos y pruebas. Un estado deseado no sustituye a uno observado.

El control negativo es un registro con solicitudes y sin confirmaciones. Un informe que lo clasifique como cancelado está deduciendo el resultado de su propia orden. Nuestro informe debe conservar el estado desconocido. Ese estado también difiere del fallo: puede indicar una respuesta tardía, un recibo ausente o una observación perdida. Reintentar podría producir otro efecto mientras el intento original sigue activo; esta categoría no basta para recomendar una repetición.

Para la tarea real asistida por fuentes, lea la unión de errores, la envoltura asíncrona y la composición dependiente del archivo GA fijado. Identifique las líneas sobre errores devueltos y las pruebas adicionales necesarias para un contrato terminal de cancelación. Use una tabla manual de eventos como referencia. Pida a un asistente que clasifique el mismo registro y cite su alcance de lectura. Rechace su respuesta si convierte una solicitud de parada en garantía de reversión o afirma haber realizado una prueba de cancelación inexistente en este ejercicio.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "requested": [
      "A",
      "B",
      "C"
    ],
    "acknowledged_cancelled": [
      "A"
    ],
    "completed": [
      "B"
    ],
    "unknown": [
      "C"
    ],
    "B_effect": "written"
  },
  "formula": "requested set partitions by observed terminal evidence, not by request count",
  "expected": {
    "requests": 3,
    "cancelled": 1,
    "completed": 1,
    "unknown": 1,
    "safe_to_claim_all_cancelled": false
  },
  "negative_control": "A request-only record has no acknowledged cancellation.",
  "assumptions": [
    "A terminal acknowledgment refers to the same attempt identity; effects are independently recorded."
  ],
  "limits": "No GA cancellation delivery, rollback or distributed stop was executed."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Cuente las solicitudes y las categorías terminales.

<details>
<summary>Respuesta 1</summary>

`3` solicitudes; `1` cancelada, `1` terminada, `1` desconocida.

</details>

### Ejercicio 2

¿Puede declararse revertido B?

<details>
<summary>Respuesta 2</summary>

No. B tiene escritura y finalización registradas; no existe recibo de compensación.

</details>

### Ejercicio 3

¿Qué demuestra el control de solo solicitudes?

<details>
<summary>Respuesta 3</summary>

Solo se enviaron solicitudes; todos los resultados terminales siguen siendo desconocidos.

</details>

### Ejercicio 4

¿Por qué conservar la identidad del intento?

<details>
<summary>Respuesta 4</summary>

Para evitar atribuir una confirmación tardía a un intento sustituto.

</details>

### Ejercicio 5

¿La unión de errores demuestra la entrega cooperativa?

<details>
<summary>Respuesta 5</summary>

No. Un caso representable no es una solicitud observada, una confirmación ni una reversión.

</details>

[Paquete de pruebas fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
