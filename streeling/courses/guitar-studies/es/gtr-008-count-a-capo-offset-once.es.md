---
module_id: gtr-008-count-a-capo-offset-once
department: guitar-studies
course: "Contar una sola vez el desplazamiento de la cejilla"
level: intermediate
prerequisites: ["gtr-001-the-fretboard-map", "gtr-003-audit-voicing-playability", "wml-005-declare-note-name-conventions", "gaa-006-separate-capo-shapes-from-sounding-pitches"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Contar una sola vez el desplazamiento de la cejilla

> **Alcance del borrador.** Cálculos didácticos de trastes y alturas en temperamento igual, lectura de código en una revisión fijada y tres respuestas reales de una herramienta de transposición de acordes. No se realizó ningún adaptador nuevo de cejilla, ejecución nativa de la habilidad, importación MusicXML, medición del instrumento ni prueba de interpretación. Siguen pendientes las revisiones humanas técnicas, musicales, lingüísticas por personas que dominen el idioma y pedagógicas con estudiantes, así como la verificación del HTML del curso desplegado.

## La pregunta del proyecto

Un guitarrista solicita una forma de C con cejilla en el traste 2. ¿Un traste mostrado como 3 indica el tercer traste físico desde la cejuela o el tercero por encima de la cejilla? La [definición de cejilla en MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/capo/) describe un cambio en la afinación al aire. Su [definición de traste](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/fret/) empieza en cero para una cuerda al aire; esa afirmación por sí sola no decide la política de coordenadas de cejilla de una aplicación receptora.

[GAA-006](../../guitar-alchemist-academy/en/gaa-006-separate-capo-shapes-from-sounding-pitches.md) ya establece la dirección de la transformación entre la fundamental de la forma y la fundamental sonora, así como el registro. Esta lección extiende esa distinción a los orígenes de los trastes por cuerda, las posiciones inválidas y la cobertura parcial.

Estipulemos una cejilla completa ideal, temperamento igual de doce sonidos y tablas ordenadas desde E grave hasta E agudo. Los números de nota al aire son `[40,45,50,55,59,64]`, con C4 igual a 60. La forma de C elaborada para el curso es `[-1,3,2,0,1,0]`: -1 indica una cuerda silenciada y los otros números son distancias por encima del extremo efectivo de la cuerda al aire.

## 1. Conservar el origen de los trastes

Para cada cuerda que suena, sea `a` el traste físico relativo a la cejuela, `c` el traste de la cejilla, `r` el traste relativo a la cejilla y `T` el número original de nota al aire. Entonces `a=c+r` y el número de nota sonora es `T+a=(T+c)+r`. Ambas expresiones son válidas bajo el modelo declarado.

Con cejilla en el traste 2, la tabla física de la forma de C pasa a ser `[-1,5,4,2,3,2]`. Las notas resultantes son `[null,50,54,57,62,66]`. Aquí null significa que una cuerda silenciada no tiene altura sonora en el registro didáctico; no es una observación de frecuencia cero.

### Ejercicio 1: convertir la forma completa

Convierta la forma de C relativa a la cejilla en trastes físicos y números de notas sonoras. ¿Dónde se encuentra una cuerda al aire relativa? ¿Qué ocurre con el marcador de cuerda silenciada?

> **Respuesta:** Los trastes físicos son `[-1,5,4,2,3,2]`; las notas sonoras son `[null,50,54,57,62,66]`. El traste relativo 0 se encuentra en el traste físico 2 con esta cejilla completa. El marcador -1 mantiene el estado de cuerda silenciada; sumarle la cejilla inventaría un traste sonoro.

## 2. No reafinar y volver a desplazar los trastes físicos

Reafinar la tabla de cuerdas al aire según la cejilla da `[42,47,52,57,61,66]`. Sumar los trastes relativos originales produce las mismas notas correctas. Sumar en cambio la tabla física ya desplazada produce `[null,52,56,59,64,68]`: cada nota sonora queda dos semitonos demasiado alta.

### Ejercicio 2: encontrar el doble cómputo

Calcule ambos resultados para la quinta cuerda, cuya nota original al aire es 45, cuyo traste relativo es 3 y cuyo traste físico es 5. ¿Qué cantidad ya ha incorporado el desplazamiento de la cejilla?

> **Respuesta:** El resultado correcto es `45+5=50` o `(45+2)+3=50`. El resultado incorrecto es `(45+2)+5=52`. Tanto la nota al aire reafinada como el traste físico ya incluyen el desplazamiento, por lo que combinarlos lo cuenta dos veces.

## 3. Conservar la dirección y el registro absoluto

La [CapoSkill de GA](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs) en la revisión fijada calcula la fundamental sonora como la fundamental de la forma más la cejilla, y la fundamental de la forma como la fundamental sonora menos la cejilla, módulo 12. Conserva la cualidad mayor o menor en los casos admitidos y acepta posiciones enteras de cejilla de 0 a 12. El código seleccionado no contiene ninguna tabla de trastes por cuerda ni cálculo de colocación física.

Tres [sondeos reales de la herramienta teórica](../../../../code/streeling/evidence/capo-spelling-2026-10-22/theory-tool-probes.json) devolvieron D para C subiendo 2, G para B bajando 4 y C para Bb subiendo 2. Se desconoce la revisión del servicio. No son ejecuciones de la habilidad inspeccionada ni de un adaptador de cejilla a trastes. Con cejilla en el traste 12, se repiten las clases de altura de una forma, pero sus notas sonoras suben una octava en nuestro modelo.

### Ejercicio 3: invertir la petición musical

Para obtener B mayor sonoro con cejilla en el traste 4, ¿qué fundamental y cualidad debe tener la forma bajo la convención declarada de nombres en inglés? ¿Una comparación limitada al módulo detectaría la octava ausente de la cejilla en el traste 12?

> **Respuesta:** La forma es G mayor porque `11-4=7`. El resultado observado de la herramienta para B bajando 4 concuerda en la fundamental; el código seleccionado de la habilidad trata la cualidad por separado. Una comparación limitada al módulo no puede detectar el cambio de registro de la cejilla en el traste 12: cada nota sonora sube 12 y conserva su clase de altura.

## 4. Separar las posiciones inválidas del estado silenciado

Con cejilla en el traste 2, el traste físico 5 corresponde al traste relativo 3, y el físico 2 al relativo 0. El traste físico 1 daría una distancia relativa negativa y queda fuera de este modelo de cejilla completa. Su diferencia aritmética de -1 no debe reinterpretarse como el marcador existente de cuerda silenciada.

Un ejemplo didáctico separado de cejilla parcial desplaza las cuerdas en `[0,2,2,2,2,2]`. Aplique los trastes relativos de la forma de E `[0,2,2,1,0,0]`: las notas sonoras son `[40,49,54,58,61,66]`. Una cejilla completa en el traste 2 da en cambio `[42,49,54,58,61,66]`. La cuerda más grave refuta una descripción por transposición uniforme de este ejemplo parcial.

### Ejercicio 4: conservar dos contraejemplos

Clasifique el traste físico 1 con cejilla en el traste 2. Después compare las dos tablas de notas sonoras de la forma de E e identifique por qué la transposición de la fundamental de todo el acorde no puede describir por completo el ejemplo parcial.

> **Respuesta:** El traste físico 1 está detrás de la cejilla completa declarada y es inválido aquí, no una cuerda silenciada deducida de la resta. El ejemplo parcial deja la nota más grave en 40, mientras que la cejilla completa da 42; las demás notas coinciden. Un desplazamiento uniforme de la fundamental no conserva esta distinción por cuerda. Ninguna tabla demuestra la precisión de la afinación ni la viabilidad física de la ejecución.

## 5. Leer el contrato de destino

El [analizador MusicXML](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L59-L78) en la revisión fijada almacena por separado la cuerda y el traste técnicos. Sus atributos seleccionados no conservan una cejilla. El [tipo RelativeFret](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Domain.Core/Instruments/Primitives/RelativeFret.cs#L9-L18) es una distancia genérica en trastes; su nombre no establece un origen en la cejilla. El [analizador de navegación](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/FretboardNavigationParser.fs#L25-L41) analiza coordenadas explícitas sin aplicar un desplazamiento de cejilla.

### Ejercicio 5: preparar una transferencia con ayuda de las fuentes

Lea esas fuentes y la [definición de cuerda en MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/string/). Especifique la información mínima necesaria para trasladar la tabla didáctica a otra herramienta sin adivinar su convención.

> **Respuesta:** Conserve la afinación, el orden y la numeración de cuerdas, la cobertura y los desplazamientos de la cejilla, el origen de los trastes, los estados silenciado o inválido, las alturas absolutas previstas y la revisión del código. En MusicXML, la cuerda 1 es la cuerda de longitud completa más aguda; nuestra tabla sigue el orden físico contrario. Convierta esa indexación explícitamente. Compare un pequeño registro tipado y cálculos comprobados antes de proponer un DSL. Siguen sin realizarse la importación, el renderizado, la reproducción y la revisión de la ejecución por un músico.

El [registro fijado de coordenadas](../../../../code/streeling/evidence/capo-spelling-2026-10-22/capo-coordinates.json) conserva los ocho casos de cejilla completa y el control parcial separado.
