---
title: ¿Cuándo ayuda el jitter a una nube de voicings?
description: ¿Cuándo ayuda el jitter a una nube de voicings? — Computación visual
sidebar:
  label: VC-003 · ¿Cuándo ayuda el jitter a una nube de voicings?
  order: 3
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/es/vc-003-jitter-and-voicing-cloud-distance.es.md
---

:::note[Streeling University]
**VC-003** · ¿Cuándo ayuda el jitter a una nube de voicings? · intermedio · 35 minutos

Generado por el departamento *Computación visual* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/es/vc-003-jitter-and-voicing-cloud-distance.es.md) · [Mi diario](../../journal/)

Requisitos previos: [VC-002](../../visual-computing/vc-002-godot-react-bridge-evidence/) *(en inglés)*
:::

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de traducciones todavía no redactadas, de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) documenta los borradores traducidos actuales, la importación y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Computación Visual** | Nivel: intermedio | Duración estimada: 35 minutos | Estado: borrador en español; revisiones de materia, estudiante, localización y publicación pendientes, incluida la aprobación de una persona que domine el español

## Objetivos

Después de esta lección, podrás seguir una posición 3D de voicing por el renderizador de GA, calcular qué modifica su control de dispersión, separar la visibilidad de solapamientos de las pruebas de distancia y especificar comprobaciones ausentes en el código actual. También sabrás qué observaciones harían falta antes de recomendar un ajuste visual a músicos reales.

## La pregunta del proyecto

El Prime Radiant de GA puede colocar voicings en una nube de puntos de Three.js. Cuando muchas marcas se solapan, un control de dispersión permite verlas por separado. Un guitarrista ve dos marcas alejadas y pregunta si sus voicings están musicalmente alejados. ¿Qué debería decir la interfaz y qué coordenadas debería comparar un analista?

En la revisión fijada de GA [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924), [`VoicingCloud.ts`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/VoicingCloud.ts) obtiene un archivo auxiliar de metadatos y un búfer binario de posiciones, construye un objeto `Points` de Three.js, colorea sus puntos por instrumento y expone `setSpread` y `setPointSize`. El [código llamante de Prime Radiant](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx) intenta cargarlo cuando la URL tiene un parámetro `voicings`; `voicings_url` puede sustituir la URL de servicio predeterminada. La fuente indica qué intentaría el código, no que un servidor IX respondiera, un binario fuera válido o un usuario viera un fotograma. El recuento aproximado del corpus y el porcentaje de grupos densos del comentario no se miden de forma independiente en esta lección.

## 1. Identificar las magnitudes visuales

El cargador espera `meta.total` puntos 3D y exactamente `meta.total * 3` números de coma flotante en el búfer binario. Cada bloque de instrumento aporta un nombre, un desplazamiento en ese búfer base y un recuento. El renderizador copia cada bloque a una matriz de destino secuencial y elige un color de su mapa de guitarra, bajo o ukelele. Los nombres desconocidos reciben blanco. El color es una etiqueta de categoría; no codifica distancia musical. Los metadatos también incluyen límites, pero esta fuente solo comprueba que `bounds` se evalúe como verdadero. No utiliza esos límites para verificar cada coordenada ni ajustar la cámara automáticamente.

`PointsMaterial` empieza con tamaño `0.3`, colores de vértices, atenuación de tamaño, transparencia, opacidad `0.85` y escritura de profundidad desactivada. Son decisiones de dibujo. Una marca mayor puede ocultar más marcas cercanas y la opacidad puede cambiar el aspecto de una región densa. Ninguna opción modifica las posiciones base. Los comentarios indican dispersión predeterminada `1.5` y tamaño de punto `0.3`; las opciones de la función lo confirman. Por tanto, una vista predeterminada ya tiene dispersión salvo que el llamante proporcione `spread: 0` o después invoque `setSpread(0)`.

Usa esta **fixture sintética fija** para todos los ejercicios. Es un modelo aritmético del código, no datos IX, una captura de navegador ni una muestra medida de voicings. Supón que la estructura de metadatos supera la comprobación inicial, todas las solicitudes tienen éxito y `bounds` es `{ min: [0, 0, 0], max: [10, 0, 0] }`.

