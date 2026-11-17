---
title: "15. Signaux : transformée de Fourier, ondelettes, filtres et Kalman"
description: "La FFT, la densité de Welch, les filtres FIR et IIR, les ondelettes de Haar et le filtre de Kalman face à la crate ix-signal d'IX, avec neuf prédictions écrites avant la première exécution, qui tiennent toutes. Les conceptions des manuels sortent exactes ; la densité de Welch d'IX ne couvre que la moitié de la variance et se trompe d'étiquette de fréquence quand un segment n'est pas une puissance de deux, l'erreur de sa FFT croît linéairement avec N, et sa transformée de Haar tronque là où son contrat promet une panique."
sidebar:
  order: 15
---

Un signal est une suite de nombres échantillonnés à intervalles réguliers : un son, un capteur, un cours de bourse, une métrique relevée chaque minute. La crate [`ix-signal`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal) d'IX, épinglée, en a les outils classiques : la transformée de Fourier rapide, les fonctions de fenêtrage, la densité spectrale de puissance de Welch, les filtres FIR et IIR, les ondelettes de Haar et le filtre de Kalman. La [leçon 12](../12-autodiff/) a déjà dérivé à travers sa FFT. Cette leçon mesure ce que renvoie chaque outil face à ce que dit la théorie, et vérifie ce que promet le [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md) d'IX.

