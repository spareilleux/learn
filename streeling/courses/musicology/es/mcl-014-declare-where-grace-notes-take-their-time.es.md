---
module_id: mcl-014-declare-where-grace-notes-take-their-time
department: musicology
course: "Declarar de dónde toman tiempo las notas de adorno"
level: intermediate
prerequisites: ["mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Declarar de dónde toman tiempo las notas de adorno

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Un adorno pequeño en la página también necesita una política de reproducción. Insertar su tiempo sin indicar de dónde procede puede desplazar eventos posteriores o acortar inesperadamente la nota principal. Comparamos dos asignaciones construidas en segundos. Se busca una política inspeccionable antes de programar, sin deducir práctica interpretativa de una barra o una cabeza pequeña.

## Leer la evidencia conservada

El paquete temporal guarda comienzos y finales absolutos de una frase construida, no una política universal de adornos. MusicXML grace distingue añadir tiempo de tomar un porcentaje de una nota vecina. Son posibilidades diferentes; nuestros ejemplos en segundos son explicativos, no una ejecución ni un atributo serializado directamente. El mapa de tempo previo no decide entre ellas.

[Requisito previo](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Paquete construido fijo](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/grace/)

### Ejercicio 1

El grupo comienza en `1 s`. La duración escrita principal es `0.5 s` y el presupuesto construido del adorno `0.1 s` para `2` notas. Dividir por igual da `0.05 s` por nota. La igualdad es una elección local, no una descripción de cómo todos los guitarristas articulan adornos.

¿Cuánto tiempo recibe cada nota de adorno?

<details><summary>Respuesta 1</summary>

Cada una recibe `0.05 s`, por repartir explícitamente `0.1 s` entre `2` notas.

</details>

### Ejercicio 2

La política principal es `steal_following`. Colocar el adorno al inicio y restar su tiempo de la principal. Esta comienza en `1.1 s` y dura `0.4 s`. Inicio tardío y duración menor son consecuencias intencionadas; ocultar cualquiera dificultaría revisar la programación.

Dar comienzo y duración de la nota principal.

<details><summary>Respuesta 2</summary>

Comienza en `1.1 s` y dura `0.4 s`. El adorno consume parte del tiempo escrito de la nota siguiente.

</details>

### Ejercicio 3

La frontera siguiente permanece en `1.5 s`. Adorno y principal suman `0.5 s`, la casilla escrita. Se conserva el soporte completo, no la principal aislada. La comprobación debe declarar qué conserva, porque pueden ser correctos a la vez una nota acortada y una frontera inalterada.

¿Qué duración se conserva en el caso principal?

<details><summary>Respuesta 3</summary>

La casilla completa conserva `0.5 s` y termina en `1.5 s`. La principal se acorta; afirmar que conserva su duración original sería falso.

</details>

### Ejercicio 4

El control negativo cambia a `add_time`. La principal sigue comenzando en `1.1 s`, pero mantiene `0.5 s`, desplazando la frontera a `1.6 s`. Las alturas podrían ser idénticas. Comprobar solo número de adornos o comienzo principal perdería la diferencia posterior.

¿Cuál es la frontera siguiente del control y por qué?

<details><summary>Respuesta 4</summary>

Es `1.6 s`: el adorno de `0.1 s` se añade a la principal de `0.5 s`. Es otra asignación, no un error aritmético dentro de la política principal.

</details>

### Ejercicio 5

Si la fuente no aporta una asignación utilizable, conservar la ambigüedad en lugar de inventar una regla estilística autoritaria. Un músico puede elegir tras revisar contexto. El agente debe declarar política y guardar notación original para permitir otra interpretación. Una reproducción fluida no prueba fidelidad a una intención no expresada.

¿Qué refutaría conservar la casilla elegida?

<details><summary>Respuesta 5</summary>

Terminar el caso principal en `1.6 s` en vez de `1.5 s` contradice su conservación. Otra política declarada podría escoger legítimamente la frontera posterior.

</details>

## Tarea con consulta de fuentes

Dibujar manualmente ambas cronologías con cada adorno, comienzo principal y frontera siguiente. Inspeccionar extremos conservados y atributos oficiales. Escribir un intercambio que nombre la asignación y preserve la marca original. Declarar un refutador de frontera antes de proponer reglas de programación y dejar pendientes adecuación estilística, reproducción real y actuación del aprendiz.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
