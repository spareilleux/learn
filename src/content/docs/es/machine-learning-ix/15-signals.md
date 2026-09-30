---
title: "15. Señales: la transformada de Fourier, ondículas, filtros y Kalman"
description: "La FFT, la densidad de Welch, los filtros FIR e IIR, las ondículas de Haar y el filtro de Kalman frente al crate ix-signal de IX, con nueve predicciones escritas antes de la primera ejecución, que se cumplen todas. Los diseños de manual salen exactos; la densidad de Welch de IX cubre la mitad de la varianza y etiqueta mal sus frecuencias cuando un segmento no es potencia de dos, el error de su FFT crece linealmente con N, y su transformada de Haar trunca donde su contrato promete un pánico."
sidebar:
  order: 15
---

Una señal es una sucesión de números muestreados a intervalos regulares: un sonido, un sensor, un precio, una métrica tomada cada minuto. El crate [`ix-signal`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal) de IX, fijado, tiene sus herramientas clásicas: la transformada rápida de Fourier, las funciones de ventana, la densidad espectral de potencia de Welch, los filtros FIR e IIR, las ondículas de Haar y el filtro de Kalman. La [lección 12](../12-autodiff/) ya derivó a través de su FFT. Esta lección mide lo que devuelve cada herramienta frente a lo que dice la teoría, y comprueba lo que promete el [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md) de IX.

