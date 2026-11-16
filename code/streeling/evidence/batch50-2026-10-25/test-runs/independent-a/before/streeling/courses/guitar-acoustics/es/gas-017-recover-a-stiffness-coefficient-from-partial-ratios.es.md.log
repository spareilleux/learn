---
module_id: gas-017-recover-a-stiffness-coefficient-from-partial-ratios
department: guitar-acoustics
course: "Recuperar un coeficiente de rigidez a partir de razones de parciales"
level: advanced
prerequisites: ["gas-010-distinguish-stiff-string-partials-from-harmonics"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Recuperar un coeficiente de rigidez a partir de razones de parciales

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Un espectro inarmónico plausible no identifica por sí solo un parámetro de producción. Antes de recomendar un ajuste de dispersión de [GA](https://github.com/GuitarAlchemist/ga), resuelva el modelo inverso declarado y compruebe un parcial que no se haya usado en el ajuste. Esta lección separa estimación y predicción, y rechaza una observación incompatible con la familia elegida.

## Leer la evidencia conservada

La fuente principal explica la propagación dispersiva y su modelado con filtros pasa todo. Nuestro coeficiente normalizado procede del ejemplo del prerrequisito, sin calibración documentada del motor. El estado de dispersión conservado describe una frontera del software, no una medición del material.

[Prerrequisito](../../guitar-acoustics/en/gas-010-distinguish-stiff-string-partials-from-harmonics.md)

[Artefacto conservado del proyecto](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.dsprelated.com/freebooks/pasp/Stiff_String.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "squared_normalized_second_ratio": 1.0297029702970297,
    "squared_normalized_third_ratio": 1.0792079207920793
  },
  "formula": "r=(f2/(2*f1))^2; B=(r-1)/(4-r); predicted_third_squared_ratio=(1+9*B)/(1+B); valid=1<=r<4 and B>=0",
  "expected": {
    "B": 0.01,
    "predicted_third_squared_ratio": 1.0792079207920793,
    "held_out_residual": 0,
    "valid": true
  },
  "negative_control": {
    "values": {
      "squared_normalized_second_ratio": 0.99,
      "squared_normalized_third_ratio": 1
    },
    "expected": {
      "B": -0.0033222591362126247,
      "valid": false
    }
  }
}
```

## Separar ajuste, predicción y calibración

Un cálculo inverso puede ajustar exactamente su observación elegida por construcción. Esa coincidencia no es validación independiente. Por ello la entrada del tercer parcial queda fuera de la ecuación de ajuste y se compara después de recuperar el coeficiente. En un espectro real también importarían incertidumbre e identidad de picos: intercambiar un índice puede dar un ajuste numérico limpio de una relación física equivocada.

La inversa tiene una región admisible. Cuando el denominador se acerca a cero, pequeños errores de razón pueden producir grandes cambios del coeficiente. Una respuesta finita puede estar definida algebraicamente y ser inestable en la práctica. El control de no negatividad trata otra cuestión: rechaza un signo incompatible con la familia, sin estimar confianza en un ajuste válido. Separe singularidad, admisibilidad e incertidumbre de medida.

Finalmente, un coeficiente didáctico inferido no es un valor de control del software. Una implementación pasa todo puede usar coeficientes relacionados con las razones de parciales a través del bucle completo. El estado conservado demuestra cantidades de dispersión, no una inversa calibrada. Antes de recomendar ajustes, un experimento necesita una intervención identificada y parciales medidos reservados para comprobarla. La inversa manual y su caso rechazado ofrecen una referencia pequeña para decidir si merece la pena esa calibración más amplia.

### Ejercicio 1

Reordene la razón cuadrática del segundo parcial para despejar el coeficiente. ¿Qué término no puede anularse?

<details><summary>Respuesta 1</summary>

Al reunir los términos se obtiene la inversa mostrada. El denominador debe ser no nulo; recortar el ajuste sin declararlo no corrige una razón singular o excluida.

</details>

### Ejercicio 2

Utilice la razón principal e indique el coeficiente recuperado. ¿Qué relación se ha ajustado?

<details><summary>Respuesta 2</summary>

El coeficiente esperado figura abajo. Solo se ajustó la relación normalizada del segundo parcial; el primero sigue fijando la escala de frecuencia.

</details>

### Ejercicio 3

Prediga la razón del tercer parcial reservado para comprobación. ¿Por qué conservar esa entrada aparte?

<details><summary>Respuesta 3</summary>

La predicción y la razón suministrada coinciden en este caso construido. Reutilizar la ecuación del segundo parcial no comprobaría la consecuencia para un parcial superior.

</details>

### Ejercicio 4

Aplique el control. ¿Por qué rechazar el coeficiente aunque el álgebra devuelva un número?

<details><summary>Respuesta 4</summary>

El coeficiente es negativo y viola la familia no negativa elegida. Un resultado algebraico finito no garantiza admisibilidad física bajo estas hipótesis.

</details>

### Ejercicio 5

¿Qué refutaría el ajuste antes de calibrar el motor?

<details><summary>Respuesta 5</summary>

Una razón reservada incompatible con la predicción más allá de la incertidumbre declarada refuta el ajuste. Identificar mal un parcial también invalida la entrada sin demostrar un defecto del motor.

</details>

## Tarea con consulta de fuentes

Derive la inversa a mano y conserve aparte la comprobación reservada. Compare el resultado con el estado del software. Proponga un registro con identidad e incertidumbre de los parciales antes de recomendar parámetros; deje sin evaluar la correspondencia con el motor y la audibilidad.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
