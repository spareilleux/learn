---
title: Conservar la duración del grupo irregular como racional
description: Conservar la duración del grupo irregular como racional — Musicología
sidebar:
  label: MCL-013 · Conservar la duración del grupo irregular como racional
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/musicology/es/mcl-013-keep-tuplet-duration-as-a-rational.es.md
---

:::note[Streeling University]
**MCL-013** · Conservar la duración del grupo irregular como racional · intermedio · 55 minutos

Generado por el departamento *Musicología* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/musicology/es/mcl-013-keep-tuplet-duration-as-a-rational.es.md) · [Mi diario](../../journal/)

Requisitos previos: [MCL-006](../../musicology/mcl-006-preserve-meter-grouping-and-tempo-units/)
:::

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Un ejercicio puede tener el número correcto de notas escritas y terminar mal si se invierte la razón del grupo irregular. La agrupación métrica no resuelve esa razón y un corchete puede no contener todos los campos. Construimos una cronología racional antes de pasar a segundos. Se añaden duraciones locales a las unidades previas para ofrecer una base manual al intercambio de notación y programación.

## Leer la evidencia conservada

Leer las coordenadas absolutas del paquete temporal: son explícitas, no deducidas de una etiqueta decorativa. MusicXML time-modification distingue cuentas actual y normal y su efecto sonoro acumulado. La notación anidada exige información adicional. El ejemplo se limita a un grupo sin puntillos ni anidamiento y no afirma un importador o exportador completo.

[Requisito previo](../../musicology/mcl-006-preserve-meter-grouping-and-tempo-units/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Paquete construido fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/time-modification/)

### Ejercicio 1

Fijar `480` ticks por negra y duración base `1/2` negra. La nota no modificada dura `240` ticks. Separar tipo base y modificador evita tratar una corchea como duración final en cualquier contexto. La referencia es la negra, no una palabra pulso sin unidad definida.

¿Cuál es la duración base en ticks?

<details><summary>Respuesta 1</summary>

Es `240` ticks según `480*(1/2)`. Corresponde a la duración sin aplicar todavía la razón declarada.

</details>

### Ejercicio 2

Usar cuenta actual `3` y normal `2`: las notas escritas ocupan el tiempo de la cuenta normal. La duración por nota es `Q*(base_num/base_den)*(normal/actual)`, dando `160` ticks. La razón multiplica tiempo; usar actual/normal alargaría las notas en vez de ajustar el grupo al espacio previsto.

¿Qué duración recibe cada nota modificada?

<details><summary>Respuesta 2</summary>

Cada nota recibe `160` ticks. El multiplicador temporal es `2/3`, aplicado a los `240` ticks originales.

</details>

### Ejercicio 3

Las `3` notas suman `480` ticks, o `1` negra. Sus comienzos relativos son `[0,160,320]` ticks y terminan en `480`. La aritmética exacta muestra el cierre. Con otras resoluciones puede haber resultados racionales no enteros; redondear cada nota por separado puede desplazar el final y necesita una política propia.

Dar comienzos y extremo final del grupo.

<details><summary>Respuesta 3</summary>

Los comienzos son `[0,160,320]` ticks y el final `480`. El grupo llena exactamente `1` negra bajo esta resolución.

</details>

### Ejercicio 4

El control negativo intercambia actual y normal, conservando `3` notas y la duración base. Cada nota queda en `360` ticks y el total en `1080`, o `2.25` negras. Comprobar solo las notas escritas aceptaría esta interpretación distinta pese al gran cambio de final.

¿Qué produce el control con campos invertidos?

<details><summary>Respuesta 4</summary>

Produce `360` ticks por nota y `1080` totales, equivalentes a `2.25` negras. Los campos son entradas semánticas, no etiquetas intercambiables.

</details>

### Ejercicio 5

Un mapa de tempo convierte después estas coordenadas a segundos; no repara una duración irregular incorrecta. Guardar unidad base, cuentas actual/normal, puntillos si existen y soporte exacto antes de proyectar a ticks enteros. Un agente puede comparar la cronología con esta base racional sin tratar un corchete impreso como prueba de reproducción fiel.

¿Qué refutaría conservar la duración de este grupo?

<details><summary>Respuesta 5</summary>

Terminar en un valor distinto de `480` ticks para el caso principal contradice el modelo. Los `1080` ticks del control son un testigo de fallo si se presentan como resultado principal.

</details>

## Tarea con consulta de fuentes

Construir manualmente con fracciones ambas cronologías e inspeccionar coordenadas conservadas y definición oficial. Proponer un intercambio que guarde base y ambas cuentas, no solo el rótulo del grupo. Declarar un refutador de extremo final y cuándo haría falta redondear. Dejar pendientes importación real, ejecución musical y aceptación del aprendiz.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
