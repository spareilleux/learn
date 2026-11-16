---
title: Auditar una clasificación de disposiciones de voces según su contrato de distancia
description: Auditar una clasificación de disposiciones de voces según su contrato de distancia — Música
sidebar:
  label: MUS-017 · Auditar una clasificación de disposiciones de voces según su contrato de distancia
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/music/es/mus-017-audit-voice-leading-rankings.es.md
---

:::note[Streeling University]
**MUS-017** · Auditar una clasificación de disposiciones de voces según su contrato de distancia · intermedio · 60 minutos

Generado por el departamento *Música* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/music/es/mus-017-audit-voice-leading-rankings.es.md) · [Mi diario](../../journal/)

Requisitos previos: [MUS-015](../../music/mus-015-choose-voice-leading-equivalences/), [MUS-016](../../music/mus-016-recover-voice-correspondence/)
:::

## Pregunta del proyecto y entregable

Un agente puede ordenar correctamente los candidatos según una puntuación que no cumple la relación musical pretendida. Construye una clasificación de dos candidatos, compárala con una referencia obtenida mediante enumeración independiente y redacta una decisión de alcance limitado. Este ejercicio trata de la [clase de distancia de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Atonal/VoiceLeadingSpace.cs) fijada. No ejecuta el índice de vecinos más cercanos ni la interfaz de usuario de GA.

Importa la distinción con [MUS-022](../../music/mus-022-grothendieck-deltas-icv-distance/): comparar vectores de contenido interválico responde a una pregunta distinta de emparejar alturas entre voces. Aquí el objetivo declarado permite cambios de octava y permutaciones del destino, y conserva el contenido de clases de altura para un emparejamiento de coste cero. Las equivalencias de transposición e inversión permanecen desactivadas.

## 1. Predecir la clasificación antes de ordenar

Usa la consulta `[60,63,65]` y dos destinos:

| Candidato | Alturas con su registro | Contenido de clases de altura |
|---|---|---|
| Same | 60, 65, 75 | 0, 5, 3 |
| Near | 60, 63, 66 | 0, 3, 6 |

Same contiene exactamente el multiconjunto de clases de altura de la consulta, por lo que una asignación exhaustiva puede costar 0. Near cambia la última clase en un semitono; su mejor asignación cuesta 1. Estas son predicciones derivadas del objetivo declarado, independientes de la búsqueda cíclica de las fuentes.

### Ejercicio práctico 1

Escribe una asignación de destino de coste cero para Same y una de coste 1 para Near.

> **Respuesta:** Same: empareja `[60,63,65]` con `[60,75,65]`, con costes circulares de 0, 0 y 0. Near: empareja `[60,63,65]` con `[60,63,66]`, con costes de 0, 0 y 1. Esto da cotas superiores; la enumeración exhaustiva del laboratorio conservado confirma los mínimos de estos casos.

## 2. Comparar dos rutas reales de cálculo

