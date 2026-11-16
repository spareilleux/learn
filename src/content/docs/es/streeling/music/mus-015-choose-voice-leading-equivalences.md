---
title: Elegir qué ignora una distancia de conducción de voces
description: Elegir qué ignora una distancia de conducción de voces — Música
sidebar:
  label: MUS-015 · Elegir qué ignora una distancia de conducción de voces
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/music/es/mus-015-choose-voice-leading-equivalences.es.md
---

:::note[Streeling University]
**MUS-015** · Elegir qué ignora una distancia de conducción de voces · intermedio · 60 minutos

Generado por el departamento *Música* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/music/es/mus-015-choose-voice-leading-equivalences.es.md) · [Mi diario](../../journal/)

Requisitos previos: [MUS-014](../../music/mus-014-inversions-bass-line/)
:::

## Pregunta del proyecto y entregable

Un guitarrista pide a GA una disposición de voces cercana. ¿«Cercana» conserva el orden de las voces, el registro o solo la colección de clases de altura? Escribe un contrato de comparación antes de interpretar la puntuación. Esta lección produce una tabla de cálculo de cuatro filas y un registro de laboratorio reproducible.

El [código fuente de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Atonal/VoiceLeadingSpace.cs) estudiado aquí está fijado en `dc2e74cbd992a298f67efb928b5b3754615e1924`. Sus [opciones](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Theory/Atonal/VoiceLeadingOptions.cs) distinguen las equivalencias de octava, permutación, transposición e inversión. Mantendremos desactivadas la transposición y la inversión salvo que un caso indique expresamente lo contrario. Las alturas numéricas están espaciadas por semitonos y siguen la convención C4 = 60; no incluyen identidad de cuerda ni de dedo.

## 1. Declarar la información conservada

Con la equivalencia de octava desactivada, el coste de una pareja emparejada es el valor absoluto de su diferencia en semitonos. Con la equivalencia de octava activada, reduce esa diferencia módulo 12 y toma la distancia más corta en el círculo de clases de altura. Así, pasar de 60 a 72 cuesta 12 en la primera comparación y 0 en la segunda. Esta es una elección de equivalencia matemática: no significa que el intérprete haya mantenido la misma nota sonora.

La equivalencia de permutación determina si las entradas de destino pueden reasignarse a las entradas de origen. Cuando está desactivada, las entradas se emparejan por posición. Cuando está activada, la implementación fijada ordena las alturas con su registro; si la equivalencia de octava también está activada, prueba desplazamientos cíclicos de esos arrays ordenados. La sección 4 muestra por qué importa este detalle de implementación.

### Ejercicio práctico 1

En un ejercicio que sigue una voz melódica identificada de C4 a C5, ¿debe la equivalencia de octava ocultar el salto?

> **Respuesta:** No. Conserva el registro e indica el movimiento de 12 semitonos. Una comparación de clases de altura puede indicar 0 por separado, pero responde a otra pregunta. Ninguna puntuación dice si una digitación concreta de guitarra es cómoda.

## 2. Calcular las cuatro comparaciones

Usa el origen `[60,64,67]` y el destino `[67,64,60]`. Las notas de origen son C4, E4 y G4. Con las posiciones de las entradas fijas, la primera y la última voz se mueven 7 semitonos en sentidos opuestos. Con equivalencia de octava, cada pareja cuesta 5 en cambio. Permitir la reasignación puede emparejar cada altura consigo misma.

| Equivalencia de octava | Equivalencia de permutación | Escalar nativo |
|---|---|---:|
| Desactivada | Desactivada | 14 |
| Activada | Desactivada | 10 |
| Desactivada | Activada | 0 |
| Activada | Activada | 0 |

