---
module_id: sem-007-preserve-the-meaning-of-a-bend-angle
department: semiotics
course: "Conservar el significado de un ángulo de doblado"
level: intermediate
prerequisites: ["sem-006-preserve-orientation-across-scene-frames", "phy-011-compute-bend-length-on-a-declared-neutral-layer"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar el significado de un ángulo de doblado

> **Alcance del borrador.** Lectura de código FOLD/IX fijado a una revisión y cálculos didácticos de ángulos y capas de referencia. Quedan pendientes las revisiones humanas técnica, artesanal, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se ejecutaron un adaptador de formato, un comprobador completo, una herramienta CAD, una escena ni un doblado físico.

## La pregunta del proyecto

Dos agentes intercambian un número llamado «ángulo de doblado». Uno se refiere a la desviación con signo respecto al estado plano; el otro, a un ángulo interior sin signo entre pestañas. Por tanto, números iguales pueden prescribir geometrías distintas. Una descripción componible necesita el significado de la cantidad antes de cualquier aritmética o coincidencia de nombres de campo.

La [especificación FOLD de la revisión fijada](https://raw.githubusercontent.com/edemaine/fold/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md) define `edges_foldAngle` como desviación del plano, en grados de -180 a 180, positiva para pliegues valle y negativa para pliegues montaña. La [rama seleccionada de validación de IX](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/fold.rs#L239-L261) comprueba intervalo angular y signos de asignación. Es semántica del código, no una conversión recién ejecutada a instrucciones de conformado de metal.

## 1. Traducir qué representa el ángulo

Para una sección plana simple didáctica, define el ángulo interior mediante `alpha=180-abs(delta)`, donde `delta` es la desviación con signo en grados. Es nuestra convención explícita para comparar los ejemplos, no una correspondencia universal para cualquier campo CAD o ensamblaje.

Un ángulo interior de 120 grados corresponde por tanto a una magnitud de desviación de 60 grados. Bajo el radio neutro de 4.8 mm de [PHY-011](../../physics/en/phy-011-compute-bend-length-on-a-declared-neutral-layer.md), el arco correcto es `4.8*pi/3=1.6*pi` mm. Interpretar 120 como desviación daría en cambio `3.2*pi` mm, el doble. La simetría de un ejemplo de 90 grados puede ocultar ese error, así que usa un control asimétrico.

### Ejercicio 1: rechazar un número igual engañoso

Convierte el ángulo interior 120 en magnitud de desviación bajo la convención declarada. Calcula el arco neutro correcto y el resultado de interpretar erróneamente 120 como desviación.

> **Respuesta:** La magnitud de desviación es 60 grados, o `pi/3` radianes. El arco correcto es `1.6*pi` mm; la lectura errónea da `3.2*pi` mm, un factor de 2. La conversión requiere la convención angular declarada en lugar de un nombre de campo compartido.

## 2. Conservar el signo aunque la longitud use magnitud

Las desviaciones con signo +60 y -60 tienen la misma magnitud y producen la misma longitud desarrollada de doblez `1.6*pi` en este modelo. No tienen el mismo significado de asignación FOLD. El código seleccionado espera un valor positivo para V y uno negativo para M. También requiere cero en aristas F, U y B.

Sustituir todos los ángulos por su valor absoluto conservaría esas dos longitudes calculadas, pero cambiaría o invalidaría el ejemplo montaña. A la inversa, usar directamente un ángulo negativo con signo como longitud desarrollada produciría una longitud negativa. Conserva el estado con signo y deriva la longitud de su magnitud como una operación nombrada por separado.

### Ejercicio 2: separar estado de longitud derivada

¿Cuáles de V con +60, M con -60 y M con +60 pasan la condición de signo inspeccionada? ¿Qué información se pierde conservando solo la longitud positiva del arco?

> **Respuesta:** V con +60 y M con -60 pasan la condición de signo seleccionada; M con +60 falla. La longitud positiva común `1.6*pi` no conserva si el pliegue era valle o montaña. Superar una rama numérica no es aceptación geométrica completa ni un veredicto de fabricación.

## 3. Convertir unidades antes de multiplicar

La longitud de arco requiere magnitud angular en radianes. Sesenta grados se convierten en `pi/3`; multiplicar 4.8 mm por ese valor da `1.6*pi`, aproximadamente 5.026548246 mm. Multiplicar en cambio 4.8 por el recuento bruto de grados 60 da 288 mm, un factor `180/pi`, aproximadamente 57.295779513, demasiado grande.

El tipo «número» por sí solo no distingue estas representaciones. Un valor llamado ángulo necesita unidad y convención en el límite, y un sufijo mostrado no lo convierte por sí mismo. Es una disciplina propuesta de traspaso, no un contrato de adaptador implementado.

### Ejercicio 3: diagnosticar un error de unidades

Un adaptador usa directamente el valor de grados 60 en una expresión de arco basada en radianes. Indica longitud incorrecta, correcta y factor de error. ¿Corregiría el número añadir «grados» junto a la salida?

> **Respuesta:** La longitud incorrecta es 288 mm; la correcta es `1.6*pi`, aproximadamente 5.026548246 mm. El factor es `180/pi`, aproximadamente 57.295779513. Una etiqueta no realiza la conversión necesaria ni hace correcta la longitud equivocada.

## 4. No mezclar cantidades sin relación que compartan símbolo

En la [referencia de reglas de chapa de Fusion](https://help.autodesk.com/cloudhelp/ENU/Fusion-Sheet-Metal/files/SM-RULES-REF.htm), la razón de desplazamiento neutro es adimensional. La llamamos `k` y estipulamos 0.4. La curvatura de Gauss, llamada aquí `K_G`, es en cambio el producto de dos curvaturas principales y tiene unidades de inverso de longitud al cuadrado. Un cilindro puede tener `K_G=0` mientras este doblez didáctico de espesor finito usa `k=0.4`.

Estas cantidades también responden a preguntas distintas. Una sitúa una capa neutra de referencia en una regla de doblado elegida. La otra describe geometría superficial local. Ninguna puede copiarse al campo de la otra solo porque un documento llame a ambas «K».

### Ejercicio 4: interpretar el cero

Un agente ve curvatura de Gauss cero en un cilindro y sustituye el factor de desplazamiento neutro 0.4 por cero. ¿Por qué es inválida la sustitución y qué unidades distinguen los dos campos?

> **Respuesta:** Sustituye una cantidad física o geométrica distinta. El factor de desplazamiento neutro es adimensional; la curvatura de Gauss tiene unidades como `mm^-2`. Curvatura cero no sitúa la capa neutra en la superficie interior ni invalida el factor 0.4 estipulado por separado.

## 5. Separar metadatos conservados de significado utilizado

Los [tipos de marco y modelo de IX de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/fold.rs#L82-L108) conservan matrices opcionales de ángulos y otros campos arbitrarios. Conservar como datos una anotación adicional de regla física no demuestra que el validador seleccionado la use para calcular longitud desarrollada de doblez. Su [ADR de espesor](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md#L30-L34) excluye explícitamente rechazos por radio de doblado y movimiento.

Un pequeño registro orientativo podría conservar revisión del código, identidad de arista, desviación con signo en grados y asignación, convención de ángulo interior, unidad física de longitud, radio interior, espesor, hipótesis de desplazamiento neutro y radianes y longitud derivados. Es una alternativa didáctica a un número ambiguo, no un esquema ratificado ni un nuevo DSL de fabricación. Pueden bastar formatos existentes con campos documentados; incluir más anotaciones también cuesta trabajo de validación y migración.

### Ejercicio 5: acotar un traspaso satisfactorio

Un agente dice «el campo sobrevivió al JSON, así que se verificó el modelo posterior de doblado». Sustituye la afirmación e indica las pruebas necesarias para superar la conservación de metadatos.

> **Respuesta:** Puede que el campo se haya conservado como datos. Para verificar su significado, identifica la implementación consumidora y su correspondencia de campos, unidades y convenciones, prueba ángulos asimétricos y signos frente a objetivos conocidos y distingue las hipótesis del modelo del comportamiento calibrado del material. Conserva identidad del código y de la arista. Ni el almacenamiento de campos arbitrarios ni este ejemplo orientativo establecen un adaptador físico implementado ni fabricación.

El [registro de ángulos](../../../../code/streeling/evidence/bend-development-2026-10-22/angle-meanings.json) separa comprobaciones numéricas predichas por el código de conversiones didácticas. [FUT-006](../../futurology/en/fut-006-test-a-no-stretch-craft-automation-claim.md) usa esa distinción al evaluar una futura afirmación de automatización.
