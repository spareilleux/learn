---
title: Préserver les axes et les unités en composant des sorties spectrales
description: Préserver les axes et les unités en composant des sorties spectrales — Informatique
sidebar:
  label: CS-013 · Préserver les axes et les unités en composant des sorties spectrales
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/fr/cs-013-preserve-spectral-axes-and-units.fr.md
---

:::note[Streeling University]
**CS-013** · Préserver les axes et les unités en composant des sorties spectrales · intermédiaire · 35 minutes

Généré par le département *Informatique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/fr/cs-013-preserve-spectral-axes-and-units.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-012](../../computer-science/cs-012-native-and-wasm-render-boundaries/), [AUD-006](../../audio-engineering/aud-006-calibrate-spectral-amplitudes/)
:::

> **Portée du brouillon.** Analyse d'interface appuyée sur le code source et jeux de données numériques mesurés. La revue technique humaine, la révision par des personnes maîtrisant la langue, les essais des apprenants et la vérification du HTML public du cours restent à effectuer. Aucun binaire IX, aucun nouveau nœud ComfyUI ni aucun schéma de transmission de production n'ont été exécutés ou introduits.

## La question du projet

Un agent transmet une matrice spectrale IX à un nœud de graphe ou à un affichage. Le destinataire vérifie le nombre total de valeurs, dessine une image plausible et annonce une réussite. Quelles informations pourraient encore être erronées ? La composition exige les coordonnées et le sens des valeurs, ainsi que leur taille de stockage. Cette leçon examine cette interface ; [CS-012](../../computer-science/cs-012-native-and-wasm-render-boundaries/) traite des limites entre les rendus natifs et WASM.

