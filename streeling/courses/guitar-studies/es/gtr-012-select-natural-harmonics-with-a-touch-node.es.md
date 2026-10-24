---
module_id: gtr-012-select-natural-harmonics-with-a-touch-node
department: guitar-studies
course: "Seleccionar armónicos naturales con un punto de contacto"
level: intermediate
prerequisites: ["gas-006-relate-pluck-position-to-string-modes"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Seleccionar armónicos naturales con un punto de contacto

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Un marcador del diapasón puede indicar dónde presionar, pero un armónico natural pide otro gesto: rozar un nodo conservando la longitud vibrante completa. Confundir las acciones cambia la altura prevista y la instrucción. Una tabla modal ideal explica la diferencia. Añadimos una restricción de contacto al modelo de pulsación previo; una coordenada igual no significa una operación física igual.

## Leer la evidencia conservada

UNSW describe nodos, frecuencias modales y armónicos obtenidos mediante contacto ligero. Leer esos pasajes junto a los estados de voz y excitación Rust conservados. Una frecuencia almacenada no es un modelo de contacto, y los parciales del motor necesitan medición real. La tabla es un cálculo construido, sin guitarra tocada ni armónico renderizado.

[Requisito previo](../../guitar-acoustics/en/gas-006-relate-pluck-position-to-string-modes.md)

[Artefacto conservado del proyecto](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Paquete construido fijo](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.phys.unsw.edu.au/jw/strings.html)

### Ejercicio 1

Elegir fundamental `110 Hz` y modos candidatos `[1,2,3,4,5,6]`. La forma ideal es `sin(n*pi*x/L)`. En la fracción de contacto `1/3`, sobrevive a la restricción de desplazamiento nulo un modo cuyo número sea divisible por `3`. El contacto no acorta la cuerda en esta regla; suprime movimientos incompatibles.

¿Qué modos candidatos tienen nodo en el contacto?

<details><summary>Respuesta 1</summary>

Sobreviven `[3,6]`. Los demás modos listados tienen desplazamiento no nulo en `1/3` y quedan suprimidos bajo la restricción declarada.

</details>

### Ejercicio 2

Multiplicar cada modo conservado por el fundamental da `[330,660] Hz`, con mínimo `330 Hz`. Puede haber varias componentes permitidas, sin que la regla determine sus amplitudes. La frecuencia permitida más baja no constituye una medición de prominencia o sonoridad.

¿Cuáles son las frecuencias supervivientes y la menor?

<details><summary>Respuesta 2</summary>

Son `[330,660] Hz`, con mínimo `330 Hz`. No se especificaron ni observaron amplitudes relativas o altura percibida.

</details>

### Ejercicio 3

Presionar firmemente en la misma coordenada impondría un nuevo extremo vibrante; la altura dependería del lado conservado entre contacto y puente. La coordenada parte de un extremo declarado y no es un número de traste. Antes de producir un diagrama o instrucción de agente hay que indicar origen y acción.

¿Por qué la fracción de contacto no determina una nota pisada?

<details><summary>Respuesta 3</summary>

Rozar y pisar imponen restricciones diferentes. La nota pisada necesita lado y longitud conservados; la tabla de armónicos mantiene el fundamental original `110 Hz` como referencia.

</details>

### Ejercicio 4

El control negativo mueve el contacto a `1/2`. Sobreviven `[2,4,6]`, con frecuencias `[220,440,660] Hz` y mínimo `220 Hz`. El sexto modo aparece en ambas posiciones, pero cambia la componente menor. Informar solo del parcial agudo compartido ocultaría una diferencia importante en la instrucción.

¿Qué cambia y qué permanece compartido?

<details><summary>Respuesta 4</summary>

El mínimo pasa de `330 Hz` a `220 Hz`. Se comparte el modo `6`, a `660 Hz`. Un parcial común no demuestra instrucciones ni espectros equivalentes.

</details>

### Ejercicio 5

Un dedo real tiene anchura y presión finitas, y una cuerda real tiene amortiguamiento y rigidez. La regla predice modos permitidos, sin garantizar que el intérprete los excite limpiamente. Una tarea futura debe conservar posición, presión descrita, pulsación y grabación bruta y buscar la familia prevista sin confundir otro parcial con el fundamental.

¿Qué refutaría aplicar esta regla ideal a una toma?

<details><summary>Respuesta 5</summary>

Una toma controlada con contacto conocido cuyo patrón modal contradiga la predicción rechazaría la explicación simple para esa toma. Un contacto ausente o una geometría ambigua deja la premisa sin verificar.

</details>

## Tarea con consulta de fuentes

Dibujar ambos contactos en la cuerda completa y calcular manualmente sus tablas modales. Inspeccionar el estado de voz e identificar la información de contacto que necesitaría otra representación. Escribir una instrucción que distinga rozar y presionar y declare el origen. Describir una grabación capaz de refutar la predicción sin afirmar que el armónico ya se haya tocado.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
