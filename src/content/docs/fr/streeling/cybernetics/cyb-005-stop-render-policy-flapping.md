---
title: Éviter les oscillations d’une politique de rendu
description: Éviter les oscillations d’une politique de rendu — Cybernétique
sidebar:
  label: CYB-005 · Éviter les oscillations d’une politique de rendu
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-005-stop-render-policy-flapping.fr.md
---

:::note[Streeling University]
**CYB-005** · Éviter les oscillations d’une politique de rendu · intermédiaire · 40 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-005-stop-render-policy-flapping.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-004](../../cybernetics/cyb-004-observe-before-correcting-a-feedback-loop/)
:::

> **Périmètre du brouillon.** Inspection du code source à une révision précise et traces d’observations et de décisions construites pour le cours. La revue technique humaine, la révision linguistique par une personne maîtrisant la langue, les essais apprenants, les résultats d’une régulation en fonctionnement et la vérification du HTML déployé restent à faire. Aucune expérience sur un moteur de rendu ou un GPU n’a été menée pour cette leçon.

## La question du projet

Un agent de l’Observatoire réduit le niveau de détail après une image lente, le relève après une image plus rapide, puis le réduit à nouveau. Ses interventions répétées peuvent contribuer à la perturbation. Trois mécanismes distincts permettent d’analyser ce comportement : **l’hystérésis** sépare les seuils d’entrée et de sortie ; **la persistance** exige plusieurs observations admissibles successives ; **le temps de maintien** limite la fréquence des changements. Ils répondent à des questions différentes et peuvent retarder une correction utile.

Le [prototype BRUTAL public](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) fournit un cas concret. Son [bloc de régulation adaptative](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L2916-L2936) ajuste le nombre de rebonds du path tracing. Nous inspectons le code immuable du commit GA `76efbffd5af82b46c3146957a6bd4504008eeb89` ; cela n’atteste ni l’état actuel de la copie de travail modifiée ni celui d’un binaire en cours d’exécution.

## 1. Lire précisément le contrôleur existant

Le code initialise le nombre de rebonds à trois et le temps GPU lissé à zéro. Les requêtes de mesure réussies mettent à jour cette valeur lissée avec un facteur de 0.05. Lorsqu’une variante de shader `--pt` est configurée (`pt.Length > 0`) et que le temps écoulé depuis le dernier changement est **strictement supérieur à une seconde**, le contrôleur retire un rebond si le temps GPU lissé dépasse son budget et si le nombre de rebonds est supérieur à un. Il ajoute un rebond en dessous de 65 pour cent du budget lorsque ce nombre est inférieur à trois. Le budget par défaut est de 16 ms, ce qui donne un seuil de remontée de 10.4 ms.

La variante est configurée à partir de vérifications des capacités et des arguments. Une bascule distincte à l’exécution, `rtxOn`, agit sur le paramètre envoyé au rendu. Ce bloc adaptatif ne vérifie pas cette bascule. Sa garde de configuration n’atteste donc pas qu’un rendu par path tracing est effectivement actif lorsqu’une décision est prise.

Une requête qui échoue ou ne fournit pas de mesure fait sauter ce bloc de mise à jour. Dans ce bloc, la valeur lissée mémorisée, le nombre de rebonds et l’instant du dernier changement restent inchangés ; l’horloge continue d’avancer. Le bloc inspecté ne vérifie pas explicitement qu’un temps GPU renvoyé avec succès est fini et non négatif. La réussite de l’appel API, la disponibilité d’une observation et sa validité numérique ne sont pas des garanties identiques.

### Exercice pratique 1 : appliquer la garde stricte du code source

Supposons une requête réussie, une variante `--pt` configurée, un temps lissé de 17 ms, un budget de 16 ms et trois rebonds. Le dernier changement a eu lieu à l’instant 1. Que se passe-t-il à l’instant 2, puis à l’instant 2.001 si les autres entrées restent inchangées ? La garde adaptative exige-t-elle aussi la bascule à l’exécution ?

