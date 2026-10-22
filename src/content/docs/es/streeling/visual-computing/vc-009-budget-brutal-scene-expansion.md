---
title: Presupuestar la expansión de escenas BRUTAL antes de renderizarlas
description: Presupuestar la expansión de escenas BRUTAL antes de renderizarlas — Computación visual
sidebar:
  label: VC-009 · Presupuestar la expansión de escenas BRUTAL antes de renderizarlas
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/es/vc-009-budget-brutal-scene-expansion.es.md
---

:::note[Streeling University]
**VC-009** · Presupuestar la expansión de escenas BRUTAL antes de renderizarlas · intermedio · 35 minutos

Generado por el departamento *Computación visual* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/es/vc-009-budget-brutal-scene-expansion.es.md) · [Mi diario](../../journal/)

Requisitos previos: [VC-008](../../visual-computing/vc-008-save-and-query-a-weave-scene/), [CS-014](../../computer-science/cs-014-compose-brutal-scene-descriptions/)
:::

> **Alcance del borrador.** Nuevos resultados de generación de escenas y rechazo en CPU a partir del código público. Quedan pendientes la revisión técnica humana, la revisión por una persona que domine el idioma, las pruebas con estudiantes y la verificación del HTML público del curso. No se inició ninguna ventana gráfica, GPU, motor de renderizado ni transmisión.

## La pregunta del proyecto

Un agente compone una escena recursiva para la [evaluación BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md). ¿Cómo puede el sistema rechazar una expansión excesiva antes de crear recursos de renderizado? Una descripción pequeña puede generar muchas cajas. Acotar el crecimiento de la descripción es una tarea concreta de preparación gráfica, aunque no predice el tiempo por fotograma.

