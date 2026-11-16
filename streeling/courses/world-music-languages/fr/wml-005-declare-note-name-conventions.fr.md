---
module_id: wml-005-declare-note-name-conventions
department: world-music-languages
course: "Déclarer la convention de nommage des notes avant d'interpréter B"
level: intermediate
prerequisites: ["wml-003-term-preservation-and-cultural-review"]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Déclarer la convention de nommage des notes avant d'interpréter B

> **Portée du brouillon.** Documentation primaire, code source public de GA à une révision précise, tableau de décision conçu pour le cours et réponses réelles de l'outil de transposition d'accords. La revue technique humaine, la relecture par des personnes maîtrisant la langue, les essais avec des apprenants et la vérification du HTML du cours déployé restent à effectuer. Aucun nouvel adaptateur linguistique ni aucune exécution du parseur C# ne sont fournis.

## La question du projet

Un guitariste envoie à un agent « B, capo 2 ». Une transposition irréprochable peut tout de même répondre à la mauvaise question musicale si l'agent choisit la mauvaise convention de nommage. Le [tableau des langues de LilyPond 2.24](https://lilypond.org/doc/v2.24/Documentation/notation/writing-pitches#note-names-in-other-languages) établit une distinction explicite utile : son vocabulaire anglais emploie B pour si naturel, tandis que son vocabulaire allemand emploie H pour si naturel et B pour si bémol. Ce cours utilise ces deux **conventions déclarées** ; la nationalité, la langue de l'interface et le lieu où se trouve le musicien ne permettent pas de déterminer la convention d'une grille particulière.

[WML-003](wml-003-term-preservation-and-cultural-review.md) préserve les termes et la responsabilité de la relecture. Ici, la tâche est plus précise : déterminer la hauteur que désigne un symbole avant de le transmettre à GA. Le [tableau de décision conçu pour le cours](../../../../code/streeling/evidence/pitch-context-2026-10-22/language-decisions.json) est un support pédagogique, et non un service de normalisation installé.

## 1. Lire un symbole avec sa convention

Dans ce tableau, les graphies de sortie utilisent les noms de notes anglais et les classes de hauteur prennent C comme 0. L'octave et la qualité de l'accord sont volontairement absentes.

| Convention déclarée | Symbole d'entrée | Sortie en notation anglaise | Classe de hauteur | Décision |
| --- | --- | --- | --- | --- |
| Anglaise | B | B | 11 | résolu |
| Anglaise | Bb | Bb | 10 | résolu |
| Allemande | B | Bb | 10 | résolu |
| Allemande | H | B | 11 | résolu |
| non précisée | B | non résolu | non résolue | demander la convention |
| Anglaise | H | non résolu | non résolue | hors du vocabulaire déclaré |

### Exercice 1 : résoudre le désaccord

Deux grilles contiennent B. L'une déclare les noms anglais ; l'autre, les noms allemands. Donnez la sortie en notation anglaise et la classe de hauteur pour chacune. L'une des grilles contient-elle nécessairement une erreur de notation ?

> **Réponse:** Le B anglais donne B, classe 11 ; le B allemand donne Bb, classe 10. Aucune des deux grilles ne contient nécessairement une erreur. Leurs conventions déclarées attribuent des sens différents au même symbole.

## 2. Examiner la véritable interface d'entrée de GA

À la révision publique de GA `dc2e74cbd992a298f67efb928b5b3754615e1924`, [NaturalNote](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Primitives/Notes/NaturalNote.cs) reconnaît les lettres de A à G. Le [PitchParser](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs) générique sélectionne une syntaxe d'altération avec dièse ou bémol et attend une octave. Son motif ne comporte pas d'alternative H. Il s'agit d'une inspection du code source, et non d'une nouvelle exécution de ce parcours C#. Son motif non ancré nous empêche également de considérer cette inspection comme une garantie générale de validation stricte de l'entrée entière.

Les graphies anglaises canoniques des exemples allemands déclarés seraient B et Bb. Une interface de hauteur incluant l'octave exigerait aussi une octave déclarée, par exemple B4 ou Bb4. Une interface de symboles d'accord suit un autre contrat : un B seul peut désigner une fondamentale d'accord sans préciser de registre. La syntaxe propre à LilyPond, avec ses notes en minuscules et sa notation des octaves, n'est pas la syntaxe d'entrée de GA.

### Exercice 2 : choisir la représentation de destination

Une source déclare les noms allemands et contient H à l'octave 4. Donnez une graphie anglaise incluant l'octave. Que faut-il établir avant de convertir un B seul provenant d'une grille dont la convention n'est pas précisée ?

> **Réponse:** Selon la convention déclarée, H à l'octave 4 devient B4. Pour le B sans convention précisée, établissez d'abord la convention de nommage ; ajoutez une octave uniquement si la destination exige une hauteur absolue. Le nom d'une fondamentale ne fournit pas à lui seul le registre.

