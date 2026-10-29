---
module_id: dv-006-position-length-area-comparisons
department: data-visualization
course: Position, longueur, aire et tâche de comparaison
level: beginner
prerequisites: [dv-002-denominators-and-test-populations, dv-003-instrument-cohorts-and-units]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: data-visualization-2026-10-11-006
version: "0.1.0"
---

# Position, longueur, aire et tâche de comparaison

> **Département de visualisation des données** | Niveau : débutant | Durée estimée : 30 minutes | Statut : brouillon de traduction ; relecture humaine du fond, relecture linguistique par une personne maîtrisant le français, essai par un apprenant et examen avant publication en attente

Données pour les exercices hors ligne : [six instantanés GA figés](../../../../code/streeling/fixtures/data-visualization/historical-ga/README.md). Ces données sont historiques ; le comportement actuel du service n'est pas évalué.

## Objectifs

À la fin de ce cours, vous saurez :

- nommer la comparaison et l'unité avant de choisir une représentation visuelle ;
- utiliser une échelle de position partagée ou une longueur d'origine commune pour des comparaisons quantitatives ;
- expliquer pourquoi l'**aire** d'un cercle, et non son rayon, doit représenter un effectif si l'on utilise des cercles ;
- garder visibles les dates historiques, les dénominateurs et les limites de comparabilité près d'un graphique.

## La question du projet

GA possède trois instantanés historiques au commit épinglé [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924). L'[instantané d'analyse des voicings du 23 juillet 2026](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/voicing-analysis/2026-07-23.json) compte **297,910 voicings de guitare**, **7,795 de basse** et **7,342 d'ukulélé**, pour un total de **313,047**. Les instantanés du contrôle qualité du chatbot du [15 juin](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) et du [19 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json) indiquent **75% sur 52 prompts** et **98.08% sur 52 prompts**. Les tâches de comparaison sont différentes : comparer les *effectifs entre instruments* et comparer les *taux publiés entre dates*. Une même collection de cercles ferait apparaître les deux comme « plus grand contre plus petit » en masquant leurs unités.

Déterminez ce que le lecteur doit juger. Pour le corpus de voicings, la question est : « Quelle est la taille de chaque cohorte d'instrument, et à quel point celles de basse et d'ukulélé sont-elles plus petites que celle de guitare ? » Pour le contrôle qualité, la question est : « Quel taux publié correspond à chaque date ? » Les fichiers du contrôle qualité n'identifient ni les prompts individuels ni les révisions de l'évaluateur ; l'écart de taux ne peut donc pas établir une amélioration sur un jeu de tests apparié. Aucun des enregistrements ne décrit le service ou l'expérience utilisateur actuels.

### Exercice 1 : nommer la tâche

Un concepteur propose un seul graphique à bulles avec cinq bulles : trois effectifs d'instruments et deux pourcentages du contrôle qualité. Nommez deux problèmes, puis rédigez les deux questions de comparaison avec leurs unités.

> **Réponse :** Les bulles mélangent des nombres de voicings et des pourcentages, qui ont des unités différentes ; l'aire des cercles rend aussi les comparaisons fines plus difficiles à lire qu'une échelle numérique partagée. Comparez les **voicings par instrument** pour la guitare, la basse et l'ukulélé dans l'audit du 23 juillet. Comparez séparément le **pourcentage publié de réussite sur 52 prompts du contrôle qualité** les 15 juin et 19 juillet. Cette seconde comparaison est descriptive et datée ; elle n'affirme pas une amélioration sur des prompts appariés.

## 1. La position sur une échelle partagée

Pour des valeurs proches, placez les marques à leur position numérique sur une même échelle étiquetée. Un diagramme à points des deux taux du contrôle qualité peut placer les points à 75 et 98.08 sur un axe de 0–100%. La distance horizontale représente **23.08 points de pourcentage**. Si une vue détaillée commence à 70%, indiquez clairement cet axe et la plage omise ; un zoom sur l'échelle de position peut aider à examiner l'écart, mais il ne doit pas transformer les valeurs en longueurs de barres mesurées depuis 70.

