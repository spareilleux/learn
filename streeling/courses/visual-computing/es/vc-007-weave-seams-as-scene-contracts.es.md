---
module_id: vc-007-weave-seams-as-scene-contracts
department: visual-computing
course: "Conservar los cruces del tejido al atravesar un límite de escena de Godot"
level: intermediate
prerequisites: [vc-005-craft-details-through-blender-to-godot]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
research_cycle: visual-computing-2026-10-12-007
version: "0.1.0"
---

# Conservar los cruces del tejido al atravesar un límite de escena de Godot

> **Alcance del borrador y las traducciones.** El texto técnico siguiente es un borrador fechado. Las menciones históricas de traducciones, integración en Learn o comprobaciones de publicación pendientes corresponden a aquella etapa; este [registro de traducción](../../../../code/streeling/evidence/locale-completion-2026-10-22/README.md) documenta los borradores actuales y las comprobaciones realizadas. Los ensayos de ejecución no realizados siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Computación Visual** | Intermedio | 40 minutos | Borrador en español; fixture sintética de cruces, sin importación Godot, prueba con estudiantes, revisión humana ni publicación; aprobación de una persona que domine el español pendiente

## Objetivos y pregunta del proyecto

Después de esta lección, podrás distinguir el orden de cruces de un tejido de su apariencia renderizada, encontrar un error de composición en la unión de módulos, dar identidades estables a los cruces y diseñar una condición de escena Godot que rechace una muestra visualmente atractiva pero incorrecta. **Pregunta del proyecto:** si un detalle tejido se convierte en objeto del observatorio Godot propuesto, ¿cómo puede sobrevivir su estructura encima/debajo a repetición y renderizado? Es un modelo de ligamento tafetán deliberadamente limitado, no una simulación de tensión del hilo, una afirmación histórica sobre textiles ni una función Godot terminada.