Las nueve predicciones que prueba esta lección se [escribieron en el diario](../journal/#2026-09-30--lección-15-predicha-antes-de-medir) y se registraron en un commit antes de que existiera su código. [Los resultados](../journal/#2026-09-30--lección-15-medida) las siguen. Los experimentos están en [`signal.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/signal.rs), un test por predicción. [`l15_signals.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l15_signals.rs) imprime lo que miden. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcula la densidad de Welch, los coeficientes del Butterworth, la ganancia de Kalman y los coeficientes FIR con [numpy](https://numpy.org/doc/stable/) y [SciPy](https://docs.scipy.org/doc/scipy/). El ruido viene del `Rng` del curso, como sumas de doce uniformes menos seis, igual que en la [lección 14](../14-reinforcement-learning/), así que los tres sistemas del CI sacan los mismos números.

## 1. La FFT y sus factores de giro

La transformada discreta de Fourier de N muestras es

X_k = Σⱼ xⱼ e^(−2πi·jk/N), k = 0, …, N − 1.

Calculada tal como está escrita, cuesta N² multiplicaciones. El algoritmo de base 2 de [Cooley y Tukey](https://doi.org/10.1090/S0025-5718-1965-0178586-1) divide la suma en muestras pares e impares, el doble de cortas, y las recombina con los *factores de giro* (twiddle factors) w^k = e^(−2πik/L), en log₂ N etapas de N/2 operaciones cada una. La `fft` de IX rellena su entrada con ceros hasta la siguiente potencia de dos ([`CONTRACTS.md` 8](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L8)), y `ifft` divide por N.

En cada etapa, IX calcula un coseno y un seno, y obtiene los demás factores multiplicando otra vez por ese ([`fft.rs` 169-178](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/fft.rs#L169-L178)). El k-ésimo factor lleva k redondeos, y parte del error es sistemático. Para un ángulo pequeño, cos θ queda justo por debajo de 1 y se redondea a menos de medio ulp de él, unos 5,5 × 10⁻¹⁷. El módulo de w deriva entonces unas k veces eso. `reference_fft` en `signal.rs` es el mismo algoritmo, con cada factor calculado directamente. `direct_dft` es la suma de arriba con sumas compensadas. P3 las compara con una entrada uniforme en [−1, 1]:

```text
== IX's FFT against a reference whose twiddles are computed one by one
  N = 2^8   relative RMS error 1e-15 to 1e-14
  N = 2^12  relative RMS error 1e-14 to 1e-13
  N = 2^16  relative RMS error 1e-13 to 1e-12
  error at 2^16 / error at 2^8: at least 16: true
  N = 2^10, the reference against the DFT by its definition: 1e-16 to 1e-15
```

El ejemplo imprime décadas, porque el `cos` y el `sin` de cada plataforma mueven las últimas cifras. En Windows, el error vale 1,8 × 10⁻¹⁵ con 2⁸, 2,9 × 10⁻¹⁴ con 2¹², 1,3 × 10⁻¹³ con 2¹⁴ y 5,4 × 10⁻¹³ con 2¹⁶. Se multiplica por unos cuatro cada vez que N lo hace. Crece linealmente: 300 veces de 2⁸ a 2¹⁶, donde un crecimiento en log N daría 2. La referencia queda a 3,9 × 10⁻¹⁶ de la DFT directa. El control cruzado con numpy repite la recurrencia de IX frente a [`numpy.fft`](https://numpy.org/doc/stable/reference/routines.fft.html) y cae en las mismas décadas.

[`CONTRACTS.md` 39](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L39) dice que los factores se «calculan con `f64::cos/sin`» y que las plataformas pueden diferir «a escala de ULP». Con 2¹⁶ el error ronda los 2400 ulps de 1. Aún deja doce cifras correctas, de sobra para un espectro. Pero sigue creciendo con N, y ya no es lo que describe el contrato. Una tabla de factores calculados directamente, como en la referencia, solo cuesta N/2 valores. [Schatzman (1996)](https://doi.org/10.1137/S1064827593247023) lo dice en su resumen: «Popular recursions for fast computation of the sine/cosine table (or twiddle factors) are inaccurate due to inherent instability.»

## 2. La densidad de Welch

Un espectro muestra dónde está la potencia de una señal en frecuencia. El periodograma |X_k|² de la señal entera es ruidoso. [Welch (1967)](https://doi.org/10.1109/TAU.1967.1161901) corta la señal en segmentos solapados, multiplica cada uno por una ventana y promedia sus periodogramas. La ventana atenúa los extremos del segmento, para que una frecuencia caída entre dos bandas se fugue menos a las demás. [Harris (1978)](https://doi.org/10.1109/PROC.1978.10837) compara las ventanas clásicas. La `welch_psd` de IX usa una ventana de Hann y divide cada |X_k|² por Σw² y por la frecuencia de muestreo ([`spectral.rs` 79-92](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs#L79-L92)). Para un ruido blanco de varianza σ², cada banda vale entonces σ²/fs en promedio.

El espectro de una señal real es simétrico: la banda N − k lleva la misma potencia que la banda k. Una densidad *unilateral* conserva las bandas 0 a N/2 y duplica las bandas 1 a N/2 − 1, para integrar a la varianza (Parseval). Es la densidad que devuelve por defecto [`scipy.signal.welch`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html). IX devuelve las mismas bandas sin duplicarlas (P1):

```text
== Welch's density, 16,384 samples of unit-variance noise, fs 1000, segments 512
  integral / variance, as IX returns it:     0.503
  bins 1 to 255 doubled (one-sided):         1.002
```

La densidad de IX integra a la mitad de la varianza, 257/512 de ella. En el control cruzado, `scipy.signal.welch`, con la misma ventana de Hann simétrica y sin quitar la tendencia, devuelve exactamente el doble de la convención de IX en las bandas 1 a 255, a menos de 10⁻⁹, y el mismo valor en las bandas 0 y 256. Ninguna de las dos convenciones es errónea. Una densidad bilateral es igual de legítima, pero cubriría también las frecuencias negativas, y el comentario de documentación de IX no nombra ninguna. Comparados con SciPy o con una varianza, los valores de IX salen la mitad de grandes.

La segunda trampa está en el eje de frecuencias. `rfft` rellena un segmento hasta la siguiente potencia de dos. `welch_psd` conserva window_size/2 + 1 bandas de esa transformada más larga, y etiqueta la banda k como k·fs/window_size ([`spectral.rs` 94-96](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs#L94-L96)). Con segmentos de 300, la transformada tiene 512 bandas, la banda k está en k·1000/512 Hz y solo se conservan las bandas 0 a 150, hasta 293 Hz (P2):

```text
== welch_psd on sines, fs 1000, 8,192 samples
  200 Hz, segments of 300: 151 bins, peak at index 102, labelled 340.0 Hz
  400 Hz, segments of 300: 151 bins, peak at index 149, labelled 496.7 Hz
  200 Hz, segments of 256: 129 bins, peak at index 51, labelled 199.2 Hz
  400 Hz, segments of 256: 129 bins, peak at index 102, labelled 398.4 Hz
  segments of 300: largest value of the 400 Hz sine / the 200 Hz peak: 1e-11 to 1e-10
```

Una senoide de 200 Hz cae en la banda 102, a 199,2 Hz, e IX la etiqueta 340 Hz. Una senoide de 400 Hz cae en la banda 204,8, más allá de lo que se devuelve. Solo queda la cola de la fuga de la ventana, de 10⁻¹¹ a 10⁻¹⁰ de un pico real, y su mayor valor está en el borde superior, etiquetado 496,7 Hz. Con segmentos de 256, ambas senoides están donde deben, a menos de una banda. `spectrogram` conserva las mismas window_size/2 + 1 bandas de la transformada rellenada ([`spectral.rs` 33-54](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs#L33-L54)). Eso sale de leer el código; esta lección no lo mide.

## 3. Filtros FIR: el seno cardinal con ventana

Un filtro de respuesta al impulso finita (FIR) sustituye cada muestra por una suma ponderada de las últimas M + 1 entradas: y[n] = Σₘ h[m]·x[n − m]. El paso bajo ideal con frecuencia de corte fc tiene la respuesta al impulso 2fc·sinc(2fc·m), que es infinita. `FirFilter::lowpass(cutoff, order)` la centra en order/2, la trunca a order + 1 coeficientes y la multiplica por una ventana de Hamming ([`filter.rs` 17-37](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs#L17-L37)). Los coeficientes son simétricos, así que el filtro retrasa todas las frecuencias las mismas order/2 muestras. `highpass` resta el paso bajo de un impulso unidad en order/2, y conserva así lo que el paso bajo quita ([`filter.rs` 40-50](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs#L40-L50)). P8:

```text
== FIR filters
  highpass(0.25, 31) at f 0.05: gain 0.1569
  highpass(0.25, 32) at f 0.05: gain 0.00046
  lowpass(0.1, 64): gain on [0, 0.05] 0.9995 to 1.0003, largest on [0.15, 0.5] 0.00184
  lowpass(0.1, 64): centre tap 0.200000000, sum of the taps 1.000041082
  lowpass(0.1, 64) on a sine at 0.02: largest |y[n] - x[n - 32]| after 64 samples 0.0002
```

Las frecuencias están en ciclos por muestra, así que 0,5 es Nyquist. Con un orden par, el seno cardinal con ventana hace lo que dice el manual. `lowpass(0.1, 64)` se queda a menos de 5 × 10⁻⁴ de 1 en su banda de paso y vale como mucho 0,00184 (−54,7 dB) a partir de 0,15, y una senoide sale con 32 muestras de retraso. [`scipy.signal.firwin`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.firwin.html)`(65, 0.2, window="hamming", scale=False)` da el mismo coeficiente central y la misma suma de coeficientes. Esa suma, 1,000041, es la ganancia en continua. IX no la normaliza; `firwin` sí, por defecto.

El comentario de `lowpass` dice que el orden «debe ser par». Nada lo comprueba, y `highpass` no lo repite. Con el orden 31 hay 32 coeficientes, y el paso bajo queda centrado en 15,5, entre dos de ellos. El impulso va al índice 31/2 = 15, media muestra antes, y la resta ya no anula la banda baja: la ganancia allí es |1 − e^(−iπf)| = 2 sen(πf/2), 0,157 en f = 0,05. IX mide 0,1569, donde el orden par deja pasar 0,00046. La razón de fondo es que un filtro simétrico con un número par de coeficientes siempre tiene un cero en Nyquist, así que no puede ser un paso alto en absoluto. `firwin` se niega a diseñar uno: el control cruzado imprime su `ValueError`.

## 4. Filtros IIR: el Butterworth

Un filtro de respuesta al impulso infinita (IIR) también realimenta sus salidas pasadas: y[n] = Σ b_k·x[n − k] − Σ a_k·y[n − k]. `butterworth_lowpass_2nd` diseña un Butterworth de orden 2, cuya ganancia es lo más plana posible en la banda de paso, con la transformación bilineal. El corte analógico se predistorsiona con tan(π·fc), para que el punto de −3 dB del filtro digital caiga exactamente en fc ([`filter.rs` 145-158](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs#L145-L158)). P4:

```text
== Second-order Butterworth, fc 0.1
  b [0.067455274, 0.134910548, 0.067455274]
  a [1.000000000, -1.142980503, 0.412801598]
  gain at DC 1.000000000000, at fc 0.707106781187, at Nyquist 0
  a sine at fc through IirFilter::apply: amplitude 0.7071
```

[`scipy.signal.butter`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.butter.html)`(2, 0.2)` devuelve los mismos coeficientes en los nueve decimales que imprime el control cruzado, y a menos de 1,7 × 10⁻¹⁶ en una comparación puntual a precisión completa en Windows (SciPy mide el corte respecto a Nyquist, de ahí 0,2). La ganancia es 1 en continua y 1/√2 en fc, con doce decimales. En Nyquist, z = −1 y la ganancia es b₀ − b₁ + b₂, exactamente 0: IX calcula b₁ como 2·wc²/k y b₀ como wc²/k, y multiplicar por 2 no redondea. El `first_order_lowpass` del mismo archivo es la media móvil exponencial y[n] = α·x[n] + (1 − α)·y[n − 1]. La sección 6 vuelve a encontrarla.

## 5. Ondículas de Haar

La transformada de Fourier dice qué frecuencias contiene una señal, no cuándo. Una transformada de ondículas responde a ambas cosas, a varias escalas. La de Haar es la más sencilla. Cada par (a, b) se convierte en una media (a + b)/√2 y un detalle (a − b)/√2, y las medias se vuelven a dividir, nivel tras nivel. La transformada es ortonormal: un ruido blanco de varianza σ² sigue siendo blanco, con varianza σ² en cada coeficiente. Una señal limpia hecha de escalones tiene detalles nulos allí donde un par no cruza un salto. [Donoho y Johnstone (1994)](https://doi.org/10.1093/biomet/81.3.425) eliminan el ruido acercando cada detalle a 0 en un umbral t (umbral suave), con el umbral universal t = σ√(2 ln N). `wavelet_denoise` hace exactamente eso ([`wavelet.rs` 62-82](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs#L62-L82)). P6 y P7:

```text
== Haar wavelets
  12 samples, 3 levels: approximation 1, details [6, 3, 1], haar_idwt returns 8, wavelet_denoise returns 8
  16 samples, 4 levels: round trip within 1e-12: true
  blocks of 64, sigma 0.5, 5 levels, universal threshold, 20 draws (15 jumps)
    jumps on multiples of 64: MSE / sigma^2 0.0360
    shifted by 16:            MSE / sigma^2 0.1953 (5.4 times)
```

Con los saltos en múltiplos de 64, los cinco niveles ven bloques de 2 a 32 muestras que nunca cruzan un salto. Cada detalle limpio es nulo, y el umbral quita casi todo el ruido que llevan. Queda el ruido de los 32 coeficientes de aproximación, más o menos 1/32 = 0,031 de σ², e IX mide 0,036. Desplace la misma señal 16 muestras y cada salto cae en medio de un bloque de 32. Ahora hay 16, contando el de la vuelta. Cada detalle de nivel 5 en un salto vale 16h/√32 = 2,83h para un salto de altura h, así que supera el umbral de 1,86, y pierde 1,86 por el camino. El error se multiplica por 5,4. Haar no es invariante por traslación: el mismo filtro lo hace mucho mejor con una señal cuyos saltos caen en su rejilla.

[`CONTRACTS.md` 14 y 33](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L14-L33) dicen que `wavelet::dwt_haar` «exige una longitud de entrada potencia de dos» y entra en pánico si no. El crate no tiene `dwt_haar`. Su `haar_dwt` llama a `haar_forward`, que toma len/2 pares y descarta en silencio una última muestra impar ([`wavelet.rs` 6-18](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs#L6-L18)). Doce muestras en tres niveles pasan por 12, 6, 3 y luego 1 par de 3, y vuelven como 8 muestras, sin pánico. La cabecera del módulo promete además una transformada de Daubechies-4 ([`wavelet.rs` 3](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs#L3)) que el archivo no contiene.

## 6. El filtro de Kalman, y por qué se convierte en una media móvil

El filtro de [Kalman (1960)](https://doi.org/10.1115/1.3662552) estima un estado oculto a partir de medidas ruidosas. El estado evoluciona según xₖ = F·xₖ₋₁ + wₖ, con un ruido de covarianza Q, y se mide como zₖ = H·xₖ + vₖ, con un ruido de covarianza R. Cada paso predice (x̂ ← F·x̂, P ← F·P·Fᵀ + Q) y luego corrige con la ganancia K = P·Hᵀ(H·P·Hᵀ + R)⁻¹: x̂ ← x̂ + K(z − H·x̂), P ← (I − K·H)·P. El `KalmanFilter` de IX hace exactamente esos pasos ([`kalman.rs` 49-85](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/kalman.rs#L49-L85)).

Tomemos el caso más sencillo: un paseo aleatorio (F = H = 1) con varianza de paso q = 0,01, medido con un ruido de varianza r = 1. La varianza converge al punto fijo de la ecuación de Riccati. La varianza de la predicción P⁻ cumple P⁻² − q·P⁻ − q·r = 0, así que P⁻ = (q + √(q² + 4qr))/2, la ganancia es K∞ = P⁻/(P⁻ + r) = 0,0951249, y la varianza tras una actualización es K∞·r. Una vez K es constante, la actualización x̂ₖ = x̂ₖ₋₁ + K(zₖ − x̂ₖ₋₁) = K·zₖ + (1 − K)·x̂ₖ₋₁ *es* una media móvil exponencial con α = K∞. IX tiene una, [`timeseries::ewma`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/timeseries.rs#L546-L558). P5:

```text
== Kalman filter of a random walk, q 0.01, r 1
  steady-state gain from the Riccati equation:   0.095124922
  IX's variance after 200 steps:                 0.095124922
  largest |state - ewma(K)|, steps 300 to 1000:  1e-13 to 1e-12
  mean squared error / (K r), 200 runs:          1.004
  KalmanFilter::new(2, 1) as built, 100 measurements of 5: largest |state| 0, first variance 2.000000
```

La varianza de IX alcanza el valor de Riccati, y [`solve_discrete_are`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.linalg.solve_discrete_are.html) de SciPy da el mismo 0,095124922 en el control cruzado. Desde el paso 300, el estado filtrado y la media móvil difieren en menos de 10⁻¹². El filtro también dice cuánto se equivoca: en 200 paseos aleatorios, su error cuadrático vale de media 1,004 veces la varianza que declara. Aquí el ruido no es gaussiano, ya que es una suma de 12 uniformes, y eso no importa: el filtro es el mejor estimador lineal para cualquier ruido con esas varianzas. La última línea es el control del que advierte [`CONTRACTS.md` 12](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L12): `KalmanFilter::new` deja H en 0, así que la ganancia es 0, el estado nunca se mueve y la varianza crece 0,01 por paso.

## 7. Casos límite frente al contrato

P9 reúne cuatro comprobaciones pequeñas:

```text
== Edge cases
  hanning        of length 1: NaN
  hamming        of length 1: NaN
  blackman       of length 1: NaN
  bartlett       of length 1: NaN
  gaussian(0.4)  of length 1: NaN
  kaiser(5)      of length 1: 0.0367
  fft(&[]): 1 value(s), [(0.0, 0.0)]
  normalized_cross_correlation([1.0, 2.0, 3.0, 4.0], [4.0, 3.0, 2.0, 1.0]): [0.0333, 0.1333, 0.3333, 0.6667, 0.8333, 0.8000, 0.5333]
  Pearson at lag 0: -1.0000
  autocorrelation([1.0, 2.0, 3.0, 4.0]): [0.1333, 0.3667, 0.6667, 1.0000, 0.6667, 0.3667, 0.1333]
```

- **Ventanas de longitud 1.** Cada ventana divide por n − 1 ([`window.rs` 11-64](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/window.rs#L11-L64)), así que con n = 1 calcula 0/0. `kaiser` pasa el NaN por [`f64::max`](https://doc.rust-lang.org/std/primitive.f64.html#method.max), que «devuelve el máximo de los dos números, ignorando NaN», y devuelve 1/I₀(5) = 0,0367. La [`hanning`](https://numpy.org/doc/stable/reference/generated/numpy.hanning.html) de numpy y sus hermanas devuelven 1 para una longitud de 1, como imprime el control cruzado.
- **Una FFT vacía.** [`CONTRACTS.md` 31](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L31) dice que una entrada vacía «entra en pánico dentro de `next_power_of_two()`», y luego describe por qué no lo hace. `0usize.next_power_of_two()` vale 1, y `fft(&[])` devuelve un cero.
- **Una correlación «de Pearson».** `normalized_cross_correlation` se documenta como «correlación de Pearson en cada desfase» ([`correlation.rs` 24-35](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/correlation.rs#L24-L35)). Divide la correlación bruta por el producto de las dos normas, sin quitar las medias. Una rampa ascendente frente a una descendente tiene Pearson −1 en el desfase 0; IX da 0,6667 ahí, y ningún desfase baja de 0.
- **`auto_correlation`.** [`CONTRACTS.md` 17](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L17) describe una `correlation::auto_correlation` que «devuelve una correlación no normalizada». El crate tiene `autocorrelation`, que divide por su valor en el desfase 0 ([`correlation.rs` 6-17](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/correlation.rs#L6-L17)), así que el centro vale exactamente 1.

## 8. Las predicciones, puntuadas

| | Predicción, escrita antes de la primera ejecución | Medido | Veredicto |
|---|---|---|---|
| P1 | La densidad de Welch de IX integra a 0,45–0,55 de la varianza; la de SciPy es el doble en las bandas 1–255, igual en 0 y 256 | 0,503; el doble a menos de 10⁻⁹, igual | Confirmada |
| P2 | Segmentos de 300: una senoide de 200 Hz tiene su pico en el índice 102, etiquetado 340 Hz; una de 400 Hz queda por debajo de 10⁻⁶ de ese pico; 256 acierta a menos de una banda | 102, 340,0 Hz; 10⁻¹¹ a 10⁻¹⁰; 199,2 y 398,4 Hz | Confirmada |
| P3 | El error de la FFT de IX con 2¹⁶ en [10⁻¹⁴, 10⁻¹¹] y al menos 16 veces su error con 2⁸; la referencia a menos de 10⁻¹⁴ de la DFT | 5,4 × 10⁻¹³ en Windows, 300 veces; 3,9 × 10⁻¹⁶ | Confirmada |
| P4 | Butterworth con fc = 0,1: ganancia 1 en continua, 1/√2 en fc, exactamente 0 en Nyquist; una senoide en fc sale a 1/√2 | Como se predijo; 0,7071 | Confirmada |
| P5 | Paseo aleatorio: varianza K∞·r = 0,0951249 tras 200 pasos; igual a la EWMA a menos de 10⁻⁹ desde el paso 300; error / varianza en [0,95, 1,05] | 0,095124922; por debajo de 10⁻¹²; 1,004 | Confirmada |
| P6 | Haar con 12 muestras, 3 niveles: 1 + [6, 3, 1], vuelven 8, sin pánico; 16 muestras vuelven | Como se predijo | Confirmada |
| P7 | Filtrado de Haar: error / σ² alineado en [0,02, 0,05]; desplazado 16, al menos 3 veces más | 0,0360; 5,4 veces | Confirmada |
| P8 | `highpass(0.25, 31)` deja pasar 0,12–0,2 en f = 0,05, `highpass(0.25, 32)` menos de 0,0032; el paso bajo de orden 64 mantiene sus bandas y retrasa 32 | 0,1569; 0,00046; como se predijo | Confirmada |
| P9 | Las ventanas de longitud 1 valen NaN, `kaiser(1, 5)` 0,0367; `fft(&[])` devuelve un cero; la correlación «de Pearson» da 0,667 donde Pearson vale −1; `autocorrelation` vale 1 en el desfase 0 | Como se predijo | Confirmada |

Las nueve se cumplieron en la primera ejecución, y ningún intervalo se cambió después. La primera compilación falló, por un préstamo en `direct_dft`, antes de que corriera ningún test. P1, P2, P6, P8 y P9 salieron de leer el código y los contratos de IX, para atrapar una diferencia entre lo que dicen y lo que hace el código, y cada una encontró una. P3 también, y además salió de un cálculo sobre los redondeos cerca de 1. P4, P5 y P7 salieron de la teoría, e IX la cumple. Los controles muestran que cada comprobación puede fallar. Duplicar las bandas interiores de IX sí devuelve la varianza. Los segmentos potencia de dos sí encuentran las frecuencias. La FFT de referencia sí coincide con la DFT. Una ida y vuelta de Haar con una potencia de dos sí vuelve. Un FIR de orden par sí mantiene sus bandas. Y el filtro de Kalman por defecto sí se queda en 0.

## Qué usar en nuestros repositorios

- **La `fft` de IX:** sirve para espectros y características. Su error relativo crece con N: 5 × 10⁻¹³ con 2¹⁶ en Windows. Para transformadas largas, o cuando importan las últimas cifras, compare con una FFT con tabla como [`rustfft`](https://docs.rs/rustfft) (no medida aquí).
- **La `welch_psd` de IX:** solo con segmentos potencia de dos. Duplique las bandas 1 a N/2 − 1 antes de comparar con SciPy o con una varianza.
- **El `FirFilter` de IX:** solo órdenes pares, y compruebe el orden usted mismo para `highpass`. Divida los coeficientes por su suma si la ganancia en continua debe valer exactamente 1.
- **`butterworth_lowpass_2nd` y `KalmanFilter` de IX:** coinciden con SciPy y con la teoría. Fije siempre la `observation` del filtro de Kalman. Para un paseo aleatorio, la ganancia estacionaria da directamente la `ewma` equivalente.
- **Las funciones de Haar de IX:** solo longitudes potencia de dos, comprobadas antes de llamar. No hay transformada de Daubechies, diga lo que diga la cabecera.
- **La `normalized_cross_correlation` de IX:** reste antes las medias. Aun así, cada desfase se divide por las normas completas, no por la parte que se solapa.

## Ejercicios

1. Demuestre que para una señal real |X_{N−k}| = |X_k|, y deduzca qué bandas debe duplicar una densidad unilateral para integrar a la varianza.
2. Con un orden impar M, el `highpass` de IX es δ[n − (M − 1)/2] − h[n], donde h está centrado en M/2. Demuestre que en la banda de paso de h, donde h ≈ δ[n − M/2], la ganancia es 2 sen(πf/2).
3. Deduzca la ganancia estacionaria del paseo aleatorio: escriba P⁺ en función de P⁻ = P⁺ + q, despeje P⁻ y calcule K∞ para q = 0,01 y r = 1.
4. Escalones de 64 muestras, Haar en 5 niveles. ¿Por qué cada coeficiente de detalle limpio es nulo cuando los saltos caen en múltiplos de 64? ¿Cuánto vale el detalle de nivel 5 de un salto de altura h en medio de un bloque de 32 muestras, y qué deja de él el umbral suave en t?

<details>
<summary>Soluciones</summary>

1. X_{N−k} = Σⱼ xⱼ e^(−2πij(N−k)/N) = Σⱼ xⱼ e^(2πijk/N), ya que e^(−2πij) = 1. Para xⱼ reales, es el conjugado de X_k, así que sus módulos son iguales. Parseval dice que Σⱼ xⱼ² = (1/N) Σₖ |X_k|². Las bandas 1 a N/2 − 1 tienen cada una una gemela entre N/2 + 1 y N − 1, y las bandas 0 y N/2 están solas. Conservar 0 a N/2 y duplicar 1 a N/2 − 1 mantiene por tanto toda la suma.
2. En la banda de paso, H_h(f) ≈ e^(−2πif·M/2), y el impulso aporta e^(−2πif(M−1)/2). El paso alto tiene H(f) = e^(−2πif(M−1)/2)·(1 − e^(−iπf)). Su módulo es |1 − e^(−iπf)| = √((1 − cos πf)² + sen² πf) = √(2 − 2cos πf) = 2 sen(πf/2). En f = 0,05 eso da 0,157, e IX mide 0,1569. Con un orden par, el impulso cae justo en el centro de h y ambos se anulan.
3. La actualización da P⁺ = P⁻·r/(P⁻ + r), y la predicción P⁻ = P⁺ + q. En el punto fijo, P⁻ − q = P⁻·r/(P⁻ + r), así que (P⁻ − q)(P⁻ + r) = P⁻·r, es decir, P⁻² − q·P⁻ − q·r = 0. La raíz positiva es P⁻ = (q + √(q² + 4qr))/2 = (0,01 + √0,0401)/2 = 0,1051249, y K∞ = P⁻/(P⁻ + r) = 0,0951249.
4. En el nivel ℓ, un detalle compara las dos mitades de un bloque de 2^ℓ muestras, de 2 a 32 aquí. Cuando cada salto cae en un múltiplo de 64, ningún bloque de 32 o menos cruza un salto: sus dos mitades son iguales y el detalle es nulo. Un salto de a a b = a + h en medio de un bloque de 32 muestras da (16a − 16b)/√32 = −16h/√32, de tamaño 2,83h. El umbral suave conserva su signo y le quita t = 1,86 a su tamaño: queda un error de 1,86 en ese coeficiente, sea cual sea h, mientras 2,83h > 1,86.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [`fft.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/fft.rs), [`spectral.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs), [`filter.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs), [`wavelet.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs), [`kalman.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/kalman.rs), [`window.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/window.rs), [`correlation.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/correlation.rs), [`timeseries.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/timeseries.rs) y [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md).
- J. W. Cooley y J. W. Tukey, [«An algorithm for the machine calculation of complex Fourier series»](https://doi.org/10.1090/S0025-5718-1965-0178586-1), Mathematics of Computation 19, 1965.
- J. C. Schatzman, [«Accuracy of the discrete Fourier transform and the fast Fourier transform»](https://doi.org/10.1137/S1064827593247023), SIAM Journal on Scientific Computing 17, 1996.
- P. D. Welch, [«The use of fast Fourier transform for the estimation of power spectra: a method based on time averaging over short, modified periodograms»](https://doi.org/10.1109/TAU.1967.1161901), IEEE Transactions on Audio and Electroacoustics 15, 1967.
- F. J. Harris, [«On the use of windows for harmonic analysis with the discrete Fourier transform»](https://doi.org/10.1109/PROC.1978.10837), Proceedings of the IEEE 66, 1978.
- R. E. Kalman, [«A new approach to linear filtering and prediction problems»](https://doi.org/10.1115/1.3662552), Journal of Basic Engineering 82, 1960.
- D. L. Donoho y I. M. Johnstone, [«Ideal spatial adaptation by wavelet shrinkage»](https://doi.org/10.1093/biomet/81.3.425), Biometrika 81, 1994.
- SciPy: [`signal.welch`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html), [`signal.butter`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.butter.html), [`signal.firwin`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.firwin.html), [`linalg.solve_discrete_are`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.linalg.solve_discrete_are.html). numpy: [`fft`](https://numpy.org/doc/stable/reference/routines.fft.html), [`hanning`](https://numpy.org/doc/stable/reference/generated/numpy.hanning.html). Rust: [`f64::max`](https://doc.rust-lang.org/std/primitive.f64.html#method.max).
