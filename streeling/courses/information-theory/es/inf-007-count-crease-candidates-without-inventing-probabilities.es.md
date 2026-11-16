---
module_id: inf-007-count-crease-candidates-without-inventing-probabilities
department: information-theory
course: "Contar candidatos de pliegues sin inventar probabilidades"
level: intermediate
prerequisites: ["inf-001-entropy-of-governance", "phy-010-check-local-flat-fold-angles"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Contar candidatos de pliegues sin inventar probabilidades

> **Alcance del borrador.** Asignaciones etiquetadas exhaustivas y modelos de probabilidad explícitos creados para el curso, con inspección de código fijado a una revisión. Quedan pendientes las revisiones humanas técnica, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se midieron una tasa de éxito de agentes, una resolución completa de origami, una ejecución de Rust ni una exportación de escena.

## La pregunta del proyecto

Un agente de búsqueda creativa informa de que una restricción eliminó la mitad de sus candidatos. ¿Cuánta incertidumbre eliminó y qué significa un candidato superviviente? Usa el entorno de grado cuatro de [PHY-010](../../physics/en/phy-010-check-local-flat-fold-angles.md): sectores cíclicos de 60, 90, 120 y 90 grados, con etiquetas de pliegues de e0 a e3. La condición angular geométrica está fijada y satisfecha; solo varían las etiquetas montaña/valle.

La [función auxiliar local de IX de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs) implementa filtros angulares y de recuento, no la regla adicional del ángulo menor usada en este cálculo didáctico. El [registro de enumeración](../../../../code/streeling/evidence/origami-local-2026-10-22/assignment-enumeration.json) enumera todos los candidatos y ambos predicados por separado. No es la salida de un solucionador completo.

## 1. Contar las opciones etiquetadas antes de filtrar

Cada uno de los cuatro pliegues tiene dos opciones binarias, lo que da `2^4=16` cadenas etiquetadas. Conserva la identidad del pliegue: permutar las etiquetas puede cambiar si bordean el ángulo menor. No tomamos clases de equivalencia por simetría ni identificamos una cadena con su inversión montaña/valle.

Elige ahora explícitamente una distribución uniforme didáctica sobre esas cadenas. Cada una tiene probabilidad `1/16`; la entropía de Shannon es 4 bits. La [definición primaria de entropía](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf#page=11) usa el negativo de una suma logarítmica ponderada por probabilidades. Con base 2, `H(X)=-sum(p_i*log2(p_i))`; un conjunto uniforme de N opciones da `log2(N)`. Contar posibilidades por sí solo no establece la distribución real de un agente ni de un proceso físico.

### Ejercicio 1: declarar el conjunto probabilístico

¿Cuántas asignaciones etiquetadas existen y qué entropía se obtiene bajo la distribución previa uniforme didáctica? ¿Demostraría el mismo recuento por sí solo que un agente real muestrea todas las cadenas con la misma frecuencia?

> **Respuesta:** Hay 16 asignaciones, con probabilidad `1/16` cada una y entropía 4 bits bajo la distribución previa declarada. El recuento no establece una distribución real de muestreo; las probabilidades iguales son una hipótesis explícita del ejercicio.

## 2. Condicionar a los filtros declarados

La condición de recuento de Maekawa conserva asignaciones con tres montañas y un valle, o a la inversa. Hay `4+4=8`. Condicionar la distribución previa uniforme a este evento da probabilidad `1/8` por cadena superviviente y entropía 3 bits.

El mínimo estricto de 60 grados está entre e0 y e1. Aplicar la regla necesaria adicional de etiquetas opuestas conserva cuatro supervivientes del recuento: `MVMM`, `MVVV`, `VMMM` y `VMVV`. Condicionada a superar ambos filtros, cada una tiene probabilidad `1/4` y la entropía es 2 bits. Es una reducción a lo largo de la rama aceptada. Un superviviente significa que pasó los filtros indicados; no es un estado plegado exportado, un éxito físico medido ni una prueba de viabilidad global.

### Ejercicio 2: contar las dos reducciones

Indica el recuento y la entropía uniforme condicional después del filtro de recuento y después de ambos filtros. ¿Por qué sería incorrecto llamar a los primeros ocho candidatos «ocho plegados verificados»?

> **Respuesta:** El filtro de recuento deja 8 candidatos y 3 bits; ambos filtros dejan 4 y 2 bits. El primer conjunto incluye asignaciones como `MMMV` que violan la restricción adicional del ángulo menor. Ninguna etapa de filtrado proporciona un testigo completo de estado plegado ni una observación física, así que ocho supervivientes del recuento no son ocho plegados verificados.

## 3. Separar cardinalidad de entropía

Para esas mismas cuatro identidades finales de candidatos, elige otra distribución didáctica: probabilidades `1/2`, `1/4`, `1/8` y `1/8` en el orden enumerado. Su entropía es 1.75 bits, mientras la distribución uniforme sobre las mismas identidades tiene 2 bits. El número de estados no ha cambiado.

El [registro de información fijado](../../../../code/streeling/evidence/origami-local-2026-10-22/candidate-information.json) conserva ambas distribuciones. Sin pruebas sobre las probabilidades, `log2(N)` es la entropía máxima sobre N posibilidades, no una entropía observada. A la inversa, una entropía baja no certifica que el candidato probable sea correcto o fabricable.

### Ejercicio 3: calcular una distribución no uniforme

Calcula la entropía para probabilidades `1/2`, `1/4`, `1/8` y `1/8`. ¿Cuál es la cota superior basada en la cardinalidad? ¿Mide la diferencia una mejora de calidad de plegado?

> **Respuesta:** Las contribuciones son `0.5+0.5+0.375+0.375=1.75` bits. La cota superior para cuatro estados es 2 bits. La diferencia refleja esta concentración didáctica de probabilidad, no mejor calidad de plegado, calibración observada de agentes ni un resultado físico.

## 4. Separar una rama seleccionada del promedio

El clasificador didáctico determinista emite una de tres etiquetas. Ocho cadenas fallan la regla de recuento; cuatro pasan el recuento pero fallan la regla del ángulo menor; cuatro superan ambas. Bajo la distribución previa uniforme, las probabilidades de esas etiquetas son `1/2`, `1/4` y `1/4`.

La entropía media de asignación restante tras conocer esa etiqueta general es `0.5*3+0.25*2+0.25*2=2.5` bits. La propia etiqueta aporta 1.5 bits y `4=1.5+2.5`. Seleccionar solo la rama aceptada deja 2 bits, pero esa rama no es el promedio de todas las entradas. Informar de una reducción media de 2 bits mirando solo entradas aceptadas cambiaría silenciosamente el condicionamiento.

### Ejercicio 4: incluir las ramas rechazadas

Calcula la entropía restante esperada usando los tamaños y probabilidades de las tres categorías. ¿Cuál es la información media de la etiqueta general? ¿Por qué el resto de 2 bits de la rama aceptada es otra estadística?

> **Respuesta:** El resto esperado es 2.5 bits, así que la etiqueta aporta `4-2.5=1.5` bits de media. El resto de 2 bits de la rama aceptada está condicionado a ese evento concreto, cuya probabilidad previa es `1/4`; no es el promedio ponderado de las ramas rechazadas y aceptadas.

## 5. Conservar identidades y significado de predicados en un traspaso

Una etiqueta general de aprobación no permite reconstruir qué asignación pasó. En el conjunto de ocho supervivientes del recuento, una descripción uniforme condicional aún tiene 3 bits de incertidumbre de asignación. Un agente que necesite colocar pliegues concretos debe conservar el etiquetado real y la geometría en lugar de recibir solo «comprobaciones locales superadas». El desconocido `U` de la [especificación FOLD de la revisión fijada](https://raw.githubusercontent.com/edemaine/fold/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md) es otra categoría de entrada; no significa automáticamente un sorteo binario equiprobable entre M y V.

Un traspaso de alto nivel propuesto puede indicar las identidades de candidatos, el orden de coordenadas, los predicados probados, los dominios omitidos y el modelo de probabilidad explícito cuando exista. Es una tarea de conservación de información, no una exigencia de crear un lenguaje nuevo. Un informe tipado sencillo puede bastar. Mide errores reales de selección o coste de búsqueda antes de afirmar que un DSL o un conjunto menor de candidatos mejoró el proceso de agentes.

### Ejercicio 5: corregir un resumen pobre en información

Un agente envía solo «recuento superado; ocho posibilidades; 3 bits», mientras el destinatario necesita seleccionar un patrón concreto de pliegues etiquetados. ¿Qué se perdió y qué hipótesis da los 3 bits? ¿Puede una etiqueta de entrada desconocida tratarse automáticamente como el mismo modelo de probabilidad?

> **Respuesta:** Se perdieron la asignación concreta y su relación con los identificadores geométricos de pliegues. Tres bits describen el conjunto uniforme condicional de los ocho supervivientes del recuento, no una distribución observada. Una etiqueta desconocida no aporta una distribución previa de probabilidad ni una asignación completada. Envía las identidades y el alcance de los predicados, y declara el modelo de probabilidad o déjalo desconocido; el plegado completo y los resultados de escena siguen sin observarse.
