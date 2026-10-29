---
module_id: aud-006-calibrate-spectral-amplitudes
department: audio-engineering
course: "Étalonner une amplitude spectrale avant de comparer des rendus"
level: intermediate
prerequisites: ["aud-003-transient-preservation-gate", "aud-005-pcm-guards-and-format-boundaries"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Étalonner une amplitude spectrale avant de comparer des rendus

> **Portée du brouillon.** Nouvelle analyse numérique de fichiers WAV de guitare conservés et de signaux d'étalonnage construits. La revue technique humaine, la révision par des personnes maîtrisant la langue, les essais des apprenants et la vérification du HTML public du cours restent à effectuer. L'analyse n'a exécuté aucun binaire IX et n'a produit aucun nouveau rendu audio de guitare.

## La question du projet

Un analyste audio de GA double une fenêtre d'analyse et observe un pic spectral plus fort. Le volume de la guitare a-t-il augmenté, ou la mesure a-t-elle changé ? Avant d'intégrer une valeur spectrale à une boucle d'amélioration, donnez-lui une référence et testez-la sur un signal d'amplitude connue. Cette leçon construit cet étalonnage ; [AUD-003](aud-003-transient-preservation-gate.md) traite du placement des transitoires et du débruitage.

L'[implémentation du spectrogramme IX à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L32-L54) prend les modules des transformées après fenêtrage. Avec son option logarithmique, elle applique `20*log10(max(magnitude,1e-10))`. L'[implémentation de la fenêtre](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/window.rs#L10-L15) utilise une fenêtre de Hann symétrique. Aucune de ces étapes ne divise par la somme de la fenêtre. L'inspection du code source établit cette formule ; elle n'établit aucun résultat provenant d'un service IX en cours d'exécution.

Lisez les [mesures d'étalonnage](../../../../code/streeling/evidence/spectral-views-2026-10-22/calibration.json) et le [compte rendu d'analyse](../../../../code/streeling/evidence/spectral-views-2026-10-22/execution.json). L'analyse temporaire utilisait la [FFT de NumPy pour les entrées réelles](https://numpy.org/doc/stable/reference/generated/numpy.fft.rfft.html), avec une transformée directe sans facteur d'échelle, et sa [fenêtre de Hann symétrique](https://numpy.org/doc/stable/reference/generated/numpy.hanning.html). Les versions des paquets installés figurent dans le compte rendu ; la documentation actuelle peut décrire une version plus récente.

## 1. Garder l'entrée physique fixe en changeant l'analyse

Le cosinus construit a une amplitude crête de 0.25 et une fréquence de 689.0625 Hz, à une fréquence d'échantillonnage de 44100 Hz. Il se situe à l'indice fréquentiel 32 pour une fenêtre de longueur 2048 et à l'indice 64 pour une longueur de 4096. Les deux cas analysent donc un nombre entier de cycles. La fenêtre de Hann symétrique est `w[n] = 0.5 - 0.5*cos(2*pi*n/(N-1))` ; sa somme vaut environ 1023.5 et 2047.5 dans ces cas.

| Longueur de fenêtre | Indice du son pur | Module brut | Estimation de l'amplitude crête |
|---|---|---|---|
| 2048 | 32 | 127.9375151793639 | 0.25000002966167834 |
| 4096 | 64 | 255.93750379229243 | 0.25000000370431497 |

La différence entre les modules bruts exprimés en dB est d'environ 6.02272037 dB. Elle découle du changement de gain de l'analyse. Elle ne prouve aucun changement de gain de l'entrée construite. La petite erreur résiduelle après normalisation provient de ce calcul avec une fenêtre symétrique finie ; ne l'arrondissez pas pour prétendre à une égalité exacte.

### Exercice 1 : diagnostiquer l'amélioration apparente

Un agent présente la deuxième ligne comme une guitare environ 6 dB plus forte. Qu'est-ce qui est resté fixe, qu'est-ce qui a changé et quel résultat remet cette interprétation en cause ?

> **Réponse:** L'amplitude crête de 0.25, la fréquence de 689.0625 Hz et la fréquence d'échantillonnage de 44100 Hz sont restées fixes. La longueur de la fenêtre est passée de 2048 à 4096, ce qui a changé le gain lié à la somme de ses coefficients. Les estimations normalisées retrouvent toutes deux environ 0.25, tandis que les modules bruts doublent presque. La différence d'environ 6 dB décrit ce changement de mesure, pas un nouveau rendu de guitare ni une entrée plus forte.

## 2. Préciser quelle amplitude la formule estime

Pour un cosinus réel isolé dont la fréquence coïncide avec un indice intérieur de la transformée, utilisez `A[k] = 2*abs(X[k])/sum(w)`. Le cosinus réel possède des contributions aux fréquences positives et négatives ; conserver un seul côté exige le facteur 2 pour cette estimation d'amplitude. Les tests retrouvent l'amplitude crête déclarée avec une tolérance absolue de `1e-6`. Certaines valeurs complexes de la transformée ont aussi été vérifiées par sommation directe avec une tolérance absolue de `1e-10`, au lieu de vérifier seulement une étiquette de graphique arrondie.

Pour une amplitude de référence de 1, l'estimation logarithmique est `20*log10(A/1)`. Une amplitude crête de 0.25 vaut environ -12.0412 dB par rapport à cette référence crête unitaire. Cette formule décrit l'amplitude crête selon un estimateur de transformée et de fenêtre déclaré. Elle n'estime ni la valeur efficace, ni la sonie, ni la puissance large bande intégrée, ni la densité spectrale de puissance. Des partiels de guitare rapprochés et des composantes entre les indices fréquentiels exigent une analyse supplémentaire avant qu'une valeur à un seul indice puisse représenter l'amplitude d'un partiel individuel.

### Exercice 2 : retrouver l'amplitude

À partir de la première ligne, calculez `2*127.9375151793639/1023.5`. Quelle valeur et quelle référence logarithmique doivent accompagner la réponse ? Peut-on la qualifier de densité spectrale de puissance ?

> **Réponse:** L'estimation est d'environ 0.25000003, à moins de `1e-6` de l'amplitude crête construite de 0.25. Par rapport à l'amplitude crête unitaire, sa valeur est d'environ -12.0412 dB. L'estimateur d'amplitude déclaré pour les indices intérieurs ne fournit aucune normalisation de puissance par hertz ; l'étiquette de densité spectrale de puissance serait donc injustifiée.

## 3. Ne pas doubler les extrémités

Pour une longueur de transformée paire, la composante continue et la fréquence de Nyquist ne sont pas appariées à des indices distincts de fréquences négatives conservées. Utilisez `A[k] = abs(X[k])/sum(w)` à ces extrémités. Les témoins distincts utilisent une constante de 0.25 et la suite alternée `0.25*(-1)^n`. Tous deux retrouvent 0.25 sans doublement. Appliquer la règle des indices intérieurs à l'une ou l'autre extrémité donnerait environ 0.5, résultat délibérément rejeté.

### Exercice 3 : repérer l'erreur aux extrémités

À la longueur 2048, le témoin continu a un module brut de 255.875 et une somme de fenêtre de 1023.5. Calculez l'amplitude correcte et l'amplitude doublée à tort. La même règle d'extrémité s'appliquerait-elle à Nyquist ?

> **Réponse:** `255.875/1023.5 = 0.25` ; un doublement incorrect donne 0.5. Nyquist utilise aussi la règle d'extrémité sans doublement pour cette transformée réelle de longueur paire. Un facteur 2 systématique ferait échouer les deux témoins d'étalonnage.

## 4. Consigner le décodeur autant que la transformée

Le [WAV de référence](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/baseline.wav) et le [WAV candidat](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/candidate.wav) conservés sont en PCM16 mono, avec 176400 échantillons à 44100 Hz. La nouvelle analyse décode chaque entier signé en le divisant par 32768. L'exportateur précédent utilisait un multiplicateur de 32767 pour créer ces WAV. Ce sont des étapes différentes, avec des conventions déclarées séparément ; cette analyse ne retrouve pas les buffers natifs en virgule flottante d'avant la quantification.

Les empreintes des WAV, la convention de décodage, certaines cellules des matrices et les coordonnées des trames complètes figurent dans le [relevé des coordonnées](../../../../code/streeling/evidence/spectral-views-2026-10-22/coordinates.json). Gardez ces entrées fixes pour comparer une référence à un candidat. Un changement de décodeur ou de normalisation dans une seule branche fausserait la comparaison.

### Exercice 4 : distinguer les grandeurs

Un analyste divise les échantillons PCM16 par 32768, puis décrit le tableau comme « les échantillons flottants natifs originaux exacts puisque l'exportateur utilisait 32767 ». Que doit plutôt indiquer le relevé ?

> **Réponse:** Il contient des échantillons PCM16 quantifiés et décodés avec le dénominateur déclaré de 32768. Le multiplicateur d'export de 32767 décrit une étape de quantification antérieure ; il n'annule pas la perte d'information et ne permet pas d'identifier les flottants originaux. Conservez l'empreinte du WAV et les deux conventions ; ne prétendez pas à une égalité avec le buffer natif à partir de ce tableau décodé.

## 5. Utiliser l'étalonnage pour protéger la décision

L'[expérience de décroissance](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/results.json) précédente a amélioré son erreur déclarée d'environ 0.11416615 dB, alors que l'amélioration requise était de 1 dB. Elle a échoué à ce critère. Un graphique étalonné ne remplace pas la mesure déclarée et ne fournit aucune préférence d'auditeur. [DV-009](../../data-visualization/en/dv-009-compare-spectrogram-color-scales.md) utilise les mêmes échantillons conservés pour montrer comment un affichage peut masquer une véritable différence de gain construite.

### Exercice 5 : décider ce que les preuves permettent d'accepter

Un agent dit que le candidat semble meilleur après un changement de normalisation de la fenêtre, et que son critère de décroissance échoué peut donc être marqué comme réussi. Que doit conserver, rejeter et tester ensuite la boucle d'amélioration ?

> **Réponse:** Conservez l'analyse étalonnée avec ses empreintes de WAV, son décodeur, sa fenêtre et sa référence. Refusez de modifier le verdict enregistré : environ 0.11416615 dB reste inférieur au seuil requis de 1 dB. Si une autre propriété musicale compte, déclarez une mesure et une règle d'acceptation distinctes avant une nouvelle comparaison, puis testez-les. Ni cet étalonnage ni une image ne constituent une approbation humaine à l'écoute.

## Limites des preuves

Le [protocole](../../../../code/streeling/evidence/spectral-views-2026-10-22/experiment-plan.md) consigne les prédictions et les conditions de réfutation ; la [vérification des sources](../../../../code/streeling/evidence/spectral-views-2026-10-22/primary-readback.json) distingue les vérifications d'octets réussies d'une requête directe à la documentation qui a échoué. Il s'agit de calculs numériques et d'observations du code source. Aucun nouveau résultat d'exécution IX, aucune exécution audio dans un navigateur, aucun adaptateur ComfyUI, aucun résultat de participant ni aucune mise en production ne sont revendiqués.
