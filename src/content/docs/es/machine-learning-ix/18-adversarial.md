---
title: "18. Ejemplos adversarios, envenenamiento y las defensas"
description: "FGSM, PGD, Carlini–Wagner y las perturbaciones universales frente a un modelo lineal fijo, y luego la detección por ruido, la compresión de características, el radio certificado y las defensas contra el envenenamiento de ix-adversarial, con ocho predicciones escritas antes de la primera ejecución, las ocho confirmadas. PGD mueve las características que el gradiente ignora, Carlini–Wagner devuelve la entrada intacta por debajo de c‖w‖ = 1, el detector da la misma puntuación a las 4000 entradas, la compresión conserva la media de la perturbación, el radio certificado se equivoca hasta en 4,4·10⁻⁴, y la función de influencia ignora las etiquetas."
sidebar:
  order: 18
---

Un ejemplo adversario es una entrada modificada un poco, a propósito, para que un modelo se equivoque. [Goodfellow et al. (2015)](https://arxiv.org/abs/1412.6572) sostuvieron que esas entradas se deben a la linealidad misma: en alta dimensión, muchos cambios pequeños suman uno grande. El envenenamiento ataca los datos de entrenamiento en lugar de la entrada. El crate fijado [`ix-adversarial`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial) de IX tiene cuatro ataques de evasión, tres defensas, un radio certificado y tres herramientas contra el envenenamiento. Esta lección los mide frente a un modelo lo bastante simple para que cada número que comprueban las pruebas se siga de una fórmula.

Las ocho predicciones que pone a prueba esta lección se [escribieron en el diario](../journal/#2026-09-30--lección-18-predicha-antes-de-medir) y se confirmaron en un commit antes de que existiera su código. [Los resultados](../journal/#2026-09-30--lección-18-medida) las siguen. Los experimentos están en [`adversarial.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/adversarial.rs), una prueba por predicción, y [`l18_adversarial.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l18_adversarial.rs) imprime lo que miden. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) reconstruye el conjunto de prueba, el camino de Carlini–Wagner, la compresión, el probit y los dos experimentos de envenenamiento con numpy y SciPy, y encuentra los mismos números.

## 1. Un modelo que se puede atacar sobre el papel

Los ataques suelen medirse contra redes entrenadas, donde el resultado depende del entrenamiento. Esta lección fija el modelo en su lugar. Dos clases y = ±1 viven en 100 dimensiones: x = y·μ + n, donde cada coordenada de μ vale 0,2 y n es el ruido normal aproximado del curso, la suma de doce uniformes menos seis. El clasificador es el lineal óptimo de Bayes para este problema, w = μ sin sesgo: predice el signo de z = w·x. El margen m = y·z de un punto es positivo cuando el punto está bien clasificado, y su distancia a la frontera es m/‖w‖₂. Como m = ‖μ‖² + y·w·n, sigue 4 + N(0, 4), y la exactitud sobre las entradas limpias es Φ(2) ≈ 0,977. Cada característica lleva poca señal, 0,2 frente a un ruido de desviación típica 1. El modelo acierta porque suma 100 de ellas.

```text
== the model under attack
2000 test points, 1000 per class, in 100 dimensions; w = mu = 0.2 everywhere, |w|_2 = 2.000, |w|_1 = 20.000
clean accuracy 0.9780   (Phi(2) = 0.9772)
```

Los ataques que siguen necesitan el gradiente de una pérdida respecto a la entrada. Para la pérdida logística log(1 + e^(−m)), vale −y·σ(−m)·w, un múltiplo positivo de −y·w: la dirección que baja el margen más deprisa.

## 2. FGSM: cada característica movida un poco

`fgsm` suma ε·sign(g) a la entrada, donde g es el gradiente de la pérdida ([`evasion.rs` 5-10](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L5-L10)). Frente a un modelo lineal, sign(g) = −y·sign(w), así que cada coordenada se mueve ε contra la clase y el margen baja ε·Σ|wⱼ| = ε‖w‖₁ = 20ε. Es la explicación lineal de Goodfellow et al. El cambio de cada característica es pequeño al lado de su ruido, y los 100 cambios se suman. La exactitud pasa a ser Φ(2 − 10ε). P1 ataca los 2000 puntos de prueba con cuatro valores de ε:

```text
== P1, FGSM: every margin falls by eps |w|_1 = 20 eps
  eps   accuracy   Phi(2 - 10 eps)   changed class   exactly those with 0 < m < 20 eps   margins within 1e-12
  0.0   0.9780     0.9772               0            yes                                 yes
  0.1   0.8460     0.8413             264            yes                                 yes
  0.2   0.4780     0.5000            1000            yes                                 yes
  0.3   0.1470     0.1587            1662            yes                                 yes
```

Cada margen bajó 20ε con un error menor que 10⁻¹². Los puntos que cambiaron de clase son exactamente los bien clasificados cuyo margen era menor que 20ε. Las exactitudes quedan a menos de 0,022 de Φ(2 − 10ε), dentro de los intervalos predichos. Con ε = 0,2, un cambio de un quinto del ruido en cada característica reduce la exactitud a la mitad. Ese ε es el menor cambio ℓ∞ que alcanza la frontera desde el margen medio: m/‖w‖₁ = 4/20.

## 3. PGD y el signo de cero

`pgd` repite el paso de FGSM: α·sign(g) desde x, y luego un recorte del cambio total a [−ε, ε] ([`evasion.rs` 12-33](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L12-L33)), según [Madry et al. (2018)](https://arxiv.org/abs/1706.06083). IX parte del propio x, sin inicio aleatorio. Aquí importa más una diferencia más pequeña. `pgd` toma el signo con [`f64::signum`](https://doc.rust-lang.org/std/primitive.f64.html#method.signum), que devuelve 1 para +0.0 y −1 para −0.0. `fgsm` lleva 0 a 0, como hace [`sign`](https://numpy.org/doc/stable/reference/generated/numpy.sign.html) de NumPy. Una componente del gradiente es exactamente cero allí donde la pérdida no depende de la característica, y su signo sale entonces de la aritmética. Aquí, 0.0 por −y·σ(−m) es un cero con el signo de −y. `adversarial_training_augment`, documentada como «via FGSM», también llama a `signum` ([`defense.rs` 7-20](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs#L7-L20)). P2 da a las dos funciones un gradiente de ceros, y luego ataca un modelo que ignora la mitad de sus características, con wⱼ = 0 para las 50 últimas:

```text
== P2, PGD and f64::signum (eps 0.2, alpha 0.05, 10 steps), largest distance from the expected point
  gradient +0.0 everywhere: pgd from x +0.2 0.000, adversarial_training_augment from x +0.2 0.000, fgsm from x 0.000
  gradient -0.0 everywhere: pgd from x -0.2 0.000, adversarial_training_augment from x -0.2 0.000, fgsm from x 0.000
  model with w_j = 0 for the last 50 features, over the 2000 points (fewest, most):
    pgd:  features moved (100, 100), perturbation norm (2.0000, 2.0000), accuracy 0.4865
    fgsm: features moved (50, 50), perturbation norm (1.4142, 1.4142), accuracy 0.4865
  control, the full model: largest distance between pgd's point and fgsm's 0.000
```

Con un gradiente nulo, `pgd` y `adversarial_training_augment` mueven cada característica el ε completo, en una dirección fijada por el signo de cero, mientras que `fgsm` no se mueve. Frente al medio modelo, `pgd` mueve las 100 características y `fgsm` solo las 50 que cuentan. La exactitud es la misma, 0,4865, porque el modelo no ve las otras 50. Pero la perturbación de PGD es √2 veces más larga, 2,0 frente a 1,414, y todo lo que la mide, como un presupuesto ℓ₂ o un detector, ve 50 cambios que no sirven para nada. El control muestra que nada más difiere: frente al modelo completo, cuyo gradiente no tiene ningún cero, `pgd` cae exactamente en el punto de `fgsm`.

## 4. Carlini–Wagner sin su búsqueda sobre c

`cw_attack` minimiza ‖δ‖₂ + c·pérdida(x + δ) por descenso de gradiente sobre δ y devuelve el iterado con el menor objetivo ([`evasion.rs` 35-71](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L35-L71)). Su comentario de documentación dice que el descenso se hace en el espacio tanh, pero el código no tiene tanh. [Carlini y Wagner (2017)](https://doi.org/10.1109/SP.2017.49) usan ese cambio de variables para mantener una imagen dentro de su caja, minimizan la norma al cuadrado y buscan sobre c la menor perturbación que funciona. IX deja c al llamador y usa la norma simple.

Con la pérdida bisagra max(m, 0), el descenso se puede seguir a mano. El gradiente de ‖δ‖₂ es δ/‖δ‖, de longitud 1, y el gradiente de la pérdida vale y·w mientras el punto está de su lado. El camino va, pues, en línea recta a lo largo de −y·w. Su primer paso tiene longitud lr·c‖w‖. Los pasos siguientes tienen longitud lr·(c‖w‖ − 1) mientras m > 0, y el camino retrocede lr una vez pasada la frontera. Si c‖w‖ < 1, cada paso después del primero vuelve hacia x, y ningún δ tiene un objetivo menor que el propio x (ejercicio 3). Si c‖w‖ > 1, el camino alcanza la frontera, a distancia m/‖w‖, y da vueltas alrededor de ella. El punto que se guarda es el del ciclo con el menor objetivo. Está más allá de la frontera con probabilidad 1/2 con c‖w‖ = 2 y 1/3 con c‖w‖ = 1,5, según dónde caiga la frontera entre dos pasos. P3 da 2000 pasos con lr = 0,01 sobre los puntos bien clasificados:

```text
== P3, cw_attack with the hinge loss max(m, 0), lr 0.01, 2000 steps, on the correctly classified points
  c = 0.25 (c|w| = 0.5): 1956 points, 1956 returned unchanged, misclassified 0.0000 (predicted every result x), largest | |delta| - m/|w| | 5.8712
  c = 1.00 (c|w| = 2.0): 1956 points, 1 returned unchanged, misclassified 0.5072 (predicted [0.464, 0.536]), largest | |delta| - m/|w| | 0.0050
  c = 0.75 (c|w| = 1.5): 1956 points, 1 returned unchanged, misclassified 0.3522 (predicted [0.299, 0.367]), largest | |delta| - m/|w| | 0.0033
```

Con c = 0,25, los 1956 resultados son el propio x. El ataque no encuentra nada, y quien lo lea como robustez solo ha elegido un c demasiado pequeño. Con c = 1 y 0,75, 0,5072 y 0,3522 de los resultados están más allá de la frontera. Cada resultado queda a menos de 0,005 de la perturbación mínima, más cerca que los 0,02 predichos, porque el objetivo se queda con el más cercano de los puntos alrededor de la frontera. El único punto devuelto intacto con c = 1 y 0,75 es el más cercano a la frontera: su primer paso ya la sobrepasa en más que la distancia ahorrada. El éxito se decide punto por punto, según dónde caiga la frontera entre dos pasos, no según el modelo. La búsqueda sobre c de Carlini y Wagner, con una comprobación de que cada resultado está mal clasificado, es lo que hace fiable el ataque. La función de IX no hace ninguna de las dos cosas. La comprobación cruzada sigue el mismo camino como una recurrencia escalar con numpy y encuentra los mismos recuentos.

## 5. Las perturbaciones universales y JSMA

Una perturbación universal, según [Moosavi-Dezfooli et al. (2017)](https://doi.org/10.1109/CVPR.2017.17), es un único vector v que engaña al modelo en la mayoría de las entradas. Para cada entrada que v aún no engaña, suman el menor cambio que lleva x + v a la frontera, hallado por DeepFool, y luego proyectan v en una bola de radio ε. Para un modelo lineal, el paso de DeepFool es exacto: −m·y·w/‖w‖², de longitud m/‖w‖ ([Moosavi-Dezfooli et al. 2016](https://doi.org/10.1109/CVPR.2016.282)). `universal_perturbation` de IX suma en cambio grad·pérdida/‖grad‖ ([`evasion.rs` 107-144](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L107-L144)), un paso a lo largo de `gradient_fn` tan largo como la pérdida. El comentario de documentación no dice si `gradient_fn` es el gradiente de la pérdida o la dirección que engaña al modelo. P4 le da un punto bien clasificado cada vez, con pérdida = m, en las dos direcciones:

```text
== P4, universal_perturbation on one correctly classified point, one iteration, loss = m
  1956 points, largest relative error of the new margin against
    m(1 - |w|) = -m with the fooling direction -y w:   8.8e-14
    m(1 + |w|) = 3m with the loss's gradient +y w:     1.2e-14
    m'(1 - |w|/4) = m'/2 with w/4, m' = m/4:           9.7e-14
  length of the w/4 perturbation against a quarter of the full one: 0.0e0
```

Con la dirección que engaña, el margen pasa de m a −m. El paso es el doble del de DeepFool, porque la pérdida m vale ‖w‖ = 2 veces la distancia m/‖w‖. Con el gradiente de la pérdida, el margen se triplica, y la perturbación ayuda al modelo. Dividir w entre 4 describe el mismo clasificador, pero el paso se vuelve cuatro veces más corto y se detiene a mitad de camino de la frontera. La longitud del paso depende de la escala de la pérdida, y la de una perturbación mínima no debería.

`jsma`, el ataque por saliencia de [Papernot et al. (2016)](https://arxiv.org/abs/1511.07528), tiene un hueco del mismo tipo: recibe un argumento `_target` y nunca lo lee ([`evasion.rs` 73-105](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L73-L105)). Una comprobación exploratoria, no prerregistrada, confirma que devuelve el mismo punto para los dos objetivos:

```text
== exploratory
  jsma returns the same point for targets 0 and 1: yes
```

## 6. La detección por ruido

`detect_adversarial` suma un ruido gaussiano a la entrada `n_samples` veces, mide el cambio cuadrático medio de la salida y marca la entrada cuando supera un umbral ([`defense.rs` 29-60](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs#L29-L60)). Su comentario da el razonamiento: «High variance suggests the input sits near a decision boundary — a hallmark of adversarial examples.» Dos detalles deciden lo que mide. El ruido sale de un generador inicializado con un `seed` fijo, así que cada entrada recibe los mismos vectores de ruido. Y para una salida lineal (z, −z), el cambio vale (w·n, −w·n), que no depende en absoluto de x. P5 la ejecuta sobre los 2000 puntos de prueba limpios y sus versiones FGSM con ε = 0,2, con las salidas (z, −z) y luego con las probabilidades (p, 1 − p):

```text
== P5, detect_adversarial, sigma 0.1, 50 samples, the 2000 clean points and their FGSM versions at eps 0.2
  outputs (z, -z): score of the first input 0.0353 (expectation 0.04); 4000 of 4000 inputs have it to within 1e-12
  flagged at threshold 0.015: 4000; at 0.09: 0
  control, outputs (p, 1 - p): score nearest the boundary 2.16e-3, farthest 2.25e-12; more than 10 times: yes
```

Las 4000 entradas tienen la misma puntuación con un error menor que 10⁻¹². Vale 0,0353, un sorteo alrededor de su esperanza σ²‖w‖² = 0,04. Sea cual sea el umbral, el detector marca todas las entradas o ninguna. Con probabilidades, la puntuación sí depende de la entrada: 2,16·10⁻³ en la más cercana a la frontera frente a 2,25·10⁻¹² en la más lejana. No se midió cómo separa entonces las entradas limpias de las atacadas; el diario lo deja por verificar. La función solo devuelve un booleano, así que la lección recupera cada puntuación por bisección sobre el umbral, y quien quiera calibrar el umbral tiene que hacer lo mismo.

## 7. La compresión de características

`feature_squeezing` limita cada valor a [0, 1] y lo redondea a uno de L + 1 niveles, L = 2^bits − 1. Está documentada como «eliminating small adversarial perturbations that fall below the quantization resolution» ([`defense.rs` 62-72](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs#L62-L72)). El redondeo no elimina un cambio, lo concentra. Un valor movido ε se redondea de otra forma cuando un umbral (k + ½)/L cae entre el valor antiguo y el nuevo. Para valores uniformes eso ocurre con probabilidad Lε, y el valor redondeado se mueve entonces un nivel entero, 1/L. El cambio absoluto medio sigue siendo ε, y su media cuadrática crece hasta √(ε/L). P6 comprime 100 000 valores uniformes, antes y después de un cambio de ±ε:

```text
== P6, feature_squeezing of 100000 uniform values moved by +-eps
  3 bits, eps 0.05: changed 0.3510, mean |change| 0.05014, root mean square 0.08463   (formula 0.350, 0.05000, 0.08452)
  5 bits, eps 0.01: changed 0.3094, mean |change| 0.00998, root mean square 0.01794   (formula 0.310, 0.01000, 0.01796)
  0 bits: [NaN, NaN, NaN, NaN]
```

Con 3 bits, el 35 % de los cambios de 0,05 sobrevive, cada uno como un salto de 1/7, y el cambio medio después de comprimir vale 0,0501, el mismo que antes. [Xu et al. (2018)](https://doi.org/10.14722/ndss.2018.23198) no usan la compresión para limpiar entradas. Comparan las salidas del modelo sobre una entrada y sobre su versión comprimida, y marcan la entrada cuando difieren. Con 0 bits, L = 0 y cada salida vale 0/0.

## 8. El radio certificado

El suavizado aleatorio de [Cohen et al. (2019)](https://arxiv.org/abs/1902.02918) clasifica x según la clase más probable bajo x + N(0, σ²I). Si esa clase tiene probabilidad de al menos p_A y cualquier otra de como mucho p_B, la predicción no puede cambiar dentro de un radio ℓ₂ de σ/2·(Φ⁻¹(p_A) − Φ⁻¹(p_B)). `certified_radius` calcula esa cota a partir de los dos valores mayores de su entrada, que su comentario de documentación llama logits, después de limitarlos a [10⁻¹⁰, 1 − 10⁻¹⁰] ([`robustness.rs` 111-144](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs#L111-L144)). Su `probit` lleva la etiqueta «Beasley-Springer-Moro», pero usa las constantes de la fórmula 26.2.23 de [Abramowitz y Stegun](https://personal.math.ubc.ca/~cbm/aands/page_933.htm), cuyo error es menor que 4,5·10⁻⁴ ([`robustness.rs` 146-174](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs#L146-L174)). P7 lo compara con σ = 1 con el radio exacto. El curso calcula Φ⁻¹ con el AS 241 de [Wichura (1988)](https://doi.org/10.2307/2347330), exacto con unas 16 cifras y probado con cuantiles conocidos:

```text
== P7, certified_radius at sigma 1 against the exact radius (AS 241)
  p_A = 0.501 to 0.999, p_B = 1 - p_A: largest error 4.44e-4, at p_A = 0.642
  p_A = 0.9: IX 1.281729, exact 1.281552
  logits (2, -1): 6.3609; logits (3, 1): 0.0000
```

El mayor error vale 4,44·10⁻⁴, en p_A = 0,642, justo por debajo de la cota de la fórmula. En p_A = 0,9, el radio de IX supera al exacto en 1,8·10⁻⁴: poco, pero en el sentido peligroso para un certificado. Los logits son la trampa mayor. Los logits (2, −1) se limitan a 1 − 10⁻¹⁰ y 10⁻¹⁰ y certifican un radio de 6,36σ, mientras que los logits (3, 1) se limitan los dos a 1 − 10⁻¹⁰ y certifican 0. La función necesita probabilidades. Cohen et al. usan una cota de confianza inferior sobre p_A, estimada a partir de muestras del ruido, que IX deja al llamador.

## 9. El envenenamiento

El envenenamiento cambia los datos de entrenamiento en lugar de la entrada, y el crate tiene tres herramientas contra él ([`poisoning.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/poisoning.rs)):

- `detect_label_flips` marca un punto cuya etiqueta contradice la mayoría de sus k vecinos más cercanos (líneas 14-61).
- `spectral_signature_defense`, según [Tran et al. (2018)](https://arxiv.org/abs/1811.00636), proyecta cada clase sobre su primera dirección principal y marca los puntos estrictamente por encima del percentil dado de las proyecciones de la clase (líneas 105-180).
- `influence_function` cita a [Koh y Liang (2017)](https://arxiv.org/abs/1703.04730). Su influencia de un punto de entrenamiento sobre una predicción de prueba pasa por el gradiente de la pérdida de ese punto, y por tanto por su etiqueta. La versión de IX ignora `_train_labels`: cada puntuación vale (xᵢ·x_test)·(y_test − x̄·x_test)/(n·λ), donde x̄ es la fila de entrenamiento media (líneas 63-103).

P8 invierte 100 de las 1000 etiquetas de dos grupos alrededor de (−2, −2) y (2, 2). Luego envenena una clase de 100 puntos en 10 dimensiones con 5 puntos desplazados 6 en una característica:

```text
== P8, poisoning
  1000 points in 2 dimensions, 100 labels flipped: influence_function unchanged bit for bit: yes
  detect_label_flips, k = 5: 99 flipped labels found, 11 other points flagged
  spectral_signature_defense, 90th percentile, 100 points per class in 10 dimensions: flagged per class [9, 9]
  with 5 points shifted by 6 added to class 0: flagged per class [10, 9], shifted points among them 5
```

Las puntuaciones de influencia no cambian cuando cambia el 10 % de las etiquetas, así que no pueden señalar los puntos de entrenamiento a los que perjudica una etiqueta invertida. La votación de los vecinos encuentra 99 de las 100 etiquetas invertidas. Un punto invertido solo se escapa si al menos 3 de sus 5 vecinos también se invirtieron, lo que tiene probabilidad 0,009. La votación marca además 11 puntos correctos, por debajo de los 17 predichos. La defensa espectral marca 9 puntos por clase en el percentil 90, no los 10 que sugiere «el 10 % superior», porque marca las puntuaciones estrictamente por encima de la de índice ⌊0,9·n⌋. Con los 5 puntos desplazados en la clase 0, marca 10 allí, y los 5 están entre ellos. La comprobación cruzada repite la votación y la defensa espectral con numpy, con sus propios vectores propios, y encuentra los mismos recuentos.

## 10. Una constante de Lipschitz por muestreo

`lipschitz_estimate` toma puntos al azar dentro de un radio y devuelve el mayor cociente ‖f(x') − f(x)‖/‖x' − x‖ ([`robustness.rs` 72-109](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs#L72-L109)). El muestreo solo puede dar una cota inferior. Una segunda comprobación exploratoria estira por 10 la primera de 100 coordenadas, una aplicación cuya constante de Lipschitz vale 10:

```text
== exploratory
  lipschitz_estimate of x -> (10 x_0, x_1, ..., x_99), constant 10, 200 samples, 20 seeds: lowest 2.617, median 3.021, highest 3.838
```

Las estimaciones van de 2,6 a 3,8. Una dirección unitaria aleatoria u pone de media 1/100 de su longitud al cuadrado en la primera coordenada, y el cociente vale √(1 + 99u₀²), alrededor de 1,4 de media. El mayor de 200 sorteos llega a unos 3. Para una aplicación lineal, la constante es el mayor valor singular. Para una red, el muestreo encuentra una cota inferior, y en 100 dimensiones una cota holgada.

## 11. Las predicciones, puntuadas

| | Predicción, escrita antes de la primera ejecución | Medido | Veredicto |
|---|---|---|---|
| P1 | Cada margen 20ε más bajo con un error menor que 10⁻¹²; exactamente los puntos con 0 < m < 20ε cambian de clase; exactitud en [0,967, 0,988], [0,815, 0,867], [0,464, 0,536] y [0,133, 0,185] | 0,9780, 0,8460, 0,4780, 0,1470; márgenes y puntos como se predijo | Confirmada |
| P2 | Gradiente nulo: `pgd` y `adversarial_training_augment` en x ± 0,2, `fgsm` en x; medio modelo: 100 características frente a 50, normas 2 y 1,414, misma exactitud; control: `pgd` igual a `fgsm` | Como se predijo; exactitud 0,4865 para los dos | Confirmada |
| P3 | c = 0,25: cada resultado es x; c = 1: ‖δ‖ a menos de 0,02 de m/‖w‖, mal clasificados en [0,464, 0,536]; c = 0,75: en [0,299, 0,367] | 1956 de 1956; a menos de 0,005, 0,5072; 0,3522 | Confirmada |
| P4 | Nuevo margen −m con −y·w, 3m con +y·w, m'/2 y un cuarto de la longitud con w/4, con un error relativo menor que 10⁻¹² | Mayor error relativo 9,7·10⁻¹⁴ | Confirmada |
| P5 | Todas las puntuaciones iguales con un error menor que 10⁻¹², cerca de 0,04; todo marcado con 0,015, nada con 0,09; con probabilidades, la mayor más de 10 veces la menor | 4000 de 4000 en 0,0353; 4000 y 0; 2,16·10⁻³ frente a 2,25·10⁻¹² | Confirmada |
| P6 | 3 bits, ε = 0,05: 0,350 ± 0,005 cambiados, media 0,05 y media cuadrática 0,0845 con un margen del 2 %; 5 bits, ε = 0,01: 0,310, 0,01, 0,0180; 0 bits: NaN | 0,3510, 0,05014, 0,08463; 0,3094, 0,00998, 0,01794; NaN | Confirmada |
| P7 | Mayor error en [10⁻⁴, 4,5·10⁻⁴]; logits (2, −1) unos 6,36; (3, 1) 0 | 4,44·10⁻⁴; 6,3609; 0 | Confirmada |
| P8 | Influencia idéntica bit a bit; al menos 95 de las 100 inversiones encontradas, como mucho 17 más; espectral 9 y 9, luego 10 en la clase 0 con los 5 | Idéntica; 99 y 11; 9 y 9, luego 10 con los 5 | Confirmada |

Las ocho se cumplieron en la primera ejecución, y el código compiló a la primera. Ningún intervalo se cambió después. Un resultado es más ajustado de lo predicho: los resultados de Carlini–Wagner quedan a menos de 0,005 de la perturbación mínima, no a 0,02, porque el objetivo se queda con el más cercano de los puntos alrededor de la frontera. La mayoría de las predicciones venían de leer una función frente a su comentario, y la mayoría encontró un hueco entre los dos. Los controles muestran que cada comprobación puede fallar: frente al modelo completo PGD es igual a FGSM, con probabilidades la puntuación del detector depende de la entrada, y la defensa espectral sí encuentra los puntos desplazados.

## Qué usar en nuestros repositorios

- **`fgsm`:** exacta en un modelo lineal, donde cada margen baja ε‖w‖₁. Un buen primer ataque, y un número que publicar junto a la exactitud sobre las entradas limpias.
- **`pgd` y `adversarial_training_augment`:** mueven el ε completo cada característica que la pérdida ignora, en una dirección fijada por el signo de cero, y ningún valor finito del gradiente lo evita, porque `signum` nunca devuelve 0. Devuelve esas características a su sitio después de la llamada, o repite `fgsm` en un bucle con un recorte.
- **`cw_attack`:** busca tú mismo sobre c, por encima de 1/‖∇pérdida‖, y comprueba que cada resultado está mal clasificado. Con c‖w‖ = 2, la mitad no lo estaba.
- **`universal_perturbation`:** pasa la dirección que engaña, no el gradiente de la pérdida, y cuenta con pasos tan largos como la pérdida, no como la distancia a la frontera.
- **`detect_adversarial`:** inútil sobre una salida lineal. Como solo devuelve un booleano, calibra su umbral con entradas limpias por bisección.
- **`feature_squeezing`:** compara las salidas del modelo con ella y sin ella, como Xu et al., en lugar de confiar en que limpie una entrada. Usa al menos 1 bit.
- **`certified_radius`:** pasa una cota inferior sobre p_A, no logits. Su probit puede sobrestimar el radio hasta en 4,4·10⁻⁴σ.
- **El envenenamiento:** `detect_label_flips` funciona con grupos separados, con 99 de las 100 inversiones encontradas y 11 falsas alarmas. `influence_function` no lee las etiquetas, así que no puede encontrar las invertidas. `spectral_signature_defense` marca n − ⌊p·n/100⌋ − 1 puntos por clase.

## Ejercicios

1. Demuestra que FGSM baja cada margen de un modelo lineal en ε‖w‖₁, y que en el modelo de esta lección la exactitud pasa a ser Φ(2 − 10ε).
2. Para un modelo lineal, ¿cuáles son las menores perturbaciones ℓ₂ y ℓ∞ que llevan un punto de margen m a la frontera? Evalúalas con m = 4 para el w de esta lección.
3. Demuestra que para el objetivo ‖δ‖₂ + c·max(m(x + δ), 0) de un modelo lineal, ningún δ tiene un objetivo menor que δ = 0 cuando c‖w‖ ≤ 1.
4. Para valores uniformes en [0, 1] redondeados a L + 1 niveles, halla la probabilidad de que un cambio de ±ε ≤ 1/(2L) cambie el valor redondeado, y la media cuadrática del cambio después de redondear.
5. ¿Por qué `detect_adversarial` da la misma puntuación a cada entrada con salidas (z, −z)? ¿Qué cambiaría si cada llamada sorteara un ruido nuevo?

<details>
<summary>Soluciones</summary>

1. El gradiente es un múltiplo positivo de −y·w, así que x' = x − ε·y·sign(w) y m' = y·w·x' = m − ε·Σ|wⱼ| = m − ε‖w‖₁. Aquí m = ‖μ‖² + y·w·n sigue N(4, ‖w‖²) = N(4, 4), así que P(m' > 0) = P(N(4, 4) > 20ε) = Φ((4 − 20ε)/2) = Φ(2 − 10ε).
2. La perturbación ℓ₂ vale −m·y·w/‖w‖₂², de longitud m/‖w‖₂. La ℓ∞ mueve cada coordenada m/‖w‖₁ contra la clase. Con ‖w‖₂ = 2, ‖w‖₁ = 20 y m = 4: 2 y 0,2. Como todos los wⱼ son iguales aquí, las dos son el mismo vector: 0,2 contra la clase en cada característica, un quinto del ruido, de longitud ℓ₂ 2 y longitud ℓ∞ 0,2.
3. Por Cauchy–Schwarz, m(x + δ) ≥ m − ‖w‖‖δ‖. Si ‖δ‖ < m/‖w‖, el objetivo vale al menos ‖δ‖ + c(m − ‖w‖‖δ‖) = cm + ‖δ‖(1 − c‖w‖) ≥ cm. Si no, vale al menos ‖δ‖ ≥ m/‖w‖ ≥ cm. En los dos casos vale al menos cm, el objetivo en δ = 0.
4. Los umbrales están en (k + ½)/L para k = 0, …, L − 1. Un movimiento de +ε cruza un umbral τ cuando x está en (τ − ε, τ), con probabilidad ε, y como mucho uno cuando ε ≤ 1/(2L). Lo mismo vale para −ε, así que la probabilidad es Lε. Cada cruce mueve el valor redondeado 1/L, así que el cuadrado medio vale Lε/L² = ε/L y la media cuadrática √(ε/L).
5. El cambio de la salida vale (w·n, −w·n) para un ruido n, sea cual sea x, y la semilla fija da a cada entrada los mismos ruidos. La puntuación vale Σₖ 2(w·nₖ)²/(2·50), idéntica para todas las entradas. Con ruido nuevo, las puntuaciones variarían alrededor de σ²‖w‖², como una χ² con 50 grados de libertad escalada, pero seguirían sin depender de x: ruido, no información.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [`evasion.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs), [`defense.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs), [`poisoning.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/poisoning.rs), [`robustness.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs).
- I. J. Goodfellow, J. Shlens y C. Szegedy, [«Explaining and harnessing adversarial examples»](https://arxiv.org/abs/1412.6572), ICLR 2015.
- A. Madry, A. Makelov, L. Schmidt, D. Tsipras y A. Vladu, [«Towards deep learning models resistant to adversarial attacks»](https://arxiv.org/abs/1706.06083), ICLR 2018.
- N. Carlini y D. Wagner, [«Towards evaluating the robustness of neural networks»](https://doi.org/10.1109/SP.2017.49), IEEE Symposium on Security and Privacy, 2017.
- N. Papernot, P. McDaniel, S. Jha, M. Fredrikson, Z. B. Celik y A. Swami, [«The limitations of deep learning in adversarial settings»](https://arxiv.org/abs/1511.07528), IEEE European Symposium on Security and Privacy, 2016.
- S.-M. Moosavi-Dezfooli, A. Fawzi y P. Frossard, [«DeepFool: a simple and accurate method to fool deep neural networks»](https://doi.org/10.1109/CVPR.2016.282), CVPR 2016; con O. Fawzi, [«Universal adversarial perturbations»](https://doi.org/10.1109/CVPR.2017.17), CVPR 2017.
- W. Xu, D. Evans y Y. Qi, [«Feature squeezing: detecting adversarial examples in deep neural networks»](https://doi.org/10.14722/ndss.2018.23198), NDSS 2018.
- J. Cohen, E. Rosenfeld y J. Z. Kolter, [«Certified adversarial robustness via randomized smoothing»](https://arxiv.org/abs/1902.02918), ICML 2019.
- M. Abramowitz e I. A. Stegun, *Handbook of Mathematical Functions*, [fórmula 26.2.23](https://personal.math.ubc.ca/~cbm/aands/page_933.htm). M. J. Wichura, [«Algorithm AS 241: the percentage points of the normal distribution»](https://doi.org/10.2307/2347330), Applied Statistics 37, 1988.
- P. W. Koh y P. Liang, [«Understanding black-box predictions via influence functions»](https://arxiv.org/abs/1703.04730), ICML 2017.
- B. Tran, J. Li y A. Madry, [«Spectral signatures in backdoor attacks»](https://arxiv.org/abs/1811.00636), NeurIPS 2018.
- Rust: [`f64::signum`](https://doc.rust-lang.org/std/primitive.f64.html#method.signum). NumPy: [`sign`](https://numpy.org/doc/stable/reference/generated/numpy.sign.html).
