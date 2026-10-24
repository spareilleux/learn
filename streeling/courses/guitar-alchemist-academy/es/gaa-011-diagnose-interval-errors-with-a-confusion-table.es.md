---
module_id: gaa-011-diagnose-interval-errors-with-a-confusion-table
department: guitar-alchemist-academy
course: "Diagnosticar errores de intervalo con una tabla de confusión"
level: intermediate
prerequisites: ["gaa-010-define-a-practice-pass-before-counting-success"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Diagnosticar errores de intervalo con una tabla de confusión

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Una puntuación resume cuántas respuestas coinciden con la clave, pero puede ocultar qué intervalos confunde el guitarrista. Eso cambia la próxima pregunta útil de GA. Construimos una tabla pequeña con convenciones explícitas de filas y columnas. Diagnostica un patrón inventado, sin demostrar mejora de una persona. El requisito previo definía el aprobado; esta lección conserva tipo y dirección de error antes de proponer práctica.

## Leer la evidencia conservada

Leer las claves por objetivo y las políticas de pistas del paquete de práctica. Una forma exacta y una familia de acordes tienen criterios diferentes, mostrando que acertar depende de la tarea. La definición factorial NIST motiva conservar condiciones antes de agregarlas. La tabla de intervalos es una construcción independiente, no un resultado recuperado del paquete ni de un participante real.

[Requisito previo](../../guitar-alchemist-academy/en/gaa-010-define-a-practice-pass-before-counting-success.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Paquete construido fijo](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.itl.nist.gov/div898/handbook/pri/section3/pri333.htm)

### Ejercicio 1

Las filas son etiquetas verdaderas y las columnas respuestas, ambas en orden `[major,minor]`. Las cuentas son `[[3,1],[2,4]]`. La esquina superior derecha significa mayor respondido menor; la inferior izquierda significa lo contrario. Escribir la orientación evita invertir el diagnóstico conservando los mismos números.

¿Cuántos errores hay en cada dirección?

<details><summary>Respuesta 1</summary>

Hay `1` error de mayor a menor y `2` de menor a mayor. La dirección depende de la convención declarada de filas y columnas.

</details>

### Ejercicio 2

La tabla contiene `10` ensayos y la diagonal suma `7`. La exactitud es `7/10=0.7`. El denominador incluye todos los ensayos completos declarados. Ausencias, reintentos y ayudas necesitarían campos separados; aquí no se añaden implícitamente. El escalar resume, pero pierde la diferencia entre direcciones.

¿Cuáles son ensayos, aciertos y exactitud?

<details><summary>Respuesta 2</summary>

Son `10`, `7` y `0.7`. Describen datos sintéticos, no una mejora de aprendizaje observada.

</details>

### Ejercicio 3

Hay `4` casos mayores y su sensibilidad es `3/4=0.75`. Hay `6` menores y su sensibilidad es `4/6=2/3`. Responder siempre la clase verdadera más frecuente daría `6/10=0.6`. Superar esa referencia local no demuestra transferencia ni beneficio causal de practicar.

¿Qué clase tiene sensibilidad menor y cuál es la referencia mayoritaria?

<details><summary>Respuesta 3</summary>

Menor tiene `2/3`, frente a `0.75` de mayor. La referencia mayoritaria es `0.6` y depende de los totales desiguales.

</details>

### Ejercicio 4

El control negativo intercambia el significado de las columnas y produce `[[1,3],[4,2]]`. Siguen `10` ensayos, pero los aciertos pasan a `3` y la exactitud a `0.3`. Comprobar solo los totales no detecta un mapa de etiquetas corrupto. Conservar etiquetas y revisión del mapa con cualquier diagnóstico generado.

¿Qué cambia al intercambiar las etiquetas de respuesta?

<details><summary>Respuesta 4</summary>

La exactitud pasa a `0.3`, con sensibilidades `[0.25,1/3]`. Un total igual no certifica la interpretación correcta de las columnas.

</details>

### Ejercicio 5

Una propuesta siguiente podría trabajar la confusión frecuente equilibrando ítems nuevos y ocultando pistas. Su utilidad sigue siendo una hipótesis. Repetir los mismos sonidos puede medir memoria de ejemplos en vez de transferencia. Guardar respuestas anteriores al feedback, asistencia y condiciones de ítems nuevos si después se pretende hablar de aprendizaje.

¿Qué refutaría que el diagnóstico conserva la dirección del error?

<details><summary>Respuesta 5</summary>

Intercambiar los significados fuera de diagonal o mantener la exactitud en el control contradice la tabla. Una puntuación futura mejor todavía exige condiciones comparables para apoyar aprendizaje.

</details>

## Tarea con consulta de fuentes

Construir a mano la tabla etiquetada y calcular exactitud, sensibilidades y referencia mayoritaria. Inspeccionar las pistas del paquete y explicar cómo mostrar la respuesta invalidaría una prueba de recuerdo. Proponer un ítem dirigido, su refutador y la evidencia necesaria para separar reconocimiento de intervalos y memoria de ejemplos. Esta hoja no evalúa a ningún aprendiz real.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