Estos valores se reprodujeron compilando la clase fijada sin cambios en el [laboratorio independiente](https://github.com/spareilleux/learn/tree/codex/streeling-craft-transfer-20261022/code/streeling/voice-leading). Allí se documenta un adaptador de anotaciones utilizado solo para compilar; no se trata del ensamblado original de GA ni de su suite completa de pruebas.

### Ejercicio práctico 2

Un agente cita 0 para estos arrays y concluye que la primera voz identificada no se movió. ¿Qué información falta?

> **Respuesta:** Los ajustes de equivalencia y la correspondencia entre voces. Un cero tras la reasignación no conserva la primera entrada como primera voz. La comparación absoluta con posiciones fijas vale 14; sus movimientos con signo son +7, 0 y −7 semitonos.

## 3. Las clases de altura comunes no significan notas sostenidas

Compara `[60,64,67]` con `[72,76,79]`. Las colecciones no comparten ninguna altura en el mismo registro, pero coinciden las tres clases de altura. Los recuentos didácticos de intersección del laboratorio dan 0 alturas comunes teniendo en cuenta el registro y 3 clases de altura comunes. Esos recuentos son cálculos sencillos de conjuntos, no resultados del servicio de notas comunes de GA. La distancia absoluta con posiciones fijas es 36; la distancia con equivalencia de octava y posiciones fijas es 0.

### Ejercicio práctico 3

Escribe una anotación veraz para ese desplazamiento de octava que incluya ambas distancias y la distinción entre tipos de notas comunes.

> **Respuesta:** «Distancia teniendo en cuenta el registro: 36; distancia con equivalencia de octava: 0; 0 alturas comunes teniendo en cuenta el registro y 3 clases de altura comunes». No describas las notas como sostenidas ni la mano como inmóvil. No se midieron la duración, la articulación ni la colocación física.

## 4. Reproducir un límite de la implementación fijada

Para `[60,63,65]` y `[60,65,75]`, activa las equivalencias de octava y permutación y desactiva la transposición y la inversión. Ambas colecciones tienen el mismo multiconjunto de clases de altura. La implementación fijada devuelve 4. Los costes de sus candidatos cíclicos son 4, 10 y 6. La enumeración exhaustiva de todas las permutaciones del destino encuentra la asignación `[60,75,65]`, cuyos costes circulares suman 0. Ordenar las alturas con su registro antes de restringir la búsqueda de asignaciones puede hacer que se omita este emparejamiento.

Usa [Node.js](https://nodejs.org/api/cli.html) y el [SDK de .NET 10.0.113](https://learn.microsoft.com/dotnet/core/tools/dotnet-build) ya instalados. Desde la copia de trabajo de Learn, elige un nuevo directorio de salida hermano; su directorio padre ya debe existir. Esta orden se escribe igual en Windows, Linux / WSL y macOS, pero solo se ha evaluado Windows:

```sh
node code/streeling/voice-leading/run.mjs ../streeling-voiceleading-new-run
```

El controlador comprueba los hashes de las fuentes, compila fuera de la copia de trabajo y escribe `results.json` y `commands.json`. Se vacían las fuentes de paquetes y se [desactivan las descargas en segundo plano de los manifiestos de cargas de trabajo](https://learn.microsoft.com/dotnet/core/tools/dotnet-environment-variables). La ejecución registrada superó 40 comprobaciones de caracterización. Esto significa que reprodujo las observaciones declaradas, incluido el desacuerdo; `original_expected_equivalence_satisfied` sigue siendo falso. Examina los [resultados conservados](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/native-results.json), no solo el código de salida del proceso.

### Ejercicio práctico 4

Calcula los costes circulares de la asignación `[60,75,65]`. ¿Debe un laboratorio que supera las comprobaciones certificar la implementación de equivalencia original?

> **Respuesta:** Las diferencias emparejadas son 0, 12 y 0, lo que da costes circulares de 0, 0 y 0. No: la caracterización tiene éxito al reproducir el resultado nativo de 4 frente al exhaustivo de 0. Este laboratorio no ha corregido el método de producción.

## 5. Entregar un contrato de comparación

Conserva en tu registro la revisión fijada de las fuentes, los arrays, las cuatro elecciones de equivalencia, la tabla de cálculo, el escalar observado y su interpretación. Adjunta los resultados ejecutables cuando estén disponibles. Si no puedes ejecutar el SDK, completa los cálculos a mano e indica que la ejecución no se ha evaluado. La [tarea del estudiante y la rúbrica de revisión](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/learner-task.md) distinguen la comprobación con ayuda de las fuentes de una prueba de aprendizaje con una persona.

### Ejercicio práctico 5

¿Qué pruebas adicionales justificarían calificar una disposición de voces recomendada como físicamente fácil de tocar?

> **Respuesta:** Una asignación real a cuerdas y trastes, las limitaciones del intérprete y una prueba instrumental con un criterio declarado. Los cálculos escalares, la inspección de las fuentes y la ejecución independiente no aportan ninguna de esas observaciones. Continúa con la [correspondencia entre voces](../../music/mus-016-recover-voice-correspondence/) antes de tratar un mínimo como un plan de ejecución instrumental.