Le [gestionnaire de spectrogramme IX à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-agent/src/handlers.rs#L1143-L1189) renvoie `spectrogram`, `n_frames`, `n_bins`, `window_size`, `hop_size` et `db`. Ses données ne fournissent ni fréquence d'échantillonnage ni tableaux d'axes temporel et fréquentiel. La [boucle de trames du cœur](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L6-L54) place les trames temporelles en lignes et les indices fréquentiels en colonnes, avec uniquement des fenêtres complètes. Ces affirmations reposent sur le texte du code source, pas sur une réponse de service en direct.

Le [jeu de données de coordonnées](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/spectral-views-2026-10-22/coordinates.json) reproduit ce découpage sur deux WAV conservés à l'aide d'une [analyse NumPy temporaire](https://numpy.org/doc/stable/reference/generated/numpy.fft.rfft.html). Son objet `advisory_handoff` est un exemple pédagogique à critiquer, pas un nouveau contrat de l'écosystème. Vous retrouverez les coordonnées, révélerez une erreur de pas de stockage et identifierez le contexte que le destinataire doit obtenir d'un appelant de confiance.

## 1. Déduire la forme de la règle de découpage en trames

Pour une longueur de signal de 176400, une fenêtre de 2048 et un pas de 512, le nombre de trames complètes est `1 + floor((176400-2048)/512) = 341`. Une transformée réelle unilatérale possède `2048/2 + 1 = 1025` indices fréquentiels. La matrice organisée par trames contient donc 349525 valeurs. La dernière trame commence à l'échantillon 174080 et se termine à l'échantillon exclusif 176128, laissant 272 échantillons hors des trames complètes.

Cette fin non couverte découle de la règle énoncée. Elle ne prouve aucune perte d'échantillons par le décodeur et ne permet pas de prétendre que l'affichage analyse tous les échantillons du fichier original. Le remplissage et le traitement de fenêtres partielles sont des politiques possibles, mais adopter l'une ou l'autre modifierait cette expérience.

### Exercice 1 : retrouver la forme et la fin non couverte

Calculez la forme de la matrice, le nombre total de cellules, les limites de la dernière trame et la fin non couverte à partir de l'entrée déclarée. Remplir la dernière trame conserverait-il la même politique d'analyse ?

> **Réponse:** La forme est de 341 par 1025, avec `341*1025 = 349525` valeurs. Le dernier début est `340*512 = 174080` ; la fin exclusive est `174080+2048 = 176128`. La fin non couverte est de `176400-176128 = 272` échantillons. Le remplissage introduirait une autre politique déclarée ; ses sorties ne doivent donc pas être présentées comme ce résultat à trames complètes.

## 2. Rattacher le temps à un point déclaré de la fenêtre

Ce jeu de données étiquette le début de trame par `t[j] = j*512/44100` secondes et la fréquence de l'indice par `f[k] = k*44100/2048` hertz. Une fenêtre s'étend sur environ 0.046440 seconde ; le pas est d'environ 0.011610 seconde. Les étiquettes de début de trame et de centre de fenêtre sont deux conventions possibles, mais passer silencieusement de l'une à l'autre décale l'événement affiché.

Le graphique associé dessine chaque colonne sur une cellule d'affichage de la largeur d'un pas. Cette cellule ne décrit pas l'ensemble des échantillons utilisés par la transformée : une trame utilise 2048 échantillons, même si les colonnes avancent de 512 échantillons. La dernière cellule d'affichage se termine vers 3.959002 secondes ; l'étendue des échantillons de la dernière trame se termine vers 3.993832 secondes. Distinguez ces étendues pour comparer un repère d'attaque à l'image.

### Exercice 2 : décoder une cellule

Pour la trame 50 et l'indice fréquentiel 32, donnez le temps de début de trame et la fréquence selon les formules déclarées. La colonne de la largeur d'un pas signifie-t-elle que seuls 512 échantillons ont contribué ? Quel contexte manque si le destinataire possède la matrice et les valeurs de fenêtre et de pas, mais aucune fréquence d'échantillonnage ?

> **Réponse:** Le début est `50*512/44100`, soit environ 0.580499 seconde ; la fréquence est `32*44100/2048 = 689.0625` Hz. Chaque transformée complète utilise toujours 2048 échantillons. Sans fréquence d'échantillonnage, le destinataire peut conserver les coordonnées en indices d'échantillon et de fréquence, mais ne peut pas attribuer ces valeurs absolues en secondes et en hertz.

## 3. Tester l'orientation avec une sentinelle non symétrique

Le petit jeu de données définit trois lignes de trames et cinq colonnes d'indices fréquentiels, avec `value = 100*frame + bin`. Il est délibérément non carré pour qu'une forme transposée soit visiblement différente. Dans un buffer aplati stocké par lignes, l'élément de la trame 2 et de l'indice 4 a pour décalage `2*5+4 = 14` et pour valeur 204. Utiliser accidentellement un pas de stockage de 3 lit plutôt le décalage 10 et la valeur 200. Les deux buffers peuvent pourtant contenir le même nombre total de valeurs.

Les bibliothèques de tracé attendent souvent une image fréquence par temps. Dans ce cas, transposez la matrice trame par indice pour l'affichage et associez ses axes en conséquence. Ne modifiez pas l'ordre des axes du relevé source pour l'adapter à un appel de tracé. Une vérification de forme, une vérification de cellule et une vérification de coordonnées ciblent des modes de défaillance différents.

### Exercice 3 : rejeter une vérification de taille réussie

Un destinataire possède 15 valeurs et lit la trame 2, indice 4, avec un pas de stockage de 3. Son auteur dit que la vérification du nombre de cellules prouve la justesse du résultat. Calculez les décalages et valeurs corrects et erronés, puis proposez une vérification plus solide.

> **Réponse:** Le décalage correct est `2*5+4 = 14`, pour une valeur de 204. Le décalage erroné est `2*3+4 = 10`, pour une valeur de 200. Le total de 15 ne distingue pas les organisations. Exigez une forme de 3 par 5, l'ordre des axes trame puis indice fréquentiel, la convention déclarée de stockage par lignes et le résultat de la cellule sentinelle, puis une vérification de coordonnées réelles.

## 4. Préserver le sens des valeurs

Le drapeau IX `db` distingue les modules bruts de leur conversion logarithmique ; il ne leur confère pas une unité physique étalonnée. [AUD-006](../../audio-engineering/aud-006-calibrate-spectral-amplitudes/) applique plutôt un estimateur explicite d'amplitude corrigé du gain cohérent de la fenêtre. Un affichage recevant cette matrice dérivée doit savoir quelle grandeur il a reçue, quelle fenêtre a été utilisée, comment les extrémités ont été mises à l'échelle, quelle est la référence des dB le cas échéant, et quel plancher d'affichage s'applique.

La transmission proposée associe une empreinte de WAV source, une fréquence d'échantillonnage, une forme, des axes ordonnés, une référence temporelle de trame, une fenêtre et un pas, une formule de fenêtre, un estimateur d'amplitude et une référence d'affichage. Ces champs expriment les informations nécessaires à cet exemple. Ils n'ont été ni ratifiés comme schéma ni implémentés dans un pont IX/ComfyUI. Une véritable intégration devrait définir sa validation et son comportement en cas d'échec à sa propre frontière ; ne déduisez pas qu'un relevé proposé les fournit déjà.

### Exercice 4 : réparer une transmission incomplète

Un agent envoie une matrice logarithmique et écrit seulement « 349525 cellules ; dB ; réussite ». Nommez les informations manquantes pour reproduire les coordonnées et l'interprétation des valeurs de cette leçon. Peut-il qualifier la matrice de réponse IX observée ?

> **Réponse:** Exigez l'identité de la source et la convention de décodage, la forme de 341 par 1025, l'ordre des axes trame/indice fréquentiel et la convention de stockage, la fréquence d'échantillonnage de 44100 Hz, la fenêtre de 2048, le pas de 512, le temps au début de trame, la formule de fenêtre, l'estimateur des valeurs, le traitement des extrémités, la référence des dB et le plancher. Les données conservées ont été calculées par une analyse numérique temporaire suivant les équations du code source à la révision fixée ; elles ne doivent donc pas être réétiquetées comme une réponse d'un binaire IX exécuté.

## 5. Faire rejeter l'ambiguïté à la frontière de composition

Dans un flux de travail d'agents, une image plausible prouve peu la justesse d'une transmission. Avant de comparer des candidats, validez les coordonnées et les hypothèses sur les grandeurs. Si une fréquence d'échantillonnage ou une référence de valeur requise manque, signalez l'exigence manquante au producteur ou conservez explicitement des données en indices seulement. Une unité devinée se propage silencieusement à tous les jugements en aval.

### Exercice 5 : choisir l'action suivante

Un agent en aval veut classer des candidats de guitare selon une caractéristique spectrale affichée, mais les données n'ont ni fréquence d'échantillonnage ni référence d'étalonnage. Que peut-il conserver sans risque, que doit-il demander et quelle affirmation doit attendre ?

> **Réponse:** Conservez les valeurs originales, l'identité de la source, la forme existante et les coordonnées d'indices connues. Demandez la fréquence d'échantillonnage de confiance et le contrat sur les valeurs, la fenêtre et la référence ; validez-les avant d'attribuer des hertz, des secondes ou des dB étalonnés. Le classement de la caractéristique et son interprétation musicale doivent attendre ces éléments. Consigner le contexte manquant est un résultat utile à cette frontière, pas une comparaison mesurée ni un protocole de contre-pression sémantique implémenté.

## Limites des preuves

Lisez le [compte rendu d'analyse](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/spectral-views-2026-10-22/execution.json) et la [vérification des sources](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/spectral-views-2026-10-22/primary-readback.json) pour les versions et les empreintes des entrées. Le jeu de données teste l'arithmétique, l'orientation et l'interprétation avec des entrées déclarées. Il n'établit ni l'adéquation d'un schéma général, ni l'exécution d'une chaîne d'éditeur IX, ni un adaptateur de production, ni un résultat d'apprentissage.
