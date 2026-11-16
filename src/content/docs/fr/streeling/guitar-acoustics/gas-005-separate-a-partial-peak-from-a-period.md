---
title: Distinguer le pic d’un partiel d’une période
description: Distinguer le pic d’un partiel d’une période — Acoustique de la guitare et synthèse sonore
sidebar:
  label: GAS-005 · Distinguer le pic d’un partiel d’une période
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-005-separate-a-partial-peak-from-a-period.fr.md
---

:::note[Streeling University]
**GAS-005** · Distinguer le pic d’un partiel d’une période · intermédiaire · 40 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-005-separate-a-partial-peak-from-a-period.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-001](../../guitar-acoustics/gas-001-open-string-audio-evidence/), [AUD-006](../../audio-engineering/aud-006-calibrate-spectral-amplitudes/)
:::

> **Portée du brouillon.** Nouvelle analyse numérique de signaux construits et d’un tampon natif de guitare conservé, accompagnée d’une inspection du code du moteur à une révision précise. Les revues humaines technique, musicale ou perceptive et linguistique, les essais apprenants et la vérification du HTML déployé restent à faire. Aucune nouvelle exécution du moteur, de WASM, du navigateur, du détecteur IX ou de la lecture audio n’a eu lieu.

## La question du projet

Un agent audio repère le plus grand pic spectral et l’appelle « la note de guitare ». Ce raccourci confond la fréquence d’une composante, une estimation de répétition et un jugement perceptif. Avant d’utiliser une valeur de hauteur pour orienter le travail sur la guitare WASM, précisez la grandeur réellement fournie par la méthode.

Le [moteur GA à la révision retenue](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L281-L326) stocke une fréquence demandée puis bornée et construit les états de retard entier et fractionnaire. Les filtres, la dispersion et les résonateurs de caisse influencent aussi la sortie. L’entrée stockée ne mesure pas la hauteur produite. Cette leçon apporte deux contrôles mathématiques et une réanalyse limitée d’échantillons générés auparavant.

## 1. Distinguer une fréquence demandée d’une estimation

Pour la demande nominale de 82.4069 Hz à 44100 Hz, le calcul en nombres réels donne une longueur de retard entière de 535, plus un reste fractionnaire. Le rapport entier seul `44100/535` vaut environ 82.429906542 Hz. Il décrit ce rapport simplifié, pas la sortie mesurée du moteur. Le code réel utilise une interpolation fractionnaire et des filtres de rétroaction plutôt qu’un simple retard entier.

