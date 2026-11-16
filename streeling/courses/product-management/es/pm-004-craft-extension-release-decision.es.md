---
module_id: pm-004-craft-extension-release-decision
department: product-management
course: "Decidir cuándo las extensiones de artesanía están listas para una versión distribuible"
level: intermediate
prerequisites: [pm-002-release-evidence-gate, pm-003-review-queue-flow-metrics]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: product-management-2026-10-12-004
version: "0.1.0"
---

# Decidir cuándo las extensiones de artesanía están listas para una versión distribuible

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de traducciones todavía no redactadas, de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](../../../../code/streeling/evidence/representation-release-2026-10-22/README.md) documenta los borradores traducidos actuales, la importación y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Gestión de Producto y Proyecto** | Nivel intermedio | 35 minutos | Borrador en español; sin distribución de extensiones, revisión humana, prueba con estudiantes ni publicación pública del curso; revisión lingüística humana pendiente

## Objetivos y pregunta del proyecto

Después de esta lección podrás nombrar la tarea de producto que sirve una extensión de artesanía, distinguir un componente fuente útil de una extensión instalable, aplicar condiciones de lanzamiento que no se compensen entre tres destinos y escribir una decisión de lanzamiento que otra persona pueda reproducir. **Pregunta del proyecto:** ¿cuándo puede el equipo anunciar con veracidad extensiones ComfyUI, Blender y Godot surgidas de sus experimentos de audio de guitarra y de artesanía a escena? Para este proyecto, afirmar que hay una versión distribuida exige una distribución versionada e instalable con artefactos y notas identificados; una etiqueta por sí sola es insuficiente. Una hoja de ruta, un borrador de curso, un script fuente, un experimento local o una fixture didáctica superada no constituyen esa distribución.

[PM-002](pm-002-release-evidence-gate.md) separa las condiciones de revisión, compilación y lectura pública de un curso Streeling. [PM-003](pm-003-review-queue-flow-metrics.md) mide el movimiento por esa cola de revisión de cursos. Esta lección toma otra decisión: si se puede ofrecer a usuarios una **extensión de software**. El propio curso sigue teniendo sus condiciones independientes de revisión y publicación.

## 1. Elegir una tarea de usuario por extensión

Una propuesta de extensión debe nombrar qué puede instalar y hacer un usuario. Un posible destino **ComfyUI** es un flujo de audio de guitarra sin conexión que toma un WAV de referencia inicial y produce un candidato con su procedencia. Un posible destino **Blender** es una ayuda de limpieza de características artesanales que conserva una identidad de característica declarada durante el procesamiento de la malla. Un posible destino **Godot** es un importador o inspector de escena que conserva la identidad y el significado por encima/por debajo de un cruce tejido. Son *tareas candidatas de producto*, no afirmaciones de que existan las tres extensiones instalables.

