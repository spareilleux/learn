---
title: Planificar la conducción de voces en una frase completa
description: Planificar la conducción de voces en una frase completa — Música
sidebar:
  label: MUS-023 · Planificar la conducción de voces en una frase completa
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/music/es/mus-023-plan-voice-leading-across-a-phrase.es.md
---

:::note[Streeling University]
**MUS-023** · Planificar la conducción de voces en una frase completa · intermedio · 60 minutos

Generado por el departamento *Música* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/music/es/mus-023-plan-voice-leading-across-a-phrase.es.md) · [Mi diario](../../journal/)

Requisitos previos: [MUS-005](../../music/mus-005-jazz-harmony/), [MUS-016](../../music/mus-016-recover-voice-correspondence/)
:::

## Pregunta del proyecto y entrega

Un guitarrista quiere llegar a un registro concreto al final de una frase. Elegir el siguiente voicing más cercano puede posponer un salto grande hasta el último acorde. Compara los recorridos completos y explica cuándo una elección localmente más costosa mejora la frase en su conjunto.

La versión de referencia de [AdvancedTabSolver](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L52) de GA construye posiciones candidatas para cada paso y utiliza una tabla de programación dinámica para conservar recorridos. Esta lección calcula un ejemplo construido mucho más pequeño. No ejecuta ese solucionador, no reproduce su objetivo físico y estilístico ni afirma que GA haya generado estos candidatos. El [conjunto de datos conservado](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/phrase-paths.json) muestra todas las entradas y todos los resultados.

## 1. Fijar la tarea musical y las etiquetas de las voces

Utiliza C4 = 60 y dos voces etiquetadas con registro definido. Empareja las entradas por su etiqueta y suma sus desplazamientos absolutos en semitonos. No reduzcas las octavas ni reasignes las voces. Son voicings reducidos a notas guía, no acordes completos ni propuestas de digitación:

| Paso | Contexto de acorde | Alturas con registro | Nombres de las notas |
|---|---|---|---|
| Inicio | Cmaj7 | 52, 59 | E3, B3 |
| Siguiente | Dm7 | 53, 60 | F3, C4 |
| Opción grave | G7 | 53, 59 | F3, B3 |
| Opción aguda | G7 | 59, 65 | B3, F4 |
| Final exigido | Cmaj7 | 64, 71 | E4, B4 |

La tercera y la séptima identifican la función de cada voicing reducido en el contexto de acorde dado; esas notas por sí solas no tienen por qué determinar el nombre del acorde. MUS-005 enseña las notas guía. Aquí se añaden el registro final exigido y la comparación de recorridos completos.

### Ejercicio práctico 1

Calcula el desplazamiento del inicio a Dm7 y después de Dm7 a cada opción de G7. Mantén fijas las etiquetas de las voces.

> **Respuesta:** Del inicio a Dm7 el coste es 1 + 1 = 2. De Dm7 a G7-grave el coste es 0 + 1 = 1. De Dm7 a G7-agudo el coste es 6 + 5 = 11. En este punto, la opción grave tiene el prefijo más barato: 3 en lugar de 13.

## 2. Incluir el final exigido

De G7-grave al final el coste es 11 + 12 = 23. De G7-agudo al mismo final el coste es 5 + 6 = 11. Este conjunto de datos solo permite dos recorridos completos:

| Opción de G7 | Costes de las tres transiciones | Coste de la frase completa |
|---|---|---:|
| Grave | 2, 1, 23 | 26 |
| Aguda | 2, 11, 11 | 24 |

La regla de elegir siempre la siguiente opción más cercana selecciona la grave y después paga el salto final mayor. La enumeración de recorridos completos selecciona la aguda con un coste de 24. Es la opción óptima entre estos dos recorridos construidos según el objetivo declarado. No es una afirmación sobre todas las armonizaciones posibles, la preferencia musical o la comodidad al tocar.

### Ejercicio práctico 2

Escribe las dos líneas etiquetadas del recorrido con menor coste total. ¿Un total menor garantiza que cada salto individual sea menor?

