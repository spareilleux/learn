---
module_id: dv-012-compute-quantiles-before-combining-latency-cohorts
department: data-visualization
course: "Calcular los cuantiles antes de combinar cohortes de latencia"
level: intermediate
prerequisites: ["dv-003-instrument-cohorts-and-units", "dv-005-baselines-alerts-and-targets"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Calcular los cuantiles antes de combinar cohortes de latencia

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Un informe del renderizador GA y un worker de publicación proporcionan una duración mediana cada uno. ¿Puede el panel promediar esas medianas para obtener la de todas las solicitudes? El registro histórico BRUTAL ya advierte que los puntos de medición diferían entre informes y que la coexistencia seguía siendo inconclusa. Conservamos ese límite y usamos muestras nuevas inventadas solo para estudiar cuantiles combinados.

[Requisito previo: dv-003-instrument-cohorts-and-units](../../data-visualization/en/dv-003-instrument-cohorts-and-units.md); [Requisito previo: dv-005-baselines-alerts-and-targets](../../data-visualization/en/dv-005-baselines-alerts-and-targets.md)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

NIST presenta varias convenciones de percentiles; elija la regla antes de comparar. Aquí use el rango superior: ordene las observaciones finitas y elija el elemento situado en el techo de probabilidad por recuento, empezando los rangos en uno. Es una convención didáctica explícita, no una descripción de todas las métricas del proyecto. Combine datos solo si unidades, extremos de medición y poblaciones previstas son comparables. El promedio de cuantiles de subgrupos no tiene por qué ser un cuantil global. Los valores idénticos siguen siendo observaciones distintas en esta lista, sin demostrar independencia ni representatividad.

## Caso fijo y supuestos

```text
A_ms=[1,2,100]; B_ms=[3,4,5,6,7]
Q(p,x)=sorted(x)[ceil(p*len(x))-1]
Q(0.5,A)=2; Q(0.5,B)=5; mean_medians=3.5
pooled_ms=[1,2,3,4,5,6,7,100]; Q(0.5,pooled)=4
Q(0.9,A)=100; Q(0.9,B)=7; Q(0.9,pooled)=100
control_A_ms=[2,2]; control_B_ms=[2,2,2]; Q(0.5,control_pooled)=2
```

## Ejercicios resueltos

### Ejercicio 1

Halle ambas medianas según la regla declarada.

> **Respuesta:** Son `2 ms` y `5 ms`. Su media simple es `3.5 ms`: otro resumen, no la mediana combinada.

### Ejercicio 2

Calcule la mediana combinada.

> **Respuesta:** Hay `8` observaciones ordenadas. El rango `4` da `4 ms`. La regla declarada importa en esta muestra de tamaño par.

### Ejercicio 3

Halle el cuantil superior combinado del modelo.

> **Respuesta:** Para `0.9`, el rango `8` da `100 ms`. Promediar los valores de grupos daría `53.5 ms`, que no es este cuantil combinado.

### Ejercicio 4

¿Qué muestra el control de valores constantes?

> **Respuesta:** Todas las medianas valen `2 ms`. Puede haber coincidencia: se refuta una regla general, no toda posibilidad de igualdad.

### Ejercicio 5

¿Pueden combinarse tiempos antiguos con extremos distintos tras convertir unidades?

> **Respuesta:** No. Las unidades no reconcilian intervalos medidos distintos. Conserve controles fallidos e inconclusos; solicite extremos comunes y muestras originales.

## Tarea con consulta de fuentes

Lea los campos de extremos temporales de la comparación histórica. Prepare una tabla manual que separe muestras inventadas compatibles de mediciones antiguas incomparables. Pida una propuesta de texto y refútela si sustituye medianas promediadas o fusiona extremos distintos.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](../../../../code/streeling/evidence/brutal-composition-2026-10-22/historical-comparison.json)
- [Fuente primaria](https://www.itl.nist.gov/div898/handbook/prc/section2/prc262.htm)
- [Expediente de evidencias fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
