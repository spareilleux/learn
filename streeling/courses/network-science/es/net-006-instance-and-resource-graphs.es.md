---
module_id: net-006-instance-and-resource-graphs
department: network-science
course: "Grafos de instancias y recursos"
level: intermediate
prerequisites: [net-002-capability-graphs-and-projections, vc-008-save-and-query-a-weave-scene]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Grafos de instancias y recursos

> **Borrador fuente redactado por IA.** Siguen pendientes las revisiones de especialistas en la materia, de personas con dominio de los idiomas y de estudiantes. La publicación del curso en HTML público sigue pendiente.

Un compañero ve objetos repetidos en el tejido guardado con [Godot](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html) y pregunta: «¿Qué objetos comparten datos y a cuáles afectaría una modificación compartida?». La respuesta exige un grafo cuyas aristas expresen referencias a recursos. [NET-002](net-002-capability-graphs-and-projections.md) estudió etiquetas de catálogo; [VC-008](../../visual-computing/en/vc-008-save-and-query-a-weave-scene.md) probó la persistencia de escenas y las consultas físicas. Aquí elegirás entre varios grafos del mismo artefacto.

Utiliza el [paquete de evidencias](../../../../code/streeling/evidence/feedback-projections-2026-10-22/README.md), la [tarea del estudiante](../../../../code/streeling/evidence/feedback-projections-2026-10-22/learner-task.md) y la [extracción del grafo de recursos](../../../../code/streeling/evidence/feedback-projections-2026-10-22/resource-graphs.json). Es un nuevo análisis estático de los bytes conservados, sin una nueva ejecución del motor. La [escena guardada](../../../../code/streeling/evidence/weave-scene-2026-10-22/native-scene.tscn) tiene el SHA-256 `7c8003a9e7ea1433cd7e7e18ed83512ca2c436ea0af70bb7415e01e43c3bb4ca`.

## 1. Contar la jerarquía antes de estudiar el uso compartido

