---
title: Références, seuils d'alerte et objectifs historiques
description: Références, seuils d'alerte et objectifs historiques — Visualisation de données
sidebar:
  label: DV-005 · Références, seuils d'alerte et objectifs historiques
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/fr/dv-005-baselines-alerts-and-targets.fr.md
---

:::note[Streeling University]
**DV-005** · Références, seuils d'alerte et objectifs historiques · débutant · 30 minutes

Généré par le département *Visualisation de données* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/fr/dv-005-baselines-alerts-and-targets.fr.md) · [Mon journal](../../journal/)

Prérequis: [DV-001](../../data-visualization/dv-001-observed-degraded-stale-quality/), [DV-004](../../data-visualization/dv-004-uncertainty-in-small-qa-suites/)
:::

> **Département de visualisation des données** | Niveau : débutant | Durée estimée : 30 minutes | Statut : brouillon de traduction ; relecture humaine du fond, relecture linguistique par une personne maîtrisant le français et essai par un apprenant en attente

Données pour les exercices hors ligne : [six instantanés GA figés](https://github.com/spareilleux/learn/blob/main/code/streeling/fixtures/data-visualization/historical-ga/README.md). Ces données sont historiques ; le comportement actuel du service n'est pas évalué.

## Objectifs

À la fin de ce cours, vous saurez :

- reconnaître une mesure de référence, un seuil d'alerte et un objectif d'acceptation sans les traiter comme une même décision ;
- lire le rapport historique de qualité GA sans transformer l'absence d'alerte de régression en affirmation d'amélioration ;
- expliquer pourquoi un indicateur de dérive et un indicateur de régression actuelle peuvent diverger ;
- rédiger une légende de graphique qui conserve la date, la comparaison, la disponibilité des données et les limites.

## La question du projet

Un tableau de bord GA a besoin d'une phrase sur le contrôle qualité du chatbot. Son [rapport historique des tendances de qualité à la révision GA `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/quality/README.md) indique un dernier taux de réussite de **98.08%**, une moyenne sur sept jours de **98.08%**, **aucune régression signalée** et une **dérive** détectée autour du 15 juin 2026. Lequel de ces éléments permet d'affirmer que le chatbot satisfait actuellement un objectif produit ?

Aucun ne le permet à lui seul. Le rapport est un artefact historique généré le 23 juillet 2026 ; sa dernière mesure du contrôle qualité du chatbot vient de l'instantané du 19 juillet. Il ne précise aucun objectif d'acceptation produit, et sa propre ligne de détail contient des observations dégradées. Commencez par [DV-001](../../data-visualization/dv-001-observed-degraded-stale-quality/) pour distinguer les observations réelles des flux dégradés ou périmés, puis par [DV-004](../../data-visualization/dv-004-uncertainty-in-small-qa-suites/) pour la résolution de la suite de contrôle qualité de 52 prompts. N'utilisez pas ce rapport comme état du service aujourd'hui.

### Exercice 1 : nommer les trois rôles

Pour chaque élément, écrivez *référence*, *règle d'alerte* ou *objectif d'acceptation* : (a) la moyenne sur sept jours du rapport, (b) le seuil de régression par défaut de 5.0% du générateur, (c) « Au moins 95% d'une suite de prompts nommée et stable doivent réussir avant la livraison », une règle d'équipe hypothétique. Quel élément est absent du rapport historique ?

> **Réponse :** (a) est une référence mobile, (b) une règle d'alerte qui compare des mesures, et (c) un objectif d'acceptation hypothétique. Le rapport contient (a) et (b), mais aucun objectif produit explicite comme (c). Une équipe devrait approuver et consigner une telle règle séparément, avec sa suite et sa méthode d'évaluation.

## 1. Une référence sert à comparer, sans promettre un résultat

Le fichier GA épinglé [`state/quality/README.md`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/README.md) décrit l'option `--baseline YYYY-MM-DD` du générateur de tendances comme un **repère informatif**. Le rapport rendu contient aussi des moyennes glissantes sur sept jours et sur 30 jours. Ce sont des usages différents du terme « baseline » : une date historique désignée et une référence mobile calculée. Aucun des deux n'est un résultat minimum acceptable.

Le chiffre principal du chatbot donne un dernier taux de 98.08% et une moyenne sur sept jours de 98.08%. Leur écart affiché est nul. Ce calcul explique pourquoi une alerte fondée sur une évolution défavorable par rapport à la moyenne affichée peut ne pas se déclencher. Il ne prouve pas que le jeu de prompts, l'évaluateur ou le backend sont restés fixes, ni que 98.08% suffisent aux utilisateurs. Les fichiers du [15 juin](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) et du [19 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json) indiquent tous deux 52 prompts, mais ne fournissent ni identifiants stables de prompts ni révision de l'évaluateur. Des dénominateurs égaux ne suffisent pas à établir une population appariée ; voir [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/).

### Exercice 2 : lire la ligne sans alerte

Dans la rubrique des régressions, le rapport dit « Aucune. Toutes les métriques suivies restent dans le seuil par rapport à leur moyenne sur 7 jours », tandis que le chiffre principal du chatbot affiche 98.08% pour la dernière valeur et la moyenne sur sept jours. Rédigez l'affirmation la plus solide sur le chatbot et une conclusion non étayée.

> **Réponse :** « Dans le rapport généré le 23 juillet, la dernière mesure du contrôle qualité du chatbot date du 19 juillet ; son taux de réussite affiché est égal à la moyenne sur sept jours affichée, à 98.08%, et aucune régression n'est signalée. » « Le chatbot satisfait maintenant un objectif produit de 98% » n'est pas étayé : le rapport n'a pas cet objectif, l'observation est historique et les instantanés du contrôle qualité n'établissent pas les résultats actuels pour les utilisateurs.

## 2. Une règle d'alerte pose une question plus étroite

Les instructions d'archive épinglées indiquent que `ix-quality-trend` utilise par défaut un seuil de régression de 5.0% par rapport à une moyenne sur sept jours. Le rapport décrit les évolutions défavorables et considère qu'un taux de réussite plus élevé est préférable. La règle d'alerte demande si une évolution mesurée franchit le comparateur et le seuil configurés. Elle ne décide pas si le service entier fonctionne bien, si une version doit être livrée ni pourquoi une métrique a changé. Dans un nouveau rapport, conservez l'unité exacte du seuil et la révision du générateur avant de calculer un cas limite ; « variation relative de 5% » et « cinq points de pourcentage » diffèrent.

Le même rapport indique une dérive du chatbot « depuis le 2026-06-15 », tandis que sa liste actuelle de régressions est vide. Sa méthodologie cite une détection de dérive Page–Hinkley sur des niveaux de métriques ajustés selon leur sens d'évolution. La détection de dérive porte sur une structure ou une rupture dans une série ; la règle de régression porte sur une comparaison de la dernière valeur à une moyenne récente. Ce sont des tests distincts, avec des fenêtres distinctes. Un indicateur historique de dérive ne prouve pas une régression actuelle, et une liste actuelle vide de régressions n'efface pas un changement antérieur de la série enregistrée.

### Exercice 3 : réconcilier deux indicateurs

Un collègue dit : « Le rapport est contradictoire : il signale une dérive du chatbot mais aucune régression. » Corrigez cette phrase sans inventer de cause à la dérive.

> **Réponse :** « Les deux indicateurs répondent à des questions différentes. La règle actuelle de régression n'a trouvé aucune évolution défavorable au-delà de son seuil par rapport à la référence sur sept jours ; le détecteur de dérive a repéré un changement de série autour du 15 juin. Examinez les observations datées sous-jacentes, les enregistrements dégradés et la version du générateur avant d'expliquer ce changement. » Le rapport seul n'identifie pas de changement causal dans les prompts, le modèle ou le code.

## 3. La disponibilité et la couverture limitent les deux comparaisons

Le rapport historique indique 35 fichiers d'instantanés du contrôle qualité du chatbot chargés. Sa ligne de détail du taux global de réussite affiche `n = 26` et `n_degraded = 23`. Ces nombres ont des périmètres différents : « fichiers chargés » couvre la catégorie d'instantanés, tandis que `n` et `n_degraded` décrivent cette série de métriques tracée. Vingt-trois des 26 points de cette ligne portent un marqueur dégradé. Ne lisez pas silencieusement la mini-courbe comme 26 évaluations indépendantes du chatbot réalisées dans de bonnes conditions.

Le rapport marque séparément plusieurs flux d'embeddings et de topologie comme périmés, leur dernière observation réelle datant du 25 juin, soit 28 jours avant le rapport. Une ancienne valeur « la plus récente » peut encore avoir une moyenne et une comparaison au seuil parfaitement mises en forme. Indiquez la fraîcheur au niveau de la métrique. Une observation absente ou dégradée est une lacune dans les éléments disponibles, pas un score d'échec ni une réussite. Un objectif produit exige aussi une population de test convenue, une notation stable, une règle de qualité des exécutions et une plage de dates ; sinon, une vérification de seuil peut sembler décisive tout en répondant à la mauvaise question.

### Exercice 4 : préserver le dénominateur

Que pouvez-vous calculer à partir de `n = 26` et `n_degraded = 23` dans la ligne du chatbot, et que ne pouvez-vous **pas** déduire de ce calcul ? Pourquoi une légende ne doit-elle pas dire « 23 des 35 fichiers du contrôle qualité du chatbot étaient dégradés » ?

> **Réponse :** La ligne contient `26 - 23 = 3` points sans marqueur dégradé, et 23/26 de ses points sont marqués dégradés. Le rapport n'établit pas que les trois points couvrent tous les besoins utilisateurs ni que les 35 fichiers chargés ont tous contribué à cette métrique. « 23 fichiers sur 35 » mélange le nombre de fichiers de la catégorie et le nombre de points d'une série de métriques.

## 4. Inscrire la limite de décision dans le graphique

Dans un tableau de bord de qualité, placez la date d'observation et la population mesurée à côté du chiffre, et identifiez séparément la date de génération du rapport. Présentez la référence mobile comme une comparaison. Étiquetez un seuil comme une configuration d'alerte, et ne mentionnez un objectif d'acceptation que si une décision consignée séparément en définit un. Représentez la dérive par un marqueur différent, avec sa propre explication. Liez une source datée et montrez l'état dégradé ou périmé près des données tracées. Si le corpus exact de prompts ou la révision de l'évaluateur manque, dites-le dans le texte de décision au lieu de le cacher dans une infobulle.

### Exercice 5 : légender le rapport historique

Rédigez une légende de deux phrases qu'une personne chargée d'examiner une livraison pourrait utiliser pour la ligne épinglée du contrôle qualité du chatbot. Incluez la date du rapport du 23 juillet et celle de l'observation du 19 juillet, le taux, le comparateur, l'absence d'alerte, la dérive et la limite principale. Ne recommandez pas la livraison à partir de ce seul artefact.

> **Réponse :** « Le rapport GA généré le 23 juillet 2026 montre la mesure du contrôle qualité du chatbot du 19 juillet à 98.08%, égale à la moyenne sur sept jours affichée ; aucune régression de la dernière valeur par rapport à la moyenne n'est signalée, tandis qu'une dérive est marquée autour du 15 juin. La ligne contient 23 points dégradés parmi 26 points de la série de métriques, et les instantanés sous-jacents n'identifient ni prompts appariés ni versions d'évaluateur ; ce rapport seul ne permet donc pas d'établir un objectif produit actuel ni une décision de livraison. »

## À retenir

- Un repère historique, une moyenne mobile, un seuil d'alerte et un objectif de livraison servent des décisions différentes.
- « Aucune régression signalée » signifie qu'une règle d'alerte précise ne s'est pas déclenchée ; ce n'est pas un verdict général de qualité.
- La dérive et la régression de la dernière valeur par rapport à la moyenne peuvent légitimement diverger.
- Gardez visibles les nombres de points des séries de métriques, les nombres de fichiers des catégories, la fraîcheur et l'état dégradé.
- Un objectif produit exige sa propre population convenue, sa règle de notation, sa fenêtre de dates et une personne responsable de la décision.

## Éléments du projet

- GA : [rapport de qualité](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/quality/README.md), [instructions d'archive](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/README.md) et instantanés du [15 juin](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) / [19 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json), tous épinglés.
- Le seuil de 5.0% est un réglage d'alerte du générateur décrit par les instructions d'archive épinglées, et non un objectif documenté de livraison GA. Le rapport n'épingle pas la révision exacte du générateur IX ; vérifiez-la avant d'expliquer un calcul d'alerte à la limite du seuil.

*Recherche : `data-visualization-2026-10-11-005`. Brouillon de traduction ; relecture humaine du fond, essai par un apprenant, relecture linguistique par une personne maîtrisant le français et vérification de la version publique Learn en attente.*
