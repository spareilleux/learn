---
title: Évaluer un moteur de rendu de l’Observatoire selon plusieurs scénarios
description: Évaluer un moteur de rendu de l’Observatoire selon plusieurs scénarios — Futurologie
sidebar:
  label: FUT-004 · Évaluer un moteur de rendu de l’Observatoire selon plusieurs scénarios
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/futurology/fr/fut-004-scenario-test-an-observatory-renderer.fr.md
---

:::note[Streeling University]
**FUT-004** · Évaluer un moteur de rendu de l’Observatoire selon plusieurs scénarios · intermédiaire · 35 minutes

Généré par le département *Futurologie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/futurology/fr/fut-004-scenario-test-an-observatory-renderer.fr.md) · [Mon journal](../../journal/)

Prérequis: [FUT-003](../../futurology/fut-003-agent-substitution-readiness-drill/)
:::

> **Périmètre du brouillon.** Rapports du projet figés à une révision précise et tables de décision construites pour le cours. La revue technique humaine, la révision linguistique par une personne maîtrisant la langue, les essais apprenants, les résultats d’un rendu en fonctionnement et la vérification du HTML déployé restent à faire. Les pertes et probabilités des scénarios ci-dessous sont des hypothèses pédagogiques inventées, pas des mesures ni des prévisions.

## La question du projet

