---
module_id: vc-005-craft-details-through-blender-to-godot
department: visual-computing
course: "Conservar detalles artesanales en una prueba de recursos de Blender a Godot"
level: intermediate
prerequisites: [vc-004-godot-observatory-capture-gate]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
research_cycle: visual-computing-2026-10-12-005
version: "0.1.0"
---

# Conservar detalles artesanales en una prueba de recursos de Blender a Godot

> **Alcance del borrador y las traducciones.** El texto técnico siguiente es un borrador fechado. Las menciones históricas de traducciones, integración en Learn o comprobaciones de publicación pendientes corresponden a aquella etapa; este [registro de traducción](../../../../code/streeling/evidence/locale-completion-2026-10-22/README.md) documenta los borradores actuales y las comprobaciones realizadas. Los ensayos de ejecución no realizados siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Computación Visual** | Intermedio | 40 minutos | Borrador en español; sin importación Godot, revisión humana, prueba con estudiantes ni publicación; aprobación de una persona que domine el español pendiente

## Objetivos y pregunta del proyecto

Después de esta lección, podrás distinguir un detalle artesanal del ruido de malla prescindible, predecir dos pérdidas de limpieza de un pipeline Blender fijado, diseñar una comparación reversible para un observatorio Godot y especificar pruebas que rechacen una regla automática de limpieza. **Pregunta del proyecto:** si un nudo tejido, una arista de papel plegado o una marca de metal cincelado transmite significado en un objeto de gobernanza, ¿puede un pipeline reducir su coste sin borrar ese significado? Es un diseño de prueba de recursos, no una afirmación de que esas artesanías o la escena Godot ya estén implementadas.

## 1. Partir de un pipeline real y una escena propuesta

