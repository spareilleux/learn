---
title: Componer descripciones de escenas BRUTAL con bloques F# tipados
description: Componer descripciones de escenas BRUTAL con bloques F# tipados — Ciencias de la computación
sidebar:
  label: CS-014 · Componer descripciones de escenas BRUTAL con bloques F# tipados
  order: 14
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/es/cs-014-compose-brutal-scene-descriptions.es.md
---

:::note[Streeling University]
**CS-014** · Componer descripciones de escenas BRUTAL con bloques F# tipados · intermedio · 35 minutos

Generado por el departamento *Ciencias de la computación* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/es/cs-014-compose-brutal-scene-descriptions.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CS-010](../../computer-science/cs-010-compose-fail-fast-ga-computations/)
:::

> **Alcance del borrador.** Nueva compilación y ejecución en CPU del código público de descripción de escenas, junto con cálculos basados en el código fuente. Quedan pendientes la revisión técnica humana, la revisión por una persona que domine el idioma, las pruebas con estudiantes y la verificación del HTML público del curso. No se inició ninguna ventana gráfica, motor de renderizado, GPU, sistema de audio ni transmisión.

## La pregunta del proyecto

Un agente del Observatory debería poder solicitar una columnata, inspeccionar su estructura, cambiar la versión de un bloque y recibir un rechazo preciso antes de dibujar nada. La [evaluación BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) contiene una biblioteca Lego en F# que separa las descripciones de la aplicación que las renderiza. Su código público, fijado al commit de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`, aporta el caso de implementación de esta lección.

