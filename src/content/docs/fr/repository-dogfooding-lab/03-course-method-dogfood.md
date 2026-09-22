---
title: Dogfooder la méthode de cours
description: Traiter écriture, vérification et journaux multilingues comme un système d'ingénierie mesurable.
sidebar:
  order: 3
---

Un cours peut enseigner de bonnes pratiques tout en étant produit par un mauvais processus. Nous évaluons donc notre propre méthode.

1. **Exemples exécutables :** toute sortie affirmée vient du code ou est marquée non testée.
2. **Preuves du journal :** hypothèse, baseline, résultat, verdict et artefact restent distincts.
3. **Parité des langues :** EN, FR et ES partagent fichiers et liens; l'automatisation vérifie la structure, l'humain le sens.
4. **Retour d'adoption :** le journal suit rejet, incubation et intégration au-delà de la publication.
5. **Efficacité agentique :** coût par résultat accepté, pas activité ni tokens seuls.

Un cours est publiable lorsque les faits instables ont des sources officielles, les commandes sont reproduites, l'inconnu est explicite, les mesures pointent vers des preuves, les traductions reflètent la source et les recommandations restent des hypothèses avant test dans le dépôt.

L'automatisation prouve parité de fichiers, liens, fraîcheur des matrices et tests. Elle ne prouve ni une traduction idiomatique ni la sagesse d'une architecture.

<details>
<summary>Exercice : rendre la matrice volontairement périmée</summary>

Modifiez un score sans régénérer `matrices.md`, puis exécutez `python dogfood.py check`. La commande doit échouer. Régénérez avec `python dogfood.py write` et relancez les tests.

</details>
