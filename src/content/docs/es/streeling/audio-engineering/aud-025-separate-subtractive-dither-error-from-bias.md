---
title: Separar error y sesgo con dither sustractivo
description: Separar error y sesgo con dither sustractivo — Ingeniería de audio
sidebar:
  label: AUD-025 · Separar error y sesgo con dither sustractivo
  order: 25
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/es/aud-025-separate-subtractive-dither-error-from-bias.es.md
---

:::note[Streeling University]
**AUD-025** · Separar error y sesgo con dither sustractivo · avanzado · 55 minutos

Generado por el departamento *Ingeniería de audio* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/es/aud-025-separate-subtractive-dither-error-from-bias.es.md) · [Mi diario](../../journal/)

Requisitos previos: [AUD-015](../../audio-engineering/aud-015-bound-quantization-error-before-comparing-wavs/)
:::

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Una propuesta de dither puede confundir el ruido añadido con el error residual tras restar el mismo desplazamiento. Mantenga juntas las ecuaciones del codificador y del decodificador. Los desplazamientos fijos forman un conjunto didáctico finito, no un generador aleatorio ni una muestra uniforme independiente. Una media nula aquí no demuestra independencia para toda entrada. En una futura exportación [GA](https://github.com/GuitarAlchemist/ga), perder la correspondencia de desplazamientos cambiaría el convertidor.

## Supuestos y límites específicos

Use un cuantificador no acotado de paso unitario con el redondeo mostrado. Los desplazamientos son fijos, sin recorte ni sorteo aleatorio. La tabla finita no demuestra densidad probabilística, independencia, inaudibilidad ni exportación real.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión GA con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../audio-engineering/aud-015-bound-quantization-error-before-comparing-wavs/)

[Artefacto de proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "x": 0,
    "dither": [
      -0.375,
      -0.125,
      0.125,
      0.375
    ],
    "subtract": true
  },
  "formula": "q=floor(x+d+0.5); decoded=q-d if subtract else q; errors=decoded-x; mean=sum(errors)/count; mse=sum(e*e)/count",
  "expected": {
    "encoded": [
      0,
      0,
      0,
      0
    ],
    "decoded": [
      0.375,
      0.125,
      -0.125,
      -0.375
    ],
    "errors": [
      0.375,
      0.125,
      -0.125,
      -0.375
    ],
    "mean": 0,
    "mse": 0.078125
  },
  "negative_control": {
    "values": {
      "x": 0.25,
      "dither": [
        -0.375,
        -0.125,
        0.125,
        0.375
      ],
      "subtract": false
    },
    "expected": {
      "encoded": [
        0,
        0,
        0,
        1
      ],
      "decoded": [
        0,
        0,
        0,
        1
      ],
      "errors": [
        -0.25,
        -0.25,
        -0.25,
        0.75
      ],
      "mean": 0,
      "mse": 0.1875
    }
  }
}
```

### Ejercicio 1

Calcule los valores decodificados con sustracción.

> **Respuesta:** Son `[0.375,0.125,-0.125,-0.375]`, aunque todos los enteros codificados valen 0.

### Ejercicio 2

¿Cuáles son la media y el error cuadrático medio finitos?

> **Respuesta:** La media es 0 y el error cuadrático medio es 0.078125 para este conjunto fijo.

### Ejercicio 3

¿Establece un teorema de independencia estocástica?

> **Respuesta:** No. Un conjunto determinista en una entrada no establece una distribución para toda entrada.

### Ejercicio 4

¿Por qué no basta la media en el control?

> **Respuesta:** Sigue siendo 0 mientras el error cuadrático medio pasa a 0.1875 y cambian los errores individuales.

### Ejercicio 5

¿Qué refuta la recuperación sustractiva declarada?

> **Respuesta:** Un desplazamiento de decodificación distinto del usado al codificar refuta el contrato estipulado.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
