---
title: Seguir un cruce evitado al variar la desintonización
description: Seguir un cruce evitado al variar la desintonización — Acústica de la guitarra y síntesis sonora
sidebar:
  label: GAS-024 · Seguir un cruce evitado al variar la desintonización
  order: 24
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/es/gas-024-track-avoided-crossings-through-detuning.es.md
---

:::note[Streeling University]
**GAS-024** · Seguir un cruce evitado al variar la desintonización · avanzado · 55 minutos

Generado por el departamento *Acústica de la guitarra y síntesis sonora* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/es/gas-024-track-avoided-crossings-through-detuning.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAS-012](../../guitar-acoustics/gas-012-distinguish-coupling-from-parallel-resonance/)
:::

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Dos picos pueden intercambiar su carácter físico dominante cuando un parámetro de caja cruza una resonancia de cuerda. Ordenarlos por frecuencia no conserva la identidad de un componente. Siga las ramas propias de una matriz simétrica de frecuencias al cuadrado durante un barrido de desintonización. El acoplamiento abre una separación mínima entre esos autovalores. No es un ancho de amortiguamiento; sus raíces cuadradas tienen otra separación. La tabla elaborada sirve al diagnóstico [GA](https://github.com/GuitarAlchemist/ga) sin ajustar una guitarra real.

## Supuestos y límites específicos

La matriz es real simétrica y sus autovalores de frecuencia al cuadrado son positivos. No hay amortiguamiento. El mínimo se toma en el barrido finito proporcionado; no se afirma acoplamiento físico ajustado.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión GA con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../guitar-acoustics/gas-012-distinguish-coupling-from-parallel-resonance/)

[Artefacto de proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "center": 10,
    "detunings": [
      -3,
      0,
      3
    ],
    "coupling": 2
  },
  "formula": "matrix=[[c+d,g],[g,c-d]]; eigenvalues=c+-sqrt(d*d+g*g); gap=2*sqrt(d*d+g*g)",
  "expected": {
    "lower": [
      6.39444872453601,
      8,
      6.39444872453601
    ],
    "upper": [
      13.60555127546399,
      12,
      13.60555127546399
    ],
    "gaps": [
      7.211102550927978,
      4,
      7.211102550927978
    ],
    "minimum_gap": 4
  },
  "negative_control": {
    "values": {
      "center": 10,
      "detunings": [
        -3,
        0,
        3
      ],
      "coupling": 0
    },
    "expected": {
      "lower": [
        7,
        10,
        7
      ],
      "upper": [
        13,
        10,
        13
      ],
      "gaps": [
        6,
        0,
        6
      ],
      "minimum_gap": 0
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** Con desintonización nula, las ramas de frecuencia al cuadrado son 8 y 12; la separación es 4.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** La separación de frecuencias al cuadrado difiere de una separación frecuencial; conserve la coordenada antes de extraer raíces.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** Este barrido finito contiene el mínimo simétrico, pero no identifica amortiguamiento ni acoplamiento de una guitarra real.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** Con acoplamiento 0, ambas ramas se encuentran en 10 y la separación mínima es 0.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Una separación de 0 con desintonización nula y acoplamiento no nulo conservado refutaría la predicción mostrada.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
