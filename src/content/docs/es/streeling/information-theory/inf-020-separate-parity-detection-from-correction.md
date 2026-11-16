---
title: Separar detección por paridad y corrección
description: Separar detección por paridad y corrección — Teoría de la información
sidebar:
  label: INF-020 · Separar detección por paridad y corrección
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/es/inf-020-separate-parity-detection-from-correction.es.md
---

:::note[Streeling University]
**INF-020** · Separar detección por paridad y corrección · intermedio · 45 minutos

Generado por el departamento *Teoría de la información* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/es/inf-020-separate-parity-detection-from-correction.es.md) · [Mi diario](../../journal/)

Requisitos previos: [INF-014](../../information-theory/inf-014-retain-message-codebook-versions/)
:::

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un agente recibe una etiqueta compacta de evidencia y observa que el registro se puede analizar. Eso no demuestra que se hayan conservado los bits transmitidos. El curso de diccionarios aborda otro problema: bits intactos interpretados con una correspondencia equivocada. Aquí ambos extremos coinciden en significado y el canal modifica determinados bits antes de decodificar.

Añada un bit para que el número total de bits activados sea par. En recepción calcule la misma condición. Cambiar un solo bit altera la paridad y permite detectar la infracción. No revela qué posición cambió. Varios mensajes originales podrían satisfacer la condición; elegir una reparación sin información adicional sería adivinar.

La entrada fija cambia una posición de datos. El control cambia dos y supera la comprobación de paridad aunque el mensaje difiera. Conserve síndrome y distancia de Hamming real en el registro didáctico: la comparación con el emisor conoce qué bits cambiaron, mientras un receptor ordinario no tiene esa referencia. Un síndrome nulo solo indica que esta comprobación no detectó una infracción.

El curso de la Universidad de Nuevo Brunswick explica la detección de un error y el límite de errores pares. Nuestra palabra corta permite inspeccionar ambos límites a mano. No aporta un resumen criptográfico ni recomienda un transporte para evidencias de Demerzel. Un recibo de producción debe tratar identidad, autorización y vínculo con la revisión semántica por separado. Antes de añadir una etapa componible, nombre su modelo de fallo y haga que informe detección, sin afirmar que el mensaje sea correcto, confiable o reparado.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: inf-014-retain-message-codebook-versions](../../information-theory/inf-014-retain-message-codebook-versions/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lectura primaria](https://www.ece.unb.ca/tervo/ece4253/ecc.shtml)

## Modelo fijo y control negativo

```json
{
  "values": {
    "data": [
      1,
      0,
      1,
      1
    ],
    "flip_indices": [
      1
    ]
  },
  "formula": "Append p=sum(data)%2, giving even total parity. Flip each distinct zero-based index in codeword. syndrome=sum(received)%2; detected iff syndrome=1. hamming_distance counts changed bits; no correction attempted.",
  "expected": {
    "parity_bit": 1,
    "codeword": [
      1,
      0,
      1,
      1,
      1
    ],
    "received": [
      1,
      1,
      1,
      1,
      1
    ],
    "syndrome": 1,
    "detected": true,
    "hamming_distance": 1
  },
  "negative_control": {
    "values": {
      "data": [
        1,
        0,
        1,
        1
      ],
      "flip_indices": [
        1,
        2
      ]
    },
    "expected": {
      "parity_bit": 1,
      "codeword": [
        1,
        0,
        1,
        1,
        1
      ],
      "received": [
        1,
        1,
        0,
        1,
        1
      ],
      "syndrome": 0,
      "detected": false,
      "hamming_distance": 2
    },
    "why": "Two substitutions preserve even parity despite altering the message."
  },
  "input_types": {
    "data": "finite binary integer list",
    "flip_indices": "distinct valid zero-based codeword indices"
  },
  "assumptions": [
    "Known codeword boundary; only bit substitutions, no insertions or deletions.",
    "Receiver checks parity but has no additional information about error location."
  ],
  "limits": "This toy parity check is not a production integrity mechanism, semantic validation, authentication or error correction."
}
```

### Ejercicio 1

Codifique los datos con paridad par.

<details><summary>Respuesta 1</summary>

El bit de paridad es `1` y la palabra completa es `[1,0,1,1,1]`. El bit añadido forma parte de la palabra comprobada, no de los símbolos de datos.

</details>

### Ejercicio 2

Compruebe la sustitución única.

<details><summary>Respuesta 2</summary>

La palabra recibida es `[1,1,1,1,1]`, síndrome `1` y detección `true`. Su distancia a la referencia es `1`; el síndrome solo no identifica la posición.

</details>

### Ejercicio 3

Aplique el control de doble sustitución.

<details><summary>Respuesta 3</summary>

La palabra recibida es `[1,1,0,1,1]`, síndrome `0`, detección `false` y distancia de Hamming `2`. Una paridad válida puede acompañar datos alterados.

</details>

### Ejercicio 4

¿Puede el receptor corregir el error detectado?

<details><summary>Respuesta 4</summary>

No con este síndrome solo: no identifica el bit cambiado. Mantenga el rechazo a adivinar una corrección y solicite la información que necesite el protocolo real.

</details>

### Ejercicio 5

¿Superar la prueba establece evidencia confiable?

<details><summary>Respuesta 5</summary>

No. Comprueba un patrón limitado de corrupción, sin establecer identidad del emisor, significado de la revisión, autorización ni verdad de la afirmación codificada.

</details>

## Tarea con consulta de fuentes

Explique el alcance exacto de una etapa de paridad propuesta para una entrega ilustrativa de evidencia.

**Referencia manual directa:** Cuente bits y marque a mano las posiciones cambiadas frente a la palabra de referencia construida.

**Criterio de refutación:** Un síndrome nulo se presenta como prueba de datos intactos o autenticados.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: Codifique los datos con paridad par. — Decisión sin resolver.
- Ejercicio 2: Compruebe la sustitución única. — Decisión sin resolver.
- Ejercicio 3: Aplique el control de doble sustitución. — Decisión sin resolver.
- Ejercicio 4: ¿Puede el receptor corregir el error detectado? — Decisión sin resolver.
- Ejercicio 5: ¿Superar la prueba establece evidencia confiable? — Decisión sin resolver.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
