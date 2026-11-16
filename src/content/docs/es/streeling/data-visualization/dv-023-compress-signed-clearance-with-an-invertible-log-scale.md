---
title: Comprimir las holguras con signo mediante una escala logarítmica invertible
description: Comprimir las holguras con signo mediante una escala logarítmica invertible — Visualización de datos
sidebar:
  label: DV-023 · Comprimir las holguras con signo mediante una escala logarítmica invertible
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/es/dv-023-compress-signed-clearance-with-an-invertible-log-scale.es.md
---

:::note[Streeling University]
**DV-023** · Comprimir las holguras con signo mediante una escala logarítmica invertible · avanzado · 50 minutos

Generado por el departamento *Visualización de datos* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/es/dv-023-compress-signed-clearance-with-an-invertible-log-scale.es.md) · [Mi diario](../../journal/)

Requisitos previos: [DV-014](../../data-visualization/dv-014-plot-signed-craft-clearance/)
:::

> Borrador pendiente de revisión técnica y lingüística. Las entradas numéricas y los resultados previstos son casos construidos. No se aporta un nuevo ensayo de materiales, una ejecución del motor de escena, una observación del alumno ni un resultado de producción. Las decisiones humanas y del aprendizaje siguen abiertas.

## Operación del proyecto e interpretación

