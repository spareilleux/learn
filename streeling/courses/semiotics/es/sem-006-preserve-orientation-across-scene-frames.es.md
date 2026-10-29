---
module_id: sem-006-preserve-orientation-across-scene-frames
department: semiotics
course: "Conservar la orientación entre los sistemas de referencia de una escena"
level: intermediate
prerequisites: ["sem-004-face-identity-under-reindexing", "cs-014-compose-brutal-scene-descriptions"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar la orientación entre los sistemas de referencia de una escena

> **Alcance del borrador.** Código de BRUTAL en una revisión fija, comprobaciones reales de matrices y validación en CPU y cálculos sobre un triángulo creado para el ejercicio. Siguen pendientes las revisiones humanas técnica, lingüística y pedagógica, así como la verificación del HTML del curso desplegado. No se realizó ninguna importación en Blender/Godot, prueba de cámara, ejecución en GPU ni ensayo de fabricación.

## La pregunta del proyecto

Un agente artesanal etiqueta un lado de un componente como «X positivo» o «frente». Otro agente refleja la pieza para una escena. ¿La etiqueta sigue identificando el mismo lado del material, la misma dirección global o la cara que verá una cámara? Esas interpretaciones pueden discrepar sin que el componente pierda su identidad.

[SEM-004](sem-004-face-identity-under-reindexing.md) conserva las referencias al material al cambiar la numeración. Aquí el cambio es espacial: la [convención de referencia de BRUTAL en la revisión inspeccionada](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs) establece metros, Y positivo hacia arriba, X positivo hacia el este y Z positivo hacia el sur. Los nombres locales de las caras y las descripciones según ejes globales deben interpretarse en ese contexto, en lugar de tratarse como cadenas intercambiables.

## 1. Nombrar el objeto y la interpretación

Usa el lado local X positivo de un sólido creado para el ejercicio. Su referencia al material identifica el lado elegido; su normal local expresa la dirección de ese lado antes de colocarlo. Una normal global describe la dirección transformada. El orden de los vértices del triángulo describe una convención de orientación, mientras que la visibilidad depende además de la cámara, el material y las reglas del anfitrión. Una palabra para el usuario como «frente» no determina todos esos campos.

En la colocación compuesta de [PHY-008](../../physics/en/phy-008-keep-surface-normals-perpendicular.md), la misma cara local X positiva tiene la normal global `(1/sqrt5,0,-2/sqrt5)`. Llamarla «X positivo global» cambiaría, por tanto, la interpretación. Conservar la selección del material no exige fingir que su dirección global sigue fija.

### Ejercicio práctico 1: corregir una etiqueta de lado ambigua

Un agente afirma: «El frente no cambia tras la colocación». ¿Qué distinciones faltan? Reescribe la afirmación para el lado X positivo creado para el ejercicio.

> **Respuesta:** Omite el lado del material seleccionado, el sistema de referencia de origen, la transformación, la dirección resultante y el significado de frente. Una afirmación acotada es que el mismo lado local X positivo creado para el ejercicio sigue seleccionado tras la colocación declarada, con normal global `(1/sqrt5,0,-2/sqrt5)`. No se probaron ni la visibilidad desde la cámara ni la clasificación de cara frontal del anfitrión. La identidad de la selección no implica una dirección global fija.

## 2. Una reflexión cambia la orientación

Toma el triángulo didáctico con vértices `(1,-1,-1)`, `(1,1,-1)` y `(1,-1,1)`. El producto vectorial ordenado de sus aristas es `(4,0,0)`, alineado con el lado exterior X positivo elegido. Refleja X manteniendo el orden de los vértices. Todos los vértices pasan a X igual a -1, pero su producto vectorial ordenado sigue siendo `(4,0,0)`. La dirección exterior transformada es X negativo, así que el orden conservado y esa interpretación exterior dejan de coincidir.

Intercambiar los dos últimos índices de vértices cambia el producto vectorial a `(-4,0,0)`. Esto recupera la coincidencia para la convención exterior indicada. No demuestra la clasificación de caras frontales de un renderizador concreto. El [registro de orientación](../../../../code/streeling/evidence/scene-frames-2026-10-22/orientation-controls.json) conserva el triángulo didáctico, el determinante y el razonamiento sobre productos vectoriales por separado de las observaciones de matrices nativas.

### Ejercicio práctico 2: seguir el triángulo reflejado

Indica el producto vectorial original, el obtenido tras reflejar X sin cambiar el orden y el obtenido tras intercambiar los dos últimos índices. ¿Qué dirección se estipuló como lado exterior reflejado?

> **Respuesta:** Son `(4,0,0)`, `(4,0,0)` y `(-4,0,0)`, respectivamente. El lado exterior reflejado es X negativo. La reflexión cambia la relación entre el orden inalterado de los vértices y la orientación exterior estipulada; no borra la referencia al material ni constituye una observación de cámara.

## 3. Dos cambios de signo no tienen por qué ser una reflexión

Los controles de matrices nativas dan determinante -1 para una reflexión solo en X, +1 para cambios simultáneos de signo en X/Z y +1 para una guiñada de 180 grados. Los signos positivo y negativo del determinante distinguen la conservación y la inversión de la orientación para estas aplicaciones invertibles. El determinante cero es otro caso, singular; no puede clasificarse como un cambio invertible de sistema de referencia.

La [colocación inspeccionada de Colossus](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L2273-L2278) incluye una guiñada de pi. Invierte X y Z a la vez mediante una rotación. Llamarla conversión de quiralidad solo porque X cambia de signo describiría mal la aplicación. Los cálculos nativos de guiñada en float32 se comprueban con tolerancia `1e-5`, sin exigir que su seno a 180 grados se represente como cero exacto.

### Ejercicio práctico 3: distinguir rotación, reflexión y colapso

Clasifica según su determinante la escala solo en X `(-1,1,1)`, la escala con dos signos negativos `(-1,1,-1)` y la escala X cero `(0,1,1)`. ¿Cuál puede describirse como el mismo efecto de rotación que conserva la orientación que una guiñada de 180 grados?

> **Respuesta:** Sus determinantes son -1, +1 y 0. La primera invierte la orientación; la segunda la conserva y tiene el mismo efecto ideal sobre los ejes que una guiñada de 180 grados; la tercera colapsa una dimensión y no tiene inversa. Un cambio de signo en una coordenada concreta no basta para clasificar toda la transformación.

## 4. Interpretar la convención del anfitrión receptor

La [referencia oficial de SurfaceTool de Godot](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html) establece un orden horario de vértices para las caras frontales de los modos de primitivas triangulares. Es una convención del anfitrión que debe consultarse durante una prueba real del adaptador. No permite que este ejemplo CPU deduzca la visibilidad frontal o posterior sin las condiciones completas de geometría, cámara y material. Hay que conciliar explícitamente la dirección matemática del producto vectorial y la regla de caras frontales.

La [ruta inspeccionada de instancias para rayos de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L4520) desactiva el descarte de triángulos según su orientación. Ese ajuste en el código no demuestra que todas las otras rutas usen la misma política ni que exista compatibilidad general con geometría reflejada o singular. No se ejecutó ningún anfitrión para esta lección.

### Ejercicio práctico 4: acotar la afirmación sobre el adaptador

Un agente cambia el signo de una normal, lee la convención de Godot y afirma que la geometría reflejada se importa correctamente. ¿Qué sigue faltando?

> **Respuesta:** Faltan el orden real de los vértices e índices convertidos, las normales, la transformación completa, los ajustes de primitivas, materiales y descarte del receptor y una observación controlada en el anfitrión. Cambiar una normal no reescribe por sí solo los índices de los triángulos, y una afirmación de la documentación no ejecuta una importación. Prueba el adaptador real con controles conocidos de rotación y reflexión antes de afirmar que la importación o la visibilidad son correctas.

## 5. Transmitir el significado necesario para la siguiente decisión

Una transferencia útil puede conservar la referencia seleccionada al material, el sistema local de referencia, la transformación completa, la convención exterior elegida, el orden de índices y la regla prevista del anfitrión receptor. Son requisitos de información propuestos para un adaptador, no un nuevo esquema implementado. La objeción es que transmitir todos los campos puede ser innecesario para una tarea que solo encuadra una cámara alrededor de los límites. La alternativa más sencilla es declarar esa tarea acotada y conservar únicamente los datos suficientes, sin convertirlos en una garantía de orientación de superficies.

El [registro nativo](../../../../code/streeling/evidence/scene-frames-2026-10-22/native-execution.json) documenta llamadas a matrices y al validador sobre borradores didácticos. No demuestra un servicio persistente de identificadores de lados ni una exportación de escena. [INF-006](../../information-theory/en/inf-006-know-what-scene-bounds-forget.md) muestra por qué un resumen de límites puede seguir siendo útil aunque pierda la geometría interior.

### Ejercicio práctico 5: redactar una transferencia que tenga en cuenta la orientación

Redacta una breve transferencia para el triángulo didáctico reflejado. Incluye una condición en la que su información sería insuficiente para la siguiente tarea.

> **Respuesta:** Conserva la referencia al lado local X positivo del material, la transformación de reflexión en X con determinante -1, la dirección exterior reflejada X negativa y el orden real de los índices, indicando si se intercambiaron los dos últimos. Marca la importación en el anfitrión y la visibilidad como no probadas. Estos campos siguen sin especificar UV, tangentes de sombreado, materiales ni todas las reglas del anfitrión; una tarea que dependa de ellos necesita pruebas adicionales, no una afirmación infundada de compatibilidad.