El proyecto ya dispone de pruebas más limitadas. La [lección fijada CS-004 del bucle de audio](https://github.com/GuitarAlchemist/Demerzel/blob/861b6b1891ef7017c22269d5ec6be4c50953040c/state/streeling/courses/computer-science/en/cs-004-composable-agentic-audio-loop.md) describe un puente GA ComfyUI local y sin fusionar en `6fac5735f7ffbb4116ebee05cfc9d7911bb12ce9`; su flujo suministrado carga y guarda audio, pero no demuestra mejora. La [lección fijada VC-005 de artesanía](https://github.com/GuitarAlchemist/Demerzel/blob/861b6b1891ef7017c22269d5ec6be4c50953040c/state/streeling/courses/visual-computing/en/vc-005-craft-details-through-blender-to-godot.md) cita el script de limpieza GLB en Blender de Learn y el informe de muestra versionado en `93d424f872a576ba8bbcd3dd44c9733292373654`, pero no informa de ninguna importación Godot ni prueba de características artesanales. La [lección fijada VC-007 de tejido](https://github.com/GuitarAlchemist/Demerzel/blob/861b6b1891ef7017c22269d5ec6be4c50953040c/state/streeling/courses/visual-computing/en/vc-007-weave-seams-as-scene-contracts.md) tiene un evaluador sintético en Python: la paridad global produce cero incumplimientos entre cruces adyacentes y la paridad local reiniciada produce doce. Es un contraejemplo semántico, no una extensión Godot. El [plan Godot aparcado de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md) esboza una ruta de escena; sus elementos sin marcar son planes.

### Ejercicio 1: escribir la promesa al usuario

Un borrador de anuncio dice: «Nuestra suite de artesanía ComfyUI, Blender y Godot está lista porque existen el puente de audio, el script GLB y el validador de tejido». Corrige la declaración en una frase veraz en presente y una tarea propuesta refutable.

> **Respuesta:** «El proyecto tiene experimentos en el código fuente de audio, limpieza de mallas y validación de tejido, con distinta procedencia y sin una distribución demostrada de extensiones para los tres destinos». Una tarea propuesta refutable es: «Un usuario instala el add-on Godot versionado, importa la muestra tejida suministrada, pulsa `w3-f0` y recibe el valor declarado por encima/por debajo de ese cruce en una traza guardada». Esta última necesita un add-on instalable y un recibo de ejecución antes de poder afirmarse como resultado logrado.

## 2. Exigir pruebas en cada frontera de destino

Recoge cuatro tipos de pruebas para cada destino. La **implementación** es un paquete de extensión versionado e instalable con instrucciones de configuración y compatibilidad. La **ejecución** es una prueba nueva en la versión identificada de la aplicación sobre una entrada fijada, con comandos, registros y hashes de salida. El **significado** es un oráculo específico de tarea: para audio, un candidato comparable contrastado con la misma referencia y una tarea de escucha; para Blender, la supervivencia de una característica artesanal identificada tras la limpieza; para Godot, un identificador estable de cruce y una correspondencia por encima/por debajo en la escena y la traza de clics. La **revisión humana** pide a un especialista examinar el artefacto real y a un usuario sin ayuda realizar la tarea. Un esquema o una prueba unitaria superados no pueden sustituir esas observaciones.

El conjunto también necesita una **repetición del contrato** entre fronteras: la identidad y el hash de salida de una herramienta deben ser la identidad y el hash de entrada de la siguiente, sin sustituciones inexplicadas. Guarda los hashes de artefactos de los tres paquetes y de sus entradas y salidas de prueba. Las versiones exactas importan porque un script examinado en un commit no demuestra que una extensión funcione en una versión posterior de la aplicación. Registra accesibilidad, licencias, compatibilidad de plataformas y comportamiento de instalación en una lista real de comprobación de lanzamiento; la fixture didáctica siguiente no los evalúa.

### Ejercicio 2: clasificar las pruebas fijadas

¿Cuáles de las cuatro columnas de pruebas por destino pueden marcarse como completas para una distribución de tres extensiones usando solo las fuentes fijadas anteriores? ¿El informe de muestra Blender versionado de Learn demuestra que una característica artesanal sobrevivió en una escena Godot?

> **Respuesta:** Ninguna de las cuatro columnas está completa para una **distribución instalable de tres extensiones** a partir de esas fuentes. Respaldan la inspección del código fuente y algunas comprobaciones más limitadas, sintéticas o de muestras versionadas. El informe Blender trata una ruta de limpieza de muestra, no una extensión Blender instalada con un veredicto de característica artesanal; no contiene ninguna importación de escena Godot. Mantén la decisión del conjunto en espera e identifica las pruebas específicas de cada destino que faltan.

## 3. Usar condiciones obligatorias antes de ordenar las mejoras

La [fixture de tarjetas de lanzamiento](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/product-management/pm-004/release-cards.json) es un **modelo didáctico**, no una auditoría de las etiquetas actuales de GitHub. Ejecuta `python state/streeling/fixtures/product-management/pm-004/evaluate_release.py` desde la raíz de Demerzel. Comprueba que cada tarjeta cubre exactamente `comfyui`, `blender` y `godot`, y después enumera los campos de prueba falsos. Su tarjeta de instantánea de fuentes no da por superada deliberadamente ninguna condición de extensión instalable: las fuentes más limitadas del proyecto anteriores no demuestran ninguna de esas condiciones. Las otras tres tarjetas son expresamente sintéticas.

El evaluador clasifica como `reject_candidate` un candidato Godot que funciona pero falla en significado, aunque pasen los otros once campos por destino, la repetición del contrato y los hashes. Los recibos ausentes producen `hold_for_evidence`. Cuando pasan todas las condiciones modeladas, devuelve `release_candidate`, que significa que el paquete *modelado* podría entrar en una decisión final de lanzamiento. El evaluador nunca crea una etiqueta, comprueba una release de GitHub ni demuestra que existan realmente recibos de revisores. Su campo `published` es independiente de la candidatura. Evita convertir sus booleanos ficticios en puntuaciones reales de calidad.

### Ejercicio 3: cuestionar una puntuación ponderada

En la tarjeta sintética `pretty-but-wrong`, todos los campos excepto `godot.meaning` son verdaderos. Un compañero propone lanzar porque la tasa de éxito es alta. ¿Qué dice el evaluador y por qué ese fallo no debería poder compensarse?

> **Respuesta:** Devuelve `reject_candidate` e identifica `godot.meaning` como ausente. La promesa de producto incluye una identidad correcta del cruce y su significado por encima/por debajo en la escena Godot. Más documentación de ComfyUI o Blender no puede corregir un cruce Godot equivocado. La puntuación ficticia no representa un resultado medido del equipo.

### Ejercicio 4: distinguir revisión de finalización técnica

La tarjeta sintética `technical-only` marca como verdaderos implementación, ejecución, significado, repetición del contrato y hashes para todos los destinos, pero los tres campos de revisión humana son falsos. Indica su decisión, las siguientes pruebas que solicitar y si existe una release de GitHub.

> **Respuesta:** Es `hold_for_evidence`. Solicita identidad del revisor, fuentes exactas y hashes de artefactos, veredicto y hallazgos específicos de cada destino, y resultados de tareas de usuarios sin ayuda para cada extensión. `published_tag` es falso; ni la tarjeta ni el programa Python crean una release de GitHub. Sus booleanos técnicos son datos didácticos inventados, no recibos reales de pruebas.

## 4. Separar el lanzamiento por una frontera útil

Un conjunto puede convertirse en cuello de botella si un destino inmaduro bloquea dos utilizables. Decide si los usuarios necesitan realmente una instalación atómica. El flujo de audio y la ruta de artesanía 3D sirven tareas diferentes, por lo que las distribuciones independientes pueden ser más baratas de validar. Un lanzamiento de integración entre herramientas debería llegar después si una tarea de usuario recorre realmente esas herramientas y puede demostrarse su repetición del contrato. Separar versiones no sirve para ocultar una condición semántica fallida: cada distribución de destino debe superar sus propias comprobaciones de paquete, ejecución, significado y humanas. Publica una matriz explícita de compatibilidad para cualquier flujo combinado.

Fija una regla de parada antes de implementar. Para un inspector propuesto de tejido Godot, rechaza una importación si cualquier cruce pulsado corresponde al identificador estable incorrecto o al valor declarado por encima/por debajo equivocado. Para una ayuda propuesta de limpieza Blender, rechaza un candidato si desaparece la característica artesanal identificada aunque baje el número de triángulos. Para un flujo de audio, un candidato idéntico byte a byte es un control sin cambios; una variación espectral necesita ventanas comparables y escucha, no una afirmación automática de «suena mejor». Estas reglas vinculan el lanzamiento al valor para el usuario en vez de hacer de la compilación la propia métrica de éxito.

### Ejercicio 5: decidir el lanzamiento

La tarjeta sintética `candidate-after-reviews` supera todas las condiciones modeladas, pero tiene `published_tag: false`. Un responsable pregunta: «¿Ya están distribuidas las extensiones?». Da el estado correcto y dos comprobaciones concretas siguientes. Después explica qué debería decir el equipo sobre la instantánea real de las fuentes fijadas.

> **Respuesta:** La tarjeta sintética es una **candidata a distribución**, no una distribución. Inspecciona de forma independiente los paquetes y recibos identificados, incluidas las comprobaciones de compatibilidad y licencia omitidas en esta fixture; después, si se aprueba, crea la release etiquetada real y descarga/instala anónimamente los artefactos para verificar la ruta documentada. Para la instantánea real de fuentes fijadas, di solo que existen experimentos y planes pertinentes y que la distribución de tres extensiones está en espera. La tarjeta didáctica no aporta ninguna aprobación real ni prueba de distribución pública.

## Ideas clave y límites

- Identifica la instalación y la tarea del usuario antes de decidir si tres herramientas necesitan un solo lanzamiento.
- Usa condiciones obligatorias específicas de destino para instalación, ejecución, significado semántico y pruebas de tareas humanas. Una puntuación agregada no puede compensar un resultado prometido incorrecto.
- Una fixture superada demuestra que el **modelo de decisión** se comporta como está escrito, no que exista una extensión, revisión humana, release etiquetada o página pública del curso.

Los enlaces de fuentes anteriores son ejemplos vinculados a revisiones. Esta lección no ejecutó ComfyUI, Blender ni Godot, inspeccionó un paquete de extensión real, midió calidad de audio, revisó un objeto artesanal con usuarios ni publicó una release de GitHub. El propio PM-004 está pendiente de revisión del contenido, prueba con estudiantes y revisión lingüística, además de integración Learn y lectura pública anónima.
