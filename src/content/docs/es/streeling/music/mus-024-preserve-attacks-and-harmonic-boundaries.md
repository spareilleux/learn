---
title: Preservar los ataques y los límites armónicos
description: Preservar los ataques y los límites armónicos — Música
sidebar:
  label: MUS-024 · Preservar los ataques y los límites armónicos
  order: 24
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/music/es/mus-024-preserve-attacks-and-harmonic-boundaries.es.md
---

:::note[Streeling University]
**MUS-024** · Preservar los ataques y los límites armónicos · intermedio · 60 minutos

Generado por el departamento *Música* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/music/es/mus-024-preserve-attacks-and-harmonic-boundaries.es.md) · [Mi diario](../../journal/)

Requisitos previos: [MUS-003](../../music/mus-003-functional-harmony/), [MUS-004](../../music/mus-004-rhythm-and-groove/)
:::

## Pregunta del proyecto y entrega

Un planificador de acordes recibe una secuencia de conjuntos de alturas. ¿Qué notas acaban de atacarse, cuáles siguen sonando y dónde ha cambiado la armonía? Reconstruye un registro de eventos y muestra qué no puede recuperarse de una transferencia que solo contiene alturas. Así se aplica el vocabulario de duraciones de MUS-004 a un límite concreto entre representaciones de GA.

El [solucionador de tablaturas de GA en la versión de referencia](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L52) acepta una secuencia de conjuntos de alturas. Los argumentos de ese método no contienen campos de inicio, duración ni ligadura de prolongación. Otros modelos de GA sí incluyen esa información: [ProgressionStep](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Theory/Harmony/Progressions/ProgressionStep.cs) tiene `DurationMs`, y, para [MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/duration/), su [modelo de nota](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L93) importado incluye campos de duración, voz y ligadura de prolongación. Esta lección examina esos tipos; no ejecuta una integración ni demuestra que todos los recorridos de GA pierdan la información temporal.

## 1. Distinguir los eventos de nota de las etiquetas de acorde

El [conjunto de datos construido](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/timed-events.json) utiliza posiciones temporales absolutas en pulsos de negra y C4 = 60. Un evento está activo desde su inicio incluido hasta su final excluido. Su identificador mantiene la continuidad de una misma nota en las instantáneas posteriores.

| Evento | Altura | Inicio | Final |
|---|---:|---:|---:|
| G en el bajo | 43 | 0 | 2 |
| B compartido | 59 | 0 | 4 |
| D interior | 62 | 0 | 2 |
| F interior | 65 | 0 | 2 |
| E anticipado | 76 | 1.5 | 4 |
| C en el bajo | 48 | 2 | 4 |
| E interior | 64 | 2 | 4 |
| G interior | 67 | 2 | 4 |

Las anotaciones armónicas se definen por separado: G7 de 0 a 2 y Cmaj7 de 2 a 4. Llamar a E5 en 1.5 una anticipación de la tercera de la tónica es una interpretación del autor. Las mismas notas en un instante dado podrían sugerir otra lectura armónica; la tabla por sí sola no demuestra la etiqueta.

### Ejercicio práctico 1

Enumera las alturas que suenan durante los tres intervalos que comienzan en 0, 1.5 y 2. ¿Cada nuevo inicio de nota exige una nueva etiqueta de acorde definida por el autor?

> **Respuesta:** Los conjuntos son `[43,59,62,65]`, `[43,59,62,65,76]` y `[48,59,64,67,76]`, con 4, 5 y 5 notas. No. El inicio en 1.5 cambia el conjunto de notas que suenan mientras el intervalo de G7 definido por el autor continúa hasta 2. La segmentación armónica es una interpretación adicional.

## 2. Examinar el cambio en el límite

En el pulso 2, las alturas 43, 62 y 65 dejan de sonar. Las alturas 48, 64 y 67 empiezan. Los eventos B3 de altura 59 y E5 de altura 76 siguen sonando; no son nuevos ataques en ese límite. Por tanto, el conjunto de ataques contiene una tríada de C mayor, mientras que el conjunto completo de notas que suenan contiene el B de Cmaj7 y un E duplicado.

Los intervalos semiabiertos hacen explícito el límite: los eventos anteriores que terminan en 2 están ausentes en 2, y los nuevos eventos que comienzan en 2 están presentes. Todos los eventos están ausentes en 4. Esta es la convención matemática del conjunto de datos, no una medición del comportamiento de liberación de notas de un motor de reproducción.

### Ejercicio práctico 2