| Punto de destino | Bloque de instrumento | Posición base del binario |
|---|---|---|
| P0 | `guitar`, desplazamiento 0, recuento 2 | `(0, 0, 0)` |
| P1 | mismo bloque de guitarra | `(0.2, 0, 0)` |
| P2 | `bass`, desplazamiento 2, recuento 1 | `(10, 0, 0)` |

Aquí `meta.total = 3`; el primer bloque cubre los puntos fuente 0 y 1 y el segundo el punto fuente 2. El decimal `0.2` es aproximado al almacenarse como flotante de 32 bits. Las coordenadas son posiciones proyectadas/de visualización arbitrarias de esta fixture didáctica; no son alturas, trastes ni el vector OPTIC-K completo.

### Ejercicio 1: comprobar la longitud binaria

¿Cuántos flotantes debe contener el binario para esta fixture? ¿Qué hace el cargador fijado si contiene solo ocho y `meta.total` sigue siendo tres?

> **Respuesta:** Necesita `3 * 3 = 9` flotantes. Ocho incumple `basePositions.length !== meta.total * 3`, así que `createVoicingCloud` rechaza con un error de tamaño antes de construir el grupo de puntos. La comprobación trata el total de flotantes, no la validez de cada bloque de instrumento.

## 2. Leer la vista de referencia sin dispersión

Con `spread = 0`, `rebuildGeometry()` copia las coordenadas base de los bloques y omite su bucle de números aleatorios. En la fixture, la distancia de visualización entre P0 y P1 es aproximadamente `0.2`, y entre P1 y P2 aproximadamente `9.8`. Las dos primeras marcas tienen RGB `(0.306, 0.631, 1.000)` para guitarra; la tercera tiene `(0.482, 0.847, 0.561)` para bajo. Una llamada posterior a `setSpread(0)` reconstruye desde `basePositions` conservadas y restaura esas coordenadas en vez de deshacer un desplazamiento aleatorio anterior por sustracción.

Esta vista sin dispersión es la referencia útil cuando se pregunta por las posiciones suministradas al renderizador. Aun así, una distancia en sus tres coordenadas es solo una distancia en esta representación 3D. `VoicingCloud.ts` no define la proyección de origen ni demuestra que la distancia euclídea equivalga a similitud en el embedding OPTIC-K completo, cercanía perceptiva, facilidad de ejecución o coste de conducción de voces. Esas relaciones necesitan una proyección documentada y validación separadas. La nube solo comunica posición fielmente respecto a las posiciones suministradas; no establece por sí sola su significado musical.

### Ejercicio 2: leer la geometría de referencia

Con dispersión cero, indica las tres coordenadas x, las distancias aproximadas P0–P1 y P1–P2 y la asignación de colores. ¿Basta para ordenar las parejas por similitud OPTIC-K de alta dimensión?

> **Respuesta:** Las x son `0`, aproximadamente `0.2` y `10`; y y z son cero. Las separaciones mostradas son aproximadamente `0.2` y `9.8`. P0 y P1 usan el RGB de guitarra `(0.306, 0.631, 1.000)`; P2 usa el RGB de bajo `(0.482, 0.847, 0.561)`. Esos hechos solo ordenan distancias en las coordenadas 3D de la fixture. No establecen el orden de similitudes OPTIC-K completas.

## 3. Calcular el efecto de la dispersión

Para cada coordenada de cada bloque, el código suma `(Math.random() + Math.random() - 1) * spread` si `spread > 0`. Dos llamadas independientes a `Math.random()` producen un desplazamiento de distribución triangular centrado cerca de cero, aproximadamente entre `-spread` y `+spread` por eje. El código muestrea por separado x, y y z. Es una transformación visual; no altera `basePositions`. Puede revelar marcas separadas en un grupo, pero también crear o invertir separaciones aparentes entre puntos concretos. La fuente no proporciona un flujo aleatorio con semilla, así que repetir una llamada positiva a `setSpread` produce una disposición recién muestreada, no una reproducible.

