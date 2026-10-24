---
module_id: wml-007-resolve-scale-degrees-against-tonic-and-mode
department: world-music-languages
course: "Resolver grados de una escala según la tónica y el modo"
level: intermediate
prerequisites: ["wml-005-declare-note-name-conventions", "mcl-005-preserve-written-and-sounding-pitch"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Resolver grados de una escala según la tónica y el modo

> **Alcance del borrador.** Tablas de grados y controles de convenciones elaborados para el curso, con lectura de documentación primaria y código. No se realizó ningún resolutor nuevo de grados, interfaz de solfeo, detector de tonalidad, experimento de canto ni ensayo con estudiantes. Siguen pendientes las revisiones humanas técnicas, musicales, lingüísticas por personas que dominen el idioma y pedagógicas con estudiantes, así como la verificación del HTML del curso desplegado.

## La pregunta del proyecto

Un agente de práctica pide «1, 3, 5» o «do, re, mi». Esas etiquetas no identifican alturas absolutas hasta que se conocen sus convenciones y su referencia musical. [WML-005](wml-005-declare-note-name-conventions.md) distingue las convenciones de nombres de alturas; [MCL-005](../../musicology/en/mcl-005-preserve-written-and-sounding-pitch.md) conserva el registro y la transposición. Aquí la referencia que falta es una tónica y una forma de escala declaradas.

El [texto de Open Music Theory sobre grados de escala, publicado por sus autores](https://openmusictheory.github.io/scales.html), define los grados en relación con una escala y describe el uso del do móvil. Leímos ese texto antiguo, no la página más reciente que devolvió un error de acceso. Nuestros ejemplos utilizan un vocabulario acotado mayor y menor natural en temperamento igual de doce sonidos; no clasifican todas las tradiciones musicales ni deducen una convención de la nacionalidad de un músico.

## 1. Un grado es un índice, no un número de semitonos

En este ejercicio, los grados ascendentes de 1 a 7 utilizan los desplazamientos mayores `[0,2,4,5,7,9,11]` o menores naturales `[0,2,3,5,7,8,10]`. Sume el desplazamiento seleccionado a un número explícito de nota tónica. D4 es 62, por lo que sus grados mayores 1, 3 y 5 son `[62,66,69]`: D4, F#4 y A4.

Utilizar el grado menos uno como desplazamiento en semitonos convertiría en cambio el grado 3 en `62+2=64`, E4. Una posición numerada en una escala declarada no es un intervalo cromático medido en semitonos.

### Ejercicio 1: resolver la tríada mayor

Calcule los grados 1, 3 y 5 por encima de la tónica D4 en la forma mayor estipulada. Analice el error de un resolutor que produce 64 para el grado 3.

> **Respuesta:** Los desplazamientos son 0, 4 y 7, dando `[62,66,69]`. El grado 3 debe ser F#4 en 66. Devolver 64 trata el índice del grado menos uno como desplazamiento en semitonos e ignora la tabla de la escala mayor.

## 2. Mantener explícitos la forma de escala y el registro de la tónica

En D menor natural, los mismos grados pasan a ser `[62,65,69]`, con F4 en lugar de F#4. Cambiar la forma de escala modifica la tercera sin cambiar la tónica. La palabra genérica «menor» no especifica todos los grados que pueden elevarse o rebajarse; esta tabla elige deliberadamente la menor natural.

La clase de altura de tónica 2 tampoco elige D4 en vez de D3. Un resolutor que necesite notas absolutas debe recibir el registro o una regla explícita para elegirlo. Un destino limitado a clases de altura puede conservar esa limitación en vez de inventar una octava.

### Ejercicio 2: cambiar una entrada declarada

Compare las tríadas mayor y menor natural con tónica D4. Si solo se proporciona la clase de tónica 2, ¿queda determinada de forma única alguna de las tríadas absolutas?

> **Respuesta:** La mayor da `[62,66,69]`; la menor natural da `[62,65,69]`. Sus terceras difieren en un semitono. Una clase de tónica por sí sola no proporciona D4 ni otro registro, y también debe declararse la forma de escala. Ninguna tríada absoluta se deduce de forma única solo de la clase 2.

## 3. El número de alteraciones de la armadura no proporciona todas las referencias

El [campo fifths de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/fifths/) cuenta los sostenidos o bemoles de una armadura tradicional. El [campo mode](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/mode/), separado, distingue mayor, menor y otros modos con nombre.

Con dos sostenidos, D mayor y B menor ya dan clases de tónica diferentes, 2 y 11, dentro de una comparación restringida a mayor y menor. Un modo ausente no puede sustituirse silenciosamente por mayor. Incluso una tonalidad y un modo seleccionados no proporcionan el registro de la tónica ni prescriben cada nota cromática de una melodía.

### Ejercicio 3: conservar el contexto tonal no resuelto

Una tonalidad almacenada tiene un número de quintas de 2 y carece de modo. Un agente supone D4 mayor y resuelve todos los grados. Identifique las entradas adivinadas y proponga un informe acotado.

> **Respuesta:** El agente adivinó mayor en vez de otro contexto compatible y adivinó el registro 4. Incluso dentro de las posibilidades mayores y menores, B menor tiene clase de tónica 11 en vez de 2. Conserve el modo y el registro ausentes como no resueltos; obtenga la tónica y la forma de escala previstas, así como la política de registro, antes de devolver notas absolutas. El número de alteraciones de la armadura por sí solo no basta.

## 4. Interpretar una sílaba bajo su vocabulario declarado

Estipulemos un vocabulario silábico relativo mayor en el que do, re y mi sean los grados 1, 2 y 3 por encima de la tónica D4. Produce `[62,64,66]`. Estipulemos por separado un vocabulario fijo de nombres de notas naturales en el registro 4 en el que esas mismas sílabas nombren C4, D4 y E4, produciendo `[60,62,64]`.

Son controles declarados explícitamente, no un diccionario universal de sílabas ni una asignación de sistemas a países. Un «do» sin especificar no proporciona el vocabulario previsto ni un registro absoluto. Este conjunto define grados solo de 1 a 7; el grado 8 queda fuera del vocabulario elegido salvo que se especifique una extensión.

### Ejercicio 4: distinguir las dos peticiones

Resuelva do, re y mi bajo ambos controles declarados. ¿Qué debe ocurrir con un do no especificado o con el grado 8? ¿Rechazar aquí el grado 8 significa que ningún sistema musical puede utilizarlo?

> **Respuesta:** El control relativo mayor produce `[62,64,66]`; el control de nombres naturales fijos produce `[60,62,64]`. Un do no especificado necesita su convención y registro; el grado 8 queda fuera de esta interfaz declarada de siete grados. Ese límite es una decisión de diseño acotada, no una prohibición universal de las notaciones de grados ampliadas.

## 5. Leer lo que conservan las interfaces seleccionadas de GA

El [analizador de tonalidad MusicXML](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L140-L153) en la revisión fijada almacena el número de quintas y una cadena opcional de modo. Su código seleccionado no resuelve este vocabulario de grados. El [analizador de alturas](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs#L5-L8), separado, espera una letra absoluta, un único sostenido o bemol opcional y una octava. En esta revisión, sus patrones están anclados; ese hecho no debe proyectarse sobre otra revisión utilizada en una lección anterior.

### Ejercicio 5: preparar una transferencia de etiquetas con ayuda de las fuentes

Lea esas interfaces y el [registro fijado de grados](../../../../code/streeling/evidence/capo-spelling-2026-10-22/degree-context.json). Especifique qué debe conservar un agente propuesto antes de traducir un grado de escala o una sílaba a una altura absoluta.

> **Respuesta:** Conserve el token original, el vocabulario declarado, la identidad y el registro de la tónica, la forma exacta de escala, la política de dirección y rango, la convención de afinación, la escritura prevista y la revisión del código. Conserve las entradas no resueltas o no admitidas en vez de asignarles una nota plausible. Las interfaces seleccionadas de altura absoluta y almacenamiento de tonalidad no demuestran la existencia de un resolutor de sílabas implementado. Compare un contexto tipado explícito y una consulta de tabla antes de proponer un nuevo DSL; siguen pendientes las revisiones por músicos, lingüísticas, con estudiantes y en la aplicación real.
