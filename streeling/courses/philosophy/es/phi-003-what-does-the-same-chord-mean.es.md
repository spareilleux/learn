---
module_id: phi-003-what-does-the-same-chord-mean
department: philosophy
course: ¿Qué significa el mismo acorde en la búsqueda de GA?
level: early-intermediate
prerequisites: [phi-001-how-to-argue-well]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
research_cycle: philosophy-2026-10-12-003
version: "0.1.0"
---

# ¿Qué significa «el mismo acorde» en la búsqueda de GA?

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de traducciones todavía no redactadas, de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](../../../../code/streeling/evidence/representation-release-2026-10-22/README.md) documenta los borradores traducidos actuales, la importación y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Filosofía** | Nivel intermedio inicial | 40 minutos | Borrador en español; pendientes la revisión del contenido, una prueba con un estudiante y la revisión lingüística humana

## Objetivos y pregunta del proyecto

Aprenderás a distinguir tres significados de igualdad para acordes de guitarra, calcular un pequeño ejemplo de clases de altura e intervalos y elegir pruebas para una afirmación de búsqueda. **Pregunta del proyecto:** cuando GA dice a un guitarrista que dos voicings son «iguales» o «similares», ¿qué relación musical ha comprobado realmente? Sin una relación explícita, un algoritmo correcto puede responder a la pregunta musical equivocada.

[PHI-001](phi-001-how-to-argue-well.md) separa una conclusión de sus premisas. [PHI-002](phi-002-when-is-an-advisory-decision-justified.md) separa un registro válido de decisión de una acción justificada. Aquí aplicamos esa disciplina a una palabra del producto. «Igual» es una conclusión; notas MIDI, clases de altura, clases de intervalos y una puntuación de búsqueda son posibles premisas diferentes. El [esquema de dominio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/architecture/DOMAIN_SCHEMA.md) pertinente de GA distingue un `PitchClassSet` literal, un `IntervalClassVector` (ICV) y una clase de conjuntos relacionados por transposición o inversión. Debemos nombrar qué relación pide un guitarrista antes de elegir un método de búsqueda.

## 1. Cuatro perspectivas sobre una comparación de acordes