Para responder «¿Qué pertenece a la raíz de esta escena?», elige la jerarquía: los vértices son nodos de escena y las aristas dirigidas van del padre al hijo. Al contar los tipos declarados, contiene 253 nodos: 37 nodos [`Node3D`](https://docs.godotengine.org/en/4.6/classes/class_node3d.html), que incluyen la raíz y 36 padres de cruces, más 72 nodos de cada tipo: [`MeshInstance3D`](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html), [`StaticBody3D`](https://docs.godotengine.org/en/4.6/classes/class_staticbody3d.html) y [`CollisionShape3D`](https://docs.godotengine.org/en/4.6/classes/class_collisionshape3d.html). Cada cruce tiene una rama de urdimbre y otra de trama, cada una con malla, cuerpo y forma.

El archivo también declara 6 subrecursos compartidos: 2 mallas, 2 formas de colisión y 2 materiales. Un [Resource](https://docs.godotengine.org/en/4.6/classes/class_resource.html) contiene datos; su declaración no añade otro nodo de escena. Sumar declaraciones y nodos mezclaría las funciones de los objetos. El [informe de ejecución anterior](../../../../code/streeling/evidence/weave-scene-2026-10-22/good-godot-report.json) registra los recuentos cargados y los recursos compartidos; esta extracción examina la representación guardada.

### Ejercicio 1 — Separar los inventarios

Alguien cuenta 259 nodos de escena al sumar los recursos. Corrige la cifra y explica los 37 nodos `Node3D`.

> **Respuesta:** Hay 253 nodos de escena y 6 recursos separados. Los 37 nodos `Node3D` comprenden 1 raíz y 36 padres de cruces. Las declaraciones de recursos no añaden vértices a la jerarquía.

## 2. Usar las referencias como relación

Para responder «¿Qué nodos de escena hacen referencia a datos compartidos?», construye un grafo bipartito dirigido. A la izquierda están los nodos de escena con una referencia `mesh`, `material_override` o `shape`; a la derecha, los objetos `SubResource` declarados. Cada referencia de propiedad aporta una arista dirigida, etiquetada con esa propiedad. Las propiedades son etiquetas de arista, no vértices adicionales.

Las 72 instancias de malla tienen una arista de malla y otra de material; los 72 nodos de forma de colisión tienen una arista de forma. Por tanto, hay 144 vértices a la izquierda, 6 a la derecha y `72 * 2 + 72 = 216` aristas. Cada recurso tiene grado de entrada 36. Los otros 109 nodos de la jerarquía carecen de estas referencias y quedan fuera del grafo. Esta exclusión no dice nada sobre su importancia en la escena.

Por ejemplo, `w0-f0/warp` hace referencia a `BoxMesh_jk82c` mediante `mesh`. Es una relación entre datos guardados, sin llamadas observadas a servicios ni colaboración entre autores.

### Ejercicio 2 — Comprobar el recuento bipartito

¿Por qué hay 144 vértices a la izquierda en lugar de 253 o 216? Indica el número de aristas y el grado de entrada de cada recurso.

> **Respuesta:** Solo participan 72 instancias de malla y 72 nodos de forma de colisión. Varias propiedades pueden salir del mismo vértice. Hay 216 aristas y cada uno de los 6 recursos tiene grado de entrada 36.

## 3. Proyectar según la pregunta

Para responder «¿Qué instancias comparten la misma malla?», conserva los 72 vértices de instancias de malla. Une 2 vértices distintos mediante una arista no dirigida exactamente cuando sus propiedades `mesh` nombran el mismo [`BoxMesh`](https://docs.godotengine.org/en/4.6/classes/class_boxmesh.html) guardado. Ignora materiales, formas y vínculos jerárquicos.

La proyección tiene 2 componentes, cada uno un clique de 36 vértices: todos los segmentos de urdimbre comparten una malla y los de trama, la otra. Cada vértice tiene grado 35. El recuento de pares no ordenados da `2 * (36 * 35 / 2) = 1260` aristas. Estas aristas resumen las referencias compartidas; no se guardó ninguna estructura de 1260 aristas como jerarquía de escena. La proyección también oculta qué recurso origina cada conexión, por lo que conviene conservar el grafo de referencias para el diagnóstico.

### Ejercicio 3 — Contar sin duplicados

Calcula el grado, los tamaños de los componentes y el número de aristas de la proyección de mallas. ¿Por qué se divide entre 2?

> **Respuesta:** Grado 35; componentes de tamaños 36 y 36; 1260 aristas. Dentro de cada clique, contar los vecinos cuenta cada par no dirigido dos veces; dividir entre 2 corrige la duplicación.

## 4. Acotar una eliminación hipotética

Elimina un vértice `BoxMesh` del grafo analítico de referencias. Desaparecen sus 36 aristas incidentes y quedan `216 - 36 = 180` aristas. Si alguien eliminara realmente esa declaración sin cambiar las asignaciones de propiedades de la escena, 36 referencias de malla perderían su destino. Esta condición delimita las reparaciones; no se ha editado ninguna escena ni se ha observado ningún fallo del motor.

Esos nodos de malla también hacen referencia a materiales. Eliminar un recurso de malla no elimina sus aristas de material ni su pertenencia a la jerarquía. Del mismo modo, un corte de grafo no demuestra un error de metadatos: los identificadores de cruce y la identidad de los recursos responden a preguntas distintas. Los ObjectID de recursos en tiempo de ejecución son efímeros y no son los identificadores de los cruces de origen.

### Ejercicio 4 — Formular el resultado acotado

Indica las aristas restantes y las referencias afectadas tras la eliminación hipotética. ¿Puedes informar de un fallo de carga en Godot?

> **Respuesta:** Quedan 180 aristas de referencia analíticas; 36 referencias de malla necesitarían reparación si se eliminara realmente la declaración sin actualizarlas. No se ha observado un fallo de carga y no se puede afirmar que lo haya habido.

## 5. Pedir el experimento que falta

Compartir un recurso sugiere hasta dónde podría propagarse un cambio de datos, pero esta extracción no mide la propagación ni el coste de renderizado. [MeshInstance3D](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html) y [MultiMesh](https://docs.godotengine.org/en/4.6/classes/class_multimesh.html) describen opciones de representación distintas. Que varios nodos referencien una malla no demuestra automáticamente instanciación mediante MultiMesh ni agrupación de llamadas de dibujo. La documentación describe capacidades; no evalúa el rendimiento de esta escena.

Para probar una afirmación sobre cambios, usa una copia de trabajo, especifica la modificación de una propiedad del recurso, compara todas las instancias afectadas y conserva las evidencias anteriores y posteriores. Para probar el rendimiento, controla escena, renderizador, hardware, carga y representación, y mide varias ejecuciones comparables. El [README del laboratorio](../../../../code/streeling/weave-godot/README.md) documenta el experimento anterior de persistencia, limitado a 36 cruces guardados. Ninguno de estos grafos demuestra un exportador general ni la necesidad de un DSL de UUID de nodos.

### Ejercicio 5 — Elegir evidencias para la afirmación

Una propuesta afirma: «Compartir recursos mejoró el rendimiento de la GPU y una modificación de la malla cambió toda la urdimbre». ¿Qué evidencias faltan?

> **Respuesta:** Un benchmark controlado con resultados de renderizado medidos y una modificación de recurso registrada con comparaciones entre instancias. El grafo estático solo respalda los recuentos de referencias compartidas; ambas afirmaciones empíricas siguen por verificar.
