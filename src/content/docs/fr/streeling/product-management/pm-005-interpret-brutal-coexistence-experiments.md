---
title: Interpréter les expériences de coexistence BRUTAL avant de choisir un réglage par défaut
description: Interpréter les expériences de coexistence BRUTAL avant de choisir un réglage par défaut — Gestion de produit et de projet
sidebar:
  label: PM-005 · Interpréter les expériences de coexistence BRUTAL avant de choisir un réglage par défaut
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-005-interpret-brutal-coexistence-experiments.fr.md
---

:::note[Streeling University]
**PM-005** · Interpréter les expériences de coexistence BRUTAL avant de choisir un réglage par défaut · intermédiaire · 35 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-005-interpret-brutal-coexistence-experiments.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-004](../../product-management/pm-004-craft-extension-release-decision/), [VC-009](../../visual-computing/vc-009-budget-brutal-scene-expansion/)
:::

> **Périmètre du brouillon.** Analyse de comptes rendus d'expériences historiques publics et proposition d'une comparaison future. La revue technique humaine, la relecture linguistique par une personne maîtrisant la langue, les essais par des apprenants et la vérification du HTML public du cours restent à faire. Aucune nouvelle expérience graphique, GPU, DLSS ou de diffusion en continu n'a été exécutée pour cette leçon.

## La question du projet

Un outil auxiliaire de l'Observatory doit-il fonctionner sans plafond de fréquence d'images parce qu'il annonce un nombre d'images par seconde très élevé ? L'[évaluation BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) consigne à la fois un échec majeur de coexistence et un suivi non concluant. Une décision produit a besoin des deux, ainsi que du comportement de la tâche voisine. Cette leçon utilise ces preuves pour concevoir une prochaine comparaison défendable ; [PM-004](../../product-management/pm-004-craft-extension-release-decision/) traite plus largement des critères de publication des extensions.

Tous les documents sont lus au commit GA public `76efbffd5af82b46c3146957a6bd4504008eeb89`. Cela fixe les octets des documents. Les en-têtes des exécutions historiques nomment séparément des révisions antérieures et signalent des modifications non commitées. L'instantané documentaire n'identifie pas un binaire exact reproductible pour ces exécutions antérieures. Le [jeu de référence de comparaison historique](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/historical-comparison.json) conserve cette distinction.

## 1. Mesurer la tâche qui doit continuer à fonctionner

Le [rapport M2 sans plafond](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m2-20261019-235218.md) indique que HallSlice atteignait 10059 fps tandis que la vue RTX voisine passait d'une médiane de 60 fps avant l'exécution à une médiane de 2 fps pendant celle-ci. Il consigne également l'échec d'une vérification des touches de caméra. Le même document rapporte une présentation et un nettoyage réussis ; « la fenêtre a fonctionné » et « toute l'évaluation a réussi » sont donc des affirmations différentes.

La variation de la médiane de la vue est `(2-60)/60`, soit environ -96.67 pour cent. Ce calcul décrit la comparaison avant/pendant consignée. Il n'isole pas le mécanisme d'ordonnancement sous-jacent, ne prouve pas que toute exécution sans plafond provoque cette chute et ne mesure pas la machine actuelle. Une fréquence élevée chez le producteur n'établit pas un débit utile pour la personne qui regarde la tâche voisine.

### Exercice 1 : énoncer l'effet sur le produit

Calculez la variation relative de la médiane de la vue voisine. Pourquoi la fréquence d'images propre à HallSlice et une sortie propre ne permettent-elles pas d'approuver la coexistence ?

> **Réponse:** `(2-60)/60` vaut environ -0.9667, soit une baisse de 96.67 pour cent de la médiane rapportée pour la vue. La fréquence de HallSlice et son cycle de vie décrivent son propre comportement. Ils ne satisfont pas l'exigence distincte selon laquelle la vue voisine doit rester utilisable ; le rapport contient également l'échec d'une vérification des touches de caméra. Conservez l'ensemble du résultat consigné sans transformer cette comparaison unique en règle causale universelle.

## 2. Conserver les témoins qui remettent en cause la première interprétation

Le [rapport des témoins M3](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) alterne des témoins sans HallSlice et des exécutions sans plafond. Sa règle de réussite déclarée exige que le minimum de la vue soit d'au moins 58 fps.

| Condition | Minima de la vue, fps | Médianes de la vue, fps | Chutes consignées |
|---|---|---|---|
| Trois témoins | 57, 60, 49 | 60, 60, 57 | 2 |
| Trois exécutions sans plafond | 60, 60, 38 | 60, 60, 51 | 1 |

Deux témoins ont subi une baisse alors que HallSlice était absent. Le README public qualifie le suivi de non concluant : l'effondrement initial n'a pas été reproduit et la vue voisine variait d'elle-même. Ces petits échantillons séquentiels ont des durées d'observation différentes et une scène en mouvement. Compter moins de chutes dans le groupe sans plafond ne prouve pas que le rendu sans plafond protège la vue.

### Exercice 2 : mettre l'affirmation à jour

Selon la règle déclarée d'un minimum de 58 fps, comptez les chutes dans les deux conditions. Qu'est-ce que cela remet en cause, et pourquoi l'affirmation « l'absence de plafond améliore la coexistence » serait-elle également sans fondement ?

> **Réponse:** Les minima témoins de 57 et 49 échouent, soit deux chutes ; le minimum sans plafond de 38 échoue, soit une chute. La variation sans HallSlice remet en cause l'attribution de chaque petite baisse à ce processus. Les courtes fenêtres séquentielles ne maintiennent pas constantes la phase de la scène et les autres charges ; l'affirmation causale inverse n'est donc pas étayée non plus. Gardez visibles l'observation M2 d'origine et le suivi non concluant.