Un número de nota MIDI incluye el registro: C3 es 48 y C4 es 60. Una **clase de altura** toma el número de nota módulo 12, por lo que ambos se convierten en C (`0`). Un conjunto no ordenado de clases de altura olvida octava, duplicaciones y orden de las notas. Un ICV cuenta las clases de intervalos no ordenadas entre clases de altura distintas; olvida aún más. El [esquema de GA en `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs) coloca el croma literal de clases de altura con 12 componentes, la cardinalidad y un ICV de seis componentes dentro de `STRUCTURE`, y lleva la clase de altura de la fundamental declarada en una partición `ROOT` separada. El esquema advierte expresamente de que **la partición `STRUCTURE` completa no es invariante ante la transposición**. Sus subdimensiones ICV/cardinalidad tienen una invariancia diferente de la de su croma.

| Posible pregunta del guitarrista | Relación operativa | Qué olvida |
|---|---|---|
| «¿Son exactamente las mismas notas tocadas?» | Mismo multiconjunto de notas MIDI | Tiempo de interpretación y timbre, pero no octava |
| «¿Son las mismas clases de altura en otra posición?» | Mismo conjunto de clases de altura | Octava, duplicaciones, orden y registro |
| «¿Es una versión transpuesta o invertida?» | Una transposición o inversión explícita transforma un conjunto en el otro | Ubicación absoluta de las clases de altura |
| «¿Tienen el mismo contenido interválico?» | Mismo ICV de seis componentes | Clases de altura absolutas, fundamental y, quizá, distinciones entre clases de conjuntos diferentes |

Estas relaciones responden a preguntas diferentes. Conjuntos de clases de altura iguales tienen ICV iguales, pero la implicación inversa no tiene por qué cumplirse. Una coincidencia de ICV no debería convertirse silenciosamente en «el mismo nombre de acorde» o «la misma forma física». Un umbral de similitud es aún más débil: puede ordenar candidatos, pero no define por sí solo una clase de equivalencia matemática.

La [fixture didáctica fijada en Demerzel `50c0d2f`](https://github.com/GuitarAlchemist/Demerzel/tree/50c0d2f5eb6684499c3bcf95d77f0481af2cc136/state/streeling/fixtures/philosophy/phi-003) proporciona cinco listas cortas de notas MIDI y etiquetas explícitas de fundamental. Su script sin dependencias calcula conjuntos de clases de altura, seis recuentos de clases de intervalos, un **coseno simplificado de croma binario** y si existe una transposición o inversión exacta. Ejecuta `python state/streeling/fixtures/philosophy/phi-003/compare_voicings.py` desde la raíz de Demerzel. La fixture no es un embedding GA, una traza de búsqueda activa ni una prueba de comodidad de digitación.

### Ejercicio práctico 1

La fixture compara `c_major_low = [48,52,55]` con `c_major_high = [60,64,67]`. ¿Son iguales los multiconjuntos de notas MIDI? ¿Son iguales los conjuntos de clases de altura y los ICV? ¿Qué sigue sin demostrarse sobre dos digitaciones de guitarra?

> **Respuesta:** Los multiconjuntos de notas MIDI difieren en una octava. Ambos se convierten en el conjunto de clases de altura `{0,4,7}` y comparten, por tanto, el ICV `[0,0,1,1,1,0]`; su coseno simplificado de croma binario es `1`. La fixture no dice nada sobre elección de cuerdas, apertura de la mano, timbre, facilidad de ejecución ni sobre si los embeddings GA *completos* de 240 dimensiones y sus clasificaciones son iguales.

## 2. Una transposición no es identidad literal de clases de altura

`c_major_low` tiene las clases de altura `{0,4,7}`. Subir cada clase dos semitonos produce `d_major = {2,6,9}`. La fixture confirma una transposición exacta `+2` y el mismo ICV `[0,0,1,1,1,0]`. Sus conjuntos de croma binario no se solapan, por lo que su **coseno simplificado solo de croma es cero**. Ese cero no es el coseno de la partición `STRUCTURE` completa de GA. El [TheoryVectorService](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs) de GA combina croma con ICV, cardinalidad y otros valores; su propio comentario indica un coseno `STRUCTURE` no nulo para una tríada mayor transpuesta. La [herramienta fijada de exportación de invariancia](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tools/GaStructureInvariance/Program.cs) existe específicamente para probar esa partición sobre clases de conjuntos y las 12 transposiciones.

La distinción afecta a un flujo de trabajo real. «Muestra este acorde en otro registro» sugiere conservar las clases de altura mientras se examinan digitación y registro. «Toca esta forma en D» requiere transposición. «Busca material relacionado armónicamente» puede requerir una búsqueda basada en ICV. El [IcvNeighborsSkill](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs) fijado de GA utiliza la distancia ICV para buscar conjuntos cercanos de clases de altura; es una operación diferente de prometer que todo el embedding OPTIC-K sea invariante ante la transposición. Una etiqueta del producto debería mostrar lo suficiente de la relación para que un guitarrista juzgue el resultado.

### Ejercicio práctico 2

Para `c_major_low` y `d_major`, nombra una relación que se cumpla y dos que no. ¿Por qué el coseno de croma cero de la fixture sería una respuesta numérica incorrecta a «¿cuál es el coseno STRUCTURE completo de GA?»?

> **Respuesta:** Se cumplen la transposición exacta y la igualdad de ICV. No se cumplen la igualdad literal de multiconjuntos de notas MIDI ni la igualdad de conjuntos de clases de altura. La fixture calcula el coseno solo sobre bits de croma binario con el mismo peso, mientras que `STRUCTURE` de GA contiene componentes adicionales de ICV, cardinalidad y tonalidad. Un cero en esta proyección simplificada no puede sustituir a la partición completa de GA ni a la puntuación ponderada final de búsqueda.

## 3. Incluso fundamental y contenido interválico pueden ser insuficientes

Compara `c_major_low = {0,4,7}` con `c_minor = {0,3,7}`. Ambos tienen fundamental declarada C (`0`) e ICV `[0,0,1,1,1,0]`; la fixture encuentra una **inversión en el sentido de la teoría de conjuntos** `pc -> (-pc + 7) mod 12` que transforma un conjunto en el otro. Es una transformación de clases de altura, no una inversión de acorde de guitarra obtenida cambiando la nota del bajo. Los conjuntos difieren y su coseno simplificado de croma es `2/3` porque solo coinciden C y G. La fundamental declarada y el ICV juntos no identifican si la tercera es E o E bemol. Una etiqueta de fundamental en la fixture es una **entrada proporcionada**, no una fundamental inferida por el script. Esto importa cuando un acorde admite varias interpretaciones plausibles.

Para `c_diminished = {0,3,6}`, el ICV es `[0,0,2,0,0,1]`; difiere del de la tríada mayor pese a compartir fundamental C. Estas pequeñas comparaciones ofrecen un contraejemplo útil a «una representación captura todas las nociones de igualdad». No implican que el sistema GA completo confunda esos acordes. El embedding de GA contiene más que los dos campos examinados aquí y una afirmación real de búsqueda necesita una consulta, revisión de índice, ruta de puntuación y salida ordenada observada.

### Ejercicio práctico 3

Alguien propone una clave `(root_pc, ICV)` como identificador único de acorde. Pruébala con `c_major_low` y `c_minor`. ¿Qué campo adicional de `STRUCTURE` de GA ayuda a distinguir los ejemplos?

> **Respuesta:** Ambos ejemplos tienen fundamental proporcionada `0` y el mismo ICV de seis componentes, por lo que la clave propuesta colisiona aunque `{0,4,7} != {0,3,7}`. El croma literal de clases de altura distingue E de E bemol. Este contraejemplo rechaza la unicidad de esa clave de dos campos; no mide la fiabilidad del vector completo de GA.

## 4. Decidir qué puede afirmar una declaración de similitud

La igualdad de conjuntos exactos de clases de altura es reflexiva, simétrica y transitiva. Una similitud con umbral puede incumplir la transitividad: una tabla sintética de puntuaciones podría tener `sim(A,B)=0.8`, `sim(B,C)=0.8` y `sim(A,C)=0.5`. Con umbral `0.75`, A es «similar» a B y B a C, mientras que A no es «similar» a C. Llamar «iguales» a esos elementos conectados por umbral crearía una clase de equivalencia engañosa. Una interfaz práctica de búsqueda puede ordenar por puntuación, pero debería declarar el alcance de esa puntuación y evitar una afirmación universal de identidad.

Una pequeña propuesta de diseño **consultiva** consiste en preguntar qué comparación desea el usuario: conjunto exacto de clases de altura, transposición explícita, vecindad ICV u ordenación de voicings. El contraargumento más sólido es la complejidad añadida de interfaz: muchos guitarristas solo quieren una alternativa tocable y no desean cuatro controles técnicos. Una alternativa más sencilla es una búsqueda normal con una explicación clara en cada resultado, como «mismas clases de altura; distinto registro» o «mismo contenido interválico tras transposición». El criterio para rechazar el control extra es una prueba con estudiantes donde añada fricción sin mejorar la tarea ni reducir elecciones equivocadas. Aquí no se ha realizado ninguna prueba de usuario así.

### Ejercicio práctico 4

Con un umbral sintético `0.75`, las similitudes son A–B `0.8`, B–C `0.8` y A–C `0.5`. ¿Puede «puntuación al menos 0.75» ser una relación de equivalencia? Nombra la propiedad incumplida.

> **Respuesta:** No. A está relacionado con B y B con C, pero A no está relacionado con C, así que falla la transitividad. Una ordenación o vecindad puede seguir siendo útil; no debe describirse como una clase matemática de acordes idénticos solo con esta regla.

### Ejercicio práctico 5

Un guitarrista pide «muestra las mismas notas más arriba en el mástil» y después «transpón esto a D». ¿Qué relación debería probar un prototipo para cada petición y qué observación refutaría que una búsqueda genérica resuelva bien ambas?

> **Respuesta:** Para la primera petición, conservar el conjunto de clases de altura y evaluar alternativas tocables de octava o registro; para la segunda, aplicar una transposición explícita a la tonalidad de destino y verificar las clases resultantes. Una tarea controlada con estudiantes donde los usuarios elijan repetidamente resultados con clases de altura, tonalidad o propósito de digitación equivocados refutaría que la etiqueta genérica de resultados sea suficiente. Prueba consultas GA reales y salidas ordenadas antes de afirmar un comportamiento del producto; la fixture por sí sola no puede demostrarlo.

## Fuentes, límites y próxima comprobación

Las referencias de implementación vinculadas al código fuente son [EmbeddingSchema](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs), [TheoryVectorService](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs), la [herramienta de exportación de invariancia](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tools/GaStructureInvariance/Program.cs), el [skill de vecinos ICV](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs) y el [esquema de dominio](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/architecture/DOMAIN_SCHEMA.md) de GA, todos en `dc2e74cbd992a298f67efb928b5b3754615e1924`. La [fixture didáctica determinista](https://github.com/GuitarAlchemist/Demerzel/tree/50c0d2f5eb6684499c3bcf95d77f0481af2cc136/state/streeling/fixtures/philosophy/phi-003) solo calcula las relaciones sencillas indicadas. No instancia el servicio de vectores GA, consulta un índice OPTIC-K actual, prueba digitaciones físicas ni entrevista a un guitarrista. Siguen pendientes la revisión humana del contenido, un intento ciego de un estudiante, la revisión lingüística humana de este borrador en español y la lectura pública.
