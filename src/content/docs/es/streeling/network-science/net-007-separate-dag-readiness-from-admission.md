---
title: Distinguir los nodos listos de un DAG de su admisión a los workers
description: Distinguir los nodos listos de un DAG de su admisión a los workers — Ciencia de redes
sidebar:
  label: NET-007 · Distinguir los nodos listos de un DAG de su admisión a los workers
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/es/net-007-separate-dag-readiness-from-admission.es.md
---

:::note[Streeling University]
**NET-007** · Distinguir los nodos listos de un DAG de su admisión a los workers · intermedio · 35 minutos

Generado por el departamento *Ciencia de redes* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/es/net-007-separate-dag-readiness-from-admission.es.md) · [Mi diario](../../journal/)

Requisitos previos: [NET-005](../../network-science/net-005-fanout-results-and-dependency-joins/)
:::

> **Alcance del borrador.** Cinco archivos públicos de IX fijados a una revisión, tres respuestas reales de la herramienta de topología, tres respuestas acotadas de la herramienta de ejecución y planificaciones creadas para el curso. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML del curso desplegado. No se implementaron un planificador de producción, un límite de workers, un mecanismo de reintentos ni cambios en el editor; no se midió la concurrencia real de los workers.

## La pregunta del proyecto

Un editor de pipelines de IX muestra ocho nodos independientes. ¿Puede un agente lanzar ocho workers porque todos los nodos estén listos? Un grafo de dependencias indica qué entradas preceden a un cálculo. La admisión en tiempo de ejecución necesita además capacidad y una política aplicable. [NET-005](../../network-science/net-005-fanout-results-and-dependency-joins/) examinó las uniones y la conservación de resultados de las ramas; aquí examinamos la distancia entre la estructura del grafo y los recursos de ejecución.

La [implementación pública del DAG de IX](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-pipeline/src/dag.rs) rechaza ciclos y calcula órdenes y niveles topológicos. Todas las observaciones del código fuente de esta lección usan el commit `456df065ee837e33b5bbe22a4df0616a4fcb76e5`. Las respuestas reales de las herramientas tienen una revisión de servicio desconocida y siguen siendo pruebas separadas.

## 1. Un nivel describe qué está listo según las dependencias

Las [pruebas reales de topología](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/topology-tool-probes.json) incluyen un rombo con aristas de a a b, de a a c, de b a d y de c a d. Sus conjuntos por nivel son a, después b y c, después d. La herramienta indica cuatro nodos, cuatro aristas y paralelismo máximo 2. Aquí ese campo describe el mayor nivel devuelto, no una medición de workers en ejecución.

Una segunda entrada tiene ocho nodos y ninguna arista. Indica un nivel que contiene los ocho y paralelismo máximo 8. Una entrada cíclica de dos nodos devuelve un error. Rechazar ciclos protege la estructura acíclica del grafo; no elige cuántos nodos listos deben ejecutarse simultáneamente.

### Ejercicio 1: interpretar la anchura indicada

Indica los conjuntos por nivel del rombo y la anchura informada. Si la máquina solo tiene una plaza de worker disponible, ¿se vuelven cíclicas o inválidas las dependencias?

> **Respuesta:** Los niveles son a, después b y c, después d; la anchura indicada es 2. Una sola plaza de worker no hace cíclico el grafo. Cambia la planificación de ejecución posible: b y c pueden ejecutarse secuencialmente conservando todas las dependencias.

## 2. Añadir una restricción de recursos explícita

El [modelo de planificación creado para el curso](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/admission-model.json) supone ocho trabajos independientes de un paso de tiempo cada uno, dos workers, sin sobrecarga ni desalojo. Cuatro tandas de dos trabajos terminan en 4 pasos, con un máximo de 2 trabajos activos. Inicialmente siguen estando listos 8 aunque solo puedan admitirse 2.

Para el rombo, supón duraciones a=1, b=4, c=2 y d=1 pasos. Dos workers pueden ejecutar a de 0 a 1, b de 1 a 5, c de 1 a 3 y d de 5 a 6. La ruta a-b-d tarda 6 pasos; un worker necesita 8 pasos para los cuatro trabajos. Son planificaciones construidas con costes declarados, no tiempos medidos de IX. La topología por sí sola no proporcionó esos costes.

### Ejercicio 2: calcular una planificación que tenga en cuenta la capacidad

¿Cuántas tandas necesitan los ocho trabajos unitarios con dos plazas? Para el rombo ponderado, indica el tiempo de finalización con dos workers y el total con uno. ¿Una anchura topológica de 2 implica una aceleración de 2?

> **Respuesta:** Los ocho trabajos necesitan cuatro tandas y 4 pasos. El rombo termina en 6 pasos con la planificación dada de dos workers, frente a 8 con uno. La aceleración es `8/6`, no 2: la ruta de dependencias y las duraciones desiguales limitan la ganancia.

## 3. Leer el flujo de control en lugar de confiar en una etiqueta de paralelismo

