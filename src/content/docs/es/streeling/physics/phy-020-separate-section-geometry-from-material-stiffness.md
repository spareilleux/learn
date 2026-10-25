---
title: Separar la geometría de la sección de la rigidez del material
description: Separar la geometría de la sección de la rigidez del material — Física
sidebar:
  label: PHY-020 · Separar la geometría de la sección de la rigidez del material
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/es/phy-020-separate-section-geometry-from-material-stiffness.es.md
---

:::note[Streeling University]
**PHY-020** · Separar la geometría de la sección de la rigidez del material · avanzado · 45 minutos

Generado por el departamento *Física* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/es/phy-020-separate-section-geometry-from-material-stiffness.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-012](../../physics/phy-012-rotate-directional-stiffness-with-the-material/)
:::

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Una tira metálica plana y una barra cuadrada pueden tener la misma área transversal y responder de forma distinta a la flexión. Si un agente conserva solo el área o el nombre del material, pierde la distribución de materia respecto al eje. El prerrequisito trata la dirección constitutiva; aquí el material permanece isótropo y cambia la geometría de la sección.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Para el eje horizontal que pasa por el centro, integre la distancia al cuadrado sobre el rectángulo: el segundo momento de área es la anchura por la altura al cubo, dividido por la constante rectangular del paquete. Intercambiar anchura y altura cambia ese factor con el área fija. Bajo la relación lineal de curvatura adoptada explícitamente, un segundo momento mayor produce menor curvatura. Atlas crea prismas rectangulares; el helper inspeccionado no resuelve elasticidad ni certifica una tira fabricada. La sección ideal no es un recuento de triángulos.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "width_mm": 12,
    "height_mm": 3,
    "moment_Nmm": 9,
    "young_N_mm2": 1000
  },
  "formula": "I_x=width*height**3/12; I_y=height*width**3/12; curvature_x=moment/(young*I_x); curvature_y=moment/(young*I_y); ratio=I_y/I_x",
  "expected": {
    "I_x_mm4": 27,
    "I_y_mm4": 432,
    "curvature_x_per_mm": 0.0003333333333333333,
    "curvature_y_per_mm": 2.0833333333333333e-05,
    "ratio": 16
  },
  "negative_control": {
    "values": {
      "width_mm": 6,
      "height_mm": 6,
      "moment_Nmm": 9,
      "young_N_mm2": 1000
    },
    "expected": {
      "I_x_mm4": 108,
      "I_y_mm4": 108,
      "curvature_x_per_mm": 8.333333333333333e-05,
      "curvature_y_per_mm": 8.333333333333333e-05,
      "ratio": 1
    }
  }
}
```

### Ejercicio 1

Calcule los segundos momentos de área sobre los ejes centrales.

<details><summary>Respuesta 1</summary>

Son `27 mm^4` y `432 mm^4`. La unidad de cuarta potencia procede de integrar distancia al cuadrado sobre área.

</details>

### Ejercicio 2

Compare las curvaturas bajo el mismo momento.

<details><summary>Respuesta 2</summary>

Son `0.0003333333333333333 mm^-1` y `0.000020833333333333333 mm^-1`. La primera es `16` veces la segunda.

</details>

### Ejercicio 3

¿Qué cambia en el control cuadrado?

<details><summary>Respuesta 3</summary>

Ambos segundos momentos son `108 mm^4`; ambas curvaturas son `0.00008333333333333333 mm^-1` y la razón es `1`.

</details>

### Ejercicio 4

¿Una misma área conserva la respuesta a flexión?

<details><summary>Respuesta 4</summary>

No. Ambas secciones tienen `36 mm^2`, pero distribuyen la materia de forma distinta respecto a los ejes. El área no basta para reconstruir el segundo momento.

</details>

### Ejercicio 5

¿Puede un agente presentar esto como un resultado de seguridad metalúrgica?

<details><summary>Respuesta 5</summary>

No. Harían falta comportamiento material validado, mediciones de la sección real, condiciones de contorno y criterios de fallo. Este cálculo lineal inventado no aporta esas observaciones.

</details>

## Tarea con consulta de fuentes

Dibuje ambas secciones y marque sus ejes centrales. Localice las dimensiones de los prismas Atlas y prepare una lista orientativa que distinga geometría, módulo material y carga. Calcule las razones manualmente antes de proponer una notación reutilizable.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

La afirmación de que igual área e igual material implican igual curvatura direccional falla al comparar el rectángulo y el cuadrado bajo el modelo declarado.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: phy-012-rotate-directional-stiffness-with-the-material](../../physics/phy-012-rotate-directional-stiffness-with-the-material/)

- [Fuente de proyecto conservada](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)

- [Lectura primaria](https://openstax.org/books/university-physics-volume-1/pages/12-3-stress-strain-and-elastic-modulus)

- [Paquete inventado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