Quelle politique visuelle un agent de l’Observatoire devrait-il choisir lorsque la capacité de la machine hôte, les charges concurrentes et la disponibilité de l’adaptateur peuvent changer ? La [page de RAND sur la prise de décision robuste](https://www.rand.org/pubs/tools/TL320/tool/robust-decision-making.html) distingue les désaccords sur les relations entre éléments du système, les probabilités et les valeurs comme sources d’incertitude. Elle décrit le cadrage, l’évaluation selon plusieurs futurs, l’analyse des vulnérabilités et l’analyse des compromis. Nous nous exerçons sur un petit calcul de décision ; ce n’est pas une mise en œuvre complète de cette démarche.

Le [rapport historique de coexistence de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) présente des variations même sans la charge de rendu supplémentaire. L’[analyse précédente dans PM-005](../../product-management/pm-005-interpret-brutal-coexistence-experiments/) conserve le caractère non concluant du suivi. Ces observations motivent l’examen d’autres options. Elles ne fournissent ni les pertes ni les probabilités de la table de cette leçon et ne valident pas un moteur de rendu adaptatif.

## 1. Cadrer la décision avant d’attribuer des probabilités

Utilisons trois stratégies hypothétiques : priorité à la coexistence `C`, priorité au détail `P` et candidate adaptative `A`. Utilisons trois conditions hypothétiques : machine hôte limitée, puissante et soumise à une contention. Chaque case est un score de perte construit ; une valeur plus faible est préférable. Supposons que ces points aient une signification cardinale comparable entre lignes et colonnes. Cette hypothèse doit elle-même être justifiée avant une décision réelle.

| Stratégie | Machine limitée | Machine puissante | Machine en contention |
| --- | --- | --- | --- |
| C | 3 | 6 | 6 |
| P | 8 | 0 | 14 |
| A | 4 | 3 | 5 |

Ces noms ne certifient ni des modes installés ni le comportement du contrôleur de [CYB-005](../../cybernetics/cyb-005-stop-render-policy-flapping/). Il n’existe ici ni distribution d’échantillonnage ni fréquence mesurée de ces conditions. Énumérer trois scénarios n’attribue pas à chacun une probabilité d’un tiers.

### Exercice pratique 1 : repérer l’inférence non étayée

Un agent qualifie la perte de 5 de A, dans la colonne de la machine en contention, de pénalité GPU mesurée et attribue la même probabilité aux trois colonnes. Quelles hypothèses a-t-il ajoutées ?

> **Réponse :** Il a transformé une hypothèse en points de perte construite pour le cours en mesure matérielle et introduit des probabilités absentes de la table. Rien de cela ne découle de l’énumération des scénarios. Une évaluation réelle exige des conséquences mesurées ou explicitement modélisées, des échelles de valeur justifiées et un traitement de l’incertitude énoncé séparément.

## 2. Calculer le regret par rapport au meilleur choix de chaque scénario

Pour chaque colonne, trouvons d’abord la perte la plus faible accessible parmi les stratégies proposées. Les meilleures pertes sont `[3,0,5]`. Le regret d’une stratégie dans cette colonne est sa perte moins cette meilleure perte. Le calcul demande de combien elle est moins bonne que l’option proposée que l’on pourrait choisir en connaissant cette condition.

| Stratégie | Regret, machine limitée | Regret, machine puissante | Regret, machine en contention | Regret maximal |
| --- | --- | --- | --- | --- |
| C | 0 | 6 | 1 | 6 |
| P | 5 | 0 | 9 | 9 |
| A | 1 | 3 | 0 | 3 |

Minimiser le regret maximal sélectionne A dans cette table. Son regret maximal de 3 est une différence en points de perte, pas une probabilité, un temps d’image, une garantie universelle ni une preuve que l’adaptation est préférable. Le critère compare les options déclarées dans l’ensemble de scénarios déclaré.

### Exercice pratique 2 : reconstruire le critère

Calculez le regret de P dans le cas de la machine en contention et les trois regrets maximaux. Quelle stratégie minimise le regret maximal et quelle est l’unité du résultat ?

> **Réponse :** Le regret de P sur la machine en contention est `14-5=9`. Les regrets maximaux sont C 6, P 9 et A 3 ; A est donc sélectionnée. Ces nombres sont des différences entre les points de perte supposés comparables de la table. Ce ne sont ni des millisecondes de rendu mesurées ni des probabilités d’échec.

## 3. Comparer avec une décision explicitement probabiliste

Supposons maintenant les probabilités `[0.1,0.8,0.1]` pour ces trois mêmes colonnes. La perte espérée est la somme pondérée de chaque ligne. C donne 5.7, P donne 2.2 et A donne 3.3 ; minimiser la perte espérée sélectionne P. Des critères et des hypothèses différents peuvent produire des choix différents sans contradiction arithmétique.

Ces probabilités sont posées, pas déduites du rapport historique. Le raisonnement en perte espérée devient utile lorsqu’une distribution est justifiée pour la question posée et que les conséquences sont représentées correctement. Un calcul minimax du regret ne dispense pas de défendre sa propre échelle de perte, son ensemble de scénarios ou son traitement des pires cas.

### Exercice pratique 3 : expliquer le changement de choix

Calculez la perte espérée de P avec les probabilités énoncées. Pourquoi peut-elle faire mieux que A selon la perte espérée tout en faisant moins bien selon le regret maximal ?

> **Réponse :** `0.1*8+0.8*0+0.1*14=2.2`, soit moins que les 3.3 de A. La distribution supposée accorde l’essentiel du poids à la colonne de la machine puissante, favorable à P. Le regret maximal considère plutôt le plus grand écart défavorable au meilleur choix de chaque colonne : P y atteint 9 et A 3. Les choix dépendent d’hypothèses et de critères déclarés différents.

## 4. Trouver la croyance qui fait basculer la comparaison

Notons p la probabilité d’une machine puissante et attribuons à chacune des autres conditions la probabilité `(1-p)/2`. Les pertes espérées deviennent `4.5+1.5*p` pour C, `11-11*p` pour P et `4.5-1.5*p` pour A. Égaliser P et A donne `p=13/19`, soit environ 0.684210526. Au-dessus de cette valeur, P a la perte espérée la plus faible ; en dessous, A a la perte espérée la plus faible dans cette comparaison par paire.

Ce point de croisement rend un désaccord examinable : quel poids faudrait-il accorder au scénario favorable pour faire basculer la décision ? Il n’estime pas ce poids. Lorsque p vaut zéro, C et A ont la même perte espérée ; l’algèbre doit conserver les égalités plutôt qu’inventer un gagnant unique.

### Exercice pratique 4 : calculer le point de croisement

Résolvez `11-11*p=4.5-1.5*p`. Le résultat prouve-t-il que le scénario de la machine puissante se produira avec cette probabilité ?

> **Réponse :** En réarrangeant, on obtient `6.5=9.5*p` ; p vaut donc `13/19`, soit environ 0.684210526. C’est une frontière de décision conditionnelle aux pertes construites et à la répartition des probabilités. Ce n’est ni une prévision, ni une fréquence observée, ni une probabilité a posteriori d’une future condition de la machine hôte.

## 5. Chercher une condition d’échec omise

Ajoutons une colonne où l’adaptateur est indisponible, avec les pertes C 4, P 10 et A 20. Sa meilleure perte est 4 ; ses regrets sont donc C 0, P 6 et A 16. Sur les quatre colonnes, les regrets maximaux deviennent C 6, P 9 et A 16. Le choix minimax du regret passe à C.

L’objection la plus forte au choix initial est donc concrète : la petite table omettait une condition dans laquelle la candidate adaptative ne peut pas remplir son rôle. Cette nouvelle colonne est elle aussi inventée ; elle révèle une vulnérabilité du modèle sans prouver une véritable défaillance d’adaptateur. Une solution plus simple qu’un changement de politique consiste à conserver un réglage fixe tout en recueillant des éléments pertinents dans un périmètre borné.

### Exercice pratique 5 : définir la prochaine investigation

Après l’ajout du quatrième scénario, quelle stratégie minimise le regret maximal ? Énoncez un déclencheur de réexamen de la décision et un résultat qui conduirait à rejeter la candidate adaptative sans prétendre avoir couvert tous les futurs.

> **Réponse :** C est sélectionnée avec un regret maximal de 6, contre P 9 et A 16. Réexaminez la décision lorsque la disponibilité réelle de l’adaptateur, les mesures de charges représentatives ou les objectifs des parties prenantes changent. Rejetez la candidate pour l’usage visé si elle ne peut pas fonctionner dans une condition exigée ou si elle enfreint une limite déclarée de qualité ou de performance de la tâche voisine. Testez directement ces exigences ; cette table finie ne peut pas certifier la robustesse face à tous les futurs.

Le [relevé de scénarios figé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/observatory-decisions-2026-10-22/scenario-decisions.json) conserve les deux tables et leurs calculs exacts. [PHI-004](../../philosophy/phi-004-separate-performance-tradeoffs-from-values/) examine l’origine de ces préférences de perte et de ces contraintes. L’exercice prépare une discussion de décision ; il n’autorise pas le remplacement d’un moteur de rendu et ne prédit pas une date d’arrivée de l’AGI.
