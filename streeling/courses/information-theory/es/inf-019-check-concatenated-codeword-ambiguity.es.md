---
module_id: "inf-019-check-concatenated-codeword-ambiguity"
department: "information-theory"
course: "Comprobar la ambigüedad de palabras de código concatenadas"
title: "Comprobar la ambigüedad de palabras de código concatenadas"
level: "intermediate"
prerequisites: ["inf-014-retain-message-codebook-versions", "inf-018-frame-text-by-utf8-byte-length"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Comprobar la ambigüedad de palabras de código concatenadas

> Este es un caso matemático o lógico construido, respaldado por pasajes consultados de fuentes. La revisión técnica humana, la revisión lingüística, los intentos de alumnos, la ejecución, la adopción en producción y la publicación siguen sin decidirse.

Una entrega de agente comprime símbolos de estado en cadenas binarias cortas. Ambos extremos eligen el mismo diccionario y los bits llegan intactos. Aun así, el receptor puede no saber dónde termina un símbolo y empieza otro. Coincidir en significado e integridad de bytes no establece por sí solo una secuencia decodificable de forma única.

Escriba cada palabra de código junto a su símbolo antes de concatenar. En un código libre de prefijos, ninguna palabra completa inicia otra palabra. Un decodificador puede terminar un símbolo sin esperar un separador oculto. Para el diccionario fijo, siga el flujo y conserve las posiciones de las fronteras. Es un argumento elemental sobre la correspondencia finita declarada, no una implementación de un protocolo de compresión de internet.

El control aporta un flujo explícitamente ambiguo. Puede designar un símbolo o un par de símbolos, consumiendo todos los bits en ambos casos. Detenerse en el primer análisis plausible ocultaría la ambigüedad. Enumere todos los análisis completos antes de comunicar una decodificación única. Una violación de prefijo advierte de un problema, pero algunos códigos no prefijos siguen siendo unívocos; no convierta una condición suficiente en una equivalencia injustificada.

HPACK describe códigos Huffman concatenados con sus propias reglas de encuadre y relleno. Nuestra correspondencia adopta la pregunta de comunicación, no su formato ni su tabla. Los requisitos conservan versiones y longitudes en bytes; esta operación trata las fronteras internas del flujo concatenado. Una abreviatura DSL tendría que explicitar separadores, longitudes o una convención de decodificación. La referencia manual permite examinar todas las alternativas sin crear un servicio de transporte.

## Fuentes y alcance del proyecto

El auxiliar de Learn separa metadatos, título y cuerpo, e indexa las identidades de los módulos ingleses. Inspeccione esa representación al nombrar el artefacto y su revisión. No implementa el modelo del curso ni aporta sus entradas inventadas.

[Requisito previo: inf-014-retain-message-codebook-versions](../../information-theory/en/inf-014-retain-message-codebook-versions.md)

[Requisito previo: inf-018-frame-text-by-utf8-byte-length](../../information-theory/en/inf-018-frame-text-by-utf8-byte-length.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://www.rfc-editor.org/rfc/rfc7541.html)

## Modelo fijo y control negativo

```json
{
  "values": {
    "codebook": {
      "A": "0",
      "B": "10",
      "C": "11"
    },
    "stream": "01011"
  },
  "formula": "A proper prefix violation is an ordered distinct-symbol pair [s,t] with code(s) a proper prefix of code(t). Enumerate every complete symbol sequence whose concatenated codewords equal stream; lexicographically sort sequences.",
  "expected": {
    "prefix_violations": [],
    "prefix_free": true,
    "decodings": [
      [
        "A",
        "B",
        "C"
      ]
    ],
    "decoding_count": 1
  },
  "negative_control": {
    "values": {
      "codebook": {
        "A": "0",
        "B": "01",
        "C": "1"
      },
      "stream": "01"
    },
    "expected": {
      "prefix_violations": [
        [
          "A",
          "B"
        ]
      ],
      "prefix_free": false,
      "decodings": [
        [
          "A",
          "C"
        ],
        [
          "B"
        ]
      ],
      "decoding_count": 2
    },
    "why": "One bit string now names both a single symbol and a symbol pair."
  },
  "input_types": {
    "codebook": "finite symbol-to-distinct-nonempty-bitstring mapping",
    "stream": "finite bitstring"
  },
  "assumptions": [
    "Codebook version agreed; no corruption; no implicit symbol separators.",
    "Only complete parses that consume every stream bit count."
  ],
  "limits": "Prefix-free is sufficient for instantaneous decoding. Failure of prefix-freeness alone does not prove every code or every stream ambiguous; the explicit witness matters."
}
```

### Ejercicio 1

Decodifique por completo el flujo fijo.

<details><summary>Respuesta 1</summary>

La única secuencia completa es `[A,B,C]`. Sus fronteras siguen `0`, `10`, `11`; ninguna otra secuencia consume el flujo.

</details>

### Ejercicio 2

Identifique la violación de prefijo del control.

<details><summary>Respuesta 2</summary>

El símbolo `A` es prefijo propio de `B`. La lista ordenada es `[[A,B]]`; el diccionario no es libre de prefijos.

</details>

### Ejercicio 3

Muestre ambos análisis completos del control.

<details><summary>Respuesta 3</summary>

El flujo `01` se decodifica como `[A,C]` o `[B]`, con `2` análisis completos. Deben conservarse ambos; elegir el veredicto preferido inventaría información.

</details>

### Ejercicio 4

¿Toda violación prueba decodificación ambigua?

<details><summary>Respuesta 4</summary>

No. Ser libre de prefijos basta para decodificación inmediata. Aquí la ambigüedad se demuestra con las secuencias concretas en conflicto, no con una recíproca generalizada indebidamente.

</details>

### Ejercicio 5

¿Resolvería la ambigüedad una suma de comprobación?

<details><summary>Respuesta 5</summary>

No. Ambas interpretaciones usan los mismos bits intactos. Especifique fronteras o un código adecuado antes de tratar comprobaciones de integridad, que abordan otro fallo.

</details>

## Tarea con consulta de fuentes

Inspeccione un alfabeto compacto de estados propuesto para una entrega de agente.

**Referencia manual directa:** Liste las palabras de código y enumere manualmente toda segmentación completa del flujo corto.

**Criterio de refutación:** Un flujo intacto tiene dos secuencias completas bajo el mismo diccionario declarado.

Guarde una primera respuesta antes de abrir las soluciones. Identifique los tipos de entrada, el límite de comparación y la cantidad que debe conservar. Dibuje la tabla o el diagrama más pequeño que permita comprobar todos los resultados intermedios. Conserve un resultado inesperado: cambiar las premisas hasta obtener la conclusión deseada eliminaría el contraejemplo.

Lea el requisito previo y el pasaje primario dentro del alcance indicado. Anote la revisión de la fuente, la definición utilizada y los supuestos incorporados. El artefacto del proyecto ofrece una representación real que inspeccionar; el modelo fijo aporta entradas inventadas. Un nombre de documento o una URL accesible no demuestra un resultado de producción. Explique qué observaciones harían falta antes de usar el cálculo para una decisión operativa.

Declare la referencia manual directa y su criterio de refutación antes de proponer un DSL componible o una abstracción de agente. Pida a un asistente que cuestione su respuesta manual después de guardarla. Conserve la consigna, la respuesta, el pasaje citado y la corrección aceptada o rechazada. Una expresión más breve solo sirve si mantiene la operación, el control y el límite de rechazo. Compárela primero con una tabla sencilla.

Entregue juntos la respuesta original, las cantidades intermedias, la respuesta corregida y el control. Declare la consulta de fuentes y el uso de calculadora como ayuda. Una futura comparación de dogfood debe usar la misma versión de la tarea y conservar fallos y aciertos; cambiar la pregunta podría parecer una mejora. Los criterios preparados siguen sin decidirse hasta que exista un intento real. Una solución y una comprobación del autor no demuestran aprendizaje ni adopción.

## Criterios preparados para el alumno

- Ejercicio 1: Decodifique por completo el flujo fijo. — Decisión sin resolver.
- Ejercicio 2: Identifique la violación de prefijo del control. — Decisión sin resolver.
- Ejercicio 3: Muestre ambos análisis completos del control. — Decisión sin resolver.
- Ejercicio 4: ¿Toda violación prueba decodificación ambigua? — Decisión sin resolver.
- Ejercicio 5: ¿Resolvería la ambigüedad una suma de comprobación? — Decisión sin resolver.

[Paquete fijo](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
