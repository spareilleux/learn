---
module_id: aud-014-budget-headroom-for-correlated-plucks
department: audio-engineering
course: "Prévoir la marge pour des attaques corrélées"
level: intermediate
prerequisites: ["aud-010-preserve-channels-before-downmixing"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Prévoir la marge pour des attaques corrélées

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un guitariste peut demander à GA un accord dont les voix sonnent ensemble. Des échantillons valides séparément ne garantissent pas que leur somme reste dans la plage normalisée. Un raccourci consiste à prévoir la marge comme si les voix étaient des bruits indépendants. Des attaques communes, une excitation copiée ou un unisson peuvent au contraire s’aligner. De petits tampons signés permettent ici d’inspecter chaque addition et de distinguer un problème de mixage interne de l’écrêtage final.

## Lire les preuves conservées

Lire le contrôle des échantillons normalisés et la conversion WAV entière du programme conservé. Ils indiquent la frontière vérifiée, sans prouver que les voix internes ne l’ont jamais dépassée. OpenStax présente la superposition comme l’addition des déplacements, avec renforcement ou annulation selon la phase relative. Nos tableaux appliquent cette addition comme modèle construit, sans mesurer les phases d’une guitare.

[Prérequis](../../audio-engineering/en/aud-010-preserve-channels-before-downmixing.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://openstax.org/books/university-physics-volume-1/pages/16-5-interference-of-waves)

### Exercice 1

Les deux tampons d’entrée valent `[0.8,-0.8,0.4]`, chacun avec une crête de `0.8`. Additionner les indices correspondants donne `[1.6,-1.6,0.8]`. Des signes opposés au sein d’une forme d’onde n’aident pas lorsque l’autre source reproduit ces mêmes signes aux mêmes instants. La crête absolue inclut aussi les excursions négatives.

Quelle est la somme brute et sa crête ?

<details><summary>Réponse 1</summary>

La somme est `[1.6,-1.6,0.8]`, avec une crête absolue de `1.6`. Chaque source respectait la limite, mais leur somme corrélée dépasse `1`.

</details>

### Exercice 2

Appliquer le gain déclaré `0.5` à la somme brute avant la limitation finale. On retrouve `[0.8,-0.8,0.4]`, avec une crête de `0.8`. Cette opération échange de l’amplitude contre de la marge. Elle ne sépare pas les voix musicales additionnées et ne constitue pas automatiquement une égalisation de sonie.

Quel gain est employé et quel tampon atteint la sortie ?

<details><summary>Réponse 2</summary>

Le gain `0.5` donne `[0.8,-0.8,0.4]`, avec une crête de `0.8`. C’est une préparation explicite, pas une preuve de sonie perçue identique.

</details>

### Exercice 3

Inverser maintenant l’ordre. Écrêter la somme dans `[-1,1]` produit `[1,-1,0.8]`. Multiplier ensuite par `0.5` donne `[0.5,-0.5,0.4]`, différent du mixage non écrêté. Réduire le gain après coup ne reconstruit pas les valeurs aplaties. Conserver une observation interne pour diagnostiquer cette frontière.

Pourquoi écrêter puis réduire le gain constitue-t-il une autre transformation ?

<details><summary>Réponse 3</summary>

Le tableau écrêté est `[1,-1,0.8]`, puis devient `[0.5,-0.5,0.4]`. Les extrêmes initiaux sont perdus ; une petite crête finale ne prouve pas l’absence de distorsion interne.

</details>

### Exercice 4

Pour le contrôle négatif, remplacer le second tampon par `[-0.8,0.8,-0.4]` en gardant le gain `0.5`. Les sommes brute et réduite valent `[0,0,0]`. Aucune source n’est pourtant silencieuse. La relation de phase appartient donc aux entrées ; un gain justifié uniquement par ce cas d’annulation serait fragile.

Que montre ce contrôle sur une estimation universelle de la marge ?

<details><summary>Réponse 4</summary>

Sa crête vaut `0` malgré des entrées non nulles. Annulation et renforcement corrélé donnent des crêtes différentes ; aucun cas seul ne fournit une estimation indépendante des sources.

</details>

### Exercice 5

Un essai d’accord devrait inclure attaques alignées, unissons et signaux volontairement opposés avant de revendiquer une marge générale. Garder visibles la somme brute, la place du gain et la règle d’écrêtage. Un limiteur ajoute une transformation non linéaire qui exige ses propres preuves. Ces tableaux finis n’établissent aucune préférence d’écoute.

Quelle observation réfuterait l’affirmation que tous les états intermédiaires respectaient la plage ?

<details><summary>Réponse 5</summary>

Un échantillon conservé avant écrêtage dont l’amplitude dépasse `1` la réfute. Un WAV final valide ne suffit pas : l’écrêtage peut avoir masqué l’excursion.

</details>

## Tâche avec consultation des sources

Préparer une note de marge pour un rendu Wasm polyphonique proposé. Calculer manuellement somme principale, gain avant écrêtage et contrôle d’annulation. Localiser les contrôles du programme et préciser la frontière interne non observée. Proposer une observation réelle distinguant une atténuation propre d’un signal écrêté puis atténué, sans trancher la qualité d’écoute ni le comportement en production.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
