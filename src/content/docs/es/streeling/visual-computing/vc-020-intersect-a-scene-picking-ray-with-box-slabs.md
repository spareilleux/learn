---
title: Intersectar un rayo de selección con las franjas de una caja
description: Intersectar un rayo de selección con las franjas de una caja — Computación visual
sidebar:
  label: VC-020 · Intersectar un rayo de selección con las franjas de una caja
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/es/vc-020-intersect-a-scene-picking-ray-with-box-slabs.es.md
---

:::note[Streeling University]
**VC-020** · Intersectar un rayo de selección con las franjas de una caja · avanzado · 45 minutos

Generado por el departamento *Computación visual* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/es/vc-020-intersect-a-scene-picking-ray-with-box-slabs.es.md) · [Mi diario](../../journal/)

Requisitos previos: [VC-008](../../visual-computing/vc-008-save-and-query-a-weave-scene/)
:::

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

La escena tejida distingue la identidad del cruce alcanzado de la etiqueta de hebra. Antes de examinar geometría detallada de bordado o escultura, un futuro selector puede descartar candidatos cuyas cajas envolventes no alcanza el rayo. La intersección de caja es un filtrado amplio: permite excluir un candidato sin certificar un impacto superficial. Aquí se calcula a mano el intervalo permitido del parámetro, conservando esa asimetría de evidencia.

Trate la caja como intersección de franjas por coordenadas. Cada coordenada no paralela aporta un intervalo de parámetros en el que el rayo queda entre mínimo y máximo. Intersecte esos intervalos con el segmento hacia delante. Una coordenada paralela necesita otra rama: su origen ya está dentro de toda la franja o nunca entra. Sustituir una división por cero por un número enorme oculta la diferencia. El control coloca el origen fuera de una franja paralela sin cambiar la coordenada recorrida.

El parámetro solo es distancia con la normalización y las unidades correspondientes. Un futuro traspaso debe conservar los marcos de caja y rayo, el límite frontal y el predicado detallado posterior. Los límites de grupos BRUTAL pueden señalar una escultura para inspección; no identifican la marca cincelada seleccionada. Mantenga separados caja fallada, mallado sin probar e impacto detallado confirmado.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "minimum": [
      0,
      0,
      0
    ],
    "maximum": [
      2,
      2,
      2
    ],
    "origin": [
      -2,
      1,
      1
    ],
    "direction": [
      1,
      0,
      0
    ],
    "t_max": 10
  },
  "formula": "start=[0,t_max]; for each nonzero direction intersect with sorted((minimum-origin)/direction,(maximum-origin)/direction); zero direction outside slab rejects; hit iff resulting interval nonempty",
  "expected": {
    "hit": true,
    "t_enter": 2,
    "t_exit": 4
  },
  "negative_control": {
    "values": {
      "minimum": [
        0,
        0,
        0
      ],
      "maximum": [
        2,
        2,
        2
      ],
      "origin": [
        -2,
        3,
        1
      ],
      "direction": [
        1,
        0,
        0
      ],
      "t_max": 10
    },
    "expected": {
      "hit": false,
      "t_enter": null,
      "t_exit": null
    }
  }
}
```

### Ejercicio 1

Halle el intervalo del eje recorrido.

<details><summary>Respuesta 1</summary>

Es `[2,4]`. Ordene los parámetros de frontera antes de intersectar para admitir también direcciones negativas.

</details>

### Ejercicio 2

Trate las coordenadas paralelas.

<details><summary>Respuesta 2</summary>

Ambos orígenes están dentro de sus franjas cerradas y no añaden restricciones. No hace falta dividir por una dirección nula.

</details>

### Ejercicio 3

Aplique el límite frontal.

<details><summary>Respuesta 3</summary>

El intervalo sigue siendo `[2,4]` dentro de `[0,10]`; el modelo indica impacto en caja. La salida pertenece a la caja cerrada.

</details>

### Ejercicio 4

Evalúe el control con origen desplazado.

<details><summary>Respuesta 4</summary>

Falla porque el origen paralelo queda fuera de la franja. Entrada y salida son `null`; el intervalo del otro eje no lo salva.

</details>

### Ejercicio 5

¿Un impacto de caja demuestra selección de cruce?

<details><summary>Respuesta 5</summary>

No. La consulta superficial y la correspondencia de identidad son predicados distintos; la caja también contiene espacio vacío.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje rayo y franjas para un selector de escultura propuesto antes de pedir un resumen del ensayo. Prepare una tabla manual de intervalos y especifique la consulta detallada de identidad posterior.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

La franja paralela refuta admitir el control solo porque coincide el intervalo del eje recorrido.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: vc-008-save-and-query-a-weave-scene](../../visual-computing/vc-008-save-and-query-a-weave-scene/)
- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/streeling/weave-godot/trial.gd)
- [Lectura primaria](https://pbr-book.org/4ed/Shapes/Basic_Shape_Interface)
- [Paquete inventado](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
