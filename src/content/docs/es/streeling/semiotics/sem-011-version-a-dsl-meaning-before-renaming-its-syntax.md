---
title: Versionar el significado de un DSL antes de renombrar su sintaxis
description: Versionar el significado de un DSL antes de renombrar su sintaxis — Semiótica
sidebar:
  label: SEM-011 · Versionar el significado de un DSL antes de renombrar su sintaxis
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/es/sem-011-version-a-dsl-meaning-before-renaming-its-syntax.es.md
---

:::note[Streeling University]
**SEM-011** · Versionar el significado de un DSL antes de renombrar su sintaxis · intermedio · 40 minutos

Generado por el departamento *Semiótica* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/es/sem-011-version-a-dsl-meaning-before-renaming-its-syntax.es.md) · [Mi diario](../../journal/)

Requisitos previos: [SEM-001](../../semiotics/sem-001-signs-in-governance/), [CS-014](../../computer-science/cs-014-compose-brutal-scene-descriptions/)
:::

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Un bloque BRUTAL conserva su nombre conocido pero genera geometría distinta. ¿Conserva su significado una instrucción antigua? A la inversa, ¿puede un token renombrado denotar la misma operación? El modelo fijado representa explícitamente nombre y versión. Esta lección usa una tabla finita de interpretación para distinguir alias y cambio semántico antes de proponer reescrituras de escenas.

[Requisito previo: sem-001-signs-in-governance](../../semiotics/sem-001-signs-in-governance/); [Requisito previo: cs-014-compose-brutal-scene-descriptions](../../computer-science/cs-014-compose-brutal-scene-descriptions/)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

En el cálculo CPU antiguo, dos versiones de columna emiten recuentos de cajas distintos para un mismo parámetro. La tabla ofrece un testigo semántico: un resultado diferente refuta significado inalterado para esa entrada. No demuestra diferencias en todas las entradas ni define equivalencia completa de escenas. Un alias sintáctico conserva el vínculo a la misma versión; reasignar silenciosamente el token antiguo a otra versión cambia la interpretación. Mantenga ambos significados accesibles cuando importe reproducibilidad. Es un argumento de migración asistido por fuentes, no un lenguaje ejecutable ni un teorema de compatibilidad.

## Caso fijo y supuestos

```text
n=4
meaning_v1(n)=3+2*n; result_v1=11
meaning_v2(n)=3+4*n; result_v2=19
difference=19-11=8
old_token="column@1"; alias="pillar@1"
alias_binding="column@1"; alias_result=11
control_n=0; control_v1=3; control_v2=3
```

## Ejercicios resueltos

### Ejercicio 1

Evalúe ambos significados para la entrada declarada.

> **Respuesta:** Los resultados son `11` y `19`, con diferencia de `8` cajas. Proceden del cálculo antiguo fijado, no de una ejecución nueva del motor.

### Ejercicio 2

¿El alias conserva este significado elegido?

> **Respuesta:** Sí, si se vincula a `column@1`, sigue dando `11`. Un token visible distinto puede denotar la misma operación versionada.

### Ejercicio 3

Vincule silenciosamente el token antiguo al segundo significado. ¿Basta conservar la sintaxis?

> **Respuesta:** No. El mismo token pasa a dar `19` en vez de `11`. Conservar la escritura no garantiza conservar la denotación.

### Ejercicio 4

¿Qué establece el control de entrada nula?

> **Respuesta:** Ambas fórmulas dan `3`. Coincidir en esa entrada ocultaría el cambio; elija una entrada admitida que distinga antes de afirmar equivalencia.

### Ejercicio 5

¿Igual número de cajas establece equivalencia completa de escenas?

> **Respuesta:** No. Pueden diferir posiciones, dimensiones, materiales, semilla y vínculos semánticos. El recuento puede refutar equivalencia, pero no identifica toda la escena.

El control de entrada nula es solo algebraico; no se afirma que sea una solicitud BRUTAL admisible.

## Tarea con consulta de fuentes

Lea BlockId y los recuentos antiguos. Prepare una tabla manual token-versión-resultado para un cambio de nombre propuesto. Pida un alias y compruebe su vínculo, no solo su redacción. Cambiar la denotación de una entrada antigua admitida refuta que el cambio conserve el significado.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json)
- [Fuente primaria](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs)
- [Expediente de evidencias fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
