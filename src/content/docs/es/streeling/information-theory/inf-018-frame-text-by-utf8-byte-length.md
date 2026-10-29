---
title: Delimitar textos mediante su longitud en bytes UTF-8
description: Delimitar textos mediante su longitud en bytes UTF-8 — Teoría de la información
sidebar:
  label: INF-018 · Delimitar textos mediante su longitud en bytes UTF-8
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/es/inf-018-frame-text-by-utf8-byte-length.es.md
---

:::note[Streeling University]
**INF-018** · Delimitar textos mediante su longitud en bytes UTF-8 · intermedio · 45 minutos

Generado por el departamento *Teoría de la información* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/es/inf-018-frame-text-by-utf8-byte-length.es.md) · [Mi diario](../../journal/)

Requisitos previos: [INF-014](../../information-theory/inf-014-retain-message-codebook-versions/)
:::

> Este curso usa entradas construidas y pasajes de fuentes consultados. Los números, historias y etiquetas son datos didácticos. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Un traspaso une mensajes con un separador que también puede aparecer dentro del contenido. El receptor no puede recuperar los límites a partir del texto unido. Compartir un vocabulario de veredictos no resuelve la ambigüedad. El curso sobre códigos fija significados; esta operación fija dónde termina cada mensaje codificado.

El RFC 8949 cuenta explícitamente los bytes de cadenas de longitud definida y especifica UTF-8. Nuestra notación decimal seguida de dos puntos toma solo esa distinción; no es codificación CBOR. Cuente los bytes UTF-8 del contenido, escriba el prefijo y consuma exactamente esa cantidad. Un separador interno sigue siendo contenido.

El carácter acentuado sirve como control porque el número de caracteres difiere del de bytes. Las traducciones deben conservar este dato literal. Una implementación real también necesita límites de tamaño, prefijos malformados y manejo de truncamientos, ausentes de este caso finito. El DSL debe declarar su unidad de representación antes de afirmar que los límites son inequívocos.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo en `parseModule` e indexa nombres ingleses en `englishModuleKeys`. Esas representaciones permiten identificar fuentes y metadatos; no implementan la operación construida. El registro de práctica distingue métricas de recuperación y evidencia de aprendizaje. Inspeccione el archivo enlazado y retenga solo lo que realmente respalda. Ninguna entrada del modelo se estimó a partir de ese archivo.

[Requisito previo: inf-014-retain-message-codebook-versions](../../information-theory/inf-014-retain-message-codebook-versions/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lectura primaria](https://www.rfc-editor.org/rfc/rfc8949.html)

## Modelo fijo y control

```json
{
  "values": {
    "messages": [
      "é",
      "A|B"
    ],
    "declared_lengths": [
      2,
      3
    ]
  },
  "formula": "actual_lengths=count UTF-8 bytes per message; valid iff declared lengths equal actual lengths; if valid frame=concatenate(decimal_length+colon+message), else null.",
  "expected": {
    "actual_lengths": [
      2,
      3
    ],
    "valid": true,
    "frame": "2:é3:A|B",
    "naive_delimited": "é|A|B"
  },
  "negative_control": {
    "values": {
      "messages": [
        "é",
        "A|B"
      ],
      "declared_lengths": [
        1,
        3
      ]
    },
    "expected": {
      "actual_lengths": [
        2,
        3
      ],
      "valid": false,
      "frame": null,
      "naive_delimited": "é|A|B"
    },
    "why": "Counting Unicode characters for the first length understates its UTF-8 byte span."
  },
  "assumptions": [
    "Decimal nonnegative byte length terminated by colon; valid UTF-8 payload.",
    "Read exactly that many bytes after each length; no stream truncation or malformed prefix."
  ],
  "limits": "Toy framing is not CBOR, an escaping implementation, authentication or arbitrary-stream parser.",
  "input_types": {
    "messages": "list<Unicode string>",
    "declared_lengths": "list<nonnegative integer> of same size"
  }
}
```

### Ejercicio 1

Cuente los bytes UTF-8.

<details><summary>Respuesta 1</summary>

Los recuentos son `[2,3]` para `[é,A|B]`. Un carácter visible no ocupa necesariamente un solo byte.

</details>

### Ejercicio 2

Escriba la trama válida.

<details><summary>Respuesta 2</summary>

La trama es `2:é3:A|B`. Los separadores internos siguen siendo contenido porque la longitud fija los límites.

</details>

### Ejercicio 3

¿Por qué es ambigua la unión ingenua?

<details><summary>Respuesta 3</summary>

`é|A|B` también encaja con mensajes `[é|A,B]`. Los bytes unidos no identifican la partición deseada.

</details>

### Ejercicio 4

Aplique el control que cuenta caracteres.

<details><summary>Respuesta 4</summary>

Las longitudes `[1,3]` difieren de `[2,3]`; `valid=false` y `frame=null`. No repare el prefijo en silencio.

</details>

### Ejercicio 5

¿Qué falta para justificar un decodificador de flujo?

<details><summary>Respuesta 5</summary>

Longitudes malformadas, entradas truncadas, límites y recuperación necesitan otros contratos. Aquí no se ejercitó ningún decodificador real.

</details>

## Tarea con consulta de fuentes

Prepare una nota de delimitación de mensajes multilingües ficticios y cuestione la premisa del recuento.

**Referencia manual directa:** Escriba los recuentos UTF-8 y siga los límites a mano antes de abreviar la representación.

**Criterio de refutación:** Se cuenta el carácter acentuado como un byte o un separador interno crea un límite nuevo.

Guarde una primera respuesta antes de abrir las soluciones. Copie las identidades y unidades de entrada, escriba cantidades intermedias y distinga cálculo e interpretación. Un número correcto con denominador, frontera de estado o unidad de recuento incorrectos no satisface la tarea. Conserve un resultado inesperado en lugar de cambiar entradas para que la respuesta parezca plausible.

Lea el pasaje primario dentro del alcance registrado en el paquete. Compare su definición con la regla construida del modelo fijo. La referencia puede motivar un concepto sin especificar todo el modelo. Anote versión o fecha, pasaje usado y supuesto importado. Poder acceder a una página o leer un archivo no verifica una afirmación.

Inspeccione el artefacto conservado y un requisito previo. Separe lo que realmente representa el archivo de lo que supone esta tarea nueva. Conserve revisión e historial de ayuda. Pida a un asistente que cuestione una premisa después de guardar la referencia manual y retenga consigna, respuesta, corrección aceptada y sugerencia rechazada. Consultar fuentes y calculadora es ayuda permitida, no recuerdo sin asistencia.

Procese la entrada modificada con el mismo razonamiento en papel. Declare el criterio de refutación antes de proponer una abstracción de agente o expresión DSL componible. Si pierde el contraejemplo o cambia el punto de evaluación aceptado, falla aunque sea más breve. Compare primero una tabla directa o un registro tipado; no hace falta un lenguaje ni un motor de producción nuevos.

Entregue las respuestas original y corregida, el control, el pasaje fuente y las dudas restantes. El paquete prepara un criterio por ejercicio y todas las decisiones del alumno siguen abiertas. Solución, hash de bytes y comprobación de autor difieren de un intento real. Una futura comparación de dogfood debe conservar intentos de la misma tarea versionada y la referencia directa antes de afirmar una mejora útil.

[Paquete fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
