---
title: Comprobar el cierre de un conjunto ante perturbaciones
description: Comprobar el cierre de un conjunto ante perturbaciones — Cibernética
sidebar:
  label: CYB-020 · Comprobar el cierre de un conjunto ante perturbaciones
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/es/cyb-020-check-disturbance-robust-set-closure.es.md
---

:::note[Streeling University]
**CYB-020** · Comprobar el cierre de un conjunto ante perturbaciones · intermedio · 45 minutos

Generado por el departamento *Cibernética* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/es/cyb-020-check-disturbance-robust-set-closure.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CYB-013](../../cybernetics/cyb-013-bound-observation-age-before-a-control-decision/)
:::

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un coordinador de Demerzel propone mantener el trabajo pendiente dentro de un conjunto pequeño de estados admisibles. Una trayectoria tranquila no demuestra que la política soporte todas las llegadas permitidas. Pregunte si cada estado seguro vuelve al conjunto para cualquier perturbación que permita el modelo. Así se convierte un ejemplo tranquilizador en un argumento de seguridad cuantificado.

Declare primero el orden del paso. El controlador atiende el trabajo existente, limita a cero el resto si corresponde y añade las llegadas después. Invertir las operaciones cambia el cálculo del límite. Enumere sucesores para cada par de estado y perturbación. Si ninguno sale, el conjunto queda cerrado bajo esa transición. Empezando dentro, las aplicaciones repetidas permanecen dentro por inducción.

El conjunto fijo permite como máximo tantas llegadas como servicio por paso. El control amplía las perturbaciones y conserva controlador y estados seguros propuestos. Un estado del límite obtiene entonces un sucesor exterior. Conserve ese par como testigo en lugar de diluirlo promediando llegadas favorables. Como el contrato exige todos los casos permitidos, un testigo raro pero admisible basta para refutarlo.

Las notas distinguen los supuestos de conjunto del peor caso y las restricciones probabilísticas. Nuestra enumeración no contiene una distribución de llegadas y no informa una probabilidad de fallo. El requisito de antigüedad de observación acota el valor actual; esta lección pregunta si todo un conjunto permanece seguro indefinidamente con una transición conocida. Ninguno garantiza servicio real. Antes de proponer una guarda DSL, compruebe la tabla manual y qué observaciones justificarían las cotas.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: cyb-013-bound-observation-age-before-a-control-decision](../../cybernetics/cyb-013-bound-observation-age-before-a-control-decision/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://underactuated.mit.edu/robust.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "safe_states": [
      0,
      1,
      2
    ],
    "disturbances": [
      0,
      1
    ],
    "service": 1
  },
  "formula": "For every safe integer state q and disturbance d compute q_next=max(0,q-service)+d. Closed iff every successor belongs to safe_states. Sort escaping [q,d,q_next] triples lexicographically.",
  "expected": {
    "successor_set": [
      0,
      1,
      2
    ],
    "escaping": [],
    "closed": true
  },
  "negative_control": {
    "values": {
      "safe_states": [
        0,
        1,
        2
      ],
      "disturbances": [
        0,
        1,
        2
      ],
      "service": 1
    },
    "expected": {
      "successor_set": [
        0,
        1,
        2,
        3
      ],
      "escaping": [
        [
          2,
          2,
          3
        ]
      ],
      "closed": false
    },
    "why": "A larger allowed arrival breaks closure at the upper state."
  },
  "input_types": {
    "safe_states": "finite set of nonnegative integers",
    "disturbances": "finite set of nonnegative integers",
    "service": "nonnegative integer"
  },
  "assumptions": [
    "Service precedes arrivals on every step.",
    "Initial state is safe; disturbance always lies in the declared set; no hidden transition exists."
  ],
  "limits": "A conditional finite invariant is not a verified production queue bound or a stochastic tail guarantee."
}
```

### Ejercicio 1

Enumere el conjunto de sucesores fijo.

<details><summary>Respuesta 1</summary>

Es `[0,1,2]`, incluido en el conjunto seguro. La lista de escapes es `[]`; el cierre es `true` con el orden estipulado.

</details>

### Ejercicio 2

Encuentre la transición que escapa en el control.

<details><summary>Respuesta 2</summary>

El triple `[2,2,3]` empieza en el estado seguro superior y termina fuera. Los sucesores son `[0,1,2,3]`; por tanto, el cierre es `false`.

</details>

### Ejercicio 3

¿Por qué se extiende el cierre a todo horizonte finito?

<details><summary>Respuesta 3</summary>

El estado inicial está dentro y cada paso permitido conserva la pertenencia. La inducción la mantiene tras cualquier número finito de pasos si los supuestos no cambian.

</details>

### Ejercicio 4

¿Estima la tabla una probabilidad de interrupción?

<details><summary>Respuesta 4</summary>

No. Las perturbaciones forman un conjunto sin probabilidades. El cierre o un testigo de escape trata pertenencia en el peor caso, no frecuencia de eventos.

</details>

### Ejercicio 5

¿Qué debe preceder a la adopción operativa?

<details><summary>Respuesta 5</summary>

Evidencias del orden, la cota de servicio, el conjunto de perturbaciones y el estado inicial, además de comprobaciones de transiciones omitidas. Una afirmación de agente no aporta esas premisas.

</details>

## Tarea con consulta de fuentes

Evalúe un esquema finito de seguridad del trabajo pendiente antes de proponer una guarda de admisión.

**Referencia manual directa:** Enumere a mano cada sucesor de estado y perturbación y marque su pertenencia al conjunto.

**Criterio de refutación:** Un par permitido de estado y perturbación sale del conjunto declarado invariante.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: Enumere el conjunto de sucesores fijo. — Decisión sin resolver.
- Ejercicio 2: Encuentre la transición que escapa en el control. — Decisión sin resolver.
- Ejercicio 3: ¿Por qué se extiende el cierre a todo horizonte finito? — Decisión sin resolver.
- Ejercicio 4: ¿Estima la tabla una probabilidad de interrupción? — Decisión sin resolver.
- Ejercicio 5: ¿Qué debe preceder a la adopción operativa? — Decisión sin resolver.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
