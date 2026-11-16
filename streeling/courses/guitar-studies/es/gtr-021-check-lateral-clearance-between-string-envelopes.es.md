---
module_id: gtr-021-check-lateral-clearance-between-string-envelopes
department: guitar-studies
course: "Comprobar la holgura lateral entre cuerdas"
level: advanced
prerequisites: ["gtr-013-judge-a-bend-with-an-uncertainty-budget"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Comprobar la holgura lateral entre cuerdas

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Una altura correcta en un bend no garantiza holgura respecto a la cuerda vecina. Conserve radios y desplazamientos barridos de ambas cuerdas antes de comparar sus envolventes. La separación entre intervalos representa el acercamiento máximo permitido, no solo la distancia entre centros en reposo. Esta comprobación geométrica conservadora puede ayudar a explicar digitaciones en [GA](https://github.com/GuitarAlchemist/ga) o una superposición [Godot](https://godotengine.org/). No reproduce elevación vertical, técnica, colisión elástica ni forma de toda la cuerda. Una separación positiva sigue siendo condicional.

## Supuestos y límites específicos

La comprobación trata una sola sección lateral con rangos de desplazamiento independientes. El contacto no cuenta como holgura y las longitudes comparten unidad. Faltan evitación vertical, geometría completa y ensayo instrumental.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión GA con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../guitar-studies/en/gtr-013-judge-a-bend-with-an-uncertainty-budget.md)

[Artefacto de proyecto conservado](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "centers": [
      0,
      10
    ],
    "radii": [
      1,
      1
    ],
    "displacements": [
      [
        0,
        6
      ],
      [
        -1,
        0
      ]
    ]
  },
  "formula": "interval_i=[center_i+min_displacement_i-radius_i,center_i+max_displacement_i+radius_i]; gap=interval_1.low-interval_0.high; clear=gap>0",
  "expected": {
    "intervals": [
      [
        -1,
        7
      ],
      [
        8,
        11
      ]
    ],
    "gap": 1,
    "clear": true
  },
  "negative_control": {
    "values": {
      "centers": [
        0,
        10
      ],
      "radii": [
        1,
        1
      ],
      "displacements": [
        [
          0,
          8
        ],
        [
          -1,
          0
        ]
      ]
    },
    "expected": {
      "intervals": [
        [
          -1,
          9
        ],
        [
          8,
          11
        ]
      ],
      "gap": -1,
      "clear": false
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** Los intervalos barridos son `[-1,7]` y `[8,11]`; la separación es 1 y hay holgura.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** La distancia entre centros en reposo no es holgura entre bordes; radios y movimientos la reducen.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** Los rangos independientes dan una envolvente conservadora; los movimientos correlacionados necesitan trayectorias.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** La separación del control es -1: las envolventes se solapan y falla la holgura anunciada.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Un desplazamiento admitido que produzca intersección refuta la holgura lateral universal en esta sección.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
