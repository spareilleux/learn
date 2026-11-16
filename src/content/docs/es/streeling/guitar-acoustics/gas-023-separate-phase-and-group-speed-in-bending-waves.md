---
title: Distinguir velocidades de fase y grupo en ondas de flexión
description: Distinguir velocidades de fase y grupo en ondas de flexión — Acústica de la guitarra y síntesis sonora
sidebar:
  label: GAS-023 · Distinguir velocidades de fase y grupo en ondas de flexión
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/es/gas-023-separate-phase-and-group-speed-in-bending-waves.es.md
---

:::note[Streeling University]
**GAS-023** · Distinguir velocidades de fase y grupo en ondas de flexión · avanzado · 55 minutos

Generado por el departamento *Acústica de la guitarra y síntesis sonora* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/es/gas-023-separate-phase-and-group-speed-in-bending-waves.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAS-010](../../guitar-acoustics/gas-010-distinguish-stiff-string-partials-from-harmonics/)
:::

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Una animación de ondas de caja puede mover crestas y envolvente a igual velocidad por defecto. Una ley ideal de dispersión por flexión da velocidades distintas. Derive la frecuencia angular respecto al número de onda en vez de dividirlos. La interpretación de paquete estrecho supone banda local y poca deformación; no promete traslación rígida de cualquier pulso. El cálculo propone un diagnóstico para una visualización acústica [Godot](https://godotengine.org/); mallas, materiales y propagación real quedan pendientes.

## Supuestos y límites específicos

Use número de onda y coeficiente positivos en la ley de potencias mostrada. La velocidad de grupo es la derivada local en banda estrecha. No se ejecutó solver material, respuesta de caja calibrada, pulso ancho ni simulación de escena.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión [GA](https://github.com/GuitarAlchemist/ga) con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../guitar-acoustics/gas-010-distinguish-stiff-string-partials-from-harmonics/)

[Artefacto de proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lectura primaria](https://www.dsprelated.com/freebooks/pasp/Stiff_String.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "coefficient": 2,
    "wavenumber": 3,
    "power": 2
  },
  "formula": "omega=C*k^p; phase_speed=omega/k; group_speed=C*p*k^(p-1)",
  "expected": {
    "omega": 18,
    "phase_speed": 6,
    "group_speed": 12
  },
  "negative_control": {
    "values": {
      "coefficient": 2,
      "wavenumber": 3,
      "power": 1
    },
    "expected": {
      "omega": 6,
      "phase_speed": 2,
      "group_speed": 2
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** La frecuencia angular es 18, la velocidad de fase 6 y la de grupo 12, en unidades coherentes estipuladas.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** Una cresta sigue la fase; una envolvente estrecha sigue la derivada local bajo la aproximación declarada.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** Un paquete ancho puede dispersarse; asignarle una velocidad de envolvente invariable exige más pruebas.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** El control lineal da ambas velocidades iguales a 2; aísla la curvatura de la dispersión.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Una animación declarada cuadrática que iguale velocidad de crestas y velocidad local de grupo contradice este modelo.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