La [liaison à l’entrée conservée](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-estimates-2026-10-22/input-bindings.json) correspond à une exécution antérieure de référence : 176400 échantillons float32 petit-boutistes, soit quatre secondes à 44100 Hz. Une [copie identique octet pour octet du tampon natif](https://raw.githubusercontent.com/spareilleux/learn/c953607dc38126877032dd5919e57d894971b257/code/streeling/evidence/pitch-estimates-2026-10-22/baseline-native.f32le) permet la vérification. Cette réanalyse utilise ces flottants, et non le WAV quantifié ou un nouveau rendu. Le [décodeur de tampon de NumPy](https://numpy.org/doc/stable/reference/generated/numpy.frombuffer.html) interprète l’ordre des octets déclaré `<f4` avant les calculs numériques.

### Exercice 1 : délimiter le calcul du retard

Quelle longueur entière et quelle fréquence fondée sur le seul retard entier découlent de la demande nominale indiquée ? La demande stockée ou ce rapport peuvent-ils certifier la hauteur mesurée en sortie ?

> **Réponse:** La longueur est de 535 et `44100/535` vaut environ 82.429906542 Hz. Aucun des deux ne certifie la hauteur mesurée. La demande stockée est une entrée, tandis que le rapport simplifié omet le comportement du retard fractionnaire et des filtres. Estimer la forme d’onde conservée constitue une autre opération, avec ses propres hypothèses et sa propre résolution.

## 2. Construire un signal dont la composante fondamentale est absente

Le complexe mathématique original A additionne des cosinus de phase nulle à 1000, 1200 et 1400 Hz, avec des amplitudes crêtes de 0.3, 0.2 et 0.1. À 48000 Hz sur une seconde, ces fréquences coïncident avec des cases de transformée cohérentes. La composante la plus forte est à 1000 Hz, mais la forme d’onde continue complète se répète toutes les `1/200` secondes : ces composantes sont les cinquième, sixième et septième harmoniques de 200 Hz. Aucune composante cosinus à 200 Hz n’a été fournie.

Les [contrôles synthétiques fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-estimates-2026-10-22/synthetic-periods.json) utilisent la [transformée de NumPy pour une entrée réelle](https://numpy.org/doc/stable/reference/generated/numpy.fft.rfft.html) et des projections directes séparées. Ils retrouvent les amplitudes fournies et l’absence d’amplitude à la fondamentale à `1e-10` près. Il s’agit de tableaux mathématiques sans fondu, pas de stimuli diffusés ou d’observations auprès d’un auditeur.

### Exercice 2 : rejeter le raccourci du plus grand pic

Pour A, indiquez la composante la plus forte, la fréquence fondamentale de répétition, la période en secondes et la période en échantillons. L’absence de composante à 200 Hz empêche-t-elle la forme d’onde complète de se répéter à cette fréquence ?

> **Réponse:** La composante la plus forte est à 1000 Hz ; la fréquence fondamentale de répétition est de 200 Hz, avec une période de `1/200` secondes et de 240 échantillons à 48000 Hz. Les trois composantes accomplissent 5, 6 et 7 cycles dans cet intervalle. Une composante spectrale non nulle à 200 Hz n’est pas nécessaire à cette répétition de la forme d’onde complète. Ce calcul ne détermine pas à lui seul la hauteur rapportée par un auditeur.

## 3. Garder visibles les multiples de période et le sens du score

Soustrayez la moyenne calculée sur toute la fenêtre. Pour chaque décalage positif, divisez le produit scalaire des parties superposées par la racine carrée du produit de leurs énergies. Vous obtenez un score de récurrence normalisé. Dans la recherche déclarée de 144 à 576 échantillons, A obtient des scores égaux à un à `1e-12` près aux décalages de 240 et 480. Le second correspond à une autre récurrence du même motif ; il ne prouve pas indépendamment qu’une composante à 100 Hz a été fournie.

Notre contrôle construit choisit le plus court de ces candidats à période parfaite ex æquo. Cette règle explicite renvoie 200 Hz ; choisir 480 renverrait 100 Hz. Les bornes des décalages et la règle de sélection influencent le résultat d’un estimateur. Un score proche de un mesure cet accord entre formes d’onde ; ce n’est pas une confiance étalonnée dans la justesse de l’octave choisie ou dans ce qu’une personne entend.

### Exercice 3 : exposer l’autre octave possible

Convertissez les décalages de 240 et 480 en fréquences à 48000 Hz. Lequel la règle déclarée du plus court décalage ex æquo choisit-elle, et que ne prouve pas l’autre score parfait ?

> **Réponse:** Ils donnent 200 et 100 Hz. La règle choisit 240 échantillons, donc 200 Hz. La récurrence à 480 est un multiple de la période ; elle ne prouve ni qu’une composante à 100 Hz a été fournie, ni une confirmation indépendante de l’octave choisie, ni une probabilité perceptive. Conservez les deux candidats et la règle.

## 4. Appliquer une méthode déclarée aux échantillons de guitare conservés

Les nouvelles fenêtres semi-ouvertes choisies sont 0.2–0.4, 0.4–0.6, 0.6–0.8 et 1.0–1.2 secondes. Chacune contient 8820 échantillons. Leur [compte rendu d’analyse](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-estimates-2026-10-22/native-pitch-windows.json) conserve les courbes complètes selon le décalage et les maxima locaux. La méthode spectrale utilise une fenêtre de Hann symétrique et la case de plus grande amplitude entre 50 et 500 Hz, sans interpolation ; l’espacement de 5 Hz entre cases compte. La méthode par décalage utilise les échantillons centrés sans Hann, des décalages entiers de 89 à 882, les maxima locaux intérieurs et un seuil de restitution de 0.9.

| Début de fenêtre, secondes | Case spectrale la plus forte, Hz | Décalage choisi, échantillons | Fréquence du décalage, Hz | Cents par rapport à la demande nominale |
| --- | --- | --- | --- | --- |
| 0.2 | 80 | 538 | 81.970260223 | -9.197475196 |
| 0.4 | 80 | 539 | 81.818181818 | -12.412395431 |
| 0.6 | 80 | 539 | 81.818181818 | -12.412395431 |
| 1.0 | 80 | 539 | 81.818181818 | -12.412395431 |

Les quatre meilleurs scores de récurrence dépassent 0.999, mais tous échouent au contrôle pédagogique de proximité déclaré à l’avance : une erreur absolue d’au plus 5 cents par rapport à la demande nominale de 82.4069 Hz. Ce contrôle est un diagnostic de cours fondé sur cette référence d’entrée, pas une mesure physique étalonnée de la hauteur ou une norme produit. De même, les cases spectrales à 80 Hz n’établissent pas une fréquence de sortie exactement égale à 80 Hz.

### Exercice 4 : conserver un contrôle échoué

Pour un décalage de 538, calculez la fréquence et interprétez l’écart rapporté d’environ -9.197475196 cents selon le contrôle à 5 cents. Son score supérieur à 0.999 rend-il le contrôle réussi ?

> **Réponse:** `44100/538` donne environ 81.970260223 Hz. La valeur absolue de son écart à la référence nominale dépasse 5 cents ; le résultat de cette méthode échoue donc au contrôle déclaré. Un score de récurrence élevé ne remplace pas le critère et ne certifie pas l’accordage. Aucune mesure physique indépendante et étalonnée de fréquence, aucun jugement humain et aucun nouveau rendu du moteur n’ont été réalisés.

## 5. Choisir l’expérience suivante sans cacher la limite

Avant de qualifier le moteur conservé de « faux », testez l’estimateur sur d’autres fréquences connues, phases, filtres, durées et octaves possibles, et précisez sa résolution. Une méthode à décalage fractionnaire pourrait être comparée, mais elle reste une candidate à étalonner, pas un remplacement automatiquement correct. Le témoignage d’un musicien sur la hauteur exige une tâche distincte, comme l’explique [COG-005](../../cognitive-science/cog-005-separate-pitch-estimates-from-listener-reports/).

Le candidat historique de décroissance de [GAS-004](../../guitar-acoustics/gas-004-run-open-e-decay-candidate/) a amélioré l’erreur retenue d’environ 0.114166150 dB face à une exigence de 1 dB et a échoué à ce critère. Une nouvelle analyse de hauteur ne renverse pas ce résultat et n’en identifie pas la cause. [DV-010](../../data-visualization/dv-010-show-pitch-errors-and-missing-estimates/) garde distinctes les estimations disponibles, les valeurs manquantes et les erreurs d’octave dans une représentation.

### Exercice 5 : rédiger le résultat de la boucle d’amélioration

Résumez le résultat des fenêtres conservées et un prochain contrôle, sans prétendre à un nouveau rendu, à la perception d’un auditeur ou à la réussite du critère de décroissance.

> **Réponse:** Quatre fenêtres natives conservées ont fourni des estimations par décalage entier proches de 81.97 ou 81.82 Hz, avec des scores de récurrence élevés, mais aucune réussite au contrôle déclaré à 5 cents de la référence nominale. Étalonnez l’estimateur et sa résolution en octave et en décalage sur des signaux contrôlés avant d’attribuer l’écart au moteur. Aucun rendu ou essai d’écoute n’a été relancé, et l’échec antérieur sur la décroissance reste inchangé.
