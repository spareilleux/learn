---
title: Prever margen para ataques correlacionados
description: Prever margen para ataques correlacionados — Ingeniería de audio
sidebar:
  label: AUD-014 · Prever margen para ataques correlacionados
  order: 14
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/es/aud-014-budget-headroom-for-correlated-plucks.es.md
---

:::note[Streeling University]
**AUD-014** · Prever margen para ataques correlacionados · intermedio · 55 minutos

Generado por el departamento *Ingeniería de audio* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/es/aud-014-budget-headroom-for-correlated-plucks.es.md) · [Mi diario](../../journal/)

Requisitos previos: [AUD-010](../../audio-engineering/aud-010-preserve-channels-before-downmixing/)
:::

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Un guitarrista puede pedir a GA un acorde cuyas voces suenen juntas. Las muestras válidas por separado no garantizan que la suma quede dentro del rango normalizado. El atajo peligroso estima el margen como si las voces fueran ruido independiente. Los ataques comunes, una excitación copiada o un unísono pueden alinearse. Esta lección usa búferes pequeños con signo para inspeccionar cada suma y distinguir un fallo interno de mezcla del recorte final.

## Leer la evidencia conservada

Leer el control de muestras normalizadas y la conversión WAV entera del programa conservado. Su existencia indica qué frontera se comprueba, sin demostrar que las voces internas nunca la excedieron. OpenStax explica la superposición como suma de desplazamientos, con refuerzo o cancelación según la fase. Nuestros arreglos aplican suma lineal como modelo construido, sin medir fases de guitarra.

[Requisito previo](../../audio-engineering/aud-010-preserve-channels-before-downmixing/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquete construido fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://openstax.org/books/university-physics-volume-1/pages/16-5-interference-of-waves)

### Ejercicio 1

Ambos búferes son `[0.8,-0.8,0.4]`, cada uno con pico `0.8`. Sumar índices correspondientes da `[1.6,-1.6,0.8]`. Los signos opuestos dentro de una onda no ayudan cuando la segunda fuente repite los mismos signos en los mismos instantes. El pico absoluto incluye también las excursiones negativas.

¿Cuáles son la suma bruta y su pico?

<details><summary>Respuesta 1</summary>

La suma es `[1.6,-1.6,0.8]`, con pico absoluto `1.6`. Cada fuente respetaba el límite, pero la suma correlacionada supera `1`.

</details>

### Ejercicio 2

Aplicar la ganancia declarada `0.5` a la suma antes del límite final. El resultado vuelve a `[0.8,-0.8,0.4]`, con pico `0.8`. Se intercambia amplitud por margen. La operación no recupera voces independientes de su suma ni debe describirse como igualación automática de sonoridad.

¿Qué ganancia se usa y qué búfer llega a la salida?

<details><summary>Respuesta 2</summary>

La ganancia `0.5` da `[0.8,-0.8,0.4]` y pico `0.8`. Es una preparación explícita, no una prueba de sonoridad percibida equivalente.

</details>

### Ejercicio 3

Invertir ahora el orden. Recortar la suma a `[-1,1]` produce `[1,-1,0.8]`. Multiplicarla después por `0.5` daría `[0.5,-0.5,0.4]`, diferente de la mezcla sin recorte. Reducir después la ganancia no reconstruye los extremos aplanados. Conservar una medición interna al diagnosticar esta frontera.

¿Por qué recortar y después reducir la ganancia es otra transformación?

<details><summary>Respuesta 3</summary>

El arreglo recortado es `[1,-1,0.8]`, que después queda en `[0.5,-0.5,0.4]`. Los extremos originales se perdieron; un pico final pequeño no demuestra ausencia de distorsión interna.

</details>

### Ejercicio 4

Para el control negativo, sustituir el segundo búfer por `[-0.8,0.8,-0.4]` manteniendo ganancia `0.5`. Tanto la suma bruta como la reducida son `[0,0,0]`. Ninguna fuente es silenciosa. La relación de fase forma parte de las entradas, y justificar una ganancia solo con este caso de cancelación sería frágil.

¿Qué demuestra el control sobre estimaciones universales de margen?

<details><summary>Respuesta 4</summary>

El pico es `0` pese a entradas no nulas. Cancelación y refuerzo correlacionado producen picos distintos; ningún ejemplo aislado ofrece una estimación independiente de las fuentes.

</details>

### Ejercicio 5

Una prueba práctica de acordes debe incluir ataques alineados, unísonos y señales opuestas antes de afirmar un margen general. Mantener visibles suma bruta, posición de ganancia y regla de recorte. Un limitador añade otra transformación no lineal que requiere evidencia propia. Los arreglos finitos no establecen preferencias auditivas.

¿Qué observación refutaría que todos los estados intermedios respetaron el rango?

<details><summary>Respuesta 5</summary>

Una muestra conservada antes del recorte con magnitud superior a `1` lo refutaría. Un WAV final válido no basta, porque el recorte puede ocultar la excursión.

</details>

## Tarea con consulta de fuentes

Redactar una nota de margen para un renderizado Wasm polifónico propuesto. Calcular manualmente la suma, la ganancia anterior al recorte y el control de cancelación. Localizar los controles del programa e identificar la frontera interna no observada. Proponer una medición que distinga atenuación limpia de señal recortada y luego atenuada, dejando pendientes la calidad auditiva y el comportamiento en producción.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
