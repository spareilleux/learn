---
module_id: gaa-016-separate-order-drift-from-a-practice-condition
department: guitar-alchemist-academy
course: "Separar la deriva temporal del efecto de una condición de práctica"
level: advanced
prerequisites: ["gaa-012-cross-timbre-with-interval-in-an-ear-trial"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separar la deriva temporal del efecto de una condición de práctica

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Un guitarrista puede mejorar durante una sesión corta aunque dos formatos de instrucciones tengan el mismo efecto. Colocar un formato más tarde puede elevar artificialmente su media. Para una comparación de [GA](https://github.com/GuitarAlchemist/ga), examine el orden además del equilibrio de factores. Construimos una deriva lineal y comparamos secuencias con iguales recuentos por condición.

## Leer la evidencia conservada

La fuente trata del orden aleatorio y las repeticiones equilibradas. Nuestra secuencia simétrica es determinista y no constituye un experimento aleatorizado. Las reglas conservadas definen respuestas, sin eliminar la dependencia temporal.

[Prerrequisito](../../guitar-alchemist-academy/en/gaa-012-cross-timbre-with-interval-in-an-ear-trial.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.itl.nist.gov/div898/handbook/pri/section3/pri331.htm)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "order": [
      "A",
      "B",
      "B",
      "A"
    ],
    "base": 4,
    "drift_per_trial": 1,
    "condition_effect": {
      "A": 0,
      "B": 0
    }
  },
  "formula": "score_i=base+drift*i+effect[condition_i], i starts at 0; contrast=mean(B)-mean(A)",
  "expected": {
    "scores": [
      4,
      5,
      6,
      7
    ],
    "mean_a": 5.5,
    "mean_b": 5.5,
    "contrast": 0
  },
  "negative_control": {
    "values": {
      "order": [
        "A",
        "B",
        "A",
        "B"
      ],
      "base": 4,
      "drift_per_trial": 1,
      "condition_effect": {
        "A": 0,
        "B": 0
      }
    },
    "expected": {
      "scores": [
        4,
        5,
        6,
        7
      ],
      "mean_a": 5,
      "mean_b": 6,
      "contrast": 1
    }
  }
}
```

## Conservar la hipótesis de perturbación temporal

Los mismos recuentos facilitan comparar medias, pero no determinan qué instantes contribuyen a ellas. Bajo una tendencia lineal, la posición media es la magnitud adicional relevante. El orden simétrico iguala esa posición entre condiciones. Es una cancelación algebraica para la tendencia elegida, no una garantía general de que el orden deje de importar.

La alternativa muestra por qué no basta una tabla de recuentos marginales. Contiene etiquetas, recuentos y respuestas iguales, pero asocia posiciones posteriores a una condición. Un resumen que descarte el orden no puede reconstruir esa asociación. El registro bruto debe sobrevivir a la agregación del panel, junto con la rúbrica y el formato realmente presentado.

Hay tendencias que la secuencia no cancela: aprendizaje brusco tras una corrección, una pausa intermedia o un efecto del formato anterior. Un experimento futuro debería decidir aleatorización, bloques o modelado antes de observar resultados. El cálculo directo de posiciones medias ayuda a elegir ese diseño. Añadir un agente que mezcle etiquetas no documenta por sí solo aleatorización, presentación real o comparación de aprendizaje sin sesgo; esas afirmaciones necesitan un procedimiento y observaciones conservados.

### Ejercicio 1

Genere la secuencia principal a partir de la deriva. ¿Qué efecto se ha supuesto ausente?

<details><summary>Respuesta 1</summary>

Las puntuaciones indicadas crecen con la posición. Los efectos de ambas condiciones son nulos por hipótesis; cualquier diferencia procede aquí del orden o del cálculo.

</details>

### Ejercicio 2

Calcule las medias principales. ¿Por qué cancela este orden la tendencia elegida?

<details><summary>Respuesta 2</summary>

La posición media de los ensayos es igual en ambas condiciones. Por tanto, esta deriva lineal contribuye por igual a sus medias.

</details>

### Ejercicio 3

¿Un contraste nulo demuestra equivalencia de las condiciones para músicos?

<details><summary>Respuesta 3</summary>

No. Es un resultado exacto de un modelo construido. No se han observado resultados reales, incertidumbre, efectos de arrastre ni pertinencia musical.

</details>

### Ejercicio 4

Aplique el control alternado. ¿El mismo número de ensayos elimina su contraste artificial?

<details><summary>Respuesta 4</summary>

No. La posición media más tardía de la segunda condición produce el contraste no nulo mostrado, pese a los recuentos iguales y al efecto supuesto nulo.

</details>

### Ejercicio 5

¿Qué refuta que el equilibrio marginal controle cualquier efecto de orden?

<details><summary>Respuesta 5</summary>

El control ya aporta un contraejemplo lineal. Una deriva no lineal también podría derrotar la secuencia simétrica; conserve el orden y compruebe la hipótesis antes de interpretar una comparación real.

</details>

## Tarea con consulta de fuentes

Prepare las tablas de posición a mano, calcule las medias e inspeccione la rúbrica conservada. Proponga un informe futuro que mantenga el orden y una hipótesis de perturbación previa. Compare esa tabla directa con cualquier secuencia generada antes de juzgar las instrucciones.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