> **Réponse :** À l’instant 2, l’intervalle écoulé est égal à une seconde ; la garde stricte n’autorise donc aucun changement. À l’instant 2.001, il dépasse une seconde ; le nombre de rebonds passe donc de trois à deux. La garde vérifie la variante configurée, pas la bascule distincte à l’exécution. Il s’agit d’appliquer arithmétiquement les conditions inspectées, pas d’exécuter le moteur de rendu.

## 2. Distinguer une bande neutre d’une réponse retardée

La [documentation officielle du bloc Relay de MathWorks](https://www.mathworks.com/help/simulink/slref/relay.html) décrit la conservation de l’état entre deux seuils de commutation distincts. Notre exemple pédagogique original utilise deux réglages : le niveau de détail élevé vaut 1 et le niveau réduit vaut 0. Il réduit le détail strictement au-dessus de 16 ms et le relève strictement en dessous de 10.4 ms. Dans cette bande, y compris aux valeurs exactes des seuils, il conserve son état courant.

Cet exemple diffère du contrôleur du code source : il utilise deux réglages, aucun lissage exponentiel, deux observations valides successives remplissant la condition et un temps de maintien minimal de trois secondes. Ces choix pédagogiques sont indicatifs ; ce ne sont ni une politique installée ni des seuils validés en production. Une observation dans la bande neutre remet à zéro la série candidate. Une série admissible est conservée lorsque le temps de maintien bloque le changement ; un changement réussi la remet à zéro.

### Exercice pratique 2 : utiliser la mémoire de l’hystérésis

Le contrôleur pédagogique est actuellement au niveau réduit. L’observation suivante vaut 14 ms. Doit-il relever le détail ? Une règle sans mémoire qui choisit le niveau élevé dès que le temps est inférieur ou égal à 16 ms prendrait-elle la même décision ?

> **Réponse :** La règle à hystérésis conserve le niveau réduit : 14 ms n’est pas inférieur à son seuil de remontée de 10.4 ms. La règle sans mémoire choisit le niveau élevé, car 14 ms est inférieur ou égal à 16 ms. Le sens de la bande neutre dépend de l’état courant ; elle ne constitue ni un troisième niveau de détail ni la preuve que le système fonctionne correctement.

## 3. Suivre séparément la persistance et le maintien

Les observations construites pour les secondes entières allant de 1 à 17 sont `[15,17,15,17,15,14,17,17,14,10,10,14,17,17,10,10,10]` ms. L’état initial est élevé et l’instant initial du dernier changement est zéro. Ce sont des entrées synthétiques en boucle ouverte : elles ne réagissent pas aux actions de la politique.

La règle sans mémoire change aux secondes `[2,3,4,5,7,9,13,15]`, soit huit fois. La politique pédagogique change aux secondes `[8,11,14,17]`, soit quatre fois. À la seconde 16, deux observations permettant la remontée se sont accumulées, mais seules deux secondes se sont écoulées depuis le changement à 14. À la seconde 17, la série admissible est toujours présente et la condition de maintien de trois secondes est satisfaite.

![Observations construites du temps GPU et traces des deux réglages](https://raw.githubusercontent.com/spareilleux/learn/218a2bffc18fe2251956197e882cb6c7ea5d7962/code/streeling/evidence/observatory-decisions-2026-10-22/control-state-traces.png)

Le graphique supérieur présente les observations construites et les seuils. Dans le graphique inférieur, `q_N` désigne la règle sans mémoire et `q_H` la politique pédagogique ; 1 signifie un niveau de détail élevé et 0 un niveau réduit. Ce sont des traces de décisions, pas une amélioration mesurée de la régularité des images ou de leur qualité.

### Exercice pratique 3 : trouver la garde qui bloque un changement

Donnez le nombre de changements de chaque règle. Pourquoi la politique pédagogique relève-t-elle le détail à la seconde 17 plutôt qu’à la seconde 16 ? Cette action plus tardive vient-elle d’une série d’observations de remontée trop courte ?

> **Réponse :** Les nombres de changements sont huit et quatre. À la seconde 16, la série de remontée atteint déjà deux observations, mais le maintien n’a duré que deux secondes. À la seconde 17, le maintien atteint trois secondes et la série qui se poursuit autorise la remontée. C’est le temps de maintien, et non une persistance insuffisante, qui bloque le changement précédent.

## 4. Compter les observations avant de les convertir en temps

Pour la récurrence exponentielle analogue à celle du code source, supposons que chaque observation construite et obtenue avec succès vaille 20 ms et que la valeur lissée initiale soit zéro. Après n mises à jour, cette valeur est `20*(1-0.95^n)`. Elle dépasse pour la première fois 16 ms à la mise à jour 32. Cela porte sur un nombre de mises à jour, pas sur un délai de démarrage mesuré de 32 images ou de 32 secondes. La cadence des requêtes, la garde temporelle et les autres conditions comptent toujours.

Le code source choisit aussi sa base de temps : l’enregistrement utilise `frame/60.0`, tandis que le fonctionnement ordinaire utilise les secondes écoulées à l’horloge. Pendant l’enregistrement, une garde temporelle peut donc se référer à une chronologie virtuelle d’images. Décrire un contrôleur sans préciser sa base de temps peut masquer une limite de fréquence différente de celle qu’imagine le lecteur.

### Exercice pratique 4 : interpréter le retard du lissage

Le franchissement du seuil à la mise à jour 32 détermine-t-il l’instant du premier changement de rebonds dans le code source ? Nommez les conditions supplémentaires et distinguez le temps d’enregistrement du temps réel écoulé.

> **Réponse :** Non. La récurrence établit uniquement un franchissement de seuil pour le lissage construit. Un changement dans le code source exige aussi une requête réussie, une variante configurée, un nombre de rebonds pouvant changer et un temps écoulé strictement supérieur à une seconde. Il faut connaître la cadence des mises à jour pour les convertir en temps. L’enregistrement utilise la chronologie des images divisée par 60 ; le fonctionnement ordinaire utilise le temps écoulé à l’horloge.

## 5. Tester la réactivité autant que le nombre de changements

Pour la trace pédagogique `[17,null,17,17]`, l’observation manquante remet la persistance à zéro ; le passage au niveau réduit se produit donc à la seconde 4. Cette même politique construite traite les entrées égales à zéro, négatives ou non finies comme invalides, conserve l’état et remet sa série à zéro. Cette règle explicite ne signifie pas que le code source inspecté effectue ces vérifications numériques.

Un contrôleur qui ne change jamais présente zéro commutation, mais ne respecte pas l’exigence construite de réagir à une entrée dépassant durablement le budget. Réduire le nombre d’interventions est donc un objectif incomplet. L’objection la plus forte à la persistance et au maintien est le retard de réponse à une véritable surcharge. Un réglage fixe plus simple peut suffire si l’adaptation ajoute de la complexité sans améliorer la tâche réelle.

### Exercice pratique 5 : formuler une prochaine étape réfutable

Un agent affirme : « quatre changements au lieu de huit prouvent une meilleure régulation ». Utilisez les contrôles avec données manquantes et sans action pour corriger cette conclusion, puis précisez un test qui pourrait conduire à rejeter la politique proposée.

> **Réponse :** La trace construite montre moins de décisions selon une règle ; elle ne mesure aucune réponse du système piloté. Les données manquantes doivent remettre à zéro la série prévue par cette règle, tandis qu’une règle sans action montre pourquoi le seul nombre de changements ne suffit pas. Une comparaison réelle et bornée devrait mesurer le délai de réponse, les performances de la tâche voisine et la qualité visuelle dans des conditions déclarées. Rejetez le déploiement si ces résultats sortent des limites annoncées, même si les changements diminuent. Aucune comparaison de ce type n’a eu lieu ici.

Le [relevé de contrôle figé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/observatory-decisions-2026-10-22/control-traces.json) et le [relevé des limites du code source](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/observatory-decisions-2026-10-22/source-controller.json) étayent les exercices. [FUT-004](../../futurology/fut-004-scenario-test-an-observatory-renderer/) étudie l’évolution des choix de politique selon les futurs supposés ; [PHI-004](../../philosophy/phi-004-separate-performance-tradeoffs-from-values/) examine les valeurs implicites d’un objectif de performance.
