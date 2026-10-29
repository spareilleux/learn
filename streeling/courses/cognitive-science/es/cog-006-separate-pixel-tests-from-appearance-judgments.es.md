---
module_id: cog-006-separate-pixel-tests-from-appearance-judgments
department: cognitive-science
course: "Separar las pruebas de píxeles de los juicios de apariencia"
level: intermediate
prerequisites: ["phy-009-distinguish-linear-color-from-display-encoding"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separar las pruebas de píxeles de los juicios de apariencia

> **Alcance del borrador.** Un control digital original, comparaciones exactas de píxeles, inspección del código público de captura fijado a una revisión y lectura de una investigación primaria de percepción. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML del curso desplegado. No participó ningún observador, no se midió la luminancia de ninguna pantalla ni se reprodujo ningún experimento de percepción citado.

## La pregunta del proyecto

Un agente compara una captura de una escena de superficies elaboradas con su textura de origen y dice: «los colores coinciden». Eso podría significar bytes coincidentes, coordenadas interpretadas coincidentes, brillo aparente similar o reflectancia sugerida del material similar. Son preguntas distintas. [PHY-009](../../physics/en/phy-009-distinguish-linear-color-from-display-encoding.md) estableció la distinción de coordenadas; esta lección especifica qué puede y qué no puede responder una prueba de píxeles.

El [estudio primario de 2026 de Lovell y sus colegas](https://pmc.ncbi.nlm.nih.gov/articles/PMC12876641/) examina respuestas de brillo y claridad con señales manipuladas en un estímulo de bloques ajedrezados. Su resumen e introducción motivan la distinción entre intensidad de luz percibida y reflectancia superficial inferida. No copiamos su estímulo ni tratamos nuestro control más sencillo de dos entornos como una reproducción, un efecto medido o una predicción de la respuesta de todos los observadores.

## 1. Plantear con precisión la pregunta sobre píxeles

El panel inferior de la imagen original contiene dos cuadrados objetivo de 160 por 160. Cada objetivo contiene 25600 píxeles con bytes RGB 128, 128, 128. El entorno izquierdo tiene valor de byte 32 y el derecho 224. La [auditoría de píxeles](../../../../code/streeling/evidence/color-contract-2026-10-22/figure-pixel-audit.json) vincula coordenadas de recorte en intervalos semiabiertos, bytes de imagen, hashes coincidentes de recortes objetivo y la interpretación sRGB etiquetada.

![Controles de puntos medios y de contexto con objetivos idénticos creados para el curso](https://raw.githubusercontent.com/spareilleux/learn/50a9e9d5604dfe60c37f4a52d6bfa5e2ca376e63/code/streeling/evidence/color-contract-2026-10-22/color-context-controls.png)

La figura compartida tiene etiquetas en inglés. El panel superior ilustra la aritmética de coordenadas; el inferior ofrece bytes objetivo iguales en contextos distintos. Los objetivos son regiones digitales verificadas, no salidas de luz medidas de la pantalla del usuario.

### Ejercicio 1: definir la región de comparación

¿Cuántos píxeles tiene cada objetivo? ¿Qué establece la igualdad de sus bytes RGB recortados? ¿Establece igualdad de los paneles circundantes completos o del juicio de un participante?

> **Respuesta:** Cada objetivo tiene 25600 píxeles. Sus matrices de bytes RGB recortadas son iguales bajo las coordenadas declaradas. Los entornos difieren y la igualdad de bytes no establece ningún juicio de participante ni luminancia de pantalla medida con instrumentos.

## 2. Separar la igualdad numérica de la experiencia solicitada

El brillo es un juicio perceptivo sobre la intensidad aparente de la luz; la claridad se refiere a la reflectancia superficial percibida. Ninguno es simplemente un byte de archivo. La auditoría de píxeles responde a si dos recortes objetivo contienen valores RGB idénticos. Preguntar si una superficie tejida parece el mismo material bajo otra iluminación requiere una pregunta operativa separada y un contexto adecuado.

El [diseño preparado de la tarea](../../../../code/streeling/evidence/color-contract-2026-10-22/appearance-task-design.json) pregunta qué objetivo parece más brillante y permite las respuestas izquierda, derecha, iguales y no estoy seguro. Contiene cero participantes y ningún dato de respuesta. La respuesta correcta del ejercicio no es una dirección de ilusión prescrita. Registra lo que un observador comunica realmente, junto con las condiciones de visualización y la pregunta formulada.

### Ejercicio 2: evitar inventar una clave de respuestas

Un estudiante verifica que los bytes objetivo son idénticos. ¿Debe un observador posterior responder «iguales» a la pregunta de apariencia? ¿Es «el mismo material pintado» la misma pregunta que «la misma intensidad aparente de luz»?

> **Respuesta:** La prueba de bytes no impone ninguna respuesta al observador. Registra la respuesta real en lugar de puntuar una dirección supuesta de ilusión como verdad. La reflectancia sugerida del material y la intensidad aparente de luz son juicios distintos que necesitan preguntas especificadas por separado.

## 3. No inferir toda la ruta de visualización a partir de una captura

El [código público de escritura de capturas de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L4308-L4337), en el commit `76efbffd5af82b46c3146957a6bd4504008eeb89`, convierte los bytes BGRA de la cadena de presentación en datos PNG RGB. El código inspeccionado emite bloques de imagen sin un bloque de espacio de color. Esta observación del código no es una nueva captura ni prueba de cómo un navegador real interpretó un archivo.

Nuestro control original lleva explícitamente un bloque sRGB. Esa etiqueta declara una interpretación prevista; no calibra el monitor, no establece la iluminación ambiental ni mide la radiancia que llega al ojo. Deben registrarse el escalado, los ajustes de gestión del color y la ruta de visualización cuando importen para la comparación. Los bytes de archivo coincidentes no pueden sustituir esas observaciones ausentes.

### Ejercicio 3: interpretar los metadatos dentro de su alcance

El PNG creado para el curso lleva un bloque sRGB. El código inspeccionado de escritura de capturas del proyecto no lo emite. ¿Puede alguno de esos hechos establecer una coincidencia visual calibrada entre ambos flujos de trabajo?

> **Respuesta:** No. Uno declara una interpretación de imagen y el otro identifica una omisión de metadatos en el código. Ninguno aporta una comparación real de capturas, configuración de navegador o pantalla, luminancia medida ni resultado de observador. No se probó ninguna coincidencia calibrada.

## 4. Controlar la disposición sin afirmar que hubo un experimento

El diseño preparado propone intercambiar los entornos oscuro y claro entre izquierda y derecha, manteniendo fijos los bytes y tamaños de los objetivos. Esto ayuda a separar una posible preferencia de lado de una respuesta ligada al contexto. Solo se ha renderizado la primera disposición en este paquete; la versión intercambiada está planificada, no es un ensayo ejecutado ni un segundo estímulo publicado.

No digas a los participantes qué objetivo debería parecer más brillante. Mantén las opciones iguales y no estoy seguro, conserva las respuestas y exclusiones reales y registra la transformación de imagen o visualización, la escala y las condiciones de observación. El pequeño control no establece un efecto poblacional, una magnitud de efecto, el realismo de un material elaborado ni la transferencia de un resultado del estudio citado de bloques ajedrezados.

### Ejercicio 4: corregir un procedimiento sesgado

Un ensayo propuesto siempre coloca el entorno oscuro a la izquierda y pregunta: «¿Ves que el objetivo izquierdo es más brillante?». Propón dos cambios e indica qué contiene realmente el paquete actual.

> **Respuesta:** Contrabalancea el lado del entorno y usa una pregunta neutral con las opciones iguales y no estoy seguro. El paquete contiene una disposición creada para el curso y comprobaciones exactas de píxeles, pero no un renderizado de la disposición intercambiada, participantes ni respuestas. El procedimiento revisado sigue siendo una propuesta hasta que se realice.

## 5. Devolver pruebas separadas al agente

Un traspaso entre agentes puede informar en campos separados de la igualdad de bytes de recortes objetivo, la codificación de color declarada, los ajustes conocidos de la ruta de visualización y un resultado de observador. Las pruebas de observador ausentes siguen ausentes. Es un registro de tarea propuesto, no un nuevo esquema normativo del ecosistema. Una prueba de píxeles positiva puede respaldar la comprobación de un artefacto y dejar sin resolver una decisión sobre la calidad del material.

[VC-010](../../visual-computing/en/vc-010-preserve-packed-texture-channel-contracts.md) muestra por qué incluso la interpretación de bytes RGBA puede depender de un contrato de canales. Una tupla numérica idéntica usada como datos de normales, rugosidad o altura no es el mismo tipo de afirmación que una tupla idéntica usada como color mostrado.

### Ejercicio 5: redactar una conclusión acotada por las pruebas

Un agente tiene el hash de la imagen y bytes coincidentes de recortes objetivo, pero ningún registro de observador. Redacta la conclusión respaldada y una acción siguiente para evaluar la apariencia de la superficie elaborada.

> **Respuesta:** Los recortes objetivo creados para el curso son idénticos byte a byte bajo las coordenadas registradas y la interpretación etiquetada de la imagen. No se establece ningún resultado de observador ni equivalencia de calidad del material. Define la pregunta de apariencia prevista y recoge una observación en el entorno de destino con condiciones de visualización controladas adecuadamente antes de afirmar ese resultado más amplio.

## Tarea del estudiante con acceso a las fuentes

Completa la [tarea preparada](../../../../code/streeling/evidence/color-contract-2026-10-22/learner-task.md). Explica cómo pueden coexistir una prueba válida de píxeles y una pregunta de apariencia sin resolver, sin sustituir una respuesta ausente por un valor numérico predeterminado.
