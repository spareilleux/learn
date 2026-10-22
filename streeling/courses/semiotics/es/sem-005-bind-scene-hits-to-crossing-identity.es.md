---
module_id: sem-005-bind-scene-hits-to-crossing-identity
department: semiotics
course: "Vincular los impactos de escena con la identidad del cruce"
level: intermediate
prerequisites: [sem-004-face-identity-under-reindexing]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Vincular los impactos de escena con la identidad del cruce

> **Borrador fuente redactado por IA.** Quedan pendientes las revisiones humanas de un especialista, una persona con dominio del idioma y un estudiante. La publicación HTML pública del curso sigue pendiente.

[SEM-004](sem-004-face-identity-under-reindexing.md) distingue una referencia material de una posición en un array. Un impacto físico de [Godot](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html) debe nombrar su cruce fuente después de la serialización. El entregable es una auditoría de identidad. Consulte el [README del laboratorio](../../../../code/streeling/weave-godot/README.md), el [README de evidencias](../../../../code/streeling/evidence/weave-scene-2026-10-22/README.md) y la [tarea del estudiante](../../../../code/streeling/evidence/weave-scene-2026-10-22/learner-task.md). El README de evidencias conserva los detalles de ejecución y los fallos.

Resultado verificado en Windows: el guardado, la carga y los 36 sondeos físicos pasaron; los controles de escala, vinculación del cuerpo de colisión y paridad reiniciada fallaron en las comprobaciones identificadas. Los fallos anteriores del lanzador no aportan pruebas de la escena.

## 1. Nombrar el objeto previsto

El [evaluador](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) y la [especificación](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json), inmutables, definen la muestra sintética `odd-tile-seam-a`. Repetir una baldosa de 3 × 3 en 2 × 2 produce 36 cruces en una cuadrícula de 6 × 6. La paridad global tiene 0 infracciones de adyacencia; la reiniciada tiene 12 y se rechaza antes de crear la escena.

`w3-f0` nombra el cruce `(3,0)` en este modelo fuente y esta revisión del manifiesto. No es una identidad material universal que sobreviva a cualquier edición. El adaptador guarda este signo en nombres de nodo y metadatos para que un cuerpo de colisión cargado pueda referirse al manifiesto. Esa correspondencia establece su significado.

### Ejercicio 1 — Completar una referencia

Un agente informa de que «el cruce 3 está mal». ¿Qué debe añadir para que el informe sea inspeccionable?

> **Respuesta:** Incluya muestra, resumen de fuente/manifiesto, ID estable como `w3-f0`, propiedad esperada y resultado observado. Un entero solo podría ser una posición de array, una coordenada de cuadrícula o un identificador de ejecución. Indique qué interpretación pretende antes de atribuir un defecto.

## 2. Distinguir tres clases de dirección

Un ID fuente identifica el cruce previsto dentro del manifiesto declarado. Una ruta de nodo localiza un nodo en una jerarquía de escena concreta. Un ID de instancia en ejecución identifica un objeto actualmente instanciado por el motor. Renombrar un nodo o cambiar su padre puede alterar su ruta sin alterar el cruce previsto. Liberar y recargar una escena crea objetos nuevos; no se espera que sus ID de instancia conserven la identidad fuente.

