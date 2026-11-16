---
title: Cuando la velocidad desplaza la posición de pulsación en el motor de guitarra de GA
description: Cuando la velocidad desplaza la posición de pulsación en el motor de guitarra de GA — Física
sidebar:
  label: PHY-004 · Cuando la velocidad desplaza la posición de pulsación en el motor de guitarra de GA
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/es/phy-004-velocity-pick-position-guitar-engine.es.md
---

:::note[Streeling University]
**PHY-004** · Cuando la velocidad desplaza la posición de pulsación en el motor de guitarra de GA · intermedio · 40 minutos

Generado por el departamento *Física* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/es/phy-004-velocity-pick-position-guitar-engine.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-001](../../physics/phy-001-science-of-guitar-sound/), [PHY-003](../../physics/phy-003-sampling-aliasing-guitar-engine/)
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de traducciones todavía no redactadas, de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) documenta los borradores traducidos actuales, la importación y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Física** | Intermedio | 40 minutos | Borrador fuente en español; revisión y publicación pendientes, incluida la aprobación de una persona que domine el español

## Objetivos

Distinguirás una posición física de pulsación de la heurística de excitación del motor de GA, calcularás cómo una velocidad de entrada modifica más que la ganancia de salida y diseñarás una comparación que aísle la causa de un cambio de timbre. Es útil al ajustar el motor de guitarra WASM: un músico puede pedir una nota más fuerte esperando el mismo gesto de púa, pero el control actual cambia varios parámetros a la vez. [PHY-001](../../physics/phy-001-science-of-guitar-sound/) describe las ondas estacionarias; [PHY-003](../../physics/phy-003-sampling-aliasing-guitar-engine/) establece por qué hay que registrar la frecuencia de muestreo del motor. Ninguna resuelve esta cuestión del acoplamiento de controles.

El límite de las pruebas es importante. La [fixture ejecutable de PHY-004](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/physics/phy-004/README.md) reproduce **cálculos seleccionados del código fuente fijado**. No sintetiza audio, mide espectros ni establece qué oye un oyente. La lección pretende explicitar las explicaciones alternativas y un experimento decisivo antes de cambiar el código del motor.

## 1. Qué predice una posición física de pulsación

Para una cuerda flexible ideal fija en ambos extremos, expresa la posición como `p = x/L`, donde `L` es la longitud de cuerda y `0 < p < 1`. Un modelo sencillo tira de ella hasta darle un desplazamiento triangular con vértice en `pL` y después la suelta. Descomponer esa forma inicial en modos de ondas estacionarias da un coeficiente de desplazamiento modal proporcional a `sin(nπp) / [n² p(1-p)]` para el índice armónico `n`, manteniendo fija la altura del vértice. Se obtiene al integrar los dos tramos rectos del triángulo contra los modos sinusoidales de la cuerda. Es un **modelo ideal de desplazamiento inicial**, no un modelo completo de grabación de guitarra.

El término seno predice ceros dependientes de la posición: en `p = 1/2`, todo `n` par cumple `sin(nπ/2) = 0`; en `p = 1/4`, cada cuarto armónico cumple `sin(nπ/4) = 0`. Una púa real tiene anchura, evolución de la fuerza y tiempo de contacto. La rigidez de la cuerda, las condiciones en sus extremos, la ubicación de la pastilla, el acoplamiento con el cuerpo, la amortiguación y la posición del micrófono pueden modificar el espectro observado. Por eso, un cero modal teórico es una buena predicción experimental bajo supuestos declarados, no una promesa de anulación exacta en un WAV.

El significado de **velocidad** depende de la interfaz. Aquí la velocidad MIDI de nota es un valor de control en `[0,1]`, no una medida de la rapidez física de la púa ni del desplazamiento inicial de la cuerda. No podemos inferir la posición real de pulsación sin una correspondencia calibrada. Un instrumento de software puede usar una entrada para controlar muchos parámetros ocultos, pero esa elección debe ser visible al evaluar causa y efecto.