Affichez `15 juin : 75% (52 prompts)` et `19 juillet : 98.08% (52 prompts)` comme libellés directs. Le dénominateur inchangé ne prouve pas que les questions sont inchangées. [DV-002](dv-002-denominators-and-test-populations.md) détaille les éléments manquants pour établir des populations appariées. Ne tracez pas entre les deux points une flèche « qualité améliorée » sans réserve.

### Exercice 2 : lire l'axe

Un diagramme à points du contrôle qualité place 75 et 98.08 sur un même axe de pourcentages. Calculez leur différence en points de pourcentage. Que devrait préciser la légende d'un axe détaillé de 70–100%, et quelle conclusion resterait inaccessible ?

> **Réponse :** `98.08 - 75 = 23.08` points de pourcentage. La légende doit préciser que l'axe de position affiché commence à 70% et montrer les deux valeurs et les dates ; sinon, la distance visuelle peut être prise pour une plage complète de 0–100%. Les enregistrements n'établissent pas que les mêmes prompts et le même évaluateur ont produit les deux taux ; une conclusion d'amélioration sur des tests appariés reste donc inaccessible.

## 2. La longueur depuis une origine commune

Quand le lecteur doit comparer les effectifs des cohortes, des barres horizontales peuvent représenter les nombres par leur longueur. Faites partir chaque barre de **zéro**, utilisez une seule échelle linéaire et imprimez le nombre exact à son extrémité. Dans une mise en page où la barre de guitare fait 100 unités de long, celle de basse devrait mesurer environ **2.62** unités et celle d'ukulélé environ **2.46** unités. Ces petites longueurs reflètent fidèlement le déséquilibre du corpus ; ce n'est pas un défaut de mise en page. Fournissez un tableau ou un agrandissement des deux petits groupes si le lecteur doit aussi distinguer 7,795 de 7,342 ; conservez la vue d'ensemble d'origine et indiquez clairement l'échelle de tout agrandissement.

La guitare a environ **38.22 fois** plus de voicings audités que la basse (`297,910 / 7,795`). Une barre tronquée à 7,000 ne représenterait la basse que par 795 unités visibles et l'ukulélé par 342, amplifiant faussement leur différence. Si un graphique partant de zéro devient peu pratique, utilisez un diagramme à points étiqueté ou des panneaux séparés de vue d'ensemble et de détail au lieu de masquer l'origine. [DV-003](dv-003-instrument-cohorts-and-units.md) explique pourquoi ces effectifs de corpus ne mesurent pas l'exactitude musicale par instrument.

### Exercice 3 : vérifier la géométrie des barres

Si la barre de 297,910 voicings de guitare mesure 100 unités, calculez les longueurs des barres de basse et d'ukulélé à deux décimales. Le graphique devrait-il raccourcir les deux barres en soustrayant 7,000 avant de les tracer ?

> **Réponse :** La basse mesure `100 × 7,795 / 297,910 = 2.62` unités ; l'ukulélé, `100 × 7,342 / 297,910 = 2.46` unités. Non. Soustraire 7,000 des longueurs changerait ce que représentent les barres. Conservez des longueurs partant de zéro et des libellés exacts ; utilisez une vue détaillée explicitement étiquetée si la tâche porte sur l'écart de 453 voicings entre basse et ukulélé.

## 3. L'aire est une autre représentation

Les cercles peuvent représenter des effectifs lorsque leurs **aires** sont proportionnelles aux valeurs. L'aire d'un cercle vaut `π × radius²`. Pour les effectifs de guitare et de basse, le rapport d'aires souhaité est `297,910 / 7,795 ≈ 38.22` ; leur rapport de rayons doit donc être `√38.22 ≈ 6.18`. Si l'on donne au cercle de guitare un rayon 38.22 fois plus grand que celui de basse, son aire devient environ **1,460.77 fois** celle de basse (`38.22² = 1460.7684`). Cette géométrie exagère fortement le rapport des effectifs enregistrés.

Même correctement dimensionnés, les cercles demandent plus d'estimation mentale que des marques sur une échelle partagée. Réservez-les aux tâches où un ordre de grandeur ou un placement spatial est utile, gardez les nombres exacts à proximité et fournissez un tableau accessible. Évitez de dimensionner des cercles à partir des pourcentages du contrôle qualité à côté d'effectifs de voicings : un rapport d'aires entre unités différentes n'a pas d'interprétation utile.

### Exercice 4 : tester les bulles

