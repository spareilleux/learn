---
module_id: gas-007-distinguish-body-poles-from-string-partials
department: guitar-acoustics
course: "Distinguir los polos del cuerpo de los parciales de las cuerdas"
level: intermediate
prerequisites: ["gas-005-separate-a-partial-peak-from-a-period", "gas-006-relate-pluck-position-to-string-modes", "aud-007-translate-attack-coefficients-into-time"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguir los polos del cuerpo de los parciales de las cuerdas

> **Alcance del borrador.** Inspección de código público y cálculos didácticos de filtros en aritmética real. Quedan pendientes las revisiones humanas técnica, lingüística, musical y de estudiantes, así como la verificación del HTML del curso desplegado. No se ejecutaron una nueva grabación de guitarra, un renderizado nativo/WASM ni un flujo de [ComfyUI](https://docs.comfy.org/).

## La pregunta del proyecto

Un agente ve un pico espectral y propone cambiar la frecuencia del cuerpo de una guitarra. ¿Qué parámetro del modelo cambiaría y equivale ese parámetro al pico observado? [GAS-005](gas-005-separate-a-partial-peak-from-a-period.md) separa un parcial de un periodo; [GAS-006](gas-006-relate-pluck-position-to-string-modes.md) modela la excitación. Aquí inspeccionamos la etapa posterior del cuerpo en el commit público de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`.

El [constructor](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L124-L135) instala cinco secciones. Son parámetros del código, no modos medidos del cuerpo:

| Parámetro de frecuencia de polos, Hz | Radio de polos r | Ganancia del numerador g |
| --- | --- | --- |
| 110 | 0.95 | 0.08 |
| 240 | 0.96 | 0.10 |
| 530 | 0.97 | 0.08 |
| 1200 | 0.98 | 0.03 |
| 2400 | 0.92 | 0.02 |

## 1. Derivar la sección antes de interpretar su nombre

La [recurrencia](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L23-L44) tiene dos estados de salida retardados, inicialmente cero. Para una frecuencia de muestreo declarada Fs y frecuencia de polos f0:

```text
omega0 = 2*pi*f0/Fs
a1 = 2*r*cos(omega0)
a2 = -r^2
y[n] = g*x[n] + a1*y[n-1] + a2*y[n-2]
H(z) = g / (1 - a1*z^-1 - a2*z^-2)
     = g / (1 - 2*r*cos(omega0)*z^-1 + r^2*z^-2)
```

Los polos tienen radio r y ángulos más y menos omega0. Todos los radios enumerados son menores que 1, así que las secciones lineales ideales aisladas son estables. La [convención biquad del W3C](https://www.w3.org/TR/audio-eq-cookbook/) escribe los coeficientes del denominador con signos de suma y resta sus salidas retardadas. Sus signos de denominador no deben copiarse directamente a la recurrencia aditiva de este código.

### Ejercicio 1 — Relacionar los signos

Para la sección de 110 Hz, indica a2 de la recurrencia y el coeficiente de z^-2 del denominador. ¿Significa g = 0.08 una ganancia de amplitud de 0.08 en todas las frecuencias?

> **Respuesta:** a2 = -0.9025; el coeficiente del denominador es +0.9025. No: g es un coeficiente del numerador. El denominador de realimentación cambia la respuesta en frecuencia.

## 2. Un ángulo de polo no es necesariamente un máximo de ganancia

La [derivación de dos polos de Julius O. Smith](https://www.dsprelated.com/freebooks/filters/Two_Pole.html) distingue explícitamente frecuencia de polos de ganancia máxima exacta. Para esta sección de numerador constante, minimizar el módulo del denominador al cuadrado entre las frecuencias de 0 a Nyquist da:

```text
c = cos(omega0)*(1+r^2)/(2*r)
omega_peak = acos(clamp(c, -1, 1))
f_peak = Fs*omega_peak/(2*pi)
```

A Fs = 44100 Hz, los [cálculos didácticos de respuesta](../../../../code/streeling/evidence/filter-phase-2026-10-22/body-response.json) dan:

| Parámetro de frecuencia de polos, Hz | Máximo aislado, Hz, aproximadamente |
| --- | --- |
| 110 | 0 |
| 240 | 0 |
| 530 | 485.059638 |
| 1200 | 1191.675201 |
| 2400 | 2330.439876 |

La primera sección tiene módulo de aproximadamente 29.268259 en continua y 27.306424 a 110 Hz. Una respuesta impulsional oscilatoria amortiguada puede tener su mayor módulo de respuesta en frecuencia en continua. Este resultado describe la sección matemática aislada, no una nueva grabación, los picos de todo el banco ni el motor no lineal completo.

### Ejercicio 2 — Leer la etiqueta 110 Hz

A Fs = 44100 Hz, ¿está respaldado que «el máximo de la sección de 110 Hz debe estar en 110 Hz»? Explica qué significa el coseno limitado anterior cuando c es mayor que 1.

> **Respuesta:** No. El mínimo del denominador ocurre en el extremo omega = 0 cuando el coseno óptimo sin restricciones supera 1. El parámetro fija el ángulo de los polos; el máximo de ganancia aislada resultante está en continua en este modelo. La limitación selecciona el extremo del dominio de frecuencias, no una calibración física reparada.

## 3. Sumar respuestas complejas antes de tomar el módulo

El [código de mezcla](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L483-L496) envía la suma normalizada de cuerdas por cada sección, suma sus salidas y después combina señales de cuerpo y cuerdas:

```text
H_body(omega) = sum_i H_i(omega)
H_dry(omega) = 0.55 + 0.45*H_body(omega)
```

A 110 Hz, el módulo matemático de la respuesta seca es aproximadamente 34.953699. Sumar en cambio módulos de modos da aproximadamente 35.364828. Las fases relativas explican la diferencia. Ningún número es una ganancia de salida medida del motor completo: después de esta etapa hay reverberación y no linealidades de salida, y la normalización de voces activas puede cambiar el comportamiento anterior.

### Ejercicio 3 — Combinar el banco

Elige la expresión correcta: el módulo de la respuesta compleja seca anterior o 0.55 más 0.45 por la suma de módulos de secciones. Explica por qué la otra expresión es solo una cota superior aquí.

> **Respuesta:** Toma el módulo después de la suma compleja. La desigualdad triangular lo acota por 0.55 más 0.45 por la suma de módulos, pero la igualdad requiere fases alineadas. El cálculo de 110 Hz muestra que ahí no se cumple la igualdad.

## 4. Un filtro lineal de cuerpo no reafina una sinusoide estacionaria

Considera una entrada didáctica estacionaria que solo contenga 82.4069 Hz y 164.8138 Hz. Bajo el modelo aislado lineal e invariante en el tiempo del cuerpo, cada sinusoide conserva su frecuencia y adquiere una ganancia compleja. Un parámetro de frecuencia de polos de 110 Hz no inserta una nueva línea espectral estacionaria de 110 Hz. Los transitorios de arranque pueden oscilar; reverberación, variación temporal y recorte de salida deben evaluarse por separado.

### Ejercicio 4 — Separar la respuesta estacionaria del arranque

Un agente dice que el parámetro de polo de 110 Hz hace que toda entrada de E al aire contenga un nuevo tono estacionario de 110 Hz. Da un contraejemplo con la entrada de dos tonos anterior e indica por qué un transitorio oscilatorio inicial no lo invalidaría.

> **Respuesta:** La salida estacionaria de esta etapa lineal e invariante en el tiempo sigue conteniendo solo 82.4069 Hz y 164.8138 Hz, con amplitudes y fases modificadas. Su respuesta natural decreciente puede aparecer al arrancar; eso es distinto de una línea espectral adicional sostenida por la entrada. Este argumento no cubre el recorte no lineal del motor completo.

## 5. Separar una afirmación física de un filtro sintético útil

La [discusión de Smith sobre modelos de puente](https://dsprelated.com/freebooks/pasp/Building_Synthetic_Guitar_Bridge.html) distingue admitancia del puente, acoplamiento de cuerdas y radiación. La etapa inspeccionada del motor es un banco de filtros de salida alimentado por la suma de cuerdas. Nombres como tapa armónica en comentarios no establecen geometría medida, ganancias modales calibradas ni un modelo pasivo de puente acoplado de vuelta a cada cuerda.

### Ejercicio 5 — Acotar el siguiente experimento

Antes de llamar a un banco modificado «un cuerpo de guitarra más preciso», identifica las pruebas actuales e indica medidas y controles de comparación ausentes. ¿Dónde deberían conservarse señales emparejadas para una prueba aislada?

> **Respuesta:** Las pruebas actuales son código fijado a una revisión y cálculos didácticos de filtros. Una afirmación de precisión física necesita instrumento y ruta de medición definidos, datos calibrados de respuesta, ubicaciones de excitación y observación, criterios de ajuste y comparaciones con datos reservados. Conserva la entrada de suma normalizada de cuerdas y la salida seca previa a reverberación con relojes y escalas coincidentes; separa recorte y reverberación posteriores. Una preferencia de oyente requiere su propia evaluación controlada. [AUD-008](../../audio-engineering/en/aud-008-measure-a-filter-with-paired-input-and-output.md) desarrolla la medición emparejada.

## Tarea del estudiante con acceso a las fuentes

Sin copiar las respuestas, prepara una revisión breve de un control propuesto de «pico de cuerpo a 110 Hz». Incluye los signos de la recurrencia, los cálculos de máximos en el extremo para las secciones de 110 Hz y 240 Hz a Fs = 44100 Hz, las ganancias de la primera sección en continua y a 110 Hz, y el módulo de la respuesta seca del banco a 110 Hz comparado con la alternativa de suma de módulos. Añade el contraejemplo estacionario de dos tonos y un plan acotado de medición. Registra ayuda e incertidumbre. La [rúbrica de revisión](../../../../code/streeling/evidence/filter-phase-2026-10-22/reviewer-rubric.json) está preparada; no hay intentos de estudiantes registrados.

El [comprobante de fuentes](../../../../code/streeling/evidence/filter-phase-2026-10-22/primary-readback.json) vincula archivos públicos inmutables. Los cálculos usan aritmética de mayor precisión sobre parámetros decimales del código, no una reproducción de Rust f32 exacta bit a bit. Esta lección por sí sola no implica un cambio de código, una reparación en ejecución ni una mejora acústica.