El [script de limpieza GLB](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/scripts/glb_pipeline.py) fijado de Learn importa un `.glb`, une objetos de malla, fusiona vértices próximos, elimina partes conexas bajo un umbral de fracción de caras, recalcula normales, opcionalmente remalla mediante vóxeles, diezma hacia un presupuesto de triángulos, exporta un `.glb` limpio y vuelve a importarlo para elaborar un informe. Su docstring apunta a three.js. El [comprobador de ejemplo](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/scripts/pipeline_check.py) construye una malla defectuosa de púa y ejecuta el pipeline dos veces, una con remallado de vóxeles. Su [informe esperado](https://github.com/spareilleux/learn/blob/93d424f872a576ba8bbcd3dd44c9733292373654/code/blender/expected/pipeline_check.txt) es un resultado de referencia versionado, no una nueva ejecución para esta lección.

La anterior [lección de captura VC-004](vc-004-godot-observatory-capture-gate.md) especifica una condición propuesta de imagen e interacción para el observatorio Godot. Este curso pregunta si una geometría derivada de técnicas artesanales podría incorporarse como recurso versionado a esa escena futura. El script Learn no demuestra compatibilidad con Godot. Importación, captura de escena y comparación de tareas siguen siendo experimentos separados.

### Ejercicio 1: nombrar el límite de las pruebas

Un colega dice: «El informe de limpieza Learn demuestra que nuestro nodo tejido es seguro en Godot». ¿Qué parte está respaldada y qué falta?

> **Respuesta:** La fuente y el informe esperado muestran que una malla de ejemplo de púa puede procesarse con ajustes declarados de Blender. No contienen un recurso de nodo tejido ni una importación Godot. Para comprobarlo, versiona el `.glb` candidato, registra fuente y ajustes, impórtalo en una escena Godot versionada, captura las vistas previstas y ejecuta una tarea de reconocimiento frente a una referencia. El informe versionado solo no certifica que un nudo siga siendo reconocible.

## 2. Modelar un detalle antes de simplificarlo

Un detalle artesanal debe tener un **papel** declarado. En un nodo hipotético de gobernanza tejido, un nudo pequeño podría indicar un límite de autoridad; en un panel de origami, una arista de pliegue distinguiría abierto de cerrado; en metal cincelado, una marca superficial identificaría material o procedencia. Trátalos como características semánticas candidatas, no como decoración por defecto. Asigna a cada una ID, significado breve, región de malla o material y una vista donde un estudiante deba identificarla. Mantén el manifiesto fuera del script actual: su unión de objetos y limpieza de partes conexas no incluyen ese contrato de aprobación.

El valor predeterminado de `--min-part` es `0.01`: se elimina una parte conexa con **menos** del uno por ciento de todas las caras. En el informe esperado fijado, el modelo importado tiene 5,140 caras y se elimina una parte de 20. Es razonable para la masa deliberadamente flotante del comprobador, pero sería una pérdida semántica si esa parte de 20 caras fuera un nudo intencional. El umbral es una regla topológica, no una prueba del significado artesanal. Llamar «importante» a un elemento en prosa no cambia el código.

### Ejercicio 2: aplicar la comparación real

Toma un recurso **sintético** de 5,140 caras con un nudo de autoridad aislado de 20 caras. Con `--min-part 0.01`, ¿se elimina? ¿Cuál es la primera comparación menos arriesgada?

> **Respuesta:** El uno por ciento es 51.4 caras y `20 < 51.4`, por lo que la regla eliminaría esa parte conexa. Compara la exportación fuente sin modificar con una limpieza usando `--min-part 0.001`: el umbral pasa a 5.14 caras y se conserva una componente aislada de 20 caras. Mantén los demás ajustes fijos y comprueba informes y vista renderizada del nudo. Conservar partes pequeñas puede conservar ruido, así que es diagnóstico, no una política final. La ruta `--min-part 0` del script fijado devuelve una lista vacía donde el llamante espera una pareja, así que cero no es una vía válida para omitir el filtro en esa revisión. La [corrección propuesta en Learn `deac6e1`](https://github.com/spareilleux/learn/blob/deac6e12a64864703300e5645cd5a9d1d374e062/code/blender/scripts/glb_pipeline.py) devuelve una pareja en ese retorno anticipado. La PR #168 se observó abierta y en borrador durante esta pasada de localización; no está fusionada. Una llamada limitada al código fuente confirma la pareja; una ejecución Blender sigue sin verificar. Si el nudo toca una componente mayor, esta regla concreta puede no eliminarlo; el reconocimiento aún puede fallar tras diezmado o cambios de sombreado.

## 3. Separar geometría, material y significado

El informe esperado ofrece otra advertencia. Sin remallado, la muestra limpia informa de una capa UV y cero aristas de borde antes de exportar; tras exportación y reimportación informa de 186 aristas de borde y luego cero al fusionar vértices por posición. El script comenta que glTF puede dividir un vértice en costuras de normales o UV. Por tanto, el recuento bruto tras reimportar no demuestra por sí solo un agujero físico. Conserva informes brutos y tras fusión por posición e inspecciona la superficie renderizada donde importe una costura. La muestra no dice si siguen siendo legibles la dirección de hilos de un patrón tejido o un acabado metálico.

En la ruta de remallado por vóxeles, el informe pasa de una capa UV antes de limpiar a `none` después. Puede ser aceptable para geometría simple, pero no permite suponer que sobreviva un patrón codificado en textura UV. Un nombre de material distinto en el informe también sería solo una señal estructural; iluminación, dirección de normales, espacio de color y distancia de observación influyen en la percepción. Una malla cerrada manifold aún puede comunicar el detalle artesanal equivocado.

### Ejercicio 3: leer el informe sin exagerar

Tras reimportar, un modelo informa de 186 aristas de borde; tras fusión por posición, cero. ¿Demuestra eso solo una malla dañada? La variante de remallado por vóxeles indica `uv: none`; ¿qué dice sobre un patrón tejido codificado con UV?

> **Respuesta:** No. Los vértices divididos en costuras de exportación pueden producir el primer recuento, y el segundo desaconseja considerarlo un agujero demostrado. Inspecciona fuente y costura renderizada antes de decidir. `uv: none` muestra que el remallado probado no conservó una capa UV en la muestra de referencia. Un patrón dependiente de ella necesita un paso separado de conservación o nuevo horneado de textura y una comprobación visual; el informe no demuestra cómo se verá otro recurso artesanal.

## 4. Componer una prueba acotada de Blender a Godot

Elige un detalle artesanal y un uso objetivo en el observatorio antes de generar muchos recursos. Guarda el `.glb` de entrada y un manifiesto con SHA fuente, ID de objeto y detalle, dimensiones previstas, argumentos de limpieza, triángulos, informe UV/materiales, hash de salida y tarea de observación. Produce referencia y candidato de la misma entrada. Un primer candidato cambia solo `--min-part`; otro puede variar diezmado manteniendo fijo el primer ajuste. No cambies juntos limpieza, cámara, luz y escalador para atribuir luego una mejora percibida al modelado artesanal.

Para Godot, importa cada versión en la misma escena y captura iguales cámara, renderizador, viewport, luces e instantánea de datos de gobernanza. Registra errores, escala, imágenes brutas, distribución del tiempo por fotograma y si los revisores identifican detalle y significado sin respuestas superpuestas. Manifiesto y capturas hacen revisable un rechazo. Las comprobaciones propuestas de zona segura y repetibilidad de VC-004 son controles útiles de captura, no pruebas de legibilidad artesanal. La vía de fork DLSS solicitada por el usuario exigiría compilación compatible separada, registro de resolución de renderizado y comparación de rendimiento/calidad; aquí no hay tal ejecución.

### Ejercicio 4: aislar una variable

A usa `--min-part 0.001`, objetivo de 2,000 triángulos y cámara de referencia. B usa `--min-part 0.01`, 1,000 triángulos, nueva cámara y nueva iluminación. B parece más claro en una captura. ¿Qué afirmación puedes defender y qué comparación sigue?

> **Respuesta:** Solo puedes comunicar que esa imagen combinada de B parecía más clara con ajustes cambiados. No puedes atribuirlo al umbral de caras o presupuesto de triángulos. Primero compara referencia y A con igual cámara, luz y condiciones de renderizado para probar la decisión de partes pequeñas. Después cambia una variable adicional cada vez. Conserva capturas brutas y un resultado de identificación, pues un sombreado atractivo puede ocultar un nudo ausente.

## 5. Decidir si se justifica una regla artesanal reutilizable

Un posible DSL artesanal futuro podría describir `feature`, `meaning`, `source_region`, `preservation_check` y `target_scene` como declaraciones componibles. Solo sería útil si sobreviven a exportación/importación y reducen pérdidas de detalles o tiempo de revisión frente a un manifiesto simple con lista manual. El script Learn y el plan Godot actuales no implementan ese DSL. La referencia más sencilla es el pipeline GLB existente, un manifiesto externo de detalles y revisión humana de antes y después.

Predeclara una comparación pequeña: varios recursos versionados con detalles conocidos que conservar y otros eliminables deliberadamente, las mismas vistas y observadores y un presupuesto acotado de triángulos/tiempo por fotograma. Rechaza una condición automática de conservación si acepta un detalle semántico ausente, bloquea simplificación útil más que la lista manual o requiere anotaciones imposibles de mantener. No tomes decisiones duraderas de esquema o API pública solo por una analogía atractiva.

### Ejercicio 5: rechazar la optimización equivocada

Un candidato cumple el presupuesto y no tiene errores de importación, pero tres de cuatro revisores no identifican el nudo de autoridad; la referencia tiene cuatro aciertos de cuatro. ¿Está listo para el observatorio? ¿Qué pruebas guardar?

> **Respuesta:** No según el objetivo declarado de conservar significado. Guarda ambos hashes, manifiestos de limpieza, informes, capturas brutas de la misma vista, respuestas y resultados de rendimiento. Menos triángulos es una mejora geométrica real, pero no compensa la pérdida semántica observada. Revisa geometría o textura y repite la comparación controlada. Cuatro revisores son una prueba pequeña, no una estimación poblacional.

## Pruebas y límites

- La fuente Learn fijada y el informe versionado respaldan operaciones y cifras anteriores. En [Learn `0eca0022`](https://github.com/spareilleux/learn/blob/0eca002201ba273dfe7348c724bd57ddea9b0568/code/blender/scripts/glb_pipeline.py), sigue presente el defecto de retorno anticipado. Una llamada específica limitada al código fuente de la función propuesta `deac6e1` confirma la pareja; no ejecuta Blender ni valida el pipeline completo. La PR no se considera fusionada. No se ejecutó ningún proceso Blender o Godot para este curso; ejemplos artesanales y resultados de revisores son hipótesis explícitas.
- El pipeline apunta actualmente a three.js y une mallas; importación Godot, conservación de ID de detalles, DSL artesanal y comparación de fork DLSS son propuestas de trabajo posterior.
- Este borrador en español aún requiere revisión independiente de la materia, intento de estudiante, revisión de una persona que domine el español, generación/compilación Learn y comprobación pública anónima antes de publicar. La traducción seguía pendiente en el ciclo anterior del original inglés.
