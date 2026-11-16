---
module_id: "cyb-010-separate-derivative-noise-from-plant-motion"
department: "cybernetics"
course: "Separar el ruido de derivación del movimiento del sistema"
title: "Separar el ruido de derivación del movimiento del sistema"
level: "intermediate"
prerequisites: ["cyb-008-check-convergence-before-repeating-a-correction"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Separar el ruido de derivación del movimiento del sistema

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [cyb-008-check-convergence-before-repeating-a-correction.md](../../cybernetics/en/cyb-008-check-convergence-before-repeating-a-correction.md)
- [discretepidcontroller.html](https://www.mathworks.com/help/simulink/slref/discretepidcontroller.html)

Un agente observa un cambio brusco en un panel y propone una corrección intensa. ¿Se mueve el sistema o fluctúa la medición? El requisito previo de convergencia estudia residuos exactos. Aquí, la posición real permanece constante mientras una perturbación declarada entra en una estimación de derivada. El ejemplo comprueba unidades y sensibilidad; no representa un servicio GA medido.

La documentación primaria del controlador describe una contribución derivativa y un filtro. Nuestras ecuaciones de diferencia finita y suavizado se declaran por separado; no reproducen todas las opciones de ese producto. Las unidades de posición divididas entre segundos dan unidades de posición por segundo. La ganancia derivativa necesitaría unidades compatibles antes de contribuir a una orden del actuador. Llamar corrección a un número no aporta ese contrato dimensional.

Calcule los cambios medidos antes de dividirlos entre el intervalo de muestreo. El movimiento aparente alterna aunque el sistema supuesto nunca se mueve. La recurrencia de suavizado parte del valor inicial declarado y retiene parte de su estado anterior. Sus salidas no se pueden comparar con un promedio recién inicializado. Conservar la inicialización es esencial cuando un agente reinicia un análisis o compara trazas cortas.

Reducir el intervalo a la mitad manteniendo los mismos saltos de medición duplica las diferencias finitas. Es una propiedad de esta entrada elaborada, no una descripción universal del ruido del sensor con muestreo más rápido. Una rampa real, un sensor retrasado y picos aislados podrían requerir análisis distintos. El suavizado también puede retrasar un cambio real: una menor fluctuación visible no demuestra mejor control ni atribución correcta.

Para la tarea asistida por fuentes, localice la descripción del filtro derivativo en la documentación primaria y contrástela con la ecuación exacta del requisito previo. Calcule a mano las trazas bruta y filtrada, conservando el control de entrada constante. Pida a un asistente que separe el movimiento real supuesto de los valores medidos. Rechace explicaciones que deduzcan una respuesta física de esta perturbación o usen una curva más tranquila como prueba de estabilidad.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "dt_seconds": 0.1,
    "true_position": [
      10,
      10,
      10
    ],
    "measurement": [
      10,
      10.2,
      10
    ],
    "gain": 1,
    "filter_alpha": 0.5,
    "filter_initial": 0
  },
  "formula": "d[k]=(y[k]-y[k-1])/dt; z[k]=alpha*d[k]+(1-alpha)*z[k-1]",
  "expected": {
    "true_derivative": [
      0,
      0
    ],
    "raw_derivative": [
      2,
      -2
    ],
    "filtered_derivative": [
      1,
      -0.5
    ],
    "half_dt_raw": [
      4,
      -4
    ]
  },
  "negative_control": "A constant measured sequence gives zero raw and filtered derivatives.",
  "assumptions": [
    "Uniform sample intervals, fixed position units, no plant motion, stipulated perturbation, no missing samples."
  ],
  "limits": "No physical sensor, GA controller or noise distribution was measured; smoothing does not establish closed-loop stability."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Calcule la derivada bruta.

<details>
<summary>Respuesta 1</summary>

`[2,-2]` unidades de posición por segundo; la derivada real es `[0,0]`.

</details>

### Ejercicio 2

Calcule la secuencia filtrada.

<details>
<summary>Respuesta 2</summary>

`[1,-0.5]` con el estado inicial y la recurrencia declarados.

</details>

### Ejercicio 3

Reduzca a la mitad el intervalo de muestreo.

<details>
<summary>Respuesta 3</summary>

Con `dt=0.05`, los mismos saltos producen `[4,-4]`.

</details>

### Ejercicio 4

Evalúe el control de entrada constante.

<details>
<summary>Respuesta 4</summary>

Ambas trazas permanecen nulas; una salida distinta contradice la recurrencia o su inicialización.

</details>

### Ejercicio 5

¿El suavizado demuestra mejor control?

<details>
<summary>Respuesta 5</summary>

No. La atribución del movimiento, el retraso, el actuador y la estabilidad siguen sin probarse.

</details>

[Paquete de pruebas fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
