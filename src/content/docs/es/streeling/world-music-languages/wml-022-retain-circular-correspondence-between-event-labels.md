---
title: Conservar la correspondencia circular entre etiquetas de eventos
description: Conservar la correspondencia circular entre etiquetas de eventos — Músicas y lenguas del mundo
sidebar:
  label: WML-022 · Conservar la correspondencia circular entre etiquetas de eventos
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/es/wml-022-retain-circular-correspondence-between-event-labels.es.md
---

:::note[Streeling University]
**WML-022** · Conservar la correspondencia circular entre etiquetas de eventos · avanzado · 55 minutos

Generado por el departamento *Músicas y lenguas del mundo* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/es/wml-022-retain-circular-correspondence-between-event-labels.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-006](../../world-music-languages/wml-006-preserve-the-origin-of-an-additive-cycle/)
:::

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Una frase cíclica puede comenzar en otro evento sin cambiar el orden circular de etiquetas. Compare todos los desplazamientos y conserve cada correspondencia válida. Las repeticiones pueden admitir varias soluciones: elegir la primera inventa un anclaje. Invertir el orden no equivale automáticamente a rotarlo. Es una regla finita de etiquetas para intercambios de práctica [GA](https://github.com/GuitarAlchemist/ga), sin identificación cultural, inferencia temporal ni equivalencia de acentos.

## Supuestos y límites específicos

Use secuencias no vacías de igual longitud, igualdad exacta de etiquetas y dirección de desplazamiento mostrada. Invertir el orden es otra operación. Acento y tiempo no están codificados: la igualdad circular no juzga equivalencia interpretativa.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión GA con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../world-music-languages/wml-006-preserve-the-origin-of-an-additive-cycle/)

[Artefacto de proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "source": [
      "a",
      "b",
      "c",
      "d"
    ],
    "target": [
      "c",
      "d",
      "a",
      "b"
    ]
  },
  "formula": "shifts=[s in range(N) where target[i]==source[(i+s)%N] for every i]; unique=len(shifts)==1",
  "expected": {
    "shifts": [
      2
    ],
    "unique": true
  },
  "negative_control": {
    "values": {
      "source": [
        "a",
        "b",
        "a",
        "b"
      ],
      "target": [
        "a",
        "b",
        "a",
        "b"
      ]
    },
    "expected": {
      "shifts": [
        0,
        2
      ],
      "unique": false
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** El desplazamiento único es 2 según la dirección declarada de objetivo a fuente.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** Equivalencia circular y anclaje único son distintos; varios desplazamientos pueden satisfacer la equivalencia.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** Las etiquetas omiten acento y duración; el orden circular no conserva propiedades musicales no registradas.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** El control repetido devuelve `[0,2]`; escoger una correspondencia inventaría un origen único.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Más de un desplazamiento válido refuta el anclaje único aunque se cumpla equivalencia circular.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
