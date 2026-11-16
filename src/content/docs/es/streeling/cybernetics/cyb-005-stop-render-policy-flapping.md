---
title: Evitar las oscilaciones de una política de renderizado
description: Evitar las oscilaciones de una política de renderizado — Cibernética
sidebar:
  label: CYB-005 · Evitar las oscilaciones de una política de renderizado
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/es/cyb-005-stop-render-policy-flapping.es.md
---

:::note[Streeling University]
**CYB-005** · Evitar las oscilaciones de una política de renderizado · intermedio · 40 minutos

Generado por el departamento *Cibernética* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/es/cyb-005-stop-render-policy-flapping.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CYB-004](../../cybernetics/cyb-004-observe-before-correcting-a-feedback-loop/)
:::

> **Alcance del borrador.** Inspección del código fuente de una revisión concreta y trazas de observaciones y decisiones construidas para el curso. Siguen pendientes la revisión técnica humana, la revisión lingüística por una persona que domine el idioma, los intentos de estudiantes, los resultados del control en funcionamiento y la verificación del HTML desplegado. No se realizó ningún experimento con un renderizador ni con una GPU para esta lección.

## La pregunta del proyecto

Un agente del Observatorio reduce el detalle visual tras un fotograma lento, lo aumenta tras uno más rápido y vuelve a reducirlo. La intervención repetida puede convertirse en parte de la perturbación. Tres mecanismos distintos ayudan a analizar ese comportamiento: la **histéresis** separa los umbrales de entrada y salida; la **persistencia** exige varias observaciones consecutivas que cumplan la condición; el **tiempo mínimo de permanencia** limita lo pronto que se permite otro cambio. Responden a preguntas diferentes y pueden retrasar una corrección útil.

