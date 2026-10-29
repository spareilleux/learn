---
module_id: gas-013-retune-with-an-explicit-tension-assumption
department: guitar-acoustics
course: "Réaccorder avec une hypothèse de tension explicite"
level: intermediate
prerequisites: ["gas-009-estimate-tuning-error-from-integer-delay-length"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Réaccorder avec une hypothèse de tension explicite

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un moteur numérique reçoit une fréquence, tandis qu’une guitare physique change de hauteur par sa longueur, sa tension et sa masse répartie. Confondre ces opérations masque les hypothèses. Une explication du réaccordage doit préciser la grandeur maintenue fixe avant de prédire une charge. Nous calculons un rapport de tension sur une corde idéale construite, puis changeons volontairement sa longueur. Ce modèle explique les commandes GA sans conseiller d’appliquer une charge donnée à un instrument.

## Lire les preuves conservées

L’état de voix conservé contient fréquence et grandeurs de retard. Il ne convertit pas une fréquence demandée en tension physique mesurée. OpenStax déduit la vitesse d’onde de la tension et de la masse linéique. Avec la relation du fondamental à extrémités fixes, cela donne notre modèle. Le prérequis étudiait un retard numérique entier ; nous examinons ici le sens physique du réaccordage.

[Prérequis](../../guitar-acoustics/en/gas-009-estimate-tuning-error-from-integer-delay-length.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://openstax.org/books/university-physics-volume-1/pages/16-3-wave-speed-on-a-stretched-string)

### Exercice 1

Employer une longueur de `0.5 m`, une masse linéique de `0.008 kg/m` et une tension initiale de `80 N`. La vitesse vaut `sqrt(T0/mu)` et le fondamental cette vitesse divisée par `2*L`. Utiliser des unités SI cohérentes plutôt que d’insérer des millimètres dans une formule en mètres. Ces paramètres simples sont construits, pas mesurés sur une corde nommée.

Quelle est la fréquence fondamentale initiale ?

<details><summary>Réponse 1</summary>

Elle vaut `100 Hz` selon `initial_f=sqrt(T0/mu)/(2*L)`. Cela décrit la corde idéale construite, pas une note de guitare mesurée.

</details>

### Exercice 2

Viser `150 Hz` en maintenant longueur et masse linéique fixes. La relation donne `target_T=mu*(2*L*target_f)^2`, soit `180 N`. Le carré est essentiel : un multiplicateur de fréquence ne multiplie pas linéairement la tension. Une commande numérique peut d’ailleurs ne proposer aucune interprétation mécanique.

Quelle tension cible découle de ces hypothèses fixes ?

<details><summary>Réponse 2</summary>

La cible est `180 N`. La fréquence est multipliée par `1.5`, mais la tension par son carré, `2.25`, à longueur et masse linéique fixes.

</details>

### Exercice 3

La charge augmente de `100 N`, selon `180-80`. Cette différence ne fournit pas la contrainte admissible : section, matériau, construction et limites de l’instrument ne sont pas renseignés. Une leçon ou un agent doit conserver cette inconnue, au lieu de transformer un calcul valide en consigne d’utilisation sûre.

Le calcul certifie-t-il que le réaccordage est sûr ?

<details><summary>Réponse 3</summary>

Non. Il prédit `180 N` et une hausse de `100 N`, sans fournir de preuve d’acceptation du matériau ou de l’instrument. Faisabilité et sécurité restent indécises.

</details>

### Exercice 4

Pour le contrôle négatif, fixer la longueur vibrante à `1/3 m`, avec masse linéique `0.008 kg/m`, tension `80 N` et cible `150 Hz`. La fréquence initiale vaut déjà `150 Hz` et la tension requise reste `80 N`. Cela réfute l’idée universelle qu’atteindre cette cible exige toujours le multiplicateur précédent.

Que change la nouvelle hypothèse de longueur ?

<details><summary>Réponse 4</summary>

Le contrôle demande `80 N`, avec un rapport de `1`, puisque la longueur réduite donne déjà `150 Hz`. Le rapport `2.25` dépendait de la longueur d’origine.

</details>

### Exercice 5

Fretter une note et réaccorder une corde ouverte changent des paramètres différents du modèle. Le frettage réel peut aussi modifier légèrement la tension, et les cordes filées ne sont pas parfaitement uniformes. Une comparaison de moteurs doit donc préciser l’idéalisation visée par son paramètre et mesurer la hauteur produite indépendamment du mécanisme physique supposé.

Quelle observation réfuterait la prédiction de tension à longueur fixe ?

<details><summary>Réponse 5</summary>

À longueur et masse linéique vérifiées inchangées, une fréquence incompatible avec la relation en racine carrée au-delà d’une incertitude déclarée réfuterait cette prédiction idéale. Sans ces contrôles, la cause ne peut pas être isolée.

</details>

## Tâche avec consultation des sources

Expliquer une commande de fréquence à un guitariste. Calculer manuellement le cas initial et celui de longueur réduite, avec les unités. Inspecter les champs de fréquence et de retard et distinguer leur sens logiciel d’une charge physique. Définir une mesure réfutante et les preuves matérielles nécessaires avant une recommandation réelle. Ne pas présenter ces paramètres construits comme spécification d’instrument.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
