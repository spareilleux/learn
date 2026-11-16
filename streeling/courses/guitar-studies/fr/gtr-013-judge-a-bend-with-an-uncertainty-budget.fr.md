---
module_id: gtr-013-judge-a-bend-with-an-uncertainty-budget
department: guitar-studies
course: "Évaluer un bend avec un budget d’incertitude"
level: intermediate
prerequisites: ["wml-004-preserve-intonation-beyond-pitch-classes"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Évaluer un bend avec un budget d’incertitude

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un accordeur proche de la cible ne prouve pas automatiquement qu’un bend satisfait le critère de travail. L’estimation peut être incertaine et la cible demande une référence. GA peut aider le guitariste à expliciter ces grandeurs avant de donner un retour. Nous utilisons une estimation construite en cents avec une erreur bornée. La leçon ajoute une règle de décision à la représentation du prérequis, sans observer détection réelle ni interprétation.

## Lire les preuves conservées

Lire référence, écarts en cents construits et limites de source du dossier d’intonation conservé. Ce sont des calculs, pas un enregistrement de bend. NIST définit le cent par un rapport de fréquences. Nous n’importons que ce rapport, sans seuil d’écoute. La tolérance suivante est un choix pédagogique local, pas une norme universelle de bonne exécution.

[Prérequis](../../world-music-languages/en/wml-004-preserve-intonation-beyond-pitch-classes.md)

[Artefact de projet conservé](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

### Exercice 1

Employer une base de `110 Hz` et une hausse cible de `2` demi-tons. L’intervalle vaut `200` cents et la fréquence `110*2^(2/12) Hz`. La référence fixe rend le calcul reproductible. Nommer une note sans référence masquerait le choix entre tempérament égal, autre accordage ou destination expressive.

Exprimer la cible en cents et en fréquence.

<details><summary>Réponse 1</summary>

La cible est à `200` cents au-dessus de la base, soit `110*2^(2/12) Hz`. C’est la cible tempérée déclarée, pas un bend mesuré.

</details>

### Exercice 2

L’estimateur construit donne `195` cents avec une incertitude bornée de `3` cents. L’erreur signée vaut `195-200=-5` cents. Son signe indique une estimation trop basse. L’incertitude n’est pas une hauteur supplémentaire à appliquer : elle décrit les valeurs que le modèle considère compatibles avec cette estimation.

Quelle est l’erreur ponctuelle signée ?

<details><summary>Réponse 2</summary>

Elle vaut `-5` cents. Le signe négatif indique une estimation inférieure à la cible, sans établir seul l’échec ni déterminer exactement l’erreur réelle.

</details>

### Exercice 3

Fixer une tolérance inclusive de `10` cents. Notre règle prudente exige que tout l’intervalle tienne dedans, avec `worst_abs_error=abs(error)+uncertainty`. Le maximum vaut ici `8` cents : l’affirmation modélisée est établie. Aucune probabilité n’est attribuée, puisque l’incertitude fournie est une borne et non une distribution.

Le cas principal établit-il le critère choisi ?

<details><summary>Réponse 3</summary>

Oui : `8` cents ne dépasse pas `10` cents. Cela accepte le cas construit selon la règle, sans certifier une prise réelle d’apprenant.

</details>

### Exercice 4

Le contrôle négatif change seulement l’estimation à `191` cents. L’erreur ponctuelle est `-9` cents, encore dans la tolérance, mais le maximum atteint `12` cents. Un affichage ponctuel accepterait ce cas ; la règle par intervalle ne le permet pas. Distinguer le refus d’une certitude d’une preuve d’échec effectif.

Quelle décision suit pour le contrôle ?

<details><summary>Réponse 4</summary>

Le critère n’est pas établi : le maximum vaut `12` cents, au-delà de `10`. Cela ne prouve pas que le bend réel était hors tolérance ; l’incertitude laisse cette question ouverte.

</details>

### Exercice 5

Une tâche réelle doit préciser l’instant évalué : attaque, plateau ou relâchement peuvent donner des réponses différentes. L’incertitude du détecteur doit aussi être étayée pour ce signal et cette fenêtre. Un agent doit conserver cible, support temporel, estimation, incertitude et règle plutôt que de prendre une étiquette de note arrondie pour preuve.

Qu’est-ce qui réfuterait un retour prétendument sensible à l’incertitude ?

<details><summary>Réponse 5</summary>

Accepter le contrôle uniquement parce que son erreur ponctuelle respecte la tolérance contredirait la règle. Fidélité du détecteur et expressivité demandent d’autres observations.

</details>

## Tâche avec consultation des sources

Préparer une fiche de retour sur bend avec référence, cible, fenêtre temporelle à renseigner et les deux cas construits. Calculer erreurs signées et maximales à la main. Inspecter la représentation des cents et identifier ce qu’un enregistrement et un détecteur doivent fournir. Définir un cas d’acceptation réfutant avant de proposer un message automatisé ; laisser les décisions de jeu réel en attente.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