Un diagnóstico artesanal en [Godot](https://docs.godotengine.org/en/stable/classes/class_transform3d.html) puede contener solapamientos y holguras de magnitudes muy distintas. El logaritmo ordinario no representa cero ni valores negativos. Aquí se construye un logaritmo con signo de la magnitud escalada más la unidad, con su inversa. No es la transformación symlog por tramos de Matplotlib. Distancias visuales iguales no representan diferencias iguales en milímetros. Conserve los valores originales y la escala junto a cada marca; cambiar solo la escala mueve las marcas sin alterar la geometría.

Lea el requisito previo versionado y el pasaje delimitado de la fuente antes de calcular. Identifique la operación que necesita el proyecto, el significado de sus entradas y la afirmación que podría respaldar el resultado. El expediente conserva la revisión y el alcance realmente consultado. Separe en columnas distintas una definición documental, una premisa construida y un resultado observado. Un asistente no debe sustituir una observación ausente por una historia plausible sobre lo que probablemente hace el programa.

Explicite la representación. El JSON siguiente es una especificación matemática finita, no una sintaxis ejecutable del proyecto ni una nueva función del motor. Los nombres de campos y el orden de las identidades forman parte del caso didáctico. Lea la fórmula junto con los valores: un número aparentemente correcto obtenido bajo otra interpretación no responde a la tarea. Conserve los pasos intermedios y el control para que otra persona pueda localizar el primer desacuerdo. Las premisas son deliberadamente estrechas; ampliar el dominio exige otra justificación.

## Modelo fijado y control con otra entrada

```json
{
  "values": {
    "clearance": [
      -3,
      -1,
      0,
      1,
      3
    ],
    "scale": 1
  },
  "formula": "y=sign(x)*log(1+abs(x)/scale), sign(0)=0; inverse=sign(y)*scale*(exp(abs(y))-1)",
  "expected": {
    "positions": [
      -1.3862943611198906,
      -0.6931471805599453,
      0,
      0.6931471805599453,
      1.3862943611198906
    ],
    "roundtrip": [
      -3,
      -1,
      0,
      1,
      3
    ]
  },
  "negative_control": {
    "values": {
      "clearance": [
        -3,
        -1,
        0,
        1,
        3
      ],
      "scale": 3
    },
    "expected": {
      "positions": [
        -0.6931471805599453,
        -0.28768207245178085,
        0,
        0.28768207245178085,
        0.6931471805599453
      ],
      "roundtrip": [
        -3,
        -1,
        0,
        1,
        3
      ]
    }
  }
}
```

### Ejercicio 1

Identifique las entradas y la operación que debe conservarse.

<details><summary>Respuesta 1</summary>

> **Respuesta:** Use las entradas con signo y una escala positiva; conserve el orden y las unidades.

</details>

### Ejercicio 2

¿Qué valores con signo debe recuperar la inversa a partir de las posiciones principales mostradas?

<details><summary>Respuesta 2</summary>

> **Respuesta:** Las posiciones mostradas son los resultados logarítmicos; la inversa recupera `[-3,-1,0,1,3]` dentro de la tolerancia numérica.

</details>

### Ejercicio 3

Explique la trampa de interpretación que podría ocultar un resumen.

<details><summary>Respuesta 3</summary>

> **Respuesta:** Una holgura comprimida en pantalla no es físicamente menor; pasos visuales iguales no implican diferencias originales iguales.

</details>

### Ejercicio 4

Aplique el control modificado y compare los resultados.

<details><summary>Respuesta 4</summary>

> **Respuesta:** El control mueve los extremos aproximadamente a `-0.6931471805599453` y `0.6931471805599453`, sin cambiar la recuperación original.

</details>

### Ejercicio 5

Indique el límite y las pruebas necesarias antes de adoptar el resultado.

<details><summary>Respuesta 5</summary>

> **Respuesta:** No se realizó un ensayo de colisión o percepción; separe geometría, unidades y política visual.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje las holguras con signo de una anotación Atlas, invierta la transformación y compare la otra escala.

Con las respuestas ocultas, dibuje una tabla o un diagrama específico de la operación y calcule a mano el resultado principal. Este primer intento guardado constituye la referencia manual directa. Incluya las entradas, los valores intermedios, la regla de cada paso y el motivo de cualquier rechazo o valor sin resolver. Declare el criterio de refutación antes de pedir a un asistente que simplifique el trabajo. Una tabla corriente puede bastar; un DSL componible o un nodo agéntico necesita demostrar un beneficio adicional.

Consulte después el artefacto local y el pasaje primario enlazados. Registre la ubicación, la revisión, la definición utilizada y lo que esta no establece. Pida al asistente que cuestione una premisa y guarde la pregunta y su respuesta. Declare como ayuda cualquier calculadora, traducción o consulta documental. Compare el resultado asistido con la referencia inicial usando las mismas entradas. Rechace una explicación más breve si elimina una identidad, una condición o la distinción entre ejemplo construido y observación del proyecto.

Trate el control negativo como otro registro. Prediga su resultado antes de abrir la corrección y compare los campos modificados y los invariantes. Ante un desacuerdo, distinga error aritmético, error semántico y limitación de las premisas. Conserve el fallo, el diagnóstico, la corrección y la repetición en lugar de sobrescribir el primer intento. Entregue esas trazas con la explicación documentada y la incertidumbre restante. Este pequeño ciclo podrá apoyar el dogfooding; aquí no se ha medido una mejora real del aprendizaje o de la ejecución.

El expediente prepara un criterio por ejercicio sin completar las decisiones del aprendizaje. La respuesta real, el historial de ayuda, la corrección personal y la decisión siguen vacíos hasta que exista un intento. Revisión técnica, revisión lingüística, ejecución del motor, validación material, adopción y publicación requieren pruebas distintas. El cálculo finito solo establece la relación declarada bajo sus premisas. Antes de usarla en una escena o una herramienta de práctica, nombre la observación adicional y su umbral de rechazo; una solución preparada no equivale a aceptación.

## Criterio prospectivo de refutación

Se rechaza una respuesta si aplicar la operación mostrada a alguna entrada conservada contradice el resultado previsto, o si su explicación presenta el caso construido como una observación ya realizada en el proyecto.

## Criterios preparados para el alumno

- Conservar la respuesta correcta y el razonamiento intermedio del ejercicio 1, junto con el alcance de la afirmación. La decisión del aprendizaje sigue abierta.
- Conservar la respuesta correcta y el razonamiento intermedio del ejercicio 2, junto con el alcance de la afirmación. La decisión del aprendizaje sigue abierta.
- Conservar la respuesta correcta y el razonamiento intermedio del ejercicio 3, junto con el alcance de la afirmación. La decisión del aprendizaje sigue abierta.
- Conservar la respuesta correcta y el razonamiento intermedio del ejercicio 4, junto con el alcance de la afirmación. La decisión del aprendizaje sigue abierta.
- Conservar la respuesta correcta y el razonamiento intermedio del ejercicio 5, junto con el alcance de la afirmación. La decisión del aprendizaje sigue abierta.

## Fuentes y alcance de las afirmaciones

- [Requisito previo versionado: dv-014-plot-signed-craft-clearance](../../data-visualization/dv-014-plot-signed-craft-clearance/)
- [Artefacto local conservado](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://docs.python.org/3/library/math.html)
- [Expediente del caso construido](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
