---
module_id: "inf-011-separate-compressed-size-from-preserved-information"
department: "information-theory"
course: "Separar el tamaño comprimido de la información conservada"
title: "Separar el tamaño comprimido de la información conservada"
level: "intermediate"
prerequisites: ["inf-004-information-loss-in-agent-handoffs"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Separar el tamaño comprimido de la información conservada

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [inf-004-information-loss-in-agent-handoffs.md](../../information-theory/en/inf-004-information-loss-in-agent-handoffs.md)
- [rfc1950.html](https://www.rfc-editor.org/rfc/rfc1950.html)

Un agente acorta un traspaso y afirma que la compresión conservó todo porque el archivo ocupa menos. El requisito previo muestra que un resumen puede fusionar estados que exigen decisiones diferentes. Esta lección compara esa operación irreversible con una codificación explícitamente reversible. Los tamaños proceden de un formato didáctico, no de un compresor real ni de un flujo medido de ahorro de tokens.

La especificación primaria de zlib describe un formato comprimido sin pérdida. Motiva comprobar la reversibilidad, pero nuestra notación de rachas es un formato elaborado independiente. Se suponen conocidos el alfabeto de entrada y el decodificador. Cada racha almacena su símbolo y un carácter de longitud, además de la cabecera fija. El supuesto excluye rachas largas y entrada binaria arbitraria; ampliarlo necesitaría otra contabilidad.

Para la entrada repetida, expanda cada racha y compare la cadena completa con la original. Una ida y vuelta correcta comprueba identidad de bytes para esa entrada y ese decodificador. El tamaño almacenado incluye la cabecera. Informar solo de la carga útil exageraría la reducción. A su vez, compartir una cabecera grande entre registros exige asignar expresamente su coste, en lugar de hacerlo desaparecer del denominador.

El control alternante se expande porque cada símbolo necesita su propia pareja. La ausencia de pérdida no promete reducir todas las entradas. El resumen limitado al alfabeto es aún menor, pero distintos órdenes y recuentos coinciden en él. Permite saber qué símbolos aparecieron, pero no reconstruir la secuencia ni tomar decisiones dependientes del orden. Un resumen adecuado depende de la pregunta real del receptor.

Para la tarea asistida por fuentes, lea la colisión del requisito previo y el alcance sin pérdida de la especificación. Codifique y decodifique ambas cadenas a mano como referencia directa. Pida a un asistente que distinga igualdad de bytes, suficiencia para la tarea y tamaño almacenado en un traspaso. Conserve el caso expansivo y la colisión con pérdida. Rechace propuestas que llamen sin pérdida a toda representación menor o deduzcan una tasa de compresión de producción de este registro didáctico.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "raw": "AAAAABBB",
    "payload": "A5B3",
    "header_bytes": 2,
    "raw_bytes": 8,
    "payload_bytes": 4,
    "control_raw": "ABABABAB",
    "control_payload": "A1B1A1B1A1B1A1B1"
  },
  "formula": "stored_bytes=header_bytes+payload_bytes; ratio=stored_bytes/raw_bytes; alphabet summary discards order and counts",
  "expected": {
    "stored_bytes": 6,
    "ratio": 0.75,
    "control_stored_bytes": 18,
    "control_ratio": 2.25,
    "decoded": "AAAAABBB",
    "lossy_collision": [
      "AAAAABBB",
      "ABAAAABB"
    ],
    "alphabet_summary": "AB"
  },
  "negative_control": "Alternating input expands under the stipulated run-length format.",
  "assumptions": [
    "ASCII symbols A/B, runs of single-digit length, symbol then count, fixed two-byte header, exact decoder known."
  ],
  "limits": "Toy run-length accounting, not measured zlib output, entropy coding efficiency or semantic preservation for arbitrary consumers."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Decodifique la carga conservada.

<details>
<summary>Respuesta 1</summary>

`A5B3` se decodifica como `AAAAABBB`, igual al original.

</details>

### Ejercicio 2

Cuente la representación almacenada completa.

<details>
<summary>Respuesta 2</summary>

`2+4=6` bytes; razón `6/8=0.75`.

</details>

### Ejercicio 3

Calcule el control alternante.

<details>
<summary>Respuesta 3</summary>

`2+16=18` bytes; razón `18/8=2.25`, una expansión.

</details>

### Ejercicio 4

¿Qué pierde la proyección al alfabeto?

<details>
<summary>Respuesta 4</summary>

Orden y recuentos; `AB` no identifica de forma única la secuencia original.

</details>

### Ejercicio 5

¿Sin pérdida significa menor?

<details>
<summary>Respuesta 5</summary>

No. Reversibilidad y tamaño son afirmaciones distintas; el control es reversible y mayor.

</details>

[Paquete de pruebas fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
