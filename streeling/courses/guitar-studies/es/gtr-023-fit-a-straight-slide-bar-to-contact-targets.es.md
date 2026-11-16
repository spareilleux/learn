---
module_id: gtr-023-fit-a-straight-slide-bar-to-contact-targets
department: guitar-studies
course: "Ajustar una barra de slide recta a contactos objetivo"
level: advanced
prerequisites: ["gtr-019-declare-the-coordinate-of-a-continuous-slide"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Ajustar una barra de slide recta a contactos objetivo

> Modelo finito elaborado y lectura acotada de fuentes. Las decisiones técnicas humanas, lingüísticas, musicales y de estudiantes siguen pendientes. No se afirma un nuevo renderizado, escucha, interpretación instrumental, ejecución de parser ni adopción en producción.

Un diagrama puede mostrar posiciones de slide válidas por separado que una barra recta rígida no alcanza simultáneamente. Ajuste la coordenada de contacto como función afín de la posición transversal. Los mínimos cuadrados dan una referencia explícita y el residuo absoluto máximo comprueba la tolerancia geométrica. La cercanía de alturas es otro objetivo y necesita otros pesos. El ajuste elaborado limita una futura sugerencia [GA](https://github.com/GuitarAlchemist/ga) o escena didáctica; no simula mano ni contacto de la barra.

## Supuestos y límites específicos

Las coordenadas transversales son distintas; los mínimos cuadrados no llevan pesos y usan longitud física. La barra rígida es recta. El residuo firmado es objetivo menos contacto ajustado. Se excluyen deformación, optimización de altura y ensayo instrumental.

## Partir de la representación directa

Escriba la tabla principal antes de abrir las respuestas preparadas. Identifique marco de coordenadas, unidad física o lógica, soporte y orden de cada campo. Una cifra sin su convención no puede pasar fielmente a un grafo de audio, una escena o un mensaje de agente. Deduzca magnitudes intermedias además de la decisión final. El paquete separa deliberadamente entradas y resultados esperados para que otra persona pueda recalcular, en vez de reconocer una etiqueta familiar.

Repita la operación con el control negativo y mantenga visibles sus entradas modificadas. Explique qué invariante se conserva y qué afirmación falla. Un control útil apunta al mecanismo estudiado; otro ejemplo meramente plausible puede no tocar la frontera arriesgada. El acuerdo del caso principal por sí solo no demuestra que una abstracción conserve la operación. A la inversa, rechazar el control es un resultado previsto del modelo didáctico, no un defecto observado en un producto existente.

Lea el prerrequisito completo y el artefacto conservado de abajo. El prerrequisito establece una operación anterior con sus límites. El programa conservado ofrece un proceso real de comparación de audio y separa muestras brutas, salida codificada y decisiones de aceptación. No implementa el nuevo modelo de esta lección. Las huellas locales identifican bytes completos en la revisión fijada; no convierten una inspección en ejecución. Una referencia primaria enlazada solo respalda la definición acotada registrada en el paquete.

## Preparar una entrega de proyecto con las fuentes

Redacte una breve nota de revisión GA con su cálculo manual, convención y testigo de rechazo. Conserve ese resultado directo como referencia antes de proponer un nodo DSL, instrucción de agente o control de escena. La propuesta debe explicar qué información conserva su entrada y qué observación refutaría su fidelidad. Si falta una entrada, deje el resultado sin resolver en vez de sustituirlo por un valor conveniente.

Conserve su respuesta sin ayuda antes de revelar las correcciones. Registre calculadora, consulta de fuentes y asistencia de agentes; guarde después respuesta corregida y original con el motivo del cambio. El paquete prepara un criterio por ejercicio, sin decisiones de aceptación de estudiantes. Coincidir con la clave no prueba recuerdo independiente ni ensayo exitoso. Registre comandos, entradas, salidas, fallos y repeticiones realmente ejecutados en el diario de validación. Revisión técnica humana, revisión lingüística, juicio musical, ejecución en producción y publicación requieren sus propias pruebas.

[Prerrequisito](../../guitar-studies/en/gtr-019-declare-the-coordinate-of-a-continuous-slide.md)

[Artefacto de proyecto conservado](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquete elaborado fijo](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "transverse": [
      0,
      1,
      2
    ],
    "targets": [
      3,
      4,
      5
    ],
    "tolerance": 0.1
  },
  "formula": "b=sum((y-mean(y))*(x-mean(x)))/sum((y-mean(y))^2); a=mean(x)-b*mean(y); residual=target-(a+b*y); fits=max(abs(residual))<=tolerance",
  "expected": {
    "intercept": 3,
    "slope": 1,
    "residuals": [
      0,
      0,
      0
    ],
    "fits": true
  },
  "negative_control": {
    "values": {
      "transverse": [
        0,
        1,
        2
      ],
      "targets": [
        3,
        4,
        6
      ],
      "tolerance": 0.1
    },
    "expected": {
      "intercept": 2.8333333333333335,
      "slope": 1.5,
      "residuals": [
        0.16666666666666666,
        -0.3333333333333333,
        0.16666666666666666
      ],
      "fits": false
    }
  }
}
```

### Ejercicio 1

Calcule el resultado principal y nombre su convención.

> **Respuesta:** La ordenada en origen es 3 y la pendiente 1; todos los residuos son 0.

### Ejercicio 2

¿Qué magnitud debe mantenerse separada?

> **Respuesta:** Error geométrico y error de altura son objetivos distintos; este ajuste no minimiza cents.

### Ejercicio 3

¿Qué supuesto limita la conclusión?

> **Respuesta:** Una barra recta rígida impone una línea afín; contactos curvos o articulados necesitan otro modelo.

### Ejercicio 4

Explique el control negativo.

> **Respuesta:** Los residuos del control son `[1/6,-1/3,1/6]`; su magnitud máxima supera 0.1.

### Ejercicio 5

¿Qué observación refutaría la propuesta?

> **Respuesta:** Un residuo máximo conservado mayor que la tolerancia refuta un ajuste simultáneo bajo esta regla.

## Tarea del estudiante con fuentes

Aplique la entrega directa anterior a ambos casos fijos. Conserve tabla de entrada tipada, resultados intermedios, explicación del control negativo y testigo final de rechazo. Las respuestas son comprobaciones preparadas, no observaciones de su trabajo.
