---
title: Contar notas legato por separado de los ataques de púa
description: Contar notas legato por separado de los ataques de púa — Estudios de guitarra
sidebar:
  label: GTR-014 · Contar notas legato por separado de los ataques de púa
  order: 14
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/es/gtr-014-count-legato-notes-separately-from-pick-attacks.es.md
---

:::note[Streeling University]
**GTR-014** · Contar notas legato por separado de los ataques de púa · intermedio · 55 minutos

Generado por el departamento *Estudios de guitarra* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/es/gtr-014-count-legato-notes-separately-from-pick-attacks.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GTR-010](../../guitar-studies/gtr-010-separate-muting-from-releasing-a-fretted-note/)
:::

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Una frase puede cambiar de altura sin otro golpe de púa. Contar cada altura nueva como ataque puede indicar una técnica incorrecta aunque la lista de notas sea correcta. Distinguimos eventos musicales de la acción que los excita o continúa. El registro ayuda a GA a explicar la frase antes de afirmar que un motor reproduce su articulación. Amplía la distinción entre soltar y apagar del requisito previo hacia cambios de altura.

## Leer la evidencia conservada

El paquete conservado de ocupación sigue notas sostenidas y excluye bends y rearticulación. Esa exclusión evita heredar afirmaciones de articulación de una tabla válida. MusicXML dispone de un elemento técnico para parejas de hammer-on separado de una ligadura amplia. Nuestro plan construido conserva acciones explícitas sin afirmar importación MusicXML ni funciones del motor de producción.

[Requisito previo](../../guitar-studies/gtr-010-separate-muting-from-releasing-a-fretted-note/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Paquete construido fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/hammer-on/)

### Ejercicio 1

Usar eventos ordenados `pick:64`, `hammer:67`, `pull:64`, `pick:69`. Los números describen destinos sonoros bajo la convención discreta declarada. Cada fila es un evento nuevo, incluido el retorno a una altura anterior. Contar alturas únicas respondería otra pregunta y eliminaría recurrencias.

¿Cuántos eventos hay y qué secuencia especifican?

<details><summary>Respuesta 1</summary>

Hay `4` eventos con alturas `[64,67,64,69]`. La segunda aparición de `64` sigue siendo un evento distinto.

</details>

### Ejercicio 2

Solo las filas de acción `pick` cuentan como ataques de púa. Hammer y pull son acciones distintas de mano izquierda. Pueden aportar o redistribuir energía, así que carecer de púa no significa carecer de transitorio. El modelo cuenta instrucciones, no picos de un detector de ataques acústicos.

¿Cuántos ataques de púa y cambios legato contiene el plan?

<details><summary>Respuesta 2</summary>

Contiene `2` ataques de púa y `2` cambios legato. No predice fuerza del transitorio, igualdad de volumen ni éxito del intérprete.

</details>

### Ejercicio 3

Una exportación solo de alturas conserva `[64,67,64,69]` pero elimina cómo se realizaron los cambios centrales. El receptor no puede deducir de forma única la articulación original. Añadir un agente después de esa proyección no recupera información sin otra fuente; una sugerencia plausible debe etiquetarse como propuesta nueva.

¿Puede la secuencia reconstruir el registro de acciones original?

<details><summary>Respuesta 3</summary>

No. Varios registros corresponden a `[64,67,64,69]`. Si se necesita el patrón de púa construido, conservar acción y procedencia.

</details>

### Ejercicio 4

El control negativo sustituye `hammer:67` por `pick:67` sin cambiar alturas. Ahora hay `3` ataques de púa y `1` cambio legato, manteniendo `4` eventos. Un test que compare solo listas de alturas considerará iguales los planes y perderá precisamente la diferencia técnica buscada.

¿Qué cuentas cambian en el control?

<details><summary>Respuesta 4</summary>

Los ataques pasan a `3` y los cambios legato a `1`; siguen `4` eventos con `[64,67,64,69]`. Alturas iguales no implican articulación igual.

</details>

### Ejercicio 5

Una interpretación real también requiere cuerda, tiempos, geometría y continuidad sonora. El paquete de ocupación responde sobre conflictos de cuerda bajo sus hipótesis; nuestro registro responde sobre mecanismo de ataque. Combinarlos requiere verificar identidades y fronteras de evento, sin tratar ningún modelo parcial como interpretación completa y ejecutable.

¿Qué refutaría que una exportación conserva la técnica?

<details><summary>Respuesta 5</summary>

Dar el mismo registro de acciones o número de ataques a los casos principal y de control pierde la distinción requerida. No hace falta escucha para detectar esa pérdida de representación.

</details>

## Tarea con consulta de fuentes

Escribir ambos registros a mano antes de abrir respuestas. Compararlos con las exclusiones de ocupación y la definición técnica MusicXML. Proponer un intercambio de frase que conserve identidad, altura y acción sin inventar soporte del motor. Indicar cómo rechazar una exportación que mantiene notas pero pierde articulación. Dejar sin evaluar facilidad física, transitorios y actuación real del aprendiz.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
