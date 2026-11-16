---
module_id: gtr-007-carry-picking-phase-across-bar-lines
department: guitar-studies
course: "Conservar la fase de púa alternada a través de las barras de compás"
level: intermediate
prerequisites: ["gtr-005-plan-which-string-keeps-ringing", "mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar la fase de púa alternada a través de las barras de compás

> **Alcance del borrador.** Modelos de ataques y reloj de movimiento creados para el curso, trazas exactas e inspección de código de notación fijado a una revisión. Quedan pendientes las revisiones humanas técnica, musical, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se probaron un guitarrista, un importador de partituras, un renderizador de audio ni una técnica física.

## La pregunta del proyecto

Un agente de guitarra escribe un compás de púa alternada y lo repite. ¿Conserva la alternancia reiniciar las direcciones en cada compás? ¿Qué ocurre con un silencio o una continuación ligada? Una instrucción útil de práctica indica qué eventos avanzan su estado de dirección en lugar de tratar silenciosamente una barra de compás como un reinicio.

Usamos una cuerda, siete pulsos equidistantes de corchea por compás y una regla didáctica: los ataques consecutivos alternan D y U, empezando con D en el pulso absoluto 0. D y U significan direcciones abajo y arriba. No prescriben sonoridad, acento, velocidad, cruce de cuerdas, esfuerzo ni una técnica preferida. El [símbolo down-bow de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/down-bow/) también representa un golpe hacia abajo en instrumentos de cuerda pulsada; el [símbolo up-bow](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/up-bow/) incluye igualmente el golpe hacia arriba. Un símbolo de notación es distinto de un movimiento de mano medido.

## 1. Conservar el estado a través de un compás impar

Coloca primero un ataque en cada pulso. Las direcciones en los pulsos absolutos de 0 a 6 son D, U, D, U, D, U, D. El ataque en el pulso 7 debe ser U según la regla declarada. Por tanto, los inicios de compás en los pulsos 0, 7, 14 y 21 tienen direcciones D, U, D y U.

Reiniciar D en cada compás crea en cambio D seguido de D en los límites del pulso 6 al 7, del 13 al 14 y del 20 al 21. Puede ser una instrucción intencionadamente distinta, pero no es alternancia estricta entre esos ataques. El desajuste simbólico no implica ningún juicio sobre la estrategia de púa preferida de un músico.

### Ejercicio 1: comprobar el compás repetido

Indica la dirección en el pulso 7 bajo alternancia continua de ataques y bajo reinicio en D por compás. Identifica el primer límite con dirección repetida y el primer inicio de compás que recupera el estado original de compás y dirección.

> **Respuesta:** La alternancia continua da U en el pulso 7; reiniciar da D. El primer límite de reinicio es pulso 6 D seguido de pulso 7 D. La fase original de compás y la dirección de púa vuelven juntas en el pulso 14, después de dos compases.

## 2. Incluir todos los relojes pertinentes en una afirmación de repetición

Añade un marcador didáctico independiente que se repita cada cuatro pulsos de corchea. Es un marcador visual de práctica, no un acento interpretado. Un estado completo incluye ahora posición módulo 7 en el compás, módulo 4 en el marcador y módulo 2 en el ciclo de púa. El primer retorno positivo de los tres a sus fases iniciales ocurre en el pulso 28, después de cuatro compases.

El pulso 14 recupera el estado de compás y púa, pero tiene fase de marcador 2. A la frecuencia de negra 120 explícitamente declarada, cada pulso de corchea dura 0.25 segundos, así que el pulso 28 ocurre 7 segundos después del pulso 0. El cálculo de fase por sí solo no establece tiempos reales de reproducción.

### Ejercicio 2: probar una repetición completa

En el pulso 14, ¿qué fase no ha regresado? Indica el primer retorno completo y su tiempo transcurrido bajo el tempo declarado. ¿Basta repetir solo el patrón de direcciones de dos compases para reiniciar todos los marcadores?

> **Respuesta:** El marcador de cuatro pulsos está en fase 2. El retorno completo es el pulso 28, o 7 segundos a negra 120. Una repetición de dos compases no recupera el marcador; la afirmación de retorno debe nombrar los componentes de estado comparados.

## 3. Indicar qué avanza un silencio

Haz ahora que el pulso 3 de cada compás sea silencioso. Con alternancia guiada por ataques, un silencio no produce ataque ni avanza el contador de ataques. Los pulsos atacados 0, 1, 2, 4, 5, 6 del primer compás tienen direcciones D, U, D, U, D, U. Hubo seis ataques, así que el primer ataque del siguiente compás en el pulso absoluto 7 es D.

Otra política didáctica de reloj de pulsos alterna en cambio movimiento D/U en cada pulso de corchea, incluidos los silenciosos. Su ataque en el pulso 4 es D y en el pulso 7 es U. Estas políticas coinciden antes del primer silencio y después difieren. Elegir entre ellas requiere el ejercicio previsto; ninguna es una instrucción universal para todas las técnicas de guitarra.

### Ejercicio 3: distinguir silencio de reinicio de estado

Indica las direcciones de ataque en los pulsos 4 y 7 para las políticas guiada por ataques y de reloj de pulsos con ese silencio repetido. ¿Qué información debe añadir el agente antes de afirmar que sus direcciones son inequívocas?

> **Respuesta:** Las direcciones guiadas por ataques son U en el pulso 4 y D en el pulso 7. Las del reloj de pulsos son D en el pulso 4 y U en el pulso 7. Especifica si los pulsos silenciosos avanzan un reloj de movimiento o solo los ataques reales avanzan la alternancia, junto con la fase inicial y cualquier reinicio intencionado.

## 4. No crear un ataque en una continuación

Vuelve a la cuadrícula de ataques en todos los pulsos salvo que el pulso absoluto 7 es continuación de la nota atacada en el pulso 6. Bajo el modelo de ataques de esta lección no vuelve a pulsarse. Después del ataque D en el pulso 6, el siguiente ataque en el pulso 8 es U. Inventar un ataque en el pulso 7 consumiría esa U y cambiaría el pulso 8 a D.

El [tipo de nota MusicXML de GA de la revisión fijada](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L93-L109) tiene un campo de ligadura de prolongación, mientras que el [analizador de notas seleccionado](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L85-L115) no le asigna valor. Este límite estático es una razón para probar una importación real antes de derivar recuentos de ataques de su resultado. No es un defecto de reproducción recién reproducido.

### Ejercicio 4: conservar la identidad de ataque

Si el pulso 7 es una continuación ligada, ¿qué dirección corresponde al ataque en el pulso 8? ¿Cómo cambiaría la respuesta un reataque falso y qué no certifica el campo inspeccionado del analizador?

> **Respuesta:** El siguiente ataque real en el pulso 8 es U. Un ataque falso en el pulso 7 haría que el pulso 8 fuera D. El campo de ligadura sin rellenar del analizador inspeccionado no certifica conservación de identidad de continuación en una ruta real de importador o reproducción; aquí no se ejecutó tal ruta.

## 5. Comprobar una dirección de notación en el límite

Los [tipos Guitar Pro del proyecto](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/GuitarProTypes.fs#L45-L96) distinguen acento de efectos de golpe y golpe de púa, con cadenas de dirección. En el [analizador de efectos inspeccionado](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/GuitarProParser.fs#L129-L147), el caso seleccionado 7 construye un golpe de púa hacia abajo. Esa rama no es un planificador de fase continua entre compases ni prueba de conformidad con todos los archivos binarios reales.

El [analizador técnico de MusicXML](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L55-L80) enumera cuerda, traste y varias técnicas, pero no los símbolos arriba/abajo enlazados antes; los nombres de hijos no reconocidos se filtran. No infieras soporte de símbolos de la existencia del estándar ni el comportamiento de todas las rutas de GA de esta única rama.

### Ejercicio 5: preparar una prueba útil de ida y vuelta

¿Por qué un tipo de datos capaz de expresar dirección o un caso de analizador de golpe hacia abajo no bastan para afirmar que se conserva el ejercicio? Indica las observaciones necesarias para una siguiente comprobación concreta.

> **Respuesta:** La capacidad de almacenar dirección no demuestra que se lean ambas direcciones, que continúen entre compases ni que se recuperen tras exportar. Usa una ruta fijada a una revisión con signos D/U explícitos, un compás impar de siete ataques, un silencio con política declarada de contador y una continuación ligada. Compara identidades de eventos, direcciones recuperadas y puntos de reinicio; examina por separado la partitura de salida y la ejecución del intérprete. Aquí no se observaron una ida y vuelta satisfactoria, una técnica preferida ni la posibilidad física de tocarlo.

El [registro de púa fijado](../../../../code/streeling/evidence/meter-picking-2026-10-22/picking-phase.json) conserva todas las políticas y controles negativos. [GTR-005](gtr-005-plan-which-string-keeps-ringing.md) comprueba por separado la ocupación de cuerdas; una traza correcta de direcciones no demuestra que sea viable una asignación de notas sostenidas.
