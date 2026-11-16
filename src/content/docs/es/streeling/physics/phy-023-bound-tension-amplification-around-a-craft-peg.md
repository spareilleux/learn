---
title: Acotar la amplificación de tensión alrededor de un poste artesanal
description: Acotar la amplificación de tensión alrededor de un poste artesanal — Física
sidebar:
  label: PHY-023 · Acotar la amplificación de tensión alrededor de un poste artesanal
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/es/phy-023-bound-tension-amplification-around-a-craft-peg.es.md
---

:::note[Streeling University]
**PHY-023** · Acotar la amplificación de tensión alrededor de un poste artesanal · avanzado · 45 minutos

Generado por el departamento *Física* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/es/phy-023-bound-tension-amplification-around-a-craft-peg.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-019](../../physics/phy-019-test-sliding-before-calling-a-sculpture-stable/)
:::

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Una presentación de nudos usa una hebra enrollada en un poste antes del cruce destacado. Un agente propone que duplicar las vueltas solo duplica la tensión soportada. Aquí se deriva una capacidad exponencial a partir del ángulo de contacto declarado. Se aplica a una cuerda ideal flexible sobre un apoyo circular rígido, al límite del deslizamiento. La escena artesanal permite adjuntar una anotación mecánica propuesta; su mallado no demuestra fricción.

La relación límite de la fuente exige conservar dirección y frontera. Identifique la menor tensión de sujeción y la mayor tensión de carga antes de dividirlas. Por debajo del límite, la fricción no tiene por qué alcanzar su máximo en cada punto. Calcule una capacidad y compárela con la demanda; no atribuya automáticamente la razón límite a toda cuerda estática. El ángulo es el contacto total, no el cambio de dirección visible entre extremos tras descartar vueltas completas.

El control sin contacto conserva las fuerzas de los extremos y el coeficiente. La pérdida de capacidad aísla el aporte geométrico, sin cambiar material y geometría a la vez. Para una futura anotación en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) o [Godot](https://docs.godotengine.org/en/4.5/), conserve la trayectoria de contacto, el autocontacto excluido y la dirección del posible deslizamiento. Una imagen convincente de un enrollado no aporta un coeficiente de fricción. Fibras reales, un ojal de bordado anguloso o un nudo deformable pueden incumplir las premisas del poste rígido.

El ángulo de contacto se mide en radianes. Una vuelta completa aporta todo su ángulo; la dirección visible de los extremos no sustituye ese total.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "hold_N": 2,
    "mu": 0.5,
    "wrap_rad": 2,
    "load_N": 4
  },
  "formula": "ratio=exp(mu*wrap); capacity=hold*ratio; reserve=capacity-load; feasible=reserve>=0",
  "expected": {
    "ratio": 2.718281828459045,
    "capacity_N": 5.43656365691809,
    "reserve_N": 1.43656365691809,
    "feasible": true
  },
  "negative_control": {
    "values": {
      "hold_N": 2,
      "mu": 0.5,
      "wrap_rad": 0,
      "load_N": 4
    },
    "expected": {
      "ratio": 1,
      "capacity_N": 2,
      "reserve_N": -2,
      "feasible": false
    }
  }
}
```

### Ejercicio 1

Calcule la razón límite.

<details><summary>Respuesta 1</summary>

Es `2.718281828459045`, la exponencial del coeficiente por el ángulo de contacto. Es una razón de capacidad adimensional.

</details>

### Ejercicio 2

Calcule la capacidad del extremo.

<details><summary>Respuesta 2</summary>

Es `5.43656365691809 N`. Es la tensión mayor sostenible bajo la condición límite declarada, no una fuerza de cuerda observada.

</details>

### Ejercicio 3

Compare capacidad y demanda.

<details><summary>Respuesta 3</summary>

La reserva es `1.43656365691809 N`; la demanda inventada cumple esta cota estática ideal. Eso no certifica un nudo.

</details>

### Ejercicio 4

Aplique el control sin contacto.

<details><summary>Respuesta 4</summary>

La capacidad baja a `2 N`, la reserva a `-2 N` y la viabilidad resulta falsa. El coeficiente por sí solo no crea amplificación de contacto.

</details>

### Ejercicio 5

¿Toda cuerda estática alcanza la razón límite?

<details><summary>Respuesta 5</summary>

No. La igualdad describe deslizamiento inminente. Por debajo la respuesta de fricción puede ser menor; aún deben examinarse geometría y material.

</details>

## Tarea con fuentes y referencia manual directa

Anote una presentación IX propuesta con extremo de sujeción, extremo cargado y arco de contacto. Derive la capacidad a mano y compruebe si una curva Atlas permitiría identificar ese arco. Proponga una observación futura sin rellenar su resultado.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

La capacidad del control refuta una explicación que conserva amplificación después de eliminar todo ángulo de contacto.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: phy-019-test-sliding-before-calling-a-sculpture-stable](../../physics/phy-019-test-sliding-before-calling-a-sculpture-stable/)
- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://www.ocw.mit.edu/courses/8-01sc-classical-mechanics-fall-2016/mit8_01scs22_chapter8.pdf)
- [Paquete inventado](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