Toma **extracciones hipotéticas**, no valores registrados del navegador: con `spread = 1.5`, supón que las extracciones x de P0 son `0.1` y `0.1`; las de P1, `0.9` y `0.9`. Supón que todas las extracciones y y z de ambos puntos son `0.5` y `0.5`, con desplazamientos nulos en esos ejes. P0 recibe `(0.1 + 0.1 - 1) * 1.5 = -1.2`, por lo que su x mostrada es `-1.2`. P1 recibe `(0.9 + 0.9 - 1) * 1.5 = 1.2`, por lo que su x mostrada es aproximadamente `1.4`. Su separación aparente es aproximadamente `2.6`, trece veces la base de `0.2`. Ningún voicing ha cambiado. Se eligieron las extracciones para mostrar el cálculo, no para estimar un resultado típico ni afirmar que un renderizado activo produjo esos puntos.

Un analista que compare estas posiciones proyectadas debería usar las coordenadas base sin dispersión o disponer de un modo sin dispersión claramente accesible. Quien deba contar o seleccionar marcas solapadas puede beneficiarse de la dispersión. Una etiqueta propuesta podría decir: «La dispersión separa las marcas solapadas para examinarlas; las distancias visibles incluyen desplazamientos aleatorios». Si se muestra una distancia entre pares, debería indicarse si procede de posiciones 3D suministradas u otra métrica definida, sin calcularla silenciosamente a partir de posiciones de pantalla perturbadas. Es una recomendación de diseño, no una función verificada en la interfaz fijada.

### Ejercicio 3: calcular una separación engañosa

Con las extracciones hipotéticas indicadas, calcula las x mostradas de P0 y P1 y su separación con dispersión `1.5`. ¿Puede citarse el resultado como disimilitud musical medida?

> **Respuesta:** P0 pasa de `0` a `-1.2`. P1 pasa de aproximadamente `0.2` a aproximadamente `1.4`. Su separación mostrada es aproximadamente `2.6`, frente a aproximadamente `0.2` antes del jitter. Ilustra extracciones aleatorias inventadas, así que no es un renderizado medido ni una prueba de disimilitud musical.

## 4. Separar controles de coordenadas y de glifos

El método `setSpread(amount)` del objeto de control actualiza la dispersión y llama a `rebuildGeometry()`. Esa función asigna nuevas matrices de posiciones y colores, vuelve a copiar el búfer base original y sustituye la geometría anterior. Por eso `setSpread(0)` proporciona una referencia estable para una fixture bien formada. En cambio, volver a llamar `setSpread(1.5)` remuestrea los desplazamientos aleatorios; no mantiene las marcas en los mismos lugares perturbados. Seleccionar un punto en una disposición dispersa y esperar que conserve su posición de pantalla tras otra llamada positiva es arriesgado sin una estrategia de selección basada en identidad.

Por comparación, `setPointSize(size)` asigna el tamaño del material sin reconstruir coordenadas. Un glifo mayor cambia el solapamiento visual, pero su centro sigue donde lo coloca la geometría actual. La fuente no implementa una capa de medidas, dispersión con semilla, animación antes/después ni leyenda de distancias. Serían posibles diseños posteriores, cada uno con su propia comprobación de comportamiento. El llamante fijado usa `createVoicingCloud(fg.scene(), { serveUrl })`, así que esta ruta utiliza dispersión y tamaño predeterminados salvo que otro código los cambie después; leer el código no muestra qué ocurrió en la pantalla de ningún usuario.

### Ejercicio 4: predecir dos controles

Tras el jitter hipotético del ejercicio 3, ¿qué ocurre con las coordenadas si se llama a `setSpread(0)`? ¿Qué ocurre si después se llama a `setPointSize(0.6)`? ¿Otra llamada a `setSpread(1.5)` conservaría las extracciones anteriores?

> **Respuesta:** `setSpread(0)` reconstruye desde el búfer base y da x `0`, aproximadamente `0.2` y `10`. `setPointSize(0.6)` solo cambia `PointsMaterial.size`, así que esos centros permanecen. Una reconstrucción posterior con dispersión positiva extrae nuevos valores; la fuente no tiene semilla ni desplazamientos guardados por punto que conserven la disposición anterior.

## 5. Hacer revisable el contrato de datos

