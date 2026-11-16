---
module_id: "sem-019-distinguish-knot-diagram-reversal-from-mirroring"
department: "semiotics"
course: "Distinguir recorrido inverso y reflejo de un diagrama de nudo"
level: "advanced"
prerequisites: ["sem-005-bind-scene-hits-to-crossing-identity"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Distinguir recorrido inverso y reflejo de un diagrama de nudo

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Un ornamento de nudo reflejado y el mismo recorrido al revés pueden conservar todos los identificadores de cruce cambiando aspectos distintos del significado. El curso de correspondencia de cruces no decide si debe cambiar una anotación firmada. Aquí declaramos una convención de pantalla orientada y calculamos cada signo con el determinante de tangentes del paso superior e inferior. La tabla es inventada; no reconstruye un nudo físico ni prueba que los cruces formen una curva cerrada embebida.

La suma de signos da el writhe del diagrama. Invertir el recorrido de toda la componente invierte ambas tangentes de cada cruce, conservando el signo. Reflejar una coordenada de pantalla invierte la orientación del plano y todos los signos. Conserve el orden superior/inferior en ambas operaciones. Intercambiar esos papeles por error añadiría otra inversión y ocultaría el efecto del espejo.

Los apuntes de Calegari distinguen writhe de diagrama e invariante de isotopía ambiente: añadir un rizo de Reidemeister lo cambia. La lección permite una anotación acotada sobre este diagrama y transformaciones declaradas, sin prueba universal de identidad de nudos. Un futuro ornamento [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) o [Godot](https://docs.godotengine.org/en/4.5/) debe conservar referentes de cruce, orientación de pantalla e historial junto al número. El asistente no puede concluir nudos iguales por writhe igual ni tipos físicos distintos por un cambio de writhe.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "over_tangents": [
      [
        1,
        0
      ],
      [
        0,
        1
      ],
      [
        1,
        1
      ]
    ],
    "under_tangents": [
      [
        0,
        1
      ],
      [
        1,
        0
      ],
      [
        -1,
        1
      ]
    ],
    "operation": "reverse"
  },
  "formula": "crossing_sign=sign(det(over,under)) in a declared oriented screen frame; writhe=sum(signs); reverse negates both tangents at every crossing; mirror negates x components; recompute signs and writhe",
  "expected": {
    "original_signs": [
      1,
      -1,
      1
    ],
    "original_writhe": 1,
    "transformed_signs": [
      1,
      -1,
      1
    ],
    "transformed_writhe": 1
  },
  "negative_control": {
    "values": {
      "over_tangents": [
        [
          1,
          0
        ],
        [
          0,
          1
        ],
        [
          1,
          1
        ]
      ],
      "under_tangents": [
        [
          0,
          1
        ],
        [
          1,
          0
        ],
        [
          -1,
          1
        ]
      ],
      "operation": "mirror"
    },
    "expected": {
      "original_signs": [
        1,
        -1,
        1
      ],
      "original_writhe": 1,
      "transformed_signs": [
        -1,
        1,
        -1
      ],
      "transformed_writhe": -1
    }
  }
}
```

### Ejercicio 1

Calcule determinantes y signos originales.

<details><summary>Respuesta 1</summary>

Los determinantes son `[1,-1,2]`, con signos `[1,-1,1]`. La magnitud no pondera la suma firmada.

</details>

### Ejercicio 2

Calcule el writhe del diagrama.

<details><summary>Respuesta 2</summary>

El resultado es `1`. Cuente cada cruce declarado una vez, no cada encuentro durante el recorrido.

</details>

### Ejercicio 3

Invierta ambas tangentes.

<details><summary>Respuesta 3</summary>

Los signos siguen `[1,-1,1]` y el writhe `1`. La bilinealidad conserva el determinante al negar ambos argumentos.

</details>

### Ejercicio 4

Aplique el control reflejado.

<details><summary>Respuesta 4</summary>

Los signos pasan a `[-1,1,-1]` y el writhe a `-1`. Cambia orientación planar, conservando los referentes superior/inferior.

</details>

### Ejercicio 5

¿El writhe certifica el tipo de nudo?

<details><summary>Respuesta 5</summary>

No. Un rizo de Reidemeister-I cambia el writhe conservando el tipo ambiente. Sumas iguales también omiten la disposición de cruces.

</details>

## Tarea con fuentes y referencia manual directa

Dibuje los pares de tangentes orientadas y conserve etiquetas al invertir y reflejar. Prepare un pie de ornamento que diga exactamente qué transformación del diagrama comprueba el número firmado.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

Los determinantes invariables refutan una anotación que afirme que invertir el recorrido invierte todos los signos.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: sem-005-bind-scene-hits-to-crossing-identity](../../semiotics/en/sem-005-bind-scene-hits-to-crossing-identity.md)
- [Fuente de proyecto conservada](../../../../code/streeling/weave-godot/trial.gd)
- [Lectura primaria](https://math.uchicago.edu/~dannyc/notes/knot_theory.pdf)
- [Paquete inventado](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