## 3. Vérifier à la fois la définition de la mesure et la règle de décision

Le README public indique que M2 chronométrait le travail du début d'une image à sa présentation. M3 chronométrait l'intervalle entre deux présentations successives. Leurs valeurs p50 ont donc des bornes temporelles différentes : comparer 0.073 ms dans le rapport M2 sans plafond à 0.064 ms dans le balayage M3 n'établit pas une amélioration de vitesse selon une mesure commune.

Le [balayage M3](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000131.md) utilisait une règle plus stricte de minimum de la vue à 60 fps. Avec les plafonds de 120 et 480, il rapportait un minimum de 59 et signalait des chutes. Reclasser ces valeurs selon une règle hypothétique de 58 fps les ferait réussir, mais ne changerait ni les observations ni la règle consignée à l'origine. Conservez les libellés d'origine et les libellés alternatifs dans des colonnes distinctes. Fixez la règle d'un nouvel essai avant d'en connaître les résultats.

### Exercice 3 : auditer une amélioration apparente

Un agent combine les deux valeurs p50 pour affirmer que le système est « plus rapide » et modifie les libellés du balayage à 59 fps pour les déclarer réussis. Identifiez les deux problèmes indépendants et les preuves nécessaires à une comparaison équitable.

> **Réponse:** Les valeurs p50 résument des intervalles dont les bornes temporelles diffèrent, et le changement de libellé applique un autre seuil après observation des données. Utilisez une définition commune du chronométrage et conservez chaque règle d'origine. Un classement alternatif à 58 fps peut être présenté explicitement, mais une nouvelle comparaison acceptée nécessite une règle déclarée à l'avance et des mesures issues du même protocole.

## 4. Distinguer une capacité demandée de son fonctionnement observé

Les [commentaires du code source public de Colossus](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L29-L41) documentent `--dlss` et `--rr`, les composants NVIDIA externes et le comportement de repli. Ils décrivent également la transmission d'une scène Lego validée à l'application graphique. Il s'agit d'observations du code source. Les nouveaux tests sur CPU de [VC-009](../../visual-computing/vc-009-budget-brutal-scene-expansion/) ont exercé le chemin de description pure, sans exercer ces fonctionnalités graphiques.

Un relevé de benchmark doit distinguer le mode demandé, la capacité disponible, le mode effectivement activé et la sortie ou le chronométrage observés. Si une fonctionnalité utilise un repli, indiquez-le pour cette exécution. Un indicateur demandé ou une scène acceptée ne peut prouver la qualité d'image de DLSS, la vitesse du lancer de rayons ou la coexistence sur un autre hôte.

### Exercice 4 : classer les preuves de capacité

Un agent joint une commande contenant `--dlss` et une description CPU réussie, puis déclare réussi le critère de performance DLSS du moteur de rendu. Que manque-t-il ?

> **Réponse:** Le relevé nécessite une véritable exécution graphique montrant la disponibilité de la capacité, son activation réussie ou un repli explicite, le mode de rendu effectif et les mesures de qualité et de performance déclarées sur un matériel et un pilote identifiés. Ni le texte de l'indicateur ni la validation de scène sur CPU ne fournissent ces observations. Aucun résultat graphique de ce type n'a été produit pour cette leçon.

## 5. Concevoir une comparaison susceptible de changer le réglage par défaut

Pour un futur test de coexistence, figez l'identité du code source et du binaire ainsi que tout diff non commité, la scène, la phase de caméra, la graine, le matériel et le pilote, le mode de présentation, le plafond, les bornes du chronométrage et la durée d'échantillonnage. Répétez les témoins et les traitements à des phases de scène correspondantes ; contrebalancez leur ordre. Observez la tâche voisine ainsi que le nouvel outil, conservez toutes les exécutions et déclarez la marge de ressources et les garde-fous d'interruption. Ce sont des exigences proposées, sans test exécuté ici.

La question produit est de savoir si le réglage par défaut choisi satisfait l'exigence de coexistence déclarée pour la charge testée. Si les témoins sont trop variables pour distinguer un effet, signalez l'incertitude et améliorez la comparaison. Les preuves historiques justifient de laisser le risque de coexistence ouvert ; elles ne certifient pas un réglage sans plafond par défaut et n'établissent pas de plafond universellement sûr.

### Exercice 5 : choisir la prochaine expérience

Rédigez une prochaine comparaison bornée entre un fonctionnement avec et sans plafond à côté de l'Observatory. Nommez un résultat qui empêcherait d'approuver l'absence de plafond par défaut et expliquez ce que ce résultat n'établirait toujours pas.

> **Réponse:** Comparez des témoins, des exécutions avec plafond et des exécutions sans plafond répétés, dans un ordre équilibré, à des phases fixes de scène et de caméra, avec les mêmes fenêtres de chronométrage et d'observation. Fixez les modes effectifs, l'état du binaire et du code source, l'hôte et le pilote ainsi qu'une règle pour la vue voisine déclarée à l'avance. Une violation reproductible sans plafond selon ce protocole empêche l'approbation pour la charge testée ; un résultat non concluant laisse également l'approbation sans fondement. Une réussite resterait conditionnelle à cet hôte, cette charge et ce protocole, sans prouver une coexistence GPU universelle.

## Limites des preuves

La [relecture du code source](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/primary-readback.json) relie les documents publics et le code. Le jeu de référence historique reconstitue fidèlement des lignes consignées sélectionnées, avec de nouveaux calculs et un protocole futur. Il ne contient aucun nouveau résultat GPU, diagnostic de la machine actuelle, revue humaine ou résultat d'apprentissage. Un déploiement ultérieur devra vérifier séparément le HTML public du cours.
