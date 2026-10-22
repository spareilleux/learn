---
module_id: cog-004-score-a-pitch-discrimination-task
department: cognitive-science
course: "Évaluer une tâche de discrimination de hauteur sans inventer un résultat d’écoute"
level: intermediate
prerequisites: ["cog-003-calibrating-fretboard-confidence"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Évaluer une tâche de discrimination de hauteur sans inventer un résultat d’écoute

> **Périmètre du brouillon.** Clé de réponses publique définie pour le cours, réponses synthétiques, calculs exacts de probabilités et fichiers de sons originaux préparés. La revue technique humaine, la relecture linguistique, les essais de participants, les résultats d’écoute et la vérification du HTML déployé restent à faire. Aucun auditeur n’a été observé dans ce dossier.

## La question du projet

Un agent peut produire deux fréquences différentes et noter des réponses. Cela ne montre pas qu’un guitariste a entendu la différence, préféré un son ou appris quoi que ce soit. Le [résumé de Creelman et Macmillan sur les procédures auditives](https://pubmed.ncbi.nlm.nih.gov/528924/) décrit comment la sensibilité mesurée dépend de la procédure psychophysique. Seul le résumé indexé a été lu ici ; il ne valide ni nos stimuli ni un auditeur.

Ce cours définit une tâche précise : après deux intervalles temporels successifs contenant chacun un son isolé, choisir celui dont la fréquence est la plus élevée. Le [relevé des fréquences construites](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json) donne 327.031956626 Hz et 329.627556913 Hz, séparés de 13.686286135 cents. La construction du rapport ne prescrit pas la pratique d’une tradition musicale. [WML-004](../../world-music-languages/en/wml-004-preserve-intonation-beyond-pitch-classes.md) traite cette limite.

## 1. Définir la question avant de noter les réponses

Les fichiers préparés [son A](../../../../code/streeling/evidence/intonation-listening-2026-10-22/tone-a.wav) et [son B](../../../../code/streeling/evidence/intonation-listening-2026-10-22/tone-b.wav) sont en PCM16 mono à 44100 Hz et durent une seconde chacun. Ils comportent des fondus de 10 ms aux extrémités. Leur RMS en virgule flottante a été ajusté à 0.05 avant quantification ; le [relevé des fichiers](../../../../code/streeling/evidence/intonation-listening-2026-10-22/audio-assets.json) conserve les mesures après décodage. Aucune préparation numérique du niveau ne prouve une égalité du niveau sonore perçu, un étalonnage de la restitution ou une présentation effective des stimuli.

La réponse demandée est l’intervalle 1 ou l’intervalle 2. Ce n’est ni une note de qualité sonore, ni une préférence d’accordage, ni une estimation de confiance, ni un test de mémoire. Le mélange simultané de [PHY-007](../../physics/en/phy-007-separate-beating-from-decay.md) répond à une autre tâche et ne doit pas remplacer ces stimuli séquentiels sans le signaler.

### Exercice pratique 1 : identifier le résultat

Un participant choisit l’intervalle 2 lorsqu’il contient le son le plus aigu. Quel résultat défini est correct, et quelles conclusions plus larges ne peut-on pas tirer de cette seule réponse ?

> **Réponse :** La réponse est correcte pour la tâche de discrimination de la fréquence la plus élevée. Une réponse seule n’établit ni une aptitude stable, ni un seuil perceptif, ni une préférence sonore, ni une qualité d’accordage, ni un apprentissage. Il faudrait aussi consigner la présentation réelle des stimuli et les preuves concernant le participant avant d’y voir un résultat observé.

## 2. Auditer un jeu de données arithmétique volontairement public

La [trace synthétique](../../../../code/streeling/evidence/intonation-listening-2026-10-22/synthetic-trials.json) contient 20 essais définis pour le cours. L’intervalle correct est 1 pour les identifiants d’essai impairs et 2 pour les identifiants pairs. Les réponses sont délibérément incorrectes aux identifiants 3, 7, 12, 16 et 20, et correctes ailleurs. Cette clé publique alternée est commode pour vérifier les calculs. Ce n’est pas une séquence d’écoute aléatoire, cachée ou effectivement administrée.

La trace obtient 15/20, soit 0.75. Choisir systématiquement l’intervalle 1 donne 10/20, soit 0.5. Les comptes conditionnels sont de 8/10 réponses correctes lorsque le son le plus aigu est en premier et de 7/10 lorsqu’il est en second. Le répondant synthétique choisit l’intervalle 1 onze fois. Ces résumés sont différents ; aucun ne transforme des réponses inventées en données de participants.

### Exercice pratique 2 : vérifier les résumés par position

Cinq réponses définies pour le cours sont incorrectes. Donnez le taux global de réponses correctes, la référence « toujours en premier » et les deux comptes conditionnels de réponses correctes. Publier ces nombres établirait-il la performance d’un auditeur ?

> **Réponse :** Le taux global est de 15/20 = 0.75 ; la référence « toujours en premier » est de 10/20 = 0.5. Les comptes conditionnels sont de 8/10 et de 7/10 pour les essais où le son le plus aigu est respectivement en premier et en second. Ils servent uniquement à auditer le jeu de données. Aucun participant n’a effectué cette séquence ; aucune performance d’auditeur n’a donc été observée.

## 3. Distinguer une règle de décision d’une probabilité a posteriori

Supposez des essais indépendants avec des réponses au hasard équiprobables et une probabilité de réussite de 0.5. Dans ce modèle, le nombre de réponses correctes suit une loi binomiale à 20 essais. La probabilité unilatérale exacte d’atteindre au moins un nombre donné de réussites est la somme des combinaisons entières correspondantes, divisée par `2^20`.

La [documentation officielle de la loi binomiale de SciPy](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.binom.html) définit sa fonction de survie comme la probabilité d’une valeur strictement supérieure à l’argument. Ainsi, « au moins 15 » utilise `binom.sf(14,20,0.5)`, et non `binom.sf(15,20,0.5)`. Les calculs indépendants par combinaisons entières concordent avec la fonction installée à `1e-14` près.

| Au moins ce nombre de réponses correctes | Probabilité de queue unilatérale |
| --- | --- |
| 12 | 0.2517223358154297 |
| 14 | 0.057659149169921875 |
| 15 | 0.020694732666015625 |
| 16 | 0.005908966064453125 |

Pour une règle unilatérale déclarée à l’avance avec alpha 0.05, le plus petit nombre entier satisfaisant le critère est 15. Il s’agit d’un modèle statistique et d’une règle supposés, pas d’un résultat d’écoute observé. Une probabilité de queue n’est pas la probabilité que l’hypothèse de réponses au hasard soit vraie, et un score sous le seuil ne prouve pas une incapacité à discriminer.

### Exercice pratique 3 : appliquer la règle exacte

Un score de 14/20 satisfait-il la règle déclarée ? Quel argument de la fonction de survie représente au moins 15 réussites, et que signifie sa probabilité ?

> **Réponse :** Non : la queue pour au moins 14 vaut 0.057659149169921875, au-dessus de 0.05. Au moins 15 utilise l’argument 14 et donne une queue de 0.020694732666015625. Sous le modèle supposé de réponses indépendantes au hasard équiprobables, c’est la probabilité d’un compte au moins aussi élevé. Ce n’est pas une probabilité a posteriori que le modèle soit vrai.

## 4. Tenir compte de la sélection d’un bloc réussi

Supposez qu’un agent effectue huit tests complets indépendants sous ce même modèle nul et ne rapporte qu’un bloc atteignant 15 réussites. La probabilité réelle de faux positif pour un test avec cette règle discrète est `q=0.020694732666015625`. La probabilité qu’au moins un des huit franchisse le seuil est `1-(1-q)^8`, soit environ 0.154049944.

Utiliser la queue discrète réelle compte : l’alpha nominal de 0.05 n’est pas ici la probabilité exacte de franchir le seuil. L’indépendance est aussi une hypothèse. Des blocs répétés par une même personne peuvent être dépendants ; un arrêt anticipé, une modification des stimuli ou une sélection des analyses exigent un traitement supplémentaire. Ce calcul ne décrit pas une expérience effectuée.

### Exercice pratique 4 : rendre la sélection visible

Un agent rapporte son meilleur bloc réussi parmi huit tests nuls indépendants comme s’il s’agissait de l’unique test. Calculez la probabilité d’au moins un franchissement du seuil et indiquez l’information manquante.

> **Réponse :** `1-(1-q)^8` vaut environ 0.154049944 avec le q indiqué. Le rapport doit mentionner les huit tests, la règle de sélection et l’hypothèse d’indépendance. Sans prise en compte de la sélection, un bloc réussi sélectionné ne conserve pas l’interprétation du faux positif d’un test unique.

## 5. Préparer un véritable test sans prétendre l’avoir effectué

Un futur protocole doit déclarer la comparaison, la règle d’ordre de présentation, les conditions de restitution, le délai de réponse, les exclusions et l’analyse avant le recueil des résultats. Gardez la clé de réponses et les noms de fichiers révélant les fréquences hors de l’interface des participants. Utilisez une séquence aléatoire équilibrée et cachée plutôt que ce jeu de données prévisible, tout en conservant un relevé privé reproductible des affectations. Vérifiez le niveau et les indices involontaires au début des sons ou dans l’interface, ainsi que la fréquence.

Consignez chaque tentative et chaque exclusion déclarée, préservez la vie privée des participants et rapportez l’incertitude ainsi que la population effectivement échantillonnée. Tester un seul écart ne permet pas de situer un seuil perceptif ; il faut pour cela une procédure adaptée à plusieurs niveaux et des preuves. Une affirmation de préférence ou d’apprentissage demande son propre critère de résultat et son propre plan d’étude. La revue humaine et le consentement des participants restent des exigences pour une véritable étude, pas des étapes déjà franchies dans ce dossier.

### Exercice pratique 5 : réécrire l’annonce de publication

La note de publication indique : « Un score de 15/20 prouve que les guitaristes peuvent entendre un écart de 13.686286135 cents et apprendre plus vite. » Quelle formulation est étayée ?

> **Réponse :** Le dossier prépare deux sons construits et vérifie la notation synthétique ainsi qu’une règle statistique déclarée. Il ne contient aucune réponse de participant observée, aucun seuil perceptif, aucun résultat de population ni aucune comparaison d’apprentissage. Un véritable protocole avec présentation contrôlée, affectations cachées, analyse déclarée et critères de résultat adaptés reste nécessaire avant de pouvoir tester ces affirmations.
