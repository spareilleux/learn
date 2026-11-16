---
title: Desplazar el límite para un armónico artificial
description: Desplazar el límite para un armónico artificial — Estudios de guitarra
sidebar:
  label: GTR-016 · Desplazar el límite para un armónico artificial
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/es/gtr-016-move-the-boundary-for-an-artificial-harmonic.es.md
---

:::note[Streeling University]
**GTR-016** · Desplazar el límite para un armónico artificial · avanzado · 60 minutos

Generado por el departamento *Estudios de guitarra* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/es/gtr-016-move-the-boundary-for-an-artificial-harmonic.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GTR-012](../../guitar-studies/gtr-012-select-natural-harmonics-with-a-touch-node/)
:::

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

La posición de un armónico natural no puede permanecer fija cuando la mano crea otro extremo vibrante. Una instrucción de armónico artificial debe separar la nota pisada de base, el punto de contacto y el sonido resultante. La lección convierte esa distinción en geometría relativa al puente para un futuro diagrama de [GA](https://github.com/GuitarAlchemist/ga).

## Leer la evidencia conservada

La referencia de notación distingue armónicos naturales y artificiales y los papeles de las alturas. La lectura de ondas estacionarias justifica los nodos ideales. Añadimos una coordenada explícita; el campo de frecuencia conservado no simula contactos de dedos.

[Prerrequisito](../../guitar-studies/gtr-012-select-natural-harmonics-with-a-touch-node/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/vendor/lib.rs)

[Registro de casos construidos](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/harmonic/)

[Lectura principal](https://www.phys.unsw.edu.au/jw/strings.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "open_hz": 110,
    "fretted_semitones": 7,
    "touch_mode": 2,
    "fixed_absolute_touch_fraction": 0.5
  },
  "formula": "vibrating_fraction=2^(-fret/12); base_hz=open*2^(fret/12); touch_fraction_from_bridge=vibrating_fraction/mode; sounding_hz=mode*base_hz; fixed_touch_local=fixed_absolute_touch_fraction/vibrating_fraction",
  "expected": {
    "vibrating_fraction": 0.6674199270850172,
    "base_hz": 164.81377845643496,
    "touch_fraction_from_bridge": 0.3337099635425086,
    "sounding_hz": 329.6275569128699,
    "fixed_touch_local": 0.7491535384383408
  },
  "negative_control": {
    "values": {
      "open_hz": 110,
      "fretted_semitones": 0,
      "touch_mode": 2,
      "fixed_absolute_touch_fraction": 0.5
    },
    "expected": {
      "vibrating_fraction": 1,
      "base_hz": 110,
      "touch_fraction_from_bridge": 0.5,
      "sounding_hz": 220,
      "fixed_touch_local": 0.5
    }
  }
}
```

## Separar la posición física de los papeles de notación

El contacto firme que detiene la cuerda y el ligero que selecciona un nodo cumplen funciones distintas. Su relación geométrica cambia cuando se mueve el contacto firme. Un diagrama con solo una distancia de trastes, sin nombrar el contacto, puede ser ambiguo aunque indique bien la nota sonora. Conserve acción y origen junto a cada posición.

La ley de longitud elegida supone que pisar cambia el tramo vibrante sin cambiar la velocidad de onda. Un contacto real también puede cambiar tensión y amortiguamiento. Esos efectos modificarían la frecuencia prevista, pero no justifican reutilizar el punto medio de toda la cuerda. Geometría y aproximaciones acústicas son afirmaciones distintas que deben revisarse por separado.

El vocabulario de notación ayuda porque altura de base, de contacto y sonora no son etiquetas intercambiables. El caso no prescribe una notación universal ni prueba que un lector la ejecute. Un dibujo manual de longitud restante y modo deseado basta para detectar el origen fijo incorrecto. Antes de generar diagramas de práctica, compruebe las relaciones con distintas notas pisadas y obtenga evidencia real de contacto y sonido de un músico. Una aritmética correcta no garantiza que la colocación propuesta sea alcanzable.

### Ejercicio 1

Calcule la fracción vibrante tras pisar la cuerda. ¿Qué extremo permanece fijo en el sistema de coordenadas?

<details><summary>Respuesta 1</summary>

La fracción aparece arriba y el puente sigue siendo el origen. Se desplaza el extremo pisado; una fracción de la cuerda inicial no es necesariamente esa fracción del segmento restante.

</details>

### Ejercicio 2

Sitúe el nuevo contacto en el punto medio y calcule la frecuencia de base pisada.

<details><summary>Respuesta 2</summary>

Utilice los resultados principales. El contacto queda a mitad del segmento restante y la frecuencia de base sigue la ley de longitud temperada declarada.

</details>

### Ejercicio 3

Indique la frecuencia sonora y sepárela de los papeles de base y contacto.

<details><summary>Respuesta 3</summary>

La frecuencia sonora es el modo elegido por la frecuencia de base. Una posición de contacto o un papel de altura notada no sustituye a la frecuencia resultante.

</details>

### Ejercicio 4

Aplique el control de cuerda al aire. ¿Por qué detecta mal una posición fija incorrecta?

<details><summary>Respuesta 4</summary>

El segmento restante es toda la cuerda y ambos puntos medios coinciden. El caso pisado los distingue porque el contacto fijo tiene otra coordenada local.

</details>

### Ejercicio 5

¿Qué refuta un diagrama que conserva el mismo punto medio en todos los trastes?

<details><summary>Respuesta 5</summary>

Una distancia al puente que no se ajuste a la longitud restante refuta esa geometría. La excitación limpia y la técnica del intérprete siguen necesitando una prueba real.

</details>

## Tarea con consulta de fuentes

Dibuje los segmentos al aire y pisado, calcule las posiciones a mano e identifique los papeles de altura en la notación. Proponga una instrucción que preserve la relación con el límite móvil. Use el punto medio inicial fijo como control de refutación, sin afirmar un resultado interpretado.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
