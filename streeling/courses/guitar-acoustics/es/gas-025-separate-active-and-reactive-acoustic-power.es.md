---
module_id: gas-025-separate-active-and-reactive-acoustic-power
department: guitar-acoustics
course: "Distinguir potencia acústica activa y reactiva"
level: advanced
prerequisites: ["gas-018-account-for-energy-at-an-impedance-junction"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguir potencia acústica activa y reactiva

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Presión y caudal oscilantes grandes no garantizan gran potencia media transferida. Importa su fase relativa. Multiplique presión por caudal conjugado y conserve el factor de fasores de pico antes de tomar la parte real. La parte imaginaria describe intercambio reactivo según el signo elegido; no es potencia media disipada adicional. Este cálculo de puerto ayuda a revisar un diagnóstico de caja sin calibrar ni medir presión real. No sustituya caudal por velocidad local sin cambiar de magnitud.

## Supuestos y límites específicos

Use fasores de pico con convención temporal exponencial compleja positiva, y presión y caudal en el mismo puerto. El flujo entra al puerto. No se obtuvo campo espacial de intensidad ni medida calibrada real de potencia.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión [GA](https://github.com/GuitarAlchemist/ga) con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../guitar-acoustics/en/gas-018-account-for-energy-at-an-impedance-junction.md)

[Artefacto de proyecto conservado](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "pressure": [
      2,
      0
    ],
    "volume_velocity": [
      0,
      1
    ],
    "phasor_kind": "peak"
  },
  "formula": "S=0.5*P*conj(U) for peak phasors; active=real(S); reactive=imag(S)",
  "expected": {
    "complex_power": [
      0,
      -1
    ],
    "active": 0,
    "reactive": -1
  },
  "negative_control": {
    "values": {
      "pressure": [
        2,
        0
      ],
      "volume_velocity": [
        1,
        0
      ],
      "phasor_kind": "peak"
    },
    "expected": {
      "complex_power": [
        1,
        0
      ],
      "active": 1,
      "reactive": 0
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** La potencia compleja principal es `-1j`, con potencia activa 0 y reactiva -1.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** La potencia reactiva no se suma a la disipación media; describe intercambio en cuadratura según la convención.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** El factor 0.5 pertenece a fasores de pico; los fasores eficaces requieren otra normalización.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** En fase, la potencia compleja es 1, la activa 1 y la reactiva 0 pese a módulos sin cambios.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Una regla basada solo en módulos que prediga igual potencia media queda refutada por su diferencia de fase.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