El ensayo usa [PackedScene](https://docs.godotengine.org/en/4.6/classes/class_packedscene.html) con propietarios y metadatos explícitos, guarda, libera el original y carga una instancia nueva. Espera 36 padres de cruce y 72 mallas, cuerpos y formas de colisión de cada categoría. Los ID de recursos en ejecución cuentan dos recursos compartidos de cada tipo de malla, forma y material; no son etiquetas de procedencia del cruce. El orden de enumeración de un array es otra dirección, no una garantía de identidad.

### Ejercicio 2 — Seguir el referente

Tras la recarga, un cuerpo tiene un ID de ejecución nuevo, pero metadatos `crossing_id = w3-f0`. ¿Queda refutada la conservación de identidad?

> **Respuesta:** No. Se espera el reemplazo de objetos en ejecución. Contraste los metadatos cargados con el manifiesto fuente correcto y el objetivo del sondeo. Una cadena coincidente sin esa procedencia y correspondencia no basta, pero no hace falta que los ID de ejecución anterior y nuevo sean iguales.

## 3. Separar los predicados

[PhysicsDirectSpaceState3D.intersect_ray](https://docs.godotengine.org/en/4.6/classes/class_physicsdirectspacestate3d.html) devuelve un impacto cuyo cuerpo de colisión lleva `crossing_id` y `strand` en los metadatos. El ensayo lanza 36 rayos descendentes a los centros esperados. Importan tres predicados distintos: la raíz cargada está vinculada al resumen del manifiesto fuente; el impacto nombra el cruce objetivo; y el hilo es el superior esperado. Con fase cero, `w2-f0` espera urdimbre y `w3-f0` espera trama.

Un resumen vincula bytes exactos, no verdad. Esos bytes pueden codificar un patrón rechazado; de ello se ocupa la admisión semántica. La identidad correcta del impacto no establece el orden superior/inferior, y una etiqueta de hilo correcta no establece la identidad del cruce. Los predicados separados hacen informativos los fallos.

### Ejercicio 3 — Leer evidencias mixtas

En `w3-f0`, el impacto indica `crossing_id = w2-f0` y `strand = weft`; el resumen de la raíz coincide. ¿Qué predicados pueden pasar todavía?

> **Respuesta:** Pueden pasar la vinculación al manifiesto y la expectativa del hilo superior. Falla `ray_crossing_identity` porque el cruce solicitado es `w3-f0`. Los dos predicados correctos no reparan la referencia falsa; conserve las tres observaciones.

## 4. Romper deliberadamente la vinculación

En una copia temporal, cambie únicamente la asignación `crossing_id` del cuerpo estático por un ID erróneo. Conserve geometría, manifiesto y asignación de hilo. La comprobación llamada `ray_crossing_identity` debe fallar aunque pasen los predicados de posición y dimensiones. Este control comprueba si el verificador detecta un referente falso, más allá de detectar una superficie.

Con [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), [Python](https://docs.python.org/3/using/cmdline.html) y Godot 4.6.1 instalados y disponibles en `PATH`, use una salida nueva fuera del checkout:

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json
```

La escritura es común a los sistemas; Windows se ha probado, Linux/WSL y macOS siguen por verificar. Conserve hashes y registros de fallo. Un tiempo de espera agotado al arrancar es un fallo de entorno o ejecución, no evidencia de que el predicado de identidad haya aceptado o rechazado la modificación. No aporta ninguna prueba nueva de la escena.

### Ejercicio 4 — Proteger el control

¿Mover el cuerpo de colisión mientras se cambia su ID aislaría un defecto de vinculación de identidad?

> **Respuesta:** No. Dos intervenciones podrían causar un rayo sin impacto o un resultado erróneo por motivos distintos. Cambie solo la asignación de metadatos, repita y conserve el fallo identificado. Si la ejecución falla antes de consultar, indique que el control no se ha evaluado.

## 5. Acotar la afirmación comunicativa

Estas cajas aisladas representan urdimbre por Z y trama por X; no establecen hilo continuo. Los impactos físicos automatizados no son clics humanos, resaltados correctos ni comprensión del estudiante. Una escena puede superar las 36 comprobaciones y seguir siendo visualmente confusa.

Trate la composabilidad como hipótesis: observe, cambie una vinculación, repita, conserve el contraejemplo e indique el límite probado. Un manifiesto simple y una cuadrícula 2D etiquetada son alternativas creíbles. Este ejercicio no da ninguna razón universal para adoptar un DSL ni esperar un progreso exponencial con el número de herramientas.

### Ejercicio 5 — Diseñar la siguiente observación

¿Qué necesitaría un ensayo real con un estudiante además de un informe de consultas correcto?

> **Respuesta:** Una tarea fija que identifique un cruce nombrado y su hilo superior, respuestas registradas sin ayuda y una comparación con la referencia 2D etiquetada. La interacción humana, la revisión de dominio, la revisión lingüística y la publicación siguen siendo trabajos separados pendientes. Un impacto programado solo prueba la correspondencia fuente-cuerpo de colisión especificada para los bytes ensayados.
