---
module_id: gas-006-relate-pluck-position-to-string-modes
department: guitar-acoustics
course: "Relacionar la posición de pulsación con los modos de la cuerda"
level: intermediate
prerequisites: ["gas-002-brightness-control-and-evaluation-gate", "gas-005-separate-a-partial-peak-from-a-period", "phy-004-velocity-pick-position-guitar-engine"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Relacionar la posición de pulsación con los modos de la cuerda

> **Alcance del borrador.** Inspección de código público fijado a una revisión y cálculos de cuerda ideal establecidos. Quedan pendientes las revisiones humanas técnica, lingüística, musical y de estudiantes, así como la verificación del HTML del curso desplegado. Para esta lección no se usaron una guitarra, un motor nativo/WASM, un navegador ni un flujo de [ComfyUI](https://docs.comfy.org/).

## La pregunta del proyecto

Mover una púa puede cambiar el espectro de una guitarra sin cambiar su altura nominal. ¿Podría un futuro control de GA expresar ese movimiento directamente? Primero hay que distinguir una condición inicial física de la heurística existente del motor. El [código Rust de excitación inspeccionado](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L294-L396) está fijado al commit de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`. Sus bytes públicos quedan vinculados en el [comprobante del código fuente](../../../../code/streeling/evidence/pluck-coordinates-2026-10-22/primary-readback.json).

[PHY-004](../../physics/en/phy-004-velocity-pick-position-guitar-engine.md) ya establece el control acoplado de velocidad y la fórmula proporcional de los modos ideales. Esta lección profundiza en ese trabajo con coeficientes normalizados y cocientes con signo para un desplazamiento máximo h fijo, comprobaciones independientes de 80 coeficientes y una comparación con el código actual fijado a la revisión indicada.

## 1. Declarar una forma inicial ideal

Usa una cuerda flexible y uniforme con extremos fijos, desplazamiento transversal lineal pequeño y sin amortiguamiento ni rigidez. Declara el puente como origen de coordenadas, la longitud vibrante como L y la posición normalizada como `u=x/L`. Una pulsación puntual alcanza su máximo en `p`, estrictamente entre los extremos, con desplazamiento fijo h y velocidad inicial cero. La forma inicial dividida entre h sube como `u/p` hasta p y después baja como `(1-u)/(1-p)` hasta el otro extremo.

Estas hipótesis siguen el [modelo de cuerda pulsada ideal](https://dsprelated.com/freebooks/pasp/Ideal_Plucked_String.html). Excluyen un contacto de púa de anchura finita, una fuerza mantenida y la respuesta del cuerpo de un instrumento observado. Un desplazamiento máximo no es una orden de velocidad ni un búfer de ruido arbitrario.

### Ejercicio 1: identificar el estado

En `p=1/5`, ¿cuál es el desplazamiento normalizado en el puente, en el punto de pulsación y en el extremo opuesto? ¿Qué velocidad inicial se supone? ¿Queda el modelo completamente especificado al decir «ataque brillante»?

> **Respuesta:** Los desplazamientos divididos entre h son 0, 1 y 0. La velocidad inicial es cero en todas partes. «Ataque brillante» no proporciona esa forma ni sus coordenadas y velocidad inicial, así que no especifica esta condición inicial.

## 2. Proyectar esa forma sobre los modos

Sea B_n nuestro coeficiente de desplazamiento del modo n. La [derivación de la clase de Princeton](https://kirkmcd.princeton.edu/examples/Ph205/ph205l21.pdf#page=5), en la página 5 del PDF, da los coeficientes de la serie de senos del desplazamiento triangular; su notación los llama A_n. En nuestra notación:

`B_n/h = 2*sin(n*pi*p)/(pi^2*n^2*p*(1-p))`

Se obtiene integrando el doble de la forma normalizada multiplicada por `sin(n*pi*u)` en el intervalo unidad. Un modo está ausente de este desplazamiento inicial ideal cuando `n*p` es un entero. En el punto medio `p=1/2`, todos los modos pares se anulan. El tercer coeficiente dividido entre el primero es `-1/9`; su magnitud es `1/9`. El signo representa la fase del desplazamiento modal al soltar la cuerda, no una sonoridad medida negativa.

### Ejercicio 2: localizar las anulaciones

¿Qué familias de modos se anulan en `p=1/5` y `p=1/10`? En el punto medio, ¿eliminar los modos pares también elimina el tercer modo?

> **Respuesta:** Los múltiplos de 5 se anulan en `p=1/5`; los múltiplos de 10 se anulan en `p=1/10`. El punto medio elimina los modos pares, mientras el tercero permanece con razón con signo `-1/9` respecto a la fundamental. Son coeficientes ideales de desplazamiento, no amplitudes medidas por un micrófono.

## 3. Comparar una razón sin cambiar el modelo

Con el mismo máximo h, la razón con signo del segundo coeficiente al primero es `cos(pi*p)/2`. La [tabla modal fijada](../../../../code/streeling/evidence/pluck-coordinates-2026-10-22/ideal-pluck-modes.json) da aproximadamente 0.40450849718747367 en `p=1/5` y 0.4755282581475768 en `p=1/10`. Ambas son positivas. Esta razón elegida aumenta hacia el puente en estos dos casos creados para el curso; no demuestra una clasificación universal del brillo percibido.

Mantener el desplazamiento h no mantiene constantes la fuerza de pulsación ni la energía inicial. La radiación debida a la fuerza en el puente, la ubicación de la pastilla, la transferencia del cuerpo, el amortiguamiento y las condiciones de escucha añadirían otras transformaciones. Una anulación exacta en este modelo es una predicción bajo sus hipótesis, no una promesa de un armónico inaudible en una guitarra grabada.

### Ejercicio 3: enunciar la comparación

Compara las dos razones del segundo coeficiente al primero. ¿Qué ubicación tiene el valor mayor según este cálculo? ¿Puede llamarse al resultado una preferencia medida o una comparación a energía constante?

> **Respuesta:** La razón en `p=1/10` es aproximadamente 0.4755282581475768, mayor que aproximadamente 0.40450849718747367 en `p=1/5`. Es un cálculo ideal de desplazamiento modal con máximo h fijo. No se midieron ni impusieron preferencias de oyentes, espectro radiado ni igualdad de energía inicial.

## 4. Leer la excitación distinta del motor

La [heurística de púa y su ventana](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L354-L379) eligen una razón del búfer de retardo dependiente de la velocidad de pulsación, la redondean a un desplazamiento entero y multiplican ruido suavizado recursivamente por una ventana triangular recortada. La expresión de la razón es `0.18+0.60*(1-velocity)` antes de sus límites. El comentario menciona cuerdas agudas, pero la expresión contiene la velocidad de pulsación, sin identidad de cuerda ni entrada de traste. La longitud del búfer también afecta al desplazamiento cuantizado.

Para una longitud de búfer didáctica 100 y velocidad de pulsación 0.5, la transcripción en aritmética real da razón 0.48, desplazamiento 48 y posición cuantizada 0.48. En el índice de búfer 88, la ventana triangular es cero, mientras que el triángulo ideal de extremos fijos con `p=0.48` tiene allí desplazamiento normalizado aproximado 0.23076923076923075. Más fundamentalmente, el motor multiplica su ventana por ruido. Ni la ventana ni el búfer resultante son el desplazamiento triangular físico anterior, y esa expresión de razón no documenta ninguna orientación relativa al puente.

### Ejercicio 4: rechazar una sustitución falsa

Para ese ejemplo de longitud 100, ¿puede un agente sustituir la ventana triangular del motor en la fórmula de coeficientes del triángulo ideal y anunciar una anulación exacta del quinto modo? Indica las diferencias relevantes entre código y modelo.

> **Respuesta:** No. El código tiene una ventana triangular compacta que multiplica ruido suavizado recursivamente, con una coordenada cuantizada del búfer de retardo. El cálculo ideal exige su desplazamiento triangular declarado de longitud completa, extremos fijos y velocidad inicial cero. Esas condiciones y un origen físico en el puente no se han establecido para ese búfer del motor.

## 5. Diseñar un control sin afirmar su resultado

Un experimento propuesto de posición de pulsación necesita su propia coordenada, unidades y política de extremos, separadas de la velocidad de pulsación. Cambiar la velocidad para mover la heurística existente también cambia la amplitud de excitación y el nivel de ataque, así que no es una comparación aislada de ubicación. [GTR-006](../../guitar-studies/en/gtr-006-keep-picking-distance-relative-to-frets.md) deriva cómo cambia el significado de una distancia al puente al pisar un traste.

El triángulo ideal tiene una esquina aguda e infinitos modos. Una implementación muestreada finita necesita un límite de banda declarado; la fuente citada sobre la cuerda ideal explica ese requisito. El suavizado recursivo del código no establece un corte antialias estricto. Cualquier implementación necesitaría sus propias pruebas de excitación finita, afinación y espectro, seguidas de escucha con nivel controlado. Esta lección ofrece un objetivo analítico y un contraejemplo a una interpretación incorrecta del código fuente.

### Ejercicio 5: proponer el siguiente experimento

Un agente cambia solo la velocidad de pulsación y llama al resultado una prueba aislada de posición física de la púa. Identifica los factores de confusión y redacta una comparación propuesta mejor. ¿Se ha realizado aquí esa comparación?

> **Respuesta:** La velocidad de pulsación cambia a la vez amplitud, razón heurística del búfer y nivel de ataque. Propón un control separado y explícitamente definido de posición relativa al puente, mantén fijos la velocidad y los demás ajustes de síntesis, declara la limitación de banda y después renderiza y compara las posiciones solicitadas con controles de afinación y nivel. Ese control y esa comparación siguen sin implementarse ni ejecutarse aquí; de estos cálculos no se deriva ningún resultado de calidad sonora.
