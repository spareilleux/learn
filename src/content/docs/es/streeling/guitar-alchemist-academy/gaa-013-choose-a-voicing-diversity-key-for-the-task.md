---
title: Elegir una clave de diversidad de voicings según la tarea
description: Elegir una clave de diversidad de voicings según la tarea — Guitar Alchemist Academy
sidebar:
  label: GAA-013 · Elegir una clave de diversidad de voicings según la tarea
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-alchemist-academy/es/gaa-013-choose-a-voicing-diversity-key-for-the-task.es.md
---

:::note[Streeling University]
**GAA-013** · Elegir una clave de diversidad de voicings según la tarea · intermedio · 55 minutos

Generado por el departamento *Guitar Alchemist Academy* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-alchemist-academy/es/gaa-013-choose-a-voicing-diversity-key-for-the-task.es.md) · [Mi diario](../../journal/)

Requisitos previos: [GAA-004](../../guitar-alchemist-academy/gaa-004-choose-a-useful-voicing/)
:::

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Una respuesta GA puede listar varias formas y un resumen llamarlas duplicadas. Ambas descripciones pueden ser correctas con equivalencias distintas. Buscar otros registros necesita otra vista que contar familias de clases de altura. Explicitamos la clave antes de comprimir resultados con un agente. La lección añade una decisión de representación a la selección previa, sin modificar embeddings, búsqueda ni esquema musical.

## Leer la evidencia conservada

Leer los candidatos conservados: varias formas comparten familia pero difieren en notas exactas y aceptación de forma específica. Esa fuente aporta el problema del proyecto, no las listas siguientes, que son construidas. No proceden de una búsqueda en vivo, y agrupar por clases no se presenta como política de implementación de un servicio.

[Requisito previo](../../guitar-alchemist-academy/gaa-004-choose-a-useful-voicing/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Paquete construido fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

### Ejercicio 1

Usar `[[48,52,55,60],[48,55,60,64],[52,55,60,64],[48,52,55,60]]`, listas ascendentes. La clave de familia toma valores módulo `12`, elimina duplicados y ordena. Descarta registro, multiplicidad y posición del bajo deliberadamente. Solo sirve cuando la tarea pide esa familia proyectada.

¿Cuántos conjuntos de clases de altura distintos aparecen?

<details><summary>Respuesta 1</summary>

Hay `1`, con clave `[0,4,7]`. La igualdad no implica listas sonoras, bajos o digitaciones idénticos.

</details>

### Ejercicio 2

La clave de voicing absoluto conserva la lista ordenada completa. El último candidato repite el primero y los intermedios difieren. Quedan `3` voicings distintos. Un agente debe nombrar la clave junto a la cantidad, pues los mismos datos permiten varias cuentas.

¿Cuántos voicings absolutos diferentes quedan?

<details><summary>Respuesta 2</summary>

Quedan `3`. Solo se colapsa la repetición exacta inicial/final; registro y multiplicidad siguen formando parte de esta clave.

</details>

### Ejercicio 3

La clave de bajo toma la nota menor módulo `12`. Primero, segundo y último tienen clase `0`; el tercero tiene `4`. Hay `2` clases de bajo pese a una sola familia. Una tarea de inversión puede conservar esa información sin afirmar digitación física o continuidad de voces.

¿Qué conserva el bajo que pierde la familia?

<details><summary>Respuesta 3</summary>

Distingue las clases `0` y `4`, dando `2` clases. El conjunto `[0,4,7]` no identifica cuál suena más grave.

</details>

### Ejercicio 4

El control negativo cambia el tercer candidato a `[52,55,60,65]`, cuya familia es `[0,4,5,7]`. Ahora hay `2` conjuntos, mientras siguen `3` voicings y `2` clases de bajo. Mirar solo cuentas inalteradas perdería la nueva familia; conservar claves además de totales.

¿Qué resultado cambia con el control?

<details><summary>Respuesta 4</summary>

Las familias aumentan a `2`: `[[0,4,7],[0,4,5,7]]`. Siguen `3` voicings y `2` bajos. Una coordenada cambiada afecta de manera distinta a cada clave.

</details>

### Ejercicio 5

Para practicar se puede buscar inversión, posición cercana o timbre distinto. Ninguna se obtiene solo de contar familias abstractas. Mantener accesibles los candidatos después del resumen y explicar lo que elimina la clave. Una futura similitud puede contrastarse con esta base manual antes de adoptar otra abstracción.

¿Qué refutaría un resumen que dice conservar diversidad de registro?

<details><summary>Respuesta 5</summary>

Colapsar todos los candidatos principales en un registro sin distinciones de voicing pierde el registro solicitado. Una cuenta correcta de familias no salva esa afirmación más fuerte.

</details>

## Tarea con consulta de fuentes

Calcular a mano las tres claves por candidato y repetir tras el control. Inspeccionar las formas conservadas y comparar aceptación exacta y por familia. Redactar una respuesta GA para buscar bajos alternativos nombrando clave y límites. Declarar un refutador de proyección antes de recomendar deduplicación y dejar sin observar ejecución física, clasificación real y preferencias.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
