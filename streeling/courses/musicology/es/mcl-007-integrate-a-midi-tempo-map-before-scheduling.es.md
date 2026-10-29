---
module_id: mcl-007-integrate-a-midi-tempo-map-before-scheduling
department: musicology
course: "Integrar un mapa de tempo MIDI antes de programar la reproducción"
level: intermediate
prerequisites: ["mcl-004-model-timing-without-inventing-a-style", "mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Integrar un mapa de tempo MIDI antes de programar la reproducción

> **Alcance del borrador.** Modelos didácticos de eventos, cálculos racionales exactos e inspección estática del código. Quedan pendientes las revisiones humanas técnica, musical, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se analizó ni reprodujo ningún archivo MIDI y no se cambió ningún analizador ni planificador de GA.

## La pregunta del proyecto

Un guitarrista importa una frase de práctica que cambia de tempo. ¿En qué segundos deben situarse los límites de sus notas? Los [Standard MIDI Files](https://midi.org/standard-midi-files) intercambian datos temporizados de eventos, pero conservar una etiqueta de evento no equivale a reconstruir una cronología. [MCL-004](mcl-004-model-timing-without-inventing-a-style.md) ya examina una expresión de tempo entero; [MCL-006](mcl-006-preserve-meter-grouping-and-tempo-units.md) separa agrupación y unidades de pulso. Esta lección añade ubicaciones de eventos, integración del tempo y una comprobación del flujo de control antes de afirmar éxito de importación.

## 1. Declarar la división y acumular ticks

Usa un ejemplo didáctico de una sola pista basado en negras, con resolución Q = 480 ticks por negra. La [documentación de archivos de Mido](https://mido.readthedocs.io/en/stable/files/midi.html) distingue deltas de ticks de pista de sus otras coordenadas de iteración. Acumula el delta de cada evento dentro de su pista antes de descartar o proyectar eventos. Mezclar varias pistas y establecer precedencia de eventos simultáneos requiere reglas adicionales; no se implementan aquí.

El mapa didáctico de tempo es 500000 microsegundos por negra desde el tick 0, 1000000 desde el tick 480 y 250000 desde el tick 960. Un cambio de tempo afecta a los intervalos positivos de ticks posteriores. El orden seleccionado es explícito en un límite compartido. Dentro de un intervalo de tempo constante:

```text
delta_seconds = delta_ticks*microseconds_per_quarter / (Q*1000000)
```

### Ejercicio 1 — Recuperar la coordenada de reloj

Para límites de notas en ticks 0, 240, 480, 720, 960 y 1200, calcula los segundos a partir de este mapa. ¿Por qué es inválido multiplicar cada tick por el último tempo?

> **Respuesta:** Los segundos son 0, 0.25, 0.5, 1, 1.5 y 1.625. El atajo del último tempo da solo 0.625 segundos en el tick 1200 porque aplica el tempo final a intervalos regidos por tempos anteriores. Un valor de tempo necesita su ubicación y una división temporal declarada.

## 2. Dividir una nota en los límites de tempo

Una nota empieza en el tick 240 y termina en el tick 1200. Su duración atraviesa tres tramos de tempo constante, con longitudes en ticks 240, 480 y 240. Sus tiempos transcurridos son 0.25, 1 y 0.125 segundos. Son cálculos didácticos de partitura a tiempo, no una interpretación grabada ni un modelo de swing.

### Ejercicio 2 — Integrar el intervalo

Calcula la duración de la nota sumando esos tramos y restando los tiempos absolutos de sus extremos. ¿Da lo mismo tomar el tempo al inicio de nota y aplicarlo a la nota completa?

> **Respuesta:** Ambos métodos correctos dan 1.375 segundos: 0.25 + 1 + 0.125, o 1.625 - 0.25. Aplicar el tempo inicial de 500000 microsegundos a los 960 ticks completos da 1 segundo y omite los cambios intermedios. El intervalo de nota debe usar todo el mapa de tempo pertinente.

## 3. No aplicar la fórmula de negras a una división basada en fotogramas

La [referencia de temporización MIDI de Microsoft](https://learn.microsoft.com/en-us/windows/win32/multimedia/timing-information) distingue divisiones de negras y SMPTE. Para el ejemplo limitado sin salto de numeración de fotogramas de aquí, 25 fotogramas por segundo y 40 ticks por fotograma dan 1000 ticks por segundo. Un evento de tempo no cambia esa duración de tick.

El byte alto codificado para la etiqueta negativa de formato -25 es 231. Con byte bajo 40, la palabra de división es `E728`. En el commit de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`, el [analizador de cabecera](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L13-L17) lee una palabra no negativa; su [rama SMPTE](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L73-L85) niega el byte alto desplazado sin decodificarlo antes con signo. La aritmética estática predice -231 para esa expresión del código, no la etiqueta positiva de formato 25. No es una nueva captura de fallo de F# ni un decodificador SMPTE completo.

### Ejercicio 3 — Comprobar la representación antes de usarla

Bajo el modelo declarado de 25 fotogramas y 40 ticks, convierte 750 ticks a segundos. Explica la diferencia entre byte codificado 231, etiqueta con signo -25 y etiqueta positiva de formato 25. ¿Puede usarse la expresión del código como decodificador verificado?

> **Respuesta:** Un tick dura 0.001 segundos, así que 750 ticks duran 0.75 segundos. El byte 231 representa -25 con signo tras decodificarlo explícitamente como byte con signo; su negación da la etiqueta de formato 25. El código seleccionado predice en cambio -231 porque niega un valor de byte alto sin signo. Esa lectura no verifica un decodificador funcional. La conversión con salto de numeración queda fuera de este ejemplo.

## 4. Una representación de evento puede perder la ubicación del tempo

Los [tipos MIDI](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MidiTypes.fs#L19-L46) conservan tiempo delta en registros de notas, mientras la alternativa de tempo solo guarda un entero. El [cuerpo seleccionado de construcción de tempo](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L197-L207) no aporta una envoltura de tiempo de evento. Considera dos flujos didácticos con tempo inicial e inicio de nota en el tick 0:

| Flujo | Delta antes del cambio a 1000000 microsegundos por negra | Delta desde ese cambio al final de nota | Tick absoluto de final de nota | Segundos de final de nota |
| --- | --- | --- | --- | --- |
| A | 480 | 480 | 960 | 1.5 |
| B | 240 | 480 | 720 | 1.25 |

El tempo inicial es 500000 microsegundos por negra. Si cuerpos de construcción correctamente encaminados proyectaran estos eventos solo a enteros de tempo y deltas locales de notas, ambas listas modeladas contendrían los mismos valores de tempo y deltas de notas. Perder el delta del evento de tempo impide recuperar la diferencia. Estas listas hipotéticas **no son salidas reales del analizador**.

### Ejercicio 4 — Mostrar qué olvida la proyección

Calcula ambos ticks absolutos de final de nota y segundos. ¿Por qué no puede un agente posterior recuperar qué flujo se proporcionó solo de las listas proyectadas hipotéticas?

> **Respuesta:** A termina en 480 + 480 = 960 ticks, después de 0.5 + 1 = 1.5 segundos. B termina en 240 + 480 = 720 ticks, después de 0.25 + 1 = 1.25 segundos. Descartar el delta del evento de tempo hace idénticas las listas modeladas aunque las ubicaciones previstas difieran. Un cálculo posterior no puede recuperar de forma única una entrada borrada. Corregir solo el encaminamiento no solucionaría esta pérdida de representación.

## 5. Comprobar si puede alcanzarse un cuerpo seleccionado

El [distribuidor de eventos](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L98-L173) enmascara primero el estado con una máscara de medio byte alto y después busca un valor completo de metaevento. Para un estado de metaevento:

```text
0xFF & 0xF0 = 0xF0
0xF0 != 0xFF
```

Por tanto, la rama de metaevento es inalcanzable mediante la selección mostrada. El [paquete fijado](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/parser-boundaries.json) enumera los 256 bytes de entrada; ninguno produce la etiqueta completa de metaevento tras esa máscara. Es un testigo de flujo de control, no una ejecución del analizador sobre un archivo válido. Las dos revisiones del analizador usadas en MCL-004 y MCL-006 tienen bytes idénticos aquí; sus ejemplos de metadatos son ahora interpretaciones explícitamente condicionales de cuerpos.

### Ejercicio 5 — Enunciar la siguiente afirmación admisible

Un agente cita el cuerpo de tempo y declara una ruta fiel de MIDI a reproducción. Da la objeción del enmascaramiento de bytes, distingue el segundo problema de representación y especifica qué debe conservar y ejecutar una validación real.

> **Respuesta:** El estado enmascarado no puede seleccionar la rama de metaevento, así que la ruta mostrada no establece análisis satisfactorio de tempo. Incluso con encaminamiento corregido, conservar enteros de tempo sin ubicaciones de eventos pierde información. Una ruta validada necesita eventos temporizados, unidades brutas de tempo, división declarada, reglas de orden y mezcla e identidad exacta del código, y después comprobaciones reales de analizador y cronología sobre casos límite antes de medir reproducción. Una ruta de otra biblioteca necesitaría sus propias pruebas. Aquí no se produjo una corrección del analizador ni una importación funcional.

## Tarea del estudiante con acceso a las fuentes

Prepara una revisión temporal con los seis límites convertidos, la duración de la nota que cruza cambios de tempo, la conversión basada en fotogramas y la comprobación de byte con signo, ambos flujos testigo y la prueba de la máscara del distribuidor. Propón un registro mínimo de evento conservado y una prueba que refute una futura implementación. Trátalo como candidato, no como contrato ratificado de GA. Registra ayuda e incógnitas. La [rúbrica de revisión](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/reviewer-rubric.json) está preparada; no hay intento de estudiante registrado.

El [comprobante de fuentes](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/primary-readback.json) vincula los archivos reales. No se leyó el PDF completo de la especificación MIDI; no se certifican conformidad, temporización del navegador, estilo cultural, beneficio de escucha ni HTML desplegado.
