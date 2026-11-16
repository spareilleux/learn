---
module_id: vc-010-preserve-packed-texture-channel-contracts
department: visual-computing
course: "Conservar los contratos de canales de las texturas empaquetadas"
level: intermediate
prerequisites: ["vc-005-craft-details-through-blender-to-godot", "phy-009-distinguish-linear-color-from-display-encoding"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar los contratos de canales de las texturas empaquetadas

> **Alcance del borrador.** Código público del productor y consumidor fijado a una revisión, inspección de dos PNG públicos existentes y un cálculo de texel creado para el curso. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML del curso desplegado. No se observaron un nuevo horneado, generación con [ComfyUI](https://docs.comfy.org/), ejecución de shader o importación ni resultados de desplazamiento geométrico.

## La pregunta del proyecto

Un agente exporta una superficie elaborada como «una textura RGBA». Esa descripción omite lo que significa cada canal. El [script público de horneado de texturas de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/textures/bake_blender.py) empaqueta dos componentes de mapa de normales, rugosidad y un indicador de altura. Su [script de generación](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/textures/generate_comfyui.py) describe un flujo previo de [ComfyUI](https://docs.comfy.org/); ninguno de los dos scripts se ejecutó para esta lección. Todas las observaciones del proyecto usan el commit público de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`.

[PHY-009](../../physics/en/phy-009-distinguish-linear-color-from-display-encoding.md) estableció por qué las coordenadas de color necesitan una codificación declarada. Los datos empaquetados necesitan otro contrato: los mismos cuatro números almacenados pueden no tener significado de color ni de transparencia.

## 1. Anotar las funciones de los canales del productor

El script declara la salida empaquetada como Non-Color, mientras declara sRGB la salida de albedo. Su orden de empaquetado es explícito:

| Canal | Valor del productor | Interpretación prevista |
| --- | --- | --- |
| R | normal X horneada | componente direccional codificado |
| G | normal Y horneada | componente direccional codificado |
| B | primer canal de rugosidad horneada | datos de rugosidad |
| A | RGB ponderado del búfer de albedo | indicador de altura |

El campo alfa no es opacidad y el azul no es la normal Z. Se omite la normal Z horneada. La altura se deriva de valores de imagen; no implica grosor físico, escala de desplazamiento ni topografía medida. Las [indicaciones de gestión del color de Blender 4.5](https://docs.blender.org/manual/en/4.5/render/color_management.html) también distinguen los datos no cromáticos de normales o desplazamiento de las imágenes de color. Esta lección no supone cuál es la transformación de visualización predeterminada actual de un entorno.

### Ejercicio 1: rechazar el importador genérico equivocado

Un importador trata RGB como un vector normal completo y alfa como opacidad. ¿Qué dos significados de canal entran en conflicto con este productor? ¿Contiene el mapa empaquetado la normal Z horneada?

> **Respuesta:** El azul es rugosidad, no normal Z; alfa es un indicador de altura, no opacidad. El productor no empaqueta la normal Z horneada. Un importador genérico de normales y opacidad impondría otro contrato y no puede suponerse que conserve este mapa.

## 2. Decodificar datos normalizados sin una transformación de color

El [texel creado para el curso](../../../../code/streeling/evidence/color-contract-2026-10-22/packed-texel-calculations.json) tiene bytes 128, 128, 128 y 64. Dividir entre 255 da aproximadamente 0.5019607843137255 para cada canal RGB y 0.25098039215686274 para alfa. Decodificar RG con signo mediante `2*v-1` da aproximadamente 0.0039215686274509665 por componente. El byte 128 está cerca del punto medio con signo, pero no exactamente en él.

Aplicar primero la decodificación de color sRGB definida por tramos a RGB daría aproximadamente 0.21586050011389926 y RG con signo de aproximadamente -0.5682789997722015. Eso cambia la interpretación de los datos. No es una corrección de visualización inofensiva de una fotografía en color.

### Ejercicio 2: detectar datos transformados

Decodifica el byte rojo didáctico 128 como dato normalizado con signo. Compara con decodificarlo primero como sRGB. ¿Debe el byte alfa 64 hacer automáticamente que el material sea parcialmente transparente?

> **Respuesta:** La decodificación directa de datos normalizados da aproximadamente 0.0039215686274509665; decodificar primero el color da aproximadamente -0.5682789997722015 tras la conversión al intervalo con signo. Alfa es el indicador de altura según este contrato, así que el byte 64 no declara transparencia.

## 3. Seguir al consumidor, no solo al nombre del archivo

El [shader de material](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L587-L655) de la revisión fijada lee RG como una señal de relieve con signo y B como rugosidad en las rutas examinadas de hormigón, fachada, revestimiento y máquina. Esas rutas no leen el alfa empaquetado como desplazamiento de altura ni reconstruyen la normal Z ahí. No describas su señal de relieve como una reconstrucción completa y sin pérdidas de una normal unitaria.

La fachada usa el valor azul directamente. El hormigón, ignorando su ajuste separado de lluvia para este control, transforma el azul mediante `0.75+0.2*B`. Por tanto, el azul didáctico da aproximadamente 0.850392156862745 para esa expresión del hormigón. Una decodificación sRGB previa incorrecta daría aproximadamente 0.7931721000227798. La interpretación de parámetros y la transformación específica del material son etapas distintas.

### Ejercicio 3: distinguir conservación de uso

El indicador de altura alfa se conserva en el PNG. ¿Establece eso que el shader examinado desplaza geometría? Calcula la expresión de rugosidad del hormigón para el azul didáctico bajo el control sin lluvia declarado.

> **Respuesta:** No. Los datos almacenados no prueban que el consumidor los utilice; las rutas examinadas no leen el alfa empaquetado para desplazamiento. La expresión sin lluvia da aproximadamente 0.850392156862745. Ese valor aislado no es un renderizado de material observado ni una salida completa afectada por lluvia.

## 4. Comprobar por separado los metadatos del artefacto real

La [inspección de archivos existentes](../../../../code/streeling/evidence/color-contract-2026-10-22/public-texture-inspection.json) lee los PNG de albedo y empaquetado de hormigón de la revisión fijada. Ambos son archivos de 512 por 512, RGBA y 8 bits, y ambos contienen bloques sRGB, gAMA y cHRM. Por tanto, los metadatos de color del archivo empaquetado no comunican el contrato de datos Non-Color declarado por el script.

Esta discrepancia es una prueba que debe conservarse. No demuestra que ese script y entorno exactos generaran el archivo comprobado, que un entorno concreto ya haya decodificado los valores como color ni que todos los recursos del proyecto compartan los mismos metadatos. El cargador BRUTAL inspeccionado lee los bytes de píxeles admitidos sin interpretar esos bloques de color; otros importadores pueden tener políticas distintas. Una extensión de archivo o etiqueta por sí sola no establece la semántica de los canales.

### Ejercicio 4: conciliar una declaración con un archivo

El script declara Non-Color, pero el PNG empaquetado de la revisión fijada contiene un bloque sRGB. ¿Puede un agente suponer un horneado nuevo correcto o eliminar silenciosamente la discrepancia de su traspaso? Enuncia la observación acotada.

> **Respuesta:** No. Conserva que el archivo empaquetado inspeccionado de 512 por 512, RGBA y 8 bits tiene metadatos de color mientras el script declara una salida no cromática. No se establecieron un horneado nuevo ni la historia exacta de generación. La interpretación del destino debe probarse en lugar de inferirse solo de la declaración.

## 5. Preparar una comprobación de transferencia específica del entorno

La [documentación de shaders de Godot 4.6](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/shading_language.html#using-source-color) distingue las texturas de color sRGB que usan `source_color` de los datos de normales, rugosidad y altura. Sus indicaciones específicas del renderizador importan; esto no prueba que se haya probado una importación concreta. Aplicar a ciegas una indicación estándar de mapa de normales a todo este mapa empaquetado también ignoraría que el azul contiene rugosidad.

Un paquete de transferencia propuesto debería identificar la revisión del recurso, las funciones por canal, los intervalos numéricos, la política de color o datos y las transformaciones del consumidor. Prueba un texel conocido tras importar y verifica de forma independiente el canal previsto antes de juzgar toda la superficie. Añadir un canal de altura a un archivo no implementa desplazamiento geométrico, y reconocer el contrato no autoriza un cambio no probado del shader de producción.

### Ejercicio 5: elegir la siguiente acción verificable

Un agente propone tratar toda la textura empaquetada como albedo con `source_color` y después declara terminada la transferencia de la superficie. ¿Cuál es la prueba de importación discriminante más pequeña y qué sigue sin realizarse?

> **Respuesta:** Usa un texel empaquetado conocido y verifica que el destino conserve sus valores de datos y las funciones declaradas de RG/B/A bajo una política deliberada de importación y muestreo. Decodificar como color toda la textura de datos no es el contrato declarado. Aquí siguen sin realizarse la importación real en el entorno, el uso por el shader, el desplazamiento, la evaluación de calidad del material renderizado y los resultados de los estudiantes.

## Tarea del estudiante con acceso a las fuentes

Completa la [tarea preparada](../../../../code/streeling/evidence/color-contract-2026-10-22/learner-task.md) siguiendo un texel por el productor, los metadatos almacenados y el consumidor previsto. Mantén visible la discrepancia de metadatos y propón una comprobación concreta en el entorno de destino.
