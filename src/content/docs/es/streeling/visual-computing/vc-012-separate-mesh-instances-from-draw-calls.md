---
title: Distinguir instancias de malla y llamadas de dibujo
description: Distinguir instancias de malla y llamadas de dibujo — Computación visual
sidebar:
  label: VC-012 · Distinguir instancias de malla y llamadas de dibujo
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/es/vc-012-separate-mesh-instances-from-draw-calls.es.md
---

:::note[Streeling University]
**VC-012** · Distinguir instancias de malla y llamadas de dibujo · intermedio · 40 minutos

Generado por el departamento *Computación visual* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/es/vc-012-separate-mesh-instances-from-draw-calls.es.md) · [Mi diario](../../journal/)

Requisitos previos: [VC-009](../../visual-computing/vc-009-budget-brutal-scene-expansion/)
:::

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Las antiguas descripciones CPU de BRUTAL cuentan instancias de bloques y cajas. ¿Puede un agente convertir cualquiera de esas cifras directamente en llamadas de dibujo de una vista Godot? Una instancia de bloque es un nodo descriptivo, una caja es una primitiva descrita y una llamada pertenece a una ruta de renderizado. El proyecto debe distinguir esas cantidades antes de usar la agrupación como argumento de rendimiento.

[Requisito previo: vc-009-budget-brutal-scene-expansion](../../visual-computing/vc-009-budget-brutal-scene-expansion/)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

Godot documenta MultiMesh como mecanismo de instanciación y advierte que la indexación espacial considera el grupo un solo objeto. Construimos un modelo limitado: una superficie, un material por grupo, un número declarado de pasadas, todas las instancias visibles, sin sombras ni trabajo adicional. El cálculo compara envíos separados y agrupados bajo esos supuestos. No predice un contador real. Cambiar grupos o pasadas cambia el modelo. La descripción aceptada y la solicitud mayor rechazada siguen siendo resultados CPU; derivar un presupuesto no los convierte en un ensayo gráfico.

## Caso fijo y supuestos

```text
historical_v1: block_instances=5; boxes=53; triangles=636
historical_v2: block_instances=5; boxes=85; triangles=1020
authored_instances=60; groups=3; passes=2
separate_submissions=60*2=120
grouped_submissions=3*2=6
reduction=120-6=114
control_groups=60; control_submissions=60*2=120
```

## Ejercicios resueltos

### Ejercicio 1

¿Qué cantidad antigua cambia entre versiones de columna?

> **Respuesta:** Las cajas pasan de `53` a `85`; las instancias de bloques siguen en `5`. Ninguna cifra indica llamadas observadas.

### Ejercicio 2

Calcule el presupuesto de envíos separados.

> **Respuesta:** Es `120` bajo el modelo estipulado de pasadas y visibilidad. Es un cálculo, no una observación de GPU.

### Ejercicio 3

Calcule los envíos agrupados y la reducción modelada.

> **Respuesta:** Hay `6` envíos agrupados y `114` menos que en el caso separado. Esto no determina el ahorro de tiempo por fotograma.

### Ejercicio 4

Use un grupo incompatible por instancia. ¿Qué ocurre?

> **Respuesta:** El control vuelve a dar `120` envíos y elimina la reducción modelada. Reutilizar una malla no garantiza agrupación.

### Ejercicio 5

¿Puede el traspaso afirmar que la escena agrupada es más rápida?

> **Respuesta:** No. Puede declarar el modelo condicional. La ruta real exige contadores medidos, carga y comportamiento de visibilidad; el descarte grueso por grupo puede cambiar el trabajo.

## Tarea con consulta de fuentes

Lea los contadores antiguos y la documentación MultiMesh. Prepare una tabla asistida con nodos, cajas, instancias de malla y envíos modelados; deje desconocidas las llamadas medidas. Compárela con una agrupación manual. Una carga compatible que requiera otros envíos refutaría la aplicabilidad del modelo.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json)
- [Fuente primaria](https://docs.godotengine.org/en/4.6/classes/class_multimesh.html)
- [Expediente de evidencias fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
