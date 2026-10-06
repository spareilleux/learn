---
title: 1. Las palabras de trenza y el polinomio de Jones
description: 'Un nudo escrito como una palabra de trenza — generadores, cierre, componentes y torsión, tal como los lee ix-knot de IX — y luego el polinomio de Jones calculado con la suma de estados del corchete de Kauffman, comprobado contra cada valor que afirman las pruebas de IX, el trébol y su imagen especular, por qué una tabla de nudos puede imprimir la otra, y el nudo llano distinguido del nudo de abuela.'
sidebar:
  order: 1
---

Código: el script de la lección, [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py), su comprobación por mutación, [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py), y las salidas con las que se compara, en [`expected/`](https://github.com/spareilleux/learn/tree/main/code/speaking-in-knots/expected). Del lado de IX: el crate [`ix-knot`](https://github.com/GuitarAlchemist/ix/tree/e8684cf/crates/ix-knot) en el commit `e8684cf`, de la [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366).

## Un nudo como una línea de texto

Coloca unas hebras una junto a otra, de arriba abajo, y deja que las vecinas se crucen. Numera las posiciones desde 1, de izquierda a derecha. Una **palabra de trenza** enumera los cruces en orden: `s1` significa que la hebra en la posición 1 pasa *por delante* de la hebra en la posición 2; `s1^-1` significa que el mismo par se cruza al revés, con la hebra de la posición 2 delante. Es la convención de IX, escrita en [`braid.rs`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/braid.rs#L30-L34): el generador `k` es σₖ, y `-k` es σₖ⁻¹.

Une después el extremo inferior de cada hebra con la parte superior de la misma posición. El resultado, el **cierre** de la trenza, es uno o varios lazos cerrados en el espacio: un nudo si hay un solo lazo, un enlace si hay varios. Todo nudo y todo enlace puede escribirse así (Alexander, 1923). Una palabra de trenza es, por tanto, un formato de texto completo para los nudos, y es el formato que comprueba IX.

IX lee la misma palabra escrita de tres formas: `s1 s2^-1`, `1,-2` y `σ1 σ2^-1`. Sin número de hebras, la trenza tiene una hebra más que su mayor generador. Rechaza una palabra de más de 8 hebras o de más de 64 cruces, y cada rechazo dice por qué. Estos son los cuatro mensajes, tomados del código fuente en `e8684cf`:

```rust
#[error("a braid needs 1 to {MAX_STRANDS} strands, got {0}")]
#[error("generator {generator} needs 1 <= |k| < strands ({strands})")]
#[error("a braid word may have at most {MAX_CROSSINGS} crossings, got {0}")]
#[error("cannot read {0:?} as a generator: write s1, s2^-1, s1^3 or a signed integer")]
```

Los límites no son arbitrarios: [el comentario que los precede](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/braid.rs#L5-L15) muestra que 64 cruces mantienen cada coeficiente dentro de un `i128`.

## Componentes y torsión

Dos números se leen en la palabra sin dibujar nada.

- **Las componentes.** Sigue las hebras a través de los cruces: cada cruce intercambia dos posiciones, así que la palabra entera es una permutación de las posiciones. El cierre une cada final con el inicio que está debajo, así que cada ciclo de la permutación se convierte en un lazo. `s1` sobre 2 hebras las intercambia una vez: un ciclo, un lazo. `s1^2` las intercambia dos veces: vuelven a su sitio, dos lazos.
- **La torsión** (*writhe*). Cuenta +1 por cada `s` y −1 por cada `s^-1`. La torsión de `s1^3 s2^-1` es 3 − 1 = 2.

IX calcula ambas en [`braid.rs`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/braid.rs#L99-L155), y el script del curso también.

## El corchete de Kauffman, suavizado a suavizado

Las componentes y la torsión no distinguen los nudos: un nudo y el nudo trivial tienen ambos una componente. El **polinomio de Jones** lo hace mucho mejor, y el **corchete de Kauffman** (Kauffman, 1987) lo calcula sin hacer otra cosa que contar.

En cada cruce, corta las dos hebras y vuelve a conectarlas sin cruzarlas, de una de dos formas: hacia abajo, como dos arcos verticales, o de lado, como una tapa y una copa. Una palabra de trenza con *c* cruces tiene 2^*c* formas de hacerlo, llamadas suavizados, y cada una deja un conjunto de círculos disjuntos. Da un peso a cada suavizado:

- un cruce positivo suavizado verticalmente cuenta *A*, suavizado en tapa y copa *A*⁻¹; un cruce negativo, al revés;
- cada círculo más allá del primero multiplica por *d* = −*A*² − *A*⁻².

El corchete ⟨*L*⟩ es la suma de estos pesos sobre todos los suavizados. Cambia cuando una hebra se retuerce sobre sí misma, y la torsión lo corrige: *V*(*t*) = (−*A*³)^(−torsión) · ⟨*L*⟩, escrito con *t* = *A*⁻⁴. Ese es el polinomio de Jones.

[`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) hace exactamente eso: recorre los 2^*c* suavizados, cuenta los círculos de cada uno con un union-find y suma los términos. La construcción es la de la función auxiliar `state_sum` de las propias pruebas de IX, reescrita en Python para que funcione sin Rust ni el repositorio de IX.

La biblioteca de IX toma otro camino. [`jones.rs`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/jones.rs#L1-L14) multiplica los cruces uno a uno en el álgebra de Temperley–Lieb, donde σₖ = *A*·1 + *A*⁻¹·eₖ. Guarda un coeficiente por diagrama plano en lugar de un término por suavizado: hay Catalan(*n*) diagramas sobre *n* hebras, 1430 con 8 hebras, así que su coste crece con los cruces en lugar de duplicarse con cada uno. Sus pruebas ya comparan los dos caminos en 150 palabras de trenza ([`the_algebra_agrees_with_the_state_sum_and_the_markov_moves`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/jones.rs#L320-L328)).

## Comprobar los valores que afirma IX

Ejecutado sin argumentos, el script recalcula cada valor que afirman las pruebas de IX en `e8684cf`: los polinomios de Jones de [`known_knots_and_links`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/jones.rs#L205-L224), las simetrías de [`the_reef_knot_is_symmetric_and_the_granny_is_not`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/jones.rs#L226-L239), y las componentes y torsiones que afirma `braid.rs`. Los imprime en el propio formato de IX. Los comandos se ejecutan desde la raíz de un clon del [repositorio del curso](https://github.com/spareilleux/learn), con Python 3 y nada más; escribe `python3` en lugar de `python` donde ese sea el nombre de Python 3, como en la mayoría de los sistemas Linux y macOS.

```bash
python code/speaking-in-knots/jones_state_sum.py
```

```text
OK   (empty) on 1 strands: jones 1
OK   s1 on 2 strands: components 1
OK   s1 on 2 strands: jones 1
OK   s1^-1 s2 s3^-1 on 4 strands: jones 1
OK   (empty) on 3 strands: jones t^-1 + 2 + t
OK   (empty) on 4 strands: components 4
OK   s1^2 on 2 strands: components 2
OK   s1^2 on 2 strands: jones -t^(1/2) - t^(5/2)
OK   s1^3 on 2 strands: components 1
OK   s1^3 on 2 strands: jones t + t^3 - t^4
OK   s1^-3 on 2 strands: jones -t^-4 + t^-3 + t^-1
OK   s1^3 s2^-1 on 3 strands: writhe 2
OK   s1 s2^-1 s1 s2^-1 on 3 strands: components 1
OK   s1 s2^-1 s1 s2^-1 on 3 strands: jones t^-2 - t^-1 + 1 - t + t^2
OK   s1 s2^-1 s1 s2^-1 s1 s2^-1 on 3 strands: components 3
OK   s1 s2^-1 s1 s2^-1 s1 s2^-1 on 3 strands: jones -t^-3 + 3t^-2 - 2t^-1 + 4 - 2t + 3t^2 - t^3
OK   s1^3 s2^-3: V = -t^-3 + t^-2 - t^-1 + 3 - t + t^2 - t^3, symmetric
OK   s1^3 s2^3: V = t^2 + 2t^4 - 2t^5 + t^6 - 2t^7 + t^8, not symmetric
OK   s1^3: V = t + t^3 - t^4, not symmetric
19/19 agree with IX at e8684cf
```

Termina con el estado 0; un solo desacuerdo imprimiría `DIFF` con el valor de IX y terminaría con el estado 1.

Una comprobación que siempre dice `OK` no demuestra nada, así que `mutants.py` rompe el script a propósito, de seis formas, una cada vez: la convención de cruce invertida, el signo del valor del lazo cambiado, el signo de la torsión olvidado, el cierre sin pegar, *t* = *A*⁴ en lugar de *A*⁻⁴, y el intercambio de la permutación omitido. Cada mutante debe hacer fallar la comprobación anterior:

```bash
python code/speaking-in-knots/mutants.py
```

```text
CAUGHT crossing convention flipped -> 15/19 agree with IX at e8684cf
CAUGHT loop value +A^2 + A^-2 -> 12/19 agree with IX at e8684cf
CAUGHT writhe sign dropped -> 15/19 agree with IX at e8684cf
CAUGHT closure not glued -> 12/19 agree with IX at e8684cf
CAUGHT t = A^4 instead of A^-4 -> 16/19 agree with IX at e8684cf
CAUGHT permutation swap skipped -> 16/19 agree with IX at e8684cf
6/6 mutants caught
```

## El trébol y su imagen especular

`s1^3` se cierra en un trébol, el nudo más simple que no se puede deshacer:

```bash
python code/speaking-in-knots/jones_state_sum.py "s1^3"
```

```text
word: s1^3
strands 2, crossings 3, writhe 3, components 1
V = t + t^3 - t^4
V(1) = 1, not symmetric
```

Invierte cada cruce, `s1^-3`, y obtienes su imagen especular, cuyo polinomio es el mismo con *t* sustituido por 1/*t*: −*t*⁻⁴ + *t*⁻³ + *t*⁻¹. Los dos polinomios son distintos, así que ninguna manipulación convierte un trébol en el otro: el trébol es **quiral**.

Abre ahora la página del trébol en una tabla de nudos, [3_1 en el Knot Atlas](https://katlas.org/wiki/3_1). Imprime −*q*⁻⁴ + *q*⁻³ + *q*⁻¹: el polinomio de `s1^-3`, no de `s1^3`. Ninguno de los dos está mal. Una tabla dibuja una de las dos imágenes especulares bajo cada nombre, y su elección no tiene por qué seguir la convención de cruce de IX. Lo mismo ocurre con el enlace más simple, dos anillos enganchados: el `s1^2` de IX da −*t*^(1/2) − *t*^(5/2), y [L2a1](https://katlas.org/wiki/L2a1) imprime −*q*^(−1/2) − *q*^(−5/2), el polinomio de `s1^-2`. Para los nudos sin sentido de giro, la tabla e IX coinciden exactamente: el nudo en ocho, `s1 s2^-1 s1 s2^-1`, corresponde a [4_1](https://katlas.org/wiki/4_1), y los anillos de Borromeo, `(s1 s2^-1)^3`, a [L6a4](https://katlas.org/wiki/L6a4). Antes de comparar un polinomio con una tabla, comprueba sus dos imágenes especulares.

## Dos comprobaciones que no cuestan nada

- ***V*(1) cuenta las componentes.** Para todo enlace, *V*(1) = (−2)^(componentes − 1): 1 para un nudo, −2 para dos lazos, 4 para tres. Las pruebas de IX lo afirman en las 150 palabras. Un polinomio que lo incumple tiene un error en alguna parte.
- **La simetría es un indicio, no una prueba.** Un nudo que es su propia imagen especular tiene *V*(*t*) = *V*(1/*t*). El nudo llano, `s1^3 s2^-3`, un trébol derecho junto a uno izquierdo, es simétrico; el nudo de abuela, `s1^3 s2^3`, dos tréboles del mismo sentido, no lo es. Los marineros saben que el nudo de abuela se escurre y que el llano aguanta; el polinomio ya los distingue. Lo recíproco no se cumple: como dice [`is_symmetric`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/jones.rs#L42-L46) en IX, tener la simetría no demuestra que un enlace sea su propia imagen especular.

## Ejercicios

1. Antes de ejecutar nada, predice el número de componentes y *V*(1) para `s1^2`. Después ejecuta `python code/speaking-in-knots/jones_state_sum.py "s1^2"`.
2. `s1 s2` tiene dos cruces y, sin embargo, su polinomio es 1, el del nudo trivial. Explica por qué sin calcularlo.
3. Ejecuta `(s1 s2^-1)^3` con `python code/speaking-in-knots/jones_state_sum.py "s1 s2^-1" 3`, y luego `(s1 s2)^3` del mismo modo. Los dos tienen tres componentes. ¿Qué los distingue, y cuál es simétrico?
4. Comprueba a mano que el polinomio del nudo de abuela, *t*² + 2*t*⁴ − 2*t*⁵ + *t*⁶ − 2*t*⁷ + *t*⁸, es el cuadrado del del trébol.
5. La trenza `s1 s2^-1` escrita 6 veces tiene 12 cruces. ¿Cuántos suavizados recorre el script? Predice *V*(1) y ejecútalo con `"s1 s2^-1" 6`.
6. IX rechaza `s9`. ¿Cuál de sus cuatro mensajes da, y con qué número?

<details>
<summary>Solución 1</summary>

Dos intercambios del mismo par devuelven las dos hebras a su sitio: dos ciclos, luego dos componentes, y *V*(1) = (−2)^(2 − 1) = −2. Son dos anillos enganchados una vez, el enlace de Hopf:

```text
word: s1^2
strands 2, crossings 2, writhe 2, components 2
V = -t^(1/2) - t^(5/2)
V(1) = -2, not symmetric
```

Un número par de componentes da potencias semienteras de *t*, por eso IX guarda las potencias en mitades.
</details>

<details>
<summary>Solución 2</summary>

`s2` es el único cruce que toca la hebra 3, y aparece una vez. Quitar ese cruce y la hebra 3 deja la misma curva cerrada con una vuelta menos: es un movimiento de Markov, que no cambia el nudo. Lo que queda, `s1` sobre 2 hebras, tiene la misma propiedad, y quitarlo deja una hebra sola: el nudo trivial. El script está de acuerdo:

```text
word: s1 s2
strands 3, crossings 2, writhe 2, components 1
V = 1
V(1) = 1, symmetric
```

Las pruebas de IX comprueban esta invariancia (añaden un cruce sobre una hebra nueva, en un sentido o en el otro, y exigen el mismo polinomio) en las 150 palabras.
</details>

<details>
<summary>Solución 3</summary>

```text
word: s1 s2^-1, repeated 3 times
strands 3, crossings 6, writhe 0, components 3
V = -t^-3 + 3t^-2 - 2t^-1 + 4 - 2t + 3t^2 - t^3
V(1) = 4, symmetric
```

```text
word: s1 s2, repeated 3 times
strands 3, crossings 6, writhe 6, components 3
V = t^2 + t^4 + 2t^6
V(1) = 4, not symmetric
```

El mismo número de lazos, el mismo *V*(1) = 4, polinomios distintos: son enlaces distintos. El primero son los anillos de Borromeo, tres anillos de los que ninguno está enlazado con otro y que, sin embargo, no se pueden separar; es simétrico y corresponde a L6a4 en el Knot Atlas. El segundo, con todos sus cruces del mismo signo, no es simétrico: es un enlace distinto de su imagen especular.
</details>

<details>
<summary>Solución 4</summary>

(*t* + *t*³ − *t*⁴)² = *t*² + *t*⁶ + *t*⁸ + 2*t*⁴ − 2*t*⁵ − 2*t*⁷, que es el polinomio del nudo de abuela. El nudo de abuela son dos tréboles anudados uno tras otro, y el polinomio de una suma así es el producto de los dos. Del mismo modo, el polinomio del nudo llano es el del trébol multiplicado por el de su imagen especular. La prueba de IX afirma los dos productos.
</details>

<details>
<summary>Solución 5</summary>

2¹² = 4096 suavizados. Tres hebras, y `s1 s2^-1` las permuta en un ciclo de longitud 3, que seis repeticiones devuelven a la identidad: tres componentes, luego *V*(1) = 4.

```text
word: s1 s2^-1, repeated 6 times
strands 3, crossings 12, writhe 0, components 3
V = t^-6 - 6t^-5 + 15t^-4 - 26t^-3 + 39t^-2 - 47t^-1 + 52 - 47t + 39t^2 - 26t^3 + 15t^4 - 6t^5 + t^6
V(1) = 4, symmetric
```

El script rechaza más de 20 cruces, un millón de suavizados. El camino de Temperley–Lieb de IX admite 64, porque nunca guarda más de 5 diagramas sobre 3 hebras.
</details>

<details>
<summary>Solución 6</summary>

El generador 9 necesita una décima hebra, así que la trenza leída tiene 10 hebras, más que el límite de 8 de IX: el primer mensaje, con 10. La prueba de IX afirma exactamente ese rechazo, [`Braid::parse(None, "s9")` da `BraidError::Strands(10)`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/braid.rs#L237). El script del curso no tiene límite de hebras y lo calcula: no es IX, solo comprueba IX.
</details>
