---
module_id: wml-020-audit-hocket-as-exclusive-voice-occupancy
department: world-music-languages
course: "Comprobar el hoquet mediante ocupación exclusiva de voces"
level: advanced
prerequisites: ["wml-019-distribute-onsets-with-a-floor-lattice"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Comprobar el hoquet mediante ocupación exclusiva de voces

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Una lista combinada de ataques puede ocultar alternancia, colisión o huecos entre voces. Conserve identidad de voces y cuente ocupación en cada pulso declarado. La regla estricta elaborada exige exactamente una voz por posición. Es un ejercicio de planificación inspirado en el hoquet, no una definición histórica o cultural completa ni evaluación de una interpretación. Un generador [GA](https://github.com/GuitarAlchemist/ga) puede comprobar ocupación antes de añadir articulación o atribución cultural. El número de ataques no conserva su reparto entre voces.

## Supuestos y límites específicos

La cuadrícula es finita con posiciones enteras únicas por voz. Ocupación significa presencia instantánea de ataque; no se infiere solapamiento de notas sostenidas. La regla elaborada no establece aceptación histórica, cultural ni expresiva.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión GA con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../world-music-languages/en/wml-019-distribute-onsets-with-a-floor-lattice.md)

[Artefacto de proyecto conservado](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/voice/)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "slots": 4,
    "voices": {
      "A": [
        0,
        2
      ],
      "B": [
        1,
        3
      ]
    }
  },
  "formula": "occupancy[t]=number of voices containing t; collisions=slots with count>1; gaps=slots with count==0; exclusive_complete=all(count==1)",
  "expected": {
    "occupancy": [
      1,
      1,
      1,
      1
    ],
    "collisions": [],
    "gaps": [],
    "exclusive_complete": true
  },
  "negative_control": {
    "values": {
      "slots": 4,
      "voices": {
        "A": [
          0,
          2
        ],
        "B": [
          2,
          3
        ]
      }
    },
    "expected": {
      "occupancy": [
        1,
        0,
        2,
        1
      ],
      "collisions": [
        2
      ],
      "gaps": [
        1
      ],
      "exclusive_complete": false
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** La ocupación es `[1,1,1,1]`; la cuadrícula principal es exclusiva y completa.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** El reparto entre voces difiere del conteo combinado; conserve la voz de cada ataque.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** La ocupación instantánea no garantiza ausencia de solapamiento de notas sostenidas; las duraciones necesitan otra regla.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** El control colisiona en 2 y deja un hueco en 1 pese a igual número total de eventos.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Cualquier posición cuyo conteo difiera de la unidad refuta la regla estricta de exclusividad completa.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
