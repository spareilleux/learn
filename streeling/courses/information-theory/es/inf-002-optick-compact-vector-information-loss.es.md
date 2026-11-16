---
module_id: inf-002-optick-compact-vector-information-loss
department: information-theory
course: Pérdida de información en los vectores compactos OPTIC-K
level: intermediate
prerequisites: [inf-001-entropy-of-governance]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: information-theory-2026-10-11-002
version: "0.1.0"
---

# Pérdida de información en los vectores compactos OPTIC-K

> **Alcance de la fuente y la transferencia.** El texto técnico siguiente procede de un borrador archivado. Las menciones históricas de una importación o compilación pendiente en Learn corresponden a aquella etapa; este [registro de transferencia](../../../../code/streeling/evidence/agentic-composition-2026-10-22/README.md) documenta la importación actual y sus comprobaciones. Las demás experiencias indicadas como no realizadas siguen pendientes. Aún faltan la revisión humana del contenido y del idioma, y la prueba con un estudiante.

> **Departamento de Teoría de la Información** | Nivel: intermedio | Duración estimada: 35 minutos | Estado: borrador en español; pendientes la revisión del contenido, una prueba con un estudiante, la revisión lingüística humana y la revisión previa a la publicación

## Objetivos

Después de esta lección podrás:

- Indicar qué información conserva, descarta y normaliza GA al construir un vector compacto de similitud OPTIC-K.
- Convertir un desplazamiento en el esquema bruto de 240 posiciones de GA a su distribución compacta de 124 posiciones sin mezclar los dos sistemas de coordenadas.
- Mostrar dos vectores brutos distintos con el mismo vector compacto y explicar por qué eso demuestra que la reconstrucción única es imposible.
- Comprobar una afirmación de similitud ponderada con una fixture fija y señalar qué **no** dice esa comprobación sobre la búsqueda completa.

## La pregunta del proyecto

GA almacena embeddings musicales para buscar voicings. Su [`EmbeddingSchema.cs` fijado](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs) declara `OPTIC-K-v1.8`, un vector bruto de 240 dimensiones, los roles de las particiones, los pesos y la operación `ExtractCompact`. Un índice compacto debería conservar el cálculo de similitud que necesita su lector. Pero ¿qué puede deducir un lector sobre el vector bruto original después de esta transformación?

Esta es la pregunta refutable: **si dos vectores brutos producen el mismo vector compacto, ¿tienen que contener los mismos datos musicales y de identidad?** La respuesta es no. Construiremos tres contraejemplos explícitos. Esto importa cuando un agente inspecciona un artefacto de búsqueda: una entrada de índice compacto aporta pruebas sobre una representación concreta para calcular puntuaciones, no una copia de todas las características originales. La distinción también evita que un ingeniero trate dos puntuaciones compactas iguales como prueba de que una solicitud de búsqueda completa, incluidos los posibles filtros, se comporta de forma idéntica.

[INF-001](inf-001-entropy-of-governance.md) estimó la incertidumbre en secuencias de tokens de políticas. Esta lección utiliza otra idea de teoría de la información: una **aplicación de muchos a uno**. Si entradas distintas se convierten en la misma salida, la salida no puede determinar de forma única la entrada. Contar dimensiones señala una posible pérdida, pero el contraejemplo es la prueba. Incluso una representación con el mismo número de posiciones podría perder información mediante la normalización.

## 1. Leer el contrato fijado, además del número de posiciones

El [registro de particiones](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L117-L148) del esquema asigna a cada intervalo bruto un inicio y un final inclusivos, un rol y un peso de similitud. Las particiones `Similarity` se empaquetan en el orden del registro. Las particiones `Identity` e `Info` no aparecen en el vector compacto. La tabla siguiente calcula los desplazamientos compactos sumando las dimensiones conservadas; esos desplazamientos **no** son desplazamientos brutos.

| Partición | Posiciones brutas | Rol | Peso | Posiciones compactas |
|---|---:|---|---:|---:|
| IDENTITY | 0–5 | Identity | 0 | omitida |
| STRUCTURE | 6–29 | Similarity | 0.45 | 0–23 |
| MORPHOLOGY | 30–53 | Similarity | 0.25 | 24–47 |
| CONTEXT | 54–65 | Similarity | 0.20 | 48–59 |
| SYMBOLIC | 66–77 | Similarity | 0.10 | 60–71 |
| EXTENSIONS | 78–95 | Info | 0 | omitida |
| SPECTRAL | 96–108 | Info | 0 | omitida |
| MODAL | 109–148 | Similarity | 0.10 | 72–111 |
| HIERARCHY | 149–163 | Info | 0 | omitida |
| ATONAL_MODAL | 164–227 | Info | 0 | omitida |
| ROOT | 228–239 | Similarity | 0.05 | 112–123 |