El [prototipo público de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) ofrece un caso concreto. Su [bloque de control adaptativo](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L2916-L2936) ajusta los rebotes del path tracing. Inspeccionamos el código inmutable del commit de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`; esto no acredita el estado actual de la copia de trabajo modificada ni de un binario en ejecución.

## 1. Leer con precisión el controlador existente

El código comienza con tres rebotes y un tiempo de GPU suavizado igual a cero. Las consultas de tiempo que tienen éxito actualizan el valor suavizado con un factor de 0.05. Con una variante de shader `--pt` configurada (`pt.Length > 0`) y un tiempo transcurrido **estrictamente superior a un segundo** desde el último cambio, el controlador reduce un rebote si el tiempo de GPU suavizado supera su presupuesto y el número de rebotes es mayor que uno. Aumenta un rebote por debajo del 65 por ciento del presupuesto cuando el número es menor que tres. El presupuesto predeterminado es de 16 ms, de modo que el umbral de recuperación es de 10.4 ms.

La variante se configura a partir de comprobaciones de capacidades y argumentos. Un conmutador distinto en tiempo de ejecución, `rtxOn`, afecta al parámetro enviado al renderizado. Este bloque adaptativo no comprueba ese conmutador. Por tanto, su condición de configuración no acredita que el path tracing esté renderizando activamente cuando se toma una decisión.

Una consulta fallida o sin medida disponible omite este bloque de actualización. En ese bloque permanecen sin cambios el suavizado almacenado, el número de rebotes y la hora del último cambio; el reloj sigue avanzando. El bloque inspeccionado no comprueba explícitamente que el tiempo de GPU devuelto con éxito sea finito y no negativo. El éxito de la API, la disponibilidad de una observación y su validez numérica no deben tratarse como garantías idénticas.

### Ejercicio práctico 1: aplicar la condición estricta del código fuente

Supón una consulta exitosa, una variante `--pt` configurada, un tiempo suavizado de 17 ms, un presupuesto de 16 ms y tres rebotes. El último cambio ocurrió en el instante 1. ¿Qué sucede en el instante 2 y después en el instante 2.001 si las demás entradas no cambian? ¿La condición adaptativa exige además el conmutador en tiempo de ejecución?

> **Respuesta:** En el instante 2, el intervalo transcurrido equivale a un segundo, por lo que la condición estricta no permite un cambio. En el instante 2.001 supera un segundo, así que el número disminuye de tres a dos. La condición comprueba la variante configurada, no el conmutador independiente en tiempo de ejecución. Es la aplicación aritmética de las condiciones inspeccionadas, no la ejecución del renderizador.

## 2. Separar una banda neutra de una respuesta retrasada

La [documentación oficial del bloque Relay de MathWorks](https://www.mathworks.com/help/simulink/slref/relay.html) describe la conservación del estado entre umbrales de conmutación distintos. Nuestro ejemplo didáctico original usa dos ajustes: detalle alto es 1 y detalle bajo es 0. Reduce el detalle estrictamente por encima de 16 ms y lo aumenta estrictamente por debajo de 10.4 ms. Dentro de esa banda, incluida la igualdad con cualquiera de los umbrales, conserva su estado actual.

Este ejemplo es un controlador distinto al del código fuente: usa dos ajustes, ningún suavizado exponencial, dos observaciones válidas consecutivas que cumplan la condición y un tiempo mínimo de permanencia de tres segundos. Son decisiones didácticas orientativas, no una política instalada ni umbrales validados en producción. Una observación en la banda neutra reinicia la racha candidata. Una racha que cumple la condición se conserva si el tiempo de permanencia bloquea el cambio; un cambio exitoso la reinicia.

### Ejercicio práctico 2: usar la memoria de la histéresis

El controlador didáctico está actualmente en detalle bajo. Su siguiente observación es de 14 ms. ¿Debería aumentar el detalle? ¿Tomaría la misma decisión una regla sin memoria que elige detalle alto siempre que el tiempo sea como máximo de 16 ms?

> **Respuesta:** La regla con histéresis mantiene el detalle bajo: 14 ms no está por debajo de su umbral de recuperación de 10.4 ms. La regla sin memoria elige detalle alto porque 14 ms es como máximo 16 ms. El significado de la banda neutra depende del estado actual; no es un tercer ajuste de detalle ni prueba que el sistema funcione bien.

## 3. Seguir por separado la persistencia y la permanencia

Las observaciones construidas para los segundos enteros del 1 al 17 son `[15,17,15,17,15,14,17,17,14,10,10,14,17,17,10,10,10]` ms. El estado inicial es alto y el instante inicial del último cambio es cero. Estos valores son entradas sintéticas en lazo abierto: no cambian como respuesta a las acciones de la política.

La regla sin memoria cambia en los segundos `[2,3,4,5,7,9,13,15]`, ocho veces. La política didáctica cambia en `[8,11,14,17]`, cuatro veces. En el segundo 16 se han acumulado dos observaciones de recuperación, pero solo han pasado dos segundos desde el cambio en 14. En el segundo 17 se mantiene la racha que cumple la condición y se satisface el requisito de permanencia de tres segundos.

![Observaciones construidas del tiempo de GPU y trazas de ambos ajustes](https://raw.githubusercontent.com/spareilleux/learn/218a2bffc18fe2251956197e882cb6c7ea5d7962/code/streeling/evidence/observatory-decisions-2026-10-22/control-state-traces.png)

El gráfico superior muestra las observaciones construidas y los umbrales. En el inferior, `q_N` es la regla sin memoria y `q_H` la política didáctica; 1 significa detalle alto y 0 detalle bajo. Muestra trazas de decisiones, no una mejora medida de la regularidad de los fotogramas ni de la calidad de imagen.

### Ejercicio práctico 3: identificar qué condición bloquea un cambio

Indica el número de cambios de cada regla. ¿Por qué la política didáctica se recupera en el segundo 17 en lugar del segundo 16? ¿Se debe la acción más tardía a una racha de recuperación insuficiente?

> **Respuesta:** Los recuentos son ocho y cuatro. En el segundo 16 la racha de recuperación ya llega a dos, pero el tiempo de permanencia transcurrido es de solo dos segundos. En el segundo 17 la permanencia alcanza tres segundos y la racha continuada permite la recuperación. La permanencia, y no una persistencia insuficiente, bloquea el cambio anterior.

## 4. Contar observaciones antes de convertirlas en tiempo

Para la recurrencia exponencial análoga a la del código fuente, supón que cada observación construida y obtenida con éxito vale 20 ms y que el valor suavizado empieza en cero. Tras n actualizaciones, el valor es `20*(1-0.95^n)`. Supera 16 ms por primera vez en la actualización 32. Esto se refiere a actualizaciones, no a un retraso de arranque medido de 32 fotogramas o 32 segundos. Siguen importando la cadencia de consultas, la condición temporal y las demás condiciones.

El código fuente también elige su base de tiempo: la grabación usa `frame/60.0`, mientras que el funcionamiento normal utiliza los segundos de reloj transcurridos. Por tanto, una condición temporal durante la grabación puede referirse a una cronología virtual de fotogramas. Una descripción del controlador que omita su base de tiempo puede ocultar una limitación de frecuencia distinta de la que espera el lector.

### Ejercicio práctico 4: interpretar la latencia del suavizado

¿El cruce del umbral en la actualización 32 establece cuándo ocurre el primer cambio de rebotes del código fuente? Nombra las condiciones adicionales y distingue el tiempo de grabación del tiempo real transcurrido.

> **Respuesta:** No. La recurrencia solo establece un cruce del umbral para el suavizado construido. Un cambio en el código fuente exige también una consulta exitosa, una variante configurada, un número de rebotes que pueda cambiar y un tiempo transcurrido estrictamente superior a un segundo. Hace falta conocer la cadencia de actualización para convertir actualizaciones en tiempo. La grabación utiliza la cronología de fotogramas dividida entre 60; el funcionamiento normal usa el tiempo de reloj transcurrido.

## 5. Probar la capacidad de respuesta además del número de cambios

Para la traza didáctica `[17,null,17,17]`, la observación ausente reinicia la persistencia, por lo que la reducción ocurre en el segundo 4. Esa misma política construida trata las entradas iguales a cero, negativas y no finitas como inválidas, mantiene el estado y reinicia su racha. Esta política explícita no afirma que el código fuente inspeccionado implemente esas comprobaciones numéricas.

Un controlador que nunca cambia tiene cero conmutaciones, pero incumple el requisito construido de responder a una entrada que supera persistentemente el presupuesto. Por tanto, menos intervenciones por sí solas son un objetivo incompleto. La objeción más fuerte a la persistencia y la permanencia es la respuesta retrasada a una sobrecarga real. Un ajuste fijo más sencillo puede bastar si la adaptación añade complejidad sin mejorar la tarea real.

### Ejercicio práctico 5: redactar un siguiente paso refutable

Un agente informa: «cuatro cambios en vez de ocho demuestran un mejor control». Usa los controles con datos ausentes y sin acción para corregir esa conclusión y especifica una prueba que pudiera rechazar la política propuesta.

> **Respuesta:** La traza construida muestra menos decisiones bajo una regla; no mide ninguna respuesta del sistema controlado. Los datos ausentes deben reiniciar la racha definida, mientras que una regla sin acción demuestra por qué el número de cambios no basta. Una comparación real y acotada debería medir el retraso de respuesta, el rendimiento de la tarea vecina y la calidad visual bajo condiciones declaradas. Rechaza el despliegue si esos resultados incumplen los límites declarados, aunque disminuyan los cambios. Aquí no se realizó tal comparación.

El [registro de control fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/observatory-decisions-2026-10-22/control-traces.json) y el [registro de los límites del código fuente](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/observatory-decisions-2026-10-22/source-controller.json) respaldan los ejercicios. [FUT-004](../../futurology/fut-004-scenario-test-an-observatory-renderer/) pregunta cómo cambian las decisiones de política entre futuros supuestos; [PHI-004](../../philosophy/phi-004-separate-performance-tradeoffs-from-values/) examina los valores implícitos en un objetivo de rendimiento.
