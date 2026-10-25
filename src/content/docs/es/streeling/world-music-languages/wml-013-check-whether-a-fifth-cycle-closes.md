---
title: Comprobar si cierra un ciclo de quintas
description: Comprobar si cierra un ciclo de quintas — Músicas y lenguas del mundo
sidebar:
  label: WML-013 · Comprobar si cierra un ciclo de quintas
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/es/wml-013-check-whether-a-fifth-cycle-closes.es.md
---

:::note[Streeling University]
**WML-013** · Comprobar si cierra un ciclo de quintas · intermedio · 55 minutos

Generado por el departamento *Músicas y lenguas del mundo* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/es/wml-013-check-whether-a-fifth-cycle-closes.es.md) · [Mi diario](../../journal/)

Requisitos previos: [WML-004](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/)
:::

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Un círculo de nombres puede volver a su etiqueta inicial mientras una secuencia de razones no coincide con la octava correspondiente. Una herramienta que guarda solo la etiqueta puede ocultar el residuo. Componemos una quinta declarada y comprobamos cierre contra un número de octavas. La comparación individual en cents previa se amplía al ciclo, sin afirmar qué temperamento es culturalmente correcto o musicalmente preferible.

## Leer la evidencia conservada

Leer el ejemplo de razones y la advertencia de proyección entera del paquete de entonación. NIST aporta el cent y UNSW distingue relaciones armónicas y aproximaciones temperadas. Deducimos el ciclo nosotros. Las cifras son valores matemáticos construidos, no una afinación realizada, una salida de detector ni evidencia de realización en GA.

[Requisito previo](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/)

[Artefacto conservado del proyecto](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Paquete construido fijo](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

[Lectura primaria](https://www.phys.unsw.edu.au/jw/strings.html)

### Ejercicio 1

Cada quinta multiplica frecuencia por `3/2`; componer `12` y comparar con `7` octavas de factor `2`. En clases, una quinta avanza `7` pasos módulo `12` y vuelve a la etiqueta. Ese cierre discreto no prueba igualdad de multiplicadores porque las representaciones conservan información distinta.

¿Volver a la etiqueta prueba cierre de razones?

<details><summary>Respuesta 1</summary>

No. Las etiquetas se calculan módulo `12`; las razones comparan `(3/2)^12` con `2^7`. Necesitan comprobaciones separadas.

</details>

### Ejercicio 2

Dividir el multiplicador de quintas entre el de octavas. El residuo `(3/2)^12/2^7=531441/524288` es mayor que `1`. Conservar la fracción exacta antes de redondear: pocos decimales pueden ocultar la diferencia. La fracción describe la construcción pura declarada, no la afinación de todo instrumento práctico.

¿Qué razón residual exacta queda?

<details><summary>Respuesta 2</summary>

Queda `531441/524288`; el ciclo no cierra exactamente. La cadena termina por encima de la referencia equivalente en octavas.

</details>

### Ejercicio 3

Convertir con `1200*log2(531441/524288)`, aproximadamente `23.460010384649` cents. El signo es positivo porque numerador supera denominador. El cálculo mide diferencia entre extremos construidos en escala de razones, sin establecer audibilidad ni preferencia musical en un contexto concreto.

Dar el residuo en cents y explicar el signo.

<details><summary>Respuesta 3</summary>

Es aproximadamente `23.460010384649` cents, positivo porque las quintas terminan por encima de las octavas. No se midió ningún umbral auditivo.

</details>

### Ejercicio 4

El control negativo cambia la razón de quinta a `2^(7/12)` conservando cuentas. Elevarla a `12` produce simbólicamente `2^7`, dando razón residual `1` y `0` cents. Una calculadora flotante puede dejar un residuo diminuto; distinguir aproximación numérica y afirmación exacta en lugar de inventar otra discrepancia.

¿Qué cierra en el control?

<details><summary>Respuesta 4</summary>

El ciclo de razones cierra exactamente según la definición simbólica: razón `1` y `0` cents. La quinta es distinta de `3/2`, por lo que no elimina el caso principal.

</details>

### Ejercicio 5

Un intercambio fiel debe guardar definición, referencia, número de composiciones y aproximación. Una máscara de clases sirve para buscar, pero no reconstruye el ciclo. Antes de proponer un DSL o agente, mostrar cómo conserva el residuo manual y distingue el control temperado.

¿Qué refutaría conservar esta distinción en un registro solo de clases?

<details><summary>Respuesta 5</summary>

Mapear ambas construcciones al mismo registro sin razón ni cents impide recuperar el residuo previsto. Los ejemplos emparejados demuestran esa pérdida.

</details>

## Tarea con consulta de fuentes

Calcular manualmente fracción y cents y repetir el control temperado simbólico. Inspeccionar la proyección conservada y explicar por qué las etiquetas no recuperan razones perdidas. Redactar una nota consultiva con referencia, definición y refutador de cierre. Dejar realización instrumental, interpretación cultural, preferencia y actuación real para evidencia separada.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
