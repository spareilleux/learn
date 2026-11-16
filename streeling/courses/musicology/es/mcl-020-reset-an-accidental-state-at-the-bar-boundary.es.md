---
module_id: mcl-020-reset-an-accidental-state-at-the-bar-boundary
department: musicology
course: "Reiniciar el estado de alteraciones en la barra de compás"
level: advanced
prerequisites: ["mcl-005-preserve-written-and-sounding-pitch"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Reiniciar el estado de alteraciones en la barra de compás

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Un generador lee un becuadro, lo conserva dentro del compás y lo arrastra por error tras la siguiente barra. La letra permanece y cambia la alteración prevista. Construimos una política limitada de estado notacional para precisar el efecto del reinicio. Trata del alcance del estado, además de distinguir altura escrita y sonora.

En este ejercicio, una instrucción explícita sustituye la armadura para esa letra y octava dentro del compás. Una instrucción ausente consulta esa sustitución y después la armadura. La otra octava sigue independiente. Al cambiar de compás se borran las sustituciones antes de resolver el evento. Es una política estipulada, no una regla universal de edición. Se excluyen ligaduras entre compases y casos entre pentagramas.

El control desactiva únicamente el borrado. Los eventos anteriores coinciden y el primer evento pertinente del compás nuevo revela la fuga. La barra ofrece así un criterio concreto de refutación. El elemento accidental de MusicXML describe el símbolo visible; alter especifica la altura. El receptor no debe aplicar este atajo a alturas explícitas ni añadir otra alteración por un signo de precaución. Una tabla manual muestra los contextos que debe conservar un futuro generador. No se observó analizador, partitura renderizada ni interpretación de músicos.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../musicology/en/mcl-005-preserve-written-and-sounding-pitch.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/pitch-context-2026-10-22/transposition-arithmetic.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/accidental/)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/alter/)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "key_F_alter": 1,
    "reset_at_bar": true,
    "events": [
      {
        "measure": 1,
        "octave": 4,
        "explicit_alter": 0
      },
      {
        "measure": 1,
        "octave": 4,
        "explicit_alter": null
      },
      {
        "measure": 1,
        "octave": 5,
        "explicit_alter": null
      },
      {
        "measure": 2,
        "octave": 4,
        "explicit_alter": null
      }
    ]
  },
  "formula": "state keyed by letter and octave; clear overrides at each new measure iff reset_at_bar; explicit_alter updates state; missing alter uses override else key; F4_base=65; F5_base=77; pitch=base+effective_alter",
  "expected": {
    "effective_alters": [
      0,
      0,
      1,
      1
    ],
    "pitches": [
      65,
      65,
      78,
      66
    ]
  },
  "negative_control": {
    "values": {
      "key_F_alter": 1,
      "reset_at_bar": false,
      "events": [
        {
          "measure": 1,
          "octave": 4,
          "explicit_alter": 0
        },
        {
          "measure": 1,
          "octave": 4,
          "explicit_alter": null
        },
        {
          "measure": 1,
          "octave": 5,
          "explicit_alter": null
        },
        {
          "measure": 2,
          "octave": 4,
          "explicit_alter": null
        }
      ]
    },
    "expected": {
      "effective_alters": [
        0,
        0,
        1,
        0
      ],
      "pitches": [
        65,
        65,
        78,
        65
      ]
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga solo la letra indicada, sustituciones por octava y ninguna ligadura entre compases. Los campos didácticos no son MusicXML bruto. La altura explícita codificada gobierna la decodificación independientemente del símbolo visible.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Resuelva la instrucción explícita y su continuación en la misma octava.

<details><summary>Respuesta 1</summary>

Ambas usan el becuadro explícito dentro del compás según la política declarada.

</details>

### Ejercicio 2

¿Por qué conserva la otra octava la armadura?

<details><summary>Respuesta 2</summary>

Las sustituciones dependen de letra y octava; la de otra octava no coincide.

</details>

### Ejercicio 3

Resuelva el primer evento tras la barra.

<details><summary>Respuesta 3</summary>

Borre la sustitución anterior y use la armadura al no haber nueva instrucción explícita.

</details>

### Ejercicio 4

¿Dónde difiere el control sin reinicio?

<details><summary>Respuesta 4</summary>

En el compás nuevo, donde conserva el becuadro anterior contra la política prevista.

</details>

### Ejercicio 5

¿Puede el estado visual reemplazar la altura MusicXML explícita?

<details><summary>Respuesta 5</summary>

No. Símbolo y altura codificada son distintos; este atajo no debe sobrescribir información explícita.

</details>

## Tarea con consulta de fuentes

Prepare la traza e identifique el primer evento afectado. Mantenga una columna de altura explícita antes de proponer cambios GA.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
