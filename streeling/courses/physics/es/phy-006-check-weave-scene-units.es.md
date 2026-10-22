---
module_id: phy-006-check-weave-scene-units
department: physics
course: "Comprobar las unidades de una escena de tejido"
level: intermediate
prerequisites: [phy-005-sheet-thickness-and-scene-units]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Comprobar las unidades de una escena de tejido

> **Borrador fuente redactado por IA.** Quedan pendientes las revisiones humanas de un especialista, una persona con dominio del idioma y un estudiante. La publicación HTML pública del curso sigue pendiente.

[PHY-005](phy-005-sheet-thickness-and-scene-units.md) exige una escala declarada. Este adaptador de [Godot](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html) la aplica a representaciones guardadas de un tejido. El entregable es una auditoría que rechace escenas con una escala incorrecta. Consulte el [README del laboratorio](../../../../code/streeling/weave-godot/README.md), el [README de evidencias](../../../../code/streeling/evidence/weave-scene-2026-10-22/README.md) y la [tarea del estudiante](../../../../code/streeling/evidence/weave-scene-2026-10-22/learner-task.md). El README de evidencias conserva los detalles de ejecución y los fallos.

Resultado verificado en Windows: el guardado, la carga y los 36 sondeos físicos pasaron; los controles de escala, vinculación del cuerpo de colisión y paridad reiniciada fallaron en las comprobaciones identificadas. Los fallos anteriores del lanzador no aportan pruebas de la escena.

## 1. Declarar la interpretación física

El [evaluador](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) y la [especificación](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json), fijados a una revisión, definen `odd-tile-seam-a`: paso de 5 mm y diámetro nominal de 2 mm. Una baldosa de 3 × 3 repetida 2 × 2 produce 6 × 6 cruces. La paridad global tiene 0 infracciones de adyacencia; la reiniciada tiene 12 y debe rechazarse antes de construir la escena.

El adaptador elige una unidad de escena por metro y representa el diámetro mediante grosor de caja. La urdimbre se extiende por Z y la trama por X. Los cruces contienen segmentos aislados. Esta interpretación es una entrada declarada, no una medición textil.

### Ejercicio 1 — Leer la escala

Convierta el paso de 5 mm y el grosor de 2 mm a la convención declarada. Calcule grosor dividido entre paso.

> **Respuesta:** El paso es `5 × 0.001 = 0.005 m`; el grosor es `2 × 0.001 = 0.002 m`. La razón sin dimensiones es `2/5 = 0.4`. Debe conservarse al aplicar una escala uniforme coherente, pero por sí sola no identifica la escala absoluta de la escena.

## 2. Comprobar posiciones y dimensiones por separado

Los índices de cruce van de 0 a 5. Por tanto, `w3-f0` está en X `3 × 0.005 = 0.015 m`, y la última coordenada es `5 × 0.005 = 0.025 m`. Seis centros de cruce delimitan cinco pasos intermedios. Afirmar que la distancia entre centros extremos es 0.030 m confunde un recuento de objetos con uno de intervalos.

Las dimensiones `(X,Y,Z)` de la caja de urdimbre son `(0.002,0.002,0.004) m`; las de la trama son `(0.004,0.002,0.002) m`. Sus ejes largos diferentes codifican las direcciones de los hilos. Comprobar solo la posición no detectaría una longitud errónea ni ejes intercambiados. Los límites de [MeshInstance3D](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html) cargado ofrecen una observación independiente del tamaño.

### Ejercicio 2 — Diagnosticar dos errores

Una escena coloca `w3-f0` en X 15 y asigna a ambas cajas `(0.004,0.002,0.002)`. Identifique los errores independientes.

> **Respuesta:** X 15 es 1000 veces el valor 0.015 requerido en la convención métrica. El eje largo de la urdimbre también es incorrecto: debe extenderse por Z con `(0.002,0.002,0.004)`. Corregir la posición no corrige las dimensiones ni la convención de orientación.

