---
module_id: gtr-017-check-contact-continuity-during-finger-substitution
department: guitar-studies
course: "Comprobar la continuidad del contacto al sustituir un dedo"
level: advanced
prerequisites: ["gtr-011-test-barre-coverage-before-calling-a-shape-playable"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Comprobar la continuidad del contacto al sustituir un dedo

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Una nota sostenida puede conservar cuerda y traste aunque cambie el dedo que la mantiene. Una lista de alturas oculta si el sustituto llega después de retirarse el primero. Para una instrucción de [GA](https://github.com/GuitarAlchemist/ga), comprobamos los contactos antes de llamar continua a la sustitución. Así añadimos una condición temporal a la geometría estática.

## Leer la evidencia conservada

El registro de ocupación conservado sigue eventos musicales sobre cuerdas, sin describir contactos de dedos. Sus límites explícitos invitan a mantener otro registro para ellos. El registro propuesto es didáctico y no modifica ningún esquema del proyecto.

[Prerrequisito](../../guitar-studies/en/gtr-011-test-barre-coverage-before-calling-a-shape-playable.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "required_interval_s": [
      0,
      1
    ],
    "contacts": [
      {
        "finger": "index",
        "interval_s": [
          0,
          0.6
        ]
      },
      {
        "finger": "ring",
        "interval_s": [
          0.5,
          1
        ]
      }
    ]
  },
  "formula": "merge half-open contact intervals at the same string/fret; gaps=required_interval minus union; overlap=max(0,min(ends)-max(starts)); continuous=(gaps empty)",
  "expected": {
    "union_s": [
      [
        0,
        1
      ]
    ],
    "gaps_s": [],
    "overlap_s": 0.1,
    "continuous": true
  },
  "negative_control": {
    "values": {
      "required_interval_s": [
        0,
        1
      ],
      "contacts": [
        {
          "finger": "index",
          "interval_s": [
            0,
            0.6
          ]
        },
        {
          "finger": "ring",
          "interval_s": [
            0.7,
            1
          ]
        }
      ]
    },
    "expected": {
      "union_s": [
        [
          0,
          0.6
        ],
        [
          0.7,
          1
        ]
      ],
      "gaps_s": [
        [
          0.6,
          0.7
        ]
      ],
      "overlap_s": 0,
      "continuous": false
    }
  }
}
```

## Tratar la sustitución como un relevo de contacto

El evento musical y el del dedo tienen identidades distintas. Mantener el primero no implica continuidad del segundo. A la inversa, cambiar de dedo no pide necesariamente otro ataque. Importa cuando una instrucción libera un dedo para el acorde siguiente y mantiene la nota actual. La cronología debe explicar el solapamiento, sin deducirlo solo de una altura invariable.

Los intervalos semiabiertos explicitan los límites. Un sustituto que empiece exactamente al terminar el contacto original no dejaría hueco en el modelo, pero tampoco margen positivo de solapamiento. Su fiabilidad para una persona es otra pregunta. La incertidumbre temporal puede convertir ese relevo exacto en un hueco; una tarea real guardaría tiempos estimados o un margen deliberado, sin presentar el calendario ideal como técnica medida.

La unión ignora otras demandas de los dedos. Un dedo puede tener que abandonar otra posición antes de aportar el contacto previsto; la misma posición también puede trastear pese a cobertura nominal continua. Estas restricciones ausentes limitan el resultado a una condición necesaria de planificación. El registro manual basta para rechazar el control retrasado. Solo después tendría sentido combinar disponibilidad, alcance y sonido sostenido limpio observado en un planificador propuesto; aquí no se entrega ese planificador ni una interpretación.

### Ejercicio 1

¿Qué permanece fijo y qué cambia en el registro principal?

<details><summary>Respuesta 1</summary>

La cuerda, el traste y el intervalo sostenido previstos permanecen fijos; cambia la identidad del dedo. Una lista de alturas no tiene un campo para expresar este relevo.

</details>

### Ejercicio 2

Una los intervalos de contacto. ¿Queda cubierto cada instante requerido?

<details><summary>Respuesta 2</summary>

La unión principal cubre el intervalo semiabierto requerido. El solapamiento representa contactos simultáneos durante el relevo, sin un nuevo ataque musical.

</details>

### Ejercicio 3

Calcule el solapamiento. ¿Garantiza un sonido limpio?

<details><summary>Respuesta 3</summary>

Su duración aparece abajo. Solo establece coexistencia programada de contactos; no se han indicado ni medido su presión o calidad.

</details>

### Ejercicio 4

Aplique el control retrasado y localice el intervalo sin cobertura.

<details><summary>Respuesta 4</summary>

El hueco mostrado rompe la continuidad aunque las alturas sigan iguales. Un comprobador de notas objetivo solamente no detecta este fallo.

</details>

### Ejercicio 5

¿Qué refuta un plan de contacto anunciado como continuo?

<details><summary>Respuesta 5</summary>

Cualquier parte descubierta del intervalo requerido refuta el plan. Un trasteo o una interrupción observados podrían refutar por separado el éxito físico aunque pase esta condición necesaria.

</details>

## Tarea con consulta de fuentes

Dibuje ambas cronologías antes de consultar las respuestas. Compare ocupación musical y contacto de dedos, y proponga el registro adicional mínimo. Conserve el control con hueco y distinga un fallo del plan de un fallo de interpretación; no se ha intentado ninguna ejecución.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
