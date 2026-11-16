---
title: Limitar la admisión con un depósito de tokens
description: Limitar la admisión con un depósito de tokens — Cibernética
sidebar:
  label: CYB-009 · Limitar la admisión con un depósito de tokens
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/es/cyb-009-bound-admission-with-a-token-bucket.es.md
---

:::note[Streeling University]
**CYB-009** · Limitar la admisión con un depósito de tokens · intermedio · 45 minutos

Generado por el departamento *Cibernética* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/es/cyb-009-bound-admission-with-a-token-bucket.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CYB-006](../../cybernetics/cyb-006-bound-retry-feedback-and-workload/)
:::

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [cyb-006-bound-retry-feedback-and-workload.md](../../cybernetics/cyb-006-bound-retry-feedback-and-workload/)
- [dag.rs](https://raw.githubusercontent.com/GuitarAlchemist/ix/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-pipeline/src/dag.rs)
- [rfc2697.html](https://www.rfc-editor.org/rfc/rfc2697.html)

Un coordinador de IX puede identificar correctamente el trabajo listo y aun así admitir demasiado durante una ráfaga. El requisito previo sobre reintentos cuenta el trabajo adicional ofrecido; no define un limitador de ráfagas. Aquí, un depósito de tokens elaborado proporciona una regla de admisión calculable en papel. Controla eventos de admisión; una regla independiente de plazas controlaría la ejecución simultánea. Ninguna sustituye a la otra.

El RFC describe depósitos de tokens para medir paquetes mediante capacidades y una tasa de reposición. Tomamos esa contabilidad, no su especificación completa de marcado de paquetes. Nuestros tokens representan permiso para admitir una tarea didáctica de coste unitario. El código del grafo de IX aporta dependencias; no demuestra que este depósito esté instalado. Por tanto, un nodo puede estar listo según sus dependencias y ser rechazado por este modelo independiente.

Comience con el depósito lleno y procese las llegadas en el orden declarado, incluidas las simultáneas. Reponga solo según el tiempo transcurrido desde la llegada anterior y limite el saldo a la capacidad. Una tarea admitida consume su coste; una rechazada no consume tokens ni pasa a un estado imaginario de finalización. Procesar secuencialmente las entradas de una ráfaga simultánea no genera tiempo para recargar. Hay que declarar el significado del reloj y el orden de los eventos.

La traza conserva las llegadas rechazadas. Eliminarlas ocultaría la demanda ofrecida y haría parecer más generoso el limitador. Nuestro modelo no define una cola: rechazado significa rechazado en esa llegada. Encolar tareas rechazadas necesita reglas de propiedad, caducidad, reintento y cancelación. Cambiar la capacidad también modifica el permiso de ráfaga aunque la tasa de reposición permanezca constante.

El control negativo desactiva la reposición para separar el crédito inicial del posterior. Para la tarea asistida por fuentes, compare las unidades de capacidad y tasa del RFC con las unidades de tareas de esta lección y anote la diferencia en un registro manual. Examine después la consulta de predecesores de IX para identificar por separado la disponibilidad del grafo. Rechace propuestas que confundan tokens con plazas de trabajo medidas, repongan entre llegadas simultáneas o presenten esta traza elaborada como una flota activa.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "capacity_tokens": 3,
    "refill_tokens_per_second": 1,
    "cost_per_job": 1,
    "arrivals_seconds": [
      0,
      0,
      0,
      0,
      1,
      1,
      2
    ]
  },
  "formula": "available=min(capacity, previous_tokens+rate*elapsed); admit iff available>=cost; debit only on admission",
  "expected": {
    "admitted": [
      true,
      true,
      true,
      false,
      true,
      false,
      true
    ],
    "remaining": [
      2,
      1,
      0,
      0,
      0,
      0,
      0
    ],
    "admissions": 5,
    "denials": 2
  },
  "negative_control": "With refill zero only the initial burst of three is admitted.",
  "assumptions": [
    "Chronological arrivals, initial bucket full, unit job cost, exact seconds, no refund."
  ],
  "limits": "Authored job-admission model; not RFC2697 packet coloring or production IX scheduling."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Indique las decisiones de admisión.

<details>
<summary>Respuesta 1</summary>

`[true,true,true,false,true,false,true]`; `5` admisiones y `2` rechazos.

</details>

### Ejercicio 2

Indique los saldos restantes.

<details>
<summary>Respuesta 2</summary>

`[2,1,0,0,0,0,0]`; las llegadas simultáneas no añaden tiempo transcurrido.

</details>

### Ejercicio 3

Evalúe el control sin reposición.

<details>
<summary>Respuesta 3</summary>

Solo `3` admisiones; las llegadas posteriores no reciben crédito.

</details>

### Ejercicio 4

¿La admisión limita las tareas simultáneas?

<details>
<summary>Respuesta 4</summary>

No sin duraciones y una regla de plazas; los tokens contabilizan crédito de admisión.

</details>

### Ejercicio 5

¿Qué debe añadir una variante con cola?

<details>
<summary>Respuesta 5</summary>

Reglas explícitas de espera, propiedad, caducidad y reintento; no se aporta medición de capacidad real.

</details>

[Paquete de pruebas fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