Las seis anchuras conservadas suman `24 + 24 + 12 + 12 + 40 + 12 = 124`. Las cinco omitidas suman `6 + 18 + 13 + 15 + 64 = 116`. Juntas cubren las 240 posiciones brutas. Es un recuento de coordenadas, **no** de bits ni una relación de compresión medida: para afirmar algo sobre almacenamiento habría que especificar la precisión numérica, las cabeceras y el formato del archivo de índice. El código construye una cadena de distribución que comienza por `optk-v4-pp-r:` y calcula su hash para comprobar la compatibilidad del esquema. Un lector debería establecer esa versión y distribución antes de interpretar los bytes del índice; el ejercicio siguiente no abre un índice de producción.

### Ejercicio práctico 1: contar cada posición

Usando extremos inclusivos, ¿cuántas coordenadas aporta MODAL? ¿Cuántas coordenadas brutas quedan fuera del vector compacto? ¿Está justificada la afirmación «116 bits perdidos»?

> **Respuesta:** MODAL aporta `148 - 109 + 1 = 40` coordenadas. Las anchuras conservadas suman 124, así que se omiten `240 - 124 = 116` coordenadas brutas. «116 bits perdidos» no está justificado porque cada coordenada es un valor numérico, no un bit, y la normalización también pierde información dentro de las particiones conservadas.

### Ejercicio práctico 2: cambiar de sistema de coordenadas

¿Dónde terminan las posiciones brutas ROOT 228 y 239 en la distribución compacta? ¿La posición compacta 112 designa la posición bruta 112?

> **Respuesta:** ROOT empieza después de 112 coordenadas conservadas, por lo que la posición bruta 228 pasa a la compacta 112 y la bruta 239 a la compacta 123. La posición compacta 112 es la primera coordenada ROOT, mientras que la posición bruta 112 está dentro de MODAL. Una etiqueta debe indicar qué sistema de coordenadas utiliza.

## 2. Qué conserva la transformación

[`ExtractCompact`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L235-L266) lee por separado cada partición de similitud. Para un segmento de partición no nulo, divide cada valor por la norma euclídea de ese segmento y lo multiplica por la raíz cuadrada del peso de la partición. Después añade el segmento escalado al vector compacto. Un segmento nulo aporta ceros. En símbolos, para una partición de similitud `p` con segmento bruto `x_p` y peso `w_p`, el segmento compacto no nulo es:

```text
c_p(x) = sqrt(w_p) * x_p / ||x_p||_2
```

El resultado conserva la **dirección** de cada segmento de similitud no nulo y su peso asignado. Descarta la magnitud positiva original del segmento. Un cambio de escala positivo de un segmento produce el mismo segmento compacto, siempre que siga siendo no nulo. También descarta los valores de los roles no seleccionados por `SimilarityPartitions`. Ninguno de los dos tipos de pérdida puede revertirse solo a partir de las coordenadas compactas.

