---
module_id: "cyb-013-bound-observation-age-before-a-control-decision"
department: "cybernetics"
course: "Acotar la antigüedad de una observación antes de decidir el control"
level: "intermediate"
prerequisites: ["cyb-004-observe-before-correcting-a-feedback-loop", "net-008-map-clock-domains-before-ordering-events"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Acotar la antigüedad de una observación antes de decidir el control

> Esta lección utiliza un caso construido y fuentes consultadas. Los recuentos, tiempos, etiquetas y señales son entradas didácticas inventadas. La revisión técnica humana, la revisión lingüística, los intentos reales, la ejecución, la adopción en producción y la publicación siguen pendientes de decisión.

Un panel sigue mostrando un valor aparentemente aceptable mientras un agente prepara una corrección. Puede ser actual o el último muestreo exitoso. El prerrequisito de observación pregunta si existe evidencia; el de relojes pregunta si las marcas temporales son comparables. Esta lección añade una cuestión cuantitativa: cuánto pudo cambiar el valor desde la observación bajo una tasa máxima explícitamente supuesta.

El modelo considera exacta la observación en su instante y permite después cambios en ambas direcciones. Multiplicar el tiempo transcurrido por la máxima tasa absoluta proporciona un radio alrededor del valor antiguo. Es un intervalo alcanzable bajo una cota, sin predicción ajustada ni intervalo de confianza. Sus extremos son posibilidades permitidas por los supuestos, no mediciones actuales.

La decisión debe examinar todo el intervalo. Si el extremo superior supera el límite, la muestra antigua no certifica seguridad actual. Eso tampoco demuestra una infracción: sigue siendo posible una trayectoria constante. En cambio, un intervalo enteramente aceptable respalda el certificado declarado solo mientras se cumpla la cota de tasa. El asistente debe conservar esta asimetría entre desconocido e inseguro.

El registro conservado separa un resumen repetido de una observación nueva. Úselo para cuestionar un informe que renueva la fecha del documento sin renovar la observación subyacente. Un sobre componible podría incluir ambas fechas, pero primero sepárelas manualmente. El control cambia la frescura manteniendo el valor mostrado. Si una herramienta produce el mismo intervalo, descartó antigüedad relevante para decidir, sin demostrar robustez.

El bloque [BRUTAL](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs) fijado actualiza `gpuSmooth` solo en la rama de consulta exitosa. Una consulta fallida no renueva ese valor en el bloque examinado. La fuente motiva distinguir leer un valor guardado y observar una muestra nueva; no proporciona una tasa máxima medida.

## Fuentes y alcance del proyecto

Lea el prerrequisito antes de usar el modelo. Examine el artefacto conservado del proyecto en la revisión registrada en el expediente e identifique el campo o la rama que respalda la observación. La fuente aporta una representación o un comportamiento declarado; no convierte el caso inventado en un resultado observado del proyecto. La lectura primaria aporta el concepto indicado dentro de su alcance declarado.

[Prerrequisito: cyb-004-observe-before-correcting-a-feedback-loop](../../cybernetics/en/cyb-004-observe-before-correcting-a-feedback-loop.md)

[Prerrequisito: net-008-map-clock-domains-before-ordering-events](../../network-science/en/net-008-map-clock-domains-before-ordering-events.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Lectura primaria: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Lectura primaria: GA 76efbffd5af82b46c3146957a6bd4504008eeb89](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs)

## Modelo fijado y control

```json
{
  "values": {
    "now_seconds": 10,
    "observed_at_seconds": 6,
    "observed_value": 4,
    "max_change_per_second": 0.5,
    "upper_limit": 5
  },
  "formula": "age=now-observed_at; radius=max_change_per_second*age; possible current interval=[observed_value-radius,observed_value+radius]; safe iff interval upper<=upper_limit.",
  "expected": {
    "age_seconds": 4,
    "radius": 2,
    "interval": [
      2,
      6
    ],
    "safe_certified": false
  },
  "negative_control": {
    "values": {
      "now_seconds": 10,
      "observed_at_seconds": 9,
      "observed_value": 4,
      "max_change_per_second": 0.5,
      "upper_limit": 5
    },
    "expected": {
      "age_seconds": 1,
      "radius": 0.5,
      "interval": [
        3.5,
        4.5
      ],
      "safe_certified": true
    },
    "why": "Same displayed value with a younger timestamp gives a smaller worst-case interval."
  },
  "assumptions": [
    "Same monotonic clock; exact initial measurement.",
    "Absolute rate bound holds throughout the elapsed interval.",
    "Safe means at or below the authored upper limit."
  ],
  "limits": "Failure to certify is uncertainty, not observed violation. No rate bound or real sensor was measured."
}
```

### Ejercicio 1

Calcule la antigüedad y el radio máximo del caso principal.

<details><summary>Respuesta 1</summary>

La antigüedad es `4` segundos y el radio `2` unidades de valor. La tasa usa unidades de valor por segundo; al multiplicarla por segundos se obtiene una cota de desplazamiento compatible, no otra medición.

</details>

### Ejercicio 2

¿Qué intervalo actual resulta y puede certificarse seguridad?

<details><summary>Respuesta 2</summary>

El intervalo es `[2,6]`. Su extremo superior supera `5`, por lo que `safe_certified=false`. La muestra no establece el certificado bajo la tasa declarada.

</details>

### Ejercicio 3

¿La falta de certificado demuestra una infracción actual?

<details><summary>Respuesta 3</summary>

No. Se permiten tanto el camino constante en `4` como trayectorias hasta `6`. La seguridad actual queda sin resolver; no se observó una infracción ni se ordenó actuar.

</details>

### Ejercicio 4

Aplique el control con observación más reciente y compare la decisión.

<details><summary>Respuesta 4</summary>

La antigüedad pasa a `1`, el radio a `0.5` y el intervalo a `[3.5,4.5]`. Por tanto `safe_certified=true`. El mismo valor mostrado puede respaldar certificados distintos según su antigüedad.

</details>

### Ejercicio 5

¿Qué campos debe conservar un intento real de dogfooding?

<details><summary>Respuesta 5</summary>

Conserve identidad y marca temporal de la observación, momento de lectura, correspondencia de relojes, unidades y evidencia de la tasa máxima. Un resumen recién escrito no basta. No se observó ningún sensor real, validación de cota ni acción correctiva.

</details>

## Tarea con consulta de fuentes

Empiece con una tabla en papel antes de abrir las respuestas. Copie las entradas y sus unidades, aplique la operación declarada y conserve los resultados intermedios. Este cálculo directo es la referencia manual para comparar una respuesta asistida o una notación componible propuesta. Una respuesta más corta no ofrece una ventaja demostrada si pierde la identidad de una entrada, una categoría de fallo o el contraejemplo.

Después examine el pasaje concreto registrado en el expediente. Cite únicamente el pequeño campo o la rama necesarios para su explicación y registre su revisión. Tras guardar su primera respuesta, pida a un asistente que cuestione un supuesto. Conserve la instrucción, la respuesta, las correcciones aceptadas y las sugerencias rechazadas. Se permiten la consulta de fuentes y la calculadora; registre esa ayuda para no presentar el resultado como recuerdo sin asistencia.

Aplique la entrada modificada del control negativo y formule un resultado observable que refutaría su conclusión antes de recomendar cambios. Un control inesperado exige revisar el cálculo y los supuestos antes de modificar el trabajo del proyecto. Entregue conjuntamente la respuesta inicial, la corregida, el historial de ayuda y la incertidumbre restante. El expediente prepara cinco criterios, uno por ejercicio, cuyas decisiones quedan pendientes. Las soluciones y comprobaciones del autor no rellenan esas decisiones. Una futura comparación mediante dogfooding necesita intentos reales sobre la misma tarea y una referencia manual conservada; esta lección no exige implementar ningún agente o DSL nuevo.

[Expediente fijado de la unidad](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
