---
module_id: gas-022-scale-a-helmholtz-cavity-with-effective-neck-length
department: guitar-acoustics
course: "Redimensionar una cavidad de Helmholtz con longitud efectiva"
level: advanced
prerequisites: ["gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Redimensionar una cavidad de Helmholtz con longitud efectiva

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Una modificación de caja cambia el área de abertura, el volumen y la corrección de extremo del cuello. El volumen por sí solo no predice el cambio frecuencial. Use la razón de Helmholtz para separar esas contribuciones. Las formas semejantes ampliadas uniformemente siguen una frecuencia inversa a la longitud. Es una aproximación de cavidad aislada: placas flexibles y radiación pueden acoplarse. La razón directa sirve de referencia para un futuro parámetro acústico de escena, no de polo identificado.

## Supuestos y límites específicos

Suponga velocidad del sonido invariable, movimientos acústicos pequeños y cavidad pequeña respecto a la longitud de onda. Las razones son positivas y la longitud del cuello es efectiva. No se incluyen vibración de placa, pérdidas de radiación ni resonancia medida.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión [GA](https://github.com/GuitarAlchemist/ga) con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../guitar-acoustics/en/gas-007-distinguish-body-poles-from-string-partials.md)

[Artefacto de proyecto conservado](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lectura primaria](https://www.phys.unsw.edu.au/jw/Helmholtz.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "area_ratio": 4,
    "volume_ratio": 8,
    "effective_length_ratio": 2
  },
  "formula": "frequency_ratio=sqrt(area_ratio/(volume_ratio*effective_length_ratio))",
  "expected": {
    "frequency_ratio": 0.5
  },
  "negative_control": {
    "values": {
      "area_ratio": 4,
      "volume_ratio": 8,
      "effective_length_ratio": 1
    },
    "expected": {
      "frequency_ratio": 0.7071067811865476
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** La razón frecuencial es 0.5 con las razones geométricas declaradas.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** La longitud efectiva incluye aire exterior arrastrado; no equivale necesariamente al grosor de la pared.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** La aproximación de cavidad compacta excluye variación arbitraria de presión y acoplamiento con una caja flexible.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** Mantener razón de longitud 1 da `sqrt(0.5)`, distinto del resultado de semejanza 0.5.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Una razón independiente incompatible con área, volumen y longitud efectiva refuta el escalado anunciado.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