El [calculador de puntuación ponderada](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L269-L302) suma `w_p * cosine(a_p, b_p)` sobre las particiones de similitud. Para vectores de longitud completa y segmentos no nulos, el producto escalar de los dos vectores compactos es igual a esa suma ponderada, dentro de la precisión de los pesos almacenados. La [prueba de contrato del esquema fijada](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.ML.Tests/SchemaLayoutContractTests.cs#L31-L50) comprueba esa relación con tolerancia de `1e-6` para entradas deterministas no nulas. La prueba es evidencia en el código fuente del contrato previsto; esta lección no afirma haber vuelto a ejecutar las pruebas C#.

Es una **representación que conserva la puntuación para la función de similitud definida**, no un archivo de propósito general del embedding bruto. «Conserva la similitud» necesita esa precisión. Una aplicación puede usar IDENTITY para filtrado estricto, otros campos para visualización o análisis, o una ruta de búsqueda diferente. La igualdad de estos vectores compactos por sí sola no puede demostrar la igualdad de los resultados completos de búsqueda ni del significado musical.

## 3. Una fixture sintética fija

Los siguientes vectores son **datos construidos para el aula**, no embeddings de guitarra observados ni entradas almacenadas en un índice. Las 240 posiciones empiezan en cero. `A` pone 1 en la primera posición de cada partición de similitud: las posiciones brutas `6, 30, 54, 66, 109, 228`. También pone 1 en la posición IDENTITY `0` y en la posición EXTENSIONS `78`. `B` copia los valores de similitud de A, pero mueve el 1 de IDENTITY de la posición bruta `0` a la `1` y el 1 de EXTENSIONS de la posición bruta `78` a la `79`. `C` copia A salvo que el 1 de ROOT se mueve de la posición bruta `228` a la `229`. `D` copia A salvo que la posición bruta STRUCTURE `6` cambia de 1 a 2.

Un cálculo independiente en Python leyó las filas de particiones de la **revisión fijada del código fuente de GA** y reprodujo la normalización por partición de `ExtractCompact` y el coseno ponderado para estas entradas. Obtuvo los valores siguientes; son cálculos de fixture, no una medición de búsqueda en producción. Las puntuaciones se muestran con dos decimales porque los pesos de coma flotante y las raíces cuadradas pueden introducir pequeñas diferencias de redondeo.

| Pareja | Relación bruta | Relación compacta | Puntuación ponderada | Producto escalar compacto |
|---|---|---|---:|---:|
| A/A | idénticos | idénticos | 1.15 | 1.15 |
| A/B | IDENTITY y EXTENSIONS difieren | idénticos | 1.15 | 1.15 |
| A/C | las direcciones one-hot de ROOT difieren | distintos | 1.10 | 1.10 |
| A/D | la magnitud de STRUCTURE difiere | idénticos | 1.15 | 1.15 |

Cada vector tiene un valor no nulo en cada partición de similitud. Las seis contribuciones de autocomparación son, por tanto, `0.45 + 0.25 + 0.20 + 0.10 + 0.10 + 0.05 = 1.15`. Una puntuación superior a 1 no es un error aquí: esta suma ponderada no es una probabilidad y los pesos del registro fijado suman 1.15. En A/C, los vectores one-hot de ROOT son ortogonales, por lo que su contribución baja de 0.05 a cero mientras las demás permanecen fijas.

### Ejercicio práctico 3: la omisión produce una colisión real

¿Puede el vector compacto distinguir A de B? ¿Puedes concluir que una solicitud completa de búsqueda GA trata A y B de forma idéntica?

> **Respuesta:** Ninguna coordenada compacta puede distinguirlos porque sus seis segmentos de similitud son iguales; ambos vectores compactos y sus puntuaciones ponderadas son iguales. Sus vectores brutos difieren en IDENTITY y EXTENSIONS, lo que demuestra que la reconstrucción de compacto a bruto no es única. Una solicitud completa de búsqueda podría usar IDENTITY como filtro estricto, así que no se deduce la equivalencia de la búsqueda completa.

### Ejercicio práctico 4: pérdida dentro de una partición conservada

¿Por qué D tiene el mismo vector compacto que A aunque se conserve STRUCTURE? ¿Cambiar la posición bruta 6 de 1 a 0 tendría la misma explicación?

> **Respuesta:** El segmento STRUCTURE de A tiene norma 1; el de D tiene norma 2. Al dividir cada uno por su propia norma se obtiene la misma dirección unitaria, y después ambos reciben la misma escala `sqrt(0.45)`. Cambiar 1 a 0 produciría, en cambio, un segmento STRUCTURE totalmente nulo, que el código deja a cero, por lo que ese cambio alteraría el vector compacto y su puntuación. La pérdida de magnitud positiva es la colisión demostrada.

### Ejercicio práctico 5: formular una predicción refutable

Antes de leer la tabla de la fixture, predice `WeightedPartitionCosine(A,C)` y el producto escalar compacto. Indica una observación concreta que refutaría tu predicción con el algoritmo fijado.

> **Respuesta:** Los cinco segmentos de similitud sin cambios aportan `0.45 + 0.25 + 0.20 + 0.10 + 0.10 = 1.10`; los segmentos ROOT ortogonales aportan cero, por lo que ambos cálculos deberían dar aproximadamente **1.10** y coincidir dentro de la tolerancia de coma flotante. Una puntuación A/C calculada cercana a 1.15, con las posiciones no nulas especificadas y los pesos fijados, refutaría la construcción de la fixture o el comportamiento de puntuación declarado y requeriría inspeccionar el código fuente y el cálculo.

## 4. Límites y próxima comprobación

La fixture demuestra una propiedad limitada de la aplicación para una revisión fijada del código fuente. No prueba la serialización del índice, el rechazo de un hash de esquema, voicings reales de guitarra codificados, la construcción de consultas, el comportamiento de los filtros, los empates de clasificación ni el despliegue actual. Estos aspectos necesitan sus propios artefactos y pruebas. El código fuente fijado indica que STRUCTURE en su conjunto **no es invariante ante la transposición** porque contiene un croma de clases de altura; esta lección no usa sus ejemplos de igualdad compacta para afirmar lo contrario. El papel de ROOT aquí es el de una partición de similitud de 12 posiciones con peso bajo, no una prueba de que un músico concreto vaya a preferir un resultado.

Para investigar un índice real, registra el commit de GA, el hash de esquema de la cabecera del índice, los sistemas de coordenadas brutas y compactas, los filtros y los artefactos exactos de consulta y candidatos. Después compara el calculador de puntuación y el producto escalar compacto en ese caso fijo. Si discrepan más allá de la tolerancia del contrato, la siguiente acción útil es un informe reproducible de la discrepancia, no interpretar la puntuación como calidad musical. En el ciclo inglés original, la lección seguía siendo un borrador hasta completar la revisión del contenido, un intento de estudiante, la localización y la revisión previa a la publicación. Este borrador en español sigue pendiente de revisión del contenido, un intento de estudiante, revisión lingüística humana y revisión previa a la publicación.

## Fuentes fijadas

- [GA `EmbeddingSchema.cs` en `dc2e74cbd992a298f67efb928b5b3754615e1924`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs): versión y registro, distribución compacta, extracción y calculador de puntuación ponderada.
- [GA `SchemaLayoutContractTests.cs` en el mismo commit](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.ML.Tests/SchemaLayoutContractTests.cs): relación prevista entre producto escalar compacto y puntuación ponderada, suma de pesos de vectores idénticos y protección del desplazamiento ROOT.