[VC-005](vc-005-craft-details-through-blender-to-godot.md) pregunta si la limpieza de mallas en Blender podría borrar un detalle artesanal pequeño. Comprueba qué sobrevive al pipeline de recursos. Aquí el fallo puede ocurrir antes: un módulo puede componerse en un patrón incorrecto antes de existir una malla. Un [plan fijado de integración Godot de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md) esboza un observatorio, pero su escena propuesta no demuestra que esta muestra se haya importado. La [fixture y el evaluador](https://github.com/GuitarAlchemist/Demerzel/tree/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007) de este curso son ejecutables, sintéticos e independientes de un renderizador.

## 1. Poner la semántica artesanal antes que los píxeles

La fixture empieza con un módulo de 3 por 3 cruces. Un hilo de urdimbre sigue una dirección declarada y otro de trama la otra. En coordenadas globales `(x, y)`, la regla simplificada coloca la urdimbre sobre la trama si `(x + y + phase) % 2 == 0`; en caso contrario, la trama queda encima. `phase = 0`. Es una abstracción elegida para el ejercicio. Las estructuras, materiales y prácticas textiles reales pueden ser más variadas. Aquí el contrato solo exige que la alternancia de tafetán *declarada* siga cumpliéndose tras componer.

La fixture repite el módulo dos veces por dirección, dando seis posiciones de urdimbre, seis de trama y `6 × 6 = 36` cruces. El par `(x, y)` recibe un ID `w<x>-f<y>`. Los ID son globales: `w3-f0` significa el mismo cruce antes y después de generar malla o escena. Color, cámara y altura aparente de hilos pueden ayudar al observador, pero no sustituyen identidad ni valor encima/debajo. El renderizador debería recibir el manifiesto validado, no inventar otra regla desde un prompt o shader.

### Ejercicio 1: nombrar el cruce

Con fase cero, ¿qué ID y valores encima/debajo tienen `(2, 0)` y `(3, 0)`? ¿Por qué hay que asignar ID antes de renderizar la escena?

> **Respuesta:** Los ID son `w2-f0` y `w3-f0`. Como `2 + 0` es par, la urdimbre queda encima en `w2-f0`; como `3 + 0` es impar, la trama queda encima en `w3-f0`. Los ID estables permiten a una prueba de importación comparar escena y manifiesto fuente y localizar un cruce erróneo. Una captura sola no establece qué cruce representa un resaltado visible.

## 2. Encontrar la unión que omite una prueba local

Hay dos formas de repetir el módulo. La **paridad global** evalúa la regla en todas las coordenadas 6 por 6. La **paridad reiniciada por módulo** evalúa `x % 3` e `y % 3` en cada copia. Cada módulo de 3 por 3 alterna localmente bajo la regla reiniciada. Sin embargo, al ser impar su anchura, su última columna y la primera del siguiente módulo indican ambas urdimbre encima en la primera fila. La unión vertical tiene un defecto análogo. Es un error de composición, no un problema de textura.

Ejecuta `python state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py` desde la raíz de Demerzel con la [entrada local de prueba](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json). Enumera los 36 cruces según cada regla, comprueba pares adyacentes horizontal y verticalmente e informa de los ID exactos que incumplen. Para la fixture suministrada, la paridad global da 0 incumplimientos de adyacencia; la reiniciada da 12. Seis son pares de uniones horizontales y seis verticales. En la intersección de uniones se notifican dos pares adyacentes distintos; el recuento es de *relaciones* incumplidas, no de píxeles defectuosos ni ID únicos de cruces. El evaluador también rechaza una muestra cuyo diámetro de hilo sea mayor o igual al espaciado. Su relación espaciado/diámetro `5 / 2 = 2.5` es solo una comprobación de coherencia de entrada, no una prueba de holgura física ni de ausencia de colisiones.

### Ejercicio 2: localizar el primer contraejemplo

La primera fila del resultado reiniciado es `warp, weft, warp, warp, weft, warp`. ¿Qué par adyacente falla y cuál debería ser el cuarto valor con la regla global? ¿Una vista previa correcta de 3 por 3 valida la muestra de 6 por 6?

> **Respuesta:** `w2-f0` y `w3-f0` indican ambos urdimbre encima, así que incumplen la alternancia. Con paridad global, `w3-f0` debería indicar trama encima. Una vista local correcta no valida la composición porque nunca examina el límite entre módulos.

## 3. Separar identidad, semántica y geometría

Un manifiesto de exportación para una prueba debería incluir hash del programa fuente, ID de muestra, dimensiones, convención de escala física, ID estables de cruces y cada valor encima/debajo. El JSON proporcionado es una *especificación de prueba* de la que el evaluador deriva valores; no es un manifiesto Godot exportado. Un futuro adaptador puede usar el resultado para construir segmentos de malla o instanciar nodos, pero debe conservar ID y valores. Si una textura tejida visualmente correcta carece de correspondencia con los cruces, los revisores no sabrán si sigue el programa o solo se le parece.

Utiliza tres condiciones. La **condición semántica** comprueba ID únicos, 36 cruces esperados y cero incumplimientos. La **condición geométrica** comprueba que existan ambos hilos en cada cruce, que la relación encima/debajo se refleje en coordenadas de malla o escena y que la escala sea coherente. La **condición perceptiva** ofrece cámara fija y pide identificar un cruce y el hilo superior. Superar una no implica superar las demás. Un manifiesto puede ser correcto mientras los cilindros se intersecan o la cámara oculta la relación. A la inversa, una imagen convincente puede ocultar paridad reiniciada en una unión.

### Ejercicio 3: clasificar el comprobante

Una futura captura Godot parece tejida. El manifiesto tiene 36 ID únicos y cero incumplimientos. Un clic en `w3-f0` resalta `w2-f0` y no se registró ninguna comprobación de coordenadas de malla. ¿Qué condiciones tienen pruebas y cuáles quedan abiertas?

> **Respuesta:** El manifiesto respalda la condición semántica del patrón declarado. El resaltado incorrecto incumple el vínculo de identidad de la escena y la ausencia de coordenadas deja la geometría sin evaluar. La captura sola no certifica orden de cruces ni comprensión. Corrige la correspondencia, registra coordenadas encima/debajo y repite la interacción antes de dar por satisfactoria la prueba de escena.

## 4. Comparar la regla con una alternativa de escena más barata

El objeto Godot propuesto debe competir con un diagrama o etiqueta simple, no solo con una escena vacía. Si el propósito es explicar una dependencia de gobernanza, una cuadrícula 2D etiquetada puede comunicarla con más fiabilidad que un tejido 3D. Una muestra 3D solo justifica su mantenimiento si mejora una tarea de aprendizaje o inspección predeclarada. Mantén fijos cámara, iluminación, etiquetas, texto de tarea y dimensiones. Conserva JSON del programa, manifiesto derivado, registro de importación, capturas brutas, trazas de clics y respuestas por estudiante. Registra tiempo por fotograma por separado; los triángulos por sí solos no miden comprensión.

Un DSL solo es útil si reduce errores o esfuerzo de autoría frente a un manifiesto simple y un validador pequeño. La fixture demuestra un invariante de composición y un contraejemplo, no que deba adoptarse un lenguaje nuevo. Los costes ocultos incluyen unidades, ID al editar, correspondencia de cruces a malla, validación de exportación, accesibilidad y explicar cómo un segmento visible representa una relación semántica. La propuesta de DSL quedaría refutada si un manifiesto JSON ordinario y un validador corto ofrecen igual corrección y autoría más rápida en una tarea repetida.

### Ejercicio 4: diseñar la comparación

A usa paridad global, cámara fija y material simple. B reinicia paridad en cada módulo, cambia cámara y añade colores de alto contraste. Cinco observadores prefieren B. ¿Qué se concluye y qué repetición con una sola variable debe hacerse primero?

> **Respuesta:** La preferencia no demuestra que la unión sea correcta ni que la cámara o el color causaran la preferencia. B tiene 12 relaciones adyacentes incumplidas en la fixture. Compara primero ambas reglas con iguales cámara, material, etiquetas y tarea; conserva el resultado del validador y la respuesta de cada observador. Después varía cámara o material independientemente. Si la condición semántica es obligatoria, B se rechaza aunque parezca mejor.

## 5. Definir una condición de publicación que pueda fallar

Antes de colocar la muestra en un observatorio, exige programa fuente y manifiesto derivado versionados, importación Godot con correspondencia estable de ID a objeto, traza reproducible de interacción de al menos un cruce a cada lado de una unión y captura bruta con vista fija. Decide tarea de estudiante y límite de rendimiento antes de ejecutarla. Una muestra con un cruce sin vincular o unión rota falla aunque su captura sea atractiva. Una topología correcta con peor comprensión que una referencia 2D debe revisarse en vez de promocionarse como mejora educativa.

Esta condición es expresamente más estricta que ejecutar el evaluador Python. No se incluye importación Godot, captura GPU, medida de tiempo por fotograma ni comparación de estudiantes. La fixture ejecutable solo demuestra que las dos reglas difieren bajo un comprobador declarado. No demuestra comportamiento real de tela ni calidad del renderizador. Mantén visible ese límite al informar de avances en ComfyUI, Blender, Godot o una publicación posterior.

### Ejercicio 5: decidir con pruebas mixtas

Supón que un adaptador exporta los 36 ID, una autoprueba Godot confirma cero incumplimientos del manifiesto y una captura es clara. Un clic en la unión devuelve el cruce equivocado una vez en diez repeticiones. Tres de cuatro estudiantes identifican el hilo superior frente a cuatro de cuatro en un diagrama 2D etiquetado; el tiempo por fotograma está dentro del presupuesto. ¿Debe aceptarse la muestra 3D según esta lección?

> **Respuesta:** No. El clic incorrecto incumple el requisito de vínculo de identidad y la prueba pequeña no supera la referencia 2D declarada. Conserva hashes fuente y salida, revisión de escena, registro de importación, diez trazas brutas, capturas, respuestas individuales y muestras de tiempo por fotograma. Corrige el vínculo y vuelve a probar la explicación con la misma tarea. Estas cifras son datos hipotéticos de ejercicio, no resultados medidos del proyecto.

## Pruebas y límites

- La fixture en el commit Demerzel `f23ccae6c049d9066a1be2221c68f3b0bcf48373` ofrece recuentos reproducibles para una regla sintética de paridad. Es un comprobador educativo, no un simulador textil ni un renderizador Godot.
- El plan fijado de GA motiva un posible uso en el observatorio; no demuestra una importación activa de esta muestra. VC-005 aporta la cuestión de limpieza de recursos, mientras esta lección prueba composición antes de exportar.
- Los recuentos de observadores, el error de clic y el resultado de tiempo por fotograma de los ejercicios 4 y 5 son inventados. No se afirma revisión humana, intento de estudiante, captura de escena, publicación ni comprobación pública anónima. El ciclo anterior del original inglés tampoco afirmaba traducción; este borrador en español requiere revisión de una persona que domine el español.