El [modelo tipado](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs#L87-L122) representa las alternativas mediante [uniones discriminadas de F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/discriminated-unions): `Box`, `Use`, `Attach`, `Move`, `Group` y decoración de superficies. La función `Build` de un bloque recibe argumentos y un contexto, y después describe piezas y puntos de anclaje. Un motor de renderizado puede consumir la escena resultante por separado.

Esta separación facilita la composición y la inspección. No garantiza que todas las funciones de bloque posibles sean matemáticamente puras o totales: el contexto proporciona un generador aleatorio inicializado con una semilla, y el código de generación captura los fallos de los bloques. El determinismo medido a continuación corresponde a nuevas llamadas completas de generación con entradas fijas, sin abarcar la reutilización arbitraria de un contexto aleatorio mutable ni la ejecución en paralelo.

## 1. Inspeccionar la estructura antes de materializarla

El [comprobante de ejecución en CPU](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/cpu-execution.json) registra una nueva compilación Release con el SDK 10.0.113, sin advertencias ni errores y con 20 pruebas existentes superadas. Se compilaron dos proyectos F# públicos sin cambios en un entorno autónomo temporal, con las propiedades y los destinos de compilación heredados de GA desactivados. Los hashes del código fuente y de los archivos de bloqueo permanecieron iguales. Ese alcance difiere de ejecutar una aplicación gráfica completa.

Las [selecciones de descripciones capturadas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/cpu-descriptions.json) incluyen una columnata con un número de columnas de 4, un espaciado de 3 y una semilla de 7. Tiene cinco instancias de bloques: la raíz y cuatro columnas con nombre. Sus orígenes son `(0,0,0)`, `(3,0,0)`, `(6,0,0)` y `(9,0,0)` metros. Sus 53 cajas incluyen la geometría dentro de esas instancias y el entablamento de la raíz. Una instancia de bloque y una caja no son la misma unidad.

### Ejercicio 1: leer el árbol de composición

Para un número de columnas de 4 y un espaciado de 3, indique los orígenes de las columnas y el número de instancias de bloques, incluida la raíz. ¿Por qué sería incorrecto interpretar cinco instancias como cinco cajas?

> **Respuesta:** Los orígenes son `(0,0,0)`, `(3,0,0)`, `(6,0,0)` y `(9,0,0)` metros. Las cuatro columnas más la raíz dan cinco instancias. Cada columna se expande en varias cajas, y la raíz añade la geometría del entablamento, lo que da 53 cajas en la versión capturada. Los dos recuentos describen niveles distintos de la representación.

## 2. Fijar la versión anidada, además del nombre de la raíz

Las [definiciones de bloques](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Blocks.fs#L36-L119) contienen `column@1` y `column@2`. Con cuatro tambores, producen 11 y 19 cajas respectivamente. Resolver el nombre sin versión `column` selecciona la versión instalada más alta, pero el parámetro `column` de la columnata tiene explícitamente 1 como valor predeterminado. Por tanto, una solicitud externa sin versión no actualiza automáticamente todos los bloques anidados.

La columnata de cuatro columnas aporta nueve cajas de entablamento: dos elementos horizontales y siete triglifos. Así, la versión 1 da `4*11+9 = 53`; seleccionar la versión 2 de las columnas anidadas da `4*19+9 = 85`. Fije la biblioteca, las versiones elegidas, los argumentos y la semilla cuando conserve un resultado. De lo contrario, el mismo nombre sencillo puede ocultar una descripción modificada.

### Ejercicio 2: resolver la versión deseada

Si `column` se resuelve a la versión 2, ¿debe una columnata predeterminada utilizar esa versión? Calcule el total de cajas cuando su parámetro de columna anidada vale 1 y 2, y la diferencia entre ambos.

> **Respuesta:** No. La columnata fija explícitamente en 1 el valor predeterminado de su parámetro de columna anidada. La versión 1 da `4*11+9 = 53`; la versión 2 da `4*19+9 = 85`, un aumento de 32 cajas. Registre el parámetro anidado en lugar de deducirlo de la resolución de nombres sin versión realizada en otro lugar.

## 3. Conectar a un punto de anclaje en vez de repetir su altura

La columnata conecta su entablamento al punto de anclaje `top` de la primera columna con nombre. La columna calcula ese anclaje a partir de su altura. En el caso capturado con altura 9, número de columnas 3 y espaciado 2, la primera caja del entablamento se traslada a `(2,9,0)`. Su centro horizontal sigue la extensión de la fila; su posición vertical sigue el punto de anclaje.

Esta interfaz de composición resulta útil: el padre solicita un punto de conexión en lugar de copiar los detalles de construcción del hijo. Una instancia o un punto de anclaje ausente sigue siendo un fallo significativo. Sustituirlo silenciosamente por el origen crearía una escena plausible pero incorrecta y borraría el requisito ausente del resultado del agente.

### Ejercicio 3: propagar una dimensión modificada

Para un número de columnas de 3, un espaciado de 2 y una altura de 9, deduzca el punto medio horizontal de la fila y la traslación de la primera caja del entablamento. ¿Qué información debe permanecer visible si falta el punto de anclaje requerido?

> **Respuesta:** La fila va de X 0 a X 4, por lo que su punto medio es X 2. El anclaje superior aporta Y 9; la traslación de la caja capturada es `(2,9,0)`. Conserve un rechazo que identifique la instancia o el anclaje ausente. Una colocación predeterminada en el origen ocultaría el fallo de composición.

## 4. Explicitar el orden de las transformaciones

La [convención espacial](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs) utiliza metros, el eje Y positivo hacia arriba y una guiñada positiva que gira X positivo hacia Z negativo. Sus [matrices System.Numerics](https://learn.microsoft.com/dotnet/api/system.numerics.matrix4x4) multiplican vectores fila: la matriz global de un hijo es su matriz local multiplicada por la de su padre. Una transformación aplica escala, rotación y, después, traslación.

Para el vector unitario X, una escala de 2 da `(2,0,0)`; una guiñada de 90 grados da `(0,0,-2)`; la traslación `(1,2,3)` da `(1,2,1)`. Trasladar primero y luego escalar y girar daría en cambio `(6,4,-4)`. Las pruebas de transformación existentes se superaron con su tolerancia declarada `1e-3`; el [registro aritmético](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json) mantiene separados el cálculo de ángulo recto y el control con el orden incorrecto.

### Ejercicio 4: detectar una composición reordenada

Transforme el vector unitario X con una escala de 2, una guiñada de 90 grados y la traslación `(1,2,3)` en el orden declarado. Compare con aplicar primero la traslación. ¿Puede un consumidor de escenas cambiar la convención matricial sin convertir los datos?

> **Respuesta:** El orden declarado da `(1,2,1)`; trasladar primero y luego escalar y girar da `(6,4,-4)`. Las operaciones no conmutan. Un consumidor que use otra convención matricial debe realizar una conversión explícita y verificar un punto conocido; copiar los valores con otra interpretación no basta.

## 5. Conservar el rechazo y el determinismo como propiedades distintas

Repetir la solicitud fija de columnata produjo bytes de salida y un hash de escena idénticos. Cambiar la semilla de un templo de 7 a 8 mantuvo 405 cajas y el mismo número de instancias, pero cambió su hash. Por tanto, unos recuentos iguales no demuestran que el contenido de las escenas sea idéntico. El hash describe el árbol de escena serializado; no es un hash de imagen renderizada ni un resultado de rendimiento.

La [CLI](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego.Cli/Program.fs) emite `lego-scene/1` y el código de salida 0 para una escena aceptada. Una solicitud con `count=2.5` emite `lego-errors/1` y el código de salida 2 porque el número debe ser entero. Recibir JSON no basta para declarar el éxito. [VC-009](../../visual-computing/vc-009-budget-brutal-scene-expansion/) amplía esta frontera a los límites de crecimiento.

### Ejercicio 5: interpretar el resultado del agente

Un agente recibe JSON y el código de salida 2 tras solicitar `count=2.5`; redondea el número silenciosamente e informa de una escena válida y determinista. ¿Qué resultado se observó realmente y qué debe conservar una solicitud corregida?

> **Respuesta:** El resultado observado fue una solicitud rechazada con `lego-errors/1`, no una escena aceptada. Conserve su código de salida y el motivo. Una solicitud corregida debe elegir explícitamente un número entero y conservar la identidad del código fuente y la biblioteca, las versiones, los argumentos, la semilla y los límites. La repetición puede probar el determinismo de esa nueva solicitud; no puede convertir retroactivamente el rechazo en éxito ni establecer el rendimiento del renderizado.

## Límites de la evidencia

Solo el [código público verificado de forma anónima](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/primary-readback.json) forma parte de este material didáctico. Las comprobaciones en CPU ejercitan la generación, la validación y la descripción. No demuestran un adaptador IX operativo, una escena Observatory renderizada, la liberación de recursos GPU, el comportamiento de DLSS, el aprendizaje humano ni la publicación desplegada.