En el pulso 2, escribe tres listas separadas: alturas liberadas, nuevos ataques y alturas sostenidas. ¿Por qué un analizador de acordes que solo considera ataques omitiría una nota del acorde que sigue sonando?

> **Respuesta:** Liberadas: 43, 62, 65. Ataques: 48, 64, 67. Sostenidas: 59, 76. B3 = 59 es la séptima mayor sostenida del Cmaj7 anotado por el autor. Un conjunto limitado a los ataques la omite aunque sigue activa. Ni la omisión ni un nombre de acorde inferido de ella se observaron en una ejecución real de GA.

## 3. No convertir cada instantánea en un nuevo ataque

El conjunto de datos contiene 8 eventos de nota. Una conversión deliberadamente incorrecta que volviera a atacar cada altura de cada instantánea de notas que suenan crearía 4 + 5 + 5 = 14 ataques. El B compartido se atacaría 3 veces en lugar del único ataque definido por el autor. Es un contraejemplo calculado de esa regla de conversión, no una salida capturada de GA ni de un motor de reproducción.

Una instantánea responde a «¿qué está sonando ahora?». Un registro de ataques responde a «¿qué ha comenzado ahora?». Una anotación armónica responde a «¿qué acorde oye el autor en este intervalo?». Mantén estas preguntas separadas incluso cuando sus límites coincidan en una partitura sencilla.

### Ejercicio práctico 3

¿Cuántos ataques adicionales añade la conversión hipotética de instantáneas a ataques? ¿Puede la mera pertenencia de una altura a esos conjuntos identificar el evento B sostenido original?

> **Respuesta:** Añade 14 − 8 = 6 ataques. No. La repetición de la altura 59 en instantáneas adyacentes puede representar un único evento sostenido o ataques separados. Conserva la identidad y los límites de los eventos para distinguirlos; los conjuntos de alturas por sí solos no bastan.

## 4. Declarar la unidad de tiempo antes de convertir

A 120 negras por minuto, un pulso de negra dura 500 milisegundos. El inicio en 1.5 corresponde a 750 milisegundos; el límite armónico en 2 corresponde a 1000 milisegundos; la frase termina en 2000 milisegundos. Cada uno de los dos pasos armónicos definidos por el autor dura 1000 milisegundos a este tempo.

El campo `DurationMs` de GA es explícitamente una duración en milisegundos, con un valor predeterminado de 1000. Ese valor predeterminado no determina un tempo. En [MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/duration/), los valores de duración utilizan unidades de división. No son milisegundos de forma predeterminada. Convertir pulsos de negra a unidades de división requiere conocer el [número de divisiones por negra](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/divisions/); convertir duraciones a milisegundos requiere además el tempo. Valores numéricos iguales pueden ser correctos cuando las escalas declaradas coinciden. Comprueba esa coincidencia en lugar de darla por supuesta.

### Ejercicio práctico 4

Convierte el inicio 1.5 y la duración 2 a milisegundos al tempo declarado. ¿Copiar el número 2 directamente en `DurationMs` preservaría la duración armónica prevista?

> **Respuesta:** Se convierten en 750 y 1000 milisegundos. No: un valor de 2 en `DurationMs` significa 2 milisegundos, no 2 pulsos de negra. El conjunto de datos declara su unidad de tiempo y su tempo; no se ejecutó ningún importador ni exportador.

## 5. Preservar la continuidad entre representaciones

El [elemento tie](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/tie/) de MusicXML describe una ligadura de prolongación sonora; su elemento separado tied describe la notación. Dividir una duración escrita no tiene por qué crear un nuevo ataque. Un modelo que solo conserva alturas no puede preservar por sí solo esa distinción. Mantén una correspondencia con los eventos originales al enviar instantáneas de alturas seleccionadas a un planificador.

Entrega los identificadores de eventos, las unidades de inicio y final, las listas de notas sostenidas y ataques, y la anotación armónica separada. El [material preparado para el alumno](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/learner-task.md) comprueba el razonamiento sin fingir que se ha realizado una escucha o una conversión de ida y vuelta mediante importación y exportación.

### Ejercicio práctico 5

Un agente conserva las tres instantáneas de alturas y promete una articulación exacta al exportar. ¿Qué pruebas y datos faltan?

> **Respuesta:** Esa transferencia limitada a las alturas carece de las identidades originales de los eventos, los límites de ataque y liberación, el contexto de unidad y tempo, y la información de ligaduras y articulación. Una exportación exacta también requeriría una conversión realmente probada. Los tipos del código fuente y este registro de eventos construido no demuestran que exista tal implementación.
