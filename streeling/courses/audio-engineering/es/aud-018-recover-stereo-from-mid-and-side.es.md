---
module_id: aud-018-recover-stereo-from-mid-and-side
department: audio-engineering
course: "Reconstruir el estéreo a partir de las componentes central y lateral"
level: advanced
prerequisites: ["aud-010-preserve-channels-before-downmixing"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Reconstruir el estéreo a partir de las componentes central y lateral

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Una referencia estéreo de guitarra puede cambiar de representación sin perder información si se conservan ambas componentes transformadas. Guardar solo su suma borra la diferencia, aunque después se exporte otro archivo estéreo. Construimos una transformación invertible y luego eliminamos su componente lateral. Así se explicitan el almacenamiento necesario y el coste energético antes de ofrecer un control de anchura.

## Leer la evidencia conservada

El prerrequisito muestra la pérdida causada por la mezcla mono. El script conservado declara una salida WAV mono, por lo que no demuestra esta operación estéreo. La matriz siguiente es una extensión creada para una propuesta de revisión, sin nuevo soporte de ejecución.

[Prerrequisito](../../audio-engineering/en/aud-010-preserve-channels-before-downmixing.md)

[Artefacto conservado del proyecto](../../../../code/streeling/guitar-runtime/run.mjs)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "left": [
      1,
      0
    ],
    "right": [
      0,
      1
    ],
    "side_gain": 1
  },
  "formula": "M=(L+R)/sqrt(2); S=(L-R)/sqrt(2); L_out=(M+g*S)/sqrt(2); R_out=(M-g*S)/sqrt(2); E=sum(L_out^2+R_out^2)",
  "expected": {
    "mid": [
      0.7071067811865476,
      0.7071067811865476
    ],
    "side": [
      0.7071067811865476,
      -0.7071067811865476
    ],
    "left_out": [
      1,
      0
    ],
    "right_out": [
      0,
      1
    ],
    "input_energy": 2,
    "output_energy": 2
  },
  "negative_control": {
    "values": {
      "left": [
        1,
        0
      ],
      "right": [
        0,
        1
      ],
      "side_gain": 0
    },
    "expected": {
      "mid": [
        0.7071067811865476,
        0.7071067811865476
      ],
      "side": [
        0.7071067811865476,
        -0.7071067811865476
      ],
      "left_out": [
        0.5,
        0.5
      ],
      "right_out": [
        0.5,
        0.5
      ],
      "input_energy": 2,
      "output_energy": 1
    }
  }
}
```

## Conservar las coordenadas mientras la pregunta exija reversibilidad

La transformación cambia coordenadas en el plano de canales. No identifica por sí sola una fuente física en el centro o a los lados de una sala. Son nombres útiles para las direcciones suma y diferencia, con orden de canales declarado. Intercambiar izquierda y derecha conserva la coordenada central e invierte la lateral; incluso un registro numéricamente reversible necesita esa orientación.

Un cambio ortonormal conserva la suma de cuadrados en cada instante y, por tanto, en todo el registro finito. Es una propiedad algebraica más fuerte que comprobar solo picos y más limitada que una conclusión perceptiva. El pico de un canal transformado puede diferir de los picos originales. Limitar, cuantizar o cambiar la ganancia después exigiría otro balance antes de prometer recuperación exacta.

El control sin componente lateral ilustra una proyección, no un cambio reversible. Copiar la media en dos canales no restaura la coordenada perdida. Muchas parejas originales comparten esa media. Conserve ambas matrices si después se compararán diferencias de sala o muestras estéreo originales. Una tabla matricial directa basta para decidir el almacenamiento; un flujo de audio propuesto debe justificar su complejidad mostrando orden, normalización y procesamiento lateral deliberado en el registro guardado.

### Ejercicio 1

Forme las matrices central y lateral. ¿Por qué hay que indicar la normalización?

<details><summary>Respuesta 1</summary>

Ambas aparecen arriba. La normalización por la raíz cuadrada hace ortonormal esta matriz; otra convención necesitaría distintas fórmulas de inversión y energía.

</details>

### Ejercicio 2

Invierta el caso principal y compare cada muestra con los canales originales.

<details><summary>Respuesta 2</summary>

La inversión restaura ambas matrices originales. Conservar las componentes central y lateral preserva la diferencia que una media mono no puede reconstruir.

</details>

### Ejercicio 3

Compruebe la energía cuadrática antes y después de la transformación principal. ¿Demuestra igual sonoridad?

<details><summary>Respuesta 3</summary>

Las energías mostradas coinciden por la propiedad de la matriz ortonormal. La sonoridad percibida también depende de la reproducción y de las condiciones de escucha.

</details>

### Ejercicio 4

Aplique el control sin componente lateral. ¿Permiten canales iguales reconstruir los originales?

<details><summary>Respuesta 4</summary>

No. Las salidas pasan a ser la misma media y la energía disminuye según lo indicado. Se ha eliminado la información lateral, no se ha almacenado por duplicado.

</details>

### Ejercicio 5

¿Qué haría rechazar una transferencia estéreo anunciada como sin pérdida?

<details><summary>Respuesta 5</summary>

No recuperar alguna muestra conservada con la inversa declarada refuta la ausencia de pérdida numérica. Un resultado del script mono tampoco demuestra esa transferencia estéreo.

</details>

## Tarea con consulta de fuentes

Dibuje las transformaciones a mano. Compare conservar ambas coordenadas con guardar solo su suma, e inspeccione la declaración mono del encabezado. Proponga el registro reversible mínimo antes de recomendar un control de anchura; mantenga el orden y la escala de los canales.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
