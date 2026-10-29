---
title: Precompensar la frecuencia de corte bilineal
description: Precompensar la frecuencia de corte bilineal — Ingeniería de audio
sidebar:
  label: AUD-024 · Precompensar la frecuencia de corte bilineal
  order: 24
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/es/aud-024-prewarp-a-bilinear-filter-cutoff.es.md
---

:::note[Streeling University]
**AUD-024** · Precompensar la frecuencia de corte bilineal · avanzado · 55 minutos

Generado por el departamento *Ingeniería de audio* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/es/aud-024-prewarp-a-bilinear-filter-cutoff.es.md) · [Mi diario](../../journal/)

Requisitos previos: [AUD-013](../../audio-engineering/aud-013-resample-without-relabeling-the-clock/)
:::

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Una petición de filtro indica un corte digital, mientras que el prototipo analógico espera frecuencia angular. Copiar directamente la frecuencia solicitada ignora la transformación bilineal. Invierta esa transformación antes de producir coeficientes para un futuro filtro de guitarra. El reloj elegido hace visible la diferencia. La correspondencia conserva un objetivo elegido, no todos los anchos de banda en frecuencia ordinaria; el diseño completo aún necesita sus especificaciones.

## Supuestos y límites específicos

El reloj es positivo y el objetivo queda estrictamente entre cero y Nyquist. Use el factor bilineal declarado y la arcotangente real principal. Es aritmética de correspondencia frecuencial, no generación ejecutada de coeficientes.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión [GA](https://github.com/GuitarAlchemist/ga) con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../audio-engineering/aud-013-resample-without-relabeling-the-clock/)

[Artefacto de proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lectura primaria](https://www.dsprelated.com/freebooks/filters/Frequency_Warping.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "sample_rate_hz": 8,
    "target_hz": 2,
    "prewarp": true
  },
  "formula": "Omega=2*fs*tan(pi*target/fs) if prewarp else 2*pi*target; achieved=fs/pi*atan(Omega/(2*fs)); error=achieved-target",
  "expected": {
    "analog_rad_s": 16,
    "achieved_hz": 2,
    "error_hz": 0
  },
  "negative_control": {
    "values": {
      "sample_rate_hz": 8,
      "target_hz": 2,
      "prewarp": false
    },
    "expected": {
      "analog_rad_s": 12.566370614359172,
      "achieved_hz": 1.6953789327654465,
      "error_hz": -0.3046210672345535
    }
  }
}
```

### Ejercicio 1

Encuentre el objetivo analógico precompensado.

> **Respuesta:** Es `16 rad/s`; el argumento de la tangente es `pi/4`.

### Ejercicio 2

Devuélvalo a frecuencia digital.

> **Respuesta:** La inversa da `2 Hz`; el error en el objetivo elegido es 0.

### Ejercicio 3

¿Pueden sustituirse hercios por frecuencia angular?

> **Respuesta:** No. Las unidades difieren; el factor de conversión pertenece a la transformación declarada.

### Ejercicio 4

¿Por qué falla el control ingenuo?

> **Respuesta:** Su valor analógico `4*pi` es menor que 16 y la transformación creciente devuelve un corte digital menor.

### Ejercicio 5

¿Qué refuta el corte anunciado?

> **Respuesta:** Una frecuencia obtenida distinta del objetivo conservado lo refuta bajo esta transformación.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
