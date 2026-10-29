---
module_id: aud-015-bound-quantization-error-before-comparing-wavs
department: audio-engineering
course: "Acotar el error de cuantización antes de comparar WAV"
level: intermediate
prerequisites: ["aud-005-pcm-guards-and-format-boundaries"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Acotar el error de cuantización antes de comparar WAV

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

El programa de guitarra conservado mantiene muestras flotantes y también escribe un WAV entero. Son representaciones diferentes del renderizado propuesto. Una diferencia en los búferes brutos puede desaparecer al convertir; una diferencia decodificada pequeña también puede proceder de la conversión. Antes de interpretar dos WAV como motores equivalentes, el agente debe identificar el cuantizador, su redondeo y las hipótesis de cualquier cota de error.

## Leer la evidencia conservada

Leer la expresión real `pcm16Wav` y su decodificador. El codificador multiplica por `32767` y usa `Math.round`; el decodificador divide el entero con signo por la misma escala. Es una observación del código en la revisión conservada. Se estudia esa convención explícita, sin sustituir una escala de manual ni afirmar compatibilidad con todos los formatos WAV.

[Requisito previo](../../audio-engineering/en/aud-005-pcm-guards-and-format-boundaries.md)

[Artefacto conservado del proyecto](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquete construido fijo](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

### Ejercicio 1

Definir `q=floor(scale*x+0.5)` con `scale=32767`, de acuerdo con el redondeo elegido para estos casos finitos. Los niveles decodificados adyacentes distan `1/32767`. Si el resultado es representable y no interviene recorte, la magnitud del error no supera `1/65534`. Es una cota de amplitud normalizada, no de frecuencia ni duración.

¿Cuáles son el paso de cuantización y la cota de medio paso?

<details><summary>Respuesta 1</summary>

Son `1/32767` y `1/65534`. La cota corresponde a la conversión declarada al nivel más cercano sin recorte, no a entradas inválidas arbitrarias.

</details>

### Ejercicio 2

Las muestras construidas son `[0,0.00001,0.5,-0.5]`. Sus enteros son `[0,0,16384,-16383]`. Las medias amplitudes muestran la regla de empate: los puntos medios positivo y negativo no producen enteros simétricos. Cambiar silenciosamente a empate al par comprobaría otro convertidor, aunque muchas muestras ordinarias coincidieran.

Codificar las muestras y explicar la asimetría de los puntos medios.

<details><summary>Respuesta 2</summary>

Los enteros son `[0,0,16384,-16383]`. Redondear los empates hacia infinito positivo da esa pareja; la regla elegida debe permanecer en el contrato del código.

</details>

### Ejercicio 3

Decodificar dividiendo por `32767`. La pequeña muestra positiva pasa exactamente a `0`, con error firmado `-0.00001`. Las medias amplitudes tienen errores `16384/32767-0.5` y `-16383/32767+0.5`. Ambos respetan la magnitud de medio paso. Desaparecer tras convertir significa que la representación entera no resuelve la diferencia, no que las muestras flotantes fueran idénticas.

¿Qué se pierde cuando la muestra pequeña queda en cero?

<details><summary>Respuesta 3</summary>

Se pierde su amplitud flotante no nula en esta frontera. El error es `-0.00001`; la igualdad entera posterior no demuestra igualdad flotante anterior.

</details>

### Ejercicio 4

El control negativo aporta `1.1`, fuera del contrato normalizado. La expresión produce el entero `36044`, que no cabe en el campo entero con signo de esta anchura. El control conservado rechaza amplitudes fuera de rango antes de escribir; la cota de redondeo no promete nada sobre desbordamiento o recorte.

¿Certifica la cota de medio paso la salida almacenada de este control?

<details><summary>Respuesta 4</summary>

No. El entero `36044` excede el rango de destino. La entrada viola el contrato y debe rechazarse antes de convertir; no se afirma que exista una muestra almacenada válida.

</details>

### Ejercicio 5

El dithering modificaría deliberadamente la muestra antes de cuantizar y exigiría distribución, nivel y alcance de medición propios. Esta lección no lo añade ni promete que los errores sean inaudibles. Para comparar nativo y Wasm, guardar por separado muestras brutas y bytes codificados y declarar si se estudia igualdad numérica, reproducción entera o escucha.

¿Qué refutaría una igualdad bruta inferida de WAV iguales?

<details><summary>Respuesta 5</summary>

Dos muestras flotantes conservadas que difieran pero produzcan el mismo entero son un contraejemplo. La muestra pequeña ofrece esa construcción; una conclusión auditiva requiere una tarea de escucha real.

</details>

## Tarea con consulta de fuentes

Escribir una nota de conversión del programa existente. Calcular manualmente enteros y errores con su regla y después inspeccionar codificador y decodificador. Incluir el control fuera de rango y explicar por qué es una entrada rechazada, no un defecto del motor medido. Recomendar qué artefactos guardar cuando difieran igualdad bruta e igualdad WAV, sin inventar resultados auditivos.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
