---
module_id: gas-021-normalize-modal-energy-before-comparing-amplitudes
department: guitar-acoustics
course: "Normalizar la energía modal antes de comparar amplitudes"
level: advanced
prerequisites: ["gas-015-separate-mode-excitation-from-observation"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Normalizar la energía modal antes de comparar amplitudes

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

El coeficiente de un modo de guitarra depende de la normalización de su forma. Comparar coeficientes sin la masa modal puede invertir una clasificación energética. Integre el cuadrado del seno en una cuerda uniforme ideal y conserve el desplazamiento generalizado y el normalizado por masa. El desplazamiento físico debe permanecer igual al cambiar de coordenadas. Un informe [GA](https://github.com/GuitarAlchemist/ga) debe declarar la normalización antes de comparar energías. Se calcula energía mecánica ideal, no amplitud de pastilla ni sonoridad.

## Supuestos y límites específicos

La cuerda es uniforme y usa modos seno enteros normalizados en pico con unidades mecánicas coherentes. En el punto de retorno de la oscilación, la velocidad se anula. Es energía modal, sin ganancia de pastilla calibrada, radiación acústica ni amortiguamiento medido.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión GA con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../guitar-acoustics/en/gas-015-separate-mode-excitation-from-observation.md)

[Artefacto de proyecto conservado](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lectura primaria](https://www.phys.unsw.edu.au/jw/strings.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "linear_density": 2,
    "length": 3,
    "omega": 4,
    "amplitude": 0.5,
    "assumed_modal_mass": null
  },
  "formula": "m_eff=mu*L/2 for sine peak normalization; E=0.5*m_eff*omega^2*A^2; q=sqrt(m_eff)*A; reported_E=0.5*used_mass*omega^2*A^2",
  "expected": {
    "modal_mass": 3,
    "mass_normalized_amplitude": 0.8660254037844386,
    "energy": 6,
    "reported_energy": 6
  },
  "negative_control": {
    "values": {
      "linear_density": 2,
      "length": 3,
      "omega": 4,
      "amplitude": 0.5,
      "assumed_modal_mass": 6
    },
    "expected": {
      "modal_mass": 3,
      "mass_normalized_amplitude": 0.8660254037844386,
      "energy": 6,
      "reported_energy": 12
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** La masa efectiva es 3 y la energía en el punto de retorno de la oscilación es 6; el seno tiene antinodo unitario.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** La amplitud generalizada es 0.5; la normalizada es `sqrt(3)/2`. Son coordenadas distintas del mismo desplazamiento.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** El seno y la densidad uniforme proporcionan la integral; los modos de caja necesitan sus propias formas y matriz.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** La masa supuesta 6 produce energía declarada 12, aunque la correcta sigue siendo 6.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Un cambio de base que altere desplazamiento reconstruido o energía refuta una conversión que promete conservarlos.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
