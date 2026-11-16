---
module_id: wml-019-distribute-onsets-with-a-floor-lattice
department: world-music-languages
course: "Distribuir ataques mediante una retícula de partes enteras"
level: advanced
prerequisites: ["wml-006-preserve-the-origin-of-an-additive-cycle"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distribuir ataques mediante una retícula de partes enteras

> Modelo construido y lectura delimitada de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, renderizado del motor, ejecución de analizador ni adopción en producción.

Una propuesta de práctica pide un número fijo de ataques repartidos por un ciclo. Conservar el total no determina la separación. Construimos una retícula de partes enteras, examinamos todos los huecos cíclicos y aplicamos una rotación declarada. El prerrequisito ya comprueba el origen de una agrupación dada; esta lección añade su construcción antes de esa comprobación.

Multiplique cada índice de evento por el número de pulsos, divida por el número de ataques y redondee hacia abajo. Los inicios enteros distribuyen los eventos construidos. Después rótelos por igual y reduzca módulo el ciclo. Ordenarlos sirve para mostrar el ciclo anclado; la identidad de eventos necesitaría otro campo si la tarea distinguiera golpes individuales.

Nuestro criterio es limitado: el hueco mayor y el menor difieren como máximo en un pulso. No es una definición completa de regularidad musical ni una atribución cultural. El control agrupado mantiene recuentos y rotación y falla el criterio. Omitir el hueco de cierre ocultaría su mayor intervalo vacío. Dibujar un círculo a mano ofrece una referencia útil antes de proponer un DSL o un agente. El curso conservado motiva preservar origen, orden y límites culturales. Ninguna grabación, ritmo culturalmente validado o salida GA produjo estos eventos.

## Leer la evidencia conservada del proyecto

El prerrequisito aporta la operación anterior y su límite probatorio. Examine el artefacto enlazado antes de proponer cambios a partir del caso construido. Las observaciones conservan su alcance original: un archivo o ejemplo no establece el despliegue actual. El registro fijo guarda entradas, salidas preparadas y procedencia de las lecturas. Las huellas locales identifican todos los bytes sin ampliar el pasaje realmente leído. Una página primaria solo respalda la definición consultada, sin inventar revisión inmutable ni huella de bytes.

[Prerrequisito](../../world-music-languages/en/wml-006-preserve-the-origin-of-an-additive-cycle.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "pulse_count": 8,
    "onset_count": 3,
    "rotation": 1,
    "policy": "floor_lattice",
    "supplied_onsets": null
  },
  "formula": "base[i]=floor(i*N/K) for i=0..K-1 in floor_lattice, else supplied_onsets; rotated=sorted((base+rotation)%N); gaps=cyclic differences including wrap; balanced=max(gaps)-min(gaps)<=1",
  "expected": {
    "base_onsets": [
      0,
      2,
      5
    ],
    "rotated_onsets": [
      1,
      3,
      6
    ],
    "cyclic_gaps": [
      2,
      3,
      3
    ],
    "balanced": true
  },
  "negative_control": {
    "values": {
      "pulse_count": 8,
      "onset_count": 3,
      "rotation": 1,
      "policy": "supplied",
      "supplied_onsets": [
        0,
        1,
        2
      ]
    },
    "expected": {
      "base_onsets": [
        0,
        1,
        2
      ],
      "rotated_onsets": [
        1,
        2,
        3
      ],
      "cyclic_gaps": [
        1,
        1,
        6
      ],
      "balanced": false
    }
  }
}
```

## Hipótesis y límites de la evidencia

Suponga ataques enteros distintos sobre una retícula circular uniforme y recuentos positivos compatibles. El criterio incluye el cierre. Es una prueba local de separación, no un teorema completo de regularidad ni una atribución cultural.

## Interpretar la operación antes de elegir una abstracción

Antes de revelar la clave, explique el contrato de entrada con sus palabras y derive a mano el resultado principal. Conserve magnitudes intermedias o transiciones de estado en lugar de copiar solo el resultado. Aplique la misma regla al control e identifique la entrada modificada. El modelo es un ejemplo construido finito. Un cálculo coincidente respalda su afirmación concreta; no aporta observaciones de usuarios ni valida una función en producción.

### Ejercicio 1

Construya los inicios sin rotar mediante la parte entera.

<details><summary>Respuesta 1</summary>

Use cada índice en vez de redondear repetidamente una suma; los inicios fijos están mostrados.

</details>

### Ejercicio 2

Aplique la rotación sin cambiar el recuento.

<details><summary>Respuesta 2</summary>

Añada la rotación módulo el ciclo a cada inicio y ordene las posiciones distintas.

</details>

### Ejercicio 3

Calcule todos los huecos, incluido el cierre.

<details><summary>Respuesta 3</summary>

Suman el número de pulsos y el caso principal cumple el criterio máximo menos mínimo.

</details>

### Ejercicio 4

¿Por qué falla el control agrupado?

<details><summary>Respuesta 4</summary>

Su cierre es mucho mayor que los huecos vecinos pese a mantener los recuentos.

</details>

### Ejercicio 5

¿Qué refuta conservar el ritmo solo mediante el recuento?

<details><summary>Respuesta 5</summary>

Recuentos iguales con huecos distintos muestran que la cardinalidad no reconstruye la separación.

</details>

## Tarea con consulta de fuentes

Dibuje ambos ciclos sin ayuda. Proponga una instrucción GA que conserve regla, rotación y huecos sin atribuir una tradición.

Conserve su respuesta sin ayuda antes de consultar fuentes o calculadora. Identifique después un pasaje preciso y su revisión, registre toda asistencia y guarde la respuesta inicial junto a cualquier corrección. Un flujo de agente o DSL propuesto debe preservar el resultado manual y su contracaso antes de valorar su utilidad. Si falta una entrada necesaria, deje la decisión pendiente en lugar de sustituirla por un valor plausible.

Formule una refutación observable frente a la regla e indique la observación necesaria en la siguiente frontera. Las respuestas son comprobaciones preparadas, no el registro de su intento. El paquete contiene un criterio separado por ejercicio; todas las decisiones del estudiante siguen pendientes hasta conservar una respuesta real y su revisión. Adjunte ayudas, correcciones y límites a la nota final para no confundir cálculo correcto, recuerdo autónomo, juicio musical y aceptación de ejecución.
