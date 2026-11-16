---
module_id: gaa-007-turn-a-voicing-result-into-a-practice-item
department: guitar-alchemist-academy
course: "Transformer un résultat de voicing en question d'entraînement"
level: early-intermediate
prerequisites: ["gaa-004-choose-a-useful-voicing", "cog-002-feedback-integrity-fretboard-recall"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Transformer un résultat de voicing en question d'entraînement

> **Portée du brouillon.** Exemples de questions de guitare conçus pour le cours, calculs exacts de hauteurs et lecture du code public et des tests à une révision précise. Les revues humaines technique, musicale, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucune requête de recherche, aucun outil de formatage, questionnaire, guitare ou apprenant n'ont fait l'objet d'un essai.

## La question du projet

GA peut proposer un voicing. Que faut-il changer avant que ce résultat devienne une question d'entraînement vérifiable ? La [compétence de voicings à la révision fixée](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L130-L167) fournit du texte affiché et des champs structurés de diagramme, de nom d'accord, d'instrument et de score de recherche. Ces champs sont utiles pour un cours ; ils ne sont ni la réponse d'un apprenant, ni une politique de révélation de réponse, ni une mesure d'apprentissage.

[GAA-004](gaa-004-choose-a-useful-voicing.md) compare les propositions de voicings aux besoins d'un guitariste. Ici, nous définissons la question et la règle d'acceptation avant d'attribuer une note. Les quatre formes candidates ci-dessous sont des jeux d'essai pédagogiques, et non des résultats capturés renvoyés par GA.

## 1. Choisir la cible avant de masquer un champ

Considérez deux tâches différentes. « Nommez l'accord représenté par ce diagramme » peut afficher le diagramme mais doit masquer la réponse donnant le nom de l'accord. « Donnez une forme quelconque de triade de C majeur avec cet accordage » peut afficher le nom de l'accord demandé mais ne doit pas présenter la forme exemple comme une réponse de mémoire. Une troisième tâche, « reproduisez exactement la forme ouverte de C qui vient d'être apprise », teste délibérément une forme préalablement spécifiée.

Le même champ de nom d'accord est une réponse dans la première tâche et un indice prévu dans les deux autres. Une consigne universelle de masquer toutes les étiquettes retirerait des informations utiles à la tâche. Une question d'entraînement déclare plutôt la cible, les indices visibles, les réponses acceptées et le moment de révélation. Ce sont des champs de cours proposés, et non une API de questions implémentée dans GA.

### Exercice 1 : classer un indice visible

Faut-il afficher C majeur lorsqu'on demande à l'apprenant de nommer un diagramme de C majeur déjà étiqueté ? Faut-il l'afficher lorsqu'on demande une forme quelconque de triade de C majeur ? Quelle précision supplémentaire rend une question sur une forme exacte sans ambiguïté ?

> **Réponse:** Masquez-le lorsqu'il est la réponse à la tâche de dénomination. Conservez-le comme cible demandée dans la tâche acceptant toute forme. Une tâche de forme exacte doit identifier explicitement la forme apprise auparavant et sa convention d'ordre des cordes ; « n'importe quel C majeur » ne précise pas un tableau unique de cases.

## 2. Construire un corrigé à partir de coordonnées déclarées

À la révision `76efbffd5af82b46c3146957a6bd4504008eeb89`, le [formateur de diagrammes](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Notation/PlayableNotationFormatter.cs#L30-L39) documente les diagrammes stockés avec la corde aiguë en premier et les grilles avec la corde grave en premier. Son exemple sélectionné de C ouvert inverse la valeur brute `0-1-0-2-3-x` en grille `x-3-2-0-1-0`. Les [cas d'inversion présents dans le dépôt](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Tests/Common/GA.Business.ML.Tests/Notation/PlayableNotationFormatterTests.cs#L37-L42) incluent cette paire. Lire des assertions n'est pas exécuter de nouveaux tests.

La compétence formate son résultat affiché dans l'ordre de la grille, tandis que son champ structuré `diagram` conserve la valeur brute. Un consommateur doit identifier la représentation qu'il lit. Pour le corrigé pédagogique, déclarez l'accordage MIDI standard du grave à l'aigu `[40,45,50,55,59,64]`, sans capo, avec des cases entières en tempérament égal et en excluant les cordes étouffées `x`. Les notes MIDI réelles de la grille sont `[48,52,55,60,64]`, soit C3, E3, G3, C4, E4 selon C4 = 60. Ce calcul vérifie une réponse proposée, et non la capacité d'un musicien à la jouer proprement.

### Exercice 2 : déduire le corrigé sonore

Inversez l'exemple brut dans l'ordre de la grille et calculez sa suite MIDI réelle selon l'accordage déclaré. Traiter le champ brut structuré comme une grille déjà formatée préserverait-il la même affectation aux cordes ?

> **Réponse:** La grille est `x-3-2-0-1-0` ; ajouter les cases aux cordes à vide non étouffées donne `[48,52,55,60,64]`. Traiter l'ordre brut comme l'ordre de la grille affecterait ses symboles à d'autres cordes et ne préserverait pas l'affectation. Conservez la révision du code, l'accordage, le capo et l'ordre avec le corrigé.

## 3. Accepter une réponse selon la question

Utilisez ces candidats pédagogiques du grave à l'aigu. Le critère restreint acceptant toute triade exige toutes les classes de hauteur C, E et G, et uniquement elles, chacune présente au moins une fois ; il ignore le registre et les doublures. Ce n'est pas une définition universelle de tous les voicings musicaux acceptables étiquetés C.

| Candidat | Grille | Classes de hauteur distinctes, C = 0 | A exact | Toute triade de C majeur selon le critère restreint |
| --- | --- | --- | --- | --- |
| A | `x-3-2-0-1-0` | 0, 4, 7 | oui | oui |
| B | `x-3-5-5-5-3` | 0, 4, 7 | non | oui |
| C | `x-3-2-0-0-0` | 0, 4, 7, 11 | non | non |
| D | `x-3-2-0-1-x` | 0, 4, 7 | non | oui |

Un validateur de tableau exact rejetterait à tort B et D si la question promettait toute forme satisfaisant le critère déclaré de triade. Un validateur limité aux classes de hauteur accepterait à tort B et D pour la tâche de reproduction exacte de A. Le candidat C ajoute B et échoue à cette règle particulière limitée aux triades. Un exercice musical autorisant les extensions exigerait une autre règle.

### Exercice 3 : vérifier la règle d'acceptation

Quels candidats réussissent la tâche de reproduction exacte de A et lesquels réussissent la tâche restreinte acceptant toute triade ? Pourquoi aucun de ces ensembles d'acceptation ne prouve-t-il la jouabilité physique ou l'unicité de l'interprétation musicalement utile ?

> **Réponse:** Seul A réussit la reproduction exacte de A. A, B et D satisfont la règle restreinte de triade ; C échoue parce que la classe de hauteur 11 est supplémentaire. Ce sont des critères symboliques déclarés. Le doigté, la tenue des notes, l'étouffement, le son et une autre demande harmonique exigent des vérifications distinctes.

## 4. Ne pas transformer la confiance de recherche en probabilité de rappel

La compétence sélectionnée attribue la confiance de réponse en bornant le meilleur score de recherche entre 0 et 1. Pour les scores finis pédagogiques -0.2, 0.8 et 1.2, cette opération donne 0, 0.8 et 1. Elle n'estime pas si un apprenant se souviendra d'un accord demain. Un nombre borné et une probabilité portant sur un événement défini d'apprenant sont des affirmations différentes.

Le [relevé d'évaluation des requêtes RAG](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Rag/RagEvaluationModels.cs#L3-L31) décrit les partitions de requêtes, le nombre de résultats, les scores de recherche et la latence. Ce n'est pas un résultat de rétention. Ne rebaptisez aucun de ces scores en construisant un tableau de bord d'entraînement.

### Exercice 4 : interpréter un score

Un résultat a un score de recherche de 0.8 et une confiance de réponse de 0.8. Un cours peut-il afficher « 80% de chances que vous vous en souveniez demain » ? Donnez les deux témoins de bornage hors intervalle et l'observation manquante.

> **Réponse:** Non. Les scores -0.2 et 1.2 sont bornés à 0 et 1, mais ce bornage ne fournit aucun étalonnage relatif à l'apprenant. Il manque une réponse différée définie, sans aide, avec un indice enregistré et un protocole de notation, ainsi que des preuves reliant les prédictions à cet événement.

## 5. Distinguer un plan d'une tentative

Les [types de routine d'entraînement](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/PracticeRoutineTypes.fs#L81-L101) nomment la précision, le tempo et d'autres objectifs ou éléments de suivi. La [compétence de catalogue d'entraînement](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Agents/Skills/PracticeRoutineSkill.cs#L3-L16) fournit une réponse de plan structuré. Aucune des deux interfaces examinées ne fournit l'observation réelle de réponse avant retour correctif de ce cours. C'est une affirmation sur des sources sélectionnées, et non sur une absence dans tout le dépôt.

### Exercice 5 : préparer un relevé de question vérifiable

Que doit conserver un futur exercice au-delà du voicing renvoyé et de son score ? Quelles preuves supplémentaires sont nécessaires avant de qualifier une question terminée de bénéfice d'apprentissage ?

> **Réponse:** Conservez l'identité de la source et de la requête, l'ordre brut et affiché, l'instrument, l'accordage et le capo, la cible, les indices autorisés, le corrigé vérifié, la règle d'acceptation, la réponse avant révélation, l'aide, l'identité et le moment de la tentative. Consignez une véritable évaluation différée avant d'affirmer une rétention, et utilisez une comparaison justifiée avant d'attribuer un bénéfice. Un plan, un clic ou un score seuls ne fournissent aucun de ces résultats.

Le [dossier fixé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/README.md) conserve le corrigé et les calculs d'acceptation. [COG-007](../../cognitive-science/en/cog-007-separate-unaided-recall-from-assisted-success.md) évalue ensuite un historique de tentatives délibérément synthétique selon un critère de résultat explicite.
