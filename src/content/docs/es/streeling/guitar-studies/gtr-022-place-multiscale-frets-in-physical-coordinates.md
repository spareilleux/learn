---
title: Situar trastes multiescala en coordenadas físicas
description: Situar trastes multiescala en coordenadas físicas — Estudios de guitarra
sidebar:
  label: GTR-022 · Situar trastes multiescala en coordenadas físicas
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/es/gtr-022-place-multiscale-frets-in-physical-coordinates.es.md
---

:::note[Streeling University]
**GTR-022** · Situar trastes multiescala en coordenadas físicas · avanzado · 55 minutos

Generado por el departamento *Estudios de guitarra* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/es/gtr-022-place-multiscale-frets-in-physical-coordinates.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GTR-006](../../guitar-studies/gtr-006-keep-picking-distance-relative-to-frets/)
:::

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

El mismo número de traste no tiene por qué corresponder a igual coordenada en cada cuerda de una guitarra multiescala. Cada cuerda conserva origen en cejuela y longitud de escala. Aplique localmente la fracción temperada y vuelva al eje común de la escena. La línea entre contactos puede ser oblicua pese al mismo intervalo musical. Esta construcción ayuda a revisar una escena [GA](https://github.com/GuitarAlchemist/ga) sin equiparar una línea renderizada a un traste fabricado y compensado.

## Supuestos y límites específicos

Suponga ejes de cuerda rectos y paralelos, unidad común y razones temperadas ideales. El control reutiliza deliberadamente la primera escala en todas las cuerdas. Compensación, ajuste de trastes y tolerancias de fabricación quedan pendientes.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión GA con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../guitar-studies/gtr-006-keep-picking-distance-relative-to-frets/)

[Artefacto de proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/fret/)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "nuts": [
      0,
      20
    ],
    "scales": [
      600,
      660
    ],
    "transverse": [
      0,
      10
    ],
    "fret": 12,
    "use_common_scale": false
  },
  "formula": "x_i=nut_i+L_i*(1-2^(-fret/12)); slope=(x_1-x_0)/(y_1-y_0)",
  "expected": {
    "positions": [
      300,
      350
    ],
    "slope": 5
  },
  "negative_control": {
    "values": {
      "nuts": [
        0,
        20
      ],
      "scales": [
        600,
        660
      ],
      "transverse": [
        0,
        10
      ],
      "fret": 12,
      "use_common_scale": true
    },
    "expected": {
      "positions": [
        300,
        320
      ],
      "slope": 2
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** Las posiciones son `[300,350]` y la pendiente es 5 en los ejes comunes.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** Origen de cejuela y escala vibrante son independientes; cambiar uno no cambia automáticamente el otro.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** Las razones ideales omiten rigidez, acción y compensación; las coordenadas no certifican afinación.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** El control de escala común da `[300,320]` y pendiente 2; el segundo contacto queda desplazado.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Un contacto de escena distinto del cálculo independiente por cuerda refuta la fidelidad geométrica.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
