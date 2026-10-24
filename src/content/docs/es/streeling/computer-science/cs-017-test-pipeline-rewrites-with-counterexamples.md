---
title: Probar reescrituras de pipelines con contraejemplos
description: Probar reescrituras de pipelines con contraejemplos — Ciencias de la computación
sidebar:
  label: CS-017 · Probar reescrituras de pipelines con contraejemplos
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-017-test-pipeline-rewrites-with-counterexamples.es.md
---

:::note[Streeling University]
**CS-017** · Probar reescrituras de pipelines con contraejemplos · intermedio · 45 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-017-test-pipeline-rewrites-with-counterexamples.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-010](../../computer-science/cs-010-compose-fail-fast-ga-computations/)
:::

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [cs-010-compose-fail-fast-ga-computations.md](../../computer-science/cs-010-compose-fail-fast-ga-computations/)
- [GaAsync.fs](https://raw.githubusercontent.com/GuitarAlchemist/ga/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs)

Una limpieza propuesta del pipeline GA fusiona etapas y desplaza la validación para reducir repeticiones. El código puede acortarse y, a la vez, aceptar una entrada antes rechazada. El requisito previo explica la composición dependiente y la reasociación. Esta lección exige algo distinto: conservar un testigo que pueda refutar la reescritura antes de cambiar la implementación. Las etapas aritméticas son funciones elaboradas, no una nueva API de GA.

La composición de GA fijada distingue éxito y error, y omite la función siguiente tras un error. Lea esa rama del código real. Describe una frontera de control que una reescritura informal podría atravesar. Reasociar conserva el orden de las funciones dependientes. Intercambiarlas cambia el cálculo. Desplazar una condición cambia el valor que examina. Son transformaciones diferentes que necesitan argumentos propios, aunque se representen mediante la misma notación.

El modelo utiliza enteros exactos para que el redondeo no explique una discrepancia. Aplique ambos órdenes a cada entrada y conserve en papel los valores intermedios. Los vectores resultantes difieren en todas las posiciones indicadas. Basta para refutar la equivalencia en este modelo, pero no determina qué orden pretendía la especificación del producto. La corrección sigue necesitando el comportamiento requerido por el consumidor y una interpretación válida de la entrada.

El testigo de frontera es especialmente útil. La validación original comprueba el valor inicial; la propuesta lo comprueba después del incremento. Una entrada rechazada puede aceptarse sin que exista error aritmético. Una demostración con una entrada claramente positiva no detectaría el cambio. El control negativo deja intacto el pipeline: si la comparación le atribuye una diferencia, el procedimiento de comparación está roto.

Para la tarea asistida por fuentes, anote la explicación de asociatividad del requisito previo y la bifurcación real de composición. Exprese la reescritura mediante dos tablas de entradas y salidas, sin inventar un DSL. Pida después un contraejemplo a un asistente, conservando primero su cálculo manual. La propuesta falla si cambia un resultado permitido, una categoría de fallo o un orden requerido. Una tabla finita satisfactoria sigue siendo una comprobación limitada; los efectos, la cancelación, los tiempos y todos los enteros requieren razonamiento adicional.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "inputs": [
      -2,
      0,
      2
    ],
    "f": "x+1",
    "g": "2*x",
    "guard": "x>0"
  },
  "formula": "original=g(f(x)); swapped=f(g(x)); validation-before versus validation-after",
  "expected": {
    "original": [
      -2,
      2,
      6
    ],
    "swapped": [
      -3,
      1,
      5
    ],
    "guard_witness": 0,
    "before": "reject",
    "after": "accept"
  },
  "negative_control": "Identity rewrite must agree for every supplied witness.",
  "assumptions": [
    "Exact integer arithmetic, no effects, guard evaluates its stated input."
  ],
  "limits": "A finite witness set can refute equality but agreement is not a universal proof."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Calcule el vector original.

<details>
<summary>Respuesta 1</summary>

`[-2,2,6]` mediante `2*(x+1)`.

</details>

### Ejercicio 2

Calcule el vector intercambiado.

<details>
<summary>Respuesta 2</summary>

`[-3,1,5]` mediante `2*x+1`; la reescritura queda refutada.

</details>

### Ejercicio 3

Aplique la condición al testigo fronterizo.

<details>
<summary>Respuesta 3</summary>

Con `x=0`, validar antes del incremento rechaza; después acepta `1`.

</details>

### Ejercicio 4

¿Qué debe indicar el control idéntico?

<details>
<summary>Respuesta 4</summary>

Resultados iguales para cada entrada; una diferencia invalida el comprobador.

</details>

### Ejercicio 5

¿Coincidir en estas entradas demuestra una ley?

<details>
<summary>Respuesta 5</summary>

No. Un contraejemplo refuta una afirmación universal; una coincidencia finita no la demuestra.

</details>

[Paquete de pruebas fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
