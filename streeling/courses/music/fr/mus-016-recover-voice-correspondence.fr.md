---
module_id: mus-016-recover-voice-correspondence
department: music
course: Une distance minimale n’identifie pas les voix
level: intermediate
alchemical_stage: albedo
prerequisites: [mus-015-choose-voice-leading-equivalences]
estimated_duration: "60 minutes"
produced_by: codex-project-lab
version: "1.0.0"
---

# Une distance minimale n’identifie pas les voix

## Question du projet et livrable

Un agent GA dispose d’une distance minimale. Peut-il dire à un guitariste quelle ligne suit chaque note ? Produisez deux tableaux de correspondance explicites, reportez-les sur deux cordes de guitare et identifiez ce que le score ne permet pas de décider. Lisez d’abord [MUS-015](mus-015-choose-voice-leading-equivalences.md) : une distance dépend des équivalences choisies.

La [méthode de distance de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Atonal/VoiceLeadingSpace.cs) figée renvoie un scalaire. Elle ne renvoie ni affectation, ni mouvement signé, ni choix de corde, ni durée. Le [laboratoire pédagogique](https://github.com/spareilleux/learn/tree/codex/streeling-craft-transfer-20261022/code/streeling/voice-leading) énumère indépendamment les affectations pour de petits cas fixes et conserve certains témoins. Ces témoins sont de nouveaux résultats pédagogiques, pas une fonctionnalité existante de l’API GA.

## 1. Retrouver deux affectations également minimales

Prenez la source `[60,62]` et la collection cible `[64,65]`. Activez les équivalences d’octave et de permutation ; désactivez la transposition et l’inversion. Le scalaire natif vaut 7. L’énumération exhaustive trouve deux affectations de ce même coût :

| Plan | Première voix identifiée | Deuxième voix identifiée | Mouvements signés | Coût circulaire total |
|---|---|---|---|---:|
| A | 60 → 64 | 62 → 65 | +4, +3 | 7 |
| B | 60 → 65 | 62 → 64 | +5, +2 | 7 |

Les deux mouvements de voix sont inférieurs à une demi-octave ; chaque coût circulaire par paire est donc ici égal à la valeur absolue du mouvement avec le registre pris en compte. Cette égalité est propre à ces paires ; ailleurs, un coût avec équivalence d’octave peut masquer une octave.

### Exercice pratique 1

Une distance de 7 sélectionne-t-elle uniquement le plan A ? Expliquez à l’aide des deux sommes.

> **Réponse :** Non. Le plan A coûte 4 + 3 = 7 et le plan B coûte 5 + 2 = 7. Le scalaire ne conserve pas la correspondance qui l’a produit. Une règle de départage pourrait en choisir une, mais ce serait une politique supplémentaire.

## 2. Distinguer l’identité d’une voix de l’ordre des hauteurs

Au départ, la première voix est la plus grave : 60 est inférieur à 62. Dans le plan A, elle reste la plus grave, puisque 64 est inférieur à 65. Dans le plan B, la première voix identifiée termine au-dessus de la seconde, puisque 65 est supérieur à 64. L’ordre relatif des hauteurs s’inverse. Appeler « première voix » l’entrée cible la plus grave après le tri reviendrait à changer implicitement l’identité des voix du plan B.

Il s’agit d’un exemple de correspondance discrète. Nous n’avons précisé ni les durées des notes ni des trajectoires continues de hauteur. Cela ne démontre pas un croisement audible dans une interprétation enregistrée. De même, un faible mouvement total n’établit pas à lui seul l’acceptabilité stylistique ni l’absence d’intervalles parallèles.

### Exercice pratique 2

Pour une tâche qui exige que les voix identifiées conservent leur ordre relatif de hauteur aux deux extrémités, quel plan satisfait cette exigence ?

> **Réponse :** Le plan A. Le plan B inverse l’ordre aux extrémités, même si son coût total vaut aussi 7. Énoncez explicitement l’exigence d’ordre ; on ne peut pas la déduire du seul minimum.

## 3. Placer les mêmes notes sur une guitare

L’[accordage par défaut figé](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs) comprend les cordes à vide G3 = 55 et B3 = 59 dans cette convention numérique. Avancer d’une case ajoute un demi-ton. Utilisez les noms des cordes pour conserver leur identité :

| État | Corde de sol | Corde de si | Hauteurs identifiées obtenues |
|---|---|---|---|
| Source | Case 5 | Case 3 | 60, 62 |
| Cible du plan A | Case 9 | Case 6 | 64, 65 |
| Cible du plan B | Case 10 | Case 5 | 65, 64 |

Ces placements sont construits et vérifiés par addition. Ils n’ont été ni générés par un solveur de doigtés de GA ni joués par un participant. Une voix qui reste sur une même corde correspond à une règle d’identité possible ; une ligne musicale peut aussi changer de corde. L’identité de la corde et celle de la voix musicale doivent donc être déclarées séparément.

### Exercice pratique 3

Vérifiez les deux notes du plan B à partir des hauteurs des cordes à vide. L’inversion de l’ordre des hauteurs exige-t-elle que les cordes échangent leurs positions physiques ?

> **Réponse :** 55 + 10 = 65 et 59 + 5 = 64. Non. La corde de sol reste la corde de sol et la corde de si reste la corde de si ; le choix des cases peut inverser l’ordre relatif des hauteurs qu’elles produisent. Aucun croisement physique des cordes n’est affirmé.

## 4. Examiner un témoin et les limites de ses preuves

Dans les [résultats natifs conservés](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/native-results.json), trouvez `ambiguous_plan`. Ce cas enregistre `minimumAssignmentCount` à 2 et conserve les deux `witnesses`. Leurs `motions` sont les différences cible moins source avec le registre pris en compte ; les `voiceCosts` sont des coûts absolus ou circulaires par octave selon les paramètres du cas. Lisez ces champs séparément.

Pour relancer l’exécution, suivez les instructions de MUS-015 avec [Node.js](https://nodejs.org/api/cli.html) et [.NET](https://learn.microsoft.com/dotnet/core/tools/dotnet-build) déjà installés. L’exécution autonome utilise le code source inchangé dans un assembly distinct, avec un adaptateur d’annotations documenté. Windows a été évalué ; Linux / WSL et macOS restent à vérifier. Elle ne fait pas passer le tableau de placements sur la guitare dans un solveur.

### Exercice pratique 4

Pour le contre-exemple distinct `[60,63,65]` apparié à `[60,75,65]`, pourquoi `motions` peut-il contenir 12 alors que chaque entrée circulaire de `voiceCosts` vaut 0 ?

> **Réponse :** La deuxième hauteur identifiée monte de 63 à 75, soit un mouvement de 12 demi-tons avec le registre pris en compte. L’équivalence d’octave attribue à cette paire un coût circulaire de 0. Le témoin conserve la différence avec le registre pris en compte ; l’objectif choisi ignore sa composante d’octave.

## 5. Rédiger une passation destinée à l’interprétation

Une passation utile indique la collection de hauteurs, la correspondance sélectionnée, la règle d’identité, la politique de départage et les questions instrumentales encore ouvertes. Pour cet exercice, sélectionnez le plan A si la conservation de l’ordre des hauteurs aux extrémités est requise. Laissez le choix des doigts, le confort et l’articulation non évalués jusqu’à ce qu’un musicien teste un placement concret. Le [dossier de revue](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/learner-task.md) propose une tâche vérifiable à partir des preuves sans inventer de résultat d’écoute.

### Exercice pratique 5

Un agent écrit « distance 7, donc le doigté le plus facile ». Remplacez cette affirmation par un énoncé défendable.

> **Réponse :** « Les deux affectations déclarées ont un coût de 7 sous les équivalences indiquées. Nous sélectionnons le plan A pour conserver l’ordre des hauteurs aux extrémités. Son placement à la case 9 sur la corde de sol et à la case 6 sur la corde de si est construit ; le confort et le choix des doigts exigent encore un essai instrumental. » Poursuivez avec le [classement des candidats](mus-017-audit-voice-leading-rankings.md).
