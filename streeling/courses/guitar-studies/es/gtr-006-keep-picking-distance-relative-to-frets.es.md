---
module_id: gtr-006-keep-picking-distance-relative-to-frets
department: guitar-studies
course: "Referir la distancia de pulsación a los trastes"
level: intermediate
prerequisites: ["gtr-001-the-fretboard-map", "gas-006-relate-pluck-position-to-string-modes"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Referir la distancia de pulsación a los trastes

> **Alcance del borrador.** Geometría ideal de trastes y longitudes creada para el curso, predicciones modales e inspección de código público fijado a una revisión. Quedan pendientes las revisiones humanas técnica, lingüística, musical y de estudiantes, así como la verificación del HTML del curso desplegado. No se probaron un intérprete, una guitarra, un motor nativo/WASM, un navegador ni un flujo de [ComfyUI](https://docs.comfy.org/).

## La pregunta del proyecto

Un guitarrista mantiene la mano que pulsa a la misma distancia del puente mientras sube por el mástil. ¿Ha permanecido la púa en la misma fracción de la cuerda vibrante? Esto importa al especificar una instrucción de práctica o un futuro control de síntesis de GA. Una distancia en milímetros, una fracción de longitud vibrante y un índice de búfer de retardo tienen significados distintos.

Usamos una longitud de escala al aire de 650 mm creada para el curso, trastes ideales de temperamento igual, tensión y densidad lineal constantes y ausencia de rigidez, compensación o estiramiento debido a la altura de las cuerdas. Son hipótesis de modelo, no mediciones de un instrumento concreto. [GAS-006](../../guitar-acoustics/en/gas-006-relate-pluck-position-to-string-modes.md) define la pulsación triangular ideal usada para las siguientes predicciones modales.

## 1. Acortar la longitud vibrante

Para el traste k, la longitud vibrante ideal es `L_k=L_0*2^(-k/12)`. La frecuencia sube según la razón inversa de longitudes bajo la hipótesis declarada de velocidad de onda fija. Esto se deriva de la relación de longitud y frecuencia de la cuerda de extremos fijos de la [clase de Princeton sobre movimiento ondulatorio](https://kirkmcd.princeton.edu/examples/Ph205/ph205l21.pdf#page=5), combinada con la razón declarada de semitonos en temperamento igual. No modela una guitarra física completa.

| Traste | Longitud vibrante, mm | Razón de frecuencia respecto a la cuerda al aire |
| --- | --- | --- |
| 0 | 650 | 1 |
| 12 | 325 | 2 |
| 24 | 162.5 | 4 |

### Ejercicio 1: calcular la longitud vibrante

Para la escala didáctica, calcula la longitud vibrante en el traste 12 y su razón de frecuencia respecto a la cuerda al aire. ¿Establece el factor un resultado de afinación medido en un instrumento?

> **Respuesta:** La longitud es `650/2=325` mm y la razón de frecuencia es 2 bajo este modelo. No se midió ningún instrumento, así que compensación, estiramiento y entonación real quedan fuera del resultado.

## 2. Distinguir distancia de fracción

Declara la distancia de pulsación al puente d en milímetros y la posición normalizada `p=d/L_k`, con `0<d<L_k`. Con una distancia fija de la mano de 65 mm, p cambia al cambiar la longitud vibrante:

| Traste | Distancia fija, mm | Fracción p | Anulaciones modales ideales |
| --- | --- | --- | --- |
| 0 | 65 | `1/10` | múltiplos de 10 |
| 12 | 65 | `1/5` | múltiplos de 5 |
| 24 | 65 | `2/5` | múltiplos de 5 |

Las familias de anulaciones proceden del desplazamiento triangular ideal y su factor `sin(n*pi*p)`. No son huecos espectrales medidos ni instrucciones para tocar un nodo de armónico natural. Pulsar y soltar normalmente y tocar ligeramente una cuerda al producir un armónico son operaciones iniciales o de contorno distintas.

### Ejercicio 2: seguir una mano inmóvil

La mano permanece a 65 mm del puente mientras la mano izquierda pasa del traste 0 al traste 12. Calcula ambas fracciones. ¿Qué quinto modo ideal pasa de no nulo a cero?

> **Respuesta:** Las fracciones son `65/650=1/10` y `65/325=1/5`. El modo 5 es no nulo para la primera pulsación triangular ideal y cero para la segunda, porque `5/10` no es un entero mientras que `5/5` sí lo es. Es una predicción del modelo, no un espectro observado de un intérprete.

## 3. Mover la mano para conservar la fracción

Para mantener `p=1/10`, resuelve `d=p*L_k`. Las distancias didácticas necesarias son 65 mm al aire, 32.5 mm en el traste 12 y 16.25 mm en el traste 24. La mano que pulsa debe acercarse al puente al acortarse la longitud vibrante. Por tanto, una instrucción de práctica puede especificar una distancia fija o una fracción fija; debería indicar cuál se pretende.

Mantener p constante conserva el patrón normalizado de coeficientes ideales para un desplazamiento máximo fijo. No garantiza el mismo timbre radiado, sonoridad, sensación ni fuerza de púa. Las resonancias del cuerpo, la construcción de la cuerda y el punto de observación acústico o mediante pastilla siguen siendo relevantes.

### Ejercicio 3: conservar una ubicación normalizada

¿Qué distancias al puente mantienen `p=1/10` en los trastes 12 y 24? ¿Satisfaría esa petición dejar la distancia en 65 mm?

> **Respuesta:** Usa 32.5 mm y 16.25 mm respectivamente. Mantener 65 mm da en cambio `1/5` y `2/5`, así que no satisface la petición de fracción fija bajo la geometría declarada.

## 4. No inferir una posición única de la mano a partir de una anulación

En los trastes 12 y 24 con distancia fija de 65 mm, ambos casos ideales suprimen múltiplos de 5, pero sus fracciones difieren. Las amplitudes y signos modales no tienen por qué coincidir. Más generalmente, otras causas pueden atenuar un parcial observado, incluida la respuesta de la pastilla o del micrófono. Un parcial ausente por sí solo no identifica la ubicación física de pulsación.

El [registro de geometría](../../../../code/streeling/evidence/pluck-coordinates-2026-10-22/fret-geometry.json) también incluye el traste 7 como caso de transferencia fuera de la octava. Sus coordenadas proceden de la misma ecuación didáctica. No se adjunta ninguna medición en milímetros ni traza de interpretación musical.

### Ejercicio 4: cuestionar la inferencia inversa

Un agente ve un quinto parcial suprimido e informa de una fracción única de púa `1/5`. Da el contraejemplo didáctico y explica por qué la grabación observada necesitaría más pruebas.

> **Respuesta:** La fracción `2/5` también suprime el modo 5 en este modelo ideal. Una atenuación grabada podría surgir además de otras rutas de transferencia, así que no puede inferirse una ubicación única solo de ese parcial. Hacen falta más información modal, un modelo de observación declarado y pruebas independientes de posición.

## 5. Traducir la petición a un futuro contrato del motor

El [punto de entrada de notas de GA](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L530-L537) de la revisión fijada acepta frecuencia y velocidad de pulsación. Su [heurística de excitación](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L354-L379) deriva un desplazamiento normalizado del búfer de retardo a partir de la velocidad de pulsación. Estas rutas inspeccionadas no aceptan longitud física de escala, identidad de traste ni distancia al puente. Una frecuencia puede describir varias realizaciones de cuerda/traste, así que no proporciona por sí sola esas coordenadas ausentes.

Una instrucción DSL propuesta podría incluir una realización física declarada de la cuerda y una distancia o una ubicación normalizada, junto con su marco de referencia. Es un diseño candidato, no una API implementada ni un requisito de que todos los modelos usen coordenadas físicas. La alternativa más sencilla es exponer y documentar un control puramente sintético de forma del búfer. La tarea prevista por el músico determina si merece la pena implementar y validar esa correspondencia física adicional.

### Ejercicio 5: hacer ejecutable el significado de la instrucción

Reescribe «mantener la púa en el mismo sitio» como dos peticiones inequívocas entre los trastes 0 y 12. ¿Puede el punto de entrada de frecuencia y velocidad de pulsación inspeccionado representar directamente ambas peticiones?

> **Respuesta:** Una petición mantiene la distancia al puente en 65 mm y produce fracciones `1/10` y `1/5`. Otra mantiene la fracción `1/10`, lo que requiere distancias de 65 mm y 32.5 mm. El punto de entrada inspeccionado no tiene campos de distancia física ni geometría de cuerda/traste, así que no codifica directamente esa distinción. Implementar y probar una correspondencia, o elegir un control sintético documentado, sigue siendo trabajo futuro.
