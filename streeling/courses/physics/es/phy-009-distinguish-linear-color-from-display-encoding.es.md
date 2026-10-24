---
module_id: phy-009-distinguish-linear-color-from-display-encoding
department: physics
course: "Distinguir el color lineal de la codificación de visualización"
level: intermediate
prerequisites: ["vc-005-craft-details-through-blender-to-godot"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguir el color lineal de la codificación de visualización

> **Alcance del borrador.** Código público de renderizado de GA fijado a una revisión, cálculos de referencia de funciones de transferencia y una imagen digital de control original. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML del curso desplegado. No se ejecutaron un shader, una importación de [Blender](https://docs.blender.org/manual/en/4.5/render/color_management.html)/[Godot](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/shading_language.html#using-source-color), un fotograma de GPU, una prueba con pantalla calibrada ni un ensayo humano de apariencia.

## La pregunta del proyecto

Una superficie tejida o una pared esculpida cambia de apariencia cuando un recurso pasa de un entorno a otro. Antes de cambiar su geometría o generador de texturas, determina qué valores representan color codificado, coordenadas de luz lineal y datos. El [script público de horneado de texturas de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/textures/bake_blender.py) declara por separado el albedo sRGB y los mapas empaquetados de datos no cromáticos. Su [modelo Lego](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs#L87-L94) declara los colores de las cajas como RGB lineal. Son contratos de entrada distintos en el commit público de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`.

El [borrador fechado de Color 4 del W3C](https://www.w3.org/TR/2026/CRD-css-color-4-20261020/#color-conversion-code) proporciona la referencia sRGB definida por tramos que se usa a continuación. Este documento en desarrollo es una referencia para nuestros cálculos, no una certificación del pipeline de renderizado del proyecto. Los ejemplos se mantienen en coordenadas no negativas de 0 a 1.

## 1. Declarar la coordenada antes de interpretar su valor

Para un canal codificado C, la referencia da `L=C/12.92` cuando `C<=0.04045`; en caso contrario, `L=((C+0.055)/1.055)^2.4`. Así, 0.5 codificado corresponde a 0.21404114048223255 lineal. Un valor lineal de 0.5 se codifica como 0.7353569830524495. El número 0.5 por sí solo no identifica cuál de esos valores se pretendía representar.

Las coordenadas RGB de luz lineal permiten la aritmética de suma de luz del modelo de color elegido. No son luminancia medida en cd/m², el espectro de reflectancia física de un material ni el juicio de brillo de un participante. Una afirmación fotométrica real necesita la medición pertinente de la pantalla o de la escena.

### Ejercicio 1: interpretar el mismo número dos veces

Compara 0.5 codificado con 0.5 lineal. Indica la coordenada lineal de referencia del primero y la coordenada codificada del segundo. ¿Puede alguno de esos números por sí solo establecer una luminancia de pantalla medida?

> **Respuesta:** 0.5 codificado se decodifica como aproximadamente 0.21404114048223255; 0.5 lineal se codifica como aproximadamente 0.7353569830524495. Ninguno establece por sí solo una luminancia de pantalla medida. Harían falta el sistema de coordenadas y una medición física real.

## 2. Elegir el dominio en el que combinar la luz

Los [cálculos fijados](../../../../code/streeling/evidence/color-contract-2026-10-22/transfer-calculations.json) promedian negro y blanco en dos dominios. Promediar sus extremos codificados da 0.5 codificado. Promediar los extremos lineales correspondientes da 0.5 lineal, que se codifica como aproximadamente 0.7353569830524495. Con la cuantización declarada de 8 bits por redondeo al valor más cercano, se convierten en los bytes 128 y 188.

La cuantización importa: el byte 128 se decodifica como aproximadamente 0.21586050011389926, mientras que el byte 188 se decodifica como aproximadamente 0.5028864580325687. No son exactamente iguales a los valores de referencia sin cuantizar. El panel superior de la imagen ilustra estas elecciones numéricas creadas para el curso; no es una comparación de luminancia calibrada.

![Muestras de puntos medios y control contextual de objetivos idénticos creados para el curso](https://raw.githubusercontent.com/spareilleux/learn/50a9e9d5604dfe60c37f4a52d6bfa5e2ca376e63/code/streeling/evidence/color-contract-2026-10-22/color-context-controls.png)

La figura compartida usa etiquetas en inglés; el panel superior contrasta los dos dominios de cálculo, mientras que el inferior sirve para otra tarea contextual.

### Ejercicio 2: auditar un punto medio

Un worker promedia negro y blanco directamente en coordenadas codificadas e informa del byte 128. Otro los combina en coordenadas lineales y vuelve a codificar, informando de 188. ¿Cuál sigue la mezcla declarada de luz lineal? ¿Por qué no debe afirmarse que su resultado cuantizado y decodificado es exactamente 0.5?

> **Respuesta:** El byte 188 sigue la mezcla declarada de luz lineal. Procede de codificar 0.5 lineal y redondear. Decodificar el byte cuantizado da aproximadamente 0.5028864580325687 en lugar de exactamente 0.5; la cuantización finita cambia el valor representado.

## 3. Examinar la aproximación real del proyecto

El [shader de material](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L587-L655) de la revisión fijada aplica una potencia de 2.2 al albedo muestreado en las rutas de hormigón, fachada y máquina. Para 0.5 codificado, esa potencia da 0.217637640824031, que difiere de la referencia en aproximadamente 0.003596500341798453. Es una aproximación, no la función exacta definida por tramos.

En cambio, la ruta de revestimiento inspeccionada usa el RGB muestreado en una expresión tonal ponderada sin esa misma expresión de potencia. No generalices una política de conversión a todos los materiales. Son observaciones del código; ninguna comparación nueva de renderizados establece la consecuencia perceptiva ni un resultado artístico preferible.

### Ejercicio 3: acotar una afirmación sobre el código

Calcula la potencia 2.2 de 0.5 y compárala con la referencia. ¿Puede una persona revisora concluir que todos los materiales de BRUTAL usan la misma conversión o que la diferencia numérica resulta visualmente molesta?

> **Respuesta:** La potencia da aproximadamente 0.217637640824031, unos 0.003596500341798453 por encima de la referencia. La expresión del revestimiento difiere, así que no está respaldada una política uniforme. La diferencia numérica por sí sola no establece ningún juicio del observador sobre visibilidad o calidad.

## 4. No trasladar la exposición de un lado a otro de una curva no lineal

El [shader de composición](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L1186-L1228) llama aces a su curva racional limitada. El cálculo didáctico evalúa esa curva escalar aislada, sin afirmar que sea una transformación completa de gestión del color ACES. Para una entrada 0.25 y una exposición 2, aplicar la exposición antes de la curva da aproximadamente 0.6163069544364508. En cambio, duplicar el valor 0.25 ya transformado por la curva da aproximadamente 0.7482219061166429.

El código real también combina bloom, ajuste RGB, una viñeta, potencia de salida 1/2.2 y grano. La curva aislada no predice un píxel capturado completo. Mantén explícitas esas etapas omitidas al comparar un cálculo simplificado con un resultado de la aplicación.

### Ejercicio 4: conservar el orden de las operaciones

Para la entrada didáctica 0.25 y la exposición 2, compara exposición antes de la curva con curva antes de duplicar. ¿Son intercambiables? ¿Reproduce alguno de los resultados escalares todo el shader de composición?

> **Respuesta:** Los resultados son aproximadamente 0.6163069544364508 y 0.7482219061166429, así que las operaciones no son intercambiables. Ninguno reproduce toda la composición: este control escalar omite bloom, ajuste RGB, viñeta, codificación de salida y grano.

## 5. Verificar conversiones sin inventar un resultado de importación

Las pruebas comprueban los 256 valores de byte mediante decodificación, codificación y la cuantización declarada; cada uno recupera su byte original. Esa ida y vuelta finita verifica esos cálculos, no la fidelidad de un renderizador ni la preferencia de un usuario. Una prueba de importación sigue necesitando un espacio de origen declarado, funciones de datos o color de los canales, política de conversión, transformación de salida o visualización y un resultado observado en el entorno de destino.

[VC-010](../../visual-computing/en/vc-010-preserve-packed-texture-channel-contracts.md) sigue el mapa empaquetado, donde aplicar una decodificación de color cambia valores que deberían ser datos. [COG-006](../../cognitive-science/en/cog-006-separate-pixel-tests-from-appearance-judgments.md) separa las comprobaciones de píxeles de las preguntas de apariencia.

### Ejercicio 5: rechazar una verificación demasiado amplia

Las 256 comprobaciones de ida y vuelta de referencia pasan. Un worker declara validada visualmente la transferencia del material de Blender a Godot. ¿Qué ha pasado realmente y qué pruebas faltan a continuación?

> **Respuesta:** Ha pasado la comprobación finita de referencia de decodificación, codificación y cuantización. No se realizaron una importación de Blender a Godot, un renderizado de destino, una comparación en pantalla calibrada ni un juicio de observador. Para esa afirmación más amplia siguen haciendo falta una configuración declarada del entorno y un resultado de transferencia observado.

## Tarea del estudiante con acceso a las fuentes

Completa la [tarea preparada](../../../../code/streeling/evidence/color-contract-2026-10-22/learner-task.md) usando la referencia y el código fijados. Distingue conversión matemática, inspección del shader, salida real del entorno y revisión humana.