## 3. Deducir la separación vertical

Los centros de las cajas superior e inferior están en Y `+0.0015 m` y `-0.0015 m`. El grosor es 0.002 m, así que cada semigrosor es 0.001 m. La base superior está en `0.0015 - 0.001 = 0.0005 m`; el techo inferior está en `-0.0015 + 0.001 = -0.0005 m`. La diferencia es `0.001 m`, o 1 mm.

El ensayo compara los límites [AABB](https://docs.godotengine.org/en/4.6/classes/class_aabb.html) transformados tras la carga. Estas cajas sin rotación, alineadas con los ejes, permiten inspeccionar la separación vertical. No establecen holgura de fabricación, contacto entre cilindros, flexión ni un recorrido que conecte los segmentos. Una geometría girada o curva requiere otro argumento.

### Ejercicio 3 — Distinguir separación y centros

Alguien informa de 3 mm de holgura porque los centros distan 3 mm. Corrija el cálculo.

> **Respuesta:** Reste ambos semigrosores a la distancia entre centros: `3 - 1 - 1 = 1 mm`. La distancia entre centros no es la holgura entre superficies. El resultado corresponde a las cajas declaradas sin rotación, no a tela real.

## 4. Usar un control de escala independiente

Si el verificador multiplica los valores esperados por el `MM_TO_M` del constructor, cambiar esa constante puede desplazar construcción y expectativas a la vez. El laboratorio fija en cambio expectativas métricas independientes. En una copia temporal, cambie únicamente el `MM_TO_M` del constructor de `0.001` a `1`. La comprobación llamada `independent_world_metres` debe rechazar el resultado; conservar las razones no detecta este factor uniforme de 1000.

Con [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), [Python](https://docs.python.org/3/using/cmdline.html) y Godot 4.6.1 instalados y disponibles en `PATH`, use un directorio de salida nuevo fuera del checkout:

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json
```

El comando se escribe igual en cada sistema. Windows se ha probado; Linux/WSL y macOS siguen por verificar. Conserve hashes de las fuentes originales y modificadas, informes reales y registros. Un fallo al arrancar es distinto de un predicado métrico falso y no aporta ninguna prueba nueva de la escena.

### Ejercicio 4 — Poner a prueba el verificador

Todas las razones siguen siendo 0.4 tras la modificación. ¿Invalida eso el control negativo?

> **Respuesta:** No. Las razones son deliberadamente insensibles a la escala uniforme. La expectativa absoluta independiente X 0.015 m en `w3-f0`, junto con las comprobaciones de grosor y centros, debe fallar. Si la ejecución modificada no arranca, el resultado previsto del control queda sin evaluar.

## 5. Transmitir solo la afirmación acotada

Observe, cambie una magnitud, repita, conserve el fallo y explique su alcance. Una auditoría correcta respaldaría estas coordenadas cargadas y los límites de las cajas para estos bytes fuente. No aporta propiedades materiales medidas. Compruebe el estado de ejecución en el README de evidencias antes de afirmar que pasó.

Combinar validación semántica, serialización y comprobaciones dimensionales es una hipótesis sobre la utilidad del proceso de inspección. La referencia 2D etiquetada, más barata, puede mostrar la misma escala y paridad. Afirmar un mejor aprendizaje exige una comparación independiente de tareas, con errores sin ayuda y esfuerzo invertido.

### Ejercicio 5 — Redactar un traspaso honesto

Escriba una conclusión de dos frases cuando pasen los predicados geométricos, pero no haya ensayos con estudiantes ni materiales.

> **Respuesta:** «Para el manifiesto fijado y la convención métrica declarada, las cajas aisladas cargadas cumplen las posiciones, dimensiones y separación vertical AABB de 0.001 m registradas. Esto no establece comportamiento de hilo continuo, holgura de fabricación, beneficio educativo ni revisiones de dominio e idioma completadas». Adjunte el registro real y use una formulación condicional si la ejecución sigue pendiente.
