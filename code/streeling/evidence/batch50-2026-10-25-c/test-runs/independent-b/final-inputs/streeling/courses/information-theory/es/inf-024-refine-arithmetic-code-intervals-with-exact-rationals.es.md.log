---
module_id: "inf-024-refine-arithmetic-code-intervals-with-exact-rationals"
department: "information-theory"
course: "Refinar intervalos de codificación aritmética con racionales exactos"
title: "Refinar intervalos de codificación aritmética con racionales exactos"
level: "intermediate"
prerequisites: ["inf-019-check-concatenated-codeword-ambiguity", "inf-014-retain-message-codebook-versions"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Refinar intervalos de codificación aritmética con racionales exactos

> Este caso matemático o lógico finito se ha creado para la lección y se apoya en una lectura acotada de fuentes. Revisión técnica humana, revisión lingüística, intentos de aprendizaje, ejecución nativa, adopción y publicación siguen sin decidirse.

Un artefacto agéntico puede contener un flujo simbólico repetitivo cuyas frecuencias declaradas sugieren una representación compacta. La codificación aritmética asigna un intervalo a toda la secuencia en vez de una palabra binaria por símbolo. Esta lección examina la semántica exacta de intervalos antes de comprimir datos reales. La tabla de frecuencias pertenece al contrato de decodificación.

Divida el intervalo semiabierto actual según las frecuencias acumuladas ordenadas. Elija el subintervalo del símbolo siguiente y repita usando ambos extremos anteriores. La aritmética racional exacta evita que un redondeo de frontera admita silenciosamente otro símbolo. Se incluye el extremo izquierdo y se excluye el derecho; una etiqueta situada en una frontera tiene así un propietario declarado.

La secuencia fija y su control comparten un prefijo y terminan en intervalos distintos sin solapamiento. Una etiqueta interior decodifica la secuencia correspondiente cuando se conoce su longitud. El coste de representación, la terminación, la renormalización y la precisión finita quedan fuera. La anchura no es un tamaño de archivo medido. Conserve el orden declarado del alfabeto, las frecuencias y la longitud: una etiqueta numérica sola no describe cómo decodificarla.

## Fuentes y alcance del proyecto

[Prerrequisito: inf-019-check-concatenated-codeword-ambiguity](../../information-theory/en/inf-019-check-concatenated-codeword-ambiguity.md)

[Prerrequisito: inf-014-retain-message-codebook-versions](../../information-theory/en/inf-014-retain-message-codebook-versions.md)

[Artefacto conservado del proyecto](../../../../scripts/streeling-lib.mjs)

[Lectura primaria](https://www.ece.unb.ca/tervo/ece4253/arith.shtml)

## Modelo fijo y control negativo

```json
{
  "values": {
    "alphabet": [
      "A",
      "B"
    ],
    "frequencies": [
      1,
      3
    ],
    "sequence": "ABA",
    "tag": "3/32"
  },
  "formula": "Start [L,U)=[0,1). For each symbol with cumulative fraction c and probability p, replace by [L+(U-L)*c,L+(U-L)*(c+p)). Compute with exact rational strings. Decode tag for the declared sequence length using the same half-open partitions.",
  "expected": {
    "intervals": [
      [
        "0",
        "1/4"
      ],
      [
        "1/16",
        "1/4"
      ],
      [
        "1/16",
        "7/64"
      ]
    ],
    "width": "3/64",
    "tag_inside": true,
    "decoded": "ABA"
  },
  "negative_control": {
    "values": {
      "alphabet": [
        "A",
        "B"
      ],
      "frequencies": [
        1,
        3
      ],
      "sequence": "ABB",
      "tag": "3/16"
    },
    "expected": {
      "intervals": [
        [
          "0",
          "1/4"
        ],
        [
          "1/16",
          "1/4"
        ],
        [
          "7/64",
          "1/4"
        ]
      ],
      "width": "9/64",
      "tag_inside": true,
      "decoded": "ABB"
    },
    "why": "A changed suffix selects a different final half-open interval under the same frequency model."
  },
  "input_types": {
    "alphabet": "ordered distinct symbol strings",
    "frequencies": "same-length positive integers",
    "sequence": "nonempty string over the single-character alphabet",
    "tag": "exact rational string inside the unit interval"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No bitstream length, finite-precision coder, entropy guarantee, compressed artifact or production decoder is measured."
}
```

## Tarea con fuentes y diario

**Referencia manual directa:** Refinar extremos racionales y decodificar una etiqueta interior con la longitud declarada.

**Criterio de refutación:** Codificador y decodificador usan órdenes, frecuencias, longitudes o fronteras diferentes.

Lea el prerrequisito y la representación conservada del proyecto antes de tratar este ejemplo como una función propuesta. El script enlazado de Learn extrae metadatos, título y cuerpo, y después indexa las identidades de módulos ingleses. Es una frontera observable de representación; no suministra las entradas inventadas ni implementa esta operación matemática. Adjunte la revisión a la nota de lectura para que un cambio posterior no herede silenciosamente esta inspección.

Para la tarea con fuentes, reproduzca directamente el caso fijo antes de pedir una explicación a un asistente. Incluya los tipos y supuestos del expediente, conserve cantidades intermedias y compare el control negativo declarado. Pregunte qué premisa distingue ambos resultados. Una explicación plausible sin calcular la entrada modificada no demuestra la operación.

Registre pregunta exacta, fuentes aportadas, respuesta, ayuda recibida y correcciones en el diario. Las respuestas corregidas son una clave, no un intento de aprendizaje. Una comprobación matemática independiente puede verificar el cálculo finito sin detectar una pregunta deficiente o una traducción engañosa. Revisión técnica humana, revisión lingüística, aceptación del aprendiz, comportamiento del motor nativo, adopción y publicación siguen sin decidirse. Conserve el fallo original y su diagnóstico antes de registrar una repetición correcta; no sustituya el fallo por el resultado corregido.

## Ejercicios corregidos

### Ejercicio 1

Halle el intervalo final fijo.

> **Respuesta:** El intervalo final es `[1/16,7/64)` y su anchura es `3/64`. La etiqueta `3/32` está dentro y decodifica `ABA`.

### Ejercicio 2

Aplique el control de sufijo modificado.

> **Respuesta:** La secuencia `ABB` termina en `[7/64,1/4)`, con anchura `9/64`; la etiqueta `3/16` decodifica `ABB`.

### Ejercicio 3

¿A quién pertenece la frontera compartida?

> **Respuesta:** La frontera `7/64` queda fuera del intervalo `ABA` y dentro del de `ABB`. Los intervalos semiabiertos evitan ambigüedad.

### Ejercicio 4

¿Qué demuestra realmente el script conservado del proyecto?

> **Respuesta:** Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.

### Ejercicio 5

¿Qué decisiones de aceptación puede cerrar la clave corregida?

> **Respuesta:** Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

## Criterios de aprendizaje preparados

Estos criterios están preparados; cada decisión del aprendiz sigue sin decidirse.

- Ejercicio 1: El intervalo final es `[1/16,7/64)` y su anchura es `3/64`. La etiqueta `3/32` está dentro y decodifica `ABA`.
- Ejercicio 2: La secuencia `ABB` termina en `[7/64,1/4)`, con anchura `9/64`; la etiqueta `3/16` decodifica `ABB`.
- Ejercicio 3: La frontera `7/64` queda fuera del intervalo `ABA` y dentro del de `ABB`. Los intervalos semiabiertos evitan ambigüedad.
- Ejercicio 4: Extrae metadatos, título y cuerpo e indexa identidades de módulos ingleses. Leerlo respalda esa representación; no ejecuta el modelo ni valida una función real.
- Ejercicio 5: Ninguna aceptación humana o del aprendiz. Un intento real necesita su respuesta, historial de ayuda y corrección; el caso finito no demuestra comportamiento nativo, adopción ni aprobación de publicación.

[Expediente fijo de la unidad](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
