---
title: Conservar la incertidumbre junto a una tasa de aciertos
description: Conservar la incertidumbre junto a una tasa de aciertos — Guitar Alchemist Academy
sidebar:
  label: GAA-015 · Conservar la incertidumbre junto a una tasa de aciertos
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-alchemist-academy/es/gaa-015-keep-uncertainty-with-a-practice-pass-rate.es.md
---

:::note[Streeling University]
**GAA-015** · Conservar la incertidumbre junto a una tasa de aciertos · avanzado · 60 minutos

Generado por el departamento *Guitar Alchemist Academy* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-alchemist-academy/es/gaa-015-keep-uncertainty-with-a-practice-pass-rate.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAA-010](../../guitar-alchemist-academy/gaa-010-define-a-practice-pass-before-counting-success/)
:::

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Un mismo porcentaje puede apoyarse en cantidades muy distintas de evidencia. Un resumen de práctica de [GA](https://github.com/GuitarAlchemist/ga) debe conservar el denominador y una regla explícita de incertidumbre antes de anunciar un objetivo establecido. Calculamos un intervalo de Wilson con aciertos construidos bajo hipótesis binomial, sin un registro real de un estudiante.

## Leer la evidencia conservada

El manual principal ofrece los límites de Wilson y los distingue de otro intervalo ajustado. Compare la fórmula con las reglas de acierto del registro conservado. Un intervalo no corrige una definición ambigua ni convierte respuestas asistidas en intentos autónomos.

[Prerrequisito](../../guitar-alchemist-academy/gaa-010-define-a-practice-pass-before-counting-success/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.itl.nist.gov/div898/handbook/prc/section2/prc241.htm)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "passes": 8,
    "attempts": 10,
    "z": 1.96,
    "required_lower_bound": 0.7
  },
  "formula": "p=k/n; d=1+z^2/n; center=(p+z^2/(2*n))/d; half=z*sqrt(p*(1-p)/n+z^2/(4*n^2))/d; lower=center-half; upper=center+half; established=lower>=required_lower_bound",
  "expected": {
    "rate": 0.8,
    "lower": 0.49015684672072346,
    "upper": 0.9433190520193067,
    "established": false
  },
  "negative_control": {
    "values": {
      "passes": 80,
      "attempts": 100,
      "z": 1.96,
      "required_lower_bound": 0.7
    },
    "expected": {
      "rate": 0.8,
      "lower": 0.7111690380734976,
      "upper": 0.8666340774409013,
      "established": true
    }
  }
}
```

## Adaptar el modelo de incertidumbre a la recogida de intentos

Una tasa exige unidad de observación y criterio estable. Contar notas como intentos independientes tras definir éxito para una frase completa cambiaría denominador y objetivo. Mezclar intentos asistidos y autónomos también cambia lo que describe la tasa aunque la aritmética sea correcta. Conserve resultados brutos y regla de muestreo para reconstruir recuentos sin adivinar.

El intervalo elegido es una construcción frecuentista bajo un modelo de muestreo repetido. No atribuye a un parámetro fijo desconocido la probabilidad indicada de estar dentro de este intervalo particular. No superar el límite inferior tampoco establece inferioridad. La regla es una convención prospectiva de esta lección, cuyas hipótesis deben examinarse antes de usarla en un informe real.

La práctica puede violar fácilmente una tasa común: el estudiante mejora, se cansa o recuerda correcciones durante la secuencia. Añadir repeticiones no repara automáticamente ese desajuste. Un informe útil conservaría bloques cronológicos, asistencia e identidad del ejercicio, y elegiría un análisis acorde con la recogida. El cálculo manual de Wilson es la referencia para entender la incertidumbre propuesta; un agente no debe dar autoridad artificial al intervalo ocultando sus condiciones de derivación.

### Ejercicio 1

Calcule la tasa principal. ¿Por qué no basta para la decisión declarada?

<details><summary>Respuesta 1</summary>

La tasa aparece arriba, pero la regla compara el límite inferior con el umbral previsto. Un porcentaje solo no contiene esa información de incertidumbre.

</details>

### Ejercicio 2

Calcule los límites con la constante indicada. ¿Es el intervalo simétrico de Wald?

<details><summary>Respuesta 2</summary>

Use el centro y la semiamplitud mostrados. La construcción ajusta denominador y centro; sustituirla por un error estándar alrededor de la tasa cambia el método.

</details>

### Ejercicio 3

Aplique la regla del límite inferior. ¿Qué no ha quedado establecido exactamente?

<details><summary>Respuesta 3</summary>

El límite principal queda por debajo del umbral. Es una decisión bajo esta regla, no una prueba de que la tasa subyacente sea inferior al umbral.

</details>

### Ejercicio 4

Aplique el control con la misma tasa. ¿Por qué cambia la decisión?

<details><summary>Respuesta 4</summary>

El tamaño supuesto mayor estrecha el intervalo y eleva su límite inferior sobre el umbral. El cálculo depende de la independencia y de la tasa común supuestas.

</details>

### Ejercicio 5

¿Qué invalidaría presentar esto como evidencia de dominio de un estudiante?

<details><summary>Respuesta 5</summary>

Denominadores desconocidos, rúbricas cambiantes, intentos dependientes o aprendizaje durante el muestreo debilitan el modelo. Los recuentos construidos nunca prueban intentos reales.

</details>

## Tarea con consulta de fuentes

Calcule ambos intervalos a mano, registre la regla prevista y explique las hipótesis de muestreo. Examine el límite de asistencia conservado. Proponga un informe con recuentos y dependencia pendiente, e indique cuándo retirar la interpretación binomial.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
