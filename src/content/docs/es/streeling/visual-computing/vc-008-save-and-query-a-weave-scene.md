---
title: Guardar y consultar una escena de tejido
description: Guardar y consultar una escena de tejido — Computación visual
sidebar:
  label: VC-008 · Guardar y consultar una escena de tejido
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/es/vc-008-save-and-query-a-weave-scene.es.md
---

:::note[Streeling University]
**VC-008** · Guardar y consultar una escena de tejido · intermedio · 45 minutos

Generado por el departamento *Computación visual* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/es/vc-008-save-and-query-a-weave-scene.es.md) · [Mi diario](../../journal/)

Requisitos previos: [VC-007](../../visual-computing/vc-007-weave-seams-as-scene-contracts/)
:::

> **Borrador fuente redactado por IA.** Quedan pendientes las revisiones humanas de un especialista, una persona con dominio del idioma y un estudiante. La publicación HTML pública del curso sigue pendiente.

[VC-007](../../visual-computing/vc-007-weave-seams-as-scene-contracts/) comprueba un tejido sintético antes de renderizarlo. Este curso pregunta si los cruces admitidos sobreviven al guardado y la carga nativos de una escena de [Godot](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html) y siguen siendo consultables. El entregable es un registro que identifique el artefacto guardado, las observaciones tras la carga y los límites de la conclusión. Consulte el [README del laboratorio](https://github.com/spareilleux/learn/blob/main/code/streeling/weave-godot/README.md), el [README de evidencias](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/README.md) y la [tarea del estudiante](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-scene-2026-10-22/learner-task.md). El README de evidencias conserva los detalles de ejecución y los fallos.

Resultado verificado en Windows: el guardado, la carga y los 36 sondeos físicos pasaron; los controles de escala, vinculación del cuerpo de colisión y paridad reiniciada fallaron en las comprobaciones identificadas. Los fallos anteriores del lanzador no aportan pruebas de la escena.

## 1. Admitir un modelo declarado

El [evaluador](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) y la [especificación](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json), inmutables, describen `odd-tile-seam-a`: una baldosa de 3 × 3 repetida 2 × 2 produce 6 × 6, es decir, 36 cruces. La paridad global tiene 0 infracciones de adyacencia; reiniciar la paridad en cada baldosa produce 12. La admisión rechaza esta última antes de crear la escena. Una apariencia convincente no corrige ese fallo semántico.

El adaptador crea dos segmentos de caja aislados por cruce. La urdimbre sigue el eje Z del mundo y la trama el eje X. El diámetro nominal de 2 mm se representa como grosor de caja, sin modelar un hilo cilíndrico. Los segmentos no establecen continuidad del hilo, tensión ni contacto textil. Este modelo pequeño permite inspeccionar la transferencia sin pretender implementar un exportador general.

### Ejercicio 1 — Situar el límite

La variante reiniciada produce 12 infracciones, pero podría generar una imagen atractiva. ¿Debe llegar a la construcción de la escena?

> **Respuesta:** No. `semantic_admission` debe rechazarla antes de crear un proyecto Godot. Conserve el informe semántico y el fallo; el atractivo visual no demuestra que la alternancia declarada haya sobrevivido a la composición.

## 2. Hacer observable la persistencia

Un árbol de nodos activo no basta para demostrar el contenido de una escena guardada. [PackedScene](https://docs.godotengine.org/en/4.6/classes/class_packedscene.html) agrupa nodos para instanciarlos; el adaptador asigna propietarios a los cruces, las mallas, los cuerpos y las formas de colisión para incluir los descendientes previstos. También adjunta metadatos de cruce y de hilo, y el resumen criptográfico del manifiesto fuente. Omitir la propiedad puede perder descendientes aunque el árbol original parezca completo.

El ensayo empaqueta la raíz, guarda `weave.tscn`, libera el árbol original, carga los bytes guardados, instancia un árbol nuevo y espera la sincronización física. Las observaciones se refieren entonces a la instancia cargada. Se esperan 36 padres de cruce y 72 mallas, cuerpos estáticos y formas de colisión de cada categoría. Dos recursos compartidos de cada tipo de malla, forma y material evitan crear 72 copias distintas; compartir recursos es independiente del número de instancias.

### Ejercicio 2 — Cuestionar una afirmación de guardado

Un informe cuenta 72 mallas antes de guardar y nunca libera el original. ¿Qué observación adicional hace falta?

> **Respuesta:** Elimine el original, cargue e instancie el artefacto guardado, cuente los descendientes cargados e inspeccione sus metadatos. Una llamada de guardado correcta y un árbol original completo no demuestran que la propiedad haya conservado los descendientes necesarios.

## 3. Consultar la representación cargada

Cada [MeshInstance3D](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html) muestra una representación simplificada, mientras un cuerpo estático y una forma de colisión permiten consultarla. Tras la carga, [PhysicsDirectSpaceState3D.intersect_ray](https://docs.godotengine.org/en/4.6/classes/class_physicsdirectspacestate3d.html) lanza 36 rayos descendentes por los centros esperados, definidos de manera independiente. Los metadatos del cuerpo alcanzado deben devolver el cruce solicitado y el hilo superior esperado. En `w2-f0`, está arriba la urdimbre; en `w3-f0`, la trama.

Son sondeos físicos automatizados. No establecen la precisión de una selección humana ni la visibilidad en una imagen renderizada. Esta tarea carece de cámara, resaltado y captura de pantalla. Una posición de malla correcta tampoco demuestra que el cuerpo de colisión esté vinculado al ID fuente adecuado.

### Ejercicio 3 — Interpretar un impacto

Un rayo dirigido a `w3-f0` alcanza la geometría de la trama, pero informa `w2-f0`. ¿Qué requisito falla?

> **Respuesta:** Falla `ray_crossing_identity` aunque pasen `ray_upper_strand` y las comprobaciones geométricas. La escena ha resuelto el cruce fuente equivocado. Conserve ambos resultados en vez de reducirlos a «el rayo alcanzó algo».

## 4. Reproducir con procedencia

Con [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), [Python](https://docs.python.org/3/using/cmdline.html) y Godot 4.6.1 instalados y disponibles en `PATH`, ejecute desde la raíz del repositorio:

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json
```

Use un directorio de salida nuevo fuera del checkout y entradas externas sin cambios. El ejecutor registra hashes SHA-256 de entradas y archivos didácticos, el resumen del manifiesto, los registros y los informes; el informe Godot registra el resumen de la escena. Compare los bytes con su procedencia, no solo los nombres. El comando se escribe igual en todos los sistemas; solo se ha probado Windows, mientras Linux/WSL y macOS siguen por verificar.

### Ejercicio 4 — Distinguir los fallos

Godot supera el tiempo de espera al arrancar después de la admisión semántica. ¿Puede el resultado semántico certificar la escena nueva?

> **Respuesta:** No. Conserve los registros de arranque y el informe de ejecución fallido. Un fallo de entorno o ejecución es distinto de un rechazo semántico, pero no aporta ninguna prueba nueva del guardado, la carga o la física. Repita en un directorio nuevo e informe del resultado real.

## 5. Conservar un contraejemplo útil

Observe la referencia, cambie una sola suposición, repita, conserve el fallo y limite la afirmación. En una copia temporal, cambiar únicamente `crossing_id` del cuerpo de colisión debe hacer fallar la identidad; cambiar únicamente `MM_TO_M` del constructor debe hacer fallar las expectativas métricas independientes. Ninguno de estos controles demuestra por sí solo el valor didáctico. Lea el README de evidencias antes de describirlos como ejecutados.

La composabilidad es una hipótesis probada en este límite. Conectar más herramientas no acelera automáticamente el progreso. Compare cualquier explicación 3D propuesta con la alternativa más barata: evaluador y cuadrícula 2D etiquetada, usando la misma tarea de aprendizaje. Registre respuestas sin ayuda y esfuerzo de mantenimiento antes de afirmar una ventaja o proponer un DSL.

### Ejercicio 5 — Redactar la conclusión de entrega

¿Qué puede respaldar un ciclo completo de guardado y carga correcto, y qué evidencia adicional justificaría preferirlo a 2D?

> **Respuesta:** Respalda la persistencia y la corrección de las consultas programadas para estas entradas fijadas y representaciones aisladas. Todavía hace falta una comparación controlada con estudiantes para justificar una preferencia educativa. Quedan pendientes las revisiones de dominio, idioma, aprendizaje y publicación; el éxito técnico no implica simulación textil, integración en producción ni resultados de interacción humana.