> **Respuesta:** Las líneas son E3 → F3 → B3 → E4 y B3 → C4 → F4 → B4. Sus desplazamientos absolutos suman 12 y 12, lo que da 24. No: el movimiento de Dm7 a G7 es mayor que en el recorrido grave. Hemos optimizado la suma de toda la frase, no cada transición individual.

## 3. Conservar el mejor prefijo para cada estado

En este ejemplo finito con costes aditivos, los costes de las transiciones futuras dependen del estado actual. Conserva el prefijo conocido más barato que termina en cada estado. El prefijo de Dm7 es 2; los de G7-grave y G7-agudo son 3 y 13. En el final exigido, compara 3 + 23 con 13 + 11.

Conservar el mejor prefijo **por estado** mantiene ambos estados de G7. Conservar únicamente el estado más barato de todos descarta el estado agudo y pierde el mejor final. La [tabla de GA en la versión de referencia](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L113) conserva hasta `k` recorridos para cada candidato actual antes de seleccionar los recorridos finales. Por tanto, fijar `k` en 1 no es lo mismo que conservar un único candidato actual en total.

### Ejercicio práctico 3

¿Qué prefijos de G7 sobreviven a un límite de 1 por estado? ¿Qué se pierde en este ejemplo con un límite de un único estado en total?

> **Respuesta:** Sobreviven ambos: el grave con 3 y el agudo con 13, un prefijo por estado. Un límite de un único estado en total conserva el grave y produce 26 en lugar del 24 disponible. Este ejemplo no demuestra que una política de poda concreta falle en una ejecución de GA.

## 4. Cambiar el destino y volver a calcular

Si el final pasa a ser el voicing reducido grave de Cmaj7 `[52,59]`, las últimas transiciones cuestan 1 desde G7-grave y 13 desde G7-agudo. Los totales completos pasan a ser 4 y 26. Los mismos candidatos favorecen ahora el recorrido grave. Un planificador de frases necesita conocer el destino y los estados permitidos para que «mejor» tenga un significado preciso.

La etapa real de generación de candidatos de GA [conserva como máximo 40 posiciones por paso tras evaluarlas](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L94). Buscar un recorrido dentro de un conjunto de candidatos conservados no demuestra un mínimo entre todas las digitaciones posibles. Del mismo modo, nuestro cálculo exhaustivo de dos recorridos está limitado por el conjunto de candidatos declarado.

### Ejercicio práctico 4

Calcula ambos totales para el nuevo final grave. ¿Qué supuesto ha cambiado y qué regla de coste sigue siendo la misma?

> **Respuesta:** El recorrido grave da 2 + 1 + 1 = 4; el agudo da 2 + 11 + 13 = 26. Ha cambiado el destino exigido. La regla del desplazamiento absoluto por voz etiquetada, conservando el registro, sigue siendo la misma. La recomendación anterior del recorrido agudo no debe reutilizarse sin comprobar este nuevo final.

## 5. Informar del objetivo realmente medido

La suma interna del solucionador en la versión de referencia incluye términos de transición, coste físico estático, estilo, inercia de posición y ML. Su [método separado de presentación de soluciones](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L23) informa de `TotalPhysicalCost` sumando las salidas del método de transición a lo largo del recorrido elegido. Ese informe no vuelve a calcular todos los términos de la suma interna de búsqueda. Se trata de una inspección del código fuente, no de una ejecución numérica observada del solucionador.

Entrega las matrices, las etiquetas de las voces, el final, la regla de coste de las transiciones, ambos recorridos completos y el alcance de la comparación. Utiliza el [material para el alumno](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/learner-task.md) para registrar una respuesta antes de abrir su rúbrica separada. Estos cálculos no aportan ningún resultado de participantes ni de pruebas al instrumento.

### Ejercicio práctico 5

Un agente llama a 24 «el coste físico total medido por GA». Reformula la afirmación para ajustarla a las pruebas disponibles.

> **Respuesta:** «En el conjunto de datos construido con dos recorridos, 24 es la suma mínima del desplazamiento absoluto con registro conservado para el final agudo exigido». Aquí no se ejecutaron ni el solucionador de GA ni su informe de coste formateado; no se midió la comodidad física ni el coste de una digitación real.