El [ejecutor ix-agent](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-agent/src/tools.rs#L408-L450) de la revisión fijada recorre el orden topológico y llama a una herramienta por iteración. Otro [ejecutor ix-pipeline](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-pipeline/src/executor.rs#L115-L243) anuncia hilos paralelos en comentarios, pero su rama multinodo inspeccionada llama directamente a compute dentro de un map de iterador seguido de una recolección. No crea hilos en ese punto. La [referencia de iteradores de Rust](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.map) describe map como una transformación de iterador; esta expresión síncrona de map y recolección no proporciona por sí misma planificación paralela.

La descripción inicial del código se dejó guiar demasiado por los comentarios. El [registro de producción del curso](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/production-plan.md) conserva esa corrección. La descripción del código de ninguna de las dos rutas demuestra concurrencia medida en el servicio desplegado. Del mismo modo, la ausencia de un campo de límite de workers no demuestra que este código lance hilos sin límite.

### Ejercicio 3: cuestionar la inferencia

Un panel dice «nivel paralelo» y un comentario del código dice «hilos std». Una persona revisora concluye que se lanzaron ocho hilos. ¿Qué observación adicional del código contradice esa inferencia y qué pruebas en ejecución determinarían la concurrencia real?

> **Respuesta:** La rama inspeccionada llama a compute de forma síncrona en map y recolección, y no contiene creación de hilos ahí. Las etiquetas no prueban que haya ocho hilos ejecutándose. Una ejecución instrumentada con observaciones de inicio y fin de intentos e identidades de contextos de ejecución podría medir el solapamiento; no se realizó esa medición de concurrencia para esta lección.

## 4. Distinguir los órdenes parciales de un orden total elegido

Las [pruebas reales de ejecución](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/execution-tool-probes.json) envían dos veces el mismo pequeño pipeline estadístico de tres pasos. Ambas conservan first antes de second y third. La primera indica first, second, third; la repetición indica first, third, second. Los resultados numéricos son iguales. Ambos órdenes satisfacen las dependencias declaradas.

El código del DAG de la revisión fijada estabiliza explícitamente su orden por la posición de inserción. Por tanto, los distintos órdenes reales de pasos hermanos no pueden utilizarse como certificación de ejecución de ese código exacto. Conserva ambas observaciones y la revisión desconocida del servicio. No ordenes silenciosamente los registros brutos ni describas esta pareja como prueba de un orden determinista.

### Ejercicio 4: identificar el invariante conservado

Los dos órdenes observados solo difieren en second y third. ¿Qué invariante de dependencias se conserva? ¿Pueden los resultados numéricos iguales o los dos órdenes demostrar que el servidor ejecuta la revisión fijada de orden determinista?

> **Respuesta:** First precede a ambos pasos dependientes en cada orden. Los resultados numéricos iguales no establecen la identidad de la implementación, y el cambio de orden no certifica el código de orden determinista de la revisión fijada. La revisión real del servidor sigue siendo desconocida.

## 5. Dar a un editor estados que pueda justificar

Un vocabulario propuesto para el editor distingue listo según las dependencias, admitido, en ejecución y completado. Son candidatos de diseño específicos de la tarea, no estados instalados en IX. Un nodo listo espera una decisión de capacidad; uno admitido tiene una plaza; estar en ejecución necesita un inicio de intento observado; la finalización necesita una observación terminal. Los fallos, las dependencias bloqueadas y las observaciones ausentes necesitan significados propios en lugar de mostrarse como un mismo estado inactivo genérico.

En la prueba de fallo deliberado, una herramienta ausente produce un error sin un agregado final por paso. La respuesta no enumera qué trabajo previo se ejecutó ni da estados de omisión posteriores. Conserva esa limitación en lugar de inventar una cronología completa para el editor. [CYB-006](../../cybernetics/cyb-006-bound-retry-feedback-and-workload/) examina la carga adicional creada cuando las observaciones ausentes provocan reintentos.

### Ejercicio 5: delimitar una comprobación de admisión propuesta

Ocho nodos han satisfecho sus dependencias, pero solo hay dos plazas disponibles. Según el vocabulario propuesto, ¿pueden marcarse los ocho como en ejecución? Indica las observaciones necesarias para marcar un nodo concreto como en ejecución y completado.

> **Respuesta:** No. Se admiten como máximo dos según la restricción de capacidad indicada, y la admisión sigue sin demostrar un inicio. Estar en ejecución requiere un inicio de intento observado; estar completado requiere su resultado terminal. Los demás nodos listos conservan su estado de dependencias mientras esperan capacidad. Es un contrato propuesto, no un informe del comportamiento instalado en el editor.

## Tarea del estudiante con acceso a las fuentes

Completa la [tarea preparada](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/learner-task.md) antes de leer su rúbrica. Reconstruye niveles, planificaciones y límites de las pruebas; después propón la visualización de admisión más pequeña que resulte útil. Aún no se han registrado resultados independientes de estudiantes ni de revisión humana.
