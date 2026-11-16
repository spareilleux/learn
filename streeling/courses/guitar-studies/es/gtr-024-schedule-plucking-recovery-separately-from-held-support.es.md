---
module_id: gtr-024-schedule-plucking-recovery-separately-from-held-support
department: guitar-studies
course: "Planificar la recuperación del dedo pulsador separada del apoyo mantenido"
level: advanced
prerequisites: ["gtr-005-plan-which-string-keeps-ringing"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Planificar la recuperación del dedo pulsador separada del apoyo mantenido

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Una nota larga ocupa un intervalo acústico sin ocupar necesariamente el dedo que la pulsó durante todo él. Usar duración de nota como tiempo de ocupación puede rechazar un patrón posible. Tampoco las notas cortas garantizan recuperación suficiente para ataques repetidos con el mismo dedo. Conserve una tabla de ataques y recuperaciones estipuladas, separada del apoyo de traste mantenido. Es una regla finita para explicar práctica [GA](https://github.com/GuitarAlchemist/ga), no un límite fisiológico medido ni una velocidad máxima recomendada.

## Supuestos y límites específicos

Los ataques están ordenados en unidad común. Todos los dedos comienzan disponibles; se admite un ataque exactamente en el plazo. La recuperación es estipulada y no proporciona medida fisiológica ni de velocidad máxima.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión GA con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../guitar-studies/en/gtr-005-plan-which-string-keeps-ringing.md)

[Artefacto de proyecto conservado](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "attacks": [
      [
        "i",
        0
      ],
      [
        "m",
        1
      ],
      [
        "i",
        2
      ]
    ],
    "recovery": {
      "i": 2,
      "m": 2
    },
    "held_support": [
      0,
      8
    ]
  },
  "formula": "a finger is ready iff attack_time>=previous_attack_same_finger+recovery[finger]; initial fingers ready; support is recorded but not a recovery resource",
  "expected": {
    "ready": [
      true,
      true,
      true
    ],
    "violations": []
  },
  "negative_control": {
    "values": {
      "attacks": [
        [
          "i",
          0
        ],
        [
          "m",
          1
        ],
        [
          "i",
          1.5
        ]
      ],
      "recovery": {
        "i": 2,
        "m": 2
      },
      "held_support": [
        0,
        8
      ]
    },
    "expected": {
      "ready": [
        true,
        true,
        false
      ],
      "violations": [
        2
      ]
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** Todos los ataques están disponibles; el último ataque del mismo dedo coincide con su plazo.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** El apoyo mantenido `[0,8]` describe el sostén de la nota, no la ocupación del dedo pulsador.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** Las recuperaciones son entradas estipuladas; no establecen la capacidad física de una persona.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** El último ataque del control llega en 1.5, antes de la disponibilidad en 2; el índice 2 viola la regla.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Un ataque del mismo dedo anterior a su disponibilidad refuta la viabilidad bajo la regla declarada.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