## 3. Une opération correcte en aval ne peut pas corriger une supposition antérieure

Les [essais réels de l'outil](../../../../code/streeling/evidence/pitch-context-2026-10-22/theory-tool-probes.json) consignent des transpositions d'accords de GA : B monté de 2 demi-tons a donné C#, et Bb monté de 2 a donné C. Ces réponses concordent avec le calcul des classes de hauteur : `(11+2)%12 = 1` et `(10+2)%12 = 0`. La révision du service est inconnue. Ces appels n'exécutent aucun adaptateur de noms allemands et ne prouvent pas que le parseur déployé correspond à la révision examinée.

L'écart d'un demi-ton apparaît dès l'interprétation. Répéter la même transposition, ajouter une chaîne d'agents plus élaborée ou augmenter le niveau de confiance conserverait la prémisse erronée.

### Exercice 3 : retracer l'erreur

Un agent interprète silencieusement un B sans convention précisée comme un B anglais et applique un capo 2. Comparez sa réponse à celle obtenue avec l'interprétation allemande déclarée. Quelle donnée manquante explique le désaccord ?

> **Réponse:** Le B anglais mène à C#, classe 1 ; le B allemand devient d'abord Bb, puis mène à C, classe 0. La donnée manquante est la convention de nommage des notes. Le calcul de transposition peut être correct dans les deux branches.

## 4. Conserver assez de contexte pour revenir sur une décision

Une transmission proposée devrait conserver le symbole d'origine, la convention déclarée, la graphie canonique, la décision d'interprétation et les éléments de preuve issus de la source. Il s'agit d'une proposition de structure de données, et non d'un nouveau schéma obligatoire pour l'écosystème. Pour le H allemand, ne conserver que le B canonique fait perdre la graphie d'origine, même si la classe de hauteur choisie est préservée. Pour un B non résolu, conservez l'ambiguïté au lieu de le convertir en une classe arbitraire en plaçant un avertissement ailleurs.

Ne déduisez pas tout un vocabulaire d'une seule substitution commode. Un adaptateur général devrait traiter les altérations, les conventions d'octave, la syntaxe valide, le comportement face aux symboles non pris en charge et une déclaration de la source pouvant être examinée. Ce petit tableau ne prétend pas tout mettre en œuvre.

### Exercice 4 : conserver la bonne distinction

Comparez un B anglais et un H allemand une fois qu'ils sont tous deux devenus un B canonique. S'agit-il du même texte d'origine ? Indiquez le contexte qu'un agent devrait conserver pour pouvoir expliquer sa décision ultérieurement.

> **Réponse:** Le texte d'origine est différent. Conservez le symbole d'origine et la convention déclarée, la sortie canonique et les preuves justifiant l'interprétation. L'égalité d'une classe de hauteur dérivée n'implique pas l'égalité de la provenance ou de la notation.

## 5. Vérifier le traitement de l'ambiguïté avant d'élargir le vocabulaire

Utilisez les six lignes comme exercice avec accès aux sources. Les quatre lignes résolues doivent conserver la correspondance déclarée. Le B sans convention précisée doit rester non résolu ; le H anglais est hors du vocabulaire déclaré pour cet exercice. Distinguez ces deux raisons au lieu de les ramener à une même valeur par défaut considérée comme un succès.

Ces décisions décrivent le comportement attendu d'une interface proposée, et non le comportement mesuré d'un nouveau composant de GA. [MCL-005](../../musicology/en/mcl-005-preserve-written-and-sounding-pitch.md) ajoute une distinction après celle de la graphie : une hauteur écrite encodée peut encore nécessiter une transposition déclarée pour identifier le son produit.

### Exercice 5 : rejeter une mesure de réussite trompeuse

Un adaptateur renvoie une classe de hauteur pour les six lignes et annonce une couverture complète. Il attribue la classe 11 au B sans convention précisée et la classe 11 au H anglais. Respecte-t-il le tableau déclaré ? Indiquez les résultats exigés.

> **Réponse:** Non. Seules les quatre lignes résolues ont des classes de hauteur déclarées. Le B sans convention précisée exige de connaître la convention ; le H anglais est hors du vocabulaire déclaré. Renvoyer un nombre pour chaque entrée masque deux cas non résolus ou non pris en charge et ne prouve pas que l'interprétation est correcte.

## Travail de l'apprenant avec accès aux sources

Effectuez le [travail préparé](../../../../code/streeling/evidence/pitch-context-2026-10-22/learner-task.md) avant d'ouvrir sa grille d'évaluation. Expliquez un désaccord dépendant de la convention et rédigez une transmission qui préserve le cas non résolu. Les sources et une calculatrice sont autorisées ; aucune réponse réelle d'apprenant ni décision de relecture n'a encore été consignée.