Un brouillon donne aux **rayons** des cercles de guitare et de basse le rapport 38.22:1 et étiquette le résultat « 38.22 fois plus de voicings ». Quel rapport d'aires les lecteurs verraient-ils ? Quel rapport de rayons préserverait le rapport des effectifs ?

> **Réponse :** L'aire croît avec le carré du rayon, donc `38.22² ≈ 1,461:1` (environ 1,460.62 avec le rapport non arrondi des effectifs). Pour montrer environ 38.22:1 par l'aire, utilisez un rapport de rayons de `√38.22 ≈ 6.18:1`. Un diagramme en barres sur une échelle commune est plus facile à auditer pour cette comparaison précise de cohortes.

## 4. Examiner la comparaison, puis l'affirmation

Un panneau GA compact peut montrer trois barres d'effectifs partant de zéro avec des libellés exacts, une vue séparée du contrôle qualité à deux points datés et un petit tableau des sources. Placez **voicings** près de la première échelle et **pourcentage sur 52 prompts** près de la seconde. Précisez que toutes les valeurs viennent d'instantanés historiques à la révision épinglée. Le nombre de voicings est l'effectif d'un corpus audité, et non une population d'utilisateurs ; les taux du contrôle qualité résument des exécutions dont l'appariement des prompts et de l'évaluateur n'est pas vérifié. Le panneau doit relier chaque nombre à sa source et rester lisible sans couleur.

Avant d'approuver un graphique, posez ces questions : les valeurs ont-elles la même unité ? La géométrie visuelle est-elle proportionnelle à la quantité visée ? L'échelle convient-elle à la tâche de comparaison ? La légende indique-t-elle les dates d'observation et la limite des éléments disponibles ? Un graphique visuellement clair peut encore appuyer une affirmation fausse si sa légende confond part du corpus, qualité des noms et taux de réussite du contrôle qualité.

### Exercice 5 : corriger une légende de tableau de bord

Examinez cette phrase : « La qualité GA est passée de 75% à 98.08% ; la guitare est 38 fois meilleure que la basse, comme le montre la grande bulle. » Remplacez-la par une légende de deux phrases qui conserve les deux tâches, les dates, les dénominateurs et les limites principales.

> **Réponse :** « À la révision GA `dc2e74c`, l'audit des voicings du 23 juillet 2026 a compté 297,910 voicings de guitare, 7,795 de basse et 7,342 d'ukulélé ; ce sont des effectifs de corpus, et non des scores de qualité des instruments. Des instantanés séparés du contrôle qualité du chatbot ont publié 75% sur 52 prompts le 15 juin et 98.08% sur 52 le 19 juillet, mais les fichiers n'établissent ni l'appariement des identités des prompts ni les révisions de l'évaluateur ; la différence est donc descriptive et non une amélioration vérifiée. »

## À retenir

- Choisissez la représentation selon la tâche de comparaison et l'unité : position partagée pour des taux précis, longueur d'origine commune pour les effectifs, aire seulement si un ordre de grandeur convient à la tâche.
- La longueur d'une barre exige un zéro commun ; la position d'un point peut utiliser une échelle détaillée explicitement étiquetée.
- Pour les cercles, une valeur proportionnelle à l'**aire** implique un rayon proportionnel à la racine carrée de la valeur.
- Affichez les dates, effectifs, dénominateurs et liens sources pour que la comparaison visible n'exagère pas la portée des éléments disponibles.

## Éléments du projet et limites

- Les instantanés GA épinglés de l'[audit des voicings du 23 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/voicing-analysis/2026-07-23.json), du [contrôle qualité du 15 juin](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) et du [contrôle qualité du 19 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json) fournissent les valeurs des exemples. Les exemples de longueurs et de rayons sont des calculs pédagogiques à partir de ces champs, et non des mesures produites par GA.
- Les instantanés n'établissent ni des utilisateurs représentatifs, ni une qualité des voicings relue indépendamment, ni des prompts du contrôle qualité appariés, ni la révision de l'évaluateur. Ce cours n'a pas fait l'objet d'une relecture humaine du fond, d'un essai par un apprenant, d'une relecture linguistique ou d'une vérification de la version publique Learn.

*Recherche : `data-visualization-2026-10-11-006`. Brouillon de traduction uniquement ; relecture et publication en attente.*