El [laboratorio independiente](https://github.com/spareilleux/learn/tree/codex/streeling-craft-transfer-20261022/code/streeling/voice-leading) compila las fuentes de GA sin cambios junto con un adaptador de anotaciones utilizado solo para compilar. También enumera de forma independiente todas las permutaciones indexadas de estos arrays pequeños. Los [resultados conservados](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/native-results.json) dan:

| Candidato | Coste nativo | Coste exhaustivo |
|---|---:|---:|
| Same | 4 | 0 |
| Near | 1 | 1 |

Ordenar cada columna de forma ascendente invierte el orden de los dos candidatos. El cálculo nativo sitúa Near antes que Same; la referencia sitúa Same antes que Near. Esta es una clasificación local construida. Un consumidor que normalice sus entradas de otro modo podría no encontrarse con este caso. Esta tabla por sí sola no permite inferir ningún comportamiento del pipeline de búsqueda original.

### Ejercicio práctico 2

¿Sustituir el algoritmo de ordenación corregiría este desacuerdo?

> **Respuesta:** No. Ambas columnas están ordenadas correctamente según sus valores. El desacuerdo procede del coste calculado para Same bajo el contrato de equivalencia pretendido. Investiga la representación y la búsqueda de asignaciones antes de cambiar la ordenación de la clasificación.

## 3. Probar un cambio de representación sin llamarlo corrección

Reducir esta consulta y Same módulo 12 da `[0,3,5]` y `[0,5,3]`. La clase nativa sin cambios devuelve entonces 0. Esta transformación elimina el obstáculo concreto debido al orden de las alturas con su registro en el ejemplo. No ha corregido el método de producción ni demostrado un teorema sobre todas las entradas.

También descarta las octavas del registro. Si un consumidor necesita el registro de una melodía, conserva por separado las alturas originales. Si necesita una correspondencia real, conserva un testigo como en [MUS-016](../../music/mus-016-recover-voice-correspondence/). Un escalar normalizado no puede reconstruir la información descartada.

### Ejercicio práctico 3

¿Puede usarse el cero normalizado para concluir que el movimiento de la segunda voz identificada, teniendo en cuenta el registro, es 0?

> **Respuesta:** No. En el testigo declarado, esa voz pasa de 63 a 75 y se mueve 12 semitonos. El cero pertenece a la comparación con equivalencia de octava. Conserva las alturas originales con su registro si ese movimiento importa para la tarea.

## 4. Exigir una referencia independiente para detectar errores

El laboratorio fija sus resultados esperados antes de la implementación. El caso de prueba original conservado de siete voces cuesta 8 en ambas rutas; la referencia exhaustiva recorre 5,040 permutaciones indexadas. Reproducir solo este caso de prueba no detectaría el contraejemplo más pequeño que tiene en cuenta el registro. Un ejemplo que supera las comprobaciones no puede establecer la afirmación general de equivalencia.

El control negativo del laboratorio sustituyó deliberadamente el oráculo por el resultado nativo en una copia temporal. Fue rechazado por `oracle_zero_known_case`: esperado 0, obtenido 4. Esto confirma que la comprobación conservada puede detectar esa pérdida concreta de independencia. No mide una cobertura general de mutaciones ni el éxito de los estudiantes. El [registro del control](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/negative-controls.json) conserva esos límites.

Repite la ejecución con [Node.js](https://nodejs.org/api/cli.html) y [.NET](https://learn.microsoft.com/dotnet/core/tools/dotnet-build) ya instalados, usando la orden de MUS-015. Examina tanto el veredicto de caracterización como el veredicto separado sobre la equivalencia original. Windows es la única plataforma evaluada.

### Ejercicio práctico 4

¿Por qué usar el mínimo cíclico nativo como «respuesta exhaustiva esperada» debilitaría el ejercicio?

> **Respuesta:** Ambas rutas heredarían la misma restricción de búsqueda. Su coincidencia podría entonces ocultar la permutación de coste cero que falta. El cálculo manual independiente y la enumeración exhaustiva aportan pruebas que el propio resultado de las fuentes no puede proporcionar sobre sí mismo.

## 5. Convertir el experimento en una decisión del agente

Redacta un traspaso con la revisión de las fuentes, los arrays de los candidatos, el contrato de equivalencia, ambos costes, ambos órdenes y la observación limitada sobre la normalización. Para esta comparación, no aceptes que la puntuación nativa cumple la equivalencia pretendida. Una corrección en producción necesita su propia implementación y pruebas de regresión; el laboratorio no ha aportado esa corrección. El [dossier del estudiante](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/learner-task.md) distingue la comprobación factual con ayuda de las fuentes, la revisión humana y una futura prueba instrumental.

### Ejercicio práctico 5

Un agente propone normalizar automáticamente la entrada de todos los consumidores. ¿Qué debe establecer primero?

> **Respuesta:** Identifica el contrato de comparación de cada consumidor y si deben conservarse la altura con su registro, la identidad de la voz o la asignación a cuerdas. Después, verifica el comportamiento propuesto frente a esos contratos con casos independientes. Este ejemplo respalda un contraejemplo concreto y una entrada transformada concreta; no autoriza una política universal de normalización.