El cargador actual comprueba que `total` sea un número, `instruments` una matriz, `bounds` se evalúe como verdadero y el binario tenga `total * 3` flotantes. No comprueba que `total` sea un entero no negativo; que desplazamientos y recuentos sean enteros no negativos dentro del búfer; que los bloques cubran cada punto exactamente una vez; que los nombres sean esperados; que las coordenadas sean finitas; ni que los límites coincidan con las posiciones. La matriz de destino empieza en cero y se rellena al copiar los bloques. Por tanto, los puntos de destino ausentes pueden permanecer en cero. Un bloque o binario mal formado puede lanzar una excepción en operaciones de matrices tipadas o colocar valores erróneos; un control global de tamaño no valida todos los datos.

Para un contrato de producción, un validador propuesto debería comprobar reglas estructurales y numéricas antes de dibujar. Debería rechazar cobertura fuente incompleta, solapada o fuera de rango; exigir que el número copiado a destino iguale `total`; comprobar coordenadas finitas y límites coherentes; y definir cómo manejar nombres desconocidos. Después el proyecto debería probar datos IX reales contra el contrato y capturar un renderizado real de navegador antes de afirmar cobertura o rendimiento. Para decidir el ajuste visual, compara tareas documentadas —contar marcas densas, seleccionar un voicing concreto y comparar posiciones 3D suministradas— con dispersión cero y varias positivas. Registra revisión de datos, cámara, tamaño, dispersión, precisión de selección y método de los participantes. Aquí no se afirma ningún estudio de usuarios ni medición de rendimiento en ejecución de ese tipo.

### Ejercicio 5: encontrar la validación ausente

Mantén `meta.total = 3` y un binario de nueve flotantes, pero cambia los bloques a `guitar` en desplazamiento 0 con recuento 1 y `bass` en desplazamiento 2 con recuento 1. Bajo las comprobaciones superficiales del código, ¿cuántos puntos de destino se rellenan? ¿Qué puede ocurrir al restante y qué regla detectaría el problema?

> **Respuesta:** Pueden pasar tanto la comprobación global de estructura de metadatos como la longitud de nueve flotantes. El bucle copia dos puntos a las posiciones de destino 0 y 1; la posición 2 queda llena de ceros, incluido el color, porque los dos recuentos suman 2 en vez de `total = 3`. Un validador que exija rangos válidos y cobertura completa sin solapamientos, con recuento total copiado 3, rechazaría esta fixture. Es razonamiento basado en código, no una prueba ejecutada del renderizador.

## Ideas clave y límites

- La dispersión revela marcas solapadas, pero cambia sus separaciones visuales. Usa una referencia sin dispersión para comparar las coordenadas 3D suministradas.
- El tamaño afecta a los glifos; la dispersión reconstruye posiciones con nuevos desplazamientos aleatorios. El color identifica la categoría instrumental en esta implementación.
- Una distancia entre puntos 3D no equivale automáticamente a una distancia OPTIC-K completa, audible o de facilidad de ejecución. La proyección y la métrica requieren pruebas separadas.
- Los cinco ejercicios utilizan una fixture sintética pequeña y extracciones elegidas explícitamente. No miden el corpus real, la densidad visual, el rendimiento, la comprensión de usuarios ni un servicio IX activo.
- Esta lección identifica comprobaciones del código y propone una validación reforzada y observación por tareas. No afirma que se hayan implementado esas comprobaciones u observaciones.

En las lecciones vecinas, [VC-001](../../visual-computing/vc-001-accessible-fretboard-paths/) aborda vías de interacción accesibles y [VC-002](../../visual-computing/vc-002-godot-react-bridge-evidence/) *(en inglés)* examina otro límite 3D: el anfitrión React y el puente Godot propuesto. Ninguna demuestra que esta nube haya superado una prueba de usabilidad. La inspección se limitó a los archivos GA fijados enlazados; no ejecutó Three.js, IX ni un navegador. La revisión humana de la materia, los intentos de estudiantes y la publicación siguen pendientes; este borrador en español requiere revisión de una persona que domine el español.

*Investigación: `visual-computing-2026-10-11-003`. Borrador en español; revisión lingüística y publicación pendientes.*
