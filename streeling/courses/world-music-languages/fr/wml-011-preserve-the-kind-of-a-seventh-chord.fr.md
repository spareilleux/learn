---
module_id: wml-011-preserve-the-kind-of-a-seventh-chord
department: world-music-languages
course: "Conserver la nature d’un accord de septième"
level: intermediate
prerequisites: ["wml-005-declare-note-name-conventions"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conserver la nature d’un accord de septième

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Traduire un symbole d’accord demande plus que garder sa fondamentale. Une triade majeure peut porter une septième mineure ou majeure ; un petit suffixe change les hauteurs voulues. Normaliser chaque étiquette contenant majeur vers une même famille peut changer silencieusement l’harmonie d’un exercice. Nous séparons convention de fondamentale, nature d’accord et symbole original avant de proposer une représentation portable pour GA.

## Lire les preuves conservées

Lire les candidats de do majeur et celui contenant une classe de septième supplémentaire dans le dossier conservé. Ils montrent pourquoi une acceptation ciblée diffère d’une correspondance large. Les définitions kind-value MusicXML distinguent dominant, minor-seventh et major-seventh par triade et septième. Nous n’utilisons que ce sous-ensemble, sans exécuter de parseur ni universaliser les abréviations des musiciens.

[Prérequis](../../world-music-languages/en/wml-005-declare-note-name-conventions.md)

[Artefact de projet conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/data-types/kind-value/)

### Exercice 1

Fixer la fondamentale à `0` et le dictionnaire construit `dominant=[0,4,7,10]`, `minor-seventh=[0,3,7,10]`, `major-seventh=[0,4,7,11]`. Les écarts sont en demi-tons dans le modèle tempéré déclaré. Afficher ce dictionnaire : le mot septième seul ne définit ni tierce ni taille de septième.

Quels écarts définissent ici la nature dominante ?

<details><summary>Réponse 1</summary>

Ce sont `[0,4,7,10]`, avec tierce majeure d’écart `4`, septième mineure d’écart `10`, fondamentale et quinte.

</details>

### Exercice 2

Le cas principal choisit `dominant`. Ajouter la fondamentale modulo `12` et trier donne `[0,4,7,10]`. Cela définit une famille, pas basse, registre, doublures ou doigté. Une guitare exige encore un voicing et une consigne physique avant que cette famille soit jouable.

Quel résultat est justifié et que manque-t-il ?

<details><summary>Réponse 2</summary>

La famille justifiée est `[0,4,7,10]`. Notes absolues, basse, cordes et jouabilité restent indéfinies.

</details>

### Exercice 3

La nature `minor-seventh` passe la tierce à `3` et garde la septième `10` ; `major-seventh` garde la tierce `4` et passe la septième à `11`. L’adjectif concerne donc des composantes différentes selon l’identifiant déclaré. Nommer les deux évite de demander une déduction à partir d’un symbole raccourci ambigu.

Pourquoi distinguer qualité de triade et qualité de septième ?

<details><summary>Réponse 3</summary>

Minor-seventh donne `[0,3,7,10]` et major-seventh `[0,4,7,11]`. Tierce et septième changent indépendamment dans ce dictionnaire.

</details>

### Exercice 4

Le contrôle négatif change seulement `dominant` en `major-seventh`. Le résultat `[0,4,7,11]` conserve fondamentale et triade majeure, avec septième rehaussée d’un demi-ton. Vérifier seulement la fondamentale ou la présence d’une septième manquerait le membre d’accord modifié.

Que doit détecter l’audit dans le contrôle ?

<details><summary>Réponse 4</summary>

Il doit détecter l’écart de septième `11` remplaçant `10`, avec tierce `4` inchangée. La famille diffère malgré fondamentale et triade communes.

</details>

### Exercice 5

Un transfert multilingue peut garder un identifiant explicite avec symbole original et convention déclarée. C’est une proposition, pas un schéma GA ratifié. Pour un suffixe non pris en charge, laisser l’interprétation ouverte plutôt que choisir une convention familière selon la langue ou nationalité supposée de l’auteur.

Qu’est-ce qui réfuterait la conservation de la nature d’accord à la traduction ?

<details><summary>Réponse 5</summary>

Mapper les cas principal et de contrôle vers la même famille perd leur septième distincte. Garder la lettre de fondamentale ne suffit pas à affirmer la conservation harmonique.

</details>

## Tâche avec consultation des sources

Construire le dictionnaire et les ensembles des deux cas à la main. Inspecter candidats conservés et définitions officielles, puis rédiger une explication bilingue gardant symbole, convention et nature explicite. Définir un réfutateur portant sur une seule note. Laisser parseur réel, usage idiomatique et choix physique du voicing à leurs preuves et revues respectives.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