### Ejercicio práctico 1

En el modelo ideal de desplazamiento triangular, ¿qué índices armónicos tienen un coeficiente inicial nulo en `p = 1/4`? ¿La ausencia del cuarto armónico en una nota de guitarra capturada demostraría que se pulsó a un cuarto de la cuerda?

> **Respuesta:** El factor seno es cero cuando `n` es un múltiplo positivo de cuatro: `n = 4, 8, 12, ...`. Un cuarto armónico ausente o débil no demuestra por sí solo una pulsación a un cuarto de cuerda. La ubicación de la pastilla o el micrófono, la anchura de excitación, la respuesta de cuerda y cuerpo, el procesamiento, el ruido y la ventana de análisis elegida son explicaciones alternativas. La fórmula describe un desplazamiento inicial ideal con supuestos fijos.

## 2. Seguir el control real de GA

En el [commit fijado de GA `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs), `engine_note_on(engine, freq, velocity)` llama a `Engine::excite`. La función limita `velocity` a `[0,1]` y establece la longitud activa del búfer Karplus–Strong en `max(2, floor(sample_rate / max(freq,20)))`. La parte fraccionaria se almacena por separado. Como **ejemplo aritmético controlado**, utiliza `44,100 Hz` y un mi E2 de `82.4069 Hz`, lo que da `floor(44,100 / 82.4069) = 535` muestras activas y una parte fraccionaria aproximada de `0.14936`. Como en PHY-003, esa frecuencia de muestreo pertenece al ejemplo; no es universal en los navegadores.

Después, la fuente calcula `pick_ratio = clamp(0.18 + 0.60(1 - velocity), 0.1, 0.85)`. Redondea `535 × pick_ratio` al entero positivo más cercano y limita el desplazamiento al búfer activo. Al aumentar la velocidad de `0.25` a `0.50` y `0.75`, los desplazamientos elegidos pasan de **337** a **257** y **177** muestras, correspondientes a posiciones normalizadas aproximadas de **0.630**, **0.480** y **0.331**. Es un **índice del búfer del motor**, no una posición medida en centímetros sobre una cuerda física. El comentario lo llama heurística de posición de pulsación; la implementación es la prueba de lo que hace.

La misma velocidad también multiplica la excitación de ruido filtrado, fija `pluck_mix = clamp(0.15 + 0.35 velocity, 0.05, 0.7)` y ayuda a establecer el nivel de ataque. Durante el renderizado, `pluck_mix` interviene en una expresión de brillo; después la señal pasa por realimentación, amortiguación, resonadores del cuerpo y reverberación. Por tanto, comparar dos notas exportadas a velocidades distintas no permite atribuir una diferencia espectral solo a la ganancia o solo a la posición de pulsación. El control está **acoplado** en la implementación fijada.

### Ejercicio práctico 2

A la frecuencia de muestreo y el mi E2 de la fixture, calcula la proporción de pulsación y el desplazamiento en muestras para una velocidad de `0.50`. ¿Qué permanece fijo cuando solo cambia la velocidad entre sus tres casos?

> **Respuesta:** `0.18 + 0.60(1 - 0.50) = 0.48`; `round(535 × 0.48) = round(256.8) = 257`. La frecuencia de muestreo de entrada y la frecuencia de nota son fijas, por lo que permanecen la longitud entera de 535 muestras y su parte fraccionaria aproximada de `0.14936`. La velocidad cambia proporción, desplazamiento, multiplicador de excitación, `pluck_mix` y nivel de ataque. El desplazamiento calculado no es una medida de micrófono.

## 3. Reproducir los cálculos y respetar su límite

Ejecuta `python state/streeling/fixtures/physics/phy-004/evaluate_pick.py` desde la raíz de Demerzel. El script sin dependencias lee tres casos declarados y comprueba mediante aserciones la longitud del búfer, los desplazamientos y los valores `pluck_mix` de la fórmula fijada. Comprueba que los desplazamientos disminuyen y `pluck_mix` aumenta cuando sube la velocidad. También evalúa la forma anterior al ruido en el desplazamiento elegido. La forma del modelo es `clamp(1 - 2.5 |i/N - offset/N|, 0, 1)` para el índice activo `i`, de modo que su pico allí vale uno por construcción. La excitación completa de Rust multiplica esta forma por ruido pseudoaleatorio filtrado paso bajo y por la velocidad; la fixture omite expresamente ese camino con estado.

Esta comprobación refuta el **atajo concreto** «la velocidad es solo un control escalar de ganancia en este código». **No** refuta la posibilidad de que, en una nota renderizada y una banda de medida concretas, el cambio de ganancia domine cualquier cambio de timbre. Inspeccionar las fórmulas y trazar parámetros establece el acoplamiento; se necesita comparar audio para establecer su magnitud perceptiva. Los valores JSON esperados fijos hacen reproducible el ejemplo y revelan cambios accidentales en la fórmula. Si cambia la fuente de GA, la comparación fijada sigue siendo una afirmación histórica y requiere una nueva revisión del código.

Un error diagnóstico fácil es convertir directamente el desplazamiento normalizado en una coordenada real de pulsación y aplicar a la salida de GA los ceros de la cuerda triangular ideal de la sección 1. El motor utiliza ruido filtrado y una forma ancha limitada, no el desplazamiento triangular ideal. Su búfer se actualiza mediante un bucle de realimentación con interpolación, dispersión, amortiguación paso bajo y resonadores. Por tanto, cualquier muesca modal predicha por la fórmula ideal es una **hipótesis que probar** en GA, no un resultado de esta fixture.

### Ejercicio práctico 3

La fixture informa de desplazamientos `337`, `257` y `177` al aumentar las velocidades, mientras el pico de la forma es `1` en los tres casos. Un compañero concluye: «Los tres WAV renderizados deben tener un brillo idéntico después de igualar niveles». Indica dos razones por las que no se deduce esa conclusión.

> **Respuesta:** Primero, la forma se mueve en el búfer; picos iguales no hacen idénticas las formas completas. Segundo, la velocidad también cambia `pluck_mix`, que interviene en la expresión de brillo del renderizado, además de la amplitud del ruido filtrado y el ataque. La fixture no incluye ruido con estado, filtrado, realimentación, resonadores ni reverberación. Harían falta renderizados con niveles igualados y un espectro localizado en el tiempo o una prueba auditiva para comparar el brillo real.

## 4. Diseñar una comparación que aísle la cuestión

Supón que un usuario dice que un mi E2 más fuerte suena más brillante en la demo WASM. Empieza por la afirmación limitada que respaldan las fuentes: el código Rust fijado asigna la velocidad **al menos** a escala de excitación, desplazamiento de pulsación, mezcla de pulsación y ataque. El AudioWorklet del navegador puede usar una frecuencia de contexto diferente de la del ejemplo. Registra la frecuencia real, compilación o commit del motor, nota y velocidad, ruta de grabación, duración, formato de salida y hashes. Compara ventanas alineadas al inicio de la nota e iguala niveles antes de juzgar el equilibrio espectral; los espectros del archivo completo pueden ocultar diferencias de ataque, como explica PHY-002.

Un experimento local decisivo añadiría una **rama instrumentada o inyección de parámetros solo para pruebas** para mantener fijo el desplazamiento al variar la velocidad y, por separado, mantener fijos `pluck_mix` y los ajustes de ataque, con la misma frecuencia de muestreo y una semilla de ruido determinista cuando sea posible. Repite renderizados y guarda trazas de parámetros y salidas. Compara las intervenciones con el motor sin modificar. Si fijar el desplazamiento deja prácticamente igual el cambio medido de brillo, pierde fuerza la hipótesis simple «el desplazamiento de la posición de pulsación es la causa dominante». Si elimina la mayor parte de la diferencia con los demás controles constantes, gana respaldo. En ambos casos, elige expresamente métrica, banda de frecuencias, ventana de ataque y tolerancia antes de mirar resultados.

Una alternativa de producto más sencilla podría bastar: conservar el acoplamiento actual de velocidad y describirlo con rigor en vez de añadir un control independiente de «posición física de pulsación». Un control independiente solo es útil si un músico o un flujo de audio posterior de ComfyUI demuestra una tarea significativa que permite y si el estado extra sigue siendo componible con los controles existentes. El experimento debería guiar esa decisión. Para PHY-004 no se ejecutó una nueva compilación del motor, captura de navegador, pareja de WAV, prueba perceptiva ni modificación de interfaz.

### Ejercicio práctico 4

Describe una comparación controlada para la afirmación «el cambio del desplazamiento de pulsación domina el cambio de brillo». ¿Qué debe mantenerse constante, qué intervención debe hacerse y qué resultado debilitaría la afirmación?

> **Respuesta:** Fija revisión del motor, nota, frecuencia de muestreo, perfil, ruta de salida, duración y preferiblemente semilla de ruido; registra la traza real de parámetros. Renderiza dos velocidades con la correspondencia actual y después con el desplazamiento fijo en un índice declarado, sin cambiar las demás correspondencias de velocidad. Iguala niveles y compara una ventana de ataque y una métrica de brillo declaradas en ensayos repetidos. Si fijar el desplazamiento apenas cambia la diferencia de brillo dependiente de velocidad dentro de una tolerancia predeclarada, se debilita la afirmación de dominio. Eso no identifica por sí solo qué parámetro restante causó la diferencia.

### Ejercicio práctico 5

Un desarrollador propone exponer `pick_position = 0.25` como nuevo parámetro de API WASM porque el modelo ideal predice un cuarto armónico nulo. ¿Qué pruebas faltan para tratar ese valor de API como una coordenada física calibrada y prometer ese resultado acústico?

> **Respuesta:** La API actual acepta frecuencia y velocidad; el desplazamiento interno es una heurística. Harían falta una correspondencia definida del valor normalizado de API a la construcción de excitación, pruebas de código que demuestren independencia de la velocidad o documenten el acoplamiento, espectros renderizados controlados y pruebas auditivas en distintas notas y frecuencias de muestreo, y calibración física o perceptiva si se llama coordenada real de cuerda. La excitación ancha actual de ruido filtrado no es la liberación triangular ideal, así que no puede prometerse la anulación del cuarto armónico. Una API pública nueva compromete la compatibilidad de forma duradera y debería seguir a las pruebas de tarea y la revisión.

## Fuentes y límites

- [Fuente fijada del motor de guitarra de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs): `Engine::excite` define longitud de retardo, límites de velocidad, desplazamiento y forma de excitación; `Engine::render` combina el camino de brillo y la realimentación; `engine_note_on` es la llamada expuesta. Los cálculos se aplican a esa revisión de la fuente.
- [Fixture ejecutable de PHY-004](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/physics/phy-004/README.md): reproducción sintética y determinista de fórmulas seleccionadas. No ejecuta Rust, sintetiza audio ni prueba a un oyente.
- La fórmula ideal de desplazamiento triangular sigue el modelo de serie de senos de cuerda fija en ambos extremos de la sección 1. Se mantiene expresamente separada de la excitación por ruido filtrado de GA. No se ha completado una comparación espectral del motor, calibración física de posición de pulsación, revisión humana de la materia, prueba con estudiantes ni comprobación pública para PHY-004. El ciclo anterior del original inglés dejaba pendiente la traducción; este borrador en español requiere revisión de una persona que domine el español.
