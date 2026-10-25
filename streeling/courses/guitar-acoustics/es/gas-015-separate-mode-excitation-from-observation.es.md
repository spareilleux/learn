---
module_id: gas-015-separate-mode-excitation-from-observation
department: guitar-acoustics
course: "Distinguir la excitación de un modo de su observación"
level: advanced
prerequisites: ["gas-006-relate-pluck-position-to-string-modes"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguir la excitación de un modo de su observación

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Que falte una componente espectral no implica que el modo no se haya excitado. Un observador puntual situado en un nodo no ve su desplazamiento. Las explicaciones de [GA](https://github.com/GuitarAlchemist/ga) deben separar excitación, propagación y observación antes de diagnosticar un modelo de guitarra. Aquí las amplitudes modales permanecen fijas mientras se mueve el observador.

## Leer la evidencia conservada

La fuente sobre ondas estacionarias describe nodos y antinodos. Compare la derivación de amplitudes del prerrequisito con el estado de voz conservado. Ninguno aporta una medida calibrada de un captador puntual. Introducimos el operador de observación como hipótesis didáctica explícita.

[Prerrequisito](../../guitar-acoustics/en/gas-006-relate-pluck-position-to-string-modes.md)

[Artefacto conservado del proyecto](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.phys.unsw.edu.au/jw/strings.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "amplitudes": [
      1,
      0.5,
      0.25,
      0.125
    ],
    "modes": [
      1,
      2,
      3,
      4
    ],
    "position_fraction": 0.5
  },
  "formula": "observed_n=A_n*sin(n*pi*u)",
  "expected": {
    "observed": [
      1,
      0,
      -0.25,
      0
    ],
    "zero_modes": [
      2,
      4
    ]
  },
  "negative_control": {
    "values": {
      "amplitudes": [
        1,
        0.5,
        0.25,
        0.125
      ],
      "modes": [
        1,
        2,
        3,
        4
      ],
      "position_fraction": 0.25
    },
    "expected": {
      "observed": [
        0.7071067811865476,
        0.5,
        0.1767766952966369,
        0
      ],
      "zero_modes": [
        4
      ]
    }
  }
}
```

## Preguntar en qué etapa desaparece la componente

El coeficiente de excitación describe el estado modal preparado y el peso de observación describe su contribución a la salida. Su producto puede anularse porque cualquiera de los factores sea nulo. El producto solo no identifica la causa del cero. Esta factorización ayuda cuando un agente quiere modificar la pulsación tras encontrar un hueco en el espectro observado.

Un punto situado en un nodo ideal es revelador: su cero no depende de la amplitud modal. Aumentar la excitación no hace visible allí el desplazamiento. Mover el observador puede ayudar si se conservan su nueva posición y la misma excitación. El control demuestra esa posibilidad sin prometer recuperación completa: un modo invisible en ambas posiciones elegidas necesita otra observación.

Las salidas reales añaden funciones de transferencia. Una pastilla magnética puede necesitar velocidad, geometría del campo y apertura finita; un micrófono observa presión radiada después del cuerpo y la sala. Nuestro observador puntual de desplazamiento no aporta ninguno de esos mecanismos. Un experimento útil caracterizaría la observación antes de atribuir un pico ausente a la síntesis. La tabla modal directa es más barata e interpretable que añadir una regla compensadora de agente sin identificar la causa.

### Ejercicio 1

Aplique el operador en la posición principal. ¿Qué modos resultan invisibles?

<details><summary>Respuesta 1</summary>

La lista de modos nulos contiene los modos pares de este ejemplo finito. Sus coeficientes de excitación son distintos de cero: la observación no demuestra ausencia de excitación.

</details>

### Ejercicio 2

Interprete el coeficiente observado negativo. ¿Es sonoridad negativa?

<details><summary>Respuesta 2</summary>

Es un coeficiente de desplazamiento con signo respecto a la fase modal declarada. La sonoridad no es un desplazamiento con signo y no se ha medido.

</details>

### Ejercicio 3

¿Permite la observación principal recuperar todas las amplitudes originales?

<details><summary>Respuesta 3</summary>

No. Un peso de observación nulo borra la amplitud de ese modo. Muchas matrices de excitación producen la misma observación en esos índices.

</details>

### Ejercicio 4

Pase a la posición de control. ¿Qué modo invisible se hace observable?

<details><summary>Respuesta 4</summary>

El segundo modo pasa a ser no nulo y el cuarto sigue invisible. La excitación no ha cambiado; el cambio de observación explica el nuevo coeficiente.

</details>

### Ejercicio 5

¿Qué refuta que un modo ausente en la observación no haya sido excitado?

<details><summary>Respuesta 5</summary>

El caso principal ya ofrece excitación no nula y desplazamiento observado nulo. Un diagnóstico real requiere un operador conocido y otras posiciones o medidas.

</details>

## Tarea con consulta de fuentes

Dibuje los nodos de los modos sinusoidales y reproduzca las tablas con signo a mano. Proponga otra posición de observación para un futuro experimento. Indique qué cero impide aún la recuperación completa; deje pendiente el captador físico antes de recomendar cambios del motor.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
