---
module_id: fut-007-test-a-weave-generator-outside-its-preview
department: futurology
course: "Probar un generador de tejido fuera de su vista previa"
level: intermediate
prerequisites: ["fut-003-agent-substitution-readiness-drill", "vc-007-weave-seams-as-scene-contracts", "sem-008-interpret-layer-order-relative-to-the-reference-normal"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Probar un generador de tejido fuera de su vista previa

> **Alcance del borrador.** Cuadrículas finitas didácticas, recuentos exactos y lectura de evaluador y escena fijados a una revisión. No se entrenó ni evaluó ningún agente y no hubo un nuevo ensayo de Godot, IX ni fabricación. Quedan pendientes las revisiones humanas técnica, artesanal, lingüística y de estudiantes reales. Las fuentes públicas y el HTML desplegado del curso tienen criterios de verificación separados.

## La pregunta del proyecto

¿Justifica una vista previa perfecta sustituir una regla de creación por un agente? [FUT-003](fut-003-agent-substitution-readiness-drill.md) pregunta qué pruebas necesita una sustitución; [VC-007](../../visual-computing/en/vc-007-weave-seams-as-scene-contracts.md) comprueba cruces y uniones. Esta lección construye dos reglas que coinciden en toda una vista previa y difieren fuera. Después muestra exactamente qué puede demostrar una hipótesis estructural adicional.

El [evaluador de Demerzel de la revisión fijada](https://github.com/GuitarAlchemist/Demerzel/blob/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) acepta dos variantes nombradas de paridad. Su [caso de prueba](https://github.com/GuitarAlchemist/Demerzel/blob/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json) define un ensayo finito concreto. La regla adversaria siguiente es didáctica; no es una variante admitida por el evaluador ni un modelo aprendido observado.

## 1. Explicitar el dominio no observado

Usa coordenadas enteras no negativas en una cuadrícula objetivo de 8 por 8. La vista previa contiene la región de 6 por 6 en su origen, con los 36 booleanos de cruce conocidos exactamente. Esto aporta pruebas más fuertes que una imagen por sí sola.

Define `G(x,y)=((x+y)%2==0)`. Define `H` igual a `G` dentro de la vista previa y con valor verdadero fuera de ella en este objetivo finito. Las dos reglas coinciden en cada cruce de la vista previa. Sin embargo, en la coordenada `(6,1)`, `G` es falso y `H` es verdadero.

### Ejercicio 1: producir un testigo fuera de la vista previa

Evalúa ambas reglas en `(6,1)`. ¿Por qué comprobar todos los booleanos de la vista previa seguiría sin detectar el fallo? ¿Demuestra un fallo de un agente real entrenado?

> **Respuesta:** La suma es 7, así que `G` es falso; la coordenada queda fuera de la vista previa, así que `H` es verdadero. Las 36 etiquetas de vista previa coinciden por construcción. Es un contraejemplo didáctico a una inferencia desde coincidencia en la vista previa, no un fallo observado de un agente entrenado.

## 2. Contar ambigüedad sin inventar probabilidades

El objetivo tiene 64 celdas y quedan 28 fuera de la vista previa. Sin ninguna regla que restrinja esos booleanos, hay `2^28=268435456` formas compatibles de completar la cuadrícula. Cuenta asignaciones finitas; no da probabilidad de que una sea correcta ni una tasa esperada de error de un agente.

### Ejercicio 2: identificar la hipótesis tras el recuento

Deriva el número de celdas no observadas y formas compatibles de completar la cuadrícula. ¿Seguiría siendo adecuado el recuento si se exigiera que cada pareja adyacente tuviera valores distintos?

> **Respuesta:** Hay `64-36=28` celdas no observadas y `2^28=268435456` formas de completar sin restricciones. Exigir que cada pareja adyacente difiera acopla las celdas, así que ya no son elecciones binarias independientes. Esa restricción estructural define otra clase de hipótesis.

## 3. Inspeccionar el objetivo finito completo

Una cuadrícula de 8 por 8 tiene 112 parejas de vecinos horizontales o verticales. El [registro didáctico de cuadrícula](../../../../code/streeling/evidence/weave-material-2026-10-22/generator-scope.json) da 14 desacuerdos de cruces entre las reglas, todos fuera de la vista previa. `G` no tiene infracciones por vecinos iguales; `H` tiene 46. Contar desacuerdos de cruces y contar infracciones de adyacencia mide cosas distintas.

Para el segundo recuento, la franja no observada de dos columnas aporta 14 parejas verticales y 8 horizontales iguales. La franja inferior restante, de 6 columnas de ancho y 2 filas de alto, aporta 10 parejas horizontales y 6 verticales. Entre ambas franjas hay 2 parejas iguales más; sus interfaces con la vista previa añaden 6, sumando 46. Estas franjas particionan la región no observada sin contar dos veces. Es un cálculo finito didáctico, no salida del evaluador ni de la escena existentes.

### Ejercicio 3: elegir el recuento correcto de fallos

Un agente informa «14 infracciones» tras comparar etiquetas de cruces. Corrige el informe, deriva el total de parejas adyacentes y justifica las 46 parejas de vecinos iguales mediante la partición en franjas. ¿Qué deberían decir las pruebas sobre ejecución de herramientas?

> **Respuesta:** Hay 14 desacuerdos de etiquetas con la regla objetivo, pero 46 infracciones por vecinos iguales para `H`. La cuadrícula tiene `8*7+8*7=112` parejas vecinas. La partición en franjas da `14+8+10+6+2+6=46` parejas iguales, incluidas las interfaces. El informe debe nombrar la métrica y decir que son comprobaciones finitas didácticas; no se ejecutaron ni el evaluador de Demerzel ni Godot sobre `H`.

## 4. Añadir una regla y demostrar solo sus consecuencias

Impón ahora una premisa separada: cada pareja vecina debe diferir. El grafo de la cuadrícula es conexo y bipartito. Elegir el valor del origen determina todos los demás por paridad de caminos, dando exactamente 2 asignaciones completas. La fase observada del origen selecciona 1. Un recorrido del grafo puede construir esas asignaciones; no hace falta enumerar todas las cuadrículas objetivo binarias.

Es una demostración condicional para la clase elegida de alternancia binaria. No muestra que un generador entrenado descubriera la regla, que todo textil deba alternar ni que cualquier patrón resultante pueda fabricarse. [SEM-008](../../semiotics/en/sem-008-interpret-layer-order-relative-to-the-reference-normal.md) explica por qué el significado de una etiqueta de orden también necesita referencia y roles.

### Ejercicio 4: distinguir una demostración de pruebas de aprendizaje

¿Por qué hay 2 formas estructurales de completar antes de observar el origen y 1 después? Indica las hipótesis y una afirmación de capacidad que la demostración no establece.

> **Respuesta:** La conexión propaga un valor elegido del origen a través de todas las restricciones de adyacencia; el carácter bipartito hace coherente la propagación. Cada valor de origen da una forma de completar y la fase observada fija cuál. Supone la cuadrícula conexa declarada, etiquetas binarias y la regla completa de alternancia de vecinos. No establece aprendizaje real, viabilidad física del tejido ni capacidad de creación sin restricciones.

## 5. Diseñar un ensayo refutable de sustitución

El evaluador existente informa de recuentos de infracciones; un recuento no nulo no es por sí solo una excepción que rechace una variante. Sus nombres admitidos y comprobaciones de dimensiones son separados. El [controlador de Learn de la revisión fijada](https://github.com/spareilleux/learn/blob/eebf49cb0b69a314bd13015340335a983aa64bfe/code/streeling/weave-godot/trial.gd) admite un manifiesto concreto de 36 cruces. Nuestra tabla didáctica mayor no se convierte por ello en entrada aceptada de escena.

### Ejercicio 5: preparar un futuro experimento con acceso a las fuentes

Lee evaluador, caso de prueba y controlador. Propón una comparación acotada para un agente o DSL componible de creación, con referencia sencilla, condición de rechazo y límite honesto de afirmaciones.

> **Respuesta:** Fija programa, revisión, dominio de entrada, semántica de etiquetas y reglas de admisión. Fija antes de comparar tamaños no observados, uniones y transformaciones de roles y marcos. Compara con la regla sencilla de paridad global y un validador independiente; conserva por separado contraejemplos y métricas de desacuerdo y adyacencia, junto con coste y evaluación humana artesanal. Rechaza una ventaja afirmada si desaparece fuera de la vista previa o incumple los criterios declarados de aceptación. Una escena mayor también necesita cambio de adaptador o admisión y su propia prueba. La aritmética actual demuestra solo los ejemplos finitos y el resultado estructural condicional; no se demostraron agente entrenado, DSL nuevo, integración en ejecución, beneficio de estudiantes ni éxito de fabricación.
