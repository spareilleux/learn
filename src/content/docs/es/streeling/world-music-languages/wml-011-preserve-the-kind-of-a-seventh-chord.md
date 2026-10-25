---
title: Conservar el tipo de un acorde de séptima
description: Conservar el tipo de un acorde de séptima — Músicas y lenguas del mundo
sidebar:
  label: WML-011 · Conservar el tipo de un acorde de séptima
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/es/wml-011-preserve-the-kind-of-a-seventh-chord.es.md
---

:::note[Streeling University]
**WML-011** · Conservar el tipo de un acorde de séptima · intermedio · 55 minutos

Generado por el departamento *Músicas y lenguas del mundo* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/es/wml-011-preserve-the-kind-of-a-seventh-chord.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-005](../../world-music-languages/wml-005-declare-note-name-conventions/)
:::

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Traducir un símbolo requiere más que mantener la fundamental. Una tríada mayor admite séptima menor o mayor; un sufijo pequeño cambia alturas. Normalizar toda etiqueta que contenga mayor hacia la misma familia puede alterar silenciosamente la armonía. Separamos convención de fundamental, tipo y símbolo original antes de proponer una representación portable para GA.

## Leer la evidencia conservada

Leer los candidatos conservados de do mayor y el que incluye una clase de séptima adicional. Ilustran que aceptación específica y coincidencia amplia son diferentes. MusicXML kind-value distingue dominant, minor-seventh y major-seventh por tríada y séptima. Solo usamos ese subconjunto; no se ejecutó un analizador ni se afirma una abreviatura universal entre músicos.

[Requisito previo](../../world-music-languages/wml-005-declare-note-name-conventions/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Paquete construido fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/data-types/kind-value/)

### Ejercicio 1

Usar raíz `0` y diccionario construido `dominant=[0,4,7,10]`, `minor-seventh=[0,3,7,10]`, `major-seventh=[0,4,7,11]`. Los desplazamientos son semitonos desde la fundamental en el modelo temperado. Conservar visible el diccionario: séptima sola no identifica tercera ni tamaño de la séptima.

¿Qué desplazamientos definen el tipo dominante?

<details><summary>Respuesta 1</summary>

Son `[0,4,7,10]`, con tercera mayor de desplazamiento `4`, séptima menor de `10`, fundamental y quinta.

</details>

### Ejercicio 2

El caso principal elige `dominant`. Sumar la raíz a cada desplazamiento módulo `12` y ordenar produce `[0,4,7,10]`. Determina familia, no bajo, registro, duplicaciones o digitación. El guitarrista todavía necesita voicing e instrucción física para tocarla.

¿Qué resultado está justificado y qué falta?

<details><summary>Respuesta 2</summary>

La familia justificada es `[0,4,7,10]`. Notas absolutas, bajo, distribución de cuerdas y ejecución física siguen sin especificar.

</details>

### Ejercicio 3

El tipo `minor-seventh` cambia la tercera a `3` y mantiene séptima `10`; `major-seventh` mantiene tercera `4` y cambia séptima a `11`. El adjetivo puede referirse a componentes distintos según el tipo declarado. Explicar ambas evita exigir inferencias desde una abreviatura ambigua.

¿Por qué separar calidad de tríada y de séptima?

<details><summary>Respuesta 3</summary>

Minor-seventh tiene `[0,3,7,10]` y major-seventh `[0,4,7,11]`. Tercera y séptima cambian independientemente en el diccionario.

</details>

### Ejercicio 4

El control negativo cambia solo `dominant` a `major-seventh`. Produce `[0,4,7,11]`, conservando raíz y tríada mayor y elevando la séptima un semitono. Una auditoría que mire solo fundamental o existencia de séptima perdería el miembro cambiado.

¿Qué debe detectar la auditoría?

<details><summary>Respuesta 4</summary>

Debe detectar séptima `11` en lugar de `10`, con tercera `4` igual. La familia cambia pese a raíz y tríada compartidas.

</details>

### Ejercicio 5

Un intercambio multilingüe puede conservar identificador explícito, símbolo original y convención. Es un registro propuesto, no un esquema GA aprobado. Si un sufijo no está soportado, dejar su interpretación sin resolver en vez de elegir una convención por idioma o nacionalidad supuesta del autor.

¿Qué refutaría conservar el tipo al traducir?

<details><summary>Respuesta 5</summary>

Mapear principal y control a la misma familia pierde la distinción de séptima. Mantener la letra fundamental no basta para afirmar conservación armónica.

</details>

## Tarea con consulta de fuentes

Construir a mano diccionario y conjuntos de ambos casos. Inspeccionar claves conservadas y definiciones oficiales; escribir una explicación bilingüe que mantenga símbolo, convención y tipo. Declarar un refutador de una nota para una traducción con pérdidas. Dejar soporte real del analizador, uso idiomático y elección física a sus propias pruebas y revisiones.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