[CS-014](../../computer-science/cs-014-compose-brutal-scene-descriptions/) presenta los bloques Lego tipados. Esta lección examina sus [límites y problemas](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs#L133-L195), las [protecciones de generación](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Generate.fs) y la [frontera de validación](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Validate.fs). Todas las observaciones del código usan el commit público de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`.

## 1. Contar la representación que realmente se expande

Los límites estándar del código fuente son una profundidad máxima de 8, un máximo de 4096 instancias de bloques y un máximo de 20000 cajas. Restringen cosas diferentes. Un bloque puede emitir varias cajas sin añadir otra instancia de bloque; el anidamiento puede superar el límite de profundidad aunque la geometría total siga siendo pequeña.

Las [descripciones reales producidas en CPU](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/cpu-descriptions.json) muestran una columnata de cuatro columnas con cinco instancias y 53 cajas. Seleccionar explícitamente la segunda versión de sus columnas mantiene cinco instancias, pero eleva el número de cajas a 85. Un presupuesto basado solo en instancias pasaría por alto ese aumento de geometría.

### Ejercicio 1: elegir el contador pertinente

Compare las dos columnatas. ¿Qué cambia, qué permanece fijo y por qué el número de instancias por sí solo no basta como presupuesto de cajas?

> **Respuesta:** Las instancias siguen siendo cinco: la raíz y cuatro columnas. Las cajas aumentan de 53 a 85, una diferencia de 32, porque la versión de columna seleccionada emite más geometría. Un contador de instancias sigue los nodos de expansión; no limita la geometría por nodo sin una regla adicional. Conserve ambos contadores.

## 2. Convertir a un coste geométrico declarado

El código fuente describe cada caja como 12 triángulos. En esa representación, 53 cajas corresponden a 636 triángulos y 85 a 1020; la diferencia es de 384. El límite estándar de 20000 cajas corresponde a un presupuesto de 240000 triángulos de cajas.

Estos recuentos corresponden a la representación. No establecen las llamadas de dibujo, los vértices únicos, la memoria GPU, el sobredibujado, el coste del trazado de rayos ni el tiempo por fotograma. Una aplicación anfitriona puede instanciar geometría, añadir otros objetos o usar otras pasadas. Indique qué cantidad controla un presupuesto antes de convertirlo en una afirmación sobre el rendimiento del producto.

### Ejercicio 2: calcular el presupuesto

Con 12 triángulos por caja, calcule los costes de ambas columnatas, su diferencia y el presupuesto estándar de triángulos de cajas. ¿Pueden los números resultantes establecer los fotogramas por segundo de la escena?

> **Respuesta:** Los costes son `53*12 = 636` y `85*12 = 1020`; el aumento es de `32*12 = 384`. El presupuesto estándar es de `20000*12 = 240000` triángulos en la representación de cajas declarada. Los fotogramas por segundo requieren una carga de renderizado medida, una aplicación anfitriona y un método de medición temporal; estos recuentos por sí solos no los aportan.

## 3. Entender dónde se produce el rechazo

El [comprobante de ejecución](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/cpu-execution.json) registra 20 pruebas Release existentes superadas. También se ejecutaron por separado solicitudes CLI seleccionadas. El santuario de nivel 2 se aceptó con 756 instancias y 8505 cajas, correspondientes a 102060 triángulos de cajas. El nivel 3 devolvió el código de salida 2 y `lego-errors/1` con un problema `too-many-boxes`. La salida rechazada no contiene el recuento de una escena completa aceptada.

La generación incrementa su contador de cajas antes de comprobar si se ha superado el límite. Por tanto, la protección permite que el contador alcance 20001 con el límite estándar, mientras conserva como máximo 20000 cajas colocadas. Son cotas superiores derivadas del código fuente, sin afirmar que la escena completa de nivel 3 prevista contenga 20001 cajas. La prueba existente comprueba una detención acotada; la validación rechaza el borrador parcial cuando presenta problemas.

### Ejercicio 3: distinguir el recuento de intentos de una escena

¿Por qué puede un contador superar en una unidad el límite de cajas sin aprobar una escena demasiado grande? ¿Qué establecen el resultado aceptado de nivel 2 y el resultado rechazado de nivel 3?

> **Respuesta:** La implementación cuenta un intento de caja, detecta que el contador supera 20000, registra el problema y deja de conservar más geometría. Por eso el contador puede alcanzar 20001 mientras las cajas conservadas siguen siendo como máximo 20000. El nivel 2 produjo una descripción aceptada de 8505 cajas y 756 instancias. El nivel 3 fue rechazado; su error no es el tamaño de una escena completa ni un resultado de renderizado.

## 4. Hacer visible la convención de profundidad

La raíz tiene profundidad 0. Una profundidad máxima de 1 permite la raíz y sus hijos inmediatos, y después rechaza una expansión mayor. La solicitud de templo capturada con ese límite devolvió `too-deep`; otra solicitud limitada a 10 instancias devolvió `too-many-instances`. La batería de pruebas también verifica que una profundidad de 2 basta para el templo probado.

Por tanto, un límite de profundidad de 8 significa ocho pasos de anidamiento por debajo de la raíz, en lugar de ocho nodos incluida la raíz en cada ruta. Mantenga esa convención en un traspaso o una interfaz. Renombrar un campo como «niveles» sin definir su origen puede crear una discrepancia de una unidad entre productor y consumidor.

### Ejercicio 4: leer un rechazo por profundidad

¿Permite una profundidad máxima de 1 un nieto en la profundidad 2? ¿Por qué debe un agente mantener la distinción entre `too-deep` y `too-many-instances`, aunque ambos detengan el mismo templo solicitado?

> **Respuesta:** No. Con la raíz en profundidad 0, se permite un hijo inmediato en profundidad 1, pero un nieto en profundidad 2 supera el límite. Los dos problemas identifican restricciones distintas. Aumentar el número de instancias permitido no puede corregir por sí solo un rechazo por profundidad, y aumentar la profundidad no garantiza que se respete el presupuesto de instancias. Cambie un requisito explícito y vuelva a ejecutar su comprobación.

## 5. Combinar la validación con una comprobación de renderizado independiente

Los [comentarios públicos del punto de entrada de Colossus](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L37-L41) describen la generación y la validación antes de crear la ventana. Eso aporta evidencia del código sobre la integración prevista. Este curso ejecutó la CLI pura, sin ejecutar esa aplicación gráfica. Una descripción aceptada está lista para la siguiente frontera; no ha superado una prueba de GPU ni de coexistencia.

[PM-005](../../product-management/pm-005-interpret-brutal-coexistence-experiments/) explica por qué una tasa histórica alta de fotogramas en un proceso no basta para aprobar su ejecución junto al Observatory. Lleve a la siguiente prueba el código fuente, la semilla, las versiones, los argumentos, los límites, el formato, el estado de salida y el hash de la descripción en vez de sustituir todos esos datos por un solo contador.

### Ejercicio 5: redactar el traspaso

Un agente informa: «8505 cajas, por tanto es rápido y seguro mostrarlo junto a [Godot](https://docs.godotengine.org/en/stable/)». Sustitúyalo por un resultado respaldado y la siguiente comprobación necesaria.

> **Respuesta:** La CLI pública fijada a la revisión indicada, ejecutada solo en CPU, aceptó el santuario de nivel 2 con 8505 cajas y 756 instancias dentro de los límites registrados. Conserve su solicitud, el formato de salida, el código de salida 0 y el hash. La velocidad de renderizado, la liberación de recursos y la coexistencia con la tarea Godot adyacente requieren una prueba medida independiente en la aplicación anfitriona. La descripción aceptada no aporta ningún resultado GPU observado.

## Límites de la evidencia

El [registro de cálculos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json) separa las descripciones reales, la aritmética y las cotas derivadas de las protecciones. Estas comprobaciones finitas no demuestran que todos los bloques posibles terminen, que todos los parámetros sean seguros, que todas las aplicaciones anfitrionas respeten los límites ni que un estudiante pueda transferir el método. Solo el código público y los resultados en CPU con el alcance definido respaldan este borrador.
