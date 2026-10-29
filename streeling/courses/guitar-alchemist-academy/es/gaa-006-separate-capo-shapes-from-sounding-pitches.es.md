---
module_id: gaa-006-separate-capo-shapes-from-sounding-pitches
department: guitar-alchemist-academy
course: "Distinguir las posiciones de acordes con capo de las alturas reales"
level: early-intermediate
prerequisites: ["gaa-004-choose-a-useful-voicing", "wml-005-declare-note-name-conventions"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguir las posiciones de acordes con capo de las alturas reales

> **Alcance del borrador.** Código público de GA fijado a una revisión, respuestas reales de la herramienta de transposición de acordes y 312 casos de aritmética de clases de altura creados para el curso. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML del curso desplegado. Para esta lección no se ejecutaron CapoSkill ni una ruta de enrutamiento de la aplicación, ni se probó con una guitarra física.

## La pregunta del proyecto

Un guitarrista conoce el acorde que necesita el cantante, pero quiere usar una posición familiar con capo. Otro conoce la posición y pregunta qué oirá el grupo. Estas preguntas recorren la misma relación en sentidos opuestos. El [CapoSkill](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs) público de GA, fijado en `dc2e74cbd992a298f67efb928b5b3754615e1924`, distingue explícitamente ambos casos.

Usa aquí nombres de notas ingleses, aritmética de semitonos en temperamento igual y un capo ordinario que cubra todas las cuerdas. Un capo parcial, otra afinación, los límites de trastes y una digitación real necesitan información adicional. [WML-005](../../world-music-languages/en/wml-005-declare-note-name-conventions.md) explica por qué una B sin convención especificada debe interpretarse antes de cualquier cálculo.

## 1. Sumar para predecir el sonido; restar para elegir una posición

Con C como clase de altura 0, la clase real es la clase de la posición más el traste del capo, reducida módulo 12. Para elegir una posición que produzca el sonido solicitado, resta el traste del capo y reduce a una clase no negativa. La habilidad de la revisión fijada valida trastes de 0 a 12; esta restricción del código fuente es distinta del alcance físico de cada guitarra o de todas las ubicaciones posibles del capo.

Las [pruebas reales de transposición de GA](../../../../code/streeling/evidence/pitch-context-2026-10-22/theory-tool-probes.json) devolvieron C# para B subido 2 y Gm para Bm bajado 4. Son llamadas a la herramienta de transposición de acordes, con una revisión del servicio desconocida. No son ejecuciones del CapoSkill de la revisión fijada ni prueba de que una petición en inglés o francés llegue a él.

### Ejercicio 1: identificar la dirección

¿Qué suena al tocar una posición de B mayor con capo 2? ¿Qué posición menor produce B menor real con capo 4? Indica los cálculos de clases de altura.

> **Respuesta:** La posición de B mayor da C# mayor: `(11+2)%12 = 1`. B menor real con capo 4 requiere G menor: `(11-4)%12 = 7`. La suma predice el sonido a partir de una posición; la resta elige la posición a partir del sonido deseado.

## 2. Conservar la cualidad al mover la fundamental

En esta lección, una tríada mayor tiene intervalos relativos de semitonos 0, 4 y 7; una tríada menor tiene 0, 3 y 7. Añadir el mismo desplazamiento a cada nota conserva esos intervalos relativos. El [paquete de aritmética fijada](../../../../code/streeling/evidence/pitch-context-2026-10-22/capo-arithmetic.json) enumera 12 clases iniciales, 13 posiciones de capo y 2 cualidades, lo que da 312 casos. Cada uno recupera su clase inicial con la operación inversa y conserva los intervalos de tríada declarados.

Es una comprobación aritmética finita. No mide la comodidad de la digitación, no demuestra compatibilidad con todas las extensiones de símbolos de acordes ni establece que un músico haya producido el sonido previsto. En particular, sustituir la posición de G menor del ejercicio anterior por G mayor cambia la cualidad solicitada aunque la clase de la fundamental sea correcta.

### Ejercicio 2: detectar un error de cualidad

Para obtener B menor real con capo 4, compara una posición de G menor con una de G mayor. Indica la lista de intervalos relativos resultante de cada una. ¿Por qué es insuficiente comprobar solo la fundamental?

> **Respuesta:** G menor conserva los intervalos 0, 3, 7 y produce B menor. G mayor conserva 0, 4, 7 y produce B mayor. Ambas alcanzan la clase de fundamental 11; una comprobación solo de la fundamental no detecta el cambio de tercera y, por tanto, de cualidad.

## 3. Una clase de altura no conserva una octava

El capo 12 devuelve la misma clase de altura. No devuelve la misma altura absoluta. El control de registro creado para el curso parte del E grave al aire en MIDI 40 y añade 12 para obtener 52, E una octava más alto. Ambos se reducen a la clase 4. Por tanto, una respuesta sobre el capo expresada como fundamental de acorde es insuficiente cuando otro agente necesita un número concreto de nota real.

El [TabToPitchConverter](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/TabToPitchConverter.cs) de GA en la revisión fijada combina por separado los desplazamientos de la afinación estándar con las posiciones de trastes; la conversión inspeccionada no tiene parámetro de capo. Esta observación del código fuente no es una nueva ejecución del convertidor. No supongas que la presencia de aritmética de capo en otro lugar significa que todas las rutas de tablatura la aplican.

### Ejercicio 3: conservar el registro

El control parte de 40 con capo 12. Indica el número absoluto resultante y ambas clases de altura. ¿Puede una respuesta de solo «E» mostrar que la octava es correcta?

> **Respuesta:** El resultado absoluto es 52; ambas clases de altura son 4. «E» por sí solo no distingue 40 de 52. Conserva la nota absoluta o el registro cuando la tarea receptora necesite la altura real en lugar de solo una fundamental de acorde.

## 4. Separar normalización, transposición y grafía

Para un B alemán declarado, normaliza primero a Bb inglés, clase 10. El capo 2 produce entonces la clase 0, C. Para un B inglés, el mismo capo produce la clase 1, C#. La [tabla de decisiones lingüísticas](../../../../code/streeling/evidence/pitch-context-2026-10-22/language-decisions.json) conserva estas entradas por separado. Una aritmética de capo correcta no puede recuperar una convención de nombres descartada antes de ejecutarla.

La grafía enarmónica de salida es otra decisión. Una posición de C con capo 3 da la clase 3, que puede nombrarse Eb o D# en este cálculo de temperamento igual. La habilidad de la revisión fijada elige una preferencia de grafía a partir de la entrada; la grafía de una herramienta de transposición no establece necesariamente cómo respondería esa habilidad a cada frase en lenguaje natural. Conserva el contexto musical cuando importe la notación, en lugar de tratar la igualdad de clases como una regla universal de escritura.

### Ejercicio 4: explicar dos discrepancias distintas

Compara C con C# después de interpretar B según las dos convenciones declaradas con capo 2. Después compara Eb con D# para una posición de C con capo 3. ¿Son el mismo tipo de discrepancia?

> **Respuesta:** No. C y C# tienen clases distintas, 0 y 1, porque el B de la fuente se interpretó de forma diferente. Eb y D# comparten la clase 3 en el cálculo de temperamento igual declarado, pero difieren en la grafía. Los errores de interpretación y las decisiones de grafía enarmónica requieren explicaciones distintas.

## 5. Componer operaciones después de declarar sus dominios

Supón que una nota escrita creada para el curso tiene coordenada 64, una transposición explícita del instrumento de -1 octava y un desplazamiento de capo declarado por separado de 2 semitonos que aún no se ha codificado. El cálculo es `64-12+2 = 54`. Es un caso de prueba aritmético compuesto deliberadamente; no afirma que una partitura real siempre deba sumar un desplazamiento de capo aparte. Una partitura o tablatura puede codificar ya sus alturas reales. Examina esa política antes de aplicar otro ajuste.

[MCL-005](../../musicology/en/mcl-005-preserve-written-and-sounding-pitch.md) muestra cómo un analizador puede descartar metadatos de transposición. Un traspaso útil entre agentes indica la convención de nombres, si el objetivo es una posición o una altura real, la cualidad, la posición del capo, el registro cuando haga falta, qué ajustes se han aplicado ya y el alcance de las pruebas. Es una propuesta de lista de comprobación para la tarea, no un nuevo esquema impuesto al repositorio.

### Ejercicio 5: evitar contar un desplazamiento dos veces

Calcula el control compuesto declarado a partir de 64, -1 octava y un capo 2 aún sin aplicar. Si un valor entrante ya es la altura real final 54, ¿debe un agente sumar 2 de nuevo? Indica la pregunta que debe resolver primero.

> **Respuesta:** El control da 54. Sumar 2 a un 54 real ya final daría 56 y contaría el capo dos veces. Establece si la altura entrante ya incluye el capo y la transposición del instrumento, y si la salida solicitada describe una posición, una altura escrita o un sonido.

## Tarea del estudiante con acceso a las fuentes

Completa la [tarea preparada](../../../../code/streeling/evidence/pitch-context-2026-10-22/learner-task.md) con las pruebas fijadas y una calculadora. Explica la dirección, la cualidad, el registro y la política de codificación antes de proponer una respuesta para el músico. Siguen pendientes la ejecución instrumental real, las respuestas de estudiantes y las decisiones de revisión humana.
