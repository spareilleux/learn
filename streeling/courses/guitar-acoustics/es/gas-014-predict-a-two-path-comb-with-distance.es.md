---
module_id: gas-014-predict-a-two-path-comb-with-distance
department: guitar-acoustics
course: "Predecir un peine de dos trayectos mediante distancias"
level: intermediate
prerequisites: ["aud-009-declare-alignment-before-a-null-test"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Predecir un peine de dos trayectos mediante distancias

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Un hueco en el espectro de guitarra puede proceder de combinar copias retrasadas de la misma fuente. No implica que la cuerda no generara esa frecuencia. En una sala o modelo de reflexión, la diferencia de recorrido cambia la fase con la frecuencia. Predecimos un peine construido antes de atribuir el hueco al instrumento y mostramos por qué acertar la frecuencia de oposición no garantiza un cero medido completo.

## Leer la evidencia conservada

Leer las reflexiones tempranas del Rust conservado y su conversión de segundos a índices. Son parámetros sintéticos, no distancias de micrófonos medidas. OpenStax explica la suma de ondas retrasadas y la oposición de fase. Introducimos distancias y velocidad propias. La decisión de alineación del requisito previo sigue siendo útil, pero alinear automáticamente eliminaría aquí el efecto de propagación estudiado.

[Requisito previo](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md)

[Artefacto conservado del proyecto](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Paquete construido fijo](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://openstax.org/books/university-physics-volume-1/pages/16-5-interference-of-waves)

### Ejercicio 1

El primer trayecto mide `1 m`, el segundo `1.343 m` y la velocidad supuesta es `343 m/s`. La diferencia es `0.343 m`. Dividirla por velocidad da `tau=(d_b-d_a)/c`, o `0.001 s`. No hace falta el inicio absoluto para esta diferencia si ambas señales comparten excitación y reloj.

¿Qué retardo relativo resulta de las distancias?

<details><summary>Respuesta 1</summary>

El retardo es `0.001 s`. Describe tiempo adicional de propagación, no una latencia absoluta de micrófono o motor medida.

</details>

### Ejercicio 2

Cuando el período es el doble del retardo, la copia retrasada queda medio ciclo atrás. La primera oposición positiva es `1/(2*tau)=500 Hz`. Con ganancias iguales y señales idénticas en lo demás, se cancelan. El resultado depende de los dos trayectos; una grabación con muchas reflexiones no tiene por qué mostrar un cero exacto aislado.

¿Dónde aparece la primera cancelación prevista con ganancias iguales?

<details><summary>Respuesta 2</summary>

En `500 Hz`, con magnitud `0` en el modelo ideal. Es una predicción, no una característica observada de una grabación.

</details>

### Ejercicio 3

La fase se repite al aumentar frecuencia en `1/tau=1000 Hz`. Por eso la oposición siguiente aparece en `1500 Hz`, después de `500 Hz`. Espaciado y primera oposición responden preguntas distintas. No debe confundirse uno con otra; además, las celdas espectrales discretas pueden no coincidir con esas frecuencias.

Dar el espaciado y la oposición siguiente.

<details><summary>Respuesta 3</summary>

El espaciado es `1000 Hz` y la siguiente oposición `1500 Hz`. Comparar un mínimo medido requiere declarar muestreo y ventana de la rejilla espectral.

</details>

### Ejercicio 4

El control negativo conserva trayectos y cambia la segunda ganancia a `0.5`. En oposición la magnitud es `abs(1-g)=0.5`, no `0`. La geometría sigue prediciendo `500 Hz`; la diferencia de amplitud cambia la profundidad. La posición del hueco sola no certifica micrófonos equivalentes ni cancelación perfecta.

¿Qué predicción se conserva y cuál falla?

<details><summary>Respuesta 4</summary>

La oposición sigue en `500 Hz`, con espaciado `1000 Hz`. Falla la cancelación completa: el residuo previsto es `0.5`. Oposición de fase y amplitud nula son afirmaciones distintas.

</details>

### Ejercicio 5

Una revisión debe conservar canales antes de sumar, distancias supuestas, ganancia y cualquier alineación. Si se estudia el efecto de sala, quitar el retardo relativo cambia el experimento. Si se comparan motores compensados, hay que declarar la compensación. Un espectro más liso después del procesamiento no decide por sí solo cuál es el objetivo.

¿Qué refutaría este modelo ideal de dos trayectos?

<details><summary>Respuesta 5</summary>

Una transferencia medida incompatible con retardo, periodicidad o residuo dependiente de ganancia más allá de la incertidumbre declarada lo rechazaría para esa captura. Los trayectos desconocidos impiden culpar solo a la guitarra.

</details>

## Tarea con consulta de fuentes

Dibujar los trayectos construidos y calcular manualmente retardo, oposición, espaciado y residuo con ganancias distintas. Inspeccionar los taps sintéticos y explicar por qué sus segundos no son un estudio de sala. Proponer una captura que conserve ambos trayectos y una medición de transferencia refutante. Decidir si alinear forma parte de la pregunta antes de proponer un flujo de audio o control nuevo.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
