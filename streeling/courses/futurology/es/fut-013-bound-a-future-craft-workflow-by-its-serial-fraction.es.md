---
module_id: "fut-013-bound-a-future-craft-workflow-by-its-serial-fraction"
department: "futurology"
course: "Acotar un futuro flujo artesanal por su fracción secuencial"
level: "advanced"
prerequisites: ["fut-008-stress-test-a-release-plan-against-review-backlogs", "pm-011-include-review-and-correction-in-automation-break-even"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Acotar un futuro flujo artesanal por su fracción secuencial

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Una propuesta añade workers a un generador artesanal y predice ganancias proporcionales. Parte del trabajo puede seguir siendo secuencial: una exportación ordenada o una inspección indivisible no se acorta simplemente añadiendo generadores. Los prerrequisitos de cola y rentabilidad tratan otras preguntas. Esta lección acota la aceleración ideal de trabajo fijo antes de pronosticar ventajas de automatización futura.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Divida el tiempo transcurrido con un worker según tiempo de ejecución, no según líneas de código. Mantenga la parte secuencial y divida solo la paralela entre los workers. [LLNL](https://hpc.llnl.gov/documentation/tutorials/introduction-parallel-computing-tutorial) presenta el modelo de Amdahl y distingue tamaño fijo de carga creciente. El pipeline ejecuta etapas ordenadas, sin aportar la descomposición temporal de este ejemplo. La división perfecta es optimista; coordinación, contención y cambios de aceptación pueden ralentizar el flujo real o invalidar la partición.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "baseline_minutes": 28,
    "serial_fraction": 0.25,
    "workers": 4
  },
  "formula": "serial_minutes=T*s; parallel_minutes=T*(1-s)/workers; ideal_minutes=serial_minutes+parallel_minutes; speedup=T/ideal_minutes; asymptotic_speedup=1/s",
  "expected": {
    "serial_minutes": 7,
    "parallel_minutes": 5.25,
    "ideal_minutes": 12.25,
    "speedup": 2.2857142857142856,
    "asymptotic_speedup": 4
  },
  "negative_control": {
    "values": {
      "baseline_minutes": 28,
      "serial_fraction": 0.6,
      "workers": 4
    },
    "expected": {
      "serial_minutes": 16.8,
      "parallel_minutes": 2.8,
      "ideal_minutes": 19.6,
      "speedup": 1.4285714285714286,
      "asymptotic_speedup": 1.6666666666666667
    }
  }
}
```

### Ejercicio 1

Descomponga el caso principal.

<details><summary>Respuesta 1</summary>

El trabajo secuencial ocupa `7` minutos y la parte paralela dividida `5.25` minutos. El total ideal es `12.25` minutos.

</details>

### Ejercicio 2

Calcule la aceleración con los workers previstos.

<details><summary>Respuesta 2</summary>

Es `2.2857142857142856`, no el número de workers. El trabajo secuencial sigue en la ruta de finalización.

</details>

### Ejercicio 3

Obtenga el techo límite.

<details><summary>Respuesta 3</summary>

La aceleración asintótica es `4`. Es un límite del modelo declarado, no una capacidad futura medida.

</details>

### Ejercicio 4

Aplique la fracción secuencial mayor.

<details><summary>Respuesta 4</summary>

Las componentes son `16.8` y `2.8` minutos, total `19.6`, aceleración `1.4285714285714286` y techo `1.6666666666666667`.

</details>

### Ejercicio 5

¿Sustituye esto los modelos de cola o coste?

<details><summary>Respuesta 5</summary>

No. La aceleración de trabajo fijo no determina llegadas, aceptación, coste inicial ni correcciones. Una comparación real debe conservar el alcance de la tarea y medir los tiempos pertinentes.

</details>

## Tarea con consulta de fuentes

Dibuje a mano una barra de tiempo secuencial y paralelo y compare el resultado finito con el techo. Inspeccione el orden del pipeline sin tratarlo como perfil temporal. Declare qué medida podría refutar la fracción supuesta antes de pedir más capacidad.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

El denominador finito refuta la ganancia proporcional con una fracción secuencial positiva estipulada; medir un trabajo diferente cuestionaría en cambio las premisas del modelo.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: fut-008-stress-test-a-release-plan-against-review-backlogs](../../futurology/en/fut-008-stress-test-a-release-plan-against-review-backlogs.md)

- [Prerrequisito ya confirmado: pm-011-include-review-and-correction-in-automation-break-even](../../product-management/en/pm-011-include-review-and-correction-in-automation-break-even.md)

- [Fuente de proyecto conservada](../../../../code/blender/scripts/glb_pipeline.py)

- [Lectura primaria](https://hpc.llnl.gov/documentation/tutorials/introduction-parallel-computing-tutorial)

- [Paquete inventado fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
