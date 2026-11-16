---
title: Choisir une représentation temps-fréquence pour un transitoire de guitare
description: Choisir une représentation temps-fréquence pour un transitoire de guitare — Physique
sidebar:
  label: PHY-002 · Choisir une représentation temps-fréquence pour un transitoire de guitare
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-002-time-frequency-guitar-transients.fr.md
---

:::note[Streeling University]
**PHY-002** · Choisir une représentation temps-fréquence pour un transitoire de guitare · intermédiaire · 35 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-002-time-frequency-guitar-transients.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-001](../../physics/phy-001-science-of-guitar-sound/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-audio-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de physique** | Intermédiaire | 35 minutes | Traduction IA provisoire ; revue humaine du contenu et tests auprès d'apprenants en attente

## Objectifs

Vous répondrez à une question précise d'analyse du signal : **une FFT peut-elle analyser une note de guitare dont le spectre évolue dans le temps, et quand un analyste GA devrait-il plutôt utiliser une STFT ou un suivi par ondelettes ?** Vous distinguerez la validité du calcul d'une transformée de l'affirmation que sa représentation permet d'étayer, calculerez un compromis de fenêtrage et interpréterez les mesures épinglées du mi à vide dans les intervalles temporels sélectionnés. [PHY-001](../../physics/phy-001-science-of-guitar-sound/) présente les harmoniques ; [GAS-001](../../guitar-acoustics/gas-001-open-string-audio-evidence/) aborde les questions de moteur de guitare et d'écoute liées à la fixture. Cette leçon se concentre sur la méthode temps-fréquence.

## 1. Une FFT globale est valide, mais son spectre ne situe pas les événements

Utilisez la [fixture GAS-001 et sa provenance](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/README.md), épinglées au commit Demerzel [`5c49674`](https://github.com/GuitarAlchemist/Demerzel/tree/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001). Les deux WAV sont des fichiers mono de quatre secondes à 44,100 Hz. La première attaque de l'enregistrement se situe vers **1.1 seconde** dans le fichier, et une autre attaque survient vers **2.75 secondes**. La note rendue par GA commence à l'instant zéro du fichier. Les événements se répartissent donc différemment, même si les deux fichiers sont étiquetés mi2 à vide.

Une transformée de Fourier discrète peut être calculée sur **tout signal échantillonné de durée finie**, y compris un signal non stationnaire. Elle n'exige pas que la guitare conserve un spectre constant. Le problème tient à l'interprétation : un seul spectre d'amplitude calculé sur les quatre secondes réunit la portion calme initiale, les attaques et les décroissances. Une composante forte dans le bin de 165 Hz ne dirait pas quelle attaque a contribué à cette énergie. La transformée complexe complète conserve la phase et peut être inversée ; c'est la **représentation unique et globale de l'amplitude** qui manque d'un axe temporel pour répondre à la question des événements. Un extrait de quatre secondes donne un espacement nominal des bins fréquentiels de `1/4 = 0.25 Hz` avant tout ajout de zéros, mais la finesse de cet espacement ne restitue pas les repères temporels manquants.

### Exercice pratique 1

Un analyste affirme : « Le mi2 enregistré évolue dans le temps ; appliquer une FFT est donc mathématiquement invalide. » Corrigez cette affirmation et nommez la véritable limite d'un spectre d'amplitude unique portant sur le fichier entier dans ce cas.

> **Réponse :** La FFT est valide sur l'enregistrement échantillonné. Son spectre d'amplitude sur le fichier entier réunit la portion calme initiale, la première note et l'attaque ultérieure sans préciser quand une composante est apparue. Il ne permet pas de dire si un partiel appartient à la première attaque ou à la suivante. Utilisez une fenêtre temporelle sélectionnée ou une transformée résolue dans le temps pour répondre à cette question.

## 2. Choisir la fenêtre en fonction de la question

Le [script de mesure](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measure-pair.py) épinglé choisit une attaque approximative pour chaque fichier et effectue une **FFT d'une seconde avec fenêtre de Hann, de 0.2 à 1.2 seconde après cette attaque**. La FFT de l'enregistrement analyse donc environ **1.3–2.3 secondes** du fichier, tandis que celle du rendu utilise **0.2–1.2 seconde**. La deuxième attaque enregistrée, vers 2.75 secondes, reste en dehors de l'intervalle spectral choisi. À 44,100 Hz, la fenêtre d'une seconde contient 44,100 échantillons et les bins de sa FFT sans ajout de zéros sont espacés de **1 Hz**. Une fenêtre de Hann réduit les fuites spectrales aux bords, mais élargit les pics ; l'espacement des bins ne garantit pas à lui seul la résolution de deux sons proches.

La nouvelle exécution de `measure-pair.py` a reproduit les [mesures](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/measurements.json) sauvegardées : le pic local du premier partiel se trouvait à **83 Hz** pour l'enregistrement et à **82 Hz** pour le rendu. Ce sont des bins sélectionnés dans la recherche du script à ±8 Hz autour de la cible mi2 de 82.4069 Hz. Ces nombres décrivent cette fenêtre et cette règle de sélection du pic. Ils n'établissent pas que les deux sources présentent un écart de hauteur d'un hertz. Modifier le repère d'attaque ou la fenêtre peut modifier le spectre local d'une note non stationnaire.

### Exercice pratique 2

Quel intervalle du fichier enregistré la FFT d'une seconde sauvegardée utilise-t-elle, et pourquoi l'intervalle 0.2–1.2 seconde du fichier répondrait-il à une autre question ? Calculez l'espacement nominal de ses bins sans ajout de zéros.

> **Réponse :** Elle utilise environ 1.3–2.3 secondes du fichier : l'attaque à 1.1 plus 0.2–1.2 seconde. L'intervalle 0.2–1.2 du fichier comprend surtout la portion précédant la note et seulement le début de celle-ci. Une FFT d'une seconde, soit 44,100 échantillons, possède des bins espacés de `44,100 / 44,100 = 1 Hz`. Cet espacement de grille ne certifie pas à lui seul un pouvoir de résolution d'un hertz.

## 3. La STFT échange du détail spectral contre la localisation temporelle des événements

Une transformée de Fourier à court terme (STFT) répète une FFT fenêtrée à des instants successifs. La [documentation de `ShortTimeFFT` de SciPy](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.ShortTimeFFT.html) décrit la fenêtre et le pas : la fenêtre définit l'étendue des échantillons qui contribuent à chaque spectre ; le pas définit la fréquence à laquelle les spectres sont produits. La sortie possède des axes temporel et fréquentiel. Réduire le pas produit davantage de colonnes qui se chevauchent, **pas** une fenêtre d'analyse plus étroite ni une résolution fréquentielle supplémentaire indépendante.

Considérons une fenêtre de Hann de 50 ms **proposée** pour examiner les attaques des fichiers GAS-001. À 44,100 Hz, elle compte 2,205 échantillons, avec une grille de bins sans ajout de zéros de `1/0.05 = 20 Hz`. Elle localise les changements bien plus précisément dans le temps que la FFT d'une seconde sauvegardée, mais donne une grille fréquentielle beaucoup plus grossière et des pics spectraux plus larges. Une fenêtre glissante d'une seconde conserve la grille plus fine, mais étale une attaque brève sur environ une seconde de contexte. Il s'agit d'un compromis temps-fréquence, pas d'un classement des outils. La fixture réelle n'a **pas** sauvegardé de STFT ; les réglages de 50 ms et cette comparaison constituent un exercice de conception, pas une sortie mesurée.

Pour une vérification ultérieure utile, repérez les deux attaques dans la forme d'onde, calculez une STFT avec une fenêtre et un pas déclarés, puis comparez ses repères temporels à ceux de la FFT d'une seconde sélectionnée. Conservez les mêmes empreintes WAV et la même convention d'attaque. Si la deuxième attaque apparaît dans la représentation fenêtrée mais pas dans l'intervalle réservé à la première note, les représentations répondent bien à des questions différentes, comme prévu.

### Exercice pratique 3

À 44,100 Hz, combien d'échantillons et quel espacement nominal des bins possède une fenêtre STFT de 50 ms sans ajout de zéros ? Passer uniquement le pas de 25 ms à 5 ms permettrait-il de mieux séparer deux partiels proches dans chaque colonne ?

> **Réponse :** `0.05 × 44,100 = 2,205` échantillons et `1/0.05 = 20 Hz` d'espacement nominal des bins. Un pas de 5 ms crée davantage de colonnes temporelles qui se chevauchent ; il ne change ni les échantillons des 50 ms de chaque colonne ni leur discrimination fréquentielle intrinsèque. Utilisez une fenêtre plus longue pour mieux séparer des fréquences proches, en acceptant une localisation temporelle moins précise.

## 4. Un suivi par ondelettes adapte sa durée à la fréquence

Le script de la fixture calcule aussi des **suivis par ondelettes complexes de type Morlet**, à des fréquences centrales choisies près de **82.41, 164.81 et 329.63 Hz**. Il choisit une largeur selon `sigma = 6/(2π × center_hz)` : un suivi de plus basse fréquence s'étend donc davantage dans le temps qu'un suivi de plus haute fréquence. C'est l'origine de son échelle temporelle dépendante de la fréquence. Le [guide des ondelettes continues de PyWavelets](https://pywavelets.readthedocs.io/en/latest/ref/cwt.html) explique la relation générale entre échelle et fréquence ; GAS-001 utilise son propre noyau de convolution explicite, et non `pywt.cwt`.

L'artefact sauvegardé indique une variation de niveau du deuxième partiel entre **0.2–0.4** et **1.0–1.2 seconde après l'attaque sélectionnée** de **−4.5 dB** pour l'enregistrement et de **−12.9 dB** pour le rendu. Avec ce noyau et ces intervalles, le suivi du deuxième partiel du rendu présente une variation tardive moins précoce **plus négative de 8.4 dB**. Une FFT locale d'une seconde peut indiquer un niveau du deuxième partiel moyenné sur son intervalle, mais elle ne peut pas, à elle seule, indiquer cette variation entre deux sous-intervalles. Les valeurs des ondelettes sont des rapports au sein de chaque fichier ; elles ne comparent ni la sonie absolue ni la qualité sonore.

Les ondelettes n'échappent pas au compromis temps-fréquence. Une ondelette plus large à basse fréquence peut brouiller une attaque rapide ; une ondelette de plus haute fréquence, plus courte dans le temps, possède une bande passante fréquentielle absolue plus large. Le choix des fréquences centrales, la largeur, les limites et l'attaque approximative comptent tous. Ce suivi de trois fréquences ne décrit pas non plus toutes les composantes spectrales. Une STFT ciblée ou un autre réglage d'ondelettes peut être préférable pour une autre question.

### Exercice pratique 4

Calculez la différence entre les deux variations sauvegardées tardives moins précoces du deuxième partiel. Que permet-elle d'établir, et que ne permet-elle pas d'établir ?

> **Réponse :** `−12.9 − (−4.5) = −8.4 dB` : le deuxième partiel suivi du rendu a baissé de 8.4 dB de plus selon la méthode sauvegardée. Cela établit une différence entre ces enveloppes par ondelettes et ces intervalles choisis au sein de chaque fichier. Cela n'établit ni une erreur de hauteur, ni un écart de volume global, ni un paramètre causal du moteur, ni le réalisme perçu.

## 5. Associer une méthode à une affirmation réfutable

Pour cette fixture, utilisez la FFT locale pour répondre à « Quels pics sont forts pendant l'intervalle sélectionné de la première note ? » Utilisez la STFT pour « Quand l'énergie spectrale change-t-elle au fil des deux attaques ? » Utilisez les suivis par ondelettes sauvegardés pour « Comment les enveloppes de ces trois partiels choisis évoluent-elles après l'attaque alignée ? » Conservez avec chaque résultat la fenêtre, le pas ou la largeur de l'ondelette, le repère d'attaque, la fréquence d'échantillonnage et les empreintes des fichiers. Ne modifiez qu'un choix d'analyse à la fois et montrez si la conclusion reste valable.

Un exercice réfutable pour une exécution ultérieure consiste à vérifier ceci : avec l'attaque enregistrée placée vers 1.1 seconde, une représentation résolue dans le temps devrait distinguer l'attaque ultérieure, vers 2.75 secondes, de l'intervalle de la première note. Si une mesure présentée comme réservée à la première note comprend l'attaque ultérieure, inspectez ses bornes temporelles et rejetez cette affirmation. Il s'agit d'un contrôle du périmètre de l'analyse, pas d'un verdict d'écoute ou sur le moteur.

### Exercice pratique 5

Un collègue montre les pics sauvegardés de 83 Hz et 82 Hz et affirme : « L'enregistrement et le rendu diffèrent exactement de 1 Hz pendant les deux extraits entiers de quatre secondes. » Quelle est l'affirmation la plus forte étayée par les données, et quel contrôle résolu dans le temps permettrait de tester l'affirmation plus large ?

> **Réponse :** Dans la recherche de pics sauvegardée, sur une seconde alignée sur l'attaque et avec une fenêtre de Hann, les bins sélectionnés étaient 83 Hz et 82 Hz. L'analyse n'a pas estimé la hauteur sur les deux extraits complets. Calculez des estimations locales répétées avec une résolution déclarée suffisante pour tester un écart de 1 Hz, indiquez chaque intervalle temporel et examinez séparément la première note et l'attaque enregistrée ultérieure. Une estimation suffisamment résolue montrant un autre écart réfuterait l'affirmation « pendant les deux extraits entiers » ; un écart non résolu dans une fenêtre grossière la laisserait non vérifiée.

## Sources et limites

Les WAV, le script et le JSON sont épinglés au commit Demerzel `5c4967454ddc740ed937c87719ca4d71a3522e4b` ; le code Rust du rendu GA est épinglé séparément au commit GA [`dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs). J'ai réexécuté le script de mesure Python versionné sur les WAV versionnés et retrouvé ses valeurs sauvegardées ainsi que les empreintes des fichiers. Les repères d'attaque sont approximatifs, l'étiquette de la source enregistrée provient des métadonnées du jeu de données, et le rendu est une compilation native plutôt qu'une capture du navigateur. Aucune sortie STFT n'a été mesurée pour cette leçon. Les documentations de SciPy et de PyWavelets étayent les descriptions des méthodes, tandis que les comparaisons numériques proviennent uniquement de la fixture épinglée. La revue humaine du contenu, les tests auprès d'apprenants, la validation linguistique et la publication restent en attente.
