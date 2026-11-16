---
module_id: "net-011-separate-reachability-from-semantic-compatibility"
department: "network-science"
course: "Separar alcanzabilidad y compatibilidad semántica"
title: "Separar alcanzabilidad y compatibilidad semántica"
level: "intermediate"
prerequisites: ["net-002-capability-graphs-and-projections", "cs-013-preserve-spectral-axes-and-units"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Separar alcanzabilidad y compatibilidad semántica

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [net-002-capability-graphs-and-projections.md](../../network-science/en/net-002-capability-graphs-and-projections.md)
- [cs-013-preserve-spectral-axes-and-units.md](../../computer-science/en/cs-013-preserve-spectral-axes-and-units.md)
- [dag.rs](https://raw.githubusercontent.com/GuitarAlchemist/ix/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-pipeline/src/dag.rs)

Un catálogo contiene una ruta desde captura hasta visualización pasando por análisis. El receptor acepta la longitud de la matriz y dibuja una imagen. ¿Se compuso correctamente el pipeline? Una ruta alcanzable afirma que existen aristas según una definición. No garantiza que las coordenadas y la escala signifiquen lo que espera el consumidor. Los requisitos previos aportan la frontera del catálogo y el contexto espectral concreto.

Lea la búsqueda de rutas de IX como una cuestión estructural y después la explicación del orden por fotogramas en la lección espectral. Las fichas fijas de productor y consumidor tienen igual forma y frecuencia de muestreo, pero difieren en orientación y escala. Son contratos elaborados, no un nuevo esquema de API. Su tamaño permite comparar todos los campos sin ejecutar servicios.

Igual forma no demuestra igual orientación. El consumidor puede interpretar de otra manera las posiciones almacenadas leyendo el mismo número de celdas. Del mismo modo, valores lineales y logarítmicos no se intercambian silenciosamente por ser numéricos. Una conversión real necesita referencia, tratamiento del cero y semántica precisa. Esta lección no la proporciona ni afirma que renombrar un campo la realice.

La compatibilidad es una conjunción de los campos didácticos declarados. Informe cada discrepancia en lugar de llamar a todo fallo de transporte. Una ruta desconectada y una carga incompatible requieren reparaciones distintas. Incluso un contrato coincidente deja abiertas disponibilidad, autenticación, identidad real de implementación y pruebas del resultado. Una arista verde no representa implícitamente esas garantías.

Para la tarea asistida por fuentes, anote la definición de arista del requisito previo de catálogo y el ejemplo de orientación del requisito espectral. Dibuje la ruta y compare las fichas campo a campo. Pida a un asistente el conjunto mínimo de diferencias y pruebas necesarias para un adaptador, sin implementarlo. El control negativo hace coincidir consumidor y productor. Rechace afirmaciones basadas solo en la existencia de la ruta o el número total de celdas.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "edges": [
      [
        "capture",
        "spectrum"
      ],
      [
        "spectrum",
        "display"
      ]
    ],
    "producer": {
      "shape": [
        2,
        3
      ],
      "orientation": "frame-major",
      "sample_rate_hz": 48000,
      "scale": "linear"
    },
    "consumer": {
      "shape": [
        2,
        3
      ],
      "orientation": "bin-major",
      "sample_rate_hz": 48000,
      "scale": "dB"
    }
  },
  "formula": "compatible=shape_match AND orientation_match AND sample_rate_match AND scale_match",
  "expected": {
    "reachable": true,
    "shape_match": true,
    "orientation_match": false,
    "sample_rate_match": true,
    "scale_match": false,
    "compatible": false,
    "mismatches": 2
  },
  "negative_control": "An otherwise identical frame-major linear consumer matches all stated fields; reachability still does not prove a live call.",
  "assumptions": [
    "The listed fields are the full teaching contract; no implicit conversion or live credentials."
  ],
  "limits": "No full spectral API validation, real transport or production adapter is established."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

¿La visualización es alcanzable estructuralmente?

<details>
<summary>Respuesta 1</summary>

Sí, mediante `capture -> spectrum -> display`; no demuestra una llamada observada.

</details>

### Ejercicio 2

Compare forma y frecuencia.

<details>
<summary>Respuesta 2</summary>

Coinciden la forma `[2,3]` y la frecuencia `48000`.

</details>

### Ejercicio 3

Cuente las discrepancias semánticas.

<details>
<summary>Respuesta 3</summary>

`2`: orientación y escala; compatibilidad global `false`.

</details>

### Ejercicio 4

Evalúe el control de fichas coincidentes.

<details>
<summary>Respuesta 4</summary>

Coinciden todos los campos declarados, pero no se observó una llamada real satisfactoria.

</details>

### Ejercicio 5

¿Qué debe especificar una propuesta de adaptador?

<details>
<summary>Respuesta 5</summary>

Significado de entradas y salidas, conversión, referencia, casos límite y pruebas de validación independiente.

</details>

[Paquete de pruebas fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
