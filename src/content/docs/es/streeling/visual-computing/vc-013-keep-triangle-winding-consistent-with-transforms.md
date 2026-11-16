---
title: Mantener coherentes el orden de los triángulos y las transformaciones
description: Mantener coherentes el orden de los triángulos y las transformaciones — Computación visual
sidebar:
  label: VC-013 · Mantener coherentes el orden de los triángulos y las transformaciones
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/es/vc-013-keep-triangle-winding-consistent-with-transforms.es.md
---

:::note[Streeling University]
**VC-013** · Mantener coherentes el orden de los triángulos y las transformaciones · intermedio · 40 minutos

Generado por el departamento *Computación visual* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/es/vc-013-keep-triangle-winding-consistent-with-transforms.es.md) · [Mi diario](../../journal/)

Requisitos previos: [SEM-006](../../semiotics/sem-006-preserve-orientation-across-scene-frames/), [PHY-008](../../physics/phy-008-keep-surface-normals-perpendicular/)
:::

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

SEM-006 mostró una cara reflejada cuyos índices sin modificar discrepaban de la convención exterior. Esta lección plantea otra pregunta: ¿quién corrige si la transformación permanece en un nodo o se incorpora a los vértices? Corregir ambos por separado puede invertir dos veces. El caso trata del seguimiento de orientación; no afirma que funcione un exportador ni una importación Godot.

[Requisito previo: sem-006-preserve-orientation-across-scene-frames](../../semiotics/sem-006-preserve-orientation-across-scene-frames/); [Requisito previo: phy-008-keep-surface-normals-perpendicular](../../physics/phy-008-keep-surface-normals-perpendicular/)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

La sección glTF sobre instanciación relaciona el orden con el determinante global. Distinga esa regla del formato de nuestra política de incorporación: tras incorporar un reflejo, el producto de aristas ordenadas debe alinearse con la referencia exterior transformada. Calcule el determinante de toda la cadena, no de una componente. Dos inversiones se cancelan. Una permutación cíclica conserva la orientación; intercambiar una pareja la invierte. Trasladar no cambia diferencias de aristas ni paridad. Un mapa singular exige un control geométrico: determinante cero impide la regla inversa de normales, pero no colapsa necesariamente cada triángulo.

## Caso fijo y supuestos

```text
A=(0,0,0); B=(2,0,0); C=(0,3,0)
(B-A) cross (C-A)=(0,0,6)
M=diag(-2,1,1); det(M)=-2
baked_cross=(0,0,-12); outward_reference=(0,0,1)
after_one_index_swap=(0,0,12)
N=diag(-1,1,1); det(M*N)=+2
Z=diag(0,1,1); triangle_cross_after_Z=(0,0,0)
```

## Ejercicios resueltos

### Ejercicio 1

Calcule el producto vectorial original y el área.

> **Respuesta:** El producto es `(0,0,6)` y el área `3` unidades de coordenadas cuadradas. La magnitud del producto duplica el área.

### Ejercicio 2

Incorpore la primera transformación. ¿Qué operación alinea la referencia exterior?

> **Respuesta:** El producto incorporado es `(0,0,-12)`. Intercambie una pareja una vez para obtener `(0,0,12)`. Es la política declarada, no una orden de duplicar una corrección del nodo.

### Ejercicio 3

Componga las dos escalas reflejadas. ¿Invierte la orientación la cadena?

> **Respuesta:** No: el determinante producto es `+2`. Intercambiar sin seguir la representación compuesta puede duplicar la corrección.

### Ejercicio 4

Aplique el control de eje nulo. ¿Repara un intercambio este triángulo?

> **Respuesta:** Su producto pasa a `(0,0,0)` y su área a `0`. Reordenar no restaura el área. La conclusión corresponde a este triángulo concreto.

### Ejercicio 5

¿Qué debe decir el adaptador además de «reflejos resueltos»?

> **Respuesta:** Indique transformaciones conservadas e incorporadas, política de índices, convención exterior y regla del consumidor. Registre la etapa correctora; la visibilidad real sigue sin observarse.

## Tarea con consulta de fuentes

Inspeccione el control histórico y la regla glTF. Prepare dos balances manuales de la misma pieza: nodo conservado y geometría incorporada. Pida ayuda para identificar quién corrige y compruébelo. Una doble corrección o supuesta reparación del triángulo colapsado refuta el traspaso.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/orientation-controls.json)
- [Fuente primaria](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#instantiation)
- [Expediente de evidencias fijas](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