Les neuf prédictions que teste cette leçon ont été [écrites dans le journal](../journal/#2026-09-30--leçon-15-prédite-avant-de-mesurer) et commitées avant que son code n'existe. [Les résultats](../journal/#2026-09-30--leçon-15-mesurée) les suivent. Les expériences sont dans [`signal.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/signal.rs), un test par prédiction. [`l15_signals.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l15_signals.rs) imprime ce qu'elles mesurent. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcule la densité de Welch, les coefficients du Butterworth, le gain de Kalman et les coefficients FIR avec [numpy](https://numpy.org/doc/stable/) et [SciPy](https://docs.scipy.org/doc/scipy/). Le bruit vient du `Rng` du cours, en sommes de douze uniformes moins six, comme dans la [leçon 14](../14-reinforcement-learning/) : les trois systèmes de la CI tirent donc les mêmes nombres.

## 1. La FFT et ses facteurs de rotation

La transformée de Fourier discrète de N échantillons est

X_k = Σⱼ xⱼ e^(−2πi·jk/N), k = 0, …, N − 1.

Calculée telle qu'écrite, elle coûte N² multiplications. L'algorithme en base 2 de [Cooley et Tukey](https://doi.org/10.1090/S0025-5718-1965-0178586-1) sépare la somme en échantillons pairs et impairs, deux fois plus courtes, et les recombine avec les *facteurs de rotation* (twiddle factors) w^k = e^(−2πik/L), en log₂ N étages de N/2 opérations chacun. La `fft` d'IX complète son entrée par des zéros jusqu'à la puissance de deux suivante ([`CONTRACTS.md` 8](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L8)), et `ifft` divise par N.

À chaque étage, IX calcule un cosinus et un sinus, puis obtient les autres facteurs en multipliant encore par celui-là ([`fft.rs` 169-178](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/fft.rs#L169-L178)). Le k-ième facteur porte k arrondis, et une partie de l'erreur est systématique. Pour un petit angle, cos θ est juste sous 1 et s'arrondit à un demi-ulp près, environ 5,5 × 10⁻¹⁷. Le module de w dérive alors d'environ k fois cela. `reference_fft` dans `signal.rs` est le même algorithme, avec chaque facteur calculé directement. `direct_dft` est la somme ci-dessus, avec des additions compensées. P3 les compare sur une entrée uniforme dans [−1, 1] :

```text
== IX's FFT against a reference whose twiddles are computed one by one
  N = 2^8   relative RMS error 1e-15 to 1e-14
  N = 2^12  relative RMS error 1e-14 to 1e-13
  N = 2^16  relative RMS error 1e-13 to 1e-12
  error at 2^16 / error at 2^8: at least 16: true
  N = 2^10, the reference against the DFT by its definition: 1e-16 to 1e-15
```

L'exemple imprime des décades, parce que le `cos` et le `sin` de chaque plateforme déplacent les derniers chiffres. Sous Windows, l'erreur vaut 1,8 × 10⁻¹⁵ à 2⁸, 2,9 × 10⁻¹⁴ à 2¹², 1,3 × 10⁻¹³ à 2¹⁴ et 5,4 × 10⁻¹³ à 2¹⁶. Elle est multipliée par environ quatre chaque fois que N l'est. Elle croît linéairement : 300 fois de 2⁸ à 2¹⁶, là où une croissance en log N donnerait 2. La référence reste à 3,9 × 10⁻¹⁶ de la TFD directe. Le contrôle croisé numpy refait la récurrence d'IX contre [`numpy.fft`](https://numpy.org/doc/stable/reference/routines.fft.html) et tombe dans les mêmes décades.

[`CONTRACTS.md` 39](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L39) dit que les facteurs sont « calculés par `f64::cos/sin` » et que les plateformes peuvent différer « à l'échelle de l'ULP ». À 2¹⁶, l'erreur vaut environ 2 400 ulps de 1. Il reste douze chiffres justes, largement assez pour un spectre. Mais elle continue de croître avec N, et ce n'est plus ce que décrit le contrat. Une table de facteurs calculés directement, comme dans la référence, ne coûte que N/2 valeurs. [Schatzman (1996)](https://doi.org/10.1137/S1064827593247023) le dit dans son résumé : « Popular recursions for fast computation of the sine/cosine table (or twiddle factors) are inaccurate due to inherent instability. »

## 2. La densité de Welch

Un spectre montre où se trouve la puissance d'un signal en fréquence. Le périodogramme |X_k|² du signal entier est bruité. [Welch (1967)](https://doi.org/10.1109/TAU.1967.1161901) découpe le signal en segments qui se chevauchent, multiplie chacun par une fenêtre et moyenne leurs périodogrammes. La fenêtre atténue les bords du segment, pour qu'une fréquence tombée entre deux raies fuie moins dans les autres. [Harris (1978)](https://doi.org/10.1109/PROC.1978.10837) compare les fenêtres classiques. La `welch_psd` d'IX utilise une fenêtre de Hann et divise chaque |X_k|² par Σw² et par la fréquence d'échantillonnage ([`spectral.rs` 79-92](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs#L79-L92)). Pour un bruit blanc de variance σ², chaque raie vaut alors σ²/fs en moyenne.

Le spectre d'un signal réel est symétrique : la raie N − k porte la même puissance que la raie k. Une densité *unilatérale* garde les raies 0 à N/2 et double les raies 1 à N/2 − 1, pour s'intégrer en la variance (Parseval). C'est la densité que renvoie par défaut [`scipy.signal.welch`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html). IX renvoie les mêmes raies sans les doubler (P1) :

```text
== Welch's density, 16,384 samples of unit-variance noise, fs 1000, segments 512
  integral / variance, as IX returns it:     0.503
  bins 1 to 255 doubled (one-sided):         1.002
```

La densité d'IX s'intègre en la moitié de la variance, 257/512 exactement en espérance. Dans le contrôle croisé, `scipy.signal.welch`, avec la même fenêtre de Hann symétrique et sans retrait de tendance, renvoie exactement le double de la convention d'IX sur les raies 1 à 255, à 10⁻⁹ près, et la même valeur sur les raies 0 et 256. Aucune des deux conventions n'est fausse. Une densité bilatérale est tout aussi légitime, mais elle couvrirait aussi les fréquences négatives, et le commentaire de documentation d'IX ne nomme ni l'une ni l'autre. Comparées à SciPy ou à une variance, les valeurs d'IX sortent deux fois trop petites.

Le second piège est dans l'axe des fréquences. `rfft` complète un segment jusqu'à la puissance de deux suivante. `welch_psd` garde window_size/2 + 1 raies de cette transformée plus longue, et étiquette la raie k par k·fs/window_size ([`spectral.rs` 94-96](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs#L94-L96)). Avec des segments de 300, la transformée a 512 raies, la raie k est à k·1000/512 Hz, et seules les raies 0 à 150 sont gardées, jusqu'à 293 Hz (P2) :

```text
== welch_psd on sines, fs 1000, 8,192 samples
  200 Hz, segments of 300: 151 bins, peak at index 102, labelled 340.0 Hz
  400 Hz, segments of 300: 151 bins, peak at index 149, labelled 496.7 Hz
  200 Hz, segments of 256: 129 bins, peak at index 51, labelled 199.2 Hz
  400 Hz, segments of 256: 129 bins, peak at index 102, labelled 398.4 Hz
  segments of 300: largest value of the 400 Hz sine / the 200 Hz peak: 1e-11 to 1e-10
```

Une sinusoïde à 200 Hz tombe dans la raie 102, à 199,2 Hz, et IX l'étiquette 340 Hz. Une sinusoïde à 400 Hz tombe dans la raie 204,8, au-delà de ce qui est renvoyé. Il ne reste que la queue de la fuite de la fenêtre, de 10⁻¹¹ à 10⁻¹⁰ d'un vrai pic, dont la plus grande valeur se trouve au bord supérieur, étiquetée 496,7 Hz. Avec des segments de 256, les deux sinusoïdes sont où elles doivent être, à une raie près. `spectrogram` garde les mêmes window_size/2 + 1 raies de la transformée complétée ([`spectral.rs` 33-54](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs#L33-L54)). Cela vient de la lecture du code ; cette leçon ne le mesure pas.

## 3. Les filtres FIR : le sinus cardinal fenêtré

Un filtre à réponse impulsionnelle finie (FIR) remplace chaque échantillon par une somme pondérée des M + 1 dernières entrées : y[n] = Σₘ h[m]·x[n − m]. Le passe-bas idéal de fréquence de coupure fc a pour réponse impulsionnelle 2fc·sinc(2fc·m), qui est infinie. `FirFilter::lowpass(cutoff, order)` la centre sur order/2, la tronque à order + 1 coefficients et la multiplie par une fenêtre de Hamming ([`filter.rs` 17-37](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs#L17-L37)). Les coefficients sont symétriques, donc le filtre retarde toutes les fréquences des mêmes order/2 échantillons. `highpass` soustrait le passe-bas d'une impulsion unité placée en order/2, et garde ainsi ce que le passe-bas retire ([`filter.rs` 40-50](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs#L40-L50)). P8 :

```text
== FIR filters
  highpass(0.25, 31) at f 0.05: gain 0.1569
  highpass(0.25, 32) at f 0.05: gain 0.00046
  lowpass(0.1, 64): gain on [0, 0.05] 0.9995 to 1.0003, largest on [0.15, 0.5] 0.00184
  lowpass(0.1, 64): centre tap 0.200000000, sum of the taps 1.000041082
  lowpass(0.1, 64) on a sine at 0.02: largest |y[n] - x[n - 32]| after 64 samples 0.0002
```

Les fréquences sont en cycles par échantillon, donc 0,5 est Nyquist. Avec un ordre pair, le sinus cardinal fenêtré fait ce que dit le manuel. `lowpass(0.1, 64)` reste à 5 × 10⁻⁴ de 1 dans sa bande passante et vaut au plus 0,00184 (−54,7 dB) à partir de 0,15, et une sinusoïde ressort avec 32 échantillons de retard. [`scipy.signal.firwin`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.firwin.html)`(65, 0.2, window="hamming", scale=False)` donne le même coefficient central et la même somme de coefficients. Cette somme, 1,000041, est le gain en continu. IX ne la normalise pas ; `firwin` le fait par défaut.

Le commentaire de `lowpass` dit que l'ordre « doit être pair ». Rien ne le vérifie, et `highpass` ne le répète pas. Avec l'ordre 31, il y a 32 coefficients, et le passe-bas est centré en 15,5, entre deux d'entre eux. L'impulsion va à l'indice 31/2 = 15, un demi-échantillon trop tôt, et la soustraction n'annule plus la bande basse : le gain y vaut |1 − e^(−iπf)| = 2 sin(πf/2), soit 0,157 à f = 0,05. IX mesure 0,1569, là où l'ordre pair laisse passer 0,00046. La raison profonde est qu'un filtre symétrique à nombre pair de coefficients a toujours un zéro à Nyquist : il ne peut pas être un passe-haut du tout. `firwin` refuse d'en concevoir un : le contrôle croisé imprime sa `ValueError`.

## 4. Les filtres IIR : le Butterworth

Un filtre à réponse impulsionnelle infinie (IIR) réinjecte aussi ses sorties passées : y[n] = Σ b_k·x[n − k] − Σ a_k·y[n − k]. `butterworth_lowpass_2nd` conçoit un Butterworth d'ordre 2, dont le gain est aussi plat que possible dans la bande passante, par la transformation bilinéaire. La coupure analogique est prédistordue par tan(π·fc), pour que le point à −3 dB du filtre numérique tombe exactement sur fc ([`filter.rs` 145-158](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs#L145-L158)). P4 :

```text
== Second-order Butterworth, fc 0.1
  b [0.067455274, 0.134910548, 0.067455274]
  a [1.000000000, -1.142980503, 0.412801598]
  gain at DC 1.000000000000, at fc 0.707106781187, at Nyquist 0
  a sine at fc through IirFilter::apply: amplitude 0.7071
```

[`scipy.signal.butter`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.butter.html)`(2, 0.2)` renvoie les mêmes coefficients aux neuf décimales qu'affiche le contrôle croisé, et à 1,7 × 10⁻¹⁶ près dans une comparaison ponctuelle en pleine précision sous Windows (SciPy mesure la coupure par rapport à Nyquist, d'où 0,2). Le gain vaut 1 en continu et 1/√2 à fc, à douze décimales. À Nyquist, z = −1 et le gain vaut b₀ − b₁ + b₂, exactement 0 : IX calcule b₁ comme 2·wc²/k et b₀ comme wc²/k, et multiplier par 2 n'arrondit pas. Le `first_order_lowpass` du même fichier est la moyenne mobile exponentielle y[n] = α·x[n] + (1 − α)·y[n − 1]. La section 6 la retrouve.

## 5. Les ondelettes de Haar

La transformée de Fourier dit quelles fréquences contient un signal, pas quand. Une transformée en ondelettes répond aux deux, à plusieurs échelles. Celle de Haar est la plus simple. Chaque paire (a, b) devient une moyenne (a + b)/√2 et un détail (a − b)/√2, et les moyennes sont de nouveau découpées, niveau après niveau. La transformée est orthonormée : un bruit blanc de variance σ² reste blanc, de variance σ² dans chaque coefficient. Un signal propre fait de paliers a des détails nuls partout où une paire n'enjambe pas un saut. [Donoho et Johnstone (1994)](https://doi.org/10.1093/biomet/81.3.425) débruitent en rapprochant chaque détail de 0 d'un seuil t (seuillage doux), avec le seuil universel t = σ√(2 ln N). `wavelet_denoise` fait exactement cela ([`wavelet.rs` 62-82](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs#L62-L82)). P6 et P7 :

```text
== Haar wavelets
  12 samples, 3 levels: approximation 1, details [6, 3, 1], haar_idwt returns 8, wavelet_denoise returns 8
  16 samples, 4 levels: round trip within 1e-12: true
  blocks of 64, sigma 0.5, 5 levels, universal threshold, 20 draws (15 jumps)
    jumps on multiples of 64: MSE / sigma^2 0.0360
    shifted by 16:            MSE / sigma^2 0.1953 (5.4 times)
```

Avec les sauts sur des multiples de 64, les cinq niveaux voient des blocs de 2 à 32 échantillons qui n'enjambent jamais un saut. Chaque détail propre est nul, et le seuillage retire presque tout le bruit qu'ils portent. Il reste le bruit des 32 coefficients d'approximation, environ 1/32 = 0,031 de σ², et IX mesure 0,036. Décalez le même signal de 16 échantillons, et chaque saut tombe au milieu d'un bloc de 32. Il y en a maintenant 16, en comptant celui du bouclage. Chaque détail de niveau 5 sur un saut vaut 16h/√32 = 2,83h pour un saut de hauteur h : il passe donc le seuil de 1,86, et y perd 1,86. L'erreur est multipliée par 5,4. Haar n'est pas invariant par translation : le même débruiteur fait bien mieux sur un signal dont les sauts tombent sur sa grille.

[`CONTRACTS.md` 14 et 33](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L14-L33) disent que `wavelet::dwt_haar` « exige une longueur d'entrée puissance de deux » et panique sinon. La crate n'a pas de `dwt_haar`. Son `haar_dwt` appelle `haar_forward`, qui prend len/2 paires et laisse tomber en silence un dernier échantillon impair ([`wavelet.rs` 6-18](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs#L6-L18)). Douze échantillons sur trois niveaux passent par 12, 6, 3, puis 1 paire sur 3, et reviennent en 8 échantillons, sans panique. L'en-tête du module promet aussi une transformée de Daubechies-4 ([`wavelet.rs` 3](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs#L3)) que le fichier ne contient pas.

## 6. Le filtre de Kalman, et pourquoi il devient une moyenne mobile

Le filtre de [Kalman (1960)](https://doi.org/10.1115/1.3662552) estime un état caché à partir de mesures bruitées. L'état évolue selon xₖ = F·xₖ₋₁ + wₖ, avec un bruit de covariance Q, et se mesure par zₖ = H·xₖ + vₖ, avec un bruit de covariance R. Chaque pas prédit (x̂ ← F·x̂, P ← F·P·Fᵀ + Q), puis corrige avec le gain K = P·Hᵀ(H·P·Hᵀ + R)⁻¹ : x̂ ← x̂ + K(z − H·x̂), P ← (I − K·H)·P. Le `KalmanFilter` d'IX fait exactement ces pas ([`kalman.rs` 49-85](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/kalman.rs#L49-L85)).

Prenons le cas le plus simple : une marche aléatoire (F = H = 1) de variance de pas q = 0,01, mesurée avec un bruit de variance r = 1. La variance converge vers le point fixe de l'équation de Riccati. La variance de la prédiction P⁻ vérifie P⁻² − q·P⁻ − q·r = 0, donc P⁻ = (q + √(q² + 4qr))/2, le gain vaut K∞ = P⁻/(P⁻ + r) = 0,0951249, et la variance après une mise à jour vaut K∞·r. Une fois K constant, la mise à jour x̂ₖ = x̂ₖ₋₁ + K(zₖ − x̂ₖ₋₁) = K·zₖ + (1 − K)·x̂ₖ₋₁ *est* une moyenne mobile exponentielle, de coefficient α = K∞. IX en a une, [`timeseries::ewma`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/timeseries.rs#L546-L558). P5 :

```text
== Kalman filter of a random walk, q 0.01, r 1
  steady-state gain from the Riccati equation:   0.095124922
  IX's variance after 200 steps:                 0.095124922
  largest |state - ewma(K)|, steps 300 to 1000:  1e-13 to 1e-12
  mean squared error / (K r), 200 runs:          1.004
  KalmanFilter::new(2, 1) as built, 100 measurements of 5: largest |state| 0, first variance 2.000000
```

La variance d'IX atteint la valeur de Riccati, et [`solve_discrete_are`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.linalg.solve_discrete_are.html) de SciPy donne le même 0,095124922 dans le contrôle croisé. À partir du pas 300, l'état filtré et la moyenne mobile diffèrent de moins de 10⁻¹². Le filtre dit aussi à quel point il se trompe : sur 200 marches aléatoires, son erreur quadratique vaut en moyenne 1,004 fois la variance qu'il annonce. Le bruit n'est pas gaussien ici, puisque c'est une somme de 12 uniformes, et cela ne change rien : le filtre est le meilleur estimateur linéaire pour tout bruit de ces variances. La dernière ligne est le contrôle contre lequel met en garde [`CONTRACTS.md` 12](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L12) : `KalmanFilter::new` laisse H à 0, donc le gain est nul, l'état ne bouge jamais, et la variance croît de 0,01 par pas.

## 7. Des cas limites face au contrat

P9 rassemble quatre petites vérifications :

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

- **Des fenêtres de longueur 1.** Chaque fenêtre divise par n − 1 ([`window.rs` 11-64](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/window.rs#L11-L64)), donc à n = 1 elle calcule 0/0. `kaiser` fait passer le NaN par [`f64::max`](https://doc.rust-lang.org/std/primitive.f64.html#method.max), qui « renvoie le maximum des deux nombres, en ignorant NaN », et renvoie 1/I₀(5) = 0,0367. La [`hanning`](https://numpy.org/doc/stable/reference/generated/numpy.hanning.html) de numpy et ses sœurs renvoient 1 pour une longueur de 1, comme l'imprime le contrôle croisé.
- **Une FFT vide.** [`CONTRACTS.md` 31](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L31) dit qu'une entrée vide « panique dans `next_power_of_two()` », puis décrit pourquoi elle ne panique pas. `0usize.next_power_of_two()` vaut 1, et `fft(&[])` renvoie un zéro.
- **Une corrélation « de Pearson ».** `normalized_cross_correlation` est documentée comme « corrélation de Pearson à chaque décalage » ([`correlation.rs` 24-35](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/correlation.rs#L24-L35)). Elle divise la corrélation brute par le produit des deux normes, sans retirer les moyennes. Une rampe montante contre une rampe descendante a un Pearson de −1 au décalage 0 ; IX y donne 0,6667, et aucun décalage ne descend sous 0.
- **`auto_correlation`.** [`CONTRACTS.md` 17](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md#L17) décrit une `correlation::auto_correlation` qui « renvoie une corrélation non normalisée ». La crate a `autocorrelation`, qui divise par sa valeur au décalage 0 ([`correlation.rs` 6-17](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/correlation.rs#L6-L17)) : le centre vaut exactement 1.

## 8. Les prédictions, notées

| | Prédiction, écrite avant la première exécution | Mesuré | Verdict |
|---|---|---|---|
| P1 | La densité de Welch d'IX s'intègre en 0,45 à 0,55 de la variance ; celle de SciPy en vaut le double sur les raies 1 à 255, la même sur 0 et 256 | 0,503 ; double à 10⁻⁹ près, égale | Confirmée |
| P2 | Segments de 300 : une sinusoïde à 200 Hz culmine à l'indice 102, étiquetée 340 Hz ; une à 400 Hz reste sous 10⁻⁶ de ce pic ; 256 est juste à une raie près | 102, 340,0 Hz ; 10⁻¹¹ à 10⁻¹⁰ ; 199,2 et 398,4 Hz | Confirmée |
| P3 | L'erreur de la FFT d'IX à 2¹⁶ dans [10⁻¹⁴, 10⁻¹¹] et au moins 16 fois son erreur à 2⁸ ; la référence à 10⁻¹⁴ près de la TFD | 5,4 × 10⁻¹³ sous Windows, 300 fois ; 3,9 × 10⁻¹⁶ | Confirmée |
| P4 | Butterworth à fc = 0,1 : gain 1 en continu, 1/√2 à fc, exactement 0 à Nyquist ; une sinusoïde à fc ressort à 1/√2 | Comme prédit ; 0,7071 | Confirmée |
| P5 | Marche aléatoire : variance K∞·r = 0,0951249 après 200 pas ; égale à l'EWMA à 10⁻⁹ près dès le pas 300 ; erreur / variance dans [0,95, 1,05] | 0,095124922 ; sous 10⁻¹² ; 1,004 | Confirmée |
| P6 | Haar sur 12 échantillons, 3 niveaux : 1 + [6, 3, 1], retour en 8, sans panique ; 16 échantillons reviennent | Comme prédit | Confirmée |
| P7 | Débruitage de Haar : erreur / σ² alignée dans [0,02, 0,05] ; décalé de 16, au moins 3 fois plus | 0,0360 ; 5,4 fois | Confirmée |
| P8 | `highpass(0.25, 31)` laisse passer 0,12 à 0,2 à f = 0,05, `highpass(0.25, 32)` moins de 0,0032 ; le passe-bas d'ordre 64 garde ses bandes et retarde de 32 | 0,1569 ; 0,00046 ; comme prédit | Confirmée |
| P9 | Les fenêtres de longueur 1 valent NaN, `kaiser(1, 5)` 0,0367 ; `fft(&[])` renvoie un zéro ; la corrélation « de Pearson » donne 0,667 là où Pearson vaut −1 ; `autocorrelation` vaut 1 au décalage 0 | Comme prédit | Confirmée |

Les neuf ont tenu au premier passage, et aucun intervalle n'a été retouché ensuite. La première compilation a échoué, sur un emprunt dans `direct_dft`, avant qu'aucun test ne tourne. P1, P2, P6, P8 et P9 viennent de la lecture du code et des contrats d'IX, pour attraper un écart entre ce qu'ils disent et ce que fait le code, et chacune en a trouvé un. P3 aussi, et elle vient en plus d'un calcul sur les arrondis près de 1. P4, P5 et P7 viennent de la théorie, et IX s'y conforme. Des contrôles montrent que chaque vérification peut échouer. Doubler les raies intérieures d'IX redonne bien la variance. Des segments puissance de deux trouvent bien les fréquences. La FFT de référence s'accorde bien avec la TFD. Un aller-retour de Haar sur une puissance de deux revient bien. Un FIR d'ordre pair garde bien ses bandes. Et le filtre de Kalman par défaut reste bien à 0.

## Quoi utiliser pour nos dépôts

- **La `fft` d'IX :** convient pour des spectres et des caractéristiques. Son erreur relative croît avec N : 5 × 10⁻¹³ à 2¹⁶ sous Windows. Pour de longues transformées, ou quand les derniers chiffres comptent, comparez avec une FFT à table comme [`rustfft`](https://docs.rs/rustfft) (non mesurée ici).
- **La `welch_psd` d'IX :** uniquement avec des segments puissance de deux. Doublez les raies 1 à N/2 − 1 avant de comparer avec SciPy ou avec une variance.
- **Le `FirFilter` d'IX :** ordres pairs uniquement, et vérifiez l'ordre vous-même pour `highpass`. Divisez les coefficients par leur somme si le gain en continu doit valoir exactement 1.
- **`butterworth_lowpass_2nd` et `KalmanFilter` d'IX :** ils concordent avec SciPy et la théorie. Réglez toujours l'`observation` du filtre de Kalman. Pour une marche aléatoire, le gain stationnaire donne directement l'`ewma` équivalente.
- **Les fonctions de Haar d'IX :** longueurs puissance de deux uniquement, vérifiées avant l'appel. Il n'y a pas de transformée de Daubechies, quoi qu'en dise l'en-tête.
- **La `normalized_cross_correlation` d'IX :** retirez d'abord les moyennes. Même alors, chaque décalage est divisé par les normes entières, pas par la partie qui se chevauche.

## Exercices

1. Montrez que pour un signal réel |X_{N−k}| = |X_k|, et déduisez-en quelles raies une densité unilatérale doit doubler pour s'intégrer en la variance.
2. Avec un ordre impair M, le `highpass` d'IX vaut δ[n − (M − 1)/2] − h[n], où h est centré en M/2. Montrez que dans la bande passante de h, où h ≈ δ[n − M/2], le gain vaut 2 sin(πf/2).
3. Dérivez le gain stationnaire de la marche aléatoire : écrivez P⁺ en fonction de P⁻ = P⁺ + q, résolvez en P⁻, et calculez K∞ pour q = 0,01 et r = 1.
4. Des paliers de 64 échantillons, Haar sur 5 niveaux. Pourquoi chaque coefficient de détail propre est-il nul quand les sauts tombent sur des multiples de 64 ? Que vaut le détail de niveau 5 d'un saut de hauteur h au milieu d'un bloc de 32 échantillons, et que lui laisse le seuillage doux à t ?

<details>
<summary>Solutions</summary>

1. X_{N−k} = Σⱼ xⱼ e^(−2πij(N−k)/N) = Σⱼ xⱼ e^(2πijk/N), puisque e^(−2πij) = 1. Pour des xⱼ réels, c'est le conjugué de X_k, donc leurs modules sont égaux. Parseval dit que Σⱼ xⱼ² = (1/N) Σₖ |X_k|². Les raies 1 à N/2 − 1 ont chacune une jumelle parmi N/2 + 1 à N − 1, et les raies 0 et N/2 sont seules. Garder 0 à N/2 et doubler 1 à N/2 − 1 conserve donc toute la somme.
2. Dans la bande passante, H_h(f) ≈ e^(−2πif·M/2), et l'impulsion apporte e^(−2πif(M−1)/2). Le passe-haut a H(f) = e^(−2πif(M−1)/2)·(1 − e^(−iπf)). Son module est |1 − e^(−iπf)| = √((1 − cos πf)² + sin² πf) = √(2 − 2cos πf) = 2 sin(πf/2). À f = 0,05, cela fait 0,157, et IX mesure 0,1569. Avec un ordre pair, l'impulsion tombe exactement sur le centre de h et les deux s'annulent.
3. La mise à jour donne P⁺ = P⁻·r/(P⁻ + r), et la prédiction P⁻ = P⁺ + q. Au point fixe, P⁻ − q = P⁻·r/(P⁻ + r), donc (P⁻ − q)(P⁻ + r) = P⁻·r, soit P⁻² − q·P⁻ − q·r = 0. La racine positive est P⁻ = (q + √(q² + 4qr))/2 = (0,01 + √0,0401)/2 = 0,1051249, et K∞ = P⁻/(P⁻ + r) = 0,0951249.
4. Au niveau ℓ, un détail compare les deux moitiés d'un bloc de 2^ℓ échantillons, de 2 à 32 ici. Quand chaque saut tombe sur un multiple de 64, aucun bloc de 32 ou moins n'enjambe un saut : ses deux moitiés sont égales et le détail est nul. Un saut de a à b = a + h au milieu d'un bloc de 32 échantillons donne (16a − 16b)/√32 = −16h/√32, de taille 2,83h. Le seuillage doux garde son signe et retire t = 1,86 à sa taille : il reste une erreur de 1,86 sur ce coefficient, quel que soit h, tant que 2,83h > 1,86.

</details>

## Sources

- IX au commit épinglé `490c395` : [`fft.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/fft.rs), [`spectral.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/spectral.rs), [`filter.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/filter.rs), [`wavelet.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/wavelet.rs), [`kalman.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/kalman.rs), [`window.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/window.rs), [`correlation.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/correlation.rs), [`timeseries.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/src/timeseries.rs) et [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-signal/CONTRACTS.md).
- J. W. Cooley et J. W. Tukey, [« An algorithm for the machine calculation of complex Fourier series »](https://doi.org/10.1090/S0025-5718-1965-0178586-1), Mathematics of Computation 19, 1965.
- J. C. Schatzman, [« Accuracy of the discrete Fourier transform and the fast Fourier transform »](https://doi.org/10.1137/S1064827593247023), SIAM Journal on Scientific Computing 17, 1996.
- P. D. Welch, [« The use of fast Fourier transform for the estimation of power spectra: a method based on time averaging over short, modified periodograms »](https://doi.org/10.1109/TAU.1967.1161901), IEEE Transactions on Audio and Electroacoustics 15, 1967.
- F. J. Harris, [« On the use of windows for harmonic analysis with the discrete Fourier transform »](https://doi.org/10.1109/PROC.1978.10837), Proceedings of the IEEE 66, 1978.
- R. E. Kalman, [« A new approach to linear filtering and prediction problems »](https://doi.org/10.1115/1.3662552), Journal of Basic Engineering 82, 1960.
- D. L. Donoho et I. M. Johnstone, [« Ideal spatial adaptation by wavelet shrinkage »](https://doi.org/10.1093/biomet/81.3.425), Biometrika 81, 1994.
- SciPy : [`signal.welch`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html), [`signal.butter`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.butter.html), [`signal.firwin`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.firwin.html), [`linalg.solve_discrete_are`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.linalg.solve_discrete_are.html). numpy : [`fft`](https://numpy.org/doc/stable/reference/routines.fft.html), [`hanning`](https://numpy.org/doc/stable/reference/generated/numpy.hanning.html). Rust : [`f64::max`](https://doc.rust-lang.org/std/primitive.f64.html#method.max).
