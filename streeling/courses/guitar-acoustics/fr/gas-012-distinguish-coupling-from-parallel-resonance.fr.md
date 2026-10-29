---
module_id: gas-012-distinguish-coupling-from-parallel-resonance
department: guitar-acoustics
course: "Distinguer le couplage de résonances en parallèle"
level: intermediate
prerequisites: ["gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer le couplage de résonances en parallèle

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Une résonance évoquant la caisse dans un rendu ne montre pas à elle seule que l’énergie peut revenir de la caisse vers une corde. Cette distinction compte lorsqu’une future leçon ou commande GA promet une réponse sympathique. Nous construisons un analogue mécanique symétrique dont les équations contiennent un couplage explicite. La séparation de ses modes est calculable indépendamment. L’analogue explique la relation requise entre coordonnées, sans prétendre qu’un moteur existant l’implémente ou reproduit une guitare acoustique.

## Lire les preuves conservées

Lire les déclarations Rust conservées pour la voix et le résonateur de caisse, puis la récurrence du résonateur pilotée par son entrée. Elles établissent certains états et une expression de calcul, pas un couplage réciproque sur tous les chemins de rendu. La source UNSW présente les modes comme des façons possibles de vibrer. Nous utilisons ce concept pour notre propre modèle ; aucune page sur les cordes sympathiques n’a été lue avec succès.

[Prérequis](../../guitar-acoustics/en/gas-007-distinguish-body-poles-from-string-partials.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.phys.unsw.edu.au/jw/strings.html)

### Exercice 1

Chaque masse vaut `1 kg`, chaque raideur d’ancrage `100 N/m` et la raideur de liaison `150 N/m`. Avec les déplacements `x1` et `x2`, la première équation est `m*x1''=-k*x1-kc*(x1-x2)` ; l’autre échange les coordonnées. La force de liaison dépend de leur différence : donner deux fréquences séparées ne définirait pas ce modèle.

Quelle relation physique rend le modèle couplé ?

<details><summary>Réponse 1</summary>

La force sur chaque masse comprend l’autre déplacement via `kc*(x1-x2)`. Les deux directions interviennent ; une simple somme en aval n’exprime pas cette relation.

</details>

### Exercice 2

Quand `x1=x2`, le ressort de liaison ne s’allonge pas. La pulsation vaut `sqrt(k/m)=10 rad/s`, soit `10/(2*pi) Hz`. Distinguer pulsation et fréquence évite une erreur de facteur. Le résultat découle de la symétrie et des paramètres construits, sans identifier le mode grave d’une guitare réelle.

Quel est le mode dans le même sens et pourquoi le couplage ne le rehausse-t-il pas ?

<details><summary>Réponse 2</summary>

Sa pulsation vaut `10 rad/s`, soit `10/(2*pi) Hz`. Les déplacements égaux ne déforment pas la liaison ; seule la raideur d’ancrage intervient.

</details>

### Exercice 3

Quand `x1=-x2`, la liaison s’allonge du double de chaque déplacement. La raideur effective est `k+2*kc`, d’où `sqrt((k+2*kc)/m)=20 rad/s`, soit `20/(2*pi) Hz`. Ce mode distingue le couplage réciproque de deux oscillateurs identiques indépendants. La séparation dépend de la symétrie ; des masses inégales demanderaient un autre calcul.

Calculer le mode opposé et identifier la raideur ajoutée.

<details><summary>Réponse 3</summary>

Il vaut `20 rad/s`, soit `20/(2*pi) Hz`. Le terme ajouté est `2*kc`, car les déplacements opposés changent la longueur de liaison du double d’une coordonnée.

</details>

### Exercice 4

Le contrôle négatif fixe la liaison à `0 N/m` en gardant masses et ancrages. Les deux modes deviennent `10 rad/s`. Chaque oscillateur peut toujours vibrer autour de son ancrage, mais la séparation disparaît. Cela réfute une explication fondée seulement sur la raideur d’ancrage inchangée ou sur la présence de deux coordonnées.

Un couplage nul implique-t-il le silence ?

<details><summary>Réponse 4</summary>

Non. Les deux modes valent `10 rad/s` ; des vibrations indépendantes restent possibles. Le contrôle retire la séparation liée au couplage, pas tout mouvement ni toute source sonore.

</details>

### Exercice 5

Une revue doit retrouver la variable renvoyée d’un composant vibrant à l’autre avant d’affirmer un échange sympathique. Un filtre de caisse piloté par le mélange des cordes peut colorer la sortie sans fournir ce retour. Inversement, un extrait ne prouve pas une absence dans tout le dépôt. Conserver chemin de rendu et conditions initiales, puis demander une intervention réelle pour toute affirmation de production.

Quelle observation mettrait en cause une explication par couplage du moteur ?

<details><summary>Réponse 5</summary>

Si modifier le couplage supposé ne change ni interaction d’état ni prédiction modale dans un essai contrôlé, le mécanisme affirmé manque de preuves. Notre algèbre propose ce diagnostic sans l’exécuter.

</details>

## Tâche avec consultation des sources

Dessiner les forces et calculer manuellement les deux fréquences, puis recommencer sans liaison. Inspecter les déclarations de voix et de résonateur et formuler une observation limitée à cet extrait. Indiquer où une future observation des échanges bidirectionnels serait nécessaire. Distinguer les preuves soutenant l’analogue mécanique, l’implémentation et la réponse d’une guitare mesurée.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
