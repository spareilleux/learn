---
title: Distinguir magnitud y fase de un filtro pasa todo
description: Distinguir magnitud y fase de un filtro pasa todo — Ingeniería de audio
sidebar:
  label: AUD-023 · Distinguir magnitud y fase de un filtro pasa todo
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/es/aud-023-distinguish-allpass-magnitude-from-phase.es.md
---

:::note[Streeling University]
**AUD-023** · Distinguir magnitud y fase de un filtro pasa todo · avanzado · 55 minutos

Generado por el departamento *Ingeniería de audio* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/es/aud-023-distinguish-allpass-magnitude-from-phase.es.md) · [Mi diario](../../journal/)

Requisitos previos: [AUD-008](../../audio-engineering/aud-008-measure-a-filter-with-paired-input-and-output/)
:::

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Una superposición de magnitudes puede hacer que una etapa pasa todo parezca la identidad. Numerador y denominador tienen igual módulo sobre el círculo unidad, pero su cociente complejo cambia la fase. En una realimentación de guitarra, esa fase puede alterar la afinación aunque la magnitud sea plana. Compare la respuesta compleja con una conexión directa antes de proponer una composición transparente. Un testigo frecuencial no mide el efecto audible sobre un ataque.

## Supuestos y límites específicos

El coeficiente real tiene módulo inferior a la unidad, por lo que el polo declarado es estable. Evalúe respuesta compleja estacionaria sin inferir energía de impulso truncado ni transparencia audible. No se probó filtro compilado ni afinación de bucle.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión [GA](https://github.com/GuitarAlchemist/ga) con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../audio-engineering/aud-008-measure-a-filter-with-paired-input-and-output/)

[Artefacto de proyecto conservado](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lectura primaria](https://www.dsprelated.com/freebooks/filters/Allpass_Filters.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "a": 0.5,
    "omega_over_pi": 0.5,
    "numerator_scale": 1
  },
  "formula": "z_inv=exp(-j*pi*omega_over_pi); H=numerator_scale*(a+z_inv)/(1+a*z_inv); magnitude=abs(H)",
  "expected": {
    "H_real": 0.8,
    "H_imag": -0.6,
    "magnitude": 1,
    "identity": false
  },
  "negative_control": {
    "values": {
      "a": 0.5,
      "omega_over_pi": 0.5,
      "numerator_scale": 2
    },
    "expected": {
      "H_real": 1.6,
      "H_imag": -1.2,
      "magnitude": 2,
      "identity": false
    }
  }
}
```

### Ejercicio 1

Calcule la respuesta compleja.

> **Respuesta:** Es `0.8-0.6j`, de módulo 1, con parte imaginaria no nula.

### Ejercicio 2

¿Por qué no basta la misma magnitud?

> **Respuesta:** La identidad exige respuesta compleja igual a 1; la componente imaginaria mostrada la refuta.

### Ejercicio 3

¿Qué expresión establece la magnitud constante?

> **Respuesta:** Ambos módulos al cuadrado valen `1+a*a+2*a*cos(omega)` antes del factor adicional del numerador.

### Ejercicio 4

¿Qué muestra el control amplificado?

> **Respuesta:** Su módulo es 2; la estabilidad del polo sin cambios no certifica magnitud de pasa todo.

### Ejercicio 5

¿Qué refuta la transparencia de la conexión directa?

> **Respuesta:** Una respuesta compleja distinta de la identidad en una frecuencia admitida refuta la identidad universal.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
