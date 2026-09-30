---
title: "13. Atención, normalización de capa y un bloque transformer"
description: "La atención y la normalización de capa escritas a mano, y luego el bloque transformer del crate ix-nn de IX comprobado frente a las fórmulas, las diferencias centradas y numpy, con nueve predicciones escritas antes de la primera ejecución: las nueve se cumplen. La pasada hacia delante es exacta; el backward actualiza las LayerNorm del bloque con el gradiente entero y sus otros pesos con la décima parte."
sidebar:
  order: 13
---

La lección 7 encontró que `Dense::backward` de IX divide por segunda vez entre el tamaño del batch (hallazgo 15), y la lección 12 mostró cómo una cinta calcula gradientes sin que nadie los derive. Un transformer reúne las dos preguntas: tiene más capas que la red de la lección 7, cada una con un backward escrito a mano. El crate [`ix-nn`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn) de IX, en el commit fijado, tiene las piezas: la atención por producto escalar escalado y la atención multicabeza, la normalización de capa, una red feed-forward y un bloque que las apila con conexiones residuales. Esta lección escribe la atención y la normalización de capa a mano, compara con ellas las versiones de IX y después comprueba qué hace el backward de IX con cada peso.

Las nueve predicciones que prueba esta lección se [escribieron en el diario](../journal/#2026-09-30--lección-13-predicha-antes-de-medir) y se registraron en un commit antes de que existiera su código. [Los resultados](../journal/#2026-09-30--lección-13-medida) vienen después. Los experimentos están en [`transformer.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/transformer.rs), un test por predicción. [`l13_transformer.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l13_transformer.rs) imprime lo que miden. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcula la atención, la normalización y la tabla de escalado con [numpy](https://numpy.org/doc/stable/).

## 1. La atención, a mano

Cada token de una secuencia hace una pregunta, una consulta q, y cada token ofrece una clave k y un valor v. La similitud de la consulta con cada clave, escalada y pasada por un softmax, se convierte en un peso, y la salida del token es la media de los valores ponderada por esos pesos ([Vaswani et al.](https://arxiv.org/abs/1706.03762), sección 3.2.1):

Attention(Q, K, V) = softmax(QKᵀ / √d_k) V

donde cada fila de Q, K y V es un token y d_k es la longitud de una consulta. `attention_by_hand`, en `transformer.rs`, la calcula con bucles simples. [`scaled_dot_product_attention`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L45-L92) de IX la calcula con productos de matrices, un elemento del batch cada vez (P1):

```text
== Attention by hand and in IX
  Q, K, V of shape (2, 4, 3), uniform in [-1, 1)
  weights of batch 0, query 0: [0.255277, 0.255466, 0.217414, 0.271842]
  output of batch 0, query 0:  [-0.338191, -0.187914, 0.504304]
  largest difference from softmax(QK^T/sqrt(d_k))V by hand: output < 1e-12, weights < 1e-12
  largest |row sum of the weights - 1|: < 1e-12
```

Los cuatro pesos valen cerca de un cuarto cada uno, porque consultas y claves aleatorias de longitud 3 apenas se parecen más a una clave que a otra. numpy, a partir de los mismos números aleatorios, imprime los mismos pesos y la misma salida.

## 2. Por qué dividir entre √d_k

Si las componentes de q y de k son independientes, con media 0 y varianza 1, entonces q·k es una suma de d_k productos de varianza 1 cada uno, y su varianza es d_k. Sin el escalado, las puntuaciones se dispersan a medida que los vectores se alargan, y el softmax da casi todo el peso a la mayor:

```text
== Why divide by sqrt(d_k)
  components of q and k with variance 1, 16 keys, 2000 queries
     d   var(q.k)   largest weight, unscaled   scaled
     4        4.0                      0.413    0.226
    16       15.7                      0.679    0.238
    64       63.8                      0.847    0.247
   256      259.7                      0.925    0.247
```

Con d_k = 256, el softmax sin escalar pone 0,925 del peso en una sola clave de 16, donde el gradiente de un softmax es casi nulo. Divididas entre √d_k, las puntuaciones conservan varianza 1 con cualquier longitud, y el mayor peso se queda cerca de un cuarto. Vaswani et al. dan este argumento en su nota 4.

## 3. La normalización de capa

Una normalización de capa ([Ba et al.](https://arxiv.org/abs/1607.06450)) reescala cada token por separado: resta la media de sus componentes, divide entre su desviación típica, y luego multiplica por un γ aprendido y suma un β aprendido, uno de cada por componente. Usa la varianza de la población, y un ε dentro de la raíz evita dividir entre cero con un token constante. Una normalización por batch hace lo mismo componente a componente, a través de los tokens de un batch: por eso depende del batch, y la normalización de capa no.

```text
== Layer normalization
  token 0:             [2.951819, 3.736748, -0.556086, 2.897718, 3.615376, 3.820285]
  normalized by IX:    [0.136528, 0.652960, -2.171448, 0.100933, 0.573105, 0.707922]
  largest difference from (x - mean)/sqrt(var + 1e-5) by hand: < 1e-12
  mean of each token after: [0.000000, 0.000000], variance: [0.999996, 0.999997]
```

La varianza después no es 1 sino var/(var + ε), con el ε = 10⁻⁵ de IX ([`norm.rs` 36-46](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/norm.rs#L36-L46)). γ empieza en 1 y β en 0: una normalización de capa nueva solo normaliza.

## 4. El bloque, la máscara y el orden

El [`TransformerBlock`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L190-L287) de IX es un bloque prenormalizado. Cada subcapa lee una copia normalizada de su entrada y suma su resultado a la entrada sin normalizar:

h = x + Attention(LN₁(x)),   salida = h + FFN(LN₂(h))

La atención es multicabeza: las consultas, las claves y los valores se proyectan con w_q, w_k y w_v, se cortan en cabezas de d_model / n_heads columnas cada una, se atienden por separado, se vuelven a poner una al lado de otra y se proyectan con w_o. La red feed-forward, FFN, son dos capas lineales con una [GELU](https://arxiv.org/abs/1606.08415) entre ellas, aplicadas a cada token por separado. El transformer original normalizaba después de cada suma residual. Normalizar antes, como aquí, mantiene de la salida a la entrada un camino que ninguna normalización reescala, lo que, según muestran [Xiong et al.](https://arxiv.org/abs/2002.04745), estabiliza el entrenamiento sin una fase de calentamiento de la tasa de aprendizaje.

**La máscara causal.** Un modelo que predice el token siguiente no debe ver los tokens que vienen después. [`causal_mask`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L37-L43) suma −10⁹ a cada puntuación por encima de la diagonal. Después de que el softmax reste el máximo de la fila, la exponencial de unos −10⁹ es menor que el menor double positivo: esos pesos valen exactamente 0, y un peso de exactamente 0 suma exactamente 0 a la salida. La atención es el único lugar donde un bloque mezcla tokens, así que las filas anteriores a un cambio no pueden moverse en absoluto (P2):

```text
== The causal mask
  block with d_model 8, 2 heads, d_ff 16; 2 sequences of 5 tokens; tokens 3 and 4 redrawn
  largest change in output rows 0 to 2: 0, exactly
  largest change in output rows 3 and 4: 1.777
```

**El orden.** Sin máscara, nada en el bloque depende de la posición de un token: las proyecciones, las normalizaciones y la FFN tratan igual a cada token, y la atención hace una suma ponderada sobre todos. Reordenar la entrada reordena la salida de la misma forma (P9). Una codificación de posición rompe esa simetría. La [codificación sinusoidal](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/positional.rs#L20-L34) de Vaswani et al. suma un vector fijo a cada posición, antes del bloque:

```text
== Order
  tokens reordered 3, 0, 4, 1, 2, no positional encoding: largest difference < 1e-12
  the same with a sinusoidal encoding added to the input: 1.894
```

## 5. El backward, y el paso que da

Las capas de IX no tienen cinta: cada una escribe su backward a mano. [`attention_backward`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L94-L161) devuelve los gradientes de Q, K y V, y coinciden con las diferencias centradas de la lección 12 (P3):

```text
== IX's attention backward against central differences
  Q, K, V of shape (2, 4, 3), L = sum c * output, eps 1e-5: worst error over 72 components below 1e-7: true
```

Las capas de encima hacen algo más que devolver gradientes: `multi_head_attention_backward`, `FeedForward::backward`, `LayerNorm::backward` y `TransformerBlock::backward` reciben cada una una tasa de aprendizaje y actualizan sus propios pesos. El curso mide lo que aplican. Llama a cada backward con tasa 1, así que el cambio de un peso es el paso mismo, y lo ajusta frente al gradiente de la misma pérdida por diferencias centradas: cambio = r × gradiente (P4 y P5):

```text
== What backward applies at learning rate 1, batch 2, seq 5 (batch x seq = 10)
  change / central-difference gradient, by least squares
  multi_head_attention_backward, d_model 8, 2 heads:
    w_q          0.1000   within 1e-6 of 0.1: true
    w_k          0.1000   within 1e-6 of 0.1: true
    w_v          0.1000   within 1e-6 of 0.1: true
    w_o          0.1000   within 1e-6 of 0.1: true
    input gradient within 1e-6 of central differences: true
  TransformerBlock::backward, d_model 8, 2 heads, d_ff 16, parameters in the order it updates them:
    ffn.w2       0.1000   within 1e-6 of 0.1: true
    ffn.b2       0.1000   within 1e-6 of 0.1: true
    ffn.w1       0.1000   within 1e-6 of 0.1: true
    ffn.b1       0.1000   within 1e-6 of 0.1: true
    norm2.gamma  1.0000   within 1e-6 of 1.0: true
    norm2.beta   1.0000   within 1e-6 of 1.0: true
    w_o          0.1000   within 1e-6 of 0.1: true
    w_q          0.1000   within 1e-6 of 0.1: true
    w_k          0.1000   within 1e-6 of 0.1: true
    w_v          0.1000   within 1e-6 of 0.1: true
    norm1.gamma  1.0000   within 1e-6 of 1.0: true
    norm1.beta   1.0000   within 1e-6 of 1.0: true
    input gradient within 1e-6 of central differences: true
```

Cada gradiente que calcula IX es correcto: los gradientes de la entrada coinciden, y cada cambio es exactamente proporcional a su gradiente. El factor, en cambio, no es el mismo en todas partes. Las proyecciones de la atención ([`attention.rs` 212, 254-257](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L212)) y los pesos del feed-forward ([`transformer.rs` 153-157](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L153-L157)) dividen su gradiente entre batch × seq antes de dar el paso. Las dos normalizaciones de capa no lo hacen ([`norm.rs` 104-128](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/norm.rs#L104-L128)). Ninguna pérdida tiene estos pasos como su paso de gradiente, sea cual sea el gradiente que se pase:

- **La pérdida es una suma sobre los tokens.** Las normalizaciones dan el paso correcto, y todos los demás pesos un paso batch × seq veces demasiado pequeño.
- **La pérdida es una media.** El `TransformerClassifier` y el `TransformerRegressor` de IX pasan este gradiente: dividen entre el tamaño del batch y después entre la longitud de la secuencia ([`classifier.rs` 316, 336](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/classifier.rs#L316-L343), y 541, 559 para el regresor). Las normalizaciones vuelven a acertar, y los demás pesos dividen por segunda vez entre batch × seq. Con el batch completo por defecto, 100 ejemplos de 4 tokens cada uno moverían los pesos de la atención y del feed-forward 400 veces menos que la cabeza del clasificador y sus normalizaciones, con la misma tasa de aprendizaje. Es el hallazgo 15 de la lección 7, encontrado en `Dense`, repetido en dos capas más.

El comentario de documentación de `multi_head_attention_backward` dice además que devuelve el gradiente de la entrada y las cuatro matrices actualizadas ([`attention.rs` 177-178](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L177-L178)). Solo devuelve el gradiente de la entrada, y actualiza las matrices a través de las referencias `&mut` que recibe.

## 6. La inicialización

[Glorot y Bengio](https://proceedings.mlr.press/v9/glorot10a.html) inicializan una capa con fan_in entradas y fan_out salidas en U(−a, a) con a = √(6 / (fan_in + fan_out)), de varianza a²/3 = 2 / (fan_in + fan_out). [`FeedForward::new`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L38-L50) anuncia «Xavier init» y calcula esa desviación típica, √(2 / (fan_in + fan_out)), pero luego la usa como la cota a. `TransformerBlock::new` hace lo mismo con √(1/d_model) para las proyecciones ([`transformer.rs` 235-238](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L235-L238)). La dispersión resulta √3 veces menor que la de la fórmula que nombra (P6):

```text
== Initial spread
  FeedForward::new(64, 256): std of w1 and w2 / sqrt(2/(64 + 256)) = 0.5767
  TransformerBlock::new(64, 4, 256): std of w_q, w_k, w_v, w_o / sqrt(1/64) = 0.5763
  U(-a, a) has std a/sqrt(3) = 0.5774 a; Glorot and Bengio's U(-sqrt(3) s, sqrt(3) s) has std s
```

En un bloque prenormalizado, la dispersión debería importar menos que en la pila simple de la lección 7, porque cada subcapa lee una entrada normalizada y el camino residual lleva la señal sean cuales sean los pesos; esta lección no entrenó un bloque para medirlo. La capa de salida del propio clasificador sí se muestrea de una normal con la desviación típica correcta ([`classifier.rs` 180-189](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/classifier.rs#L180-L189)). La U(−1, 1) del propio numpy, con un millón de muestras, da 0,5776 frente a 1/√3 = 0,5774.

## 7. Dos casos límite

**Cabezas que no dividen d_model.** La atención multicabeza corta d_model en n_heads cabezas de d_model / n_heads columnas, con división entera y sin comprobación ([`attention.rs` 377](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L377)). Con 10 dimensiones y 3 cabezas, cada cabeza recibe 3 columnas y la columna 9 no va a ninguna parte (P7):

```text
== Ten dimensions over three heads
  change when column 9 of w_q, w_k, w_v and row 9 of w_o are redrawn: 0, exactly
  the same for column 8: 1.327
```

El bloque se ejecuta y no informa de ningún error. Con la misma lectura de `multi_head_attention_backward`, los pesos de la columna 9 reciben también un gradiente nulo, porque nada escribe esa columna de los gradientes de las proyecciones; el curso no lo midió.

**SwiGLU con una longitud impar.** [`swiglu`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L180-L188) ([Shazeer](https://arxiv.org/abs/2002.05202)) corta su entrada en len / 2 en una compuerta y un valor, y los multiplica. Con 5 valores, la compuerta tiene 2 y el valor 3 (P8):

```text
== SwiGLU
  4 values: Value
  5 values: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
```

## 8. Las predicciones, puntuadas

| | Predicción, escrita antes de la primera ejecución | Medida | Veredicto |
|---|---|---|---|
| P1 | `scaled_dot_product_attention` es igual a la fórmula a mano con una diferencia menor que 10⁻¹², y sus filas suman 1 | Menos de 10⁻¹² en ambos | Confirmada |
| P2 | Con la máscara causal, volver a sortear los tokens 3 y 4 cambia las filas 0 a 2 de la salida en exactamente 0 | 0; las filas 3 y 4 cambian 1,777 | Confirmada |
| P3 | `attention_backward` a menos de 10⁻⁷ de las diferencias centradas con ε = 10⁻⁵ | Menos de 10⁻⁷ en las 72 componentes | Confirmada |
| P4 | `multi_head_attention_backward` hace dar a las proyecciones un paso de la décima parte de su gradiente con batch 2, seq 5, y devuelve el gradiente de la entrada tal cual | 0,1000 en las cuatro; gradiente de la entrada a menos de 10⁻⁶ | Confirmada |
| P5 | En `TransformerBlock::backward`, las LayerNorm dan un paso del gradiente entero y todos los demás pesos uno de la décima parte | 1,0000 en los cuatro parámetros de normalización, 0,1000 en los otros ocho | Confirmada |
| P6 | La dispersión «Xavier» es 1/√3 de la que nombra: razón en [0,56; 0,60] | 0,5767 y 0,5763 | Confirmada |
| P7 | 10 dimensiones en 3 cabezas: volver a sortear la columna 9 cambia la salida en exactamente 0 | 0; la columna 8 la cambia 1,327 | Confirmada |
| P8 | `swiglu` entra en pánico con 5 valores | Entra en pánico | Confirmada |
| P9 | Sin posiciones, reordenar los tokens reordena la salida con una diferencia menor que 10⁻¹² | Menos de 10⁻¹²; 1,894 con una codificación sinusoidal | Confirmada |

Las nueve se cumplieron en la primera ejecución, y ninguna se ajustó después. P4 a P8 se escribieron leyendo el código de IX, para detectar una diferencia entre lo que dice y lo que hace, y cada una encontró una. P2, P7 y P9 tienen cada una un control que muestra que la comprobación puede fallar: las filas posteriores al cambio sí se mueven, la columna 8 sí cuenta, y una codificación de posición sí rompe la simetría.

## Qué usar en nuestros repositorios

- **Las pasadas hacia delante de la atención y de la normalización de capa de IX:** exactas, y la máscara causal también. Comprueba que n_heads divide d_model antes de construir un bloque, porque nada más lo hará.
- **Entrenar con los métodos backward de `ix-nn`:** el paso de cada peso es su gradiente por la tasa de aprendizaje, dividido entre batch × seq salvo en las normalizaciones de capa. Elige la tasa de aprendizaje de los pesos de la atención y del feed-forward sabiéndolo, o escala el gradiente que pasas. Para entrenar una capa nueva, la cinta de la lección 12 es más segura que un backward escrito a mano.
- **Antes de fiarte de un backward escrito a mano,** mide el paso que aplica, no solo el gradiente que devuelve: los gradientes de IX son todos correctos, y sus pasos no.
- **`swiglu`:** solo longitudes pares.

## Ejercicios

1. Demuestra que si las componentes de q y de k son independientes, con media 0 y varianza 1, entonces q·k tiene media 0 y varianza d_k.
2. Después de normalizar, la varianza del primer token se imprime como 0,999996. Sin mirar el token, ¿cuál era su varianza antes?
3. `TransformerClassifier` se entrena con 100 ejemplos de 4 tokens cada uno, en un solo batch. Con tasa de aprendizaje η, ¿cuánto se mueve w_q, comparado con un paso de gradiente sobre la pérdida media del clasificador? ¿Qué cambiarías en IX para que una tasa de aprendizaje signifique un solo tamaño de paso?
4. `rope_rotate` ([`positional.rs` 36-66](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/positional.rs#L36-L66), [Su et al.](https://arxiv.org/abs/2104.09864)) gira cada par de componentes (2i, 2i + 1) del token en la posición m un ángulo m·θᵢ. Demuestra que el producto escalar de una consulta girada en la posición m y una clave girada en la posición n depende de m − n y no de m y n por separado.

<details>
<summary>Soluciones</summary>

1. q·k = Σᵢ qᵢkᵢ. Cada producto tiene media E[qᵢ]E[kᵢ] = 0 y varianza E[qᵢ²]E[kᵢ²] − 0 = 1. Los d_k productos son independientes, así que sus varianzas se suman: d_k.
2. La varianza después es var/(var + 10⁻⁵) = 0,999996, con un margen de 5 × 10⁻⁷ por el redondeo, así que var = 10⁻⁵ × 0,999996/(1 − 0,999996) ≈ 2,5, en algún punto entre 2,2 y 2,9. La varianza del token era 2,31.
3. El gradiente del clasificador ya está dividido entre los 100 ejemplos y las 4 posiciones, y la atención lo divide otra vez entre batch × seq = 400: w_q se mueve η/400 veces su gradiente, donde la cabeza y las normalizaciones de capa se mueven η veces el suyo. Quitar la división de `multi_head_attention_backward` y de `FeedForward::backward` haría que cada capa diera un paso de η veces el gradiente de la pérdida que deriva quien la llama, como ya hace `LayerNorm::backward`.
4. En un par, la rotación de ángulo α es la matriz 2 × 2 R(α), y R(α)ᵀR(β) = R(β − α). Así, (R(mθᵢ)q)·(R(nθᵢ)k) = qᵀR(mθᵢ)ᵀR(nθᵢ)k = qᵀR((n − m)θᵢ)k, que solo depende de n − m. El producto escalar es la suma de estos términos sobre los pares.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [`attention.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs), [`norm.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/norm.rs), [`transformer.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs), [`positional.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/positional.rs) y [`classifier.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/classifier.rs).
- A. Vaswani et al., [«Attention is all you need»](https://arxiv.org/abs/1706.03762), NeurIPS 2017: la atención, el escalado, la atención multicabeza, la codificación sinusoidal.
- J. L. Ba, J. R. Kiros y G. E. Hinton, [«Layer normalization»](https://arxiv.org/abs/1607.06450), 2016.
- R. Xiong et al., [«On layer normalization in the transformer architecture»](https://arxiv.org/abs/2002.04745), ICML 2020: prenormalización y posnormalización.
- X. Glorot y Y. Bengio, [«Understanding the difficulty of training deep feedforward neural networks»](https://proceedings.mlr.press/v9/glorot10a.html), AISTATS 2010: la inicialización.
- D. Hendrycks y K. Gimpel, [«Gaussian error linear units (GELUs)»](https://arxiv.org/abs/1606.08415), 2016.
- N. Shazeer, [«GLU variants improve transformer»](https://arxiv.org/abs/2002.05202), 2020: SwiGLU.
- J. Su et al., [«RoFormer: enhanced transformer with rotary position embedding»](https://arxiv.org/abs/2104.09864), 2021.
