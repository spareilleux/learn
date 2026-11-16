---
title: Conservar la orientación de la base tangente tras un reflejo
description: Conservar la orientación de la base tangente tras un reflejo — Computación visual
sidebar:
  label: VC-011 · Conservar la orientación de la base tangente tras un reflejo
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/es/vc-011-preserve-tangent-handedness-after-a-mirror.es.md
---

:::note[Streeling University]
**VC-011** · Conservar la orientación de la base tangente tras un reflejo · intermedio · 40 minutos

Generado por el departamento *Computación visual* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/es/vc-011-preserve-tangent-handedness-after-a-mirror.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-008](../../physics/phy-008-keep-surface-normals-perpendicular/), [VC-010](../../visual-computing/vc-010-preserve-packed-texture-channel-contracts/)
:::

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Un agente refleja un panel y conserva correctamente su normal. ¿Garantiza eso que una textura en espacio tangente describa el mismo detalle? La normal por sí sola no determina el sentido del segundo eje tangente. Esto importa para una futura transferencia de Blender a Godot, pero no se ejecutó ninguna. El requisito previo define la interpretación de los canales; esta lección reconstruye la base local que da significado a esos valores.

[Requisito previo: phy-008-keep-surface-normals-perpendicular](../../physics/phy-008-keep-surface-normals-perpendicular/); [Requisito previo: vc-010-preserve-packed-texture-channel-contracts](../../visual-computing/vc-010-preserve-packed-texture-channel-contracts/)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

La especificación glTF reconstruye la bitangente a partir de normal, tangente y componente con signo. Nuestro reflejo mantiene las coordenadas de textura ligadas a los mismos puntos materiales y refleja la base física. Compare la bitangente reflejada deseada con la reconstruida conservando el signo antiguo. Una discrepancia revela un error de base aunque la normal siga siendo perpendicular. El caso alineado con los ejes aísla la orientación; una escala no uniforme y la ortogonalización exigirían más controles. El signo tangente no ordena invertir toda la textura empaquetada ni cambiar los índices de los triángulos: esas operaciones corresponden a contratos diferentes.

## Caso fijo y supuestos

```text
N=(0,0,1); T=(1,0,0); w=+1
B=w*(N cross T)=(0,1,0)
M=diag(-1,1,1); det(M)=-1
N2=(0,0,1); T2=(-1,0,0); desired_B2=(0,1,0)
old_w_B2=(0,-1,0); corrected_w=-1
sample=(0,0.6,0.8); desired_world=(0,0.6,0.8)
wrong_world=(0,-0.6,0.8); dot=0.28
```

## Ejercicios resueltos

### Ejercicio 1

Reconstruya la bitangente original.

> **Respuesta:** El producto vectorial da `(0,1,0)` y multiplicar por `+1` no lo cambia. La normal por sí sola no codifica ese signo.

### Ejercicio 2

Conserve el signo antiguo tras el reflejo. ¿Qué falla?

> **Respuesta:** La bitangente reconstruida es `(0,-1,0)`, opuesta a la bitangente material reflejada `(0,1,0)`. La perpendicularidad no detecta este fallo.

### Ejercicio 3

¿Qué signo corrige esta base construida?

> **Respuesta:** Usar `-1` reconstruye `(0,1,0)`. Se supone conservada la correspondencia material de UV y la convención declarada de transformación.

### Ejercicio 4

Use la muestra asimétrica. ¿Es igual la dirección mundial incorrecta?

> **Respuesta:** No. La componente Y cambia de signo y las direcciones unitarias tienen producto escalar `0.28`. Una muestra `(0,0,1)` ocultaría el error y sería un control poco discriminante.

### Ejercicio 5

¿Demuestra esto un defecto visual del material del proyecto?

> **Respuesta:** No. Es un contraejemplo sobre la base. Quedan sin probar generación de UV, desempaquetado de canales, convención del motor y una importación controlada.

## Tarea con consulta de fuentes

Lea la comparación de normales y la definición tangente glTF; después anote la base reflejada de un traspaso propuesto. Conserve la tabla manual de productos vectoriales y los supuestos UV. Una bitangente reconstruida opuesta a la deseada refuta la conservación declarada.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/normal-comparison.json)
- [Fuente primaria](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#meshes)
- [Expediente de evidencias fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
