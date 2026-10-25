---
module_id: "cyb-019-test-coupled-feedback-eigenmodes"
department: "cybernetics"
course: "Comprobar los modos propios de bucles acoplados"
title: "Comprobar los modos propios de bucles acoplados"
level: "intermediate"
prerequisites: ["cyb-008-check-convergence-before-repeating-a-correction"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Comprobar los modos propios de bucles acoplados

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Los agentes de GA e IX pueden reducir su desviación local y a la vez provocar trabajo correctivo en el otro repositorio. Examinar cada multiplicador local aisladamente puede ocultar esa interacción. La pregunta es si la actualización conjunta reduce todos los modos, incluido aquel en que ambas desviaciones crecen juntas. Declare el acoplamiento antes de aplicar una regla escalar a un flujo multiagente.

Use una transición simétrica con diagonales iguales y un término cruzado en cada posición fuera de la diagonal. Sumar las ecuaciones da el multiplicador del modo común; restarlas da el del modo opuesto. Los vectores propios aparecen directamente, sin un solucionador numérico general. Una entrada diagonal menor que la unidad solo describe el sistema con su vecino inmóvil.

En el caso fijo crece el modo común, mientras el opuesto disminuye y alterna. Iniciar ambas coordenadas iguales y positivas excita el modo creciente y ofrece un testigo mediante una trayectoria corta exacta. El control reduce el término cruzado y contrae ambos modos. Comprobar solo la trayectoria mostrada sería más débil que revisar los dos multiplicadores: otro estado inicial podría excitar el modo restante.

La lección de convergencia aporta una dinámica de error de un cálculo material diagonal. Aquí cambia la estructura de dependencias, no simplemente su ganancia. El criterio discreto de Harvard se aplica a esta matriz diagonalizable. Las entregas reales entre agentes pueden ser retardadas, no lineales y discontinuas; las mejoras locales observadas no identifican estos coeficientes. Un estudio de dogfood necesitaría cambios alineados y ligados a revisiones, además de una transición medida.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: cyb-008-check-convergence-before-repeating-a-correction](../../cybernetics/en/cyb-008-check-convergence-before-repeating-a-correction.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://hankyang.seas.harvard.edu/OptimalControlEstimation/app-lti-system-theory.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "diagonal": 0.5,
    "coupling": 0.75,
    "initial": [
      1,
      1
    ],
    "steps": 3
  },
  "formula": "A=[[a,b],[b,a]]; eigenvalues are a+b and a-b. Iterate x_next=A*x exactly steps times. Asymptotically stable iff both eigenvalue absolute values are strictly below 1.",
  "expected": {
    "eigenvalues": [
      1.25,
      -0.25
    ],
    "spectral_radius": 1.25,
    "stable": false,
    "trajectory": [
      [
        1,
        1
      ],
      [
        1.25,
        1.25
      ],
      [
        1.5625,
        1.5625
      ],
      [
        1.953125,
        1.953125
      ]
    ]
  },
  "negative_control": {
    "values": {
      "diagonal": 0.5,
      "coupling": 0.25,
      "initial": [
        1,
        1
      ],
      "steps": 3
    },
    "expected": {
      "eigenvalues": [
        0.75,
        0.25
      ],
      "spectral_radius": 0.75,
      "stable": true,
      "trajectory": [
        [
          1,
          1
        ],
        [
          0.75,
          0.75
        ],
        [
          0.5625,
          0.5625
        ],
        [
          0.421875,
          0.421875
        ]
      ]
    },
    "why": "Reducing cross-coupling puts both modes strictly inside the unit circle."
  },
  "input_types": {
    "diagonal": "rational scalar",
    "coupling": "rational scalar",
    "initial": "length-2 rational vector",
    "steps": "nonnegative integer"
  },
  "assumptions": [
    "Synchronous autonomous linear updates with fixed coefficients.",
    "The two coordinates are deviations, not literal nonnegative queue counts."
  ],
  "limits": "No production controller or gain recommendation. Delays, saturation and disturbance change the transition."
}
```

### Ejercicio 1

Obtenga los multiplicadores de los modos.

<details><summary>Respuesta 1</summary>

Son `1.25` y `-0.25`; el radio espectral es `1.25`. La matriz es inestable pese a sus diagonales de `0.5`.

</details>

### Ejercicio 2

Siga el testigo del modo común.

<details><summary>Respuesta 2</summary>

Desde `[1,1]`, el vector tras `3` pasos es `[1.953125,1.953125]`. Cada paso amplifica la desviación compartida.

</details>

### Ejercicio 3

Aplique el control de menor acoplamiento.

<details><summary>Respuesta 3</summary>

Los valores propios son `[0.75,0.25]`, estrictamente dentro del círculo unidad. El vector común final es `[0.421875,0.421875]`; la estabilidad es `true`.

</details>

### Ejercicio 4

¿Certifica estabilidad una trayectoria opuesta decreciente?

<details><summary>Respuesta 4</summary>

No. Solo excita su propio modo. El modo común no excitado aún puede crecer; compruebe todos los modos propios del modelo lineal declarado.

</details>

### Ejercicio 5

¿Qué rechazaría la regla real propuesta?

<details><summary>Respuesta 5</summary>

Una transición medida fuera del modelo, un modo amplificador o un comportamiento inadmisible en los límites. El progreso escalar local no valida por sí solo la regla acoplada.

</details>

## Tarea con consulta de fuentes

Evalúe un esquema de corrección acoplada para entregas entre GA e IX.

**Referencia manual directa:** Sume y reste las ecuaciones y siga manualmente las direcciones de ambos modos.

**Criterio de refutación:** Algún modo propio crece bajo una regla que afirma reducir cualquier desviación inicial.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: Obtenga los multiplicadores de los modos. — Decisión sin resolver.
- Ejercicio 2: Siga el testigo del modo común. — Decisión sin resolver.
- Ejercicio 3: Aplique el control de menor acoplamiento. — Decisión sin resolver.
- Ejercicio 4: ¿Certifica estabilidad una trayectoria opuesta decreciente? — Decisión sin resolver.
- Ejercicio 5: ¿Qué rechazaría la regla real propuesta? — Decisión sin resolver.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
